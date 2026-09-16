#!/usr/bin/env python3
"""
SUI Repository Pawn Compiler & Fixture Verification Tool (SUI-014)

Provides reproducible, repository-owned compilation of all 18 Pawn scripts:
- 1 shipped example: examples/factory_login_example.pwn
- 17 regression test fixtures in tests/

Features:
- Automated discovery of all .pwn fixtures
- Auto-detection of pawncc on PATH, environment variable PAWNCC, or common local paths
- Verification of 0 errors and 0 warnings (Layer B check-only mode)
- Output layout generation (placing gamemodes in gamemodes/ and filterscripts in filterscripts/)
"""

import sys
import os
import re
import argparse
import subprocess
import shutil
import tempfile
from pathlib import Path

def find_repo_root():
    cur = Path(__file__).resolve().parent
    while cur != cur.parent:
        if (cur / "pawn" / "sui.inc").exists() and (cur / "CMakeLists.txt").exists():
            return cur
        cur = cur.parent
    raise RuntimeError("Repository root not found")

def discover_pwn_files(root: Path):
    """Finds all 18 tracked .pwn files in deterministic order."""
    all_files = sorted(list(root.glob("examples/**/*.pwn")) + list(root.glob("tests/**/*.pwn")))
    # Normalize paths
    return [f for f in all_files if f.is_file()]

def resolve_compiler(explicit_path: str = None):
    if explicit_path and Path(explicit_path).exists():
        return Path(explicit_path)
    
    env_path = os.environ.get("PAWNCC")
    if env_path and Path(env_path).exists():
        return Path(env_path)

    # Check PATH
    which_pawncc = shutil.which("pawncc") or shutil.which("pawncc.exe") or shutil.which("pawnc")
    if which_pawncc:
        return Path(which_pawncc)

    # Common fallback candidate paths
    candidates = [
        Path(r"C:\Users\alifc\Downloads\Project\Texture Studio\pawno\pawncc.exe"),
        Path("tools/pawn/bin/pawncc"),
        Path("pawno/pawncc.exe"),
        Path(r"C:\pawno\pawncc.exe"),
        Path(r"C:\samp\pawno\pawncc.exe"),
        Path("/usr/local/bin/pawncc"),
        Path("/usr/bin/pawncc"),
    ]
    for c in candidates:
        if c.exists():
            return c

    return None

def resolve_includes(explicit_path: str = None):
    if explicit_path and Path(explicit_path).exists():
        return Path(explicit_path)

    env_path = os.environ.get("SAMP_INCLUDE_PATH")
    if env_path and Path(env_path).exists():
        return Path(env_path)

    # Common fallback candidate paths
    candidates = [
        Path(r"C:\Users\alifc\Downloads\Project\Texture Studio\pawno\include"),
        Path("tools/samp-stdlib"),
        Path("tools/pawn-stdlib"),
        Path("pawno/include"),
        Path(r"C:\pawno\include"),
        Path(r"C:\samp\pawno\include"),
        Path("/usr/local/include/samp"),
        Path("/usr/include/samp"),
    ]
    for c in candidates:
        if c.exists() and (c / "a_samp.inc").exists():
            return c

    return None

def main():
    parser = argparse.ArgumentParser(description="Compile and verify SUI Pawn scripts.")
    parser.add_argument("--compiler", "--pawncc", dest="compiler", help="Path to pawncc binary")
    parser.add_argument("--includes", dest="includes", help="Path to SA-MP standard includes (containing a_samp.inc)")
    parser.add_argument("--check-only", action="store_true", help="Compile and verify 0 errors/warnings, immediately purging .amx")
    parser.add_argument("--output-dir", dest="output_dir", help="Directory to store compiled .amx files")
    parser.add_argument("--script", dest="script", help="Compile a specific .pwn file only")
    parser.add_argument("--list", action="store_true", help="List all 18 discovered .pwn files and exit")

    args = parser.parse_args()
    root = find_repo_root()
    pawn_inc = root / "pawn"

    pwn_files = discover_pwn_files(root)

    if args.list:
        print(f"Discovered {len(pwn_files)} Pawn files:")
        for idx, f in enumerate(pwn_files, 1):
            print(f"  {idx:2d}. {f.relative_to(root)}")
        return 0

    if args.script:
        target_path = Path(args.script).resolve()
        if not target_path.exists():
            target_path = root / args.script
        if not target_path.exists():
            print(f"Error: Specified script not found: {args.script}")
            return 1
        pwn_files = [target_path]

    compiler = resolve_compiler(args.compiler)
    if not compiler:
        print("ERROR: Pawn compiler ('pawncc') not found.")
        print("Please provide --compiler <path>, set PAWNCC environment variable, or ensure pawncc is on PATH.")
        return 2

    includes_list = []
    if args.includes:
        for inc_item in [item.strip() for item in args.includes.split(",") if item.strip()]:
            if inc_item and Path(inc_item).exists():
                includes_list.append(Path(inc_item).resolve())
    else:
        inc_resolved = resolve_includes()
        if inc_resolved:
            includes_list.append(inc_resolved)

    if not includes_list:
        print("ERROR: SA-MP includes directory (containing a_samp.inc) not found.")
        print("Please provide --includes <path>, set SAMP_INCLUDE_PATH environment variable, or place standard includes in pawno/include.")
        return 2

    # Prepare environment with LD_LIBRARY_PATH if needed for Linux pawncc
    proc_env = os.environ.copy()
    potential_lib = compiler.parent.parent / "lib"
    if potential_lib.exists() and (potential_lib / "libpawnc.so").exists():
        existing_ld = proc_env.get("LD_LIBRARY_PATH", "")
        proc_env["LD_LIBRARY_PATH"] = f"{potential_lib}:{existing_ld}" if existing_ld else str(potential_lib)

    output_dir = Path(args.output_dir).resolve() if args.output_dir else None
    if output_dir:
        output_dir.mkdir(parents=True, exist_ok=True)
        (output_dir / "gamemodes").mkdir(parents=True, exist_ok=True)
        (output_dir / "filterscripts").mkdir(parents=True, exist_ok=True)

    print("=================================================================")
    print(" SUI REPOSITORY PAWN COMPILER (SUI-014)")
    print("=================================================================")
    print(f"Compiler:  {compiler}")
    print(f"Includes:  {[str(p) for p in includes_list]}")
    print(f"SUI Inc:   {pawn_inc}")
    print(f"Mode:      {'Check-Only (Purge AMX)' if args.check_only else ('Output to ' + str(output_dir) if output_dir else 'In-Place Compilation')}")
    print(f"Targets:   {len(pwn_files)} script(s)")
    print("=================================================================")

    passed_count = 0
    failed_count = 0

    for pwn in pwn_files:
        rel = pwn.relative_to(root)
        is_fs = "filterscript" in pwn.stem.lower()

        if output_dir:
            subdir = "filterscripts" if is_fs else "gamemodes"
            amx_out = output_dir / subdir / f"{pwn.stem}.amx"
        elif args.check_only:
            # Use temporary amx alongside
            amx_out = pwn.with_suffix(".amx")
        else:
            amx_out = pwn.with_suffix(".amx")

        cmd = [
            str(compiler),
            str(pwn),
        ]
        for inc_dir in includes_list:
            cmd.append(f"-i{inc_dir}")
        cmd.extend([
            f"-i{pawn_inc}",
            "-d3",
            "-p:",
            "-w239",
            f"-o{amx_out}"
        ])

        try:
            res = subprocess.run(cmd, capture_output=True, text=True, env=proc_env)
            output = (res.stdout or "") + (res.stderr or "")

            has_error = "Error" in output or "error" in output
            has_warning = "Warning" in output or "warning" in output

            # Also verify amx was actually generated if no errors
            amx_created = amx_out.exists()

            if args.check_only and amx_created:
                amx_out.unlink()

            if res.returncode == 0 and not has_error and not has_warning and (amx_created or args.check_only):
                print(f"[PASS] {str(rel):52s} 0 errors, 0 warnings")
                passed_count += 1
            else:
                print(f"[FAIL] {str(rel):52s}")
                print("--- Output ---")
                print(output.strip())
                print("--------------")
                failed_count += 1
                if amx_out.exists():
                    amx_out.unlink()

        except Exception as e:
            print(f"[ERROR] Failed to execute compiler for {rel}: {e}")
            failed_count += 1

    print("=================================================================")
    print(f" COMPILATION RESULT: {passed_count} / {len(pwn_files)} PASSED")
    print("=================================================================")

    return 0 if failed_count == 0 else 1

if __name__ == "__main__":
    sys.exit(main())
