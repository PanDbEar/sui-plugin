# SUI-006 Callback Return Semantics & Execution Status Test Plan

This document defines the test suite designed to verify **SUI-006** (Pawn Callback Return Semantics, Execution Status, and Lifecycle State Consistency).

## 1. Objective

Decouple Pawn callback return values from SUI internal state machine transitions (`ShowGroup`, `HideGroup`, `DestroyGroupInternal`, `EvictOneHiddenGroup`, `ProcessTick`):
1. Ordinary Pawn return values (`0`, `1`, `42`, `-1`, or omitted returns defaulting to `0`) must NOT accidentally abort SUI lifecycle transitions or leave internal state desynchronized from already-executed callback behavior.
2. AMX VM execution status (`amx_Exec == AMX_ERR_NONE`) determines callback success, NOT the returned cell `retval`.
3. Missing callbacks or actual AMX execution errors fail safely without corrupting internal state or committing uncreated groups.
4. Existing invariants from SUI-002 (AMX ownership isolation) and SUI-017 (generation identity) must remain strictly preserved.

---

## 2. Test Architecture & Fixtures

The suite executes inside a 32-bit Linux SA-MP dedicated server (`samp03svr`):
- **Gamemode:** `tests/callback_semantics/callback_semantics.pwn`
- **Filterscript:** `tests/callback_semantics/callback_filterscript.pwn`

---

## 3. Test Specifications (P1 - P13)

### Test P1: Create Callback - Return 1
- **Mechanism**: Group `"p1_grp"` registered with `cbCreate` returning `1`. `SUI_ShowGroup` is called.
- **Verification**: `isCreated == 1`, `isVisible == 1`, active textdraw count matches size (5), and clean destroy reduces count to 0.

### Test P2: Create Callback - Return 0
- **Mechanism**: Group `"p2_grp"` registered with `cbCreate` returning `0`. `SUI_ShowGroup` is called.
- **Verification**: `isCreated == 1`, `isVisible == 1`, active count matches size (5). Proves return 0 does NOT abort creation or prevent visibility.

### Test P3: Create Callback - No Explicit Return
- **Mechanism**: Group `"p3_grp"` registered with `cbCreate` omitting `return` (defaulting to 0 in Pawn). `SUI_ShowGroup` is called.
- **Verification**: `isCreated == 1`, `isVisible == 1`, active count matches size (5). Proves default 0 return does not cause unexpected lifecycle failure.

### Test P4: Show Callback - Return 0
- **Mechanism**: Group `"p4_grp"` registered with `cbShow` returning `0`. `SUI_ShowGroup` is called.
- **Verification**: `isVisible == 1`. Proves return 0 in `cbShow` does not veto group visibility.

### Test P5: Hide Callback - Return 0
- **Mechanism**: Group `"p5_grp"` (size 6) is shown, then `SUI_HideGroup` is called with `cbHide` returning `0`.
- **Verification**: `isVisible == 0`, `isCreated == 1`, capacity is preserved (6). Proves return 0 in `cbHide` does not prevent hide transition.

### Test P6: Destroy Callback - Return 0
- **Mechanism**: Group `"p6_grp"` (size 4) is shown, then `SUI_DestroyGroup` is called with `cbDestroy` returning `0`.
- **Verification**: `isCreated == 0`, `isVisible == 0`, capacity is released (0). Proves return 0 in `cbDestroy` does not strand the group or leak capacity.

### Test P7: ProcessTick Idle Destroy with Return 0
- **Mechanism**: Group `"p7_grp"` (size 3, idle timeout 50ms) is shown and hidden. `cbDestroy` returns `0`.
- **Verification**: After 250ms, `ProcessTick` executes idle destruction cleanly: `isCreated == 0`, capacity is released (0). The group does not become immortal.

### Test P8: Eviction Destroy with Return 0
- **Mechanism**: Candidate `"p8_cand"` (size 20, priority LOW) is hidden under threshold 50. Group `"p8_req"` (size 40) is shown, triggering eviction. Candidate's `cbDestroy` returns `0`.
- **Verification**: Eviction succeeds: `"p8_cand"` is destroyed (`isCreated == 0`), capacity released, and `"p8_req"` is created and visible with active count 40.

### Test P9: Missing Callback Handling
- **Mechanism**: Group `"p9_grp"` registered with nonexistent callback name `"DoesNotExist_Create"`. `SUI_ShowGroup` is called.
- **Verification**: Invocation fails safely: `isCreated == 0`, active count remains 0, server remains stable.

### Test P10: Same Callback, Returning Different Values
- **Mechanism**: Groups registered with callbacks returning `0`, `1`, `42`, and `-1`.
- **Verification**: All 4 groups create, show, hide, and destroy with identical lifecycle state and capacity accounting (0 -> 8 -> 8 -> 0).

### Test P11: Generation Replacement + Return 0
- **Mechanism**: During `OnP11_OldCreate`, old group is erased via `SUI_ResetPlayer`, replacement registered (size 8), and callback returns `0`.
- **Verification**: Outer `ShowGroup` aborts due to instance mismatch (SUI-017), not due to return 0. Replacement remains uncreated and can subsequently be created cleanly.

### Test P12: Cross-AMX Callback Collision with Return 0
- **Mechanism**: Gamemode and Filterscript define identical public `SharedCallback_ZeroReturn` returning `0`. Gamemode registers and shows group.
- **Verification**: Gamemode callback executes, Filterscript callback is NOT executed (SUI-002), and group becomes created/visible.

### Test P13: AMX Execution Error Safe Handling
- **Mechanism**: Callback `OnP13_ErrorCreate` triggers an AMX runtime error (division by zero).
- **Verification**: `amx_Exec` returns an error code, `CallPawnFunction` reports failure, group is NOT marked created, capacity is NOT debited, and server remains alive without memory corruption.
