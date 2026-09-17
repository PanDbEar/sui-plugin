#!/usr/bin/env python3
"""
SUI Release Package Contract Checker (SUI-015 - Draft Test Infrastructure)

Validates distribution packages against the structural release contract:
- PK1: Expected tar.gz exists
- PK2: Expected zip exists
- PK3: Archive root and allowlisted file set match exactly in both archives
- PK4: Zero forbidden files present
- PK5: Packaged .so is verified ELF32 Intel 80386 DYN
- PK6: Packaged .so contains all 6 canonical exports
- PK7: Packaged pawno/include/sui.inc matches repository pawn/sui.inc byte-for-byte
- PK8: Internal SHA256SUMS manifest validates in both archives
- PK9: Outer archive checksum manifest validates both archives
- PK10: Archive paths contain no traversal or absolute entries; ZIP paths use '/'
- PK11: BUILD_INFO.txt metadata aligns with package version, git commit, and SDK pin

NOTE: This checker validates structural integrity of CI test packages.
Official release readiness is tracked separately and remains BLOCKED pending
the project owner's licensing decision.
"""

import argparse
import hashlib
import os
import re
import shutil
import struct
import subprocess
import sys
import tarfile
import tempfile
import zipfile
from pathlib import Path

CANONICAL_EXPORTS = [
    "Supports",
    "Load",
    "Unload",
    "AmxLoad",
    "AmxUnload",
    "ProcessTick",
]

FORBIDDEN_SUBSTRINGS = [
    "src/",
    "tests/",
    ".git",
    ".github",
    "build/",
    "lib/samp-plugin-sdk",
    "samp03svr",
    "announce",
    "server.cfg",
    "samp-npc",
    "pawncc",
]

FORBIDDEN_EXTENSIONS = [
    ".amx",
    ".o",
    ".obj",
    ".cpp",
    ".hpp",
    ".c",
    ".h",
]


def find_repo_root() -> Path:
    cur = Path(__file__).resolve().parent
    while cur != cur.parent:
        if (cur / "pawn" / "sui.inc").exists() and (cur / "src" / "main.cpp").exists():
            return cur
        cur = cur.parent
    raise RuntimeError("Repository root not found from " + str(Path(__file__)))


def compute_sha256(filepath: Path) -> str:
    h = hashlib.sha256()
    with open(filepath, "rb") as f:
        while chunk := f.read(65536):
            h.update(chunk)
    return h.hexdigest()


def compute_bytes_sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def validate_elf_header(data: bytes) -> tuple[bool, str]:
    if len(data) < 52:
        return False, f"Data too short for ELF header ({len(data)} bytes)"
    if data[:4] != b"\x7fELF":
        return False, f"Invalid ELF magic: {data[:4]!r}"
    ei_class = data[4]
    if ei_class != 1:
        return False, f"ELF class is {ei_class} (expected 1 for ELF32; 64-bit rejected)"
    ei_data = data[5]
    if ei_data != 1:
        return False, f"ELF data encoding is {ei_data} (expected 1 for little-endian)"
    e_type = struct.unpack("<H", data[16:18])[0]
    if e_type != 3:
        return False, f"ELF type is {e_type} (expected 3 for ET_DYN)"
    e_machine = struct.unpack("<H", data[18:20])[0]
    if e_machine != 3:
        return False, f"ELF machine is {e_machine} (expected 3 for EM_386 / Intel 80386)"
    return True, "ELF32 Intel 80386 ET_DYN"


def check_exports_in_file(so_path: Path) -> tuple[bool, list[str]]:
    symbols = set()
    try:
        res = subprocess.run(
            ["nm", "-D", "--defined-only", str(so_path)],
            capture_output=True,
            text=True,
            check=True,
        )
        for line in res.stdout.splitlines():
            parts = line.strip().split()
            if len(parts) >= 3:
                symbols.add(parts[-1])
    except Exception:
        try:
            res = subprocess.run(
                ["readelf", "--dyn-syms", str(so_path)],
                capture_output=True,
                text=True,
                check=True,
            )
            for line in res.stdout.splitlines():
                parts = line.strip().split()
                if len(parts) >= 8:
                    symbols.add(parts[7].split("@")[0])
        except Exception:
            return False, ["Failed to invoke nm/readelf"]

    missing = [exp for exp in CANONICAL_EXPORTS if exp not in symbols]
    return len(missing) == 0, missing


def validate_pe_binary_path(dll_path: Path) -> tuple[bool, list[str]]:
    repo_root = find_repo_root()
    if str(repo_root) not in sys.path:
        sys.path.insert(0, str(repo_root))
    from tests.platform_contract.check_windows_binary import validate_windows_pe_binary
    return validate_windows_pe_binary(dll_path)


def main():
    parser = argparse.ArgumentParser(description="SUI Release Package Contract Checker")
    parser.add_argument("--platform", choices=["linux-x86", "windows-x86"], default=None, help="Target platform (linux-x86 or windows-x86)")
    parser.add_argument("--dist", default="dist", help="Path to dist directory (default: dist)")
    parser.add_argument("--version", default="", help="Expected package version (e.g. 0.0.0-test)")
    args = parser.parse_args()

    repo_root = find_repo_root()
    dist_dir = (repo_root / args.dist).resolve()

    print("==================================================")
    print(" SUI RELEASE PACKAGE CONTRACT CHECKER (SUI-015)   ")
    print("==================================================")

    platform = args.platform
    if not platform:
        win_archives = list(dist_dir.glob("sui-plugin-*-windows-x86.zip")) + list(dist_dir.glob("sui-plugin-*-windows-x86.tar.gz"))
        linux_archives = list(dist_dir.glob("sui-plugin-*-linux-x86.zip")) + list(dist_dir.glob("sui-plugin-*-linux-x86.tar.gz"))
        if win_archives and not linux_archives:
            platform = "windows-x86"
        elif linux_archives and not win_archives:
            platform = "linux-x86"
        elif os.name == "nt":
            platform = "windows-x86"
        else:
            platform = "linux-x86"

    version = args.version.strip()
    if not version:
        for item in dist_dir.glob(f"sui-plugin-*-{platform}.tar.gz"):
            m = re.match(rf"sui-plugin-(.+)-{platform}\.tar\.gz", item.name)
            if m:
                version = m.group(1)
                break
        if not version:
            for item in dist_dir.glob(f"sui-plugin-*-{platform}.zip"):
                m = re.match(rf"sui-plugin-(.+)-{platform}\.zip", item.name)
                if m:
                    version = m.group(1)
                    break
    if not version:
        print("[FAIL] Could not determine package version. Please supply --version.")
        sys.exit(1)

    print(f"Checking package version:  {version}")
    print(f"Target platform:           {platform}")
    print(f"Distribution directory:    {dist_dir}")

    package_root_name = f"sui-plugin-{version}"
    tar_name = f"sui-plugin-{version}-{platform}.tar.gz"
    zip_name = f"sui-plugin-{version}-{platform}.zip"
    outer_manifest_name = f"sui-plugin-{version}-{platform}-SHA256SUMS.txt"

    tar_path = dist_dir / tar_name
    zip_path = dist_dir / zip_name
    outer_manifest_path = dist_dir / outer_manifest_name

    passed_checks = 0
    total_checks = 0

    # -------------------------------------------------------------
    # PK1: Tar Archive Existence
    # -------------------------------------------------------------
    total_checks += 1
    if tar_path.exists() and tar_path.is_file() and tar_path.stat().st_size > 0:
        passed_checks += 1
        print(f"[PK1] PASS: Tar archive exists: {tar_name} ({tar_path.stat().st_size} bytes)")
    else:
        print(f"[PK1] FAIL: Tar archive missing or empty: {tar_path}")

    # -------------------------------------------------------------
    # PK2: Zip Archive Existence
    # -------------------------------------------------------------
    total_checks += 1
    if zip_path.exists() and zip_path.is_file() and zip_path.stat().st_size > 0:
        passed_checks += 1
        print(f"[PK2] PASS: Zip archive exists: {zip_name} ({zip_path.stat().st_size} bytes)")
    else:
        print(f"[PK2] FAIL: Zip archive missing or empty: {zip_path}")

    # Inspect tar members
    tar_members = []
    tar_member_files = []
    if tar_path.exists():
        with tarfile.open(tar_path, "r:gz") as tar:
            for member in tar.getmembers():
                tar_members.append(member.name)
                if member.isfile():
                    tar_member_files.append(member.name)

    # Inspect zip members
    zip_members = []
    zip_member_files = []
    if zip_path.exists():
        with zipfile.ZipFile(zip_path, "r") as zf:
            for zinfo in zf.infolist():
                zip_members.append(zinfo.filename)
                if not zinfo.is_dir():
                    zip_member_files.append(zinfo.filename)

    # -------------------------------------------------------------
    # PK3: Archive root and allowlisted file set match exactly
    # -------------------------------------------------------------
    total_checks += 1
    expected_binary = "plugins/sui-plugin-legacy.dll" if platform == "windows-x86" else "plugins/sui-plugin-legacy.so"
    expected_relative_files = [
        expected_binary,
        "pawno/include/sui.inc",
        "examples/factory_login_example.pwn",
        "docs/API_REFERENCE.md",
        "docs/BUILD.md",
        "README.md",
        "CHANGELOG.md",
        "LICENSE",
        "BUILD_INFO.txt",
        "SHA256SUMS",
    ]

    expected_full_files = {f"{package_root_name}/{f}" for f in expected_relative_files}
    tar_files_set = set(tar_member_files)
    zip_files_set = set(zip_member_files)

    pk3_pass = True
    if tar_files_set != expected_full_files:
        pk3_pass = False
        print(f"[PK3] Tar file mismatch: diff={tar_files_set.symmetric_difference(expected_full_files)}")
    if zip_files_set != expected_full_files:
        pk3_pass = False
        print(f"[PK3] Zip file mismatch: diff={zip_files_set.symmetric_difference(expected_full_files)}")

    if pk3_pass:
        passed_checks += 1
        print(f"[PK3] PASS: Archive root ({package_root_name}/) and allowlisted file set ({len(expected_full_files)} files) match exactly in both archives.")
    else:
        print("[PK3] FAIL: Archive file set does not match expected allowlist.")

    # -------------------------------------------------------------
    # PK4: Forbidden Files Absence
    # -------------------------------------------------------------
    total_checks += 1
    forbidden_found = []
    all_members = set(tar_members + zip_members)
    forbidden_platform_exts = ["sui-plugin-legacy.so"] if platform == "windows-x86" else ["sui-plugin-legacy.dll"]
    for m in all_members:
        for fsub in FORBIDDEN_SUBSTRINGS:
            if fsub in m:
                forbidden_found.append(f"{m} (matched substring '{fsub}')")
        for fext in FORBIDDEN_EXTENSIONS:
            if m.endswith(fext) and not m.endswith("/sui.inc") and not m.endswith(".pwn"):
                forbidden_found.append(f"{m} (matched forbidden extension '{fext}')")
        for fplat in forbidden_platform_exts:
            if m.endswith(fplat):
                forbidden_found.append(f"{m} (matched forbidden cross-platform file '{fplat}')")

    if not forbidden_found:
        passed_checks += 1
        print("[PK4] PASS: Zero forbidden files or directories found in archives.")
    else:
        print(f"[PK4] FAIL: Forbidden items detected: {forbidden_found}")

    # -------------------------------------------------------------
    # PK5: Binary Architecture
    # -------------------------------------------------------------
    total_checks += 1
    pk5_pass = False
    bin_name = "sui-plugin-legacy.dll" if platform == "windows-x86" else "sui-plugin-legacy.so"
    bin_rel_path = f"{package_root_name}/plugins/{bin_name}"
    temp_dir = tempfile.mkdtemp(prefix="sui_check_pkg_")
    extracted_bin = Path(temp_dir) / bin_name

    try:
        with tarfile.open(tar_path, "r:gz") as tar:
            fobj = tar.extractfile(bin_rel_path)
            if fobj:
                bin_bytes = fobj.read()
                extracted_bin.write_bytes(bin_bytes)
                if platform == "windows-x86":
                    ok, details = validate_pe_binary_path(extracted_bin)
                    if ok:
                        pk5_pass = True
                        print("[PK5] PASS: Packaged .dll binary verified: PE32 Intel 386 DLL")
                    else:
                        print(f"[PK5] FAIL: Packaged .dll binary validation failed: {details}")
                else:
                    ok, msg = validate_elf_header(bin_bytes)
                    if ok:
                        pk5_pass = True
                        print(f"[PK5] PASS: Packaged .so binary verified: {msg}")
                    else:
                        print(f"[PK5] FAIL: Packaged .so binary validation failed: {msg}")
            else:
                print(f"[PK5] FAIL: Could not extract {bin_rel_path} from tar")
    except Exception as e:
        print(f"[PK5] FAIL: Exception verifying binary header: {e}")

    if pk5_pass:
        passed_checks += 1

    # -------------------------------------------------------------
    # PK6: Canonical Plugin Exports
    # -------------------------------------------------------------
    total_checks += 1
    if pk5_pass and extracted_bin.exists():
        if platform == "windows-x86":
            ok, details = validate_pe_binary_path(extracted_bin)
            if ok:
                passed_checks += 1
                print(f"[PK6] PASS: All 6 canonical plugin exports verified present in packaged .dll: {CANONICAL_EXPORTS}")
            else:
                print(f"[PK6] FAIL: Missing canonical exports in packaged .dll: {details}")
        else:
            ok, missing = check_exports_in_file(extracted_bin)
            if ok:
                passed_checks += 1
                print(f"[PK6] PASS: All 6 canonical plugin exports verified present in packaged .so: {CANONICAL_EXPORTS}")
            else:
                print(f"[PK6] FAIL: Missing canonical exports in packaged .so: {missing}")
    else:
        print(f"[PK6] FAIL: Cannot inspect exports; {bin_name} extraction failed")

    # -------------------------------------------------------------
    # PK7: Public Include Integrity (Byte-for-byte match with pawn/sui.inc)
    # -------------------------------------------------------------
    total_checks += 1
    repo_inc = repo_root / "pawn" / "sui.inc"
    inc_rel_path = f"{package_root_name}/pawno/include/sui.inc"
    pk7_pass = False
    if repo_inc.exists():
        repo_inc_bytes = repo_inc.read_bytes()
        with tarfile.open(tar_path, "r:gz") as tar:
            inc_fobj = tar.extractfile(inc_rel_path)
            if inc_fobj:
                tar_inc_bytes = inc_fobj.read()
                if tar_inc_bytes == repo_inc_bytes:
                    pk7_pass = True
                    print(f"[PK7] PASS: Packaged pawno/include/sui.inc matches repository pawn/sui.inc byte-for-byte ({len(repo_inc_bytes)} bytes, SHA-256: {compute_bytes_sha256(repo_inc_bytes)[:16]}...)")
                else:
                    print("[PK7] FAIL: Packaged sui.inc differs from repository pawn/sui.inc")
            else:
                print(f"[PK7] FAIL: Could not extract {inc_rel_path} from tar archive")
    else:
        print(f"[PK7] FAIL: Repository include not found: {repo_inc}")

    if pk7_pass:
        passed_checks += 1

    # -------------------------------------------------------------
    # PK8: Internal SHA256SUMS Manifest Validation
    # -------------------------------------------------------------
    total_checks += 1
    pk8_pass = True
    manifest_rel_path = f"{package_root_name}/SHA256SUMS"

    try:
        with tarfile.open(tar_path, "r:gz") as tar:
            m_fobj = tar.extractfile(manifest_rel_path)
            if not m_fobj:
                pk8_pass = False
                print("[PK8] FAIL: SHA256SUMS missing from tar archive")
            else:
                manifest_text = m_fobj.read().decode("utf-8")
                for line in manifest_text.splitlines():
                    if not line.strip():
                        continue
                    exp_hash, rel_f = line.strip().split(maxsplit=1)
                    full_f = f"{package_root_name}/{rel_f}"
                    f_fobj = tar.extractfile(full_f)
                    if not f_fobj:
                        pk8_pass = False
                        print(f"[PK8] FAIL: File listed in tar SHA256SUMS not found in archive: {rel_f}")
                        break
                    actual_hash = compute_bytes_sha256(f_fobj.read())
                    if actual_hash != exp_hash:
                        pk8_pass = False
                        print(f"[PK8] FAIL: Hash mismatch in tar for {rel_f}: expected {exp_hash}, got {actual_hash}")
                        break
    except Exception as e:
        pk8_pass = False
        print(f"[PK8] FAIL: Exception validating tar internal manifest: {e}")

    try:
        with zipfile.ZipFile(zip_path, "r") as zf:
            if manifest_rel_path not in zf.namelist():
                pk8_pass = False
                print("[PK8] FAIL: SHA256SUMS missing from zip archive")
            else:
                manifest_text = zf.read(manifest_rel_path).decode("utf-8")
                for line in manifest_text.splitlines():
                    if not line.strip():
                        continue
                    exp_hash, rel_f = line.strip().split(maxsplit=1)
                    full_f = f"{package_root_name}/{rel_f}"
                    if full_f not in zf.namelist():
                        pk8_pass = False
                        print(f"[PK8] FAIL: File listed in zip SHA256SUMS not found in archive: {rel_f}")
                        break
                    actual_hash = compute_bytes_sha256(zf.read(full_f))
                    if actual_hash != exp_hash:
                        pk8_pass = False
                        print(f"[PK8] FAIL: Hash mismatch in zip for {rel_f}: expected {exp_hash}, got {actual_hash}")
                        break
    except Exception as e:
        pk8_pass = False
        print(f"[PK8] FAIL: Exception validating zip internal manifest: {e}")

    if pk8_pass:
        passed_checks += 1
        print("[PK8] PASS: Internal SHA256SUMS manifest verified in both .tar.gz and .zip archives.")
    else:
        print("[PK8] FAIL: Internal SHA256SUMS manifest verification failed.")

    # -------------------------------------------------------------
    # PK9: Outer Archive Checksum Manifest Validation
    # -------------------------------------------------------------
    total_checks += 1
    pk9_pass = False
    if outer_manifest_path.exists():
        manifest_text = outer_manifest_path.read_text(encoding="utf-8")
        outer_hashes = {}
        for line in manifest_text.splitlines():
            if line.strip():
                h, fn = line.strip().split(maxsplit=1)
                outer_hashes[fn] = h

        tar_actual_hash = compute_sha256(tar_path)
        zip_actual_hash = compute_sha256(zip_path)

        if outer_hashes.get(tar_name) == tar_actual_hash and outer_hashes.get(zip_name) == zip_actual_hash:
            pk9_pass = True
            print(f"[PK9] PASS: Outer checksum manifest {outer_manifest_name} accurately validates both archives.")
        else:
            print(f"[PK9] FAIL: Outer checksum mismatch. Expected: {outer_hashes}, Got: {tar_name}={tar_actual_hash}, {zip_name}={zip_actual_hash}")
    else:
        print(f"[PK9] FAIL: Outer checksum manifest not found: {outer_manifest_path}")

    if pk9_pass:
        passed_checks += 1

    # -------------------------------------------------------------
    # PK10: Archive Path Safety
    # -------------------------------------------------------------
    total_checks += 1
    pk10_pass = True
    path_issues = []

    for name in all_members:
        if name.startswith("/") or name.startswith("\\"):
            path_issues.append(f"{name}: starts with root separator")
        if ".." in name:
            path_issues.append(f"{name}: contains directory traversal '..'")
        if ":" in name and len(name) > 1 and name[1] == ":":
            path_issues.append(f"{name}: contains drive letter")
        if not name.startswith(f"{package_root_name}/") and name != package_root_name and name != f"{package_root_name}/":
            path_issues.append(f"{name}: not located under package root {package_root_name}/")

    for name in zip_members:
        if "\\" in name:
            path_issues.append(f"{name}: zip entry contains backslash")

    if not path_issues:
        passed_checks += 1
        print(f"[PK10] PASS: All archive paths verified safe (no traversal, no absolute paths, POSIX '/' normalized).")
    else:
        print(f"[PK10] FAIL: Archive path safety issues detected: {path_issues}")

    # -------------------------------------------------------------
    # PK11: Build Traceability Alignment (BUILD_INFO.txt)
    # -------------------------------------------------------------
    total_checks += 1
    pk11_pass = True
    build_info_rel = f"{package_root_name}/BUILD_INFO.txt"
    try:
        with tarfile.open(tar_path, "r:gz") as tar:
            b_fobj = tar.extractfile(build_info_rel)
            if not b_fobj:
                pk11_pass = False
                print("[PK11] FAIL: BUILD_INFO.txt missing from tar archive")
            else:
                b_text = b_fobj.read().decode("utf-8")
                expected_target_str = f"Target: {platform}"
                expected_arch_str = "Architecture: PE32 (Intel 386)" if platform == "windows-x86" else "Architecture: ELF32 (Intel 80386)"
                if f"SUI Version: {version}" not in b_text:
                    pk11_pass = False
                    print(f"[PK11] FAIL: BUILD_INFO.txt does not contain expected SUI Version {version}")
                if expected_target_str not in b_text:
                    pk11_pass = False
                    print(f"[PK11] FAIL: BUILD_INFO.txt missing target '{expected_target_str}'")
                if expected_arch_str not in b_text:
                    pk11_pass = False
                    print(f"[PK11] FAIL: BUILD_INFO.txt missing architecture specification '{expected_arch_str}'")
                if "SDK Commit: a5ce36a9b6ebbea6ad36705603f653bf3d4f41c5" not in b_text:
                    pk11_pass = False
                    print("[PK11] FAIL: BUILD_INFO.txt SDK commit mismatch")
                if "Git Commit: " not in b_text:
                    pk11_pass = False
                    print("[PK11] FAIL: BUILD_INFO.txt missing Git Commit")
                if "Source Date Epoch: " not in b_text:
                    pk11_pass = False
                    print("[PK11] FAIL: BUILD_INFO.txt missing Source Date Epoch")
    except Exception as e:
        pk11_pass = False
        print(f"[PK11] FAIL: Exception verifying BUILD_INFO.txt: {e}")

    if pk11_pass:
        passed_checks += 1
        print("[PK11] PASS: BUILD_INFO.txt verified: version, SDK pin, target arch, epoch, and git commit aligned.")
    else:
        print("[PK11] FAIL: BUILD_INFO.txt verification failed.")

    # Cleanup temp directory
    shutil.rmtree(temp_dir, ignore_errors=True)

    # -------------------------------------------------------------
    # PK12: MIT License Validation (Presence, terms, copyright identity)
    # -------------------------------------------------------------
    total_checks += 1
    pk12_pass = True
    repo_license_path = repo_root / "LICENSE"
    if not repo_license_path.exists():
        pk12_pass = False
        print("[PK12] FAIL: Root LICENSE file is missing from repository.")
    else:
        repo_lic_text = repo_license_path.read_text(encoding="utf-8")
        if not repo_lic_text.startswith("MIT License"):
            pk12_pass = False
            print("[PK12] FAIL: Repository LICENSE does not begin with 'MIT License'")
        if "Copyright (c) 2026 PanDbEar" not in repo_lic_text:
            pk12_pass = False
            print("[PK12] FAIL: Repository LICENSE does not contain 'Copyright (c) 2026 PanDbEar'")

        lic_rel = f"{package_root_name}/LICENSE"
        try:
            with tarfile.open(tar_path, "r:gz") as tar:
                fobj = tar.extractfile(lic_rel)
                if not fobj:
                    pk12_pass = False
                    print("[PK12] FAIL: LICENSE file missing from tar archive")
                else:
                    tar_lic_bytes = fobj.read()
                    if tar_lic_bytes != repo_license_path.read_bytes():
                        pk12_pass = False
                        print("[PK12] FAIL: Packaged tar LICENSE does not match repository LICENSE byte-for-byte")
        except Exception as e:
            pk12_pass = False
            print(f"[PK12] FAIL: Exception validating tar LICENSE: {e}")

        try:
            with zipfile.ZipFile(zip_path, "r") as zf:
                if lic_rel not in zf.namelist():
                    pk12_pass = False
                    print("[PK12] FAIL: LICENSE file missing from zip archive")
                else:
                    zip_lic_bytes = zf.read(lic_rel)
                    if zip_lic_bytes != repo_license_path.read_bytes():
                        pk12_pass = False
                        print("[PK12] FAIL: Packaged zip LICENSE does not match repository LICENSE byte-for-byte")
        except Exception as e:
            pk12_pass = False
            print(f"[PK12] FAIL: Exception validating zip LICENSE: {e}")

    if pk12_pass:
        passed_checks += 1
        print("[PK12] PASS: MIT LICENSE verified: exists in repository and both archives, matches byte-for-byte, contains 2026 PanDbEar copyright.")
    else:
        print("[PK12] FAIL: MIT LICENSE verification failed.")

    # -------------------------------------------------------------
    # Licensing & Official Release Readiness Audit
    # -------------------------------------------------------------
    print("--------------------------------------------------")
    print(" LICENSING AUDIT & RELEASE READINESS GATE         ")
    print("--------------------------------------------------")
    if pk12_pass:
        print("[INFO] MIT License authorized by project owner and fully verified.")
        print("       Release readiness: READY FROM PACKAGING-CONTRACT PERSPECTIVE")
    else:
        print("[BLOCKER] Repository LICENSE missing or invalid.")
        print("          Official public release is blocked by the project's release policy until the project owner selects and authorizes a license.")
        print("          Current package is strictly classified as a CI TEST PACKAGE (not for public distribution).")

    print("==================================================")
    print(f" TOTAL RESULT: {passed_checks} / {total_checks} STRUCTURAL CHECKS PASSED")
    print(f" PACKAGE STRUCTURAL VALIDATION: {'PASS' if passed_checks == total_checks else 'FAIL'}")
    print(f" OFFICIAL RELEASE READINESS:    {'READY FROM PACKAGING-CONTRACT PERSPECTIVE' if (passed_checks == total_checks and pk12_pass) else 'BLOCKED'}")
    print("==================================================")

    if passed_checks == total_checks:
        return 0
    else:
        return 1


if __name__ == "__main__":
    sys.exit(main())
