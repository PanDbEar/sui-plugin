# SUI — Continuous Integration & Test Automation Architecture

**Document Version:** 1.1.0 (Phase 19 Multi-Platform Architecture Baseline)  
**Author:** SUI Engineering  
**Scope:** Automated testing gates, multi-tier evidence layers, toolchain provenance, cross-platform runners, and local replication.

---

## 1. System Overview

To guarantee long-term regression safety without weakening platform constraints, SUI establishes a reproducible, repository-owned test automation framework and continuous integration pipeline across both supported SA-MP server platforms:
- **Linux x86:** 32-bit ELF, multilib GCC (`-m32`), dedicated headless server (`samp03svr`).
- **Windows x86:** 32-bit PE DLL (Win32), MSVC static CRT (`/MT`), dedicated server (`samp-server.exe`).

The CI architecture strictly separates verification into **Four Distinct Evidence Layers** across independent platform jobs (`linux-x86-gates` and `windows-x86-gates`), preventing the conflation of static syntax checks, binary build verification, live server runtime regressions, and release packaging mechanics.

```text
+-------------------------------------------------------------------------+
|                        SUI FOUR-LAYER EVIDENCE GATES                    |
+-------------------------------------------------------------------------+
|                                                                         |
|  [ LAYER A ] Static Repository Contract Gates                           |
|  ├── API Surface Checker (tests/api_contract/check_api_surface.py)      |
|  │   └── 7 / 7 PASS (20 C++ Natives, 1 Stock Helper, 100% Synced)       |
|  └── Repo Surface Checker (tests/repo_contract/check_source_surface.py) |
|      └── 6 / 6 PASS (7 Canonical Files, 3 C++ Units, 0 Leaks)           |
|                                                                         |
|  [ LAYER B ] Build & Compilation Contract Gates                         |
|  ├── Binary Compilation:                                                |
|  │   ├── Linux x86: gcc -m32 Release -> sui-plugin-legacy.so (ELF32)    |
|  │   └── Windows x86: MSVC Win32 /MT -> sui-plugin-legacy.dll (PE32)    |
|  ├── Binary Architecture & Export Audits (ELF32/PE32, 6 Exports)        |
|  └── Pawn Fixture Compilation Audit (scripts/compile_pawn.py --check)   |
|      └── 23 / 23 PASS (0 errors, 0 warnings under -w239)                |
|                                                                         |
|  [ LAYER C ] Live Runtime Regression Gates                              |
|  ├── Headless SA-MP 0.3.7-R2 Dedicated Server (samp03svr / exe)         |
|  ├── Dynamic Fixture Deployment (gamemodes/ & filterscripts/)           |
|  └── 13 Permanent Regression Test Suites (scripts/run_regression.py)    |
|      ├── Linux x86:   179 / 179 PASS (100% Runtime Assertion Baseline)  |
|      └── Windows x86: 179 / 179 PASS (100% Runtime Assertion Baseline)  |
|                                                                         |
|  [ LAYER D ] Release Packaging & Package-Only Deployment Gates          |
|  ├── Deterministic Packager (scripts/package_release.py --platform)     |
|  ├── Release Contract Checker (tests/release_contract/check_release)   |
|  │   └── 12 / 12 PASS (PK1–PK12 Distribution Integrity Verification)    |
|  └── Package Deployment Smoke Test (tests/release_contract/run_smoke)   |
|      └── Isolated Server Boot with Packaged Binary + sui.inc Only (PASS)|
|                                                                         |
+-------------------------------------------------------------------------+
```

---

## 2. Toolchain Provenance & Dependency Integrity

To ensure 100% reproducible and verifiable verification across environments without committing external binaries to version control, all build-critical dependencies and test tooling are strictly version/commit pinned and integrity verified.

SA-MP server binaries are not stored in this repository and are acquired externally for runtime verification.

### Dependency Pin Matrix

| Dependency | Source | Version / Commit | Integrity Pin | License |
| :--- | :--- | :--- | :--- | :--- |
| **`actions/checkout`** | GitHub Actions | `11bd71901bbe5b1630ceea73d27597364c9af683` (v4.2.2) | Commit SHA | MIT |
| **`actions/setup-python`** | GitHub Actions | `42375524e23c412d93fb67b49958b491fce71c38` (v5.4.0) | Commit SHA | MIT |
| **`actions/upload-artifact`** | GitHub Actions | `ea165f8d65b6e75b540449e92b4886f43607fa02` (v4.6.1) | Commit SHA | MIT |
| **`samp-plugin-sdk`** | Tracked Git Submodule (`lib/samp-plugin-sdk`) | Commit `a5ce36a9b6ebbea6ad36705603f653bf3d4f41c5` | Submodule Commit SHA | zlib/libpng |
| **Pawn Compiler (Linux)** | `pawn-lang/compiler` Linux release asset | Release `v3.10.10` | SHA-256 `9bbb1df6e933318fce1fa61951e4196b70613c637a5a1d4c96937e147c18468d` | zlib/libpng |
| **Pawn Compiler (Windows)** | `pawn-lang/compiler` Windows release asset | Release `v3.10.10` | SHA-256 `14a94e93f0e05443752b9925d69f76c07db7970eaa4dfb175cde01c74451c2fe` | zlib/libpng |
| **`pawn-stdlib`** | `pawn-lang/pawn-stdlib` | Commit `e96507d9a6ddaae5bb0f3ec31479ba805aeff964` | Commit SHA | Apache-2.0 |
| **`samp-stdlib`** | `pawn-lang/samp-stdlib` | Tag `0.3.7-R2-1-1` (Commit `7b194986946f64e8c0a4d4223aafec704ffd6b88`) | Tag & Commit SHA | Apache-2.0 |
| **SA-MP Server Archive (Linux)** | Community preservation archive (`samp037svr_R2-1.tar.gz`) | Version `0.3.7-R2-1` | SHA-256 `f8ead0b15683fc34f13a7a84ba9ea7252b17c5e3161d8255364e1abedd697a53` | SA-MP EULA (External) |
| **SA-MP Server Archive (Windows)** | Community preservation archive (`samp037_svr_R2-1-1_win32.zip`) | Version `0.3.7-R2-1-1` | SHA-256 `e12e7483d4df0349f52e2c5f47d6afd3f782acbc2bbb19fa61adced3bfff2d90` | SA-MP EULA (External) |
| **MSVC 2010 x86 Redistributable** | Microsoft Official CDN (`vcredist_x86.exe`) | Version `10.0.40219.1` | SHA-256 `99dce3c841cc6028560830f7866c9ce2928c98cf3256892ef8e6cf755147b0d8` | Microsoft Software License |

### Provenance Details
- **Pawn Compiler**: Pinned to `v3.10.10` release assets from `pawn-lang/compiler` (Linux tarball and Windows zip). The license distributed in that repository is `zlib/libpng` (per upstream `license.txt`). Archives are verified against SHA-256 checksums before extraction. On Windows, the official Microsoft Visual C++ 2010 x86 Redistributable (`vcredist_x86.exe`) is pinned and installed to satisfy `pawncc.exe` runtime linkage to `MSVCR100.dll`.
- **Pawn Standard Libraries**: Both `pawn-stdlib` and `samp-stdlib` are pinned to immutable commit SHAs. `samp-stdlib` is locked to release tag `0.3.7-R2-1-1`, matching the SA-MP 0.3.7-R2 target.
- **SA-MP Server Acquisition**: Headless server packages are downloaded dynamically via `scripts/setup_test_server.py` from pinned preservation mirrors. SHA-256 hashes are computed and compared against pinned expected hashes before extraction. If hashes do not match, setup aborts immediately. Safe extraction enforces path traversal checks on every member.

---

## 3. The Four Evidence Layers

### Layer A — Static Repository Contract
Layer A verifies that the repository source tree, header declarations, public Pawn include files, and documentation remain 100% truthful and synchronized.
- **`tests/api_contract/check_api_surface.py` (7 / 7 PASS)**:
  - `AP1`: Exactly 20 public natives declared and registered.
  - `AP2`: 100% name set equality between `pawn/sui.inc` and `src/main.cpp`.
  - `AP3`: Stock helper `SUI_RegisterGroup` distinction from C++ natives.
  - `AP4`: Parameter count alignment between Pawn declarations and `Utils::CheckParams`.
  - `AP5`: C++ handler declaration and definition parity (`Natives.hpp` / `Natives.cpp`).
  - `AP6`: Complete documentation coverage in `docs/API_REFERENCE.md`.
  - `AP7`: Priority constants and capacity defaults synchronization.
- **`tests/repo_contract/check_source_surface.py` (6 / 6 PASS)**:
  - `RC1`: All `src/*.cpp` files listed in `CMakeLists.txt:SOURCES` (3 project translation units: `Core.cpp`, `Natives.cpp`, `main.cpp`).
  - `RC2`: Zero banned includes (`Component.hpp`, `Compat.hpp`, `<sdk.hpp>`).
  - `RC3`: Directory `src/` contains exactly the canonical 7 files (`Core.cpp`, `Core.hpp`, `main.cpp`, `Natives.cpp`, `Natives.hpp`, `sui-plugin-legacy.def`, `Utils.hpp`).
  - `RC4`: All CMake source paths exist on disk.
  - `RC5`: Complete absence of orphaned component prototypes.
  - `RC6`: Portable automation path contract (zero developer-specific path literals).

### Layer B — Build & Compilation Contract
Layer B verifies that the plugin compiles cleanly under strict platform constraints and that all Pawn code compiles with zero errors and zero emitted warnings under the pinned CI warning policy (`-w239`).
- **Linux x86 Shared Library (`sui-plugin-legacy.so`)**:
  - Compiled with `-m32` targeting Linux x86 (32-bit ELF, Intel 80386, DYN shared object file).
  - Validated via `file` and `readelf -h`.
  - Dynamic export validation via `nm -D` asserting that all six canonical SA-MP plugin entry points are present:
    - `Supports`, `Load`, `Unload`, `AmxLoad`, `AmxUnload`, `ProcessTick`
- **Windows x86 Shared Library (`sui-plugin-legacy.dll`)**:
  - Compiled with MSVC x86 (`-A Win32`, `/MT` static C/C++ runtime).
  - Validated via `tests/platform_contract/check_windows_binary.py` enforcing:
    - Valid DOS MZ and PE header signatures
    - Machine type `IMAGE_FILE_MACHINE_I386` (0x014c)
    - 32-bit PE format (`Magic` 0x010b, strictly rejecting 64-bit PE32+)
    - DLL characteristics (`IMAGE_FILE_DLL` 0x2000)
    - Export directory parsing verifying all 6 canonical exports (`Supports`, `Load`, `Unload`, `AmxLoad`, `AmxUnload`, `ProcessTick`)
  - Audited via `dumpbin /dependents` in CI to ensure zero dynamic MSVC runtime dependencies (`MSVCP140.dll`, `VCRUNTIME140.dll`).
- **Pawn Fixture Compilation**:
  - Executed via repository-owned tool `scripts/compile_pawn.py --check-only`.
  - Verifies all 23 Pawn files (1 shipped example + 22 regression test fixtures).
  - Enforces `0 errors, 0 emitted warnings under the pinned CI warning policy`.
  - Note: Warning 239 (`literal array/string passed to a non-const parameter`) is intentionally suppressed via `-w239` because it originates from legacy SA-MP `SendRconCommand` non-const signature compatibility under `pawn-lang/compiler` v3.10.10. No broader warning classes are suppressed.
  - Immediately purges generated `.amx` binaries to preserve repository hygiene.

### Layer C — Live Runtime Regression
Layer C verifies actual plugin behavior within genuine 32-bit SA-MP dedicated servers (`samp03svr` on Linux, `samp-server.exe` on Windows).
- **Orchestration**: Executed via repository-owned cross-platform runner `scripts/run_regression.py`.
- **Permanent Suites Tested (13 Suites, 179 Assertions)**:
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
  12. `amx_unload_cleanup`: 14 / 14 PASS (U1–U14)
  13. `callback_error_recovery`: 14 / 14 PASS (F1–F14)
- **Cumulative Assertion Requirement**:
  - **Linux x86**: **179 / 179 PASS (100%)**
  - **Windows x86**: **179 / 179 PASS (100%)**

### Layer D — Release Packaging & Deployment Verification
Layer D verifies that distributed prebuilt archives conform to the distribution specification and boot cleanly in an isolated downstream server environment without access to repository source code.
- **Deterministic Packaging (`scripts/package_release.py --platform <target>`)**:
  - Produces byte-reproducible `.tar.gz` and `.zip` archives with outer `SHA256SUMS.txt` using `SOURCE_DATE_EPOCH`.
  - Embeds mandatory `LICENSE`, documentation, include header, example, and `BUILD_INFO.txt`.
- **Package Contract Audit (`tests/release_contract/check_release_package.py`)**:
  - Validates all 12 distribution contracts (PK1–PK12 = 12 / 12 PASS): archive presence, file structure, binary architecture (ELF32 on Linux, PE32 on Windows), public header equality, checksum manifest integrity, permissions, and strict exclusion of internal files (`src/`, `tests/`, `.git/`, `.github/`).
- **Package Deployment Smoke Test (`tests/release_contract/run_package_smoke.py`)**:
  - Extracts distribution archive into an isolated test environment without repository fallbacks.
  - Compiles `tests/release_contract/package_smoke.pwn` using extracted `sui.inc`.
  - Boots headless SA-MP server loading the extracted plugin binary (`sui-plugin-legacy.so` or `sui-plugin-legacy.dll`).
  - Asserts successful initialization, AMX native binding, and graceful server shutdown.

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

#### Linux / WSL:
1. **Provision Server**:
   ```bash
   python3 scripts/setup_test_server.py --platform linux-x86 --dest test-server
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
   python3 scripts/run_regression.py --platform linux-x86 --server-dir test-server
   ```

#### Windows:
1. **Provision Server**:
   ```powershell
   py scripts/setup_test_server.py --platform windows-x86 --dest test-server
   ```
2. **Build Plugin**:
   ```powershell
   cmake -S . -B build -A Win32
   cmake --build build --config Release
   copy build\Release\sui-plugin-legacy.dll test-server\plugins\
   ```
3. **Compile Fixtures into Server Layout**:
   ```powershell
   py scripts/compile_pawn.py --output-dir test-server
   ```
4. **Execute Regression Suites**:
   ```powershell
   py scripts/run_regression.py --platform windows-x86 --server-dir test-server
   ```

### Running Layer D (Packaging & Smoke Verification)

#### Linux:
```bash
SOURCE_DATE_EPOCH=1700000000 python3 scripts/package_release.py \
  --binary build/sui-plugin-legacy.so \
  --platform linux-x86 \
  --version 1.1.0 \
  --output-dir dist

python3 tests/release_contract/check_release_package.py \
  --dist dist \
  --platform linux-x86 \
  --version 1.1.0

python3 tests/release_contract/run_package_smoke.py \
  --platform linux-x86 \
  --archive dist/sui-plugin-1.1.0-linux-x86.tar.gz
```

#### Windows:
```powershell
$env:SOURCE_DATE_EPOCH = "1700000000"
py scripts/package_release.py `
  --binary build\Release\sui-plugin-legacy.dll `
  --platform windows-x86 `
  --version 1.1.0 `
  --output-dir dist

py tests/release_contract/check_release_package.py `
  --dist dist `
  --platform windows-x86 `
  --version 1.1.0

py tests/release_contract/run_package_smoke.py `
  --platform windows-x86 `
  --archive dist/sui-plugin-1.1.0-windows-x86.zip
```

---

## 5. GitHub Actions Continuous Integration

The GitHub Actions workflow is defined in [`.github/workflows/ci.yml`](../.github/workflows/ci.yml). It triggers automatically on all pushes and pull requests across all branches, executing two independent jobs:

### Job 1: `linux-x86-gates` (`ubuntu-24.04`)
1. **Layer A**: Runs static contract checkers (`check_api_surface.py`, `check_source_surface.py`) against Python 3.12.
2. **Layer B**: Installs multilib GCC, builds 32-bit Release plugin, asserts ELF32 architecture and canonical exports via `readelf`/`nm`, downloads Pawn compiler, and verifies 23 / 23 Pawn compilation.
3. **Layer C**: Provisions Linux SA-MP server via `setup_test_server.py --platform linux-x86`, deploys compiled test fixtures and `sui-plugin-legacy.so`, and executes all 13 suites via `run_regression.py --platform linux-x86`, asserting 179 / 179 passing assertions.
4. **Layer D**: Packages deterministic distribution archives, verifies PK1–PK12 distribution contracts, and executes isolated deployment smoke test.

### Job 2: `windows-x86-gates` (`windows-2022`)
1. **Layer A**: Runs static contract checkers (`check_api_surface.py`, `check_source_surface.py`) against Python 3.12.
2. **Layer B**: Configures MSVC Win32 (`-A Win32`, `/MT`), builds `sui-plugin-legacy.dll`, validates PE32 Intel 80386 architecture and exports via `tests/platform_contract/check_windows_binary.py`, audits static CRT via `dumpbin /dependents`, downloads Windows Pawn compiler, and verifies 23 / 23 Pawn compilation.
3. **Layer C**: Provisions Win32 SA-MP server via `setup_test_server.py --platform windows-x86`, deploys compiled test fixtures and `sui-plugin-legacy.dll`, and executes all 13 suites via `run_regression.py --platform windows-x86`, asserting 179 / 179 passing assertions.
4. **Layer D**: Packages deterministic Windows distribution archives, verifies PK1–PK12 distribution contracts, and executes isolated deployment smoke test.

---

## 6. Pre-Tag Verification & Release Gate Policy

All pre-tag release candidate gates must execute both `linux-x86-gates` and `windows-x86-gates` successfully, proving:
- **Zero Regressions:** 179 / 179 PASS on Linux x86 AND 179 / 179 PASS on Windows x86.
- **Contract Adherence:** 7 / 7 AP PASS, 6 / 6 RC PASS, 23 / 23 Pawn compilation PASS on both runners.
- **Distribution Integrity:** 12 / 12 PK PASS and isolated deployment smoke PASS on both platforms.
- **Cleanup Guarantee:** Servers and test harnesses terminated and purged cleanly in `always()` step on both platforms.
