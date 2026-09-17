# SUI Release & Distribution Specification (SUI-015)

**Document Version:** 1.1.0 (Phase 19 Multi-Platform Release Baseline)  
**Target Platform:** SA-MP 0.3.7-R2 Legacy:
- Linux x86 (ELF32 / Intel 80386 / `-m32`)
- Windows x86 (PE32 / Intel 80386 / Win32 MSVC `/MT`)  
**Project License:** MIT License  

---

## 1. Overview

This document specifies the official distribution contract, artifact naming conventions, package layout, verification procedures, and deployment instructions for the Smart UI Virtualizer (SUI) plugin.

SUI releases provide self-contained, prebuilt binary distribution archives designed for SA-MP server administrators on both Linux and Windows. Downstream users do not need to clone the git repository, compile C++ sources, or run development toolchains.

---

## 2. Project Licensing

The SUI project is licensed under the **MIT License**.

- **Copyright:** Copyright (c) 2026 PanDbEar
- **License File:** All official binary release packages bundle `LICENSE` at the root of the distribution directory.
- **Third-Party Notices:** The plugin binary statically links portions of `samp-plugin-sdk` (Pawn Abstract Machine header Copyright (c) 1997-2005 ITB CompuPhase, under zlib/libpng license; plugin SDK Copyright (c) 2004-2009 SA-MP Team). External test servers and Pawn compilers used during CI validation are acquired externally and are not redistributed in SUI release packages.

---

## 3. Canonical Distribution Archives

Each release produces prebuilt platform-specific archives and an outer integrity checksum manifest:

### Linux x86 Archives
| Artifact Name | Format | Description |
| :--- | :--- | :--- |
| `sui-plugin-<VERSION>-linux-x86.tar.gz` | POSIX tarball (gzip) | Primary Linux distribution archive with normalized permissions and deterministic headers. |
| `sui-plugin-<VERSION>-linux-x86.zip` | Zip archive (deflated) | Universal archive with normalized POSIX directory separators (`/`). |
| `sui-plugin-<VERSION>-linux-x86-SHA256SUMS.txt` | Text manifest | External SHA-256 checksums of both Linux distribution archives. |

### Windows x86 Archives
| Artifact Name | Format | Description |
| :--- | :--- | :--- |
| `sui-plugin-<VERSION>-windows-x86.zip` | Zip archive (deflated) | Primary Windows distribution archive with normalized directory separators. |
| `sui-plugin-<VERSION>-windows-x86.tar.gz` | POSIX tarball (gzip) | Compressed tar archive for automated deployment pipelines. |
| `sui-plugin-<VERSION>-windows-x86-SHA256SUMS.txt` | Text manifest | External SHA-256 checksums of both Windows distribution archives. |

### Architecture Contracts
- **Linux x86:**
  - Format: ELF32 (Intel 80386), DYN (Shared object file), dynamically linked, `-m32` required.
  - Binary: `plugins/sui-plugin-legacy.so`
- **Windows x86:**
  - Format: PE32 (Intel 80386), Dynamic Link Library (DLL), MSVC `/MT` static C/C++ runtime (zero external MSVC DLL dependencies).
  - Exports defined via `src/sui-plugin-legacy.def`.
  - Binary: `plugins/sui-plugin-legacy.dll`
- **Canonical Exports (6 on both platforms):** `Supports`, `Load`, `Unload`, `AmxLoad`, `AmxUnload`, `ProcessTick`.

---

## 4. Package Directory Structure

Every archive extracts into a single top-level directory: `sui-plugin-<VERSION>/`.

```text
sui-plugin-<VERSION>/
├── plugins/
│   └── sui-plugin-legacy.so      # (Linux) Validated ELF32 Intel 80386 shared object
│   └── sui-plugin-legacy.dll     # (Windows) Validated PE32 Intel 80386 Win32 DLL (/MT)
├── pawno/
│   └── include/
│       └── sui.inc               # Public Pawn API include (20 C++ natives + 1 Pawn stock helper)
├── examples/
│   └── factory_login_example.pwn # Reference factory UI implementation
├── docs/
│   ├── API_REFERENCE.md          # Complete public API reference
│   └── BUILD.md                  # Source compilation & toolchain guide (GCC multilib & MSVC Win32)
├── README.md                     # Project overview and quick start
├── CHANGELOG.md                  # Project version history and issue ledger
├── LICENSE                       # Canonical MIT License
├── BUILD_INFO.txt                # Build traceability metadata (Platform target, Git commit, SDK pin)
└── SHA256SUMS                    # Internal SHA-256 manifest of all packaged files
```

### Exclusions
The release package strictly excludes repository internal files:
- Zero C++ source files (`src/`, `*.cpp`, `*.hpp`, `*.h`, `*.def`)
- Zero test fixtures or harnesses (`tests/`, `*.amx`, `*.o`)
- Zero Git metadata (`.git/`, `.github/`)
- Zero build artifacts (`build/`, `CMakeCache.txt`)
- Zero proprietary server binaries (`samp03svr`, `samp-server.exe`, `announce`, `server.cfg`)
- Zero compiler binaries (`pawncc`, `pawnc`)

---

## 5. Integrity Verification

### Verifying Downloaded Archives
Before extracting, verify archive SHA-256 checksums against the platform checksum manifest:

On Linux:
```bash
sha256sum -c sui-plugin-<VERSION>-linux-x86-SHA256SUMS.txt
```

On Windows (PowerShell):
```powershell
Get-FileHash sui-plugin-<VERSION>-windows-x86.zip -Algorithm SHA256
```

### Verifying Extracted Files
After extraction, verify internal files against `SHA256SUMS`:

```bash
cd sui-plugin-<VERSION>
sha256sum -c SHA256SUMS
```

---

## 6. Server Installation Guide

### Linux Deployment

1. **Deploy Plugin Binary**:
   Copy `plugins/sui-plugin-legacy.so` into your SA-MP server's `plugins/` directory:
   ```bash
   cp plugins/sui-plugin-legacy.so /path/to/server/plugins/
   ```

2. **Configure `server.cfg`**:
   Add `sui-plugin-legacy.so` to the `plugins` line in `server.cfg`:
   ```text
   plugins sui-plugin-legacy.so
   ```

3. **Install Pawn Include**:
   Copy `pawno/include/sui.inc` into your Pawn include directory:
   ```bash
   cp pawno/include/sui.inc /path/to/server/pawno/include/
   ```

### Windows Deployment

1. **Deploy Plugin Binary**:
   Copy `plugins/sui-plugin-legacy.dll` into your SA-MP server's `plugins\` directory:
   ```cmd
   copy plugins\sui-plugin-legacy.dll C:\path\to\server\plugins\
   ```

2. **Configure `server.cfg`**:
   Add `sui-plugin-legacy` to the `plugins` line in `server.cfg` (Windows SA-MP does not use the `.dll` extension):
   ```text
   plugins sui-plugin-legacy
   ```

3. **Install Pawn Include**:
   Copy `pawno\include\sui.inc` into your Pawn include directory:
   ```cmd
   copy pawno\include\sui.inc C:\path\to\server\pawno\include\
   ```

### Gamemode Usage
Include SUI in your gamemode or filterscript:
```pawn
#include <sui>
```

---

## 7. Version Authority & Test Packages

- **Official Release Authority:** Official version numbers are derived strictly from Git release tags (`refs/tags/v*`).
- **CI Test Packages:** Version strings such as `0.0.0-test` represent non-official, dry-run test packages generated by CI pipelines to validate packaging mechanics and release contracts. **Test packages are NOT official releases and are not intended for public server deployment.**
