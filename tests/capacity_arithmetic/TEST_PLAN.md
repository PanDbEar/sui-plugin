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

> [!IMPORTANT]
> **Execution Environment Requirement:**
> `capacity_filterscript` must **NEVER** be preloaded in `server.cfg` under `filterscripts`. It is designed to be loaded dynamically during runtime by Test C9 via `SendRconCommand("loadfs capacity_filterscript")`. Preloading it in `server.cfg` allocates 15 textdraws prior to suite initialization, introducing an offset into initial capacity baselines and causing false-positive failures across 11 assertions. Always run with an empty `filterscripts` entry in `server.cfg`.

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

---

## 3. Phase 5.1 Accounting Gate Specifications (G1–G7)

### Test G1: Standard Bounds Validation
- **Actions**: Call `SUI_SetMaxTextDraws(0, 256)` and `SUI_SetEvictionThreshold(0, 230)`.
- **Expected**: Both calls return `1`, validating standard defaults (`230 <= 256`).

### Test G2: Threshold > Max Rejection
- **Setup**: `maxTextDraws = 256`, `evictionThreshold = 230`.
- **Actions**: Attempt `SUI_SetEvictionThreshold(0, 257)`.
- **Expected**: Rejection (`return 0`). `evictionThreshold` remains unchanged at `230`.

### Test G3: Lowering Max Below Threshold Rejection
- **Setup**: `maxTextDraws = 256`, `evictionThreshold = 230`.
- **Actions**: Attempt `SUI_SetMaxTextDraws(0, 100)` without lowering threshold first.
- **Expected**: Rejection (`return 0`). `maxTextDraws` remains unchanged at `256`.

### Test G4: Threshold Boundary Admission Check
- **Setup**: `maxTextDraws = 100`, `evictionThreshold = 90`. Show non-evictable group of size 80 -> active = 80.
- **Actions**: Attempt to show candidate group of size 15 (projected 95 > threshold 90, but < max 100).
- **Expected**: Eviction cannot free space -> `ShowGroup` fails, candidate is not created, active remains 80.
- **Cleanup**: Destroy base group.

### Test G5: Hard Max Ceiling Enforcement
- **Setup**: `maxTextDraws = 100`, `evictionThreshold = 95`. Show non-evictable group of size 95 -> active = 95.
- **Actions**: Attempt to show group of size 10 (projected 105 > maxTextDraws 100).
- **Expected**: Hard ceiling check prevents admission. `ShowGroup` fails, candidate not created, active never exceeds 95.
- **Cleanup**: Destroy base group.

### Test G6: Lowering Max Below Active Count Rejection
- **Setup**: `maxTextDraws = 256`, `evictionThreshold = 230`. Show group of size 50 -> active = 50.
- **Actions**: Lower threshold to 30, then attempt `SUI_SetMaxTextDraws(0, 40)`.
- **Expected**: Rejection (`return 0`) because `requested max (40) < active count (50)`. `maxTextDraws` remains unchanged, active count preserved at 50.
- **Cleanup**: Destroy group, reset player.

### Test G7: Invariant I1 Conservation Verification
- **Setup**: Clean player.
- **Actions**:
  - Show group 1 (size 12) + group 2 (size 18) -> active = 30.
  - Hide group 1 -> active remains 30 (hidden created groups retain allocated capacity).
  - Destroy group 2 -> active decreases to 12.
  - Reset player -> active decreases to 0.
- **Expected**: Exact conservation `activeTextDrawCount == \sum g.estimatedSize` across all lifecycle states.

