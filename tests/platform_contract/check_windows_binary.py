#!/usr/bin/env python3
"""
SUI Windows Binary Contract Checker (Phase 19)

Verifies PE32 binaries directly against official Windows x86 platform requirements:
- WB1: Valid DOS MZ Header (0x5A4D)
- WB2: Valid PE Signature (IMAGE_NT_SIGNATURE)
- WB3: Target Machine is IMAGE_FILE_MACHINE_I386 (0x014C); reject x64/AMD64 (0x8664)
- WB4: Format is PE32 (0x010B), rejecting 64-bit PE32+ (0x020B)
- WB5: File characteristics indicate IMAGE_FILE_DLL (0x2000)
- WB6: Export directory contains all 6 canonical undecorated exports
"""

import argparse
import struct
import sys
from pathlib import Path

CANONICAL_EXPORTS = [
    "Supports",
    "Load",
    "Unload",
    "AmxLoad",
    "AmxUnload",
    "ProcessTick",
]

IMAGE_FILE_MACHINE_I386 = 0x014C
IMAGE_FILE_MACHINE_AMD64 = 0x8664
IMAGE_FILE_DLL = 0x2000
MAGIC_PE32 = 0x010B
MAGIC_PE32_PLUS = 0x020B


def validate_windows_pe_binary(file_path: Path) -> tuple[bool, list[str]]:
    details: list[str] = []
    if not file_path.exists():
        return False, [f"File not found: {file_path}"]

    try:
        data = file_path.read_bytes()
    except Exception as e:
        return False, [f"Failed to read file: {e}"]

    # -------------------------------------------------------------
    # WB1: DOS Header
    # -------------------------------------------------------------
    if len(data) < 64:
        return False, [f"File too small for DOS header: {len(data)} bytes"]

    if data[:2] != b"MZ":
        return False, [f"Invalid DOS MZ magic: {data[:2]!r} (expected b'MZ')"]
    details.append("[WB1] PASS: DOS MZ header validated.")

    e_lfanew = struct.unpack_from("<I", data, 0x3C)[0]
    if e_lfanew + 24 > len(data):
        return False, [f"Invalid PE header offset e_lfanew: 0x{e_lfanew:X}"]

    # -------------------------------------------------------------
    # WB2: PE Signature
    # -------------------------------------------------------------
    pe_sig = data[e_lfanew : e_lfanew + 4]
    if pe_sig != b"PE\x00\x00":
        return False, [f"Invalid PE signature: {pe_sig!r} (expected b'PE\\0\\0')"]
    details.append("[WB2] PASS: Valid PE signature verified.")

    # -------------------------------------------------------------
    # WB3 & WB5: COFF File Header
    # -------------------------------------------------------------
    coff_offset = e_lfanew + 4
    if coff_offset + 20 > len(data):
        return False, ["Truncated COFF file header"]

    machine, num_sections, _, _, _, opt_size, characteristics = struct.unpack_from(
        "<HHIIIHH", data, coff_offset
    )

    if machine == IMAGE_FILE_MACHINE_AMD64:
        return False, [
            f"[WB3] FAIL: Machine is 0x{machine:04X} (IMAGE_FILE_MACHINE_AMD64). 64-bit binaries strictly rejected."
        ]
    elif machine != IMAGE_FILE_MACHINE_I386:
        return False, [
            f"[WB3] FAIL: Machine is 0x{machine:04X} (expected IMAGE_FILE_MACHINE_I386 = 0x014C)"
        ]
    details.append(
        f"[WB3] PASS: Machine architecture validated as IMAGE_FILE_MACHINE_I386 (0x{machine:04X})."
    )

    if not (characteristics & IMAGE_FILE_DLL):
        return False, [
            f"[WB5] FAIL: Missing IMAGE_FILE_DLL flag in characteristics (0x{characteristics:04X})"
        ]
    details.append(
        f"[WB5] PASS: File characteristics include IMAGE_FILE_DLL (0x{characteristics:04X})."
    )

    # -------------------------------------------------------------
    # WB4: Optional Header & PE32 validation
    # -------------------------------------------------------------
    opt_offset = coff_offset + 20
    if opt_offset + opt_size > len(data) or opt_size < 96:
        return False, ["Truncated or invalid Optional Header"]

    opt_magic = struct.unpack_from("<H", data, opt_offset)[0]
    if opt_magic == MAGIC_PE32_PLUS:
        return False, [
            "[WB4] FAIL: Optional header magic is 0x020B (PE32+ 64-bit). 64-bit binaries strictly rejected."
        ]
    elif opt_magic != MAGIC_PE32:
        return False, [
            f"[WB4] FAIL: Optional header magic is 0x{opt_magic:04X} (expected PE32 = 0x010B)"
        ]
    details.append(f"[WB4] PASS: Optional header format validated as PE32 (0x{opt_magic:04X}).")

    num_rva_and_sizes = struct.unpack_from("<I", data, opt_offset + 92)[0]
    if num_rva_and_sizes < 1:
        return False, ["No data directories found in Optional Header"]

    export_rva, export_size = struct.unpack_from("<II", data, opt_offset + 96)
    if export_rva == 0 or export_size == 0:
        return False, ["No export directory found in PE binary"]

    # Read section table
    sec_table_offset = opt_offset + opt_size
    sections = []
    for i in range(num_sections):
        s_off = sec_table_offset + i * 40
        if s_off + 40 > len(data):
            break
        s_name = data[s_off : s_off + 8].decode("latin1", errors="replace").strip("\x00")
        v_size, v_addr, raw_size, raw_ptr = struct.unpack_from("<IIII", data, s_off + 8)
        sections.append({
            "name": s_name,
            "v_addr": v_addr,
            "v_size": v_size,
            "raw_size": raw_size,
            "raw_ptr": raw_ptr,
        })

    def rva_to_offset(rva: int) -> int | None:
        for sec in sections:
            sec_span = max(sec["v_size"], sec["raw_size"])
            if sec["v_addr"] <= rva < sec["v_addr"] + sec_span:
                return sec["raw_ptr"] + (rva - sec["v_addr"])
        return None

    # -------------------------------------------------------------
    # WB6: Export Directory & Canonical Symbols
    # -------------------------------------------------------------
    export_offset = rva_to_offset(export_rva)
    if export_offset is None or export_offset + 40 > len(data):
        return False, ["Failed to resolve export directory table offset"]

    num_names = struct.unpack_from("<I", data, export_offset + 24)[0]
    names_rva = struct.unpack_from("<I", data, export_offset + 32)[0]
    names_offset = rva_to_offset(names_rva)

    if names_offset is None:
        return False, ["Failed to resolve export names pointer table"]

    exported_symbols = set()
    for i in range(num_names):
        entry_offset = names_offset + i * 4
        if entry_offset + 4 > len(data):
            break
        name_rva = struct.unpack_from("<I", data, entry_offset)[0]
        str_offset = rva_to_offset(name_rva)
        if str_offset is not None and str_offset < len(data):
            null_pos = data.find(b"\x00", str_offset)
            if null_pos != -1:
                sym_name = data[str_offset:null_pos].decode("latin1", errors="replace")
                exported_symbols.add(sym_name)

    missing = [exp for exp in CANONICAL_EXPORTS if exp not in exported_symbols]
    if missing:
        return False, [
            f"[WB6] FAIL: Missing canonical plugin exports in PE export table: {missing}. Present: {sorted(list(exported_symbols))}"
        ]

    details.append(
        f"[WB6] PASS: All 6 canonical plugin exports present in PE export table: {CANONICAL_EXPORTS}"
    )
    return True, details


def main():
    parser = argparse.ArgumentParser(description="SUI Windows PE32 Binary Contract Checker")
    parser.add_argument("binary", help="Path to sui-plugin-legacy.dll")
    args = parser.parse_args()

    binary_path = Path(args.binary).resolve()
    print("==================================================")
    print(" SUI WINDOWS PE32 BINARY CONTRACT CHECKER         ")
    print("==================================================")
    print(f"Target Binary: {binary_path}")

    ok, details = validate_windows_pe_binary(binary_path)
    for line in details:
        print(line)

    if ok:
        print("==================================================")
        print(" WINDOWS PE32 BINARY VERIFICATION: PASS           ")
        print("==================================================")
        sys.exit(0)
    else:
        print("==================================================")
        print(" WINDOWS PE32 BINARY VERIFICATION: FAIL           ")
        print("==================================================")
        sys.exit(1)


if __name__ == "__main__":
    main()
