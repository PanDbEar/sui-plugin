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
| **SUI-005** | High | Core / Lifecycle | Reset/Cleanup state loss when destruction fails | `FIXED — runtime teardown regression verified` | Phase 8 |
| **SUI-006** | Medium | Core / AMX | Callback return-value / internal state divergence | `FIXED — runtime callback semantics verified` | Phase 7 |
| **SUI-007** | Medium | Core / Eviction | Destructive capacity eviction without pre-flight sufficiency | `FIXED — runtime eviction preflight verified` | Phase 9 |
| **SUI-008** | Medium | Core / State Machine | Failed-show hidden timestamp/state anomaly | `CONFIRMED` | Phase 1 |
| **SUI-009** | Low | Core / Validation | Player ID validation / phantom PlayerContext creation | `PARTIALLY ADDRESSED` | Phase 1 |
| **SUI-010** | Medium | API / Docs | Public API synchronization risk | `CONFIRMED` | Phase 0.1 / 1 |
| **SUI-011** | High | AMX / Loading | Non-standard AMX native registration behavior | `FIXED` | Phase 2 |
| **SUI-012** | Low | Repo / Build | Orphaned open.mp component prototype and unused header | `CONFIRMED` | Phase 3 |
| **SUI-013** | High | Repo / Git | Repository dependency / nested Git metadata handling | `RESOLVED` | Pre-Release |
| **SUI-014** | Medium | QA / Tooling | Missing automated tests and CI | `CONFIRMED` | Phase 2 |
| **SUI-015** | Medium | Build / Packaging | Release packaging not yet defined | `CONFIRMED` | Pre-Release |
| **SUI-016** | Medium | Core / Resource Lifecycle | Owner-unload external UI resource cleanup limitation | `CONFIRMED` | Phase 5 |
| **SUI-017** | High | Core / Lifecycle / Identity | Re-entrant group replacement / generation identity confusion | `FIXED — runtime regression verified` | Phase 6 |
| **SUI-018** | Medium | Core / Resource Lifecycle | In-flight callback execution error leaves partial external UI resources in indeterminate state | `CONFIRMED` | Phase 8 |

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
- **Fix Summary:** Group registration binds `SUIGroup::ownerAmx` to the originating script's `AMX*`. Callbacks dispatch strictly to `ownerAmx` without falling back to other scripts. Re-registration by any different AMX while a group exists is strictly rejected, and callback-window hijacking is completely blocked. `UnloadAmx` purges registered groups and repairs active capacity when a script unloads.
- **Runtime Verification:** Verified across A1–A7 live scenarios inside 32-bit Linux SA-MP dedicated server (`samp03svr`) (7/7 passing).
- **Evidence:** `src/Core.hpp:35`, `src/Core.cpp:55-95, 295-335, 1225-1260`, `tests/amx_ownership/`.
- **Planned phase:** Phase 3 / Phase 6.2 (Hardened)

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
  - Hardened capacity comparison in `EnsureCapacity` using widened 64-bit arithmetic (`(uint64_t)active + (uint64_t)required <= (uint64_t)threshold`), eliminating unsigned 32-bit addition wrap-around across multi-group accumulations.
  - Enforced `maxTextDraws` as a strict hard capacity ceiling: `SUICore::TryAddActiveTextDrawCount` validates `sum <= maxTextDraws` and rejects addition without mutating state; `EnsureCapacity` pre-rejects `requiredSize > maxTextDraws`.
  - Enforced configuration invariant `evictionThreshold <= maxTextDraws`: `SetEvictionThreshold` rejects `threshold > maxTextDraws`; `SetMaxTextDraws` rejects lowering `maxCount < evictionThreshold` or `maxCount < activeTextDrawCount`.
  - Hardened underflow handling in `SUICore::SubtractActiveTextDrawCount`: underflow is classified as corruption containment/recovery and initiates state reconciliation via `SUICore::RecalculateActiveTextDrawCount` across tracked created groups rather than arbitrary zero-clamping. If tracked corrupted state itself sums above `maxTextDraws`, `RecalculateActiveTextDrawCount` detects this as invariant corruption, logs `[SUI] Invariant corruption detected`, and clamps `activeTextDrawCount` to `maxTextDraws` to prevent exceeding hard capacity ceilings.
  - Implemented locking in `SUICore::SetGroupSize`: rejects size mutation while group is created (`isCreated == true`) or currently executing a lifecycle callback (`isExecutingCallback == true`), preventing TOCTOU accounting corruption during `cbCreate` and accounting drift upon destruction.
  - In `ShowGroup`, snapshotted `authorizedSize` prior to `EnsureCapacity`, bound `postGroup.estimatedSize` to `authorizedSize` upon creation success, and added callback re-entrancy created-guard, guaranteeing that capacity reservation matches exact accounting addition.
- **Runtime Verification:** Verified in live headless 32-bit Linux SA-MP dedicated server (`samp03svr`) executing `tests/capacity_arithmetic/capacity_arithmetic.pwn` (scenarios C1 through C12 and Phase 5.1 gate scenarios G1 through G7). All 19 scenarios passed with 0 crashes, 0 memory corruption, and zero accounting drift across 100 lifecycle cycles. Zero regressions in V1–V10, R1–R10, and A1–A6.
- **Evidence:** `src/Core.hpp:78-87`, `src/Core.cpp:320-410, 765-855, 940-975`, `tests/capacity_arithmetic/TEST_PLAN.md`.
- **Planned phase:** Phase 5 & Phase 5.1

---

### SUI-005: Reset/Cleanup state loss and callback creation leak
- **ID:** SUI-005
- **Severity:** High
- **Area:** Core / Lifecycle
- **Status:** FIXED — runtime teardown regression verified
- **Fix Summary:** Implemented explicit `PlayerTeardownState` (`None`, `Cleanup`, `Reset`) on `PlayerContext`. Enforced mutual exclusion blocking nested teardown recursion and blocking all re-entrant mutations (group creation, registration, show, hide, size, priority, evictability) while teardown is active, while preserving read-only diagnostic queries (`GetActiveTextDrawCount`, `IsGroupCreated`, `IsGroupVisible`, `IsGroupEvictable`, `PrintPlayerState`). Decoupled and strictly differentiated `CleanupPlayer` (terminal disconnect; snapshot created groups, prune uncreated, best-effort destroy, unconditional player purge) from `ResetPlayer` (non-terminal reset; snapshot created groups, prune uncreated, preserve groups and capacity if destroy callback fails, retain context if incomplete, restore teardown state to allow recovery). Both natives return `bool` indicating complete destruction success (`1`) vs incomplete/failed callback (`0`).
- **Runtime Verification:** Verified in live headless 32-bit Linux SA-MP dedicated server (`samp03svr`) executing `tests/player_teardown/player_teardown.pwn` with filterscript `player_teardown_filterscript.pwn` across scenarios T1 through T18. All 18 scenarios passed with no crashes or observed memory corruption in executed scenarios, and zero accounting drift. Verified zero regressions across SUI-001 (R1–R10), SUI-002 (A1–A7), SUI-003 (V1–V10), SUI-004 (C1–C12 + G1–G7), SUI-017 (ID1–ID10, H1–H4, ID-EVICT, ID-ABA-CROSS, O1, O2, RAG1–RAG3, X1–X4), and SUI-006 (P1–P13). Cumulative 102/102 runtime assertions passing across all 7 permanent test suites.
- **Evidence:** `src/Core.hpp:27-31, 38, 126-128`, `src/Core.cpp:320-335, 415-430, 480-500, 520-650`, `src/Natives.cpp:60-70`, `pawn/sui.inc`, `tests/player_teardown/`.
- **Planned phase:** Phase 8 & Phase 8.1

---

### SUI-006: Callback return-value / internal state divergence
- **ID:** SUI-006
- **Severity:** Medium
- **Area:** Core / AMX
- **Status:** FIXED — runtime callback semantics verified
- **Fix Summary:** Decoupled AMX virtual machine execution status (`amx_Exec == AMX_ERR_NONE`) from Pawn callback return cells. Implemented `PawnCallResult` evaluating `Success() = found && executed && amxError == AMX_ERR_NONE`. Pawn return values (`0`, `1`, `42`, `-1`, or omitted returns) are captured for diagnostics and ignored by lifecycle control. Missing callbacks and AMX runtime execution errors fail safely without committing state.
- **Runtime Verification:** Verified in live headless 32-bit Linux SA-MP dedicated server (`samp03svr`) executing `tests/callback_semantics/callback_semantics.pwn` with filterscript `callback_filterscript.pwn` across scenarios P1 through P13. All 13 scenarios passed with 0 crashes, 0 memory corruption, and zero accounting drift. Verified zero regressions across SUI-001 (R1–R10), SUI-002 (A1–A7), SUI-003 (V1–V10), SUI-004 (C1–C12 + G1–G7), and SUI-017 (ID1–ID10, H1–H4, ID-EVICT, O1, O2, RAG1–RAG3) with cumulative 79/79 assertions passing.
- **Evidence:** `src/Core.hpp:47-56, 117`, `src/Core.cpp:244, 470, 555, 645, 1225, 1335, 1372, 1588-1643`, `tests/callback_semantics/`.
- **Planned phase:** Phase 7

---

### SUI-007: Destructive capacity eviction without pre-flight sufficiency
- **ID:** SUI-007
- **Severity:** Medium
- **Area:** Core / Eviction
- **Status:** FIXED — runtime eviction preflight verified
- **Fix Summary:** Implemented non-destructive capacity eviction preflight in `EnsureCapacity`. Before destroying any candidate group, SUI calculates total eligible capacity across all viable eviction candidates (`isCreated && !isVisible && !isExecutingCallback && evictable && priority < CRITICAL`). If total eligible capacity cannot satisfy the capacity deficit against `min(evictionThreshold, maxTextDraws)`, `EnsureCapacity` returns `false` immediately with zero candidate destructions and zero callback invocations. SUI evicts candidates using policy-minimal ordered eviction (evicting the minimal prefix of the deterministic candidate order: priority LOW < NORMAL < HIGH, older `lastUsedTick` before newer, lexicographical groupName tie-breaker), stopping as soon as the capacity deficit is satisfied and replanning after each candidate to safely handle re-entrant callback mutations or failed destructions without infinite loops. Filterscript candidates are destroyed strictly in their `ownerAmx` script context.
- **Runtime Verification:** Verified in live headless 32-bit Linux SA-MP dedicated server (`samp03svr`) executing `tests/eviction_preflight/eviction_preflight.pwn` with filterscript `eviction_preflight_filterscript.pwn` across scenarios E1 through E14 (14/14 passing). Verified zero regressions across all 7 existing permanent test suites with cumulative 116 / 116 passing tests across 8 suites.
- **Evidence:** `src/Core.hpp:69-75, 119-121`, `src/Core.cpp:1197-1380`, `tests/eviction_preflight/`.
- **Planned phase:** Phase 9

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

---

### SUI-017: Re-entrant group replacement / generation identity confusion
- **ID:** SUI-017
- **Severity:** High
- **Area:** Core / Lifecycle / Identity
- **Status:** FIXED — runtime regression verified
- **Root Cause:** A group name is an addressable string key within a `PlayerContext`, not a unique logical lifecycle identity. If an outer lifecycle transaction (`ShowGroup`, `HideGroup`, `DestroyGroupInternal`, `EvictOneHiddenGroup`, `ProcessTick`, `CleanupPlayer`, `ResetPlayer`) invoked arbitrary Pawn code and that callback caused the group to be destroyed/reset and re-registered under the same `(playerId, groupName)`, looking up the group purely by name upon callback return re-acquired the replacement group (an ABA identity collision). The outer transaction would then proceed to mutate the replacement's state (`isCreated`, `isVisible`, `hiddenSinceTick`), improperly clear its re-entrancy mutex flag (`isExecutingCallback`), debit/credit capacity against the wrong lifetime, or erase the replacement. Raw pointer addresses could not be used as identity because `std::unordered_map` bucket node allocation reuses freed memory addresses.
- **Fix Summary:**
  - Added a private, internal 64-bit `instanceId` field to `struct SUIGroup` (non-Pawn-visible). `0` represents uninitialized/invalid.
  - Implemented a plugin-lifetime monotonic counter `SUICore::nextGroupInstanceId = 1` and allocator `SUICore::TryAllocateGroupInstanceId()`. Wrap detection refuses allocation on 64-bit exhaustion (`nextGroupInstanceId == 0`), guaranteeing IDs are never recycled.
  - In `SUICore::RegisterFactoryGroup`, validated and allocated fresh `instanceId` FIRST before mutating any state. Re-registration during active callback execution (`isExecutingCallback == true`) is strictly REJECTED (`return false`) for both same-owner and cross-owner, eliminating mid-callback state corruption and phantom capacity decrements.
  - Required genuine removal (via `ResetPlayer`, `CleanupPlayer`, or `DestroyGroup`) before a new generation can be registered under the same name. Genuine replacement receives a fresh monotonic `instanceId` and clean default state (`isCreated = false`, `isVisible = false`, `isExecutingCallback = false`).
  - Outside callbacks, benign re-registrations by the same owner update callback strings while preserving existing `instanceId` and group state.
  - Cross-AMX takeover while a group exists is strictly rejected; cross-AMX reuse is permitted only after the previous group is genuinely removed from SUI state.
  - Implemented lookup helper `SUICore::GetPlayerGroupIfInstance(playerId, groupName, instanceId)` enforcing `same name ≠ same group` unless `instanceId` also matches.
  - Audited all 7 callback boundaries across `ShowGroup` (create and show boundaries), `HideGroup` (hide boundary), `DestroyGroupInternal` (hide and destroy boundaries), `EvictOneHiddenGroup` (eviction destroy boundary), and `ProcessTick` (idle destroy boundary): outer transactions capture `instanceId`, re-verify matching identity after each callback, and immediately abort if the instance changed or was removed.
  - Aborted transactions never clear `isExecutingCallback` on replacement instances, never mutate replacement creation or visibility flags, never invoke stale subsequent callbacks, and never add or subtract accounting against replacement generations.
  - Updated `CleanupPlayer` and `ResetPlayer` candidate snapshots to record `{groupName, instanceId}` tuples, preventing identity confusion during batch group destruction (while final player context erasure semantics remain categorized under SUI-005).
- **Runtime Verification:** Verified in live headless 32-bit Linux SA-MP dedicated server (`samp03svr`) executing `tests/group_identity/group_identity.pwn` with filterscript `group_identity_filterscript.pwn` across scenarios ID1 through ID10, lifecycle reconciliation suite H1 through H4, extended ABA scenarios ID-EVICT and ID-ABA-CROSS, ownership isolation scenarios O1 and O2, resource accounting gate scenarios RAG1 through RAG3, and diagnostic reset scenarios X1 through X4. All 25 scenarios passed with 0 crashes, no observed memory corruption, and no accounting drift across rapid replacement cycles. Verified zero regressions across SUI-001 (R1–R10), SUI-002 (A1–A7), SUI-003 (V1–V10), SUI-004 (C1–C12 + G1–G7), SUI-006 (P1–P13), and SUI-005 (T1–T18) with cumulative 102/102 assertions passing across all 7 permanent test suites.
- **Evidence:** `src/Core.hpp:17, 55, 60, 66`, `src/Core.cpp:12-25, 139-160, 185-280, 295-365, 370-560, 580-660, 700-800, 1170-1230, 1260-1380`, `tests/group_identity/`, `tests/amx_ownership/`.
- **Planned phase:** Phase 6 / Phase 6.2 (Hardened)

---

### SUI-018: In-flight callback execution error leaves partial external UI resources in indeterminate state
- **ID:** SUI-018
- **Severity:** Medium
- **Area:** Core / Resource Lifecycle
- **Status:** CONFIRMED
- **Current behavior:** If a user-defined factory callback (`cbCreate`, `cbShow`, `cbHide`, `cbDestroy`) partially creates, shows, or modifies host SA-MP resources (e.g., calling `CreatePlayerTextDraw`) and subsequently triggers an AMX runtime error (e.g. division by zero, invalid array index) before completion, `amx_Exec` returns an error code. SUI safely aborts internal state transitions (refusing to mark the group created or debit capacity). However, because SUI virtualizes groups and does not own raw host `PlayerTextDraw` handles, it cannot automatically roll back or destroy partially allocated host resources.
- **Risk:** Server hosts with buggy callback logic may leak unmanaged SA-MP textdraw slots in the host server, which SUI cannot track or clean up upon disconnect/unload.
- **Distinction from SUI-016:** SUI-016 addresses script unloading (`AmxUnload`) without destroying created textdraw handles. SUI-018 addresses mid-callback AMX runtime errors causing partial external allocation before state commit.
- **Planned phase:** Phase 8


