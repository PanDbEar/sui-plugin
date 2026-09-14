# SUI Phase 11: Player ID Domain Validation Test Plan (PV1–PV14)

## Objective
Verify that all public Pawn natives and internal `SUICore` routines strictly validate the player ID domain (`0 <= playerId < 1000`), rejecting invalid player IDs at the outer trust boundary before string dereference, state allocation, or callback dispatch, while ensuring valid player lifecycles (`0` and `999`) operate with full fidelity and idempotent cleanups are preserved.

## Authoritative Player ID Domain
- Valid domain: `0 .. 999` (inclusive), matching SA-MP 0.3.7-R2 `#define MAX_PLAYERS (1000)`.
- Rejection domain: `playerId < 0 || playerId >= 1000`.
- Standard sentinels: `INVALID_PLAYER_ID` (`65535` / `0xFFFF`), `cellmin` (`-2147483648`), `cellmax` (`2147483647`).

## Scenarios Matrix

| ID | Title | Description | Target Invariant |
|---|---|---|---|
| **PV1** | Negative ID Rejection (-1) | Invocations with `playerId = -1` across all natives fail immediately without side effects. | Rejection of negative IDs |
| **PV2** | Cellmin Rejection (-2147483648) | Minimum signed 32-bit cell is rejected without integer overflow, wrap, or crash. | Signed integer lower boundary |
| **PV3** | Boundary Out-Of-Range (1000) | Upper boundary value `1000` (`SUI_MAX_PLAYERS`) is strictly rejected. | Upper boundary strict inequality |
| **PV4** | Cellmax Rejection (2147483647) | Maximum signed 32-bit cell is rejected without truncation or sign issues. | Signed integer upper boundary |
| **PV5** | INVALID_PLAYER_ID (65535) | Standard SA-MP disconnected sentinel (`0xFFFF`) is strictly rejected across all natives. | Sentinel rejection |
| **PV6** | Player 0 Valid Lifecycle | Lower boundary valid ID `0` supports complete registration, show, hide, touch, query, destroy, and cleanup. | Lowest valid ID fidelity |
| **PV7** | Player 999 Valid Lifecycle | Upper boundary valid ID `999` supports complete registration, show, hide, touch, query, destroy, and cleanup. | Highest valid ID fidelity |
| **PV8** | No Callbacks on Invalid Registration | Registration attempts on invalid player IDs never invoke create, show, hide, or destroy callbacks. | Trust boundary callback isolation |
| **PV9** | No Phantom Context via Setters | Setters (`SetMaxTextDraws`, `SetEvictionThreshold`) on invalid IDs return 0 and never insert entries into `players`. | Phantom context prevention |
| **PV10** | Side-Effect Free Queries | Inspection queries (`GetActiveTextDrawCount`, `IsGroupCreated`, `IsGroupVisible`, `IsGroupEvictable`) return 0 without creating context. | Read-only inspection safety |
| **PV11** | Valid-No-Context Cleanup/Reset | `CleanupPlayer` and `ResetPlayer` for valid IDs without registered groups return 1 (idempotent success). | SUI-005 idempotent cleanup |
| **PV12** | Invalid Cleanup/Reset Rejection | `CleanupPlayer` and `ResetPlayer` for invalid IDs (`-1`, `1000`, `cellmin`, `cellmax`) return 0. | Invalid player teardown rejection |
| **PV13** | Repeated Invalid-ID Stress Loop | Iterative invocation of all natives across multiple invalid IDs to verify zero memory leaks or instability. | Boundary stability under stress |
| **PV14** | Complete Native Matrix Coverage | Explicit execution of all 19 public SUI natives under valid and invalid inputs to confirm universal boundary enforcement. | Full surface coverage |
