# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Fixed
- **SUI-005**: Hardened player teardown transactions (`CleanupPlayer` and `ResetPlayer`), blocked re-entrant mutations, prevented recursion, and established explicit failure preservation contracts. Status: `FIXED — runtime teardown regression verified`.
  - Introduced `enum class PlayerTeardownState : uint8_t { None = 0, Cleanup, Reset }` in `PlayerContext`.
  - Enforced teardown guards across all mutation points (`RegisterFactoryGroup`, `ShowGroup`, `HideGroup`, `DestroyGroup`, `SetIdleTimeout`, `SetGroupSize`, `SetMaxTextDraws`, `SetEvictionThreshold`, `SetGroupPriority`, `SetGroupEvictable`, `TouchGroup`, `EnsureCapacity`), rejecting mutations during active teardown callbacks to prevent orphaned resources.
  - Guarded `CleanupPlayer` and `ResetPlayer` against nested re-entrant recursion (`teardownState != None`), returning `false` immediately.
  - Implemented direct pruning of uncreated groups (`isCreated == false`) from the player's group container without executing callbacks.
  - Snapshotted only created groups (`isCreated == true`) as `{groupName, instanceId}` tuples before iterating.
  - Differentiated terminal `CleanupPlayer` from non-terminal `ResetPlayer`:
    - `CleanupPlayer`: Best-effort destruction of created groups; unconditionally purges player context (`players.erase(playerId)`) upon completion; returns `true` (1) on full success, `false` (0) on any failed callback.
    - `ResetPlayer`: Destroys created groups; if any callback fails or encounters an AMX error, preserves the failed group in tracking with conservative state and active capacity preserved; player context is retained; teardown flag is restored to `None` for script-level recovery; returns `true` (1) on complete reset, `false` (0) if any group failed.
  - Updated `SUI_CleanupPlayer` and `SUI_ResetPlayer` native return values to `bool` in C++ and `1 : 0` in Pawn.
  - Verified live runtime execution on 32-bit Linux SA-MP dedicated server (`samp03svr`) with dedicated test suite `tests/player_teardown/` passing 16/16 test scenarios (T1–T16).
  - Verified cumulative 95/95 passing assertions across all test suites without regressions.
- **SUI-006**: Decoupled Pawn callback return values from SUI lifecycle state transitions and established robust callback execution semantics. Status: `FIXED — runtime callback semantics verified`.
  - Introduced `struct PawnCallResult` with explicit execution fields (`found`, `executed`, `amxError`, `retval`, `Success()`), separating execution validity (`amx_Exec == AMX_ERR_NONE`) from application-level return values.
  - Decoupled lifecycle transitions from callback return values across all 7 callback invocation points in `ShowGroup` (create & show boundaries), `HideGroup`, `DestroyGroupInternal` (hide & destroy boundaries), `EvictOneHiddenGroup`, and `ProcessTick`. Return values `0`, `1`, `42`, `-1`, or omitted `0` are treated as informational and do not abort state transitions.
  - Enforced safe, conservative state policies for missing callbacks (e.g. empty string or unexported public function) and AMX runtime execution errors:
    - Creation failure (missing callback or runtime error) prevents group creation without reserving capacity.
    - Show failure (missing callback or runtime error) preserves hidden state (`isVisible = false`).
    - Hide failure (missing callback or runtime error) preserves visible state (`isVisible = true`).
    - Destroy failure (missing callback or runtime error) aborts destruction and preserves capacity reservation.
  - Maintained complete isolation between callback execution status and SUI-002 owner AMX enforcement and SUI-017 generation tracking.
  - Preserved public Pawn API signatures in `pawn/sui.inc` without breaking changes.
  - Cataloged transactional external-resource limitation as new issue `SUI-018: In-flight callback execution error leaves partial external UI resources in indeterminate state`.
- **SUI-017 / SUI-002 (Integration Gate Phase 6.2)**: Preserved AMX ownership immutability across lifecycle generation changes and reconciled same-name group replacement semantics. Status: `FIXED — runtime regression verified`.
  - Established architectural separation: *instance identity protects lifecycle generations*, while *owner AMX protects script isolation*. Generation change does NOT authorize owner transfer.
  - In `SUICore::RegisterFactoryGroup`, strictly rejected re-registration during active callback execution (`isExecutingCallback == true`) for both same-owner and cross-owner callers (`return false`), eliminating mid-callback state corruption, callback-window takeover, and phantom capacity decrements.
  - Enforced genuine removal requirement (via `ResetPlayer`, `CleanupPlayer`, or `DestroyGroup`) before a new generation can be registered under an existing name. Genuine replacement receives a fresh monotonic `instanceId` and clean default state.
  - Enforced atomic monotonic `instanceId` allocation: `TryAllocateGroupInstanceId` validates and allocates FIRST before modifying any container or player context state. 64-bit counter exhaustion (`nextGroupInstanceId == 0`) returns `false` without state mutation.
  - Added Test A7 (Anti-Hijack Guard During Callback Execution) to permanent SUI-002 ownership suite (`tests/amx_ownership/`) with 7/7 passing assertions.
  - Added O1 (Callback-Window Anti-Hijack), O2 (Legitimate Cross-AMX Reuse After Removal), and RAG1–RAG3 (Resource Accounting Gate) to group identity suite (`tests/group_identity/`) with 20/20 passing assertions.
  - Verified 66/66 total test assertions passing across all suites on live 32-bit Linux SA-MP dedicated server (`samp03svr`) with zero crashes, no observed memory corruption, and no accounting drift.
- **SUI-017**: Hardened group lifecycle transactions against re-entrant group replacement and ABA identity confusion across Pawn callbacks. Status: `FIXED — runtime regression verified`.
  - Added unique 64-bit monotonic `uint64_t instanceId` to `SUIGroup` allocated via `SUICore::TryAllocateGroupInstanceId()`. Wrap detection refuses allocation on 64-bit exhaustion (`nextGroupInstanceId == 0`), guaranteeing instance IDs are never recycled.
  - Implemented `SUICore::GetPlayerGroupIfInstance(playerId, groupName, instanceId)` to enforce strict lifecycle generation matching (`same name != same group`).
  - Audited and secured all 7 callback boundaries across `ShowGroup`, `HideGroup`, `DestroyGroupInternal`, `EvictOneHiddenGroup`, and `ProcessTick` using transaction snapshots (`instanceId`) and post-callback generation verification. Outer operations abort immediately upon generation mismatch without mutating replacement state or prematurely resetting its callback guard.
  - Hardened multi-target lifecycle operations (`CleanupPlayer`, `ResetPlayer`) to snapshot `{groupName, instanceId}` tuples, preventing duplicate or mismatched destructions.
  - Reconciled lifecycle accounting: verified created-capacity preservation on `HideGroup` (H1) and exact single subtraction on destroy (H2, H3).
- **SUI-004**: Hardened capacity accounting and arithmetic invariants against overflow, underflow, and callback size mutation. Status: `FIXED — runtime regression verified`.
  - Converted capacity evaluation in `EnsureCapacity` to 64-bit widened space (`(uint64_t)active + (uint64_t)required <= (uint64_t)threshold && total <= (uint64_t)max`), eliminating unsigned 32-bit addition wrap-around to zero.
  - Enforced `maxTextDraws` as a strict hard capacity ceiling in `SUICore::TryAddActiveTextDrawCount` and `EnsureCapacity`, failing addition and rejecting group creation without mutating accounting if projected count exceeds `maxTextDraws`.
  - Enforced configuration invariant `evictionThreshold <= maxTextDraws`: `SetEvictionThreshold` rejects `threshold > maxTextDraws`; `SetMaxTextDraws` rejects lowering `maxCount < evictionThreshold` or `maxCount < activeTextDrawCount`.
  - Hardened `SUICore::SubtractActiveTextDrawCount` with state reconciliation via `SUICore::RecalculateActiveTextDrawCount` across tracked created groups on underflow invariant violation.
  - Implemented state-locking in `SUICore::SetGroupSize`: rejects mutation when a group is already created (`isCreated == true`) or currently executing a lifecycle callback (`isExecutingCallback == true`), eliminating TOCTOU capacity bypass during `cbCreate` and accounting drift upon destruction.
  - In `ShowGroup`, snapshotted `authorizedSize` prior to `EnsureCapacity`, bound `postGroup.estimatedSize` to `authorizedSize` upon creation success, and added callback re-entrancy created-guard, guaranteeing that capacity reservation matches exact accounting addition.
  - Verified live runtime regression execution across all scenarios C1–C12 and Phase 5.1 gate scenarios G1–G7 inside a 32-bit Linux SA-MP dedicated server (`samp03svr`) with zero accounting drift over 100 lifecycle cycles (19/19 passing).
- **SUI-003**: Hardened the Pawn → C++ native boundary with comprehensive input validation and safe type conversions across all 19 natives. Status: `FIXED — runtime input validation verified`.
  - Implemented `TryGetNonNegativeUInt32` to eliminate signed-to-unsigned wrap-around where negative Pawn cells (`-1`) were converted into `4294967295` via `static_cast<uint32_t>`. Applied to `size`, `timeout`, `maxCount`, and `threshold`.
  - Implemented `TryGetPriority` strictly constraining priority parameters to valid domain `[0..3]` (`SUI_PRIORITY_LOW` through `SUI_PRIORITY_CRITICAL`).
  - Implemented `TryGetStringParam` validating AMX address resolution and string bounds via `amx_GetAddr`, `amx_StrLen`, and `amx_GetString` error codes (e.g. `AMX_ERR_MEMACCESS`), preventing SIGSEGV crashes on invalid memory offsets.
  - Hardened `CheckParams` with negative `params[0]` guards to reject malformed AMX argument vectors.
  - Normalized boolean flags with `(params[X] != 0)` to guarantee clean truth values.
  - Enforced atomic parameter validation in all 19 native handlers prior to invoking core mutations.
  - Verified live runtime validation suite (`tests/native_validation/`) with 10/10 test scenarios (V1–V10) passing on a 32-bit Linux SA-MP dedicated server (`samp03svr`).
- **SUI-002**: Implemented strict AMX ownership, callback isolation, and safe AMX unload. Status: `FIXED — runtime multi-AMX regression verified`.
  - Added non-owning pointer `AMX* ownerAmx` to `SUIGroup` tracking the originating AMX instance.
  - Updated `SUI_CreatePlayerFactoryGroup` and `SUICore::RegisterFactoryGroup` to record caller AMX and prevent group hijacking if already owned by another active AMX.
  - Refactored `CallPawnFunction` to dispatch exclusively to `group.ownerAmx`, removing the global fallback loop across `activeAmxInstances` and ensuring complete callback isolation between Gamemode and Filterscripts.
  - Implemented `SUICore::UnloadAmx(AMX* amx)` called during `AmxUnload`, safely purging all groups registered by the unloading AMX and repairing `activeTextDrawCount` via `SubtractActiveTextDrawCount` without invoking Pawn callbacks or disturbing other scripts.
  - Verified multi-AMX isolation and dynamic unload on live 32-bit Linux SA-MP dedicated server (`samp03svr`) with 6/6 test scenarios passing.
- **SUI-001**: Resolved callback-driven re-entrancy, iterator invalidation, and use-after-free risks across all Pawn callback boundaries (`OnPlayerUIDestroyGroup`, `OnPlayerUIHideGroup`, `OnPlayerUICreateGroup`, `OnPlayerUIShowGroup`). Status: `FIXED — runtime regression verified`.
  - Eliminated iterator and raw reference survival across `CallPawnFunction` calls in `ProcessTick`, `ShowGroup`, `HideGroup`, `CleanupPlayer`, `ResetPlayer`, `EnsureCapacity`, `EvictOneHiddenGroup`, and `DestroyGroup`.
  - Replaced container traversal with stable key snapshots (`playerId`, `groupName`) and post-callback re-acquisition via `GetPlayerContext()` and `GetPlayerGroup()`.
  - Verified live runtime regression execution across all scenarios R1–R10 inside a 32-bit Linux SA-MP dedicated server (`samp03svr`).
- **SUI-011**: Corrected AMX native registration in `AmxLoad`. Replaced non-standard `amx_FindNative` / `amx_Redirect` loop with standard `amx_Register(amx, natives, -1)`, properly resolving SUI natives in the host server's AMX native table and unblocking AMX script execution (eliminating `Run time error 19: "File or function is not found"`). Removed obsolete `#include "amx/amx2.h"` from `src/main.cpp`.
- **SUI-009 (Partially Addressed)**: Replaced mutating `players[playerId]` `std::unordered_map::operator[]` lookups in group setters (`SetGroupSize`, `SetGroupPriority`, `SetGroupEvictable`, `SetIdleTimeout`) with defensive non-inserting `GetPlayerContext()` lookups to prevent phantom `PlayerContext` creation.

### Added
- Created `tests/callback_semantics/TEST_PLAN.md` documenting Pawn callback return semantics, execution status, and lifecycle consistency test scenarios P1 through P13.
- Created `tests/callback_semantics/callback_semantics.pwn` and `tests/callback_semantics/callback_filterscript.pwn` verifying informational return values (0, 1, 42, -1, omitted), safe handling of missing callbacks, AMX runtime execution error containment (division by zero), ABA generation safety, and cross-AMX isolation under return value 0.
- Created `tests/group_identity/TEST_PLAN.md` documenting group identity, lifecycle reconciliation (H1–H4), and extended ABA re-entrancy test scenarios (ID1–ID10, ID-EVICT, ID-CROSS-AMX).
- Created `tests/group_identity/group_identity.pwn` and `tests/group_identity/group_identity_filterscript.pwn` verifying ABA re-entrant replacement during callbacks (`cbCreate`, `cbShow`, `cbHide`, `cbDestroy`), transaction abort on replacement, tick processing identity safety, multi-AMX generation isolation, 100-cycle replacement stability, hide capacity preservation, visible/hidden destroy accounting order, in-place eviction replacement, and clean callback guard ownership.
- Created `tests/capacity_arithmetic/TEST_PLAN.md` documenting capacity arithmetic test scenarios C1 through C12.
- Created `tests/capacity_arithmetic/capacity_arithmetic.pwn` and `tests/capacity_arithmetic/capacity_filterscript.pwn` verifying overflow safety, underflow guards, callback size-mutation locking, exact accounting subtraction, and 100-cycle drift resistance.
- Created `tests/native_validation/TEST_PLAN.md` documenting validation test scenarios V1 through V10.
- Created `tests/native_validation/native_validation.pwn` verifying negative parameters, invalid priorities, AMX memory safety, zero-value semantics, and boundary invariants.
- Created `tests/amx_ownership/TEST_PLAN.md` documenting multi-AMX ownership test scenarios A1 through A6.
- Created `tests/amx_ownership/ownership_gamemode.pwn` and `tests/amx_ownership/ownership_filterscript.pwn` verifying multi-AMX callback isolation, duplicate callback name isolation, missing callback non-fallback, anti-hijacking, and safe dynamic AMX unload with capacity repair.
- Created `tests/REENTRANCY_TEST_PLAN.md` cataloging re-entrancy test scenarios R1 through R10.
- Created `tests/reentrancy_regression.pwn` providing regression test coverage for re-entrant lifecycle operations across Pawn callbacks (compiled and verified with Pawn compiler 3.2.3664).

### Documentation
- Updated `docs/API_REFERENCE.md`, `docs/ARCHITECTURE.md`, `docs/KNOWN_ISSUES.md`, and `docs/ARCHITECTURE_AUDIT.md` reflecting decoupled callback return semantics, `PawnCallResult` model, conservative failure policies, and cataloged SUI-018.
- Created authoritative engineering issue tracker `docs/KNOWN_ISSUES.md` cataloging issues SUI-001 through SUI-015.
- Created `docs/API_INVENTORY.md` synchronizing all C++ natives, parameters, helpers, and constants.
- Created `docs/ARCHITECTURE_AUDIT.md` providing an in-depth technical analysis of concurrency, AMX routing, and lifecycle risks.
- Created `docs/API_REFERENCE.md` documenting user-facing Pawn functions and callbacks.
- Created `docs/BUILD.md` describing compilation procedures and platform verification status.
- Created `CONTRIBUTING.md` with development rules and the Public API synchronization checklist.
- Created `SECURITY.md` establishing policies for server stability and vulnerability reporting.
- Restructured `README.md` into clean documentation reflecting truthful baseline status and deferred licensing.

### Repository
- Initialized root Git repository on branch `main` establishing an authoritative commit baseline.
- Normalized nested SDK dependency `lib/samp-plugin-sdk` as a formal Git submodule (mode `160000`) tracking upstream `https://github.com/maddinat0r/samp-plugin-sdk.git` pinned at commit `a5ce36a9b6ebbea6ad36705603f653bf3d4f41c5`.
- Added `.gitignore` covering CMake build trees, compiled binaries, Pawn outputs, and IDE configurations.
- Removed unauthorized MIT `LICENSE` file pending project owner licensing decision.
- Identified orphaned experimental sources `src/Component.hpp` and `src/Component.cpp`.

### Pawn API
- Synchronized `pawn/sui.inc` to truthfully declare all 19 C++ natives implemented in the plugin.
- Added definitions for `SUI_PRIORITY_LOW`, `SUI_PRIORITY_NORMAL`, `SUI_PRIORITY_HIGH`, and `SUI_PRIORITY_CRITICAL`.
- Added convenience stock helper `SUI_RegisterGroup`.
- Removed historical phantom native `SUI_SetDestroyOnDisconnect` from `pawn/sui.inc`.
- Updated `examples/factory_login_example.pwn` to utilize standard command processing and verified callback return values.
