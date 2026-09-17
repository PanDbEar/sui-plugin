# SUI Phase 13: Repository Source Surface Contract Test Plan (RC1–RC5)

## Objective
Verify that the tracked source tree truthfully represents the architecture that is actually built and supported (SA-MP 0.3.7-R2 legacy plugin architecture targeting Linux x86 ELF32 with `-m32`). Eliminate orphaned components, dead compatibility headers, and uncompiled open.mp prototypes (`src/Component.cpp`, `src/Component.hpp`, `src/Compat.hpp`), ensuring 100% synchronization between tracked source files, CMake build targets, and active header includes.

---

## Static & Contract Verification Scenarios

| Test ID | Scope | Invariant / Target Specification | Method | Expected Outcome |
| :--- | :--- | :--- | :--- | :--- |
| **RC1** | CMake Source Alignment | All `.cpp` source files present in `src/` are explicitly listed in `CMakeLists.txt:set(SOURCES ...)`. Zero uncompiled or dangling C++ implementation units exist. | Automated Static Checker (`check_source_surface.py`) | Set equality across `src/*.cpp` and CMake sources (`['Core.cpp', 'Natives.cpp', 'main.cpp']`). |
| **RC2** | Banned Include Ban | Zero `#include` directives referencing `Component.hpp`, `Compat.hpp`, `<sdk.hpp>`, or open.mp component SDK headers exist in active source files or test scripts. | Automated Static Checker (`check_source_surface.py`) | 0 violations found. |
| **RC3** | Canonical Source Surface | The `src/` directory contains exactly the canonical 7 files: `Core.cpp`, `Core.hpp`, `main.cpp`, `Natives.cpp`, `Natives.hpp`, `Utils.hpp`, `sui-plugin-legacy.def`. No prototype, legacy wrapper, or dead code files exist. | Automated Static Checker (`check_source_surface.py`) | Exactly 7 files match canonical set. |
| **RC4** | Build Dependency Existence | All source and SDK dependency files listed in `CMakeLists.txt:SOURCES` resolve to existing, accessible files on disk. | Automated Static Checker (`check_source_surface.py`) | All 5 source paths exist on disk. |
| **RC5** | Orphan Deletion Verification | The orphaned prototype and compatibility files (`Component.cpp`, `Component.hpp`, `Compat.hpp`) are completely removed from both disk and git version control tracking. | Automated Static Checker (`check_source_surface.py`) | 0 disk orphans, 0 git tracked occurrences. |

---

## Execution Guidelines

Run the automated source surface checker:
```bash
python tests/repo_contract/check_source_surface.py
```

Run the public API contract checker:
```bash
python tests/api_contract/check_api_surface.py
```
