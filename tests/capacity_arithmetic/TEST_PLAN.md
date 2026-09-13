# SUI-004 Capacity Arithmetic & Accounting Invariants Test Plan

This document defines the regression test suite for **SUI-004** (Overflow-Safe Capacity Arithmetic and Accounting Invariants).

---

## 1. Objectives

1. **Overflow Safety**: Prove that capacity comparison (`EnsureCapacity`) and accounting addition (`TryAddActiveTextDrawCount`) cannot wrap around zero in 32-bit integer arithmetic.
2. **Underflow Protection**: Prove that `activeTextDrawCount` subtractions cannot underflow below zero and log diagnostic warnings if an invariant violation is attempted.
3. **Locking During Creation / Execution**: Verify that `SUI_SetGroupSize` cannot modify `estimatedSize` while a group is created (`isCreated == true`) or currently executing a lifecycle callback (`isExecutingCallback == true`).
4. **Exact Accounting Across Lifecycles**: Verify that `activeTextDrawCount` increases by the authorized size at creation and decreases by that exact amount upon destruction or AMX unload, preventing accounting drift.
5. **Atomic Capacity Failure**: Verify that when capacity checks fail, no internal counters or group creation flags are altered.

---

## 2. Test Specifications (C1–C12)

### Test C1: Normal Addition
- **Setup**: Active = 0, threshold = 230.
- **Actions**:
  - Show group `c1_a` (size 10) -> Expected active: `10`.
  - Show group `c1_b` (size 20) -> Expected active: `30`.
- **Cleanup**: Destroy both -> Expected active: `0`.

### Test C2: Exact Threshold
- **Setup**: Threshold = 50.
- **Actions**:
  - Show group `c2_a` (size 20) -> Expected active: `20`.
  - Show group `c2_b` (size 30) -> Total: `50 == threshold`.
- **Expected**: Show succeeds, active becomes `50`.
- **Cleanup**: Destroy both -> Expected active: `0`. Reset threshold to 230.

### Test C3: One Above Threshold
- **Setup**: Threshold = 50.
- **Actions**:
  - Show group `c3_a` (size 50, non-evictable) -> Expected active: `50`.
  - Attempt `SUI_ShowGroup` for group `c3_b` (size 1).
- **Expected**: Fails (active 50 + 1 = 51 > threshold 50). `c3_b` is not created. Active remains `50`.
- **Cleanup**: Destroy `c3_a`, `c3_b` -> Expected active: `0`. Reset threshold to 230.

### Test C4: Maximum Pawn-Positive Size (2147483647)
- **Setup**: Threshold = 230, active = 0.
- **Actions**:
  - Register group `c4_grp` with size `2147483647` (`0x7FFFFFFF`).
  - Attempt `SUI_ShowGroup(0, "c4_grp")`.
- **Expected**: Show denied cleanly. Group is not created. Active remains `0`.

### Test C5: Callback Changes Size During Create
- **Setup**: Group `c5_grp` registered with size = 1.
- **Actions**:
  - In `OnC5_Create(playerid)`, invoke `SUI_SetGroupSize(playerid, "c5_grp", 2147483647)`.
  - Call `SUI_ShowGroup(0, "c5_grp")`.
- **Expected**:
  - `SetGroupSize` returns `0` (rejected because group is executing callback).
  - Group size remains `1`.
  - Accounting records exactly authorized size `1` (`activeTextDrawCount == 1`).
- **Cleanup**: Destroy `c5_grp` -> Expected active: `0`.

### Test C6: Change Size While Created
- **Setup**: Group `c6_grp` registered with size = 5.
- **Actions**:
  - Show `c6_grp` -> active = 5.
  - Call `SUI_SetGroupSize(0, "c6_grp", 100)`.
- **Expected**:
  - `SetGroupSize` returns `0` (rejected because group is created).
  - `activeTextDrawCount` remains `5`.
- **Cleanup**: Destroy `c6_grp` -> active decreases by 5 and becomes exactly `0`.

### Test C7: Size Change While Hidden But Created
- **Setup**: Group `c7_grp` registered with size = 8.
- **Actions**:
  - Show `c7_grp`, then Hide `c7_grp` (`isCreated == true, isVisible == false`).
  - Call `SUI_SetGroupSize(0, "c7_grp", 50)`.
- **Expected**:
  - `SetGroupSize` returns `0` (rejected because group is created).
- **Cleanup**: Destroy `c7_grp` -> active decreases by 8 and becomes exactly `0`.

### Test C8: Destroy Accounting Exactness
- **Setup**: Register and show 3 groups: `c8_a` (size 5), `c8_b` (size 10), `c8_c` (size 20).
- **Actions**: Total active = 35.
  - Destroy `c8_b` (size 10) -> Expected active: `25`.
  - Destroy `c8_a` (size 5) -> Expected active: `20`.
  - Destroy `c8_c` (size 20) -> Expected active: `0`.
- **Expected**: Active count matches expected value at every step without underflow.

### Test C9: AMX Unload Accounting
- **Setup**: Load filterscript `capacity_filterscript`.
- **Actions**:
  - Filterscript creates and shows group of size 15 -> active increases by 15.
  - Unload filterscript via `unloadfs`.
- **Expected**: `UnloadAmx` purges the group and subtracts exactly 15, returning active count to prior baseline.

### Test C10: Repeated Create/Destroy Cycles
- **Setup**: Group `c10_grp` with size = 7.
- **Actions**: Perform 100 consecutive ShowGroup and DestroyGroup cycles.
- **Expected**: Active count toggles between 7 and 0; final active count after 100 cycles is exactly `0` (zero drift).

### Test C11: Capacity Failure Must Be Atomic
- **Setup**: Threshold = 230. Show baseline group `c11_base` (size 10) -> active = 10.
- **Actions**: Attempt to show `c11_oversized` (size 500).
- **Expected**: Show fails. Group is not created. Active remains exactly `10`.
- **Cleanup**: Destroy `c11_base` -> active returns to `0`.

### Test C12: Large Values / Wrap Proof
- **Setup**: Threshold = 230. Show baseline group `c12_base` (size 100) -> active = 100.
- **Actions**: Attempt to show group with size `2147483647`.
- **Expected**: Show fails (100 + 2147483647 = 2147483747 > 230). Active remains 100.
- **Cleanup**: Destroy `c12_base` -> active returns to `0`.
