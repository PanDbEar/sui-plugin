# SUI-017 Group Identity and Lifecycle Generations Test Plan

This document defines the test suite designed to verify **SUI-017** (Re-entrant Group Replacement, ABA Identity, and Lifecycle Transaction Safety).

---

## 1. Objectives

1. **Monotonic Lifecycle Generation Identity**:
   Every logical `SUIGroup` instance receives a globally unique, monotonically increasing 64-bit `instanceId`. Name alone is never trusted across Pawn callback execution.
2. **Safe Callback Abort on Replacement**:
   If an outer lifecycle operation (`ShowGroup`, `HideGroup`, `DestroyGroupInternal`, `EvictOneHiddenGroup`, `ProcessTick`, `CleanupPlayer`, `ResetPlayer`) invokes a Pawn callback and that callback deletes or replaces the group under the same `(playerId, groupName)`, the outer operation detects the identity change and aborts immediately without mutating or corrupting the replacement group.
3. **No Flag Leaks or Stale Mutex Clearing**:
   `isExecutingCallback` is only cleared on the exact instance that initiated the callback, preventing re-entrancy guard corruption on replacement generations.
4. **Capacity Accounting Integrity**:
   Aborted lifecycle operations never credit or debit capacity against replacement generations. Invariant I1 (`activeTextDrawCount == sum(created groups)`) and I2 (`activeTextDrawCount <= maxTextDraws`) remain strictly satisfied.
5. **Cross-AMX Identity Discrimination**:
   Even if a replacement group belongs to a different AMX instance, SUI discriminates via `instanceId` and prevents foreign outer transactions from continuing on the new group.

---

## 2. Test Suite Architecture

The test suite consists of two scripts running on a live SA-MP 0.3.7 server:

1. **group_identity.pwn**:
   The primary test gamemode. Implements test cases ID1 through ID10, runs state machine assertions, coordinates with the filterscript for cross-AMX tests, and reports individual and overall PASS/FAIL statuses.
2. **group_identity_filterscript.pwn**:
   A secondary filterscript AMX instance used to verify cross-AMX identity isolation (ID7).

---

## 3. Test Cases Specification

### ID1: Create Callback Reset + Same-Name Replacement
- **Mechanism**: In `cbCreate` of `"id1"`, Pawn resets the player and re-registers `"id1"` with new callbacks.
- **Verification**: Outer `ShowGroup` detects `instanceId` mismatch and aborts. Old `cbShow` never executes. Replacement remains in an uncreated state (`isCreated == 0`, `activeTD == 0`). Subsequent explicit `ShowGroup` on the replacement works normally.

### ID2: Hide Callback Same-Name Replacement
- **Mechanism**: In `cbHide` of visible group `"id2"`, Pawn resets the player and re-registers `"id2"`.
- **Verification**: Outer `HideGroup` aborts. Replacement is not marked hidden (`isVisible` and `hiddenSinceTick` remain untouched). Replacement can be shown and operated normally.

### ID3: Destroy Callback Same-Name Replacement
- **Mechanism**: In `cbDestroy` of `"id3"`, Pawn resets the player and registers `"id3"` again.
- **Verification**: Outer `DestroyGroupInternal` aborts. Replacement is not marked destroyed and capacity is not double-subtracted. Replacement exists and can be shown.

### ID4: ProcessTick Same-Name Replacement
- **Mechanism**: Group `"id4"` with a minimal idle timeout is hidden. During `ProcessTick` idle destroy callback, Pawn resets and replaces `"id4"`.
- **Verification**: `ProcessTick` detects `instanceId` mismatch. Replacement survives and is not marked destroyed or erased.

### ID5: Eviction Same-Name Replacement
- **Mechanism**: A candidate group `"id5_cand"` is selected for eviction during `EnsureCapacity`. During eviction `cbDestroy`, Pawn resets and re-registers the candidate.
- **Verification**: `EvictOneHiddenGroup` detects candidate replacement and fails eviction safely without corrupting replacement state or capacity accounting.

### ID6: Same Owner / Same Callback Names
- **Mechanism**: Old and new group share the identical group name, owner AMX, and public callback names. In the create callback, player is reset and group re-registered with identical callback names.
- **Verification**: SUI detects replacement purely through `instanceId`, proving identity is not inferred from metadata or callback names.

### ID7: Cross-AMX Replacement
- **Mechanism**: Filterscript registers and shows `"id7_fs"`. During destroy callback, player is reset and Gamemode registers `"id7_fs"` under Gamemode ownership.
- **Verification**: Filterscript's outer destroy operation does not mutate Gamemode's new group. Gamemode shows the group and dispatches callbacks exclusively to Gamemode.

### ID8: Normal No-Replacement Path
- **Mechanism**: Standard register -> show -> hide -> show -> destroy sequence.
- **Verification**: Ordinary lifecycle transitions succeed without regression.

### ID9: Reset + Register Same Name Multiple Times
- **Mechanism**: Within controlled callbacks, cycle generation A -> B -> C.
- **Verification**: Every registration receives a distinct monotonically allocated ID; no stale outer operation on A affects C.

### ID10: 100 Rapid Replacement Cycles
- **Mechanism**: Execute 100 consecutive register -> show -> destroy -> reset cycles in a tight loop.
- **Verification**: No crashes, zero memory corruption, active textdraw count cleanly returns to 0, and subsequent registrations operate reliably.
