# SUI-016 AMX Unload Lifecycle Cleanup Test Plan

## Overview

- **Target Issue:** SUI-016 (Owner-AMX Unload External UI Resource Cleanup Limitation)
- **Implemented Model:** Model E (Explicit Owner-AMX Pre-Unload Cleanup via `native SUI_CleanupOwnerGroups();`)
- **Suite Directory:** `tests/amx_unload_cleanup/`
- **Fixtures:**
  - Gamemode: `tests/amx_unload_cleanup/owner_cleanup_gamemode.pwn`
  - Filterscript: `tests/amx_unload_cleanup/owner_cleanup_filterscript.pwn`
- **Total Assertions:** 14 (U1–U14)

---

## Test Scenarios & Invariants

### U1: Visible Created Group Cleanup
- **Condition:** Group registered with size 5, created, and visible (`isCreated == true`, `isVisible == true`).
- **Execution:** Owner AMX invokes `SUI_CleanupOwnerGroups()`.
- **Invariants:**
  1. `cbHide` is invoked first.
  2. `cbDestroy` is invoked second.
  3. Group is marked destroyed (`isCreated == false`, `isVisible == false`).
  4. Active textdraw count decrements by 5.
  5. Native returns `1`.

### U2: Hidden Created Group Cleanup
- **Condition:** Group registered with size 3, created and shown, then hidden (`isCreated == true`, `isVisible == false`).
- **Execution:** Owner AMX invokes `SUI_CleanupOwnerGroups()`.
- **Invariants:**
  1. `cbHide` is NOT invoked (skipped because group is already hidden).
  2. `cbDestroy` is invoked.
  3. Group metadata is purged, active textdraw count decrements by 3.
  4. Native returns `1`.

### U3: Uncreated Group Cleanup
- **Condition:** Group registered with size 4, but never shown or created (`isCreated == false`).
- **Execution:** Owner AMX invokes `SUI_CleanupOwnerGroups()`.
- **Invariants:**
  1. Neither `cbHide` nor `cbDestroy` is invoked.
  2. Group metadata is purged from player context.
  3. Re-registration under the same name succeeds immediately.
  4. Active textdraw count remains unchanged (0 delta).
  5. Native returns `1`.

### U4: Mixed-Ownership Isolation
- **Condition:** Gamemode owns visible group `gm_u4_grp` (size 10); Filterscript owns visible group `fs_u4_grp` (size 7).
- **Execution:** Filterscript invokes `SUI_CleanupOwnerGroups()`.
- **Invariants:**
  1. Filterscript's group `fs_u4_grp` is hidden, destroyed, and purged.
  2. Gamemode's group `gm_u4_grp` remains created, visible, and completely untouched.
  3. Gamemode callbacks are NOT invoked.
  4. Active textdraw count decrements by exactly 7, leaving 10.
  5. Native returns `1`.

### U5: Multi-Player Context Ownership
- **Condition:** Filterscript owns groups across multiple players: player 0 (size 2) and player 1 (size 3). Both visible.
- **Execution:** Filterscript invokes `SUI_CleanupOwnerGroups()`.
- **Invariants:**
  1. Both groups across player 0 and player 1 are hidden, destroyed, and purged.
  2. Active textdraw count for player 0 drops by 2.
  3. Active textdraw count for player 1 drops by 3.
  4. Native returns `1`.

### U6: Mutation Reentrancy Rejection
- **Condition:** Visible group `u6_grp` is undergoing owner cleanup.
- **Execution:** Inside `cbDestroy`, owner AMX attempts 10 mutating SUI operations (`ShowGroup`, `HideGroup`, `DestroyGroup`, `CreatePlayerFactoryGroup`, `SetGroupSize`, `SetIdleTimeout`, `SetGroupPriority`, `SetGroupEvictable`, `TouchGroup`, `SUI_CleanupOwnerGroups`).
- **Invariants:**
  1. Caller-AMX mutation guard rejects all 10 mutation attempts (each returns `0`).
  2. No memory corruption, infinite recursion, or state inconsistency occurs.
  3. Outer cleanup transaction completes successfully and returns `1`.

### U7: Callback Failure Semantics
- **Condition:** Group `u7_grp` is visible, but its registered `cbDestroy` callback does not exist in the AMX.
- **Execution:** Owner AMX invokes `SUI_CleanupOwnerGroups()`.
- **Invariants:**
  1. Callback failure is detected.
  2. `SUI_CleanupOwnerGroups()` returns `0` (failure reported).
  3. Terminal sweep purges group metadata and repairs active textdraw accounting (no leak).
  4. Name is freed and subsequent re-registration succeeds.

### U8: Repeated Filterscript Unload & PlayerTextDraw Handle Reuse
- **Condition:** A connected NPC exists. Filterscript creates real `PlayerTextDraw` instances in `cbCreate` and destroys them via `PlayerTextDrawDestroy` in `cbDestroy`.
- **Execution:** Gamemode orchestrates 3 consecutive `loadfs` / `unloadfs` cycles where `OnFilterScriptExit` calls `SUI_CleanupOwnerGroups()`.
- **Invariants:**
  1. Each load allocates PlayerTextDraws starting from the same base handle ID.
  2. No PlayerTextDraw pool exhaustion or handle slot drift occurs across cycles.
  3. Proves actual host handle reclamation under Model E.

### U9: Nested Cleanup Rejection
- **Condition:** Owner AMX is currently executing `SUI_CleanupOwnerGroups()`.
- **Execution:** An invoked lifecycle callback calls `SUI_CleanupOwnerGroups()` again.
- **Invariants:**
  1. Nested invocation is detected via `ownerCleanupActive` set.
  2. Nested call returns `0` immediately without executing nested loops.

### U10: Zero Owned Groups (Clean No-Op)
- **Condition:** Calling AMX owns zero groups across all players.
- **Execution:** AMX calls `SUI_CleanupOwnerGroups()`.
- **Invariants:**
  1. Native executes cleanly without error.
  2. Native returns `1`.

### U11: Cross-AMX Reentrant Target Guard (Two-Layer Guard Proof)
- **Condition:** Group `u11_grp` owned by AMX A is undergoing owner cleanup.
- **Execution:** During AMX A's `cbDestroy`, AMX A calls AMX B synchronously via `CallRemoteFunction`. AMX B attempts to mutate AMX A's group (`ShowGroup`, `HideGroup`, `DestroyGroup`).
- **Invariants:**
  1. Caller AMX (AMX B) is NOT in `ownerCleanupActive`, but target owner (AMX A) IS in `ownerCleanupActive`.
  2. Target-Owner guard in `Core.cpp` intercepts and rejects all mutation attempts (return `0`).
  3. No duplicate callbacks or state corruptions occur.

### U12: Player-Teardown Collision Guard
- **Condition:** Player 0 context contains group `u12_grp` owned by AMX A, which is undergoing owner cleanup.
- **Execution:** During AMX A's `cbDestroy`, AMX B calls `SUI_CleanupPlayer(0)` or `SUI_ResetPlayer(0)`.
- **Invariants:**
  1. Player-wide teardown collision guard detects that player 0 contains a group whose owner is cleanup-active.
  2. Teardown call is rejected and returns `0`.
  3. Owner cleanup transaction proceeds to normal completion.

### U13: Hide Failure with Destroy Still Attempted (Terminal Semantics)
- **Condition:** Visible group `u13_grp` has an invalid/missing `cbHide` callback, but a valid `cbDestroy` callback.
- **Execution:** Owner AMX invokes `SUI_CleanupOwnerGroups()`.
- **Invariants:**
  1. `cbHide` execution fails (recorded).
  2. In accordance with terminal best-effort semantics, `cbDestroy` IS STILL ATTEMPTED and executes.
  3. Overall native returns `0` (because hide failed).
  4. Terminal sweep purges group metadata and decrements capacity.

### U14: Active AMX Lifetime Preservation
- **Condition:** Inside `OnFilterScriptExit()`, the filterscript invokes `SUI_CleanupOwnerGroups()`.
- **Execution:** Immediately following cleanup, still inside `OnFilterScriptExit()`, the filterscript executes a read-only SUI query (`SUI_GetActiveTextDrawCount(0)` and `SUI_IsGroupCreated(0, ...)`).
- **Invariants:**
  1. Read-only natives execute without error, returning valid data.
  2. The filterscript AMX remains valid and registered in `activeAmxInstances` until actual SA-MP host `AmxUnload` occurs.
