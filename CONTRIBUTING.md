# Contributing to SUI

Thank you for your interest in contributing to **SUI (Smart UI Virtualizer)**.

To maintain stability, predictability, and clean public repository standards, all contributors are expected to follow the guidelines below.

---

## 1. Development Environment & Technical Standards

- **Primary Target Environment:** Linux x86 (32-bit ELF) legacy plugin mode for SA-MP and open.mp.
- **Verification Status:** Linux 32-bit is the primary verified target. Windows / MSVC 32-bit is not currently verified.
- **C++ Standard:** **C++20** (`set(CMAKE_CXX_STANDARD 20)`).
- **Architecture Requirement:** 32-bit (`-m32`). SA-MP and legacy open.mp plugin interfaces require 32-bit binaries.
- **Continuous Integration:** Note that automated CI is **not currently configured**. Local verification is mandatory prior to submitting contributions.

---

## 2. Clean Build Procedure

Always verify builds in a clean, out-of-source build directory:

```bash
# Configure clean build
cmake -S . -B build-verify -DCMAKE_BUILD_TYPE=Release

# Compile
cmake --build build-verify --config Release -j$(nproc)

# Verify 32-bit architecture
file build-verify/sui-plugin-legacy.so
```

Do not commit any build artifacts (`build/`, `*.so`, `*.o`, `CMakeCache.txt`, etc.). Ensure `.gitignore` is respected.

---

## 3. Code Style & Architecture Expectations

- Use modern, safe C++20 constructs while adhering strictly to legacy AMX C interfaces.
- Avoid raw pointer ownership where possible; respect AMX memory life cycles.
- Do NOT perform direct container modifications inside callback iteration loops (see `docs/KNOWN_ISSUES.md` issue `SUI-001`).
- Validate all parameter ranges, indices, and signed/unsigned boundaries before passing them to core routines.
- Maintain documentation integrity: preserve all existing comments and docstrings.

---

## 4. Public API Synchronization

Any addition, modification, or removal of a native function, callback, or constant must remain synchronized across the entire codebase.

Contributors making API modifications must complete the following checklist:

## Public API synchronization checklist

[ ] Native implemented in C++
[ ] Native registered with AMX/plugin entrypoint
[ ] Native declared in pawn/sui.inc
[ ] Constants/helper stocks updated where applicable
[ ] API inventory updated
[ ] API reference updated
[ ] README updated where applicable
[ ] Examples updated
[ ] Tests updated

---

## 5. Bug Reports & Issue Registration

- When reporting bugs, reference existing issue IDs in `docs/KNOWN_ISSUES.md` if applicable.
- For crash or stability reports (e.g. server segfaults, memory corruption, AMX faults), provide reproduction steps, player count, and relevant console log snippets.
- See `SECURITY.md` for guidelines on reporting critical server stability and memory vulnerabilities.
