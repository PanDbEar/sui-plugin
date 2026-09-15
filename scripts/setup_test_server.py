#!/usr/bin/env python3
"""
SUI Repository Test Server Setup Tool (SUI-014)

Prepares a clean, isolated SA-MP 0.3.7-R2 Linux test server environment
without committing proprietary binaries to version control.

Features:
- Downloads official SA-MP 0.3.7-R2 Linux server archive (with fallback mirrors)
- Extracts samp03svr and required server assets
- Creates gamemodes/, filterscripts/, plugins/, and scriptfiles/ directories
- Generates default server.cfg tailored for headless plugin regression testing
- Sets executable permissions (+x) on samp03svr
"""

import sys
import os
import tarfile
import urllib.request
import argparse
from pathlib import Path

DEFAULT_SERVER_ARCHIVE_URLS = [
    # Community preservation archive (verified)
    "https://raw.githubusercontent.com/Se8870/SAMP-File-Archive/master/archives/samp037svr_R2-1.tar.gz",
    # Legacy official URL (fallback)
    "http://files.sa-mp.com/samp037svr_R2-1.tar.gz",
]

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

def download_archive(urls, dest_path: Path):
    dest_path.parent.mkdir(parents=True, exist_ok=True)
    for url in urls:
        print(f"[DOWNLOAD] Attempting download from: {url}")
        try:
            req = urllib.request.Request(
                url,
                headers={"User-Agent": "Mozilla/5.0 (SUI-CI-Automation)"}
            )
            with urllib.request.urlopen(req, timeout=30) as response, open(dest_path, "wb") as out_file:
                out_file.write(response.read())
            if dest_path.stat().st_size > 100000:
                print(f"[DOWNLOAD] Successfully retrieved archive ({dest_path.stat().st_size} bytes).")
                return True
        except Exception as e:
            print(f"[DOWNLOAD] Mirror failed: {e}")
            if dest_path.exists():
                dest_path.unlink()
    return False

def setup_server(dest_dir: Path, archive_path: Path = None, skip_download: bool = False):
    dest_dir.mkdir(parents=True, exist_ok=True)
    server_bin = dest_dir / "samp03svr"

    if server_bin.exists() and not archive_path:
        print(f"[SETUP] Server binary already exists at {server_bin}.")
    else:
        if not archive_path or not archive_path.exists():
            if skip_download:
                print("ERROR: Server binary missing and skip_download was requested.")
                return False
            archive_path = dest_dir / "samp037svr_R2-1.tar.gz"
            success = download_archive(DEFAULT_SERVER_ARCHIVE_URLS, archive_path)
            if not success:
                print("ERROR: Failed to download SA-MP 0.3.7-R2 Linux server archive from all mirrors.")
                return False

        print(f"[EXTRACT] Extracting {archive_path.name} into {dest_dir}...")
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

                target_file = dest_dir.joinpath(*rel_parts)
                if member.isdir():
                    target_file.mkdir(parents=True, exist_ok=True)
                elif member.isfile():
                    target_file.parent.mkdir(parents=True, exist_ok=True)
                    with tar.extractfile(member) as src, open(target_file, "wb") as dst:
                        dst.write(src.read())

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
    parser = argparse.ArgumentParser(description="Setup SA-MP 0.3.7-R2 test server for SUI CI/regression.")
    parser.add_argument("--dest", default="test-server", help="Destination directory for test server (default: test-server)")
    parser.add_argument("--archive", help="Path to existing samp037svr_R2-1.tar.gz archive")
    parser.add_argument("--skip-download", action="store_true", help="Do not attempt to download server archive")

    args = parser.parse_args()
    dest_path = Path(args.dest).resolve()
    archive_path = Path(args.archive).resolve() if args.archive else None

    print("=================================================================")
    print(" SUI TEST SERVER SETUP TOOL (SUI-014)")
    print("=================================================================")
    print(f"Destination: {dest_path}")

    ok = setup_server(dest_path, archive_path, args.skip_download)
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
