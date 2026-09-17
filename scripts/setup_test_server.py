#!/usr/bin/env python3
"""
SUI Repository Test Server Setup Tool (SUI-014 / Phase 19)

Prepares a clean, isolated SA-MP 0.3.7-R2 test server environment (Linux x86 or Windows x86)
without committing external binaries to version control.

Features:
- Platform selector: --platform linux-x86 | windows-x86
- Downloads SA-MP 0.3.7-R2 server archive from an overridable URL
- Verifies SHA-256 checksum integrity before archive extraction
- Safely extracts archive with path traversal protection (tar.gz and zip)
- Creates gamemodes/, filterscripts/, plugins/, and scriptfiles/ directories
- Generates default server.cfg tailored for headless plugin regression testing
- Sets executable permissions (+x) on POSIX binaries
"""

import argparse
import hashlib
import os
import re
import shutil
import sys
import tarfile
import urllib.request
import zipfile
from pathlib import Path

DEFAULT_LINUX_ARCHIVE_URL = (
    "https://raw.githubusercontent.com/Se8870/SAMP-File-Archive/master/archives/samp037svr_R2-1.tar.gz"
)
DEFAULT_LINUX_ARCHIVE_SHA256 = (
    "f8ead0b15683fc34f13a7a84ba9ea7252b17c5e3161d8255364e1abedd697a53"
)

DEFAULT_WINDOWS_ARCHIVE_URL = (
    "https://raw.githubusercontent.com/Se8870/SAMP-File-Archive/master/archives/samp037_svr_R2-1-1_win32.zip"
)
DEFAULT_WINDOWS_ARCHIVE_SHA256 = (
    "e12e7483d4df0349f52e2c5f47d6afd3f782acbc2bbb19fa61adced3bfff2d90"
)


def get_default_cfg(platform: str) -> str:
    plugin_name = "sui-plugin-legacy" if platform == "windows-x86" else "sui-plugin-legacy.so"
    return f"""echo Executing Server Config...
lanmode 0
rcon_password test
maxplayers 50
port 7777
hostname SUI Test Server
gamemode0 reentrancy_regression 1
filterscripts
plugins {plugin_name}
announce 0
chatlogging 0
weburl www.sa-mp.com
onfoot_rate 40
incar_rate 40
weapon_rate 40
stream_distance 300.0
stream_rate 1000
maxnpc 10
logtimeformat [%H:%M:%S]
"""


def compute_sha256(file_path: Path) -> str:
    """Computes SHA-256 hex digest of a local file."""
    hasher = hashlib.sha256()
    with open(file_path, "rb") as f:
        while chunk := f.read(65536):
            hasher.update(chunk)
    return hasher.hexdigest()


def verify_archive_sha256(file_path: Path, expected_sha256: str) -> bool:
    """Verifies file checksum against expected SHA-256."""
    if not expected_sha256:
        print("[WARN] No expected SHA-256 provided; skipping checksum validation.")
        return True
    print(f"[INTEGRITY] Computing SHA-256 for {file_path.name}...")
    actual_sha256 = compute_sha256(file_path)
    print(f"[INTEGRITY] Expected: {expected_sha256}")
    print(f"[INTEGRITY] Actual:   {actual_sha256}")
    if actual_sha256.lower() == expected_sha256.lower():
        print("[INTEGRITY] Checksum verified successfully.")
        return True
    else:
        print(f"ERROR: SHA-256 checksum mismatch for {file_path.name}!")
        return False


def download_archive(url: str, dest_path: Path) -> bool:
    """Downloads an archive from a URL."""
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    print(f"[DOWNLOAD] Retrieving server archive from: {url}")
    try:
        req = urllib.request.Request(
            url,
            headers={"User-Agent": "Mozilla/5.0 (SUI-CI-Automation)"}
        )
        with urllib.request.urlopen(req, timeout=60) as response, open(dest_path, "wb") as out_file:
            while chunk := response.read(65536):
                out_file.write(chunk)
        if dest_path.stat().st_size > 100000:
            print(f"[DOWNLOAD] Successfully retrieved archive ({dest_path.stat().st_size} bytes).")
            return True
        else:
            print(f"[DOWNLOAD] File too small ({dest_path.stat().st_size} bytes), download incomplete.")
    except Exception as e:
        print(f"[DOWNLOAD] Download failed: {e}")
    if dest_path.exists():
        dest_path.unlink()
    return False


def extract_tar_safe(archive_path: Path, dest_dir: Path) -> None:
    dest_dir_resolved = dest_dir.resolve()
    with tarfile.open(archive_path, "r:gz") as tar:
        for member in tar.getmembers():
            parts = Path(member.name).parts
            if parts and parts[0] in ("samp03", "samp037"):
                rel_parts = parts[1:]
            else:
                rel_parts = parts

            if not rel_parts:
                continue

            target_file = (dest_dir / Path(*rel_parts)).resolve()
            try:
                target_file.relative_to(dest_dir_resolved)
            except ValueError:
                raise RuntimeError(
                    f"SECURITY VIOLATION: Archive member '{member.name}' resolves outside target directory: {target_file}"
                )

            if member.isdir():
                target_file.mkdir(parents=True, exist_ok=True)
            elif member.isfile():
                target_file.parent.mkdir(parents=True, exist_ok=True)
                with tar.extractfile(member) as src, open(target_file, "wb") as dst:
                    shutil.copyfileobj(src, dst)


def extract_zip_safe(archive_path: Path, dest_dir: Path) -> None:
    dest_dir_resolved = dest_dir.resolve()
    with zipfile.ZipFile(archive_path, "r") as zf:
        for zinfo in zf.infolist():
            name = zinfo.filename.replace("\\", "/")
            parts = Path(name).parts
            if parts and parts[0] in ("samp03", "samp037"):
                rel_parts = parts[1:]
            else:
                rel_parts = parts

            if not rel_parts:
                continue

            target_file = (dest_dir / Path(*rel_parts)).resolve()
            try:
                target_file.relative_to(dest_dir_resolved)
            except ValueError:
                raise RuntimeError(
                    f"SECURITY VIOLATION: Archive member '{zinfo.filename}' resolves outside target directory: {target_file}"
                )

            if zinfo.is_dir() or name.endswith("/"):
                target_file.mkdir(parents=True, exist_ok=True)
            else:
                target_file.parent.mkdir(parents=True, exist_ok=True)
                with zf.open(zinfo) as src, open(target_file, "wb") as dst:
                    shutil.copyfileobj(src, dst)


def setup_server(dest_dir: Path,
                 platform: str = "linux-x86",
                 archive_path: Path = None,
                 archive_url: str = None,
                 expected_sha256: str = None,
                 skip_download: bool = False) -> bool:
    dest_dir.mkdir(parents=True, exist_ok=True)

    if platform == "windows-x86":
        server_bin = dest_dir / "samp-server.exe"
        npc_bin = dest_dir / "samp-npc.exe"
        default_url = DEFAULT_WINDOWS_ARCHIVE_URL
        default_sha = DEFAULT_WINDOWS_ARCHIVE_SHA256
        default_archive_name = "samp037_svr_R2-1-1_win32.zip"
    else:
        server_bin = dest_dir / "samp03svr"
        npc_bin = dest_dir / "samp-npc"
        default_url = DEFAULT_LINUX_ARCHIVE_URL
        default_sha = DEFAULT_LINUX_ARCHIVE_SHA256
        default_archive_name = "samp037svr_R2-1.tar.gz"

    archive_url = archive_url or default_url
    expected_sha256 = expected_sha256 if expected_sha256 is not None else default_sha

    if server_bin.exists() and not archive_path:
        print(f"[SETUP] Server binary already exists at {server_bin}.")
    else:
        downloaded = False
        if not archive_path or not archive_path.exists():
            if skip_download:
                print(f"ERROR: Server binary missing at {server_bin} and skip_download was requested.")
                return False
            archive_path = dest_dir / default_archive_name
            success = download_archive(archive_url, archive_path)
            if not success:
                print(f"ERROR: Failed to download SA-MP 0.3.7-R2 ({platform}) server archive.")
                return False
            downloaded = True

        # Checksum validation before extraction
        if expected_sha256:
            if not verify_archive_sha256(archive_path, expected_sha256):
                if downloaded and archive_path.exists():
                    archive_path.unlink()
                return False

        print(f"[EXTRACT] Extracting {archive_path.name} into {dest_dir} with path traversal protection...")
        if archive_path.suffix == ".zip" or str(archive_path).endswith(".zip"):
            extract_zip_safe(archive_path, dest_dir)
        else:
            extract_tar_safe(archive_path, dest_dir)

    # Ensure directories exist
    (dest_dir / "gamemodes").mkdir(parents=True, exist_ok=True)
    (dest_dir / "filterscripts").mkdir(parents=True, exist_ok=True)
    (dest_dir / "plugins").mkdir(parents=True, exist_ok=True)
    (dest_dir / "scriptfiles").mkdir(parents=True, exist_ok=True)

    # Set executable permissions on POSIX
    if os.name != "nt":
        if server_bin.exists():
            try:
                os.chmod(server_bin, 0o755)
                print(f"[PERM] Set executable permissions on {server_bin}.")
            except Exception as e:
                print(f"[PERM] Warning: Could not chmod {server_bin}: {e}")

        if npc_bin.exists():
            try:
                os.chmod(npc_bin, 0o755)
                print(f"[PERM] Set executable permissions on {npc_bin}.")
            except Exception as e:
                print(f"[PERM] Warning: Could not chmod {npc_bin}: {e}")

    # Ensure server.cfg has proper configuration and non-default password
    cfg_path = dest_dir / "server.cfg"
    default_cfg = get_default_cfg(platform)
    plugin_entry = "sui-plugin-legacy" if platform == "windows-x86" else "sui-plugin-legacy.so"

    if not cfg_path.exists():
        with open(cfg_path, "w", encoding="utf-8") as f:
            f.write(default_cfg)
        print(f"[CONFIG] Wrote default server.cfg at {cfg_path}.")
    else:
        with open(cfg_path, "r", encoding="utf-8", errors="replace") as f:
            cfg = f.read()
        cfg = re.sub(r"^rcon_password\s+.*", "rcon_password testpass", cfg, flags=re.MULTILINE)
        if not re.search(r"^plugins\s+.*sui-plugin-legacy", cfg, flags=re.MULTILINE):
            cfg += f"\nplugins {plugin_entry}\n"
        with open(cfg_path, "w", encoding="utf-8") as f:
            f.write(cfg)
        print(f"[CONFIG] Updated {cfg_path} with rcon_password testpass and plugin {plugin_entry}.")

    return True


def main():
    default_platform = "windows-x86" if os.name == "nt" else "linux-x86"

    parser = argparse.ArgumentParser(description="Setup SA-MP 0.3.7-R2 test server for SUI CI/regression.")
    parser.add_argument("--platform", choices=["linux-x86", "windows-x86"], default=default_platform,
                        help=f"Target platform (default: {default_platform})")
    parser.add_argument("--dest", default="test-server", help="Destination directory for test server (default: test-server)")
    parser.add_argument("--archive", help="Path to existing server archive (.tar.gz or .zip)")
    parser.add_argument("--archive-url", help="URL to download SA-MP server archive (override default)")
    parser.add_argument("--archive-sha256", help="Expected SHA-256 checksum for server archive (override default)")
    parser.add_argument("--skip-download", action="store_true", help="Do not attempt to download server archive")

    args = parser.parse_args()
    dest_path = Path(args.dest).resolve()
    archive_path = Path(args.archive).resolve() if args.archive else None

    print("=================================================================")
    print(" SUI TEST SERVER SETUP TOOL (SUI-014 / Phase 19)")
    print("=================================================================")
    print(f"Platform:       {args.platform}")
    print(f"Destination:    {dest_path}")
    if args.archive_url:
        print(f"Archive URL:    {args.archive_url}")
    if args.archive_sha256:
        print(f"Expected SHA:   {args.archive_sha256}")

    ok = setup_server(
        dest_dir=dest_path,
        platform=args.platform,
        archive_path=archive_path,
        archive_url=args.archive_url,
        expected_sha256=args.archive_sha256,
        skip_download=args.skip_download
    )
    if ok:
        print("=================================================================")
        print(" SUCCESS: Test server is ready.")
        print("=================================================================")
        return 0
    else:
        print("=================================================================")
        print(" FAILURE: Test server setup failed.")
        print("=================================================================")
        return 1


if __name__ == "__main__":
    sys.exit(main())
