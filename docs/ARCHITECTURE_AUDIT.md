# SUI (Smart UI Virtualizer) — Architecture & Technical Audit

**Document Version:** 1.0.0 (Phase 0 Baseline)  
**Author:** Pandbear / SUI Engineering  
**Scope:** Deep architectural, safety, and runtime review of the legacy C++ plugin codebase prior to Phase 1 refactoring.

---

## 1. Executive Summary

SUI is designed as an out-of-process lifecycle and virtualization manager for per-player UI / `PlayerTextDraw` pools in SA-MP and open.mp legacy plugin mode. Rather than hooking low-level textdraw creation natives, SUI coordinates lazy creation, visibility, and idle destruction through user-defined Pawn public callbacks.

While the conceptual abstraction is sound, this Phase 0 audit identifies **critical stability, concurrency, and lifecycle vulnerabilities** in the current C++ implementation (`src/main.cpp`, `src/Core.cpp`, `src/Natives.cpp`).

Per Phase 0 guidelines, these vulnerabilities are documented here in detail to guide systematic, isolated bug fixes in Phase 1 without destabilizing the current baseline.

---

## 2. Architecture Overview

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
|  | (AmxLoad/Redirect) |   | (Param Unpacking) |   | (State Store)  |  |
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
|   forward CreateLoginTD(playerid);                                    |
|   forward DestroyLoginTD(playerid);                                   |
|   forward ShowLoginTD(playerid);                                      |
|   forward HideLoginTD(playerid);                                      |
+-----------------------------------------------------------------------+
```

---

## 3. Detailed Vulnerability & Architectural Findings

### 3.1. CRITICAL: Container Invalidation & Re-entrancy Crashes

**Location:** `src/Core.cpp:38-79` (`SUICore::ProcessTick`), `src/Core.cpp:526-573` (`SUICore::EnsureCapacity`), `src/Core.cpp:310-388` (`CleanupPlayer` / `ResetPlayer`).

#### Mechanism
In `ProcessTick`, SUI iterates over player contexts and group maps:
```cpp
for (auto& [playerId, ctx] : players)
{
    for (auto& [groupName, group] : ctx.groups)
    {
        if (!group.isVisible && group.isCreated)
        {
            if ((currentTick - group.hiddenSinceTick) > group.idleTimeoutMs)
            {
                // ...
                if (CallPawnFunction(playerId, group.cbDestroy))
                {
                    MarkGroupDestroyed(ctx, group);
                }
            }
        }
    }
}
```

During `CallPawnFunction`, execution leaves C++ and enters the Pawn virtual machine. Inside the destroy callback (or callbacks triggered in cascade), the Pawn gamemode may:
1. Call `SUI_CleanupPlayer(playerid)` or `SUI_ResetPlayer(playerid)` (e.g. if the player is disconnected or kicked). This calls `players.erase(it)` on the very map being iterated.
2. Call `SUI_CreatePlayerFactoryGroup` or `SUI_RegisterGroup`, inserting new elements into `ctx.groups`, which can trigger a hash map rehash.
3. Call `SUI_DestroyGroup` or `SUI_ShowGroup` for other groups.

#### Impact
- **Fatal Server Crash (SIGSEGV / Access Violation)**: Iterating an `std::unordered_map` while erasing or inserting elements invalidates active bucket iterators.
- The existing guard `group.isExecutingCallback` only prevents re-invoking the *same* group, providing zero protection to the outer maps or neighbouring groups.

#### Recommended Phase 1 Remediation
- Collect expired groups or actions into a deferred execution queue (`std::vector<std::pair<int, std::string>> pendingActions`).
- Drain and execute actions outside map iteration loops.
- Employ an AMX call re-entrancy depth counter or context locking.

---

### 3.2. HIGH: Non-Standard AMX Native Registration Strategy

**Location:** `src/main.cpp:76-105` (`AmxLoad`).

#### Mechanism
Instead of registering native functions with the standard SA-MP API `amx_Register(amx, natives, -1)`:
```cpp
for (int i = 0; natives[i].name != nullptr; i++)
{
    int index = -1;
    int findResult = amx_FindNative(amx, natives[i].name, &index);

    if (findResult == AMX_ERR_NONE)
    {
        amx_Redirect(amx, const_cast<char*>(natives[i].name), reinterpret_cast<ucell>(natives[i].func), nullptr);
    }
}
```

#### Impact
- `amx_FindNative` only finds natives already present in the AMX header's native table. If a script was compiled without invoking every single native directly, or if the compiler omitted unused declarations, `amx_Redirect` will fail (`result = AMX_ERR_NOTFOUND`).
- `amx_Redirect` is intended for hooking existing registered natives or replacing existing function pointers, not for primary native table registration.
- If an AMX script dynamically loads or uses wrapper libraries, natives may remain unregistered.

#### Recommended Phase 1 Remediation
- Replace manual `amx_FindNative` + `amx_Redirect` loop with standard `amx_Register(amx, natives, -1)` (or `Compat::RegisterNatives`).

---

### 3.3. HIGH: Multi-AMX Script Ownership Ambiguity

**Location:** `src/Core.cpp:926-971` (`SUICore::CallPawnFunction`), `src/Core.cpp:48` (`activeAmxInstances`).

#### Mechanism
```cpp
for (AMX* amx : activeAmxInstances)
{
    int index = -1;
    int findResult = amx_FindPublic(amx, functionName.c_str(), &index);
    if (findResult == AMX_ERR_NONE)
    {
        cell retval = 0;
        amx_Push(amx, static_cast<cell>(playerId));
        int execResult = amx_Exec(amx, &retval, index);
        return execResult == AMX_ERR_NONE && retval != 0;
    }
}
```

#### Impact
- SUI maintains a global list of `AMX*` instances (`activeAmxInstances`). When invoking a callback, it executes on the **first** AMX instance that defines the public function.
- If a gamemode and a filterscript (or two filterscripts) both register groups or define generic callback names (e.g. `CreateLoginTD`), SUI will execute the callback on whichever script was loaded first in `activeAmxInstances`, causing cross-script variable corruption.
- Furthermore, when a script is unloaded (`AmxUnload`), any groups registered by that script remain in `PlayerContext::groups`, pointing to dead callbacks.

#### Recommended Phase 1 Remediation
- Associate registered groups with their parent `AMX*` instance during `RegisterFactoryGroup`.
- Purge groups owned by an AMX instance during `AmxUnload`.

---

### 3.4. MEDIUM: Return Value Trap in Callback Execution (SUI-006 — Resolved)

**Location:** `src/Core.cpp:1588-1643`, `src/Core.hpp:47-56, 117`.

#### Mechanism
Historical implementation evaluated:
```cpp
return execResult == AMX_ERR_NONE && retval != 0;
```

#### Impact
- In Pawn programming conventions, many callbacks default to returning `0` or omit explicit return values (evaluating to 0).
- If a Pawn callback returns `0`, `CallPawnFunction` returned `false`.
- This caused SUI to treat valid executions as failures:
  - In `ShowGroup`: `group.isCreated` was not set to `true`, and active count was not updated.
  - In `EvictOneHiddenGroup`: Eviction aborted, which caused `EnsureCapacity` to fail, blocking group display.
  - In `DestroyGroupInternal`: Destruction aborted, leaving the group stuck.

#### Phase 7 Remediation (Resolved)
- Decoupled AMX virtual machine execution status (`amx_Exec == AMX_ERR_NONE`) from Pawn callback return cells.
- Implemented `struct PawnCallResult` evaluating `Success() = found && executed && amxError == AMX_ERR_NONE`.
- Pawn return cells (`0`, `1`, `42`, `-1`, or omitted returns) are recorded for diagnostic logging and ignored by lifecycle state control.
- Missing callbacks and AMX runtime execution errors fail safely without committing state.
- Verified across 13 live server test scenarios (P1–P13) with zero regressions across prior suites (79/79 cumulative assertions passing).

---

### 3.5. MEDIUM: Eager & Destructive Capacity Eviction (SUI-007)

**Location:** `src/Core.hpp:69-75, 119-121`, `src/Core.cpp:1197-1380` (`SUICore::EnsureCapacity`, `CollectEligibleEvictionCandidates`, `EvictCandidate`).

#### Historical Mechanism (Vulnerability)
```cpp
while (true)
{
    uint64_t total = (uint64_t)currentCtx->activeTextDrawCount + (uint64_t)requiredSize;
    if (total <= currentCtx->evictionThreshold && total <= currentCtx->maxTextDraws) return true;
    if (!EvictOneHiddenGroup(*currentCtx)) return false;
}
```
If a player requested capacity exceeding `min(evictionThreshold, maxTextDraws)` and total eligible hidden group capacity was less than the needed deficit, `EnsureCapacity` eagerly evicted and destroyed candidates one by one before discovering sufficiency was unachievable. Existing user UI was permanently destroyed for nothing, callbacks executed, and capacity was reclaimed, yet `ShowGroup` still returned `0`.

#### Phase 9 Remediation (Resolved)
- **Preflight Sufficiency Guarantee**: Before any candidate destruction or callback execution, SUI calculates total eligible capacity across all viable eviction candidates ($\mathcal{E}$). If $\text{Cap}(\mathcal{E}) < \Delta_{\text{needed}}$ (where $\Delta_{\text{needed}} = \text{activeTextDrawCount} + \text{requiredSize} - \min(\text{evictionThreshold}, \text{maxTextDraws})$), `EnsureCapacity` returns `false` immediately.
  - *Postconditions on static insufficiency*: Zero candidate groups destroyed, zero callbacks invoked, `activeTextDrawCount` unchanged, existing group states untouched, incoming group remains uncreated (verified by E1 and E2).
- **Candidate Eligibility**: A group is eligible if and only if `isCreated == true`, `isVisible == false`, `isExecutingCallback == false`, `evictable == true`, and `priority < SUI_PRIORITY_CRITICAL`.
- **Policy Ordering Contract**: Sorted by priority ascending (`LOW [0] < NORMAL [1] < HIGH [2]`), then `lastUsedTick` ascending (older before newer), with a deterministic lexicographical tie-breaker (`groupName < other.groupName`).
- **Policy-Minimal Ordered Eviction**: Eviction proceeds sequentially through the policy order, evicting the minimal prefix necessary to satisfy capacity and stopping immediately once the request fits (no over-eviction).
- **Generation-Safe Execution & Re-entrancy Discipline**: `EvictCandidate` acquires candidates by `(playerId, instanceId)` and sets `isExecutingCallback = true`. No iterators, pointers, or references are retained across `CallPawnFunction`. All state is reacquired by `instanceId` post-callback.
- **Candidate-by-Candidate Replanning**: After each candidate eviction, SUI replans against updated state, safely observing any re-entrant mutations (e.g. groups marked non-evictable or deleted in Pawn callbacks).
- **Destroy Failure Forward Progress**: If a candidate's `cbDestroy` fails (`PawnCallResult.Success() == false`), the group is preserved and capacity is not decremented. Attempted candidates are tracked in an `attemptedCandidates` ledger (`{groupName, instanceId}`), preventing repeated infinite attempts during the same `EnsureCapacity` call.
- **Multi-AMX Ownership**: Filterscript candidates are destroyed strictly in their `ownerAmx` context.
- **Partial Side-Effect Limitation**: Phase 9 prevents destruction when insufficiency is knowable before eviction begins (static insufficiency). If arbitrary Pawn callback side effects alter eligibility mid-transaction after candidate destruction has started, replanning aborts safely, but already-destroyed candidates cannot be rolled back (verified by E13).
- **Runtime Verification**: Verified across tests E1–E14 in `tests/eviction_preflight/` (14/14 PASS). Cumulative regression baseline across all 8 suites passes 116 / 116 (100%).

---

### 3.6. MEDIUM: State Machine Timing Anomaly on Failed Show

**Location:** `src/Core.cpp:145-217` (`SUICore::ShowGroup`).

#### Mechanism
1. A group is not yet created (`!group.isCreated`).
2. `cbCreate` succeeds -> `group.isCreated = true`.
3. `cbShow` fails (e.g. returns 0 or error) -> `group.isVisible` remains `false`.
4. However, `group.hiddenSinceTick` was initialized to `0` and is only updated in `HideGroup`.
5. On the very next tick, `ProcessTick` checks:
   `(currentTick - group.hiddenSinceTick) > group.idleTimeoutMs`
   Since `group.hiddenSinceTick == 0`, `currentTick - 0` is enormous (~millions of ms), immediately triggering auto-destroy on the next server tick.

#### Recommended Phase 1 Remediation
- Explicitly initialize `hiddenSinceTick = Utils::GetTickCountMs()` upon creation if the group does not become visible immediately.

---

### 3.7. LOW: Unbounded Player ID & Context Map Insertion

**Location:** `src/Natives.cpp`, `src/Core.cpp:390-520`.

#### Mechanism
- Multiple natives accept `int playerId` without validating whether `playerId >= 0` and `playerId < MAX_PLAYERS`.
- Functions like `SetGroupSize`, `SetGroupPriority`, and `SetMaxTextDraws` perform:
  `auto& ctx = players[playerId];`
- If an invalid player ID is queried, `std::unordered_map::operator[]` default-constructs an empty `PlayerContext` in `players`, permanently consuming memory.

#### Recommended Phase 1 Remediation
- Add validation helper `Utils::IsValidPlayerId(playerId)`.
- Use `find()` instead of `operator[]` for mutation and query operations when the player does not yet exist.

---

### 3.8. CODEBASE HYGIENE: Orphaned & Dead Code

#### `src/Component.hpp` and `src/Component.cpp`
- Implements an unfinished open.mp native component (`IComponent`, `CoreEventHandler`, `PROVIDE_UID`).
- Includes `<sdk.hpp>` from the modern open.mp C++ Component SDK, which is **not included in `lib/`**.
- It is excluded from `CMakeLists.txt` and will fail compilation if added.
- **Decision for Phase 0:** Document as experimental / non-active target; keep untouched.

#### `src/Compat.hpp`
- Defines `Compat::GetString` and `Compat::RegisterNatives`.
- Never included anywhere in `src/`.
- **Decision for Phase 0:** Preserve for Phase 1 AMX refactoring.

---

### 3.9. HIGH: Unsafe Pawn Native Parameter Validation and Signed/Unsigned Conversion (SUI-003)

**Location:** `src/Natives.cpp`, `src/Utils.hpp`.

#### Mechanism
Pawn `cell` values are signed 32-bit integers (`int32_t`). Native parameter unpacking previously cast `cell` values directly to unsigned types via `static_cast<uint32_t>(params[X])` without verifying signed bounds.
Furthermore, string parameters were retrieved via an unchecked `GetStringParam` function that never examined the return values of `amx_GetAddr`, `amx_StrLen`, or `amx_GetString`, and `CheckParams` did not protect against negative `params[0]` values.

#### Impact
- **Signed-to-Unsigned Wrap**: Supplying negative values (e.g., `-1`) wrapped around to `4294967295` in group size, idle timeout, max textdraw count, and eviction threshold. This bypassed capacity logic or caused massive timing values.
- **Out-of-Range Priority**: Priority values outside `[0..3]` were cast to `uint8_t`, breaking priority tier logic.
- **SIGSEGV / Memory Corruption**: Invalid AMX memory addresses passed into string arguments caused `amx_GetAddr` to fail with `AMX_ERR_MEMACCESS`. Without checking return codes, subsequent dereferencing caused segmentation faults.
- **Partial State Mutation**: If a multi-argument native had valid leading arguments but invalid trailing arguments, state could be partially mutated before failure.

#### Phase 4 Remediation (Resolved)
- Implemented `Utils::TryGetNonNegativeUInt32` to strictly reject negative integers before unsigned conversion.
- Implemented `Utils::TryGetPriority` strictly enforcing range `[SUI_PRIORITY_LOW (0) .. SUI_PRIORITY_CRITICAL (3)]`.
- Implemented `Utils::TryGetStringParam` validating `amx_GetAddr`, `amx_StrLen`, and `amx_GetString` error codes and distinguishing empty strings from invalid pointers.
- Hardened `Utils::CheckParams` with negative `params[0]` guards.
- Enforced atomic parameter validation in all 19 natives prior to mutating SUI core state.

---

### 3.10. MEDIUM: Capacity Arithmetic Overflow & Accounting Invariant Safety (SUI-004)

**Location:** `src/Core.cpp:320-410, 765-855, 940-975`, `src/Core.hpp:78-87`.

#### Mechanism & Reachability
1. **Unsigned 32-bit Addition Overflow**: `EnsureCapacity` evaluated `currentCtx->activeTextDrawCount + requiredSize <= currentCtx->evictionThreshold`. While single-call Pawn cell input cannot exceed `2147483647` after SUI-003, multiple group allocations accumulating $\ge 2^{32}$ caused unsigned addition to wrap modulo $2^{32}$ back around zero, falsely evaluating as smaller than `evictionThreshold` and approving excessive resource allocation.
2. **TOCTOU Size Mutation During Callback**: In `ShowGroup`, `EnsureCapacity` approved admission using `group.estimatedSize` before invoking `cbCreate`. If `cbCreate` called `SUI_SetGroupSize` to increase the size, post-callback accounting previously added the newly mutated size to `activeTextDrawCount`, completely bypassing `EnsureCapacity`.
3. **Post-Creation Size Modification Drift**: Modifying `SUI_SetGroupSize` on an already-created group altered `group.estimatedSize` without updating `activeTextDrawCount`. When the group was later destroyed, `SubtractActiveTextDrawCount` subtracted the mismatched new size, causing permanent accounting drift.
4. **Hard Maximum Ceiling vs Diagnostic Only**: Previous revisions diagnosed `sum > maxTextDraws` without failing the addition, committing active counts above `maxTextDraws`.

#### Phase 5 & 5.1 Remediation (Resolved)
- Hardened `EnsureCapacity` using widened 64-bit space (`uint64_t total = (uint64_t)active + (uint64_t)required <= (uint64_t)threshold && total <= (uint64_t)max`).
- Enforced `maxTextDraws` as a strict hard capacity ceiling in `SUICore::TryAddActiveTextDrawCount`, returning `false` without mutating accounting if `sum > maxTextDraws`.
- Enforced configuration invariant `evictionThreshold <= maxTextDraws` in `SetEvictionThreshold` and `SetMaxTextDraws`, rejecting invalid transitions (`return false`).
- Hardened `SUICore::SubtractActiveTextDrawCount` with state reconciliation via `SUICore::RecalculateActiveTextDrawCount` across tracked created groups on underflow invariant violation.
- Implemented size locking in `SUICore::SetGroupSize`: rejects mutations while a group is currently created (`isCreated == true`) or executing a lifecycle callback (`isExecutingCallback == true`).
- In `ShowGroup`, snapshotted `authorizedSize` prior to `EnsureCapacity`, bound `postGroup.estimatedSize` to `authorizedSize` on creation success, and added callback re-entrancy created-guard, guaranteeing that capacity reservation matches exact accounting addition.

---

### 3.11. HIGH: Re-entrant Group Replacement / Generation Identity Confusion (SUI-017)

**Location:** `src/Core.hpp:16, 53, 58, 62`, `src/Core.cpp` (`ShowGroup`, `HideGroup`, `DestroyGroupInternal`, `EvictOneHiddenGroup`, `ProcessTick`, `CleanupPlayer`, `ResetPlayer`).

#### Mechanism
Group names are addressable string keys within `PlayerContext::groups`, not unique object identities. When an outer lifecycle operation invokes a Pawn callback, arbitrary script code can destroy, reset, or replace that group under the exact same name. Upon returning from the callback, reacquiring the group purely by name reacquired the replacement generation (an ABA identity collision). The outer transaction would then erroneously mutate replacement state, clear re-entrancy mutex flags, or debit/credit capacity against the wrong lifetime. Raw pointer addresses could not serve as identity because `std::unordered_map` bucket node allocation reuses freed memory addresses.

#### Phase 6 & 6.1 Remediation (Initial)
- Added a private, non-Pawn-visible 64-bit `uint64_t instanceId = 0` to `SUIGroup` with monotonic plugin-lifetime allocation via `SUICore::TryAllocateGroupInstanceId()`. Counter wrap detection strictly refuses allocation on 64-bit exhaustion (`nextGroupInstanceId == 0`), guaranteeing instance IDs are never recycled.
- Enforced post-callback identity verification across all 7 callback boundaries in `ShowGroup`, `HideGroup`, `DestroyGroupInternal`, `EvictOneHiddenGroup`, and `ProcessTick`. Stale operations immediately abort upon identity mismatch without mutating replacement state or corrupting capacity accounting.
- Updated `CleanupPlayer` and `ResetPlayer` snapshots to preserve `{groupName, instanceId}` tuples. Note that while generation-aware snapshots prevent operating on replacement groups during teardown loops, final `players.erase(playerId)` semantics remain categorized under SUI-005.

---

### 3.12. HIGH: SUI-017 / SUI-002 Ownership Immutability & Safe Same-Name Replacement Integration Gate (Phase 6.2)

**Location:** `src/Core.cpp:295-365`, `tests/amx_ownership/`, `tests/group_identity/`.

#### Mechanism & Conflict Identification
Phase 6 / 6.1 introduced generation tracking but permitted in-place replacement during `isExecutingCallback == true`, allowing `pGroup.ownerAmx = amx` to be reassigned during an active callback. This introduced a direct conflict with SUI-002 ownership immutability:
1. **Callback-Window Hijacking**: A different AMX script could invoke `SUI_CreatePlayerFactoryGroup` during another script's callback and take over group ownership.
2. **Phantom Capacity Subtraction**: Calling `SubtractActiveTextDrawCount` on an in-flight replacement group without genuine destruction subtracted capacity prematurely while external SA-MP UI handles remained allocated in the server.

#### Phase 6.2 Remediation (Resolved)
- **Strict Separation of Invariants**: Established that *instance identity protects lifecycle generations*, while *owner AMX protects script isolation*. A generation change does NOT authorize owner transfer.
- **Callback-Window Re-Registration Rejected**: `SUICore::RegisterFactoryGroup` strictly rejects re-registration when `isExecutingCallback == true` (`return false`) for both same-owner and cross-owner attempts.
- **Genuine Removal Requirement**: Group replacement under the same name requires genuine removal (via `ResetPlayer`, `CleanupPlayer`, or `DestroyGroup`) before re-registration.
- **Cross-AMX Reuse After Removal**: A group name can only be acquired by a different AMX after the old group has been genuinely removed from SUI state.
- **Validate First, Commit Second**: `TryAllocateGroupInstanceId` allocates a fresh `instanceId` before any container modification or entry creation. Counter wrap (`nextGroupInstanceId == 0`) returns `false` without partial state mutation.
- **Runtime Verification**:
  - Test A7 (Anti-hijack during callback): PASS (7/7 in `amx_ownership`).
  - Tests O1 & O2 (Anti-hijack & legitimate cross-AMX reuse): PASS.
  - Tests RAG1–RAG3 (Resource accounting preservation & safe reuse): PASS.
  - Complete regression suite (66/66 assertions) PASS with 0 crashes, no observed memory corruption, and no accounting drift.

---

## 4. Risk & Severity Matrix

| ID | Issue | Severity | Target Phase |
| :--- | :--- | :--- | :--- |
| **3.1** | Container invalidation / iterator crash during Pawn callbacks | **CRITICAL** | Phase 1 (Resolved) |
| **3.2** | Non-standard native registration (`amx_Redirect`) | **HIGH** | Phase 2 (Resolved) |
| **3.3** | AMX script ownership & multi-script collision | **HIGH** | Phase 3 (Resolved) |
| **3.4** | Inverted return code failure trap in `CallPawnFunction` | **MEDIUM** | Phase 7 (Resolved) |
| **3.5** | Eager & destructive capacity eviction failure (SUI-007) | **MEDIUM** | Phase 9 (Resolved) |
| **3.6** | Immediate auto-destroy on failed show (`hiddenSinceTick == 0`) | **MEDIUM** | Phase 8 |
| **3.7** | Unchecked player ID & phantom context allocation | **LOW** | Phase 1/4 (Partially Resolved) |
| **3.8** | Orphaned open.mp component code (`Component.cpp`) | **LOW** | Future |
| **3.9** | Unsafe Pawn parameter validation and signed/unsigned conversion (SUI-003) | **HIGH** | Phase 4 (Resolved) |
| **3.10** | Capacity arithmetic overflow and accounting invariant safety (SUI-004) | **MEDIUM** | Phase 5 (Resolved) |
| **3.11** | Re-entrant group replacement / generation identity confusion (SUI-017) | **HIGH** | Phase 6 (Resolved) |
| **3.12** | SUI-017 / SUI-002 ownership immutability & safe replacement integration gate | **HIGH** | Phase 6.2 (Resolved) |
| **3.13** | In-flight callback execution error leaves partial external UI resources in indeterminate state (SUI-018) | **MEDIUM** | Phase 8 |

---

## 5. Phase Roadmap

1. **Phase 1 (SUI-001)**: Implemented safe re-entrancy and eliminated iterator invalidation across Pawn callback boundaries.
2. **Phase 2 (SUI-011)**: Transitioned from `amx_Redirect` to standard `amx_Register`.
3. **Phase 3 (SUI-002)**: Implemented strict AMX ownership, callback isolation, and safe AMX unload.
4. **Phase 4 (SUI-003)**: Hardened Pawn native input validation, bounds checking, and memory safety.
5. **Phase 5 (SUI-004)**: Hardened capacity arithmetic, overflow prevention, and accounting invariants.
6. **Phase 6 (SUI-017)**: Implemented monotonic group instance generations, ABA identity resolution, and lifecycle transaction safety.
7. **Phase 6.2 (Gate)**: Reconciled SUI-017 generation identity with SUI-002 ownership immutability and genuine removal semantics.
8. **Phase 7 (SUI-006)**: Decoupled callback return semantics from state transition success.
9. **Phase 8 (SUI-005)**: Hardened player teardown transactions (`CleanupPlayer` and `ResetPlayer`), failure preservation, and re-entrant mutation blocking.
10. **Phase 9 (SUI-007)**: Implemented non-destructive capacity eviction preflight, policy-minimal ordered eviction, and candidate-by-candidate replanning.


