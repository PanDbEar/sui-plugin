# SUI (Smart UI Virtualizer) — Architecture Specification

**Document Version:** 1.0.0 (Phase 6.2 Baseline)  
**Author:** SUI Engineering  
**Scope:** Core system architecture, lifecycle management, AMX ownership boundaries, and generation identity invariants.

---

## 1. System Overview

SUI is an out-of-process lifecycle and virtualization manager for per-player UI / `PlayerTextDraw` pools in SA-MP and open.mp legacy plugin environments. SUI coordinates lazy creation, visibility, and idle destruction of textdraw groups through user-defined Pawn public callbacks (`cbCreate`, `cbDestroy`, `cbShow`, `cbHide`).

Rather than hooking low-level SA-MP internal textdraw creation tables, SUI manages UI state at the logical group level, tracking capacity via `estimatedSize` and ensuring textdraw limits (`maxTextDraws`, `evictionThreshold`) are never violated.

```
+-----------------------------------------------------------------------+
|                              SA-MP / open.mp Server                   |
+------------------------------------+----------------------------------+
                                     |
                                     | ProcessTick / AmxLoad / AmxUnload
                                     v
+------------------------------------+----------------------------------+
|                            sui-plugin-legacy                          |
|                                                                       |
|  +--------------------+   +-------------------+   +----------------+  |
|  |     main.cpp       |-->|   Natives.cpp     |-->|   SUICore      |  |
|  | (AmxLoad/Register) |   | (Param Unpacking) |   | (State Store)  |  |
|  +--------------------+   +-------------------+   +----------------+  |
|                                                          |            |
|                               +--------------------------+            |
|                               v                                       |
|                  std::unordered_map<int, PlayerContext>              |
|                     └── groups: std::unordered_map<string, SUIGroup>  |
+-------------------------------+---------------------------------------+
                                |
                                | amx_Exec (cbCreate, cbDestroy, ...)
                                v
+-----------------------------------------------------------------------+
|                            Pawn Gamemode / AMX                        |
|                                                                       |
|   forward OnCreate(playerid);                                         |
|   forward OnDestroy(playerid);                                        |
|   forward OnShow(playerid);                                           |
|   forward OnHide(playerid);                                           |
+-----------------------------------------------------------------------+
```

---

## 2. Authoritative Data Model

The authoritative data model for group state is defined in `src/Core.hpp`:

```cpp
struct SUIGroup
{
    std::string name;
    uint64_t instanceId = 0;              // Monotonic lifecycle generation identity
    AMX* ownerAmx = nullptr;              // Script ownership handle for callback isolation
    std::string cbCreate;
    std::string cbDestroy;
    std::string cbShow;
    std::string cbHide;
    bool isCreated = false;
    bool isVisible = false;
    uint64_t hiddenSinceTick = 0;
    uint64_t lastUsedTick = 0;
    uint32_t idleTimeoutMs = 30000;
    uint32_t estimatedSize = 1;           // Logical capacity consumption
    uint8_t priority = SUI_PRIORITY_NORMAL;
    bool evictable = true;
    bool isExecutingCallback = false;     // Mutex guard against re-entrant invocation
};
```

> **Important Accounting Principle:**  
> SUI resource accounting is strictly driven by `group.estimatedSize`. The plugin does not store raw SA-MP textdraw IDs or an array of handles (`textDraws.size()`). Capacity reservations, additions, and subtractions are computed directly against `estimatedSize`.

---

## 3. Core Invariants: Generations vs. AMX Ownership

A critical architectural distinction in SUI is the strict separation between **Lifecycle Generations** and **AMX Ownership**.

### 3.1. Invariant 1: Instance Identity Protects Lifecycle Generations
- A group name (e.g. `"login_menu"`) is a map lookup key within a `PlayerContext`, not an immutable object identity.
- Every newly created logical group is assigned a unique, non-zero 64-bit monotonic `instanceId` allocated via `SUICore::TryAllocateGroupInstanceId()`.
- If an outer transaction triggers a Pawn callback, arbitrary script execution may genuinely destroy or reset the player and subsequently register a new group under the same name.
- When the outer transaction regains control from Pawn, it compares the snapshotted `instanceId` against the current group's `instanceId` via `SUICore::GetPlayerGroupIfInstance()`.
- If the IDs do not match (or the group was removed), the outer transaction safely aborts immediately. This eliminates the classic ABA problem where an outer operation continues operating on a completely different generation.

### 3.2. Invariant 2: Owner AMX Protects Script Isolation
- Every group is owned by exactly one `AMX*` instance recorded at initial registration (`group.ownerAmx = amx`).
- Callbacks (`cbCreate`, `cbDestroy`, `cbShow`, `cbHide`) dispatch strictly and exclusively to `group.ownerAmx`.
- When an AMX script unloads (e.g. `AmxUnload`), all groups owned by that AMX are immediately purged and their active capacity is reclaimed without invoking callbacks into unloaded memory.

### 3.3. Invariant 3: Generation Change Does NOT Authorize Owner Transfer
- An active callback window must never be exploited to reassign or hijack group ownership.
- While a group exists in SUI tracking, any registration attempt by a different AMX (`caller != ownerAmx`) is strictly rejected with `false` (`0` in Pawn).
- This holds true regardless of whether a callback is currently executing.

### 3.4. Invariant 4: Cross-AMX Reuse Is Allowed Only After Old Group Removal
- A group name may be registered by a different AMX script **only** after the old group has been genuinely removed from SUI state (e.g. through `SUI_ResetPlayer`, `SUI_CleanupPlayer`, or `SUI_DestroyGroup`).
- Once fully purged, the name becomes free for registration, receiving a new `instanceId` and binding cleanly to the new owning AMX.

---

## 4. Safe Factory Group Registration Semantics

`SUICore::RegisterFactoryGroup` implements the following decision tree:

```
RegisterFactoryGroup(playerId, group, amx, callbacks...):
    1. Look up player and group:
       IF group exists:
           a. IF group.ownerAmx != nullptr AND group.ownerAmx != amx:
                  REJECT (Anti-Hijack: different owner cannot touch existing group)
           b. IF group.isExecutingCallback:
                  REJECT (Re-entrancy Guard: cannot mutate group during its own callback)
           c. IF outside callbacks (!isExecutingCallback):
                  UPDATE callback configuration on existing group
                  KEEP existing instanceId, capacity, and lifecycle state
                  RETURN true
    2. IF group does NOT exist (new insertion):
           a. TryAllocateGroupInstanceId(newId) FIRST
              IF counter wrapped or allocation fails:
                  REJECT (return false, commit ZERO state)
           b. Insert new SUIGroup into player context
           c. Set instanceId = newId, ownerAmx = amx, isCreated = false, isVisible = false
           d. RETURN true
```

### Key Safety Rules
1. **No In-Place Callback Re-Registration**: Re-registering the same group name while `isExecutingCallback == true` is rejected (`return false`). This prevents phantom capacity subtractions (`SubtractActiveTextDrawCount` without actual destruction) and prevents resetting active transaction state in-flight.
2. **Atomic ID Allocation**: `TryAllocateGroupInstanceId` is invoked before modifying any map or container state. If monotonic 64-bit counter exhaustion occurs (`nextGroupInstanceId == 0`), the function returns `false` without partial mutation.
3. **Legitimate ABA Replacement**: To replace a group under the same name, the script must genuinely remove the old group first (e.g. calling `SUI_ResetPlayer` or `SUI_DestroyGroup`). The subsequent registration creates a new generation with a fresh `instanceId`. Stale outer transactions detect the mismatch and abort cleanly.

---

## 5. Callback Execution Model & Lifecycle Semantics (SUI-006)

### 5.1. Decoupling AMX Execution from Pawn Return Value
In historical revisions, `CallPawnFunction` evaluated success as `execResult == AMX_ERR_NONE && retval != 0`. This conflated the AMX virtual machine execution status with the cell returned by the Pawn script. If a script omitted a return statement (defaulting to `0`) or explicitly returned `0`, SUI treated the callback as failed and aborted the lifecycle transition.

Under SUI-006, callback success is governed by the `PawnCallResult` model:
```cpp
struct PawnCallResult {
    bool found = false;
    bool executed = false;
    int amxError = AMX_ERR_NONE;
    cell retval = 0;

    bool Success() const {
        return found && executed && amxError == AMX_ERR_NONE;
    }
};
```

### 5.2. Callback Contract
1. **Pawn Return Values Are Informational**: Return values (`0`, `1`, `42`, `-1`, etc.) are captured for diagnostic logging but do **NOT** determine whether SUI lifecycle transitions succeed. Callbacks are not veto hooks.
2. **Missing Callbacks Fail Safely**: If a callback is not defined in the owning AMX, `found` is `false`, `Success()` returns `false`, and the transition safely aborts without committing state.
3. **AMX Execution Errors Abort State Commits**: If `amx_Exec` returns an error (e.g. `AMX_ERR_DIVIDE` = 11), `Success()` returns `false`, preventing SUI from committing the state transition.
4. **Conservative State Policies on Execution Failure**:
   - **Create**: Does not mark created; does not add capacity.
   - **Show**: Does not mark visible.
   - **Hide**: Preserves existing visible state.
   - **Destroy**: Preserves created state and capacity.
5. **Activity Tracking Model**: Group idle and visibility timing are tracked explicitly via monotonic timestamps (`lastUsedTick` and `hiddenSinceTick`), ensuring predictable timeouts without relying on external clocks.

### 5.3. External Resource Transactional Limitation (SUI-018)
While SUI guarantees that its internal state machine remains consistent and aborts state transitions upon AMX execution errors, SUI does not track or manage underlying raw SA-MP textdraw IDs. If a callback partially allocates textdraws before encountering an execution error, SUI cannot automatically roll back those external host resources.

---

## 6. Player Teardown Transactions & Failure Preservation (SUI-005)

### 6.1. Teardown Phases and Mutual Exclusion
To prevent state loss, memory leaks, and infinite recursion during player teardown, `PlayerContext` maintains an explicit `PlayerTeardownState`:

```cpp
enum class PlayerTeardownState : uint8_t {
    None = 0,
    Cleanup,
    Reset
};
```

1. **Re-entrant Mutation Blocking**: When `teardownState != None`, all mutations for that player are strictly blocked:
   - `RegisterFactoryGroup`: Returns `false`. Prevents newly-created groups during `cbDestroy` from being orphaned.
   - `ShowGroup`: Returns `false`.
   - `HideGroup`: Returns `false`.
   - `SetIdleTimeout`, `SetGroupSize`, `SetMaxTextDraws`, `SetEvictionThreshold`, `SetGroupPriority`, `SetGroupEvictable`, `TouchGroup`, `EnsureCapacity`: Ignored or return `false`.
2. **Teardown Recursion Blocking**: If `SUI_CleanupPlayer` or `SUI_ResetPlayer` is invoked while `teardownState != None`, the nested call immediately returns `false` without executing or corrupting in-flight teardown iterators.

### 6.2. Two Teardown Contracts
SUI strictly differentiates between terminal disconnect cleanup and non-terminal player resets:

| Trait | `CleanupPlayer` | `ResetPlayer` |
| :--- | :--- | :--- |
| **Primary Use Case** | `OnPlayerDisconnect` | Gamemode transitions, minigame resets, character switch |
| **Snapshotted Scope** | Only groups with `isCreated == true` | Only groups with `isCreated == true` |
| **Uncreated Groups** | Pruned directly from `groups` map (no callback) | Pruned directly from `groups` map (no callback) |
| **Failed Destructions** | Logged as warning; teardown continues | **Preserved in tracking** with conservative state and capacity |
| **Final Player Context** | **Unconditionally erased** (`players.erase`) | Erased ONLY if all groups destroyed cleanly; **retained if any failed** |
| **Return Value** | `true` (1) if all destroyed cleanly; `false` (0) if any callback failed | `true` (1) if reset completed cleanly; `false` (0) if any failed |
| **Teardown State Post-Condition** | Context gone | Reset to `None` to allow script-level recovery |

### 6.3. Snapshot and Pruning Order
Both routines snapshot target groups as a vector of `{groupName, instanceId}` tuples. Uncreated groups (`isCreated == false`) are removed directly from the `groups` container before iterating, ensuring zero callbacks are invoked for unallocated resources while preventing iterator invalidation.

### 6.4. Read-Only Query Policy During Teardown
While all mutating operations (`RegisterFactoryGroup`, `ShowGroup`, `HideGroup`, `DestroyGroup`, `SetGroupSize`, etc.) are strictly rejected during active teardown, read-only diagnostic and query natives remain fully operational:
- `SUI_GetActiveTextDrawCount(playerid)`
- `SUI_IsGroupCreated(playerid, group[])`
- `SUI_IsGroupVisible(playerid, group[])`
- `SUI_IsGroupEvictable(playerid, group[])`
- `SUI_PrintPlayerState(playerid)`

These operations perform non-mutating lookups against the active `PlayerContext` and `groups` container. Callbacks executing within `cbDestroy` may query active counts or group visibility for logging or diagnostic decisions without causing recursion or mutating state.

### 6.5. Best-Effort Reset Semantics & Partial-Failure Preservation
`ResetPlayer` is fundamentally a **best-effort reset with failure preservation**, not a transactional rollback system:
- When a visible group undergoes destruction, `cbHide` is executed first.
- If `cbHide` succeeds, the group is marked hidden (`isVisible = false`) and its hidden timestamp is updated.
- If the subsequent `cbDestroy` callback fails (e.g. missing public function or AMX runtime execution error), destruction aborts.
- In this partial-failure state, the group remains created (`isCreated == true`), is marked hidden (`isVisible = false`), and its textdraw capacity remains reserved (`activeTextDrawCount` is not decremented).
- `ResetPlayer` does not attempt to "unhide" or roll back the visual transition; instead, it preserves the failed group in tracking to prevent resource leakage, restores `currentCtx->teardownState = PlayerTeardownState::None`, and returns `0` (`false`).

### 6.6. Terminal Cleanup Scope & External Resource Disclaimer
In `SUI_CleanupPlayer`, SUI unconditionally purges the internal C++ `PlayerContext` and associated container structures from plugin memory upon loop completion, ensuring zero tracking memory leaks in the plugin. However, if an external callback fails during destroy execution, host SA-MP textdraw IDs allocated inside Pawn scripts cannot be automatically reclaimed by SUI (as detailed under SUI-018).

---

## 7. Capacity Eviction Architecture & Preflight Safety (SUI-007)

### 7.1. Non-Destructive Preflight Sufficiency Guarantee
Before SUI destroys any existing hidden UI group during capacity reservation (`EnsureCapacity`), SUI computes the total eligible eviction capacity. If the total capacity of all currently eligible groups is less than the capacity required to satisfy the reservation ceiling (`min(evictionThreshold, maxTextDraws)`):
- `EnsureCapacity` returns `false` immediately.
- **Zero groups are destroyed.**
- **Zero Pawn callbacks are invoked.**
- **All existing UI groups and capacity counts are preserved intact.**

### 7.2. Eviction Eligibility and Ordering Policy
A group is eligible for capacity eviction if and only if all of the following hold:
1. `group.isCreated == true` (group is instantiated)
2. `group.isVisible == false` (group is hidden)
3. `group.isExecutingCallback == false` (group is not in-flight)
4. `group.evictable == true` (group is evictable)
5. `group.priority < SUI_PRIORITY_CRITICAL` (critical groups are never evictable)

Eligible candidates are ordered deterministically by:
1. **Priority**: Lower numerical value first (`SUI_PRIORITY_LOW` [0] < `SUI_PRIORITY_NORMAL` [1] < `SUI_PRIORITY_HIGH` [2]).
2. **Age**: Older `lastUsedTick` before newer.
3. **Deterministic Tie-Breaker**: Lexicographical `groupName < other.groupName`.

### 7.3. Policy-Minimal Ordered Eviction and Re-entrant Execution Replanning
SUI executes candidate eviction **one candidate at a time** in an iterative loop:
1. Recompute projected capacity and remaining deficit against `targetCeiling`.
2. Filter out candidates previously attempted in the current reservation transaction.
3. Verify that remaining viable candidate capacity satisfies the deficit. If not, abort safely without further destruction.
4. Evict the top-ranked candidate (`EvictCandidate`).
5. Upon callback return, reacquire player and group state by `(playerId, instanceId)`.
6. Re-evaluate overall capacity. If capacity is now satisfied, terminate successfully; otherwise, replan with updated state.

This candidate-by-candidate loop guarantees that:
- **Policy-Minimal Ordered Eviction**: SUI evicts the minimal prefix of the configured eviction policy order necessary to satisfy capacity. SUI never continues evicting after the policy order has already freed enough capacity. For example, if a request needs 15 capacity and the policy order is Candidate A (size 10), B (size 8), and C (size 100), SUI evicts A and B (freeing 18 >= 15) and stops, preserving C. SUI does NOT claim C would be selected alone merely because that minimizes total group count; eviction strictly follows policy order and halts at the first sufficient prefix.
- **Re-entrant Mutation Visibility**: Mutations performed by Pawn callbacks (e.g. changing group evictability, creating or destroying groups) are immediately observed on the next replanning iteration.
- **Destroy Failure Forward Progress**: Failed destroy callbacks are tracked in `attemptedCandidates` to prevent infinite retry loops.

### 7.4. Multi-AMX Eviction Ownership
When an eviction candidate was registered by an AMX script different from the script requesting capacity (e.g., a filterscript group evicted to make room for a gamemode group), `CallPawnFunction` invokes `cbDestroy` strictly within the candidate's `ownerAmx` context. AMX ownership is fully preserved across the eviction boundary.

### 7.5. Scope Boundaries: Static Preflight vs. Arbitrary Callback Side Effects
- **Static Insufficiency Guarantee**: At the beginning of an eviction attempt, if the currently eligible candidate set cannot free enough capacity to satisfy the deficit against `min(evictionThreshold, maxTextDraws)`, `EnsureCapacity` returns `false` before invoking any eviction callback. Zero candidate groups are destroyed, zero callbacks are executed, `activeTextDrawCount` is unchanged, and existing group states are preserved intact (verified by E1 and E2).
- **Callback-Mutation Limitation**: SUI does NOT provide full transactional rollback after arbitrary Pawn callback side effects have already occurred. If candidate A is evicted, and A's `cbDestroy` callback alters other groups (e.g. marking candidate B non-evictable) such that remaining capacity becomes insufficient, replanning aborts cleanly without destroying B, but candidate A cannot be resurrected. SUI guarantees zero destruction when insufficiency is knowable before eviction begins; it does not provide rollback once arbitrary external callbacks have executed.

---

## 8. Group Lifetime Timestamps & Tick-State Consistency (SUI-008)

### 8.1. Timestamp Semantic Separation
SUI maintains two explicit timestamps for every registered group:
1. `hiddenSinceTick`: The monotonic millisecond tick at which the group entered its current uninterrupted hidden interval (`isCreated == true && isVisible == false`).
   - When a group is visible (`isVisible == true`) or not created (`isCreated == false`), `hiddenSinceTick` is strictly inactive (`0`).
   - Used exclusively by `SUICore::ProcessTick` to determine idle expiration: `(now - group.hiddenSinceTick) >= group.idleTimeoutMs`.
2. `lastUsedTick`: The monotonic millisecond tick of most recent interaction or state change.
   - Updated upon successful show, successful hide, touch (`SUI_TouchGroup`), or fresh group creation.
   - Used by `SUICore::EnsureCapacity` as the age tie-breaker for LRU candidate eviction ordering.

### 8.2. Show Failure Lifecycle Semantics
Historically under SUI-008, when an uncreated group succeeded in its `cbCreate` callback but subsequently failed its `cbShow` callback, `hiddenSinceTick` was left at its default value `0`. Consequently, on the subsequent server tick, `ProcessTick` calculated `(currentTick - 0) >= idleTimeoutMs`, which evaluated to true for any non-zero server uptime, causing immediate, unintentional idle destruction.

To ensure deterministic lifetime management, SUI establishes the following rules:
- **Fresh-Create Show Failure**: When an uncreated group (`!wasCreatedBeforeShow`) is created by `ShowGroup` (`cbCreate` succeeds) but `cbShow` fails:
  - The group remains created but hidden (`isCreated = true, isVisible = false`).
  - SUI initializes `hiddenSinceTick = now` and `lastUsedTick = now`.
  - The group survives its configured `idleTimeoutMs` interval and is only destroyed when that interval genuinely expires.
- **Pre-Existing Hidden Show Failure**: If a group was already created and hidden (`wasCreatedBeforeShow == true`) before `ShowGroup` was invoked, and `cbShow` fails:
  - SUI preserves the existing `hiddenSinceTick` untouched.
  - This maintains continuous hidden interval accounting rather than granting an unearned lifetime reset.
- **Show Success**:
  - Sets `isVisible = true`.
  - Sets `hiddenSinceTick = 0` (inactive, as visible groups cannot expire via idle timeout).
  - Refreshes `lastUsedTick = now`.
- **Hide Success**:
  - Sets `isVisible = false`.
  - Sets `hiddenSinceTick = now` (starts fresh hidden interval countdown).
  - Sets `lastUsedTick = now`.
- **Hide Failure**:
  - Preserves `isVisible = true`.
  - Leaves `hiddenSinceTick = 0` (group is still visible; idle countdown does not begin).
- **Create Failure**:
  - Group remains uncreated (`isCreated = false, isVisible = false`).
  - Leaves `hiddenSinceTick = 0` and allocates zero capacity.
- **Zero Idle Timeout (`idleTimeoutMs == 0`)**:
  - A group configured with zero idle timeout is permitted to be destroyed on the very first tick after entering hidden state, representing intentional instantaneous idle collection.

### 8.3. Monotonic Timestamp Domain & Width Invariants
- **Monotonic 64-bit Domain**: All lifecycle timestamps (`hiddenSinceTick`, `lastUsedTick`, `Utils::GetTickCountMs()`, `ProcessTick::currentTick`, `EvictionCandidate::lastUsedTick`) are strictly defined as unsigned 64-bit integers (`uint64_t`). SUI uses `std::chrono::steady_clock`, a steady/non-decreasing clock suitable for elapsed-time measurement. Its epoch is intentionally treated as opaque; SUI depends only on differences between time points.
- **Wrap-Free Arithmetic**: A 64-bit millisecond counter requires $2^{64}$ milliseconds ($\approx 584$ million years) to wrap. Practical overflow, signed/unsigned wrap, or modular boundary inversion cannot occur during server runtime.
- **Consistent LRU Eviction Ordering**: Because `lastUsedTick` is evaluated directly in `uint64_t` space (`a.lastUsedTick < b.lastUsedTick`), long server uptimes can never cause age ordering inversions.
- **Sentinel Semantics**: State presence is governed strictly by lifecycle flags (`isCreated`, `isVisible`, and `isExecutingCallback`). `hiddenSinceTick` is non-zero whenever a group is created and hidden. `ProcessTick` directly evaluates `(currentTick - group.hiddenSinceTick) > group.idleTimeoutMs` on created-hidden groups without sentinel ambiguity.

---

## 9. Player ID Domain Validation & Trust Boundary Hardening (SUI-009)

### 9.1. Authoritative Domain Definition
SUI defines the authoritative player ID domain as:
$$0 \le \text{playerId} < \text{SUI\_MAX\_PLAYERS} \quad (\text{where } \text{SUI\_MAX\_PLAYERS} = 1000)$$
matching the legacy SA-MP 0.3.7-R2 platform limit defined in `pawno/include/a_samp.inc` (`#define MAX_PLAYERS (1000)`).
- **Valid Player IDs**: `0` through `999` (inclusive).
- **Invalid Domain**: Any integer `value < 0` or `value >= 1000`.
- **Special Sentinels**: Standard disconnected sentinels such as `INVALID_PLAYER_ID` (`65535` / `0xFFFF`), `cellmin` (`-2147483648`), and `cellmax` (`2147483647`) fall strictly within the invalid domain and are rejected.

### 9.2. Parameter Extraction & Validation Order
To prevent memory leaks, address dereference errors, and phantom state allocation, all 18 public Pawn natives that accept a `playerid` enforce a strict validation sequence at the trust boundary:
1. `Utils::CheckParams(params, expectedCount)`: Validates parameter block bounds and non-null pointers.
2. `Utils::TryGetPlayerId(params[1], playerId)`: Validates that `params[1]` falls within `[0 .. 999]`. If validation fails, SUI immediately logs a debug warning and returns `0` (or `false`).
3. Parameter Unpacking: String parameters (`amx_GetAddr`, `amx_GetString`) and numeric properties are extracted only after the player ID is validated. Zero string dereferences occur for invalid player IDs.
4. `SUICore` Entry: Operation proceeds to core business logic.

### 9.3. Phantom PlayerContext Prevention
In legacy implementations, accessing unvalidated player IDs through map subscript `players[playerId]` implicitly created default-constructed `PlayerContext` objects, permanently leaking memory in `SUICore::players`. SUI-009 hardens this by:
- Eliminating all unchecked `players[playerId]` `operator[]` lookups across setters (`SetMaxTextDraws`, `SetEvictionThreshold`) and group registration (`RegisterFactoryGroup`).
- Guarding `SUICore::GetPlayerContext(playerId)` with `!Utils::IsValidPlayerId(playerId)` check, returning `nullptr` for any invalid ID.
- Guarding all public `SUICore` entry points against invalid `playerId` values (defense in depth).

### 9.4. Cleanup and Reset Semantic Contract
- **Valid Player ID without Context**: If `SUI_CleanupPlayer(playerId)` or `SUI_ResetPlayer(playerId)` is called with a valid player ID (`0 <= playerId < 1000`) for which no `PlayerContext` exists (e.g. player never registered any UI), the function returns `true` (`1` in Pawn). This preserves the idempotent cleanup contract established in SUI-005.
- **Invalid Player ID**: If called with an invalid player ID (`playerId < 0 || playerId >= 1000`), the function returns `false` (`0` in Pawn), signaling explicit rejection at the native boundary.




