#!/usr/bin/env python3
"""
SUI Repository Contract Surface Checker (SUI-012)

Performs static verification to guarantee:
- RC1: All tracked .cpp in src/ are listed in CMake SOURCES.
- RC2: No banned includes (Component.hpp, Compat.hpp, <sdk.hpp>) exist in src/ or tests/.
- RC3: src/ contains exactly the canonical 7 files (Core.cpp, Core.hpp, main.cpp, Natives.cpp, Natives.hpp, Utils.hpp, sui-plugin-legacy.def).
- RC4: All files listed in CMake SOURCES exist on disk.
- RC5: Orphaned Component/Compat files are absent from src/ and git index.
- RC6: Portable automation path contract: scripts/, .github/workflows/, tests/ contain 0 developer-specific path literals.
"""

import sys
import os
import re
import subprocess
from pathlib import Path

def find_repo_root():
    cur = Path(__file__).resolve().parent
    while cur != cur.parent:
        if (cur / "pawn" / "sui.inc").exists() and (cur / "src" / "main.cpp").exists():
            return cur
        cur = cur.parent
    raise RuntimeError("Repository root not found")

def main():
    root = find_repo_root()
    src_dir = root / "src"
    cmake_path = root / "CMakeLists.txt"

    print("==================================================")
    print(" SUI REPOSITORY CONTRACT SURFACE CHECKER (SUI-012)")
    print("==================================================")

    checks_passed = 0
    total_checks = 0

    # Read CMakeLists.txt
    with open(cmake_path, "r", encoding="utf-8") as f:
        cmake_content = f.read()

    # Parse SOURCES from CMakeLists.txt
    sources_match = re.search(r"set\s*\(\s*SOURCES\s*(.*?)\)", cmake_content, re.DOTALL)
    if not sources_match:
        print("[FAIL] Could not find set(SOURCES ...) in CMakeLists.txt")
        return 1

    raw_sources = sources_match.group(1).split()
    cmake_src_files = []
    cmake_all_resolved = []
    for s in raw_sources:
        s_clean = s.strip()
        if not s_clean or s_clean.startswith("#"):
            continue
        # replace ${SAMP_SDK_DIR}
        resolved = s_clean.replace("${SAMP_SDK_DIR}", "lib/samp-plugin-sdk")
        cmake_all_resolved.append(root / resolved)
        if resolved.startswith("src/"):
            cmake_src_files.append(Path(resolved).name)

    # 1. RC1: All tracked .cpp in src/ are listed in CMake SOURCES
    total_checks += 1
    src_cpp_files = sorted([f.name for f in src_dir.glob("*.cpp")])
    unlisted_cpp = [f for f in src_cpp_files if f not in cmake_src_files]
    if not unlisted_cpp and set(src_cpp_files) == set(cmake_src_files):
        checks_passed += 1
        print(f"[RC1] PASS: All {len(src_cpp_files)} .cpp files in src/ are listed in CMake SOURCES: {src_cpp_files}")
    else:
        print(f"[RC1] FAIL: Discrepancy between src/*.cpp and CMake SOURCES: unlisted={unlisted_cpp}")

    # 2. RC2: No banned includes in src/ or tests/
    total_checks += 1
    banned_patterns = [
        re.compile(r'#include\s*["<]Component\.hpp[">]'),
        re.compile(r'#include\s*["<]Compat\.hpp[">]'),
        re.compile(r'#include\s*<sdk\.hpp>'),
    ]
    banned_violations = []

    scan_dirs = [src_dir, root / "tests"]
    for sdir in scan_dirs:
        for p in sdir.rglob("*"):
            if p.is_file() and p.suffix in (".cpp", ".hpp", ".h", ".pwn", ".inc"):
                try:
                    with open(p, "r", encoding="utf-8", errors="replace") as f:
                        for idx, line in enumerate(f, 1):
                            for bpat in banned_patterns:
                                if bpat.search(line):
                                    banned_violations.append(f"{p.relative_to(root)}:{idx}: {line.strip()}")
                except Exception as e:
                    banned_violations.append(f"Error reading {p}: {e}")

    if not banned_violations:
        checks_passed += 1
        print("[RC2] PASS: Zero banned includes (Component.hpp, Compat.hpp, <sdk.hpp>) found in active source/test trees.")
    else:
        print(f"[RC2] FAIL: Banned includes found: {banned_violations}")

    # 3. RC3: src/ contains exactly the canonical 7 files
    total_checks += 1
    expected_src_files = {
        "Core.cpp",
        "Core.hpp",
        "main.cpp",
        "Natives.cpp",
        "Natives.hpp",
        "Utils.hpp",
        "sui-plugin-legacy.def",
    }
    actual_src_files = set(f.name for f in src_dir.iterdir() if f.is_file())
    if actual_src_files == expected_src_files:
        checks_passed += 1
        print(f"[RC3] PASS: src/ contains exactly the canonical 7 files: {sorted(list(expected_src_files))}")
    else:
        extra = actual_src_files - expected_src_files
        missing = expected_src_files - actual_src_files
        print(f"[RC3] FAIL: src/ inventory mismatch: extra={extra}, missing={missing}")

    # 4. RC4: All files listed in CMake SOURCES exist on disk
    total_checks += 1
    missing_sources = [str(p.relative_to(root)) for p in cmake_all_resolved if not p.exists()]
    if not missing_sources:
        checks_passed += 1
        print(f"[RC4] PASS: All {len(cmake_all_resolved)} files in CMake SOURCES exist on disk.")
    else:
        print(f"[RC4] FAIL: Missing CMake source files on disk: {missing_sources}")

    # 5. RC5: Orphaned Component/Compat files absent from src/ and git index
    total_checks += 1
    orphaned_names = ["Component.cpp", "Component.hpp", "Compat.hpp"]
    disk_orphans = [name for name in orphaned_names if (src_dir / name).exists()]

    # Check git tracked files if git available
    git_orphans = []
    try:
        res = subprocess.run(
            ["git", "ls-files", "src/Component.*", "src/Compat.*"],
            cwd=str(root),
            capture_output=True,
            text=True,
            check=False
        )
        if res.returncode == 0 and res.stdout.strip():
            git_orphans = res.stdout.strip().splitlines()
    except Exception:
        pass

    if not disk_orphans and not git_orphans:
        checks_passed += 1
        print("[RC5] PASS: Orphaned Component/Compat files completely absent from disk and tracked git index.")
    else:
        print(f"[RC5] FAIL: Orphaned files still present: disk={disk_orphans}, git_tracked={git_orphans}")

    # 6. RC6: Portable automation path contract (zero developer-specific path literals)
    total_checks += 1
    banned_patterns = [
        re.compile(r"C:\\Users\\alifc", re.IGNORECASE),
        re.compile(r"/home/pandbear", re.IGNORECASE),
        re.compile(r"/mnt/c/Users/alifc", re.IGNORECASE),
        re.compile(r"\.gemini[/\\]"),
        re.compile(r"Texture Studio", re.IGNORECASE),
    ]
    scan_targets = [
        root / "scripts",
        root / ".github" / "workflows",
        root / "tests",
    ]
    path_violations = []
    this_file = Path(__file__).resolve()
    for target_dir in scan_targets:
        if not target_dir.exists():
            continue
        for p in target_dir.rglob("*"):
            if not p.is_file() or p.resolve() == this_file:
                continue
            if p.suffix in [".py", ".sh", ".yml", ".yaml"]:
                try:
                    content = p.read_text(encoding="utf-8", errors="replace")
                    for pat in banned_patterns:
                        m = pat.search(content)
                        if m:
                            path_violations.append(f"{p.relative_to(root)}: '{m.group(0)}'")
                except Exception:
                    pass

    if not path_violations:
        checks_passed += 1
        print("[RC6] PASS: Portable automation path contract verified (developer-specific automation paths: 0).")
    else:
        print(f"[RC6] FAIL: Found {len(path_violations)} developer-specific path violation(s):")
        for v in path_violations:
            print(f"  - {v}")

    print("==================================================")
    print(f" TOTAL RESULT: {checks_passed} / {total_checks} CHECKS PASSED")
    print("==================================================")

    return 0 if checks_passed == total_checks else 1

if __name__ == "__main__":
    sys.exit(main())
