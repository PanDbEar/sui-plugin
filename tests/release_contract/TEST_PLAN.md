# SUI Release Contract Test Plan (SUI-015)

## Overview

This test plan formalizes the verification criteria for SUI distribution packages under issue **SUI-015**. The test suite guarantees that prebuilt release archives delivered to downstream SA-MP server administrators are deterministic, self-contained, architecturally compliant, integrity-verified, and free from internal development or proprietary files.

---

## Test Cases

| Check ID | Name | Description | Acceptance Criteria |
| :--- | :--- | :--- | :--- |
| **PK1** | Tar Archive Existence | Verify `sui-plugin-<VERSION>-<PLATFORM>.tar.gz` exists in distribution directory. | File exists, is regular file, size > 0. |
| **PK2** | Zip Archive Existence | Verify `sui-plugin-<VERSION>-<PLATFORM>.zip` exists in distribution directory. | File exists, is regular file, size > 0. |
| **PK3** | Root & Allowlist Match | Verify archive root directory is `sui-plugin-<VERSION>/` and internal layout exactly matches the allowlist in both archives. | All allowlisted files present; 0 extraneous files. |
| **PK4** | Forbidden Files Absence | Verify archives contain no internal source, build, git, test, compiler, or server binaries, nor cross-platform binaries. | Zero matches for `src/`, `tests/`, `.git/`, `.github/`, `build/`, `lib/`, `samp03svr`, `samp-server.exe`, `pawncc`, `*.o`, `*.cpp`, `*.hpp`. |
| **PK5** | Binary Architecture | Verify extracted binary is ELF32 Intel 80386 ET_DYN (Linux) or PE32 Intel 386 DLL (Windows). | Platform-specific header valid. 64-bit strictly rejected. |
| **PK6** | Canonical Plugin Exports | Verify extracted plugin binary exports all 6 canonical SA-MP entry points. | `Supports`, `Load`, `Unload`, `AmxLoad`, `AmxUnload`, `ProcessTick` all present in export symbol table. |
| **PK7** | Public Include Integrity | Verify packaged `pawno/include/sui.inc` matches repository `pawn/sui.inc` byte-for-byte. | SHA-256 identical, byte length identical. |
| **PK8** | Internal SHA256SUMS Verification | Verify internal `SHA256SUMS` manifest matches SHA-256 hashes of all files in archive. | All listed files pass checksum verification. |
| **PK9** | Outer Integrity Manifest Verification | Verify `sui-plugin-<VERSION>-SHA256SUMS.txt` accurately validates `.tar.gz` and `.zip` archives. | Both outer archives pass checksum verification. |
| **PK10** | Archive Path Safety | Verify no path traversal (`../`), drive letters, or absolute paths exist; ZIP entries use POSIX `/`. | All paths begin with `sui-plugin-<VERSION>/` and contain no traversal tokens. |
| **PK11** | Build Traceability Alignment | Verify `BUILD_INFO.txt` records matching version, git commit, target platform architecture, and SDK pin. | Version matches package version; SDK submodule pin is `a5ce36a9b6ebbea6ad36705603f653bf3d4f41c5`. |
| **PK12** | MIT License Validation | Verify repository root and both release archives contain identical canonical MIT LICENSE file with copyright year 2026 and PanDbEar holder. | File exists in repo, tar, zip; matches byte-for-byte; starts with 'MIT License'; contains 'Copyright (c) 2026 PanDbEar'. |

---

## Allowed Package Contents

Each release archive must contain strictly (10 items under `sui-plugin-<VERSION>/`):
- `sui-plugin-<VERSION>/plugins/sui-plugin-legacy.so` (Linux) OR `sui-plugin-<VERSION>/plugins/sui-plugin-legacy.dll` (Windows)
- `sui-plugin-<VERSION>/pawno/include/sui.inc`
- `sui-plugin-<VERSION>/examples/factory_login_example.pwn`
- `sui-plugin-<VERSION>/docs/API_REFERENCE.md`
- `sui-plugin-<VERSION>/docs/BUILD.md`
- `sui-plugin-<VERSION>/README.md`
- `sui-plugin-<VERSION>/CHANGELOG.md`
- `sui-plugin-<VERSION>/LICENSE`
- `sui-plugin-<VERSION>/BUILD_INFO.txt`
- `sui-plugin-<VERSION>/SHA256SUMS`

---

## Execution Instructions

```bash
python tests/release_contract/check_release_package.py \
  --dist dist \
  --version <VERSION>
```
