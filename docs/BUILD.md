# SUI — Build & Compilation Guide

This document describes how to compile the **SUI (Smart UI Virtualizer)** legacy plugin from source.

---

## 1. Supported Build Targets & Platform Status

The supported platform targets for SUI are:
```text
Legacy SA-MP/open.mp-compatible 32-bit plugin interface:
1. Linux x86 (ELF32)
2. Windows x86 (Win32 PE32 DLL)
```

| Target Name | Interface Type | Architecture | Binary Output | Verification Status |
| :--- | :--- | :--- | :--- | :--- |
| `sui-plugin-legacy` (Linux) | Legacy Plugin (`AmxLoad`/`Supports`) | x86 (32-bit ELF) | `sui-plugin-legacy.so` | **Verified (Ubuntu 24.04 / GCC multilib)** |
| `sui-plugin-legacy` (Windows) | Legacy Plugin (`AmxLoad`/`Supports`) | x86 (Win32 PE32) | `sui-plugin-legacy.dll` | **Verified (Windows 2022 / MSVC /MT)** |
| `sui-component` (open.mp) | Native open.mp Component (`IComponent`) | x86 / x64 | N/A | **Not supported (removed under SUI-012)** |

> [!IMPORTANT]
> **Do not confuse legacy plugin compatibility with native open.mp component support.**
> SUI is strictly configured as a legacy 32-bit SA-MP/open.mp plugin. Modern open.mp native component prototypes (`IComponent`) were audited and removed under SUI-012 to ensure 100% truthfulness with the build system.

> [!NOTE]
> 64-bit builds are **not supported**. SA-MP server and open.mp legacy plugin hosts run strictly as 32-bit (x86) processes.

---

## 2. Linux 32-Bit Build Procedure (Primary Target)

### Prerequisites (Ubuntu / Debian)
Install CMake, standard build tools, and the 32-bit multilib compiler toolchain:

```bash
sudo apt update
sudo apt install -y build-essential cmake gcc-multilib g++-multilib
```

### Clean Build Instructions
From the repository root:

```bash
# 1. Configure in a clean verification build directory
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release

# 2. Compile the 32-bit shared library
cmake --build build --config Release -j$(nproc)
```

### Verifying Binary Architecture
Verify that the output is indeed a 32-bit ELF shared object:

```bash
file build/sui-plugin-legacy.so
# Expected output: ELF 32-bit LSB shared object, Intel 80386 ...
```

---

## 3. Windows Win32 / MSVC Build Procedure

### Prerequisites
- Visual Studio 2022 (or Visual Studio Build Tools) with the "Desktop development with C++" workload (includes MSVC x86/x64 tools and Windows SDK).
- CMake 3.20 or newer.

### Build Instructions
From the repository root (e.g. in `x64_x86 Cross Tools Command Prompt` or PowerShell):

```cmd
:: 1. Configure for 32-bit (x86 / Win32)
cmake -S . -B build -A Win32

:: 2. Compile Release configuration
cmake --build build --config Release
```

The compiled binary will be produced at:
```text
build\Release\sui-plugin-legacy.dll
```

### Static C Runtime (/MT) & Export Table
- SUI enforces static C Runtime (`/MT`) via `MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>"`, completely eliminating external dynamic MSVC dependencies (`MSVCP140.dll`, `VCRUNTIME140.dll`).
- The module definition file `src/sui-plugin-legacy.def` ensures all 6 canonical plugin entry points (`Supports`, `Load`, `Unload`, `AmxLoad`, `AmxUnload`, `ProcessTick`) are exported with exact, undecorated names.

### Verifying Windows PE32 Binary
Run the repository contract checker:
```cmd
py tests/platform_contract/check_windows_binary.py build\Release\sui-plugin-legacy.dll
```

---

## 4. Server Deployment

### Linux Servers
1. Copy `build/sui-plugin-legacy.so` to your server's `plugins/` directory.
2. In `server.cfg`, add:
   ```text
   plugins sui-plugin-legacy.so
   ```

### Windows Servers
1. Copy `build\Release\sui-plugin-legacy.dll` to your server's `plugins/` directory.
2. In `server.cfg`, add:
   ```text
   plugins sui-plugin-legacy
   ```

### Pawn Script Configuration (All Platforms)
Copy `pawn/sui.inc` to your compiler's include path (`pawno/include/` or `qawno/include/`), then add `#include <sui>` to your gamemode or filterscript.

---

## 5. Source Tree Synchronization & Exclusions
 
Under SUI-012, all orphaned prototypes and unreferenced compatibility headers (`src/Component.cpp`, `src/Component.hpp`, and `src/Compat.hpp`) were audited and permanently removed from the repository. All `.cpp` files in `src/` are 100% synchronized with `CMakeLists.txt:SOURCES`.
