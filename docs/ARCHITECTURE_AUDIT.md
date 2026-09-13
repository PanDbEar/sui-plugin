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

### 3.4. MEDIUM: Return Value Trap in Callback Execution

**Location:** `src/Core.cpp:965` (`SUICore::CallPawnFunction`).

#### Mechanism
```cpp
return execResult == AMX_ERR_NONE && retval != 0;
```

#### Impact
- In Pawn programming conventions, many callbacks default to returning `0` or omit explicit return values (evaluating to 0).
- If a Pawn callback returns `0`, `CallPawnFunction` returns `false`.
- This causes SUI to treat valid executions as failures:
  - In `ShowGroup`: `group.isCreated` is not set to `true`, and active count is not updated.
  - In `EvictOneHiddenGroup`: Eviction aborts, which causes `EnsureCapacity` to fail, blocking group display.
  - In `DestroyGroupInternal`: Destruction aborts, leaving the group stuck.

#### Recommended Phase 1 Remediation
- Decouple execution success (`execResult == AMX_ERR_NONE`) from user callback return logic, or explicitly specify return code semantics in documentation.

---

### 3.5. MEDIUM: Eager & Destructive Capacity Eviction

**Location:** `src/Core.cpp:526-573` (`SUICore::EnsureCapacity`).

#### Mechanism
```cpp
while (ctx.activeTextDrawCount + requiredSize > ctx.evictionThreshold)
{
    if (!EvictOneHiddenGroup(ctx))
    {
        return false;
    }
}
```

#### Impact
- If a player needs 50 textdraws, but only 20 textdraws can be reclaimed from hidden evictable groups:
  - SUI evicts the first candidate group (destroys it).
  - SUI evicts the second candidate group (destroys it).
  - No further evictable groups exist; `EvictOneHiddenGroup` returns `false`.
  - `EnsureCapacity` returns `false`, aborting `ShowGroup`.
- **Result:** Existing user UI was permanently destroyed for nothing, without freeing enough capacity to show the requested UI.

#### Recommended Phase 1 Remediation
- Implement a two-pass eviction algorithm:
  1. *Simulation pass*: Calculate whether total evictable hidden textdraws can satisfy `requiredSize`.
  2. *Execution pass*: Only evict if the requirement can actually be met.

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

## 4. Risk & Severity Matrix

| ID | Issue | Severity | Target Phase |
| :--- | :--- | :--- | :--- |
| **3.1** | Container invalidation / iterator crash during Pawn callbacks | **CRITICAL** | Phase 1 (Resolved) |
| **3.2** | Non-standard native registration (`amx_Redirect`) | **HIGH** | Phase 2 (Resolved) |
| **3.3** | AMX script ownership & multi-script collision | **HIGH** | Phase 3 (Resolved) |
| **3.4** | Inverted return code failure trap in `CallPawnFunction` | **MEDIUM** | Phase 5 |
| **3.5** | Eager & destructive capacity eviction failure | **MEDIUM** | Phase 5 |
| **3.6** | Immediate auto-destroy on failed show (`hiddenSinceTick == 0`) | **MEDIUM** | Phase 5 |
| **3.7** | Unchecked player ID & phantom context allocation | **LOW** | Phase 1/4 (Partially Resolved) |
| **3.8** | Orphaned open.mp component code (`Component.cpp`) | **LOW** | Future |
| **3.9** | Unsafe Pawn parameter validation and signed/unsigned conversion (SUI-003) | **HIGH** | Phase 4 (Resolved) |

---

## 5. Phase Roadmap

1. **Phase 1 (SUI-001)**: Implemented safe re-entrancy and eliminated iterator invalidation across Pawn callback boundaries.
2. **Phase 2 (SUI-011)**: Transitioned from `amx_Redirect` to standard `amx_Register`.
3. **Phase 3 (SUI-002)**: Implemented strict AMX ownership, callback isolation, and safe AMX unload.
4. **Phase 4 (SUI-003)**: Hardened Pawn native input validation, bounds checking, and memory safety.
5. **Phase 5 (SUI-006 / SUI-004)**: Callback return semantics and non-destructive capacity overflow redesign.

