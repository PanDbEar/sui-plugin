# SUI — Build & Compilation Guide

This document describes how to compile the **SUI (Smart UI Virtualizer)** legacy plugin from source.

---

## 1. Supported Build Targets & Platform Status

The current known primary target is:
```text
Legacy SA-MP/open.mp-compatible plugin interface
Linux x86 / 32-bit
```

| Target Name | Interface Type | Architecture | Binary Output | Verification Status |
| :--- | :--- | :--- | :--- | :--- |
| `sui-plugin-legacy` (Linux / WSL) | Legacy Plugin (`AmxLoad`/`Supports`) | x86 (32-bit) | `sui-plugin-legacy.so` | **Verified (WSL Ubuntu 24.04)** |
| `sui-plugin-legacy` (Windows Native) | Legacy Plugin | x86 (32-bit) | `sui-plugin-legacy.dll` | **Not currently verified.** |
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

## 3. Windows / MSVC Build Status

> [!WARNING]
> **Windows builds are not currently verified.**
> The current `CMakeLists.txt` explicitly sets `-m32` (GCC/Clang flag) and hardcodes `-DLINUX` and `.so` extensions. Native MSVC builds require compiler-specific generator flags (`-A Win32`) and platform definition adaptations that have not yet been implemented or verified.

---

## 4. Server Deployment

1. Copy the compiled 32-bit `.so` binary to your server `plugins/` directory:
   ```bash
   cp build/sui-plugin-legacy.so /path/to/server/plugins/
   ```

2. Copy the Pawn include file to your compiler's include path:
   ```bash
   cp pawn/sui.inc /path/to/server/qawno/include/
   # or
   cp pawn/sui.inc /path/to/server/pawno/include/
   ```

3. Enable the plugin in your server configuration:

   **SA-MP (`server.cfg`)**:
   ```text
   plugins sui-plugin-legacy.so
   ```

   **open.mp (`config.json`)**:
   ```json
   {
       "pawn": {
           "legacy_plugins": [
               "sui-plugin-legacy"
           ]
       }
   }
   ```

---

## 5. Source Tree Synchronization & Exclusions
 
Under SUI-012, all orphaned prototypes and unreferenced compatibility headers (`src/Component.cpp`, `src/Component.hpp`, and `src/Compat.hpp`) were audited and permanently removed from the repository. All `.cpp` files in `src/` are 100% synchronized with `CMakeLists.txt:SOURCES`.
