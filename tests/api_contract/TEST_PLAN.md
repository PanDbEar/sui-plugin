# SUI Phase 12.3: Public API Contract Test Plan (AP1–AP8, AS1–AS10)

## Objective
Verify that all public SUI declarations in `pawn/sui.inc`, runtime AMX native registrations in `src/main.cpp`, C++ dispatchers in `src/Natives.hpp` and `src/Natives.cpp`, core data structures in `src/Core.hpp` and `src/Core.cpp`, documentation in `docs/API_REFERENCE.md` and `README.md`, and shipped code in `examples/` are 100% synchronized, truthful, and free of tag mismatches, phantom declarations, or broken example scripts.

---

## Static & Contract Verification Scenarios

| Test ID | Scope | Invariant / Target Specification | Method | Expected Outcome |
| :--- | :--- | :--- | :--- | :--- |
| **AP1** | Native Count | Exactly 20 public natives declared in `pawn/sui.inc` and registered in `src/main.cpp:AMX_NATIVE_INFO`. | Automated Static Checker (`check_api_surface.py`) | 20 == 20 |
| **AP2** | Include-Registration Name Equality | Set of native names in `pawn/sui.inc` matches `src/main.cpp` native table with zero omissions or additions. | Automated Static Checker (`check_api_surface.py`) | Set equality |
| **AP3** | Stock / Native Distinction | Convenience stock helper `SUI_RegisterGroup` is recognized as a Pawn stock, not a C++ native. | Automated Static Checker (`check_api_surface.py`) | Validated stock separation |
| **AP4** | Parameter Count Audit | Number of arguments in `pawn/sui.inc` for each native exactly matches `Utils::CheckParams(params, N)` in `src/Natives.cpp`. | Automated Static Checker (`check_api_surface.py`) | 20 / 20 match |
| **AP5** | Handler Declarations & Definitions | Every registered C++ native handler is declared in `src/Natives.hpp` and defined in `src/Natives.cpp`. | Automated Static Checker (`check_api_surface.py`) | 20 / 20 match |
| **AP6** | Documentation Synchronization | All 20 registered natives are documented in `docs/API_REFERENCE.md` with accurate signatures and parameters. | Automated Static Checker (`check_api_surface.py`) | 20 / 20 match |
| **AP7** | Priority Constants & Defaults | Priority constants (`LOW=0`, `NORMAL=1`, `HIGH=2`, `CRITICAL=3`) and capacity defaults (`size=1`, `timeout=30000`, `max=256`, `threshold=230`) match between include, C++ headers, and docs. | Automated Static Checker & Source Audit | 100% synchronized |
| **AP8** | Example & Fixture Compilation | Shipped example (`examples/factory_login_example.pwn`) and all 22 test fixture `.pwn` scripts (23 total `.pwn` scripts) compile cleanly with Pawn compiler v3.10.10. | Automated Pawn Compiler (`pawncc`) | 0 errors, 0 warnings |

---

## Runtime Stock Helper Verification Scenarios (AS1–AS10)

Suite script: `tests/api_contract/api_contract_runtime.pwn`

| Test ID | Scope | Invariant / Target Specification | Expected Outcome |
| :--- | :--- | :--- | :--- |
| **AS1** | Valid Setup | Complete valid `SUI_RegisterGroup` parameters register group, show group, verify active textdraw count matches size. | PASS (return 1) |
| **AS2** | Invalid Priority | Out-of-bounds priority (99, -1, 4) rejected by prevalidation; zero state created; capacity unaffected. | PASS (return 0) |
| **AS3** | Negative Size | Negative size parameter (-10) rejected by prevalidation; zero state created; capacity unaffected. | PASS (return 0) |
| **AS4** | Negative Timeout | Negative timeout parameter (-500) rejected by prevalidation; zero state created; capacity unaffected. | PASS (return 0) |
| **AS5** | Invalid Player ID | Out-of-bounds player IDs (-1, 1000, INVALID_PLAYER_ID) rejected at native boundary; no phantom PlayerContext. | PASS (return 0) |
| **AS6** | Config Update | Re-registering existing uncreated group with updated size/priority/timeout updates config cleanly. | PASS (return 1) |
| **AS7** | Usable Lifecycle | Valid registered group operates cleanly through full lifecycle: show, touch, hide, state queries. | PASS (return 1) |
| **AS8** | Prevalidation Cleanliness | Prevalidation rejects invalid priority (99) before registration native is invoked; leaves zero group state. | PASS (return 1) |
| **AS9** | Existing Group Safety | Calling `SUI_RegisterGroup` on an already-created group fails safely (size change rejected) without calling `SUI_DestroyGroup`; live group, visibility, and active textdraw count remain intact. | PASS (return 1) |
| **AS10** | Callback Isolation | Calling `SUI_RegisterGroup` with new callbacks on an already-created group fails safely (return 0) before native registration; original callbacks remain authoritative through subsequent hide, show, and destroy; new callbacks receive zero calls. | PASS (return 1) |

---

## Execution Guidelines

Run the automated surface checker:
```bash
python tests/api_contract/check_api_surface.py
```

Compile all fixtures:
```bash
python scripts/compile_pawn.py --check-only
```
Never commit `.amx` binaries to version control.
