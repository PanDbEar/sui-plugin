#!/usr/bin/env python3
"""
SUI Package Deployment Smoke Test Runner (SUI-015)

Verifies that a prebuilt SUI release package is 100% self-contained and functional:
1. Extracts prebuilt .tar.gz archive into an isolated temporary directory.
2. Proves Pawn include isolation: compiles smoke fixture pointing ONLY to extracted
   <extracted>/pawno/include (plus pinned standard libs); repository pawn/ is NOT referenced.
3. Proves binary isolation: deploys ONLY <extracted>/plugins/sui-plugin-legacy.so
   into a fresh server environment; build/sui-plugin-legacy.so is NOT referenced.
4. Executes server and verifies clean plugin loading, full callback lifecycle,
   active textdraw tracking, and clean exit.
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import time
from pathlib import Path


def find_repo_root() -> Path:
    cur = Path(__file__).resolve().parent
    while cur != cur.parent:
        if (cur / "pawn" / "sui.inc").exists() and (cur / "src" / "main.cpp").exists():
            return cur
        cur = cur.parent
    raise RuntimeError("Repository root not found from " + str(Path(__file__)))


def main():
    parser = argparse.ArgumentParser(description="Run SUI package deployment smoke test")
    parser.add_argument(
        "--archive",
        default="dist/sui-plugin-0.0.0-test-linux-x86.tar.gz",
        help="Path to release tar.gz archive",
    )
    parser.add_argument(
        "--compiler",
        default="tools/pawn/bin/pawncc",
        help="Path to pawncc compiler executable",
    )
    parser.add_argument(
        "--stdlibs",
        default="tools/pawn-stdlib,tools/samp-stdlib",
        help="Comma-separated paths to standard Pawn includes",
    )
    parser.add_argument(
        "--server-dir",
        default="test-server-smoke",
        help="Directory to set up isolated test server",
    )
    parser.add_argument(
        "--server-archive",
        default="",
        help="Optional local path to samp037svr_R2-1.tar.gz",
    )
    args = parser.parse_args()

    repo_root = find_repo_root()
    archive_path = (repo_root / args.archive).resolve()
    compiler_path = Path(args.compiler)
    if not compiler_path.is_absolute():
        compiler_path = (repo_root / compiler_path).resolve()
    server_dir = (repo_root / args.server_dir).resolve()
    fixture_pwn = (repo_root / "tests" / "release_contract" / "package_smoke.pwn").resolve()

    print("==================================================")
    print(" SUI PACKAGE-ONLY DEPLOYMENT SMOKE TEST (SUI-015) ")
    print("==================================================")

    if not archive_path.exists():
        print(f"[FAIL] Release archive not found: {archive_path}")
        sys.exit(1)

    if not compiler_path.exists():
        print(f"[FAIL] Pawn compiler not found: {compiler_path}")
        sys.exit(1)

    if not fixture_pwn.exists():
        print(f"[FAIL] Smoke fixture not found: {fixture_pwn}")
        sys.exit(1)

    # 1. Extract package into isolated temporary directory
    extract_temp = Path(tempfile.mkdtemp(prefix="sui_smoke_pkg_"))
    print(f"[EXTRACT] Extracting {archive_path.name} to {extract_temp}...")
    with tarfile.open(archive_path, "r:gz") as tar:
        tar.extractall(extract_temp)

    # Find extracted root (sui-plugin-<VERSION>)
    extracted_roots = [p for p in extract_temp.iterdir() if p.is_dir() and p.name.startswith("sui-plugin-")]
    if not extracted_roots:
        print("[FAIL] No sui-plugin-<VERSION> directory found in extracted package.")
        shutil.rmtree(extract_temp, ignore_errors=True)
        sys.exit(1)
    pkg_root = extracted_roots[0]
    pkg_so = pkg_root / "plugins" / "sui-plugin-legacy.so"
    pkg_inc_dir = pkg_root / "pawno" / "include"
    pkg_inc_file = pkg_inc_dir / "sui.inc"

    print(f"[ISOLATION-CHECK] Extracted package root: {pkg_root.name}")
    print(f"[ISOLATION-CHECK] Packaged plugin binary:  {pkg_so}")
    print(f"[ISOLATION-CHECK] Packaged Pawn include:   {pkg_inc_file}")

    if not pkg_so.exists():
        print(f"[FAIL] Missing packaged plugin binary: {pkg_so}")
        shutil.rmtree(extract_temp, ignore_errors=True)
        sys.exit(1)

    if not pkg_inc_file.exists():
        print(f"[FAIL] Missing packaged include: {pkg_inc_file}")
        shutil.rmtree(extract_temp, ignore_errors=True)
        sys.exit(1)

    # 2. Setup fresh test server
    print(f"[SERVER] Setting up fresh test server at {server_dir}...")
    if server_dir.exists():
        shutil.rmtree(server_dir)

    setup_cmd = [
        sys.executable,
        str(repo_root / "scripts" / "setup_test_server.py"),
        "--dest",
        str(server_dir),
    ]
    if args.server_archive and Path(args.server_archive).exists():
        setup_cmd.extend(["--archive", str(Path(args.server_archive).resolve())])
    elif (repo_root / "test-server" / "samp037svr_R2-1.tar.gz").exists():
        setup_cmd.extend(["--archive", str(repo_root / "test-server" / "samp037svr_R2-1.tar.gz")])

    setup_res = subprocess.run(setup_cmd, capture_output=True, text=True)
    if setup_res.returncode != 0:
        print(f"[FAIL] Failed to setup server: {setup_res.stderr}\n{setup_res.stdout}")
        shutil.rmtree(extract_temp, ignore_errors=True)
        sys.exit(1)

    # 3. Deploy ONLY the packaged .so binary into server/plugins
    plugins_dest = server_dir / "plugins"
    plugins_dest.mkdir(parents=True, exist_ok=True)
    shutil.copy2(pkg_so, plugins_dest / "sui-plugin-legacy.so")
    print(f"[DEPLOY] Deployed packaged binary ONLY: {plugins_dest / 'sui-plugin-legacy.so'}")

    # 4. Compile smoke fixture with Pawn include isolation
    gamemodes_dir = server_dir / "gamemodes"
    gamemodes_dir.mkdir(parents=True, exist_ok=True)
    output_amx = gamemodes_dir / "package_smoke.amx"

    # Build include arguments: ONLY extracted package pawno/include + stdlibs
    # Strictly NO repository pawn/ included!
    compile_cmd = [
        str(compiler_path),
        str(fixture_pwn),
        f"-o{output_amx}",
        f"-i{pkg_inc_dir}",
    ]
    for std in args.stdlibs.split(","):
        std_p = (repo_root / std.strip()).resolve()
        if std_p.exists():
            compile_cmd.append(f"-i{std_p}")

    compile_cmd.extend(["-d3", "-p:", "-w239"])

    # Prepare environment with LD_LIBRARY_PATH if needed for Linux pawncc
    proc_env = os.environ.copy()
    potential_lib = compiler_path.parent.parent / "lib"
    if potential_lib.exists() and (potential_lib / "libpawnc.so").exists():
        existing_ld = proc_env.get("LD_LIBRARY_PATH", "")
        proc_env["LD_LIBRARY_PATH"] = f"{potential_lib}:{existing_ld}" if existing_ld else str(potential_lib)

    print(f"[COMPILE] Compiling smoke fixture with strictly package-isolated include:")
    print(f"          Command: {' '.join(compile_cmd)}")
    comp_res = subprocess.run(compile_cmd, env=proc_env, capture_output=True, text=True)
    if comp_res.returncode != 0 or not output_amx.exists():
        print(f"[FAIL] Pawn compilation failed:\n{comp_res.stdout}\n{comp_res.stderr}")
        shutil.rmtree(extract_temp, ignore_errors=True)
        sys.exit(1)
    print(f"[OK] Compiled package_smoke.amx ({output_amx.stat().st_size} bytes)")

    # 5. Configure server.cfg
    cfg_file = server_dir / "server.cfg"
    cfg_content = (
        "echo Executing Server Config...\n"
        "lanmode 0\n"
        "rcon_password testpass\n"
        "maxplayers 10\n"
        "port 7777\n"
        "hostname SUI Package Smoke Test\n"
        "gamemode0 package_smoke 1\n"
        "plugins sui-plugin-legacy.so\n"
        "announce 0\n"
        "chatlogging 0\n"
        "weburl www.sa-mp.com\n"
        "onfoot_rate 40\n"
        "incar_rate 40\n"
        "weapon_rate 40\n"
        "stream_distance 300.0\n"
        "stream_rate 1000\n"
        "maxnpc 0\n"
        "logtimeformat [%H:%M:%S]\n"
    )
    cfg_file.write_text(cfg_content, encoding="utf-8")

    # 6. Execute server
    server_bin = server_dir / "samp03svr"
    os.chmod(server_bin, 0o755)
    log_file = server_dir / "server_log.txt"
    if log_file.exists():
        log_file.unlink()

    print(f"[RUN] Starting {server_bin}...")
    proc = subprocess.Popen(
        [str(server_bin)],
        cwd=server_dir,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )

    try:
        proc.wait(timeout=15)
    except subprocess.TimeoutExpired:
        print("[WARN] Server timed out; terminating process...")
        proc.kill()
        proc.wait()

    # 7. Analyze log output
    if not log_file.exists():
        print(f"[FAIL] Server log not found at {log_file}")
        shutil.rmtree(extract_temp, ignore_errors=True)
        sys.exit(1)

    log_text = log_file.read_text(encoding="utf-8", errors="replace")
    print("--------------------------------------------------")
    print(" SERVER LOG OUTPUT:")
    print("--------------------------------------------------")
    for line in log_text.splitlines():
        if any(tok in line for tok in ["Smart UI", "Mode", "Version", "SMOKE", "Loaded."]):
            print(f"  {line}")

    # Check assertions
    has_loaded = "Smart UI Virtualizer Loaded" in log_text or "Loaded." in log_text
    has_pass = "SUI package deployment smoke test PASS" in log_text
    has_fail = "[SMOKE-FAIL]" in log_text
    has_runtime_err = "Run time error" in log_text

    # Cleanup temp extraction
    shutil.rmtree(extract_temp, ignore_errors=True)

    print("--------------------------------------------------")
    if has_loaded and has_pass and not has_fail and not has_runtime_err:
        print("[OK] SUI package deployment smoke test PASS")
        print("==================================================")
        return 0
    else:
        print("[FAIL] SUI package deployment smoke test FAILED.")
        if not has_loaded:
            print("       Plugin failed to load.")
        if has_fail:
            print("       Smoke assertion failed.")
        if has_runtime_err:
            print("       Pawn runtime error encountered.")
        print("==================================================")
        return 1


if __name__ == "__main__":
    sys.exit(main())
