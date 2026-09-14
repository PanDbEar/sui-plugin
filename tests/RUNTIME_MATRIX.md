# SUI Runtime Test Execution Matrix

This document defines the authoritative configuration, script dependencies, fixture requirements, and expected outcomes for all 10 permanent regression test suites in SUI.

---

## Suite Matrix Summary

| Suite Name | Gamemode (`server.cfg`) | Filterscripts (`server.cfg`) | Dynamic Scripts | Tests Count | Expected Result | Auto-Exit |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **reentrancy_regression** | `reentrancy_regression` | *(none)* | *(none)* | 10 | 10 / 10 PASS | Yes |
| **amx_ownership** | `ownership_gamemode` | `ownership_filterscript` | *(none)* | 7 | 7 / 7 PASS | Yes |
| **native_validation** | `native_validation` | *(none)* | *(none)* | 10 | 10 / 10 PASS | Yes |
| **capacity_arithmetic** | `capacity_arithmetic` | *(none)* | `capacity_filterscript` (C9) | 19 | 19 / 19 PASS | Yes |
| **callback_semantics** | `callback_semantics` | `callback_filterscript` | *(none)* | 13 | 13 / 13 PASS | No |
| **player_teardown** | `player_teardown` | `player_teardown_filterscript` | *(none)* | 18 | 18 / 18 PASS | Yes |
| **group_identity** | `group_identity` | `group_identity_filterscript` | *(none)* | 25 | 25 / 25 PASS | Yes |
| **eviction_preflight** | `eviction_preflight` | `eviction_preflight_filterscript` | *(none)* | 15 | 15 / 15 PASS | Yes |
| **show_failure_lifecycle** | `show_failure_lifecycle` | *(none)* | *(none)* | 10 | 10 / 10 PASS | Yes |
| **player_id_validation** | `player_id_validation` | *(none)* | *(none)* | 14 | 14 / 14 PASS | Yes |
| **api_contract_runtime** | `api_contract_runtime` | *(none)* | *(none)* | 9 | 9 / 9 PASS | Yes |

**Total Permanent Suite Pass Rate:** **150 / 150 PASS (100%)**

---

## Detailed Suite Specifications

### 1. reentrancy_regression
- **Target Issue:** SUI-001 (Re-entrancy recursion and state corruption)
- **Gamemode:** `tests/reentrancy_regression.pwn`
- **Filterscripts:** None
- **Key Invariants:** `isExecutingCallback` prevents nested lifecycle mutation; player context snapshots prevent iterator invalidation.
- **Assertions:** R1–R10 (10 tests)
- **Exit Behavior:** Server automatically issues `exit` via RCON upon completing R10.

### 2. amx_ownership
- **Target Issue:** SUI-002 (Cross-AMX ownership isolation and anti-hijack)
- **Gamemode:** `tests/amx_ownership/ownership_gamemode.pwn`
- **Filterscript:** `tests/amx_ownership/ownership_filterscript.pwn`
- **Key Invariants:** Group owner AMX is immutable across callbacks; foreign AMX cannot hijack registered group name; AMX unload safely purges owned groups without capacity leaks.
- **Assertions:** A1–A7 (7 tests)
- **Exit Behavior:** Server automatically terminates via RCON upon completing A7.

### 3. native_validation
- **Target Issue:** SUI-003 (Pointer, string, and integer boundary validation)
- **Gamemode:** `tests/native_validation/native_validation.pwn`
- **Filterscripts:** None
- **Key Invariants:** NULL pointers, out-of-bounds AMX addresses, and negative parameter integers fail cleanly without crashing or corrupting memory.
- **Assertions:** V1–V10 (10 tests)
- **Exit Behavior:** Server automatically terminates via RCON upon completing V10.

### 4. capacity_arithmetic
- **Target Issue:** SUI-004 (Overflow-safe arithmetic and accounting invariants)
- **Gamemode:** `tests/capacity_arithmetic/capacity_arithmetic.pwn`
- **Filterscripts in `server.cfg`:** **MUST BE EMPTY**
- **Dynamic Filterscripts:** `capacity_filterscript` dynamically loaded by Test C9 via `rcon loadfs` and unloaded via `rcon unloadfs`.
- **Warning:** If `capacity_filterscript` is preloaded in `server.cfg`, 15 textdraws will be allocated at startup, causing an active textdraw offset that fails 11 tests. Always ensure `filterscripts` is empty in `server.cfg`.
- **Assertions:** C1–C12, G1–G7 (19 tests)
- **Exit Behavior:** Server automatically terminates via RCON upon completing G7.

### 5. callback_semantics
- **Target Issue:** SUI-006 (Pawn callback return values decoupled from lifecycle state transitions)
- **Gamemode:** `tests/callback_semantics/callback_semantics.pwn`
- **Filterscript:** `tests/callback_semantics/callback_filterscript.pwn`
- **Key Invariants:** Pawn return value (`0`, `1`, `42`, `-1`, or omitted default `0`) does not veto lifecycle transitions; AMX execution status (`AMX_ERR_NONE`) governs transition success.
- **Assertions:** P1–P13 (13 tests)
- **Exit Behavior:** Gamemode outputs results and stays active; monitor `server_log.txt` or terminate runner process.

### 6. player_teardown
- **Target Issue:** SUI-005 (Deterministic player teardown, failure preservation, and re-entrant mutation blocking)
- **Gamemode:** `tests/player_teardown/player_teardown.pwn`
- **Filterscript:** `tests/player_teardown/player_teardown_filterscript.pwn`
- **Key Invariants:** `SUI_CleanupPlayer` is terminal; `SUI_ResetPlayer` is non-terminal and preserves failed destruction state; re-entrant mutations during teardown are rejected; uncreated groups are directly pruned without callbacks.
- **Assertions:** T1–T18 (18 tests)
- **Exit Behavior:** Server automatically terminates via RCON upon completing T18.

### 7. group_identity
- **Target Issue:** SUI-017 / SUI-005 / SUI-002 reconciliation (Monotonic generation identity, ABA replacement isolation, and teardown failure preservation)
- **Gamemode:** `tests/group_identity/group_identity.pwn`
- **Filterscript:** `tests/group_identity/group_identity_filterscript.pwn`
- **Key Invariants:**
  1. `instanceId` monotonically discriminates group generations.
  2. Outer transactions (`ShowGroup`, `HideGroup`, `DestroyGroupInternal`, `EvictOneHiddenGroup`, `ProcessTick`) abort immediately on generation change.
  3. Uncreated groups pruned during `cbCreate` via `ResetPlayer` allow genuine ABA replacement (`ID1`, `X1`, `ID-ABA-CROSS`).
  4. Active groups executing `cbHide` or `cbDestroy` cannot be destroyed by re-entrant `ResetPlayer`; reset returns 0, in-callback re-registration is rejected (Invariant 2), outer destroy authoritatively finalizes, and post-destruction name reuse succeeds (`ID2`, `ID3`, `ID4`, `ID7`, `ID-EVICT`, `X2`, `X3`, `X4`).
- **Assertions:** ID1–ID10, H1–H4, ID-EVICT, ID-ABA-CROSS, O1–O2, RAG1–RAG3, X1–X4 (25 tests)
- **Exit Behavior:** Server automatically terminates via RCON upon completing X4.

### 8. eviction_preflight
- **Target Issue:** SUI-007 (Non-destructive capacity eviction preflight, minimal eviction planning, and re-entrant execution safety)
- **Gamemode:** `tests/eviction_preflight/eviction_preflight.pwn`
- **Filterscript:** `tests/eviction_preflight/eviction_preflight_filterscript.pwn`
- **Key Invariants:**
  1. Capacity sufficiency preflight: If total eligible capacity < needed capacity, return false, destroy NOTHING, invoke NO callbacks, and preserve all existing groups.
  2. Policy-minimal ordered eviction: SUI evicts the minimal prefix of ordered candidates necessary to satisfy capacity, stopping as soon as deficit is satisfied (no over-eviction).
  3. Strict eviction priority: LOW < NORMAL < HIGH, older `lastUsedTick` before newer, deterministic alphabetical tie-breaker. CRITICAL, visible, non-evictable, and callback-executing groups strictly excluded.
  4. Candidate-by-candidate replanning: Replanning runs after each candidate eviction to safely observe re-entrant state changes or failed destruction.
  5. Multi-AMX eviction ownership: Filterscript candidate destroy callbacks execute within the Filterscript's AMX context.
- **Assertions:** E1–E15 (15 tests)
- **Exit Behavior:** Server automatically terminates via RCON upon completing E15.

### 9. show_failure_lifecycle
- **Target Issue:** SUI-008 (Failed-show hidden timestamp semantics, idle lifetime correctness, and tick-state consistency)
- **Gamemode:** `tests/show_failure_lifecycle/show_failure_lifecycle.pwn`
- **Filterscripts:** None
- **Key Invariants:**
  1. Fresh-create show failure initializes `hiddenSinceTick` and `lastUsedTick` to current time so idle timeout operates correctly without premature tick destruction.
  2. Continuous hidden lifetime preservation: Pre-existing created-hidden groups that fail a subsequent show preserve their established `hiddenSinceTick`.
  3. Successful show resets `hiddenSinceTick = 0` (inactivating hidden timer) and refreshes `lastUsedTick`.
  4. Successful hide records fresh `hiddenSinceTick` and `lastUsedTick`.
  5. Failed hide leaves group visible and does not start hidden lifetime countdown.
  6. Failed create leaves group uncreated without starting hidden interval.
- **Assertions:** F1–F10 (10 tests)
- **Exit Behavior:** Server automatically terminates via RCON upon completing F10.

### 10. player_id_validation
- **Target Issue:** SUI-009 (Player ID Domain Validation, Phantom PlayerContext Prevention, and Native Trust-Boundary Hardening)
- **Gamemode:** `tests/player_id_validation/player_id_validation.pwn`
- **Filterscripts:** None
- **Key Invariants:**
  1. Authoritative Domain: Only numeric player IDs `0 <= playerId < 1000` (`SUI_MAX_PLAYERS = 1000`) are accepted across all 18 player-accepting Pawn natives.
  2. Immediate Native Rejection: Out-of-bounds IDs (negative numbers, `>= 1000`, `INVALID_PLAYER_ID = 65535`, `cellmin`, `cellmax`) are rejected immediately after `CheckParams` and before any AMX string resolution or core dispatch.
  3. Safe Native Return Defaults: Rejected player-accepting operations return `0` (or `false`) without logging spurious string or lookup errors.
  4. Phantom Context Prevention: Core lookups via `GetPlayerContext(playerId)` return `nullptr` for invalid IDs; setter methods (`RegisterFactoryGroup`, `SetMaxTextDraws`, `SetEvictionThreshold`) and query methods never create default-constructed entries in `players` map for out-of-bounds IDs.
  5. Teardown Idempotency & Rejection: `CleanupPlayer` and `ResetPlayer` return `0` for invalid player IDs, while returning `1` for valid player IDs that have no instantiated context.
- **Assertions:** PV1–PV14 (14 tests)
- **Exit Behavior:** Server automatically terminates via RCON upon completing PV14.

### 11. api_contract_runtime
- **Target Issue:** SUI-010 (Public Pawn API Synchronization, Stock Helper Return Contract Truthfulness, and Failure Safety)
- **Gamemode:** `tests/api_contract/api_contract_runtime.pwn`
- **Filterscripts:** None
- **Key Invariants:**
  1. Complete Setup Verification: `SUI_RegisterGroup` returns `1` only if registration and all four configuration setters (`SetGroupSize`, `SetIdleTimeout`, `SetGroupPriority`, `SetGroupEvictable`) succeed.
  2. Prevalidation Defense: Out-of-bounds parameters (negative size, negative timeout, priority outside LOW..CRITICAL) are prevalidated and rejected (`return 0`) before registration native is invoked.
  3. Zero Inadvertent Destruction: If a setter fails after registration (e.g. attempting to re-register an already created group), `SUI_RegisterGroup` returns `0` without calling `SUI_DestroyGroup`, preserving active UI groups and textdraw accounting.
  4. Clean Subsequent Registration: A prevalidation rejection leaves zero state in `PlayerContext`; subsequent registration under the same group name succeeds with full lifecycle functionality.
  5. Complete Lifecycle Usability: Groups registered via the helper are fully functional through creation, show, touch, hide, state query, and destruction.
- **Assertions:** AS1–AS9 (9 tests)
- **Exit Behavior:** Server automatically terminates via RCON upon completing AS9.

---

## Compilation Guidelines

All test scripts must be compiled with the Pawn 3.2.3664 compiler:
```bash
pawncc <file>.pwn -i<pawno_include> -ipawn -o<file>.amx
```
Never commit `.amx` binaries into the git repository.
