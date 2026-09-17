# SUI v1.1.0 Release Notes

**Release Version:** `v1.1.0`  
**Target Platforms:**
- SA-MP 0.3.7-R2 Dedicated Server (Linux x86 / ELF32 / Intel 80386)
- SA-MP 0.3.7-R2 Dedicated Server (Windows x86 / PE32 / Intel 386 / Win32)  
**Project License:** MIT License (Copyright (c) 2026 PanDbEar)

---

## 1. Overview & What Changed Since v1.0.0

SUI v1.1.0 establishes official **Windows x86 (Win32 / 32-bit PE DLL)** platform support for the Smart UI Virtualizer plugin, achieving 100% test assertion parity with the immutable v1.0.0 Linux baseline.

Key additions and improvements in this release:
- **Official Windows x86 Port:** Native MSVC Win32 32-bit PE DLL (sui-plugin-legacy.dll).
- **Self-Contained Deployment (/MT):** The Windows plugin is compiled with the static C/C++ runtime library (/MT), eliminating any external runtime DLL dependency (MSVCP140.dll or VCRUNTIME140.dll) on clean Windows SA-MP server hosts.
- **Canonical Export Contract:** A module definition file (src/sui-plugin-legacy.def) guarantees that all six SA-MP entry points (Supports, Load, Unload, AmxLoad, AmxUnload, ProcessTick) are exported as exact undecorated symbols without __stdcall mangling.
- **Platform-Qualified Package Manifests:** Outer integrity checksum manifests are now platform-qualified (sui-plugin-1.1.0-linux-x86-SHA256SUMS.txt and sui-plugin-1.1.0-windows-x86-SHA256SUMS.txt), preventing filename collisions in dual-platform distributions.
- **Dual-Runner CI Verification:** Automated continuous integration runs independent jobs on ubuntu-24.04 and windows-2022, enforcing all four evidence layers (Layers A–D) on both platforms.

---

## 2. Platform Support & Compatibility Matrix

| Platform | Binary | Format | Toolchain | CRT Linkage | SA-MP Target | Verified Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Linux x86** | sui-plugin-legacy.so | ELF32 (Intel 80386 DYN) | GCC multilib (-m32, C++20) | Dynamic (glibc 32-bit) | 0.3.7-R2 (samp03svr) | **VERIFIED (179/179 assertions)** |
| **Windows x86** | sui-plugin-legacy.dll | PE32 (Intel 386 DLL) | MSVC 2022 (-A Win32, C++20) | Static (/MT) | 0.3.7-R2 (samp-server.exe) | **VERIFIED (179/179 assertions)** |

### Platform Boundary Statements
- **Linux Retained:** Linux x86 ELF32 support is 100% preserved from v1.0.0 with zero regressions.
- **MinGW Deferred:** MinGW / GCC cross-compilation for Windows is **NOT officially supported** in this release. The pinned SA-MP plugin SDK relies on _MSC_VER + WIN32 x86 inline assembly thunks for AMX dispatch.
- **open.mp Not Verified:** Native open.mp Windows runtime operation has not been verified and is not covered by this release contract.

---

## 3. Public API & Lifecycle Contract

The public Pawn API surface remains **strictly frozen and unchanged**:
- Exactly **20 C++ natives**
- Exactly **1 Pawn stock helper** (SUI_RegisterGroup)
- Zero added, zero removed, zero renamed natives

### SUI-016 Lifecycle Requirement
To prevent PlayerTextDraw handle leaks when filterscripts or gamemodes unload dynamically, scripts that allocate UI groups must invoke SUI_CleanupOwnerGroups() during OnFilterScriptExit or OnGameModeExit. This allows SUI to execute cbHide and cbDestroy within the still-valid AMX context before script memory is unmapped.

### SUI-018 Mitigation Boundary
SUI-018 remains classified as **MITIGATED**. SUI provides internal group recovery quarantine (`recoveryDestroyRequired = true`) and compensating destroy attempts when in-flight callback execution errors occur. However, raw untracked host PlayerTextDraw handles allocated by user code that are not bound to SUI lifecycle state remain outside SUI ownership.

---

## 4. Canonical Distribution Assets

Each release provides six deterministic, byte-reproducible custom distribution assets:

### Linux x86 Distribution
- sui-plugin-1.1.0-linux-x86.tar.gz (POSIX tarball)
- sui-plugin-1.1.0-linux-x86.zip (Universal zip archive)
- sui-plugin-1.1.0-linux-x86-SHA256SUMS.txt (Outer SHA-256 checksum manifest)

### Windows x86 Distribution
- sui-plugin-1.1.0-windows-x86.zip (Primary Windows zip archive)
- sui-plugin-1.1.0-windows-x86.tar.gz (Compressed tar archive)
- sui-plugin-1.1.0-windows-x86-SHA256SUMS.txt (Outer SHA-256 checksum manifest)

Each package archive extracts into root sui-plugin-1.1.0/ containing the platform binary, public include (sui.inc), factory login example, API documentation, build instructions, license, build traceability metadata (BUILD_INFO.txt), and internal SHA256SUMS.

---

## 5. Server Installation Guide

### Linux Deployment
1. Copy plugins/sui-plugin-legacy.so to your server's plugins/ directory.
2. Add plugins sui-plugin-legacy.so to server.cfg.
3. Copy pawno/include/sui.inc to your compiler's include directory.
4. Include #include <sui> in your script.

### Windows Deployment
1. Copy plugins\sui-plugin-legacy.dll to your server's plugins\ directory.
2. Add plugins sui-plugin-legacy to server.cfg (Windows SA-MP does not use the .dll extension).
3. Copy pawno\include\sui.inc to your compiler's include directory.
4. Include #include <sui> in your script.
