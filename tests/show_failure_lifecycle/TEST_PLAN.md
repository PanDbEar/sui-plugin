# SUI-008: Failed-Show Hidden Timestamp and Idle Lifetime Test Plan

## Objective
Verify that every created-but-hidden SUI group has a valid and intentional hidden lifetime timestamp, preventing accidental immediate idle destruction or inconsistent timeout behavior after a failed show attempt.

## Invariant Specification
1. **Meaningful Hidden Origin**: Every group with `isCreated == true && isVisible == false` must have a valid `hiddenSinceTick` recording the start of its uninterrupted hidden interval.
2. **Fresh Create + Failed Show**: When an uncreated group (`!isCreated`) successfully completes `cbCreate` but fails `cbShow`, it transitions into `isCreated == true && isVisible == false`. It must receive `hiddenSinceTick = now` (and `lastUsedTick = now`), starting a valid hidden lifetime. It must NOT retain `hiddenSinceTick = 0`.
3. **Existing Hidden Group + Failed Show**: An already-hidden group (`isCreated == true && isVisible == false`) that attempts `ShowGroup` and fails `cbShow` never stopped being hidden. It must preserve its original `hiddenSinceTick`, maintaining continuous hidden lifetime accounting without resetting its idle timer.
4. **Show Success Inactivation**: When `cbShow` succeeds, `isVisible` becomes `true`, `lastUsedTick` is refreshed to `now`, and `hiddenSinceTick` is inactivated (`0`).
5. **Hide Success Origin**: When a visible group successfully hides, `isVisible` becomes `false`, and `hiddenSinceTick = now` begins a new hidden interval.
6. **Hide Failure Invariant**: If `cbHide` fails, the group remains visible (`isVisible == true`); no hidden interval begins, and `hiddenSinceTick` is not modified.
7. **Create Failure Invariant**: If `cbCreate` fails, `isCreated` remains `false`; no created-resource timer exists.
8. **SUI-006 Decoupling**: Pawn callbacks returning `0` are successful executions (`PawnCallResult::Success() == true`) and do not trigger failed-show handling.
9. **SUI-017 Generation Safety**: Generation changes during callbacks abort outer operations without corrupting new generations.
10. **Idle Timeout Zero Contract**: `idleTimeoutMs == 0` evaluates `currentTick - hiddenSinceTick > 0`, causing destruction on the next tick where server time advances.

## Test Matrix (F1 – F10)

| Test ID | Category | Scenario Description | Success Criteria |
|---|---|---|---|
| **F1** | Fresh Create + Failed Show | Uncreated group with 5000ms timeout has missing `cbShow` | `ShowGroup` returns 0; `isCreated=1`; `isVisible=0`; active capacity held; `ProcessTick` does NOT destroy group prematurely. |
| **F2** | Real Idle Expiration | Group with 50ms timeout created but failed show | Group survives before 50ms; after 50ms elapses, `ProcessTick` destroys group exactly once; capacity restored to 0. |
| **F3** | Continuous Hidden Preservation | Existing hidden group (300ms timeout) attempts show and fails at 150ms | `hiddenSinceTick` is NOT reset to 150ms; group expires at 300ms total from original hide time. |
| **F4** | Show Success Inactivation | Hidden group successfully shown | `isVisible=1`; `hiddenSinceTick=0`; group survives past idle timeout; subsequent hide starts fresh timer. |
| **F5** | Hide Success Timer Origin | Group shown, waited, then hidden with 100ms timeout | Timer measured from hide time, not creation time; group survives before 100ms from hide, destroyed after. |
| **F6** | Hide Failure Invariant | Visible group with failing `cbHide` attempts hide | `HideGroup` returns 0; `isVisible=1`; `ProcessTick` does not idle-destroy visible group. |
| **F7** | Create Failure Invariant | Uncreated group with failing `cbCreate` attempts show | `ShowGroup` returns 0; `isCreated=0`; active count 0; `ProcessTick` does not destroy. |
| **F8** | Return 0 Callback Success | Callback returns 0 | `ShowGroup` returns 1; `isVisible=1`; treated as successful show (not failed show). |
| **F9** | Generation ABA Safety | Callback replaces group during `cbCreate` | Outer operation detects instance change and aborts; replacement generation timestamp intact. |
| **F10** | Zero Timeout Contract | Group hidden with `idleTimeoutMs = 0` | On subsequent tick where `currentTick > hiddenSinceTick`, `ProcessTick` destroys group. |
