# SUI — Public API & Symbol Inventory

**Document Version:** 1.0.0 (v1.0.0 Release Baseline)  
**Type:** Engineering Synchronization Ledger  
**Primary Source Evidence:** `src/main.cpp`, `src/Natives.cpp`, `src/Natives.hpp`, `src/Core.hpp`, `pawn/sui.inc`

---

## 1. Symbol Inventory Table

| Symbol | Implemented in C++ | Registered in plugin | Declared in sui.inc | Helper/Constant | Used by Example | Documented | Status |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| `SUI_CreatePlayerFactoryGroup` | Yes | Yes (`main.cpp:15`) | Yes | Native | Yes (via stock) | Yes | `OK` |
| `SUI_ShowGroup` | Yes | Yes (`main.cpp:16`) | Yes | Native | Yes | Yes | `OK` |
| `SUI_HideGroup` | Yes | Yes (`main.cpp:17`) | Yes | Native | Yes | Yes | `OK` |
| `SUI_DestroyGroup` | Yes | Yes (`main.cpp:18`) | Yes | Native | Yes | Yes | `OK` |
| `SUI_CleanupPlayer` | Yes | Yes (`main.cpp:19`) | Yes | Native | Yes | Yes | `OK` |
| `SUI_ResetPlayer` | Yes | Yes (`main.cpp:20`) | Yes | Native | No | Yes | `OK` |
| `SUI_SetDebug` | Yes | Yes (`main.cpp:22`) | Yes | Native | No | Yes | `OK` |
| `SUI_SetIdleTimeout` | Yes | Yes (`main.cpp:23`) | Yes | Native | Yes (via stock) | Yes | `OK` |
| `SUI_SetGroupSize` | Yes | Yes (`main.cpp:25`) | Yes | Native | Yes (via stock) | Yes | `OK` |
| `SUI_GetActiveTextDrawCount` | Yes | Yes (`main.cpp:26`) | Yes | Native | Yes | Yes | `OK` |
| `SUI_SetMaxTextDraws` | Yes | Yes (`main.cpp:27`) | Yes | Native | No | Yes | `OK` |
| `SUI_SetEvictionThreshold` | Yes | Yes (`main.cpp:28`) | Yes | Native | No | Yes | `OK` |
| `SUI_SetGroupPriority` | Yes | Yes (`main.cpp:29`) | Yes | Native | Yes (via stock) | Yes | `OK` |
| `SUI_IsGroupCreated` | Yes | Yes (`main.cpp:31`) | Yes | Native | Yes | Yes | `OK` |
| `SUI_IsGroupVisible` | Yes | Yes (`main.cpp:32`) | Yes | Native | Yes | Yes | `OK` |
| `SUI_PrintPlayerState` | Yes | Yes (`main.cpp:33`) | Yes | Native | Yes | Yes | `OK` |
| `SUI_SetGroupEvictable` | Yes | Yes (`main.cpp:35`) | Yes | Native | Yes (via stock) | Yes | `OK` |
| `SUI_IsGroupEvictable` | Yes | Yes (`main.cpp:36`) | Yes | Native | No | Yes | `OK` |
| `SUI_TouchGroup` | Yes | Yes (`main.cpp:37`) | Yes | Native | No | Yes | `OK` |
| `SUI_CleanupOwnerGroups` | Yes | Yes (`main.cpp:38`) | Yes | Native | No | Yes | `OK` |
| `SUI_RegisterGroup` | No | No | Yes | Helper Stock | Yes | Yes | `HELPER` |
| `SUI_PRIORITY_LOW` | Yes (`Core.hpp:9`) | N/A | Yes | Constant (0) | No | Yes | `CONSTANT` |
| `SUI_PRIORITY_NORMAL` | Yes (`Core.hpp:10`) | N/A | Yes | Constant (1) | Yes (via stock) | Yes | `CONSTANT` |
| `SUI_PRIORITY_HIGH` | Yes (`Core.hpp:11`) | N/A | Yes | Constant (2) | Yes | Yes | `CONSTANT` |
| `SUI_PRIORITY_CRITICAL` | Yes (`Core.hpp:12`) | N/A | Yes | Constant (3) | No | Yes | `CONSTANT` |
| `SUI_SetDestroyOnDisconnect` | **No** | **No** | **No** | Native (Historical) | No | No | `MISSING_IMPLEMENTATION` |

> [!NOTE]
> `SUI_SetDestroyOnDisconnect` was declared in the pre-Phase 0 `pawn/sui.inc` but had zero backing implementation or registration in C++. It was removed from `sui.inc` during Phase 0 to maintain truthfulness.

---

## 2. Callback Interface Expectations

SUI invokes user gamemode callbacks via AMX public function resolution (`amx_FindPublic` + `amx_Exec`).

| Callback Name | Pawn Signature | Invocation Trigger | Return Semantics | Failure Behavior |
| :--- | :--- | :--- | :--- | :--- |
| `cbCreate` | `public cbCreate(playerid)` | `SUI_ShowGroup` (if uncreated) | Informational (`cell` value ignored) | If missing or `amx_Exec` fails, `group.isCreated` remains `false`; allocation aborted. |
| `cbDestroy` | `public cbDestroy(playerid)` | `ProcessTick` (idle), `DestroyGroup`, `EvictOneHiddenGroup`, `CleanupPlayer` | Informational (`cell` value ignored) | If missing or `amx_Exec` fails, state and active counts are still cleaned up to prevent capacity leaks. |
| `cbShow` | `public cbShow(playerid)` | `SUI_ShowGroup` (after create) | Informational (`cell` value ignored) | If missing or `amx_Exec` fails, show is aborted; hidden lifetime initialized via SUI-008. |
| `cbHide` | `public cbHide(playerid)` | `SUI_HideGroup`, `DestroyGroupInternal` | Informational (`cell` value ignored) | If missing or `amx_Exec` fails, hide is aborted. |

> [!NOTE]
> Following **SUI-006**, callback return values are purely informational and do not veto lifecycle state transitions. A transition succeeds if and only if `amx_Exec` returns `AMX_ERR_NONE`. This prevents accidental UI deadlocks when callbacks omit `return 1;` (evaluating to 0 in Pawn).

---

## 3. Configuration & State Defaults

The following internal default values are compiled into `src/Core.hpp` and `pawn/sui.inc`:

| Configuration Attribute | Default Value | Struct / Source Location | Pawn Configurable Via |
| :--- | :--- | :--- | :--- |
| `idleTimeoutMs` | `30000` (30 seconds) | `SUIGroup` (`src/Core.hpp:27`) | `SUI_SetIdleTimeout`, `SUI_RegisterGroup` |
| `estimatedSize` | `1` PlayerTextDraw | `SUIGroup` (`src/Core.hpp:29`) | `SUI_SetGroupSize`, `SUI_RegisterGroup` |
| `priority` | `1` (`SUI_PRIORITY_NORMAL`) | `SUIGroup` (`src/Core.hpp:30`) | `SUI_SetGroupPriority`, `SUI_RegisterGroup` |
| `evictable` | `true` | `SUIGroup` (`src/Core.hpp:31`) | `SUI_SetGroupEvictable`, `SUI_RegisterGroup` |
| `maxTextDraws` | `256` PlayerTextDraws | `PlayerContext` (`src/Core.hpp:43`) | `SUI_SetMaxTextDraws` |
| `evictionThreshold` | `230` PlayerTextDraws | `PlayerContext` (`src/Core.hpp:44`) | `SUI_SetEvictionThreshold` |
| `debugEnabled` | `false` | `SUICore` (`src/Core.hpp:53`) | `SUI_SetDebug` |

---

## 4. Helper Stock Semantics

### `SUI_RegisterGroup`
Declared in `pawn/sui.inc`:
```pawn
stock SUI_RegisterGroup(
    playerid,
    const group[],
    const cbCreate[],
    const cbDestroy[],
    const cbShow[],
    const cbHide[],
    size = 1,
    timeout_ms = 30000,
    priority = SUI_PRIORITY_NORMAL,
    bool:evictable = true
);
```
**Composition:**
Composes 5 real C++ natives sequentially:
1. `SUI_CreatePlayerFactoryGroup(playerid, group, cbCreate, cbDestroy, cbShow, cbHide)`
2. `SUI_SetGroupSize(playerid, group, size)`
3. `SUI_SetIdleTimeout(playerid, group, timeout_ms)`
4. `SUI_SetGroupPriority(playerid, group, priority)`
5. `SUI_SetGroupEvictable(playerid, group, evictable)`

**Analysis:**
The helper introduces no new runtime behavior; it is purely syntactic sugar for gamemode convenience. In Phase 12.1, 12.2, and 12.3, it was hardened following the **Prevalidated Truthful Helper model (Model B)**:
- Parameter prevalidation defends against out-of-bounds configurations (rejecting negative sizes, negative timeouts, or out-of-bounds priorities) before invoking `SUI_CreatePlayerFactoryGroup`.
- If the target group is already created (`SUI_IsGroupCreated(playerid, group) == true`), the helper returns `0` immediately before native registration, guaranteeing that live UI groups reject re-registration without mutating callback strings, visibility, or active textdraw capacity.
- If a subsequent setter fails on an uncreated group, the helper returns `0` without calling `SUI_DestroyGroup`.
- This eliminates both the destructive rollback hazard and the partial callback-mutation defect.
- Return value contract: `1` indicates complete registration and configuration success; `0` indicates any validation, registration, or setter failure.
