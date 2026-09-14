# SUI-005: Player Teardown Transactions & Failure Preservation Test Plan

## Overview

This suite validates the deterministic player teardown architecture established in Phase 8 (SUI-005). It tests `SUI_CleanupPlayer` (terminal purge with observable failure reporting) and `SUI_ResetPlayer` (non-terminal reset with failed-state preservation), mutation blocking during active teardown, recursion prevention, uncreated group pruning, multi-AMX ownership isolation, and flag recovery.

---

## Test Scenarios

### Test T1: Normal Cleanup
- **Mechanism**: Player 0 registers 3 groups: `t1_vis` (shown, visible, size 4), `t1_hid` (shown and hidden, size 6), and `t1_unc` (never shown, uncreated, size 5). Total capacity = 10. `SUI_CleanupPlayer(0)` is invoked.
- **Verification**: All destroyable created groups are hidden/destroyed cleanly, uncreated registrations removed, context erased, capacity returns to 0, and `SUI_CleanupPlayer` returns 1.

### Test T2: Cleanup Callback Tries New Registration
- **Mechanism**: Inside `cbDestroy` of group `t2_old` during `SUI_CleanupPlayer(0)`, the callback attempts `SUI_CreatePlayerFactoryGroup(0, "t2_spawned", ...)`.
- **Verification**: The registration call is rejected (returns 0). Outer cleanup completes, context is erased, and `"t2_spawned"` does not exist.

### Test T3: Reset Callback Tries New Registration
- **Mechanism**: Inside `cbDestroy` of group `t3_old` during `SUI_ResetPlayer(0)`, the callback attempts `SUI_CreatePlayerFactoryGroup(0, "t3_spawned", ...)`.
- **Verification**: The registration call is rejected (returns 0). Outer reset completes cleanly, context is erased, and `"t3_spawned"` does not exist.

### Test T4: Reset Destroy Callback Execution Error
- **Mechanism**: Player 0 has group `t4_good` (normal destroy, size 3) and `t4_err` (cbDestroy triggers division by zero AMX error, size 5). Active capacity = 8. `SUI_ResetPlayer(0)` is invoked.
- **Verification**: `t4_good` is destroyed and capacity released (3). `t4_err` destruction fails; `t4_err` remains tracked with `isCreated == 1` and conservative capacity (5). `SUI_ResetPlayer` returns 0. PlayerContext is preserved, and `teardownState` returns to `None`.

### Test T5: Cleanup Destroy Callback Execution Error
- **Mechanism**: Player 0 has group `t5_good` (normal destroy, size 3) and `t5_err` (cbDestroy triggers division by zero, size 5). `SUI_CleanupPlayer(0)` is invoked.
- **Verification**: `t5_err` destruction fails. `SUI_CleanupPlayer` detects failure and returns 0. However, because Cleanup is terminal, PlayerContext is unconditionally purged from SUI memory.

### Test T6: Nested CleanupPlayer
- **Mechanism**: Inside `cbDestroy` of group `t6_grp` during `SUI_CleanupPlayer(0)`, the callback invokes `SUI_CleanupPlayer(0)` re-entrantly.
- **Verification**: The nested call is rejected and returns 0. Outer cleanup completes exactly once without recursion, double snapshot, or iterator invalidation.

### Test T7: Nested ResetPlayer
- **Mechanism**: Inside `cbDestroy` of group `t7_grp` during `SUI_ResetPlayer(0)`, the callback invokes `SUI_ResetPlayer(0)` re-entrantly.
- **Verification**: The nested call is rejected and returns 0. Outer reset completes cleanly without recursion.

### Test T8: ShowGroup During Teardown
- **Mechanism**: Inside `cbDestroy` of group `t8_grp` during teardown, the callback attempts `SUI_ShowGroup(0, "t8_other")`.
- **Verification**: `SUI_ShowGroup` is rejected and returns 0. No new resources are created or shown. Outer teardown continues cleanly.

### Test T9: Same-Name Re-Registration During Teardown
- **Mechanism**: Group `t9_grp` is being destroyed in teardown. Inside its callback (or after its destruction has executed), the script attempts to re-register `t9_grp`.
- **Verification**: Registration is rejected because `PlayerContext::teardownState` blocks all registrations for the player during teardown.

### Test T10: Uncreated Group Cleanup
- **Mechanism**: Group `t10_grp` is registered but never shown or created (`isCreated == 0`, size 10). `SUI_ResetPlayer(0)` is invoked.
- **Verification**: The registration is pruned directly without calling `cbCreate` or `cbDestroy`. Capacity remains 0. `SUI_ResetPlayer` returns 1.

### Test T11: Visible + Hidden Destroy Exactness
- **Mechanism**: Group `t11_vis` (visible, size 5) and `t11_hid` (hidden, size 7) have active count 12. `SUI_CleanupPlayer(0)` is invoked.
- **Verification**: `cbHide` is invoked once for `t11_vis`, `cbDestroy` is invoked once for `t11_vis`, `cbDestroy` is invoked once for `t11_hid`. Capacity is released exactly (12 -> 0) with zero drift.

### Test T12: Empty Player Context
- **Mechanism**: `SUI_CleanupPlayer(99)` and `SUI_ResetPlayer(99)` are called on an untracked/empty player.
- **Verification**: Both return 1 idempotently without errors or crashes.

### Test T13: Multi-AMX Player Teardown
- **Mechanism**: Player 0 has group `t13_gm` registered by Gamemode and group `t13_fs` registered by Filterscript. `SUI_ResetPlayer(0)` is invoked from the Gamemode.
- **Verification**: `t13_gm` callbacks execute only in Gamemode; `t13_fs` callbacks execute only in Filterscript. Both destroy cleanly, capacity returns to 0, and `SUI_ResetPlayer` returns 1.

### Test T14: Missing Destroy Callback During Reset
- **Mechanism**: Group `t14_grp` is created, but its `cbDestroy` specifies a nonexistent public function `"NonExistent_Destroy"`. `SUI_ResetPlayer(0)` is called.
- **Verification**: `DestroyGroupInternal` fails safely. `SUI_ResetPlayer` returns 0. `t14_grp` remains tracked with conservative capacity preserved.

### Test T15: Missing Destroy Callback During Cleanup
- **Mechanism**: Group `t15_grp` is created with nonexistent `cbDestroy`. `SUI_CleanupPlayer(0)` is called.
- **Verification**: Destruction fails safely. `SUI_CleanupPlayer` returns 0 (observable failure), but internal PlayerContext is nevertheless purged.

### Test T16: Teardown Flag Recovery
- **Mechanism**: Group `t16_fail` triggers Reset failure (via missing destroy callback). `SUI_ResetPlayer(0)` returns 0. Immediately afterward:
  1. Verify `t16_fail` is still created (`SUI_IsGroupCreated == 1`).
  2. Register a new group `t16_recovered` (must succeed because `teardownState` returned to `None`).
  3. Show `t16_recovered` (must succeed).
  4. Manually destroy `t16_recovered`.
  5. Call `SUI_CleanupPlayer(0)` to purge player cleanly.
- **Verification**: Proves player is not permanently locked in teardown after a failed reset.
