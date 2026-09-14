# SUI Phase 12: Public API Contract Test Plan (AP1–AP8)

## Objective
Verify that all public SUI declarations in `pawn/sui.inc`, runtime AMX native registrations in `src/main.cpp`, C++ dispatchers in `src/Natives.hpp` and `src/Natives.cpp`, core data structures in `src/Core.hpp` and `src/Core.cpp`, documentation in `docs/API_REFERENCE.md` and `README.md`, and shipped code in `examples/` are 100% synchronized, truthful, and free of tag mismatches, phantom declarations, or broken example scripts.

---

## Static & Contract Verification Scenarios

| Test ID | Scope | Invariant / Target Specification | Method | Expected Outcome |
| :--- | :--- | :--- | :--- | :--- |
| **AP1** | Native Count | Exactly 19 public natives declared in `pawn/sui.inc` and registered in `src/main.cpp:AMX_NATIVE_INFO`. | Automated Static Checker (`check_api_surface.py`) | 19 == 19 |
| **AP2** | Include-Registration Name Equality | Set of native names in `pawn/sui.inc` matches `src/main.cpp` native table with zero omissions or additions. | Automated Static Checker (`check_api_surface.py`) | Set equality |
| **AP3** | Stock / Native Distinction | Convenience stock helper `SUI_RegisterGroup` is recognized as a Pawn stock, not a C++ native. | Automated Static Checker (`check_api_surface.py`) | Validated stock separation |
| **AP4** | Parameter Count Audit | Number of arguments in `pawn/sui.inc` for each native exactly matches `Utils::CheckParams(params, N)` in `src/Natives.cpp`. | Automated Static Checker (`check_api_surface.py`) | 19 / 19 match |
| **AP5** | Handler Declarations & Definitions | Every registered C++ native handler is declared in `src/Natives.hpp` and defined in `src/Natives.cpp`. | Automated Static Checker (`check_api_surface.py`) | 19 / 19 match |
| **AP6** | Documentation Synchronization | All 19 registered natives are documented in `docs/API_REFERENCE.md` with accurate signatures and parameters. | Automated Static Checker (`check_api_surface.py`) | 19 / 19 match |
| **AP7** | Priority Constants & Defaults | Priority constants (`LOW=0`, `NORMAL=1`, `HIGH=2`, `CRITICAL=3`) and capacity defaults (`size=1`, `timeout=30000`, `max=256`, `threshold=230`) match between include, C++ headers, and docs. | Automated Static Checker & Source Audit | 100% synchronized |
| **AP8** | Example & Fixture Compilation | Shipped example (`examples/factory_login_example.pwn`) and all 15 permanent test fixture `.pwn` scripts compile cleanly with Pawn compiler 3.2.3664. | Automated Pawn Compiler (`pawncc`) | 0 errors, 0 warnings |

---

## Execution Guidelines

Run the automated surface checker:
```bash
python tests/api_contract/check_api_surface.py
```
Compile all fixtures:
```powershell
& "C:\Users\alifc\Downloads\Project\Texture Studio\pawno\pawncc.exe" <file>.pwn -i<include_path> -ipawn
```
Never commit `.amx` binaries to version control.
