# SUI — Continuous Integration & Test Automation Architecture

**Document Version:** 1.0.0 (Phase 14 Baseline)  
**Author:** SUI Engineering  
**Scope:** Automated testing gates, multi-tier evidence layers, toolchain provenance, and local replication.

---

## 1. System Overview

To guarantee long-term regression safety without weakening platform constraints (Linux x86 ELF32, `-m32`), SUI establishes a reproducible, repository-owned test automation framework and continuous integration pipeline.

The CI architecture strictly separates verification into **Three Distinct Evidence Layers**, preventing the conflation of static syntax checks, binary build verification, and live server runtime regressions.

```
+-------------------------------------------------------------------------+
|                       SUI THREE-LAYER EVIDENCE GATES                     |
+-------------------------------------------------------------------------+
|                                                                         |
|  [ LAYER A ] Static Repository Contract Gates                           |
|  ├── API Surface Checker (tests/api_contract/check_api_surface.py)      |
|  └── Repo Surface Checker (tests/repo_contract/check_source_surface.py) |
|                                                                         |
|  [ LAYER B ] Build & Compilation Contract Gates                         |
|  ├── 32-bit Multilib Shared Object Build (gcc -m32, Release)            |
|  ├── Binary Architecture Verification (ELF32, Intel 80386)              |
|  ├── Canonical C Plugin Export Audit (exact 6 exports)                  |
|  └── Pawn Fixture Compilation Audit (scripts/compile_pawn.py --check)   |
|                                                                         |
|  [ LAYER C ] Live Runtime Regression Gates                              |
|  ├── Headless SA-MP 0.3.7-R2 Linux Dedicated Server (samp03svr)         |
|  ├── Dynamic Fixture Deployment (gamemodes/ & filterscripts/)           |
|  └── 11 Permanent Regression Test Suites (scripts/run_regression.py)    |
|      └── 151 / 151 PASS (100% Assertion Baseline)                       |
|                                                                         |
+-------------------------------------------------------------------------+
```

---

## 2. Toolchain Provenance & Redistribution Policy

To maintain strict compliance with software licenses and repository hygiene, proprietary server binaries are **never committed to version control**. Instead, CI runners and developer workstations dynamically provision test environments using verified sources.

| Dependency | Already Tracked? | Source / Upstream Provenance | License / Redistribution Policy | CI Provisioning Strategy | Local Workstation Strategy |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`samp-plugin-sdk`** | **Yes** (`lib/samp-plugin-sdk`) | `maddinat0r/samp-plugin-sdk` pinned at commit `a5ce36a9b6ebbea6ad36705603f653bf3d4f41c5` | Permissive (zlib) | Recursive checkout via `actions/checkout@v4` | Tracked git submodule |
| **Pawn Compiler (`pawncc`)** | **No** | CompuPhase Pawn 3.2.3664 / `pawn-lang/compiler` v3.10.10 | Permissive (Apache-2.0 / zlib) | Downloaded dynamically during runner setup | Local Pawno or `PAWNCC` env var |
| **SA-MP 0.3.7-R2 Linux Server (`samp03svr`)** | **No** | SA-MP Team archive (`samp037svr_R2-1.tar.gz`) | Proprietary Freeware (redistribution in git strictly prohibited) | Dynamically retrieved via `scripts/setup_test_server.py` | Local test server directory or setup script |
| **SA-MP Standard Includes (`a_samp.inc`, etc.)** | **No** (only `pawn/sui.inc` is tracked) | Bundled with SA-MP server package and `pawn-lang/samp-stdlib` | SA-MP License / Apache-2.0 | Shallow clone of `pawn-lang/pawn-stdlib` and `pawn-lang/samp-stdlib` | Local include path (`pawno/include` or `SAMP_INCLUDE_PATH`) |

---

## 3. The Three Evidence Layers

### Layer A — Static Repository Contract
Layer A verifies that the repository source tree, header declarations, public Pawn include files, and documentation remain 100% truthful and synchronized.
- **`tests/api_contract/check_api_surface.py`**:
  - `AP1`: Exactly 19 public natives declared and registered.
  - `AP2`: 100% name set equality between `pawn/sui.inc` and `src/main.cpp`.
  - `AP3`: Stock helper `SUI_RegisterGroup` distinction from C++ natives.
  - `AP4`: Parameter count alignment between Pawn declarations and `Utils::CheckParams`.
  - `AP5`: C++ handler declaration and definition parity (`Natives.hpp` / `Natives.cpp`).
  - `AP6`: Complete documentation coverage in `docs/API_REFERENCE.md`.
  - `AP7`: Priority constants and capacity defaults synchronization.
- **`tests/repo_contract/check_source_surface.py`**:
  - `RC1`: All `src/*.cpp` files listed in `CMakeLists.txt:SOURCES`.
  - `RC2`: Zero banned includes (`Component.hpp`, `Compat.hpp`, `<sdk.hpp>`).
  - `RC3`: Directory `src/` contains exactly the canonical 6 files.
  - `RC4`: All CMake source paths exist on disk.
  - `RC5`: Complete absence of orphaned component prototypes.

### Layer B — Build & Compilation Contract
Layer B verifies that the plugin compiles cleanly under strict platform constraints and that all Pawn code compiles with zero errors and zero warnings.
- **C++ Shared Library**:
  - Compiled with `-m32` targeting Linux x86 (32-bit ELF, Intel 80386).
  - Validated via `file` and `readelf -h`.
  - Dynamic export validation via `nm -D` ensuring exactly 6 canonical C entry points:
    - `Supports`
    - `Load`
    - `Unload`
    - `AmxLoad`
    - `AmxUnload`
    - `ProcessTick`
- **Pawn Fixture Compilation**:
  - Executed via repository-owned tool `scripts/compile_pawn.py --check-only`.
  - Verifies all 18 Pawn files (1 example + 17 test scripts).
  - Enforces `0 errors, 0 warnings`.
  - Immediately purges generated `.amx` binaries to preserve repository hygiene.

### Layer C — Live Runtime Regression
Layer C verifies actual plugin behavior within a genuine 32-bit Linux SA-MP dedicated server (`samp03svr`).
- **Orchestration**: Executed via repository-owned tool `scripts/run_regression.py`.
- **Permanent Suites Tested**:
  1. `reentrancy_regression`: 10 / 10 PASS (R1–R10)
  2. `amx_ownership`: 7 / 7 PASS (A1–A7)
  3. `native_validation`: 10 / 10 PASS (V1–V10)
  4. `capacity_arithmetic`: 19 / 19 PASS (C1–C12, G1–G7)
  5. `callback_semantics`: 13 / 13 PASS (P1–P13)
  6. `player_teardown`: 18 / 18 PASS (T1–T18)
  7. `group_identity`: 25 / 25 PASS (ID1–ID10, H1–H4, ID-EVICT, ID-ABA-CROSS, O1–O2, RAG1–RAG3, X1–X4)
  8. `eviction_preflight`: 15 / 15 PASS (E1–E15)
  9. `show_failure_lifecycle`: 10 / 10 PASS (F1–F10)
  10. `player_id_validation`: 14 / 14 PASS (PV1–PV14)
  11. `api_contract_runtime`: 10 / 10 PASS (AS1–AS10)
- **Cumulative Assertion Requirement**: **151 / 151 PASS (100%)**.

---

## 4. Local Execution & Developer Guide

### Running Layer A (Static Checks)
```bash
python tests/api_contract/check_api_surface.py
python tests/repo_contract/check_source_surface.py
```

### Running Layer B (Pawn Compilation)
On Windows:
```powershell
py scripts/compile_pawn.py --check-only
```

On Linux / WSL:
```bash
python3 scripts/compile_pawn.py \
  --compiler /path/to/pawncc \
  --includes "/path/to/include" \
  --check-only
```

### Running Layer C (Full Runtime Regression)
1. **Provision Server**:
   ```bash
   python3 scripts/setup_test_server.py --dest test-server
   ```
2. **Build Plugin**:
   ```bash
   cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
   cmake --build build --config Release
   cp build/sui-plugin-legacy.so test-server/plugins/
   ```
3. **Compile Fixtures into Server Layout**:
   ```bash
   python3 scripts/compile_pawn.py \
     --compiler /path/to/pawncc \
     --includes "/path/to/include" \
     --output-dir test-server
   ```
4. **Execute Regression Suites**:
   ```bash
   python3 scripts/run_regression.py --server-dir test-server
   ```

---

## 5. GitHub Actions Continuous Integration

The GitHub Actions workflow is defined in [`.github/workflows/ci.yml`](../.github/workflows/ci.yml). It triggers automatically on all pushes and pull requests across all branches, executing all three evidence layers in order:

1. **Layer A**: Runs static contract checkers against Python 3.11.
2. **Layer B**: Installs `gcc-multilib`, builds 32-bit Release plugin, asserts ELF32 architecture and 6 exports, downloads Pawn compiler, and verifies 18 / 18 Pawn compilation.
3. **Layer C**: Automatically provisions SA-MP server via `setup_test_server.py`, deploys compiled test fixtures and `sui-plugin-legacy.so`, and executes all 11 suites via `run_regression.py`, asserting 151 / 151 passing assertions.
