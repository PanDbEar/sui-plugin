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
| **SUI-003** | Medium | Natives / Validation | Unsafe Pawn parameter validation and signed/unsigned conversion | `CONFIRMED` | Phase 1 |
| **SUI-004** | Medium | Core / Capacity | Capacity arithmetic overflow risk | `CONFIRMED` | Phase 2 |
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
| **SUI-016** | Low | Core / Resource Lifecycle | Owner-unload external UI resource cleanup limitation | `CONFIRMED` | Phase 4 |

---

## 2. Issue Details

### SUI-001: Re-entrancy / callback-driven container invalidation
- **ID:** SUI-001
- **Severity:** Critical
- **Area:** Core / Concurrency
- **Status:** FIXED — runtime regression verified
- **Technical Context:** `SUICore::players` is `std::unordered_map<int, PlayerContext>` and `PlayerContext::groups` is `std::unordered_map<std::string, SUIGroup>`. In `std::unordered_map`, element insertion can trigger a bucket rehash that invalidates all active iterators and references across the container.
- **Fix Summary:** Eliminated stale container iterator and reference lifetimes across `CallPawnFunction` boundaries. `ProcessTick`, `CleanupPlayer`, and `ResetPlayer` now use stable key snapshots (`playerIds`, `groupNames`). All continuation points (`ShowGroup`, `HideGroup`, `DestroyGroupInternal`, `EvictOneHiddenGroup`, `EnsureCapacity`) revalidate and reacquire `PlayerContext` and `SUIGroup` from stable identifiers post-callback. Erase operations utilize stable keys (`players.erase(playerId)`).
- **Lookup Helpers:** `GetPlayerContext` and `GetPlayerGroup` perform non-inserting `find()` queries. Pointers returned by these helpers are valid strictly until the next mutation/callback boundary; the helpers do not make pointers globally stable.
- **Runtime Verification:** Verified in live headless 32-bit Linux SA-MP dedicated server (`samp03svr`) executing `tests/reentrancy_regression.pwn` (scenarios R1 through R10). All 10 scenarios passed with 0 crashes, 0 memory corruption, and clean server shutdown.
- **Evidence:** `src/Core.cpp:38-52`, `src/Core.cpp:54-152`, `src/Core.cpp:183-360`, `src/Core.cpp:362-444`, `src/Core.cpp:478-590`, `src/Core.cpp:739-908`, `src/Core.cpp:910-1046`.
- **Planned phase:** Phase 1

---

### SUI-002: Missing AMX ownership / ambiguous callback routing
- **ID:** SUI-002
- **Severity:** High
- **Area:** AMX / Dispatch
- **Status:** FIXED — runtime multi-AMX regression verified
- **Fix Summary:** Implemented explicit AMX ownership on `SUIGroup` (`AMX* ownerAmx`). Native `SUI_CreatePlayerFactoryGroup` captures caller AMX and enforces anti-hijacking (rejecting registration if group is already owned by another active AMX). `CallPawnFunction` isolates lookup and execution strictly to `ownerAmx` without cross-script fallback. `AmxUnload` delegates to `SUICore::UnloadAmx`, safely purging all groups owned by the unloading AMX and repairing `activeTextDrawCount` via `SubtractActiveTextDrawCount` without invoking Pawn callbacks or disturbing other active AMX instances.
- **Runtime Verification:** Verified in headless 32-bit Linux SA-MP dedicated server (`samp03svr`) with simultaneous Gamemode (`ownership_gamemode.pwn`) and Filterscript (`ownership_filterscript.pwn`). All test cases (A1: Gamemode owner dispatch, A2: Callback name collision isolation with `SharedCallback`, A3: No fallback on missing callback, A4: Anti-hijacking registration guard, A5: Safe AMX unload and capacity repair, A6: Post-unload re-registration) PASSED (6/6). Zero regressions in SUI-001 (R1-R10 all PASS).
- **Evidence:** `src/Core.hpp:37, 58-59, 66, 99`, `src/Core.cpp:39-114, 183-196, 230-276, 353-421, 495-508, 951-968, 1059-1108, 1321-1366`, `src/Natives.cpp:15-28`, `src/main.cpp:88-97`, `tests/amx_ownership/TEST_PLAN.md`.
- **Planned phase:** Phase 3

---

### SUI-003: Unsafe Pawn parameter validation and signed/unsigned conversion
- **ID:** SUI-003
- **Severity:** Medium
- **Area:** Natives / Parameter Handling
- **Status:** CONFIRMED
- **Current behavior:** Native handlers in `src/Natives.cpp` cast parameters via `static_cast<uint32_t>(params[X])` without verifying signed bounds.
- **Risk:** Negative values passed from Pawn (e.g. `-1`) wrap around to large positive integers (e.g. `4294967295`), causing corrupted capacity counts and timer state.
- **Evidence:** `src/Natives.cpp:80, 99, 110, 123`, `src/Utils.hpp:27-29`.
- **Planned phase:** Phase 1

---

### SUI-004: Capacity arithmetic overflow risk
- **ID:** SUI-004
- **Severity:** Medium
- **Area:** Core / Capacity
- **Status:** CONFIRMED
- **Current behavior:** `EnsureCapacity` checks `ctx.activeTextDrawCount + requiredSize <= ctx.evictionThreshold` using 32-bit unsigned integers without overflow checking.
- **Risk:** Large `requiredSize` values can wrap arithmetic around zero, bypassing threshold checks.
- **Evidence:** `src/Core.cpp:533, 551`.
- **Planned phase:** Phase 2

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
- **Severity:** Low
- **Area:** Core / Resource Lifecycle
- **Status:** CONFIRMED
- **Current behavior:** When an AMX instance unloads (e.g. `AmxUnload`), SUI purges all internal group state owned by that AMX and repairs `activeTextDrawCount`. However, SUI does not track or manage underlying host SA-MP PlayerTextDraw handles (`PlayerTextDrawDestroy`).
- **Risk:** If an unloading script fails to destroy its PlayerTextDraws in `OnFilterScriptExit`, the underlying textdraw IDs remain allocated in the host server memory even though SUI has cleared its virtual tracking. Scripts must clean up their own textdraw IDs in their exit callback.
- **Planned phase:** Phase 4
