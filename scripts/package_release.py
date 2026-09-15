#!/usr/bin/env python3
"""
SUI Deterministic Release Packager (SUI-015 - Draft CI Test Infrastructure)

NOTE: This script produces non-official CI test packages for structural verification.
It does NOT produce official releases. Official distribution is BLOCKED pending
the project owner's licensing decision.

Assembles the legacy Linux x86 release package layout for SUI:
1. Validates binary architecture (ELF32, Intel 80386, DYN) and canonical exports.
2. Creates package layout under root: sui-plugin-<VERSION>/
3. Copies allowlisted deployment assets.
4. Generates deterministic BUILD_INFO.txt metadata file.
5. Generates internal SHA256SUMS manifest.
6. Packages sui-plugin-<VERSION>-linux-x86.tar.gz (normalized permissions & gzip mtime).
7. Packages sui-plugin-<VERSION>-linux-x86.zip (normalized POSIX paths & ZipInfo timestamps).
8. Generates outer sui-plugin-<VERSION>-SHA256SUMS.txt manifest.
"""

import argparse
import gzip
import hashlib
import io
import os
import re
import shutil
import struct
import subprocess
import sys
import tarfile
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


def get_git_commit(root: Path) -> str:
    try:
        res = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            cwd=root,
            capture_output=True,
            text=True,
            check=True,
        )
        return res.stdout.strip()
    except Exception:
        return "unknown"


def get_sdk_commit(root: Path) -> str:
    try:
        res = subprocess.run(
            ["git", "submodule", "status", "lib/samp-plugin-sdk"],
            cwd=root,
            capture_output=True,
            text=True,
            check=True,
        )
        parts = res.stdout.strip().split()
        if parts:
            return parts[0].lstrip("+-U")
        return "unknown"
    except Exception:
        return "a5ce36a9b6ebbea6ad36705603f653bf3d4f41c5"


def get_git_timestamp(root: Path) -> int:
    try:
        res = subprocess.run(
            ["git", "log", "-1", "--format=%ct"],
            cwd=root,
            capture_output=True,
            text=True,
            check=True,
        )
        return int(res.stdout.strip())
    except Exception:
        return 1700000000


def derive_version_from_git(root: Path) -> str:
    github_ref = os.environ.get("GITHUB_REF", "")
    if github_ref.startswith("refs/tags/"):
        tag = github_ref[len("refs/tags/") :]
        if tag.startswith("v"):
            return tag[1:]
        return tag

    try:
        res = subprocess.run(
            ["git", "describe", "--exact-match", "--tags", "HEAD"],
            cwd=root,
            capture_output=True,
            text=True,
            check=True,
        )
        tag = res.stdout.strip()
        if tag.startswith("v"):
            return tag[1:]
        return tag
    except Exception:
        return ""


def validate_binary_elf(binary_path: Path) -> None:
    """Validate binary is strictly ELF32, Intel 80386, and ET_DYN."""
    if not binary_path.exists():
        raise FileNotFoundError(f"Plugin binary not found: {binary_path}")

    if binary_path.name != "sui-plugin-legacy.so":
        raise ValueError(
            f"Plugin binary name must be 'sui-plugin-legacy.so', got '{binary_path.name}'"
        )

    file_size = binary_path.stat().st_size
    if file_size < 52:
        raise ValueError(f"File too small to be a valid ELF binary ({file_size} bytes)")

    with open(binary_path, "rb") as f:
        header = f.read(52)

    # Magic: \x7fELF
    if header[:4] != b"\x7fELF":
        raise ValueError(f"Invalid ELF magic: {header[:4]!r}")

    # EI_CLASS: 1 = ELF32, 2 = ELF64
    ei_class = header[4]
    if ei_class != 1:
        if ei_class == 2:
            raise ValueError("Binary is 64-bit ELF (ELFCLASS64). -m32 32-bit ELF32 is REQUIRED.")
        raise ValueError(f"Unsupported ELF class: {ei_class}")

    # EI_DATA: 1 = 2's complement, little endian
    ei_data = header[5]
    if ei_data != 1:
        raise ValueError(f"Expected little-endian ELF (1), got {ei_data}")

    # e_type: offset 16, uint16
    e_type = struct.unpack("<H", header[16:18])[0]
    # ET_DYN = 3 (shared object)
    if e_type != 3:
        raise ValueError(f"Expected ELF type ET_DYN (3, shared object), got {e_type}")

    # e_machine: offset 18, uint16
    # EM_386 = 3 (Intel 80386)
    e_machine = struct.unpack("<H", header[18:20])[0]
    if e_machine != 3:
        raise ValueError(f"Expected ELF machine EM_386 (3, Intel 80386), got {e_machine}")

    print(f"[OK] Binary ELF header validated: ELF32, Intel 80386, ET_DYN (size: {file_size} bytes)")


def validate_canonical_exports(binary_path: Path) -> None:
    """Validate presence of all 6 canonical SA-MP plugin entry points."""
    symbols_found = set()

    try:
        res = subprocess.run(
            ["nm", "-D", "--defined-only", str(binary_path)],
            capture_output=True,
            text=True,
            check=True,
        )
        for line in res.stdout.splitlines():
            parts = line.strip().split()
            if len(parts) >= 3:
                symbols_found.add(parts[-1])
    except Exception:
        try:
            res = subprocess.run(
                ["readelf", "--dyn-syms", str(binary_path)],
                capture_output=True,
                text=True,
                check=True,
            )
            for line in res.stdout.splitlines():
                parts = line.strip().split()
                if len(parts) >= 8:
                    symbols_found.add(parts[7].split("@")[0])
        except Exception as e:
            raise RuntimeError(f"Failed to inspect dynamic symbols with nm or readelf: {e}")

    missing_exports = [sym for sym in CANONICAL_EXPORTS if sym not in symbols_found]
    if missing_exports:
        raise ValueError(f"Missing required canonical plugin exports: {missing_exports}")

    print(f"[OK] All 6 canonical plugin exports verified present: {CANONICAL_EXPORTS}")


def assemble_package_tree(
    root: Path,
    staging_dir: Path,
    binary_path: Path,
    version: str,
    git_commit: str,
    sdk_commit: str,
    epoch: int,
) -> None:
    """Copies all allowlisted files into staging directory and creates metadata files."""
    staging_dir.mkdir(parents=True, exist_ok=True)

    # 1. plugins/sui-plugin-legacy.so
    plugins_dir = staging_dir / "plugins"
    plugins_dir.mkdir(parents=True, exist_ok=True)
    shutil.copy2(binary_path, plugins_dir / "sui-plugin-legacy.so")

    # 2. pawno/include/sui.inc
    pawno_dir = staging_dir / "pawno" / "include"
    pawno_dir.mkdir(parents=True, exist_ok=True)
    inc_src = root / "pawn" / "sui.inc"
    if not inc_src.exists():
        raise FileNotFoundError(f"Missing public include: {inc_src}")
    shutil.copy2(inc_src, pawno_dir / "sui.inc")

    # 3. examples/factory_login_example.pwn
    examples_dir = staging_dir / "examples"
    examples_dir.mkdir(parents=True, exist_ok=True)
    ex_src = root / "examples" / "factory_login_example.pwn"
    if not ex_src.exists():
        raise FileNotFoundError(f"Missing example: {ex_src}")
    shutil.copy2(ex_src, examples_dir / "factory_login_example.pwn")

    # 4. docs/API_REFERENCE.md and docs/BUILD.md
    docs_dir = staging_dir / "docs"
    docs_dir.mkdir(parents=True, exist_ok=True)
    for doc_name in ["API_REFERENCE.md", "BUILD.md"]:
        d_src = root / "docs" / doc_name
        if not d_src.exists():
            raise FileNotFoundError(f"Missing doc file: {d_src}")
        shutil.copy2(d_src, docs_dir / doc_name)

    # 5. README.md and CHANGELOG.md
    for root_file in ["README.md", "CHANGELOG.md"]:
        rf_src = root / root_file
        if not rf_src.exists():
            raise FileNotFoundError(f"Missing root file: {rf_src}")
        shutil.copy2(rf_src, staging_dir / root_file)

    # 6. LICENSE (mandatory release asset per MIT license authorization)
    lic_src = root / "LICENSE"
    if not lic_src.exists():
        raise FileNotFoundError(f"Missing mandatory release asset: {lic_src}")
    shutil.copy2(lic_src, staging_dir / "LICENSE")

    # 7. BUILD_INFO.txt (deterministic fields only)
    build_info_content = (
        f"SUI Version: {version}\n"
        f"Git Commit: {git_commit}\n"
        "Target: linux-x86\n"
        "Architecture: ELF32 (Intel 80386)\n"
        f"SDK Commit: {sdk_commit}\n"
        f"Source Date Epoch: {epoch}\n"
    )
    (staging_dir / "BUILD_INFO.txt").write_text(build_info_content, encoding="utf-8")

    # 8. SHA256SUMS (internal manifest of all files relative to package root)
    manifest_lines = []
    for fpath in sorted(staging_dir.rglob("*")):
        if fpath.is_file() and fpath.name != "SHA256SUMS":
            rel_path = fpath.relative_to(staging_dir).as_posix()
            f_hash = compute_sha256(fpath)
            manifest_lines.append(f"{f_hash}  {rel_path}\n")

    manifest_content = "".join(manifest_lines)
    (staging_dir / "SHA256SUMS").write_text(manifest_content, encoding="utf-8")
    print(f"[OK] Staging tree assembled with {len(manifest_lines) + 1} files under {staging_dir.name}")


def create_tar_archive(
    staging_dir: Path,
    output_tar: Path,
    package_root_name: str,
    epoch: int,
) -> None:
    """Creates a deterministic tar.gz archive with normalized metadata and fixed gzip mtime."""
    def tar_filter(tarinfo: tarfile.TarInfo) -> tarfile.TarInfo:
        tarinfo.uid = 0
        tarinfo.gid = 0
        tarinfo.uname = ""
        tarinfo.gname = ""
        tarinfo.mtime = epoch
        if tarinfo.isdir():
            tarinfo.mode = 0o755
        else:
            tarinfo.mode = 0o644
        return tarinfo

    items = []
    for root, dirs, files in os.walk(staging_dir):
        dirs.sort()
        files.sort()
        rel_root = Path(root).relative_to(staging_dir)
        for d in dirs:
            items.append(rel_root / d)
        for f in files:
            items.append(rel_root / f)

    # Use explicit GzipFile with fixed mtime and empty filename to avoid header divergence
    with open(output_tar, "wb") as f_out:
        with gzip.GzipFile(filename="", mode="wb", fileobj=f_out, mtime=epoch) as gz_out:
            with tarfile.open(mode="w", fileobj=gz_out) as tar:
                # Add root directory entry
                root_info = tarfile.TarInfo(name=package_root_name)
                root_info.type = tarfile.DIRTYPE
                root_info = tar_filter(root_info)
                tar.addfile(root_info)

                for item in items:
                    full_path = staging_dir / item
                    arcname = (Path(package_root_name) / item).as_posix()
                    info = tar.gettarinfo(str(full_path), arcname=arcname)
                    info = tar_filter(info)
                    if info.isreg():
                        with open(full_path, "rb") as f:
                            tar.addfile(info, f)
                    else:
                        tar.addfile(info)

    print(f"[OK] Created deterministic tar.gz archive: {output_tar.name} ({output_tar.stat().st_size} bytes)")


def create_zip_archive(
    staging_dir: Path,
    output_zip: Path,
    package_root_name: str,
    epoch: int,
) -> None:
    """Creates a deterministic zip archive with normalized POSIX paths and timestamps."""
    # Convert epoch to MS-DOS compatible time tuple (year >= 1980)
    # Use UTC components
    import time
    gm = time.gmtime(epoch)
    year = max(1980, gm.tm_year)
    zip_dt = (year, gm.tm_mon, gm.tm_mday, gm.tm_hour, gm.tm_min, gm.tm_sec)

    items = []
    for root, dirs, files in os.walk(staging_dir):
        dirs.sort()
        files.sort()
        rel_root = Path(root).relative_to(staging_dir)
        for d in dirs:
            items.append(rel_root / d)
        for f in files:
            items.append(rel_root / f)

    with zipfile.ZipFile(output_zip, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        # Add root directory entry
        root_zinfo = zipfile.ZipInfo(f"{package_root_name}/", date_time=zip_dt)
        root_zinfo.external_attr = 0o755 << 16 | 0o040000
        zf.writestr(root_zinfo, "")

        for item in items:
            full_path = staging_dir / item
            rel_str = item.as_posix()
            if full_path.is_dir():
                arcname = f"{package_root_name}/{rel_str}/"
                zinfo = zipfile.ZipInfo(arcname, date_time=zip_dt)
                zinfo.external_attr = 0o755 << 16 | 0o040000
                zf.writestr(zinfo, "")
            else:
                arcname = f"{package_root_name}/{rel_str}"
                zinfo = zipfile.ZipInfo(arcname, date_time=zip_dt)
                zinfo.external_attr = 0o644 << 16 | 0o100000
                with open(full_path, "rb") as f:
                    zf.writestr(zinfo, f.read())

    print(f"[OK] Created deterministic zip archive: {output_zip.name} ({output_zip.stat().st_size} bytes)")


def main():
    parser = argparse.ArgumentParser(
        description="SUI Deterministic Release Packager (SUI-015 - Draft Test Infrastructure)"
    )
    parser.add_argument(
        "--binary",
        default="build/sui-plugin-legacy.so",
        help="Path to sui-plugin-legacy.so (default: build/sui-plugin-legacy.so)",
    )
    parser.add_argument(
        "--version",
        default="",
        help="Release version string (e.g. 0.0.0-test). If omitted, derived from Git tag.",
    )
    parser.add_argument(
        "--output-dir",
        default="dist",
        help="Directory to output archives and checksum manifest (default: dist)",
    )
    parser.add_argument(
        "--source-date-epoch",
        type=int,
        default=0,
        help="Deterministic Unix timestamp for archives. Defaults to SOURCE_DATE_EPOCH or git commit timestamp.",
    )
    parser.add_argument(
        "--git-commit",
        default="",
        help="Override git commit SHA for metadata. Defaults to current HEAD.",
    )
    parser.add_argument(
        "--sdk-commit",
        default="",
        help="Override SDK submodule commit SHA for metadata. Defaults to submodule status.",
    )
    parser.add_argument(
        "--keep-staging",
        action="store_true",
        help="Keep intermediate unpacked staging directory in output-dir.",
    )
    args = parser.parse_args()

    repo_root = find_repo_root()
    binary_path = (repo_root / args.binary).resolve()
    output_dir = (repo_root / args.output_dir).resolve()

    print("==================================================")
    print(" SUI RELEASE PACKAGER (DRAFT CI TEST INFRASTRUCTURE)")
    print("==================================================")

    # 1. Determine release version
    version = args.version.strip()
    if not version:
        version = derive_version_from_git(repo_root)
    if not version:
        print("ERROR: Release version not specified and not on a Git tag.")
        print("Provide --version (e.g. --version 0.0.0-test) for non-tag builds.")
        sys.exit(1)

    print(f"Target Version:    {version}")
    print(f"Input Binary:      {binary_path}")
    print(f"Output Directory:  {output_dir}")

    # 2. Determine git and SDK metadata
    git_commit = args.git_commit.strip() or get_git_commit(repo_root)
    sdk_commit = args.sdk_commit.strip() or get_sdk_commit(repo_root)
    print(f"Git Commit SHA:    {git_commit}")
    print(f"SDK Submodule:     {sdk_commit}")

    # 3. Determine epoch timestamp
    epoch = args.source_date_epoch
    if not epoch:
        env_epoch = os.environ.get("SOURCE_DATE_EPOCH", "").strip()
        if env_epoch.isdigit():
            epoch = int(env_epoch)
        else:
            epoch = get_git_timestamp(repo_root)
    print(f"Source Date Epoch: {epoch}")

    # 4. Validate binary ELF32 and canonical exports
    validate_binary_elf(binary_path)
    validate_canonical_exports(binary_path)

    # 5. Prepare output and staging directories
    output_dir.mkdir(parents=True, exist_ok=True)
    package_root_name = f"sui-plugin-{version}"
    staging_dir = output_dir / package_root_name
    if staging_dir.exists():
        shutil.rmtree(staging_dir)

    # 6. Assemble staging tree
    assemble_package_tree(
        root=repo_root,
        staging_dir=staging_dir,
        binary_path=binary_path,
        version=version,
        git_commit=git_commit,
        sdk_commit=sdk_commit,
        epoch=epoch,
    )

    # 7. Generate archives
    tar_filename = f"sui-plugin-{version}-linux-x86.tar.gz"
    zip_filename = f"sui-plugin-{version}-linux-x86.zip"
    tar_path = output_dir / tar_filename
    zip_path = output_dir / zip_filename

    create_tar_archive(staging_dir, tar_path, package_root_name, epoch)
    create_zip_archive(staging_dir, zip_path, package_root_name, epoch)

    # 8. Generate outer SHA256SUMS manifest
    tar_hash = compute_sha256(tar_path)
    zip_hash = compute_sha256(zip_path)
    outer_manifest_filename = f"sui-plugin-{version}-SHA256SUMS.txt"
    outer_manifest_path = output_dir / outer_manifest_filename
    outer_content = f"{tar_hash}  {tar_filename}\n{zip_hash}  {zip_filename}\n"
    outer_manifest_path.write_text(outer_content, encoding="utf-8")
    print(f"[OK] Created outer checksum manifest: {outer_manifest_filename}")
    print(f"     {tar_hash}  {tar_filename}")
    print(f"     {zip_hash}  {zip_filename}")

    # 9. Cleanup staging tree unless --keep-staging
    if not args.keep_staging:
        shutil.rmtree(staging_dir)
        print(f"[OK] Cleaned up temporary staging tree: {staging_dir.name}")

    print("==================================================")
    print(" SUI TEST PACKAGE GENERATION COMPLETED           ")
    print("==================================================")


if __name__ == "__main__":
    main()
