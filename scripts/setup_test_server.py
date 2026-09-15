#!/usr/bin/env python3
"""
SUI Repository Test Server Setup Tool (SUI-014)

Prepares a clean, isolated SA-MP 0.3.7-R2 Linux test server environment
without committing external binaries to version control.

Features:
- Downloads SA-MP 0.3.7-R2 Linux server archive from an overridable URL
- Verifies SHA-256 checksum integrity before archive extraction
- Safely extracts archive with path traversal protection
- Creates gamemodes/, filterscripts/, plugins/, and scriptfiles/ directories
- Generates default server.cfg tailored for headless plugin regression testing
- Sets executable permissions (+x) on samp03svr
"""

import sys
import os
import re
import tarfile
import hashlib
import shutil
import urllib.request
import argparse
from pathlib import Path

DEFAULT_SERVER_ARCHIVE_URL = (
    "https://raw.githubusercontent.com/Se8870/SAMP-File-Archive/master/archives/samp037svr_R2-1.tar.gz"
)
DEFAULT_SERVER_ARCHIVE_SHA256 = (
    "f8ead0b15683fc34f13a7a84ba9ea7252b17c5e3161d8255364e1abedd697a53"
)

DEFAULT_SERVER_CFG = """echo Executing Server Config...
lanmode 0
rcon_password test
maxplayers 50
port 7777
hostname SUI Test Server
gamemode0 reentrancy_regression 1
filterscripts
plugins sui-plugin-legacy.so
announce 0
chatlogging 0
weburl www.sa-mp.com
onfoot_rate 40
incar_rate 40
weapon_rate 40
stream_distance 300.0
stream_rate 1000
maxnpc 0
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

def setup_server(dest_dir: Path, archive_path: Path = None,
                 archive_url: str = DEFAULT_SERVER_ARCHIVE_URL,
                 expected_sha256: str = DEFAULT_SERVER_ARCHIVE_SHA256,
                 skip_download: bool = False) -> bool:
    dest_dir.mkdir(parents=True, exist_ok=True)
    server_bin = dest_dir / "samp03svr"

    if server_bin.exists() and not archive_path:
        print(f"[SETUP] Server binary already exists at {server_bin}.")
    else:
        downloaded = False
        if not archive_path or not archive_path.exists():
            if skip_download:
                print("ERROR: Server binary missing and skip_download was requested.")
                return False
            archive_path = dest_dir / "samp037svr_R2-1.tar.gz"
            success = download_archive(archive_url, archive_path)
            if not success:
                print("ERROR: Failed to download SA-MP 0.3.7-R2 Linux server archive.")
                return False
            downloaded = True

        # Checksum validation before extraction
        if expected_sha256:
            if not verify_archive_sha256(archive_path, expected_sha256):
                if downloaded and archive_path.exists():
                    archive_path.unlink()
                return False

        print(f"[EXTRACT] Extracting {archive_path.name} into {dest_dir} with path traversal protection...")
        dest_dir_resolved = dest_dir.resolve()
        with tarfile.open(archive_path, "r:gz") as tar:
            for member in tar.getmembers():
                # Strip leading samp03/ if present
                parts = Path(member.name).parts
                if parts and parts[0] == "samp03":
                    rel_parts = parts[1:]
                else:
                    rel_parts = parts

                if not rel_parts:
                    continue

                target_file = (dest_dir / Path(*rel_parts)).resolve()

                # Path traversal defense: target must resolve within dest_dir
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

    # Ensure directories exist
    (dest_dir / "gamemodes").mkdir(parents=True, exist_ok=True)
    (dest_dir / "filterscripts").mkdir(parents=True, exist_ok=True)
    (dest_dir / "plugins").mkdir(parents=True, exist_ok=True)
    (dest_dir / "scriptfiles").mkdir(parents=True, exist_ok=True)

    # Set executable permissions
    if server_bin.exists():
        try:
            os.chmod(server_bin, 0o755)
            print(f"[PERM] Set executable permissions on {server_bin}.")
        except Exception as e:
            print(f"[PERM] Warning: Could not chmod {server_bin}: {e}")

    # Ensure server.cfg has proper configuration and non-default password
    cfg_path = dest_dir / "server.cfg"
    if not cfg_path.exists():
        with open(cfg_path, "w", encoding="utf-8") as f:
            f.write(DEFAULT_SERVER_CFG)
        print(f"[CONFIG] Wrote default server.cfg at {cfg_path}.")
    else:
        with open(cfg_path, "r", encoding="utf-8", errors="replace") as f:
            cfg = f.read()
        cfg = re.sub(r"^rcon_password\s+.*", "rcon_password testpass", cfg, flags=re.MULTILINE)
        if not re.search(r"^plugins\s+.*sui-plugin-legacy", cfg, flags=re.MULTILINE):
            cfg += "\nplugins sui-plugin-legacy.so\n"
        with open(cfg_path, "w", encoding="utf-8") as f:
            f.write(cfg)
        print(f"[CONFIG] Updated {cfg_path} with rcon_password testpass.")

    return True

def main():
    archive_url_default = os.environ.get("SAMP_SERVER_ARCHIVE_URL", DEFAULT_SERVER_ARCHIVE_URL)
    archive_sha_default = os.environ.get("SAMP_SERVER_ARCHIVE_SHA256", DEFAULT_SERVER_ARCHIVE_SHA256)

    parser = argparse.ArgumentParser(description="Setup SA-MP 0.3.7-R2 test server for SUI CI/regression.")
    parser.add_argument("--dest", default="test-server", help="Destination directory for test server (default: test-server)")
    parser.add_argument("--archive", help="Path to existing samp037svr_R2-1.tar.gz archive")
    parser.add_argument("--archive-url", default=archive_url_default, help="URL to download SA-MP server archive (default: community preservation mirror or env SAMP_SERVER_ARCHIVE_URL)")
    parser.add_argument("--archive-sha256", default=archive_sha_default, help="Expected SHA-256 checksum for server archive (default: verified checksum or env SAMP_SERVER_ARCHIVE_SHA256)")
    parser.add_argument("--skip-download", action="store_true", help="Do not attempt to download server archive")

    args = parser.parse_args()
    dest_path = Path(args.dest).resolve()
    archive_path = Path(args.archive).resolve() if args.archive else None

    print("=================================================================")
    print(" SUI TEST SERVER SETUP TOOL (SUI-014)")
    print("=================================================================")
    print(f"Destination:    {dest_path}")
    print(f"Archive URL:    {args.archive_url}")
    print(f"Expected SHA:   {args.archive_sha256}")

    ok = setup_server(
        dest_dir=dest_path,
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
