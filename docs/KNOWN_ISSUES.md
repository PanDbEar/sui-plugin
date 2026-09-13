# SUI — Known Issues Ledger

**Document Version:** 1.0.0 (Phase 0.1 Baseline)  
**Type:** Authoritative Engineering Issue Tracker  
**Policy:** Do NOT fix runtime issues in Phase 0 / 0.1. All runtime issues must be addressed in subsequent planned phases.

---

## 1. Issue Matrix

| ID | Severity | Area | Title | Status | Planned Phase |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **SUI-001** | Critical | Core / Concurrency | Re-entrancy / callback-driven container invalidation | `FIXED — runtime regression verified` | Phase 1 |
| **SUI-002** | High | AMX / Dispatch | Missing AMX ownership / ambiguous callback routing | `FIXED — runtime multi-AMX regression verified` | Phase 3 |
| **SUI-003** | Medium | Natives / Validation | Unsafe Pawn parameter validation and signed/unsigned conversion | `FIXED — runtime input validation verified` | Phase 4 |
| **SUI-004** | Medium | Core / Capacity | Capacity arithmetic overflow and accounting invariant safety | `FIXED — runtime regression verified` | Phase 5 |
| **SUI-005** | High | Core / Lifecycle | Reset/Cleanup state loss when destruction fails | `CONFIRMED` | Phase 1 |
| **SUI-006** | Medium | Core / AMX | Callback return-value / internal state divergence | `CONFIRMED` | Phase 1 |
| **SUI-007** | Medium | Core / Eviction | Destructive capacity eviction without pre-flight sufficiency | `CONFIRMED` | Phase 2 |
| **SUI-008** | Medium | Core / State Machine | Failed-show hidden timestamp/state anomaly | `CONFIRMED` | Phase 1 |
| **SUI-009** | Low | Core / Validation | Player ID validation / phantom PlayerContext creation | `PARTIALLY ADDRESSED` | Phase 1 |
| **SUI-010** | Medium | API / Docs | Public API synchronization risk | `CONFIRMED` | Phase 0.1 / 1 |
| **SUI-011** | High | AMX / Loading | Non-standard AMX native registration behavior | `FIXED` | Phase 2 |
| **SUI-012** | Low | Repo / Build | Orphaned open.mp component prototype and unused header | `CONFIRMED` | Phase 3 |
| **SUI-013** | High | Repo / Git | Repository dependency / nested Git metadata handling | `RESOLVED` | Pre-Release |
| **SUI-014** | Medium | QA / Tooling | Missing automated tests and CI | `CONFIRMED` | Phase 2 |
| **SUI-015** | Medium | Build / Packaging | Release packaging not yet defined | `CONFIRMED` | Pre-Release |
| **SUI-016** | Medium | Core / Resource Lifecycle | Owner-unload external UI resource cleanup limitation | `CONFIRMED` | Phase 5 |

---

## 2. Issue Details

### SUI-001: Re-entrancy / callback-driven container invalidation
- **ID:** SUI-001
- **Severity:** Critical
- **Area:** Core / Concurrency
- **Status:** FIXED — runtime regression verified
- **Fix Summary:** Converted all raw references and iterator-dependent traversals to stable key snapshots (`playerId`, `groupName`) with post-callback re-acquisition via `GetPlayerContext` and `GetPlayerGroup`. Container modification or player context erasure during callbacks no longer triggers iterator invalidation or memory faults.
- **Runtime Verification:** Verified across R1–R10 live scenarios inside 32-bit Linux SA-MP dedicated server (`samp03svr`).
- **Evidence:** `src/Core.cpp:38-230, 310-475, 500-600, 845-920, 940-1010, 1070-1170`, `tests/reentrancy_regression.pwn`.
- **Planned phase:** Phase 1

---

### SUI-002: Missing AMX ownership / ambiguous callback routing
- **ID:** SUI-002
- **Severity:** High
- **Area:** AMX / Dispatch
- **Status:** FIXED — runtime multi-AMX regression verified
- **Fix Summary:** Group registration now binds `SUIGroup::ownerAmx` to the originating script's `AMX*`. Callbacks dispatch strictly to `ownerAmx` without falling back to other scripts. `UnloadAmx` purges registered groups and repairs active capacity when a script unloads.
- **Runtime Verification:** Verified across A1–A6 live scenarios inside 32-bit Linux SA-MP dedicated server (`samp03svr`).
- **Evidence:** `src/Core.hpp:35`, `src/Core.cpp:55-95, 1225-1260`, `tests/amx_ownership/`.
- **Planned phase:** Phase 3

---

### SUI-003: Unsafe Pawn parameter validation and signed/unsigned conversion
- **ID:** SUI-003
- **Severity:** Medium
- **Area:** Natives / Parameter Handling
- **Status:** FIXED — runtime input validation verified
- **Fix Summary:** 
  - Implemented `Utils::TryGetNonNegativeUInt32` to strictly reject negative Pawn cells (`value < 0`) before converting to unsigned `uint32_t` (`SUI_SetGroupSize`, `SUI_SetMaxTextDraws`, `SUI_SetEvictionThreshold`, `SUI_SetIdleTimeout`).
  - Implemented `Utils::TryGetPriority` enforcing range validation `[SUI_PRIORITY_LOW (0) .. SUI_PRIORITY_CRITICAL (3)]` before casting to `uint8_t` in `SUI_SetGroupPriority`.
  - Implemented `Utils::TryGetStringParam` which validates `amx_GetAddr`, `amx_StrLen`, and `amx_GetString` return codes before accessing AMX memory, distinguishing valid empty strings from invalid memory addresses (`AMX_ERR_MEMACCESS`).
  - Hardened `Utils::CheckParams` with defensive null and negative `params[0]` guards to prevent out-of-bounds parameter reads.
  - Normalized boolean parameters via standard Pawn semantics `(params[X] != 0)` in `SUI_SetDebug` and `SUI_SetGroupEvictable`.
  - Enforced atomic parameter validation across all string parameters in `SUI_CreatePlayerFactoryGroup` to ensure failed parameter extraction never partially mutates state.
- **Runtime Verification:** Verified in live headless 32-bit Linux SA-MP dedicated server (`samp03svr`) executing `tests/native_validation/native_validation.pwn` (scenarios V1 through V10). All 10 scenarios passed with 0 crashes, 0 memory corruption, and clean server shutdown. Zero regressions in SUI-001 (R1–R10) and SUI-002 (A1–A6).
- **Evidence:** `src/Utils.hpp:12-68`, `src/Natives.cpp:7-189`, `tests/native_validation/TEST_PLAN.md`.
- **Planned phase:** Phase 4

---

### SUI-004: Capacity arithmetic overflow and accounting invariant safety
- **ID:** SUI-004
- **Severity:** Medium
- **Area:** Core / Capacity
- **Status:** FIXED — runtime regression verified
- **Fix Summary:**
  - Hardened capacity comparison in `EnsureCapacity` using widened 64-bit arithmetic (`(uint64_t)active + (uint64_t)required <= (uint64_t)threshold`), eliminating unsigned 32-bit addition wrap-around.
  - Implemented `SUICore::TryAddActiveTextDrawCount` with 64-bit overflow detection and diagnostic logging; rejects addition without mutating state if overflow would occur.
  - Hardened `SUICore::SubtractActiveTextDrawCount` with diagnostic logging on underflow invariant violation and safe clamp to zero.
  - Implemented locking in `SUICore::SetGroupSize`: rejects size mutation while group is created (`isCreated == true`) or currently executing a lifecycle callback (`isExecutingCallback == true`), preventing TOCTOU accounting corruption during `cbCreate` and accounting drift upon destruction.
  - In `ShowGroup`, snapshotted `authorizedSize` prior to `EnsureCapacity` and bound `postGroup.estimatedSize` to `authorizedSize` upon creation success, guaranteeing that capacity reservation matches exact accounting addition.
- **Runtime Verification:** Verified in live headless 32-bit Linux SA-MP dedicated server (`samp03svr`) executing `tests/capacity_arithmetic/capacity_arithmetic.pwn` (scenarios C1 through C12). All 12 scenarios passed with 0 crashes, 0 memory corruption, and zero accounting drift across 100 lifecycle cycles. Zero regressions in V1–V10, R1–R10, and A1–A6.
- **Evidence:** `src/Core.hpp:78-83`, `src/Core.cpp:320-395, 705-757, 908-918`, `tests/capacity_arithmetic/TEST_PLAN.md`.
- **Planned phase:** Phase 5

---

### SUI-005: Reset/Cleanup state loss and callback creation leak
- **ID:** SUI-005
- **Severity:** High
- **Area:** Core / Lifecycle
- **Status:** CONFIRMED
- **Current behavior:** `CleanupPlayer` and `ResetPlayer` take an initial snapshot of created group names (`groupNames`), invoke `DestroyGroupInternal` on each, and subsequently call `players.erase(playerId)` unconditionally.
- **Risk:**
  1. If a destruction callback fails or returns 0, the textdraw remains allocated in the server, but SUI erases its tracking context, leading to permanent handle leakage.
  2. **Phase 1.1 Lifecycle Finding (Snapshot Creation Leak):** If a destruction callback during `CleanupPlayer` or `ResetPlayer` registers and creates a NEW group (allocating SA-MP textdraw resources), the outer cleanup routine continues executing using its pre-taken snapshot. Once the snapshot finishes, `players.erase(playerId)` destroys the `PlayerContext`. SUI completely forgets the player, but the newly spawned group's textdraws remain permanently allocated in SA-MP server memory without any tracking or cleanup.
- **Reproduction Path:** Call `SUI_CleanupPlayer(0)`. Inside `cbDestroy` of group A, script executes `SUI_CreatePlayerFactoryGroup(0, "new_group", ...)` and `SUI_ShowGroup(0, "new_group")`. Outer loop completes. `players.erase(0)` runs. Textdraws for `new_group` are orphaned in SA-MP.
- **Recommended Future Phase:** Phase 2 (Lifecycle & Cleanup State Machine Redesign).
- **Evidence:** `src/Core.cpp:494-531`, `src/Core.cpp:551-588`.
- **Planned phase:** Phase 2

---

### SUI-006: Callback return-value / internal state divergence
- **ID:** SUI-006
- **Severity:** Medium
- **Area:** Core / AMX
- **Status:** CONFIRMED
- **Current behavior:** `CallPawnFunction` requires `retval != 0` to report success.
- **Risk:** Standard Pawn callbacks that return `0` (or omit explicit returns) cause SUI to flag the callback as failed, aborting show/destroy/hide state transitions.
- **Evidence:** `src/Core.cpp:965`.
- **Planned phase:** Phase 1

---

### SUI-007: Destructive capacity eviction without pre-flight sufficiency
- **ID:** SUI-007
- **Severity:** Medium
- **Area:** Core / Eviction
- **Status:** CONFIRMED
- **Current behavior:** `EnsureCapacity` executes eviction callbacks one by one in a while loop. If total evictable textdraws cannot satisfy `requiredSize`, `EnsureCapacity` returns `false` only after already destroying candidate groups.
- **Risk:** Existing user UI is permanently destroyed even though the requested UI cannot be shown.
- **Evidence:** `src/Core.cpp:551-563`.
- **Planned phase:** Phase 2

---

### SUI-008: Failed-show hidden timestamp/state anomaly
- **ID:** SUI-008
- **Severity:** Medium
- **Area:** Core / State Machine
- **Status:** CONFIRMED
- **Current behavior:** If `cbCreate` succeeds but `cbShow` fails during `ShowGroup`, `group.isCreated` becomes `true` and `group.isVisible` remains `false`. However, `group.hiddenSinceTick` remains `0`.
- **Risk:** On the very next tick, `ProcessTick` sees `currentTick - 0 > idleTimeoutMs` (evaluating to millions of ms), immediately auto-destroying the group.
- **Evidence:** `src/Core.cpp:168-214`, `src/Core.cpp:46`.
- **Planned phase:** Phase 1

---

### SUI-009: Player ID validation / phantom PlayerContext creation
- **ID:** SUI-009
- **Severity:** Low
- **Area:** Core / Validation
- **Status:** PARTIALLY ADDRESSED
- **Phase 1 Mitigation:** Migrated group property setters (`SetGroupSize`, `SetGroupPriority`, `SetGroupEvictable`, `SetIdleTimeout`) from mutating `players[playerId]` `operator[]` lookups to defensive, non-inserting `GetPlayerContext(playerId)` queries. Querying uncreated players via these setters now gracefully fails without creating empty `PlayerContext` entries.
- **Remaining Scope:** `RegisterFactoryGroup`, `SetMaxTextDraws`, and `SetEvictionThreshold` still use mutating `players[playerId]` `operator[]` lookups. Player ID bounds checking (`0 <= playerId < MAX_PLAYERS`) is not yet implemented across any native.
- **Risk:** Accessing invalid or disconnected player IDs creates empty `PlayerContext` map entries that permanently consume memory.
- **Evidence:** `src/Core.cpp:163`, `src/Core.cpp:648`, `src/Core.cpp:672`.
- **Planned phase:** Phase 1

---

### SUI-010: Public API synchronization risk
- **ID:** SUI-010
- **Severity:** Medium
- **Area:** API / Docs
- **Status:** CONFIRMED
- **Current behavior:** Historical drift between `src/Natives.cpp`, `pawn/sui.inc`, and documentation led to undeclared natives and phantom declarations.
- **Risk:** Gamemodes cannot compile or call natives without ad-hoc declarations.
- **Evidence:** Original `pawn/sui.inc` had only 6 natives and phantom `SUI_SetDestroyOnDisconnect`.
- **Planned phase:** Phase 0.1 (Process) / Phase 1 (Verification)

---

### SUI-011: Non-standard AMX native registration behavior
- **ID:** SUI-011
- **Severity:** High
- **Area:** AMX / Loading
- **Status:** FIXED
- **Fix Summary:** Replaced non-standard `amx_FindNative` / `amx_Redirect` loop in `AmxLoad` with standard `amx_Register(amx, natives, -1)`. If registration fails, an error code is returned and the AMX instance is not tracked. Removed obsolete `#include "amx/amx2.h"` from `src/main.cpp`.
- **Runtime Verification:** Verified in live headless 32-bit Linux SA-MP dedicated server (`samp03svr`). Native resolution succeeded and eliminated `Run time error 19: "File or function is not found"`, allowing regression gamemode to load and execute all tests cleanly.
- **Evidence:** `src/main.cpp:75-89`.
- **Planned phase:** Phase 2

---

### SUI-012: Orphaned open.mp component prototype and unused header
- **ID:** SUI-012
- **Severity:** Low
- **Area:** Repo / Build
- **Status:** CONFIRMED
- **Current behavior:** `src/Component.hpp` and `src/Component.cpp` target modern open.mp `<sdk.hpp>` but are unreferenced by `CMakeLists.txt` and uncompilable without the open.mp SDK. `src/Compat.hpp` is unreferenced.
- **Risk:** Dead code drift and confusion about active plugin architecture.
- **Evidence:** `src/Component.hpp:3`, `src/Compat.hpp`, `CMakeLists.txt:15-21`.
- **Planned phase:** Phase 3

---

### SUI-013: Repository dependency / nested Git metadata handling
- **ID:** SUI-013
- **Severity:** High
- **Area:** Repo / Git
- **Status:** CONFIRMED
- **Current behavior:** `lib/samp-plugin-sdk/` contains an independent `.git` directory (`origin: https://github.com/maddinat0r/samp-plugin-sdk.git`). Root repo lacks `.gitmodules`.
- **Risk:** Incomplete recursive clones and accidental nested git repository tracking.
- **Evidence:** `lib/samp-plugin-sdk/.git`.
- **Planned phase:** Pre-Release

---

### SUI-014: Missing automated tests and CI
- **ID:** SUI-014
- **Severity:** Medium
- **Area:** QA / Tooling
- **Status:** CONFIRMED
- **Current behavior:** No unit test suite, mock AMX environment, or automated CI build workflows exist.
- **Risk:** Inability to detect regressions automatically across pull requests or platforms.
- **Evidence:** Root directory lacks test framework and CI configurations.
- **Planned phase:** Phase 2

---

### SUI-015: Release packaging not yet defined
- **ID:** SUI-015
- **Severity:** Medium
- **Area:** Build / Packaging
- **Status:** CONFIRMED
- **Current behavior:** `CMakeLists.txt` lacks installation rules (`install()`) and packaging metadata.
- **Risk:** Manual, error-prone artifact bundling for public release.
- **Evidence:** `CMakeLists.txt` has no install target.
- **Planned phase:** Pre-Release

---

### SUI-016: Owner-unload external UI resource cleanup limitation
- **ID:** SUI-016
- **Severity:** Medium
- **Area:** Core / Resource Lifecycle
- **Status:** CONFIRMED
- **Current behavior:** When an AMX instance unloads (e.g. `AmxUnload`), SUI purges all internal group state owned by that AMX and repairs `activeTextDrawCount`. However, SUI does not track or manage underlying host SA-MP PlayerTextDraw handles (`PlayerTextDrawDestroy`).
- **Risk:** In server environments where filterscripts are dynamically reloaded (e.g., administrative script updates or modular gamemode designs), if an unloading script fails to destroy its raw PlayerTextDraw handles in `OnFilterScriptExit`, those IDs remain allocated in the SA-MP host server memory. SA-MP allocates a maximum of 256 PlayerTextDraw IDs per player; repeatedly reloading scripts with unmanaged handles will eventually exhaust player textdraw pools, causing all future UI creation to fail server-wide.
- **Planned phase:** Phase 5
