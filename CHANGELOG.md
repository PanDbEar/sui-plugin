# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Fixed
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
- Created `tests/amx_ownership/TEST_PLAN.md` documenting multi-AMX ownership test scenarios A1 through A6.
- Created `tests/amx_ownership/ownership_gamemode.pwn` and `tests/amx_ownership/ownership_filterscript.pwn` verifying multi-AMX callback isolation, duplicate callback name isolation, missing callback non-fallback, anti-hijacking, and safe dynamic AMX unload with capacity repair.
- Created `tests/REENTRANCY_TEST_PLAN.md` cataloging re-entrancy test scenarios R1 through R10.
- Created `tests/reentrancy_regression.pwn` providing regression test coverage for re-entrant lifecycle operations across Pawn callbacks (compiled and verified with Pawn compiler 3.2.3664).

### Documentation
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
