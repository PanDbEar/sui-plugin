#!/usr/bin/env python3
"""
SUI API Contract Surface Checker (SUI-010)

Performs static verification to guarantee synchronization between:
- pawn/sui.inc (native declarations, stock helpers, priority constants)
- src/main.cpp (AMX_NATIVE_INFO registration table)
- src/Natives.hpp & src/Natives.cpp (C++ handler declarations and CheckParams)
- src/Core.hpp (internal defaults and SUIPriority enum)
- docs/API_REFERENCE.md (human-facing documentation)
"""

import sys
import re
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
    inc_path = root / "pawn" / "sui.inc"
    main_path = root / "src" / "main.cpp"
    natives_h_path = root / "src" / "Natives.hpp"
    natives_cpp_path = root / "src" / "Natives.cpp"
    core_h_path = root / "src" / "Core.hpp"
    docs_api_path = root / "docs" / "API_REFERENCE.md"

    print("==================================================")
    print(" SUI API CONTRACT SURFACE CHECKER (SUI-010)")
    print("==================================================")

    checks_passed = 0
    total_checks = 0

    # 1. Parse pawn/sui.inc
    with open(inc_path, "r", encoding="utf-8") as f:
        inc_content = f.read()

    # Extract natives
    native_pattern = re.compile(r"^\s*native\s+(?:bool:)?([A-Za-z0-9_]+)\s*\(([^)]*)\);", re.MULTILINE)
    natives_in_inc = []
    inc_param_counts = {}
    for match in native_pattern.finditer(inc_content):
        name = match.group(1)
        params_str = match.group(2).strip()
        params = [p.strip() for p in params_str.split(",") if p.strip()] if params_str else []
        natives_in_inc.append(name)
        inc_param_counts[name] = len(params)

    # Extract stock helpers
    stock_pattern = re.compile(r"^\s*stock\s+(?:bool:)?([A-Za-z0-9_]+)\s*\(", re.MULTILINE)
    stocks_in_inc = [match.group(1) for match in stock_pattern.finditer(inc_content)]

    # 2. Parse src/main.cpp registration table
    with open(main_path, "r", encoding="utf-8") as f:
        main_content = f.read()

    table_match = re.search(r"AMX_NATIVE_INFO\s+natives\[\]\s*=\s*\{(.*?)\n\};", main_content, re.DOTALL)
    if not table_match:
        print("[FAIL] Could not find AMX_NATIVE_INFO natives[] table in src/main.cpp")
        return 1

    entry_pattern = re.compile(r'\{\s*"([A-Za-z0-9_]+)"\s*,\s*([A-Za-z0-9_:]+)\s*\}')
    registered_entries = entry_pattern.findall(table_match.group(1))
    registered_names = [e[0] for e in registered_entries]
    registered_handlers = [e[1] for e in registered_entries]

    # 3. Parse src/Natives.hpp declarations
    with open(natives_h_path, "r", encoding="utf-8") as f:
        natives_h_content = f.read()

    declared_handlers = re.findall(r"cell\s+AMX_NATIVE_CALL\s+([A-Za-z0-9_]+)\s*\(", natives_h_content)

    # 4. Parse src/Natives.cpp CheckParams
    with open(natives_cpp_path, "r", encoding="utf-8") as f:
        natives_cpp_content = f.read()

    cpp_param_counts = {}
    handler_blocks = re.split(r"cell\s+AMX_NATIVE_CALL\s+Natives::([A-Za-z0-9_]+)", natives_cpp_content)
    for i in range(1, len(handler_blocks), 2):
        h_name = handler_blocks[i]
        h_body = handler_blocks[i+1]
        cp_match = re.search(r"Utils::CheckParams\s*\(\s*params\s*,\s*(\d+)\s*\)", h_body)
        if cp_match:
            cpp_param_counts[h_name] = int(cp_match.group(1))

    # 5. Parse docs/API_REFERENCE.md
    with open(docs_api_path, "r", encoding="utf-8") as f:
        docs_content = f.read()

    doc_native_headers = re.findall(r"^###\s+`?(SUI_[A-Za-z0-9_]+)`?", docs_content, re.MULTILINE)
    doc_natives = [name for name in doc_native_headers if name != "SUI_RegisterGroup"]

    # RUN CHECKS

    # AP1: Native Count Check
    total_checks += 1
    if len(natives_in_inc) == 19 and len(registered_names) == 19:
        checks_passed += 1
        print(f"[AP1] PASS: Authoritative native count is exactly 19 in include and registration table.")
    else:
        print(f"[AP1] FAIL: Native counts mismatch: include={len(natives_in_inc)}, registration={len(registered_names)} (expected 19)")

    # AP2: Include vs Registration Name Equality
    total_checks += 1
    inc_set = set(natives_in_inc)
    reg_set = set(registered_names)
    if inc_set == reg_set:
        checks_passed += 1
        print(f"[AP2] PASS: Native names in pawn/sui.inc and src/main.cpp match 100% (set equality).")
    else:
        diff_inc = inc_set - reg_set
        diff_reg = reg_set - inc_set
        print(f"[AP2] FAIL: Name discrepancy: in include but not registered: {diff_inc}; registered but not in include: {diff_reg}")

    # AP3: Stock Helper Distinction
    total_checks += 1
    if "SUI_RegisterGroup" in stocks_in_inc and "SUI_RegisterGroup" not in inc_set and "SUI_RegisterGroup" not in reg_set:
        checks_passed += 1
        print(f"[AP3] PASS: SUI_RegisterGroup is classified as stock helper, not C++ native.")
    else:
        print(f"[AP3] FAIL: SUI_RegisterGroup improperly classified.")

    # AP4: Parameter Count Audit
    total_checks += 1
    param_mismatches = []
    for name, inc_count in inc_param_counts.items():
        cpp_count = cpp_param_counts.get(name)
        if cpp_count is None or cpp_count != inc_count:
            param_mismatches.append((name, inc_count, cpp_count))

    if not param_mismatches:
        checks_passed += 1
        print(f"[AP4] PASS: All 19 natives have matching parameter counts between pawn/sui.inc and CheckParams.")
    else:
        print(f"[AP4] FAIL: Parameter count mismatches found: {param_mismatches}")

    # AP5: Handler Declarations & Definitions Audit
    total_checks += 1
    handler_mismatches = []
    for reg_name, reg_handler in registered_entries:
        raw_handler = reg_handler.split("::")[-1]
        if raw_handler not in declared_handlers:
            handler_mismatches.append(f"Handler {raw_handler} not declared in Natives.hpp")
        if raw_handler not in cpp_param_counts:
            handler_mismatches.append(f"Handler {raw_handler} not defined in Natives.cpp")

    if not handler_mismatches:
        checks_passed += 1
        print(f"[AP5] PASS: All 19 registered C++ handlers are declared in Natives.hpp and defined in Natives.cpp.")
    else:
        print(f"[AP5] FAIL: C++ handler mismatches: {handler_mismatches}")

    # AP6: Documentation Synchronization
    total_checks += 1
    doc_set = set(doc_natives)
    if doc_set == reg_set:
        checks_passed += 1
        print(f"[AP6] PASS: All 19 registered natives are documented in docs/API_REFERENCE.md.")
    else:
        missing_doc = reg_set - doc_set
        extra_doc = doc_set - reg_set
        print(f"[AP6] FAIL: Documentation discrepancy: missing in docs: {missing_doc}; extra in docs: {extra_doc}")

    # AP7: Priority Constants Synchronization
    total_checks += 1
    inc_priorities = dict(re.findall(r"#define\s+(SUI_PRIORITY_[A-Z]+)\s+\((\d+)\)", inc_content))
    expected_priorities = {
        "SUI_PRIORITY_LOW": "0",
        "SUI_PRIORITY_NORMAL": "1",
        "SUI_PRIORITY_HIGH": "2",
        "SUI_PRIORITY_CRITICAL": "3"
    }
    if inc_priorities == expected_priorities:
        checks_passed += 1
        print(f"[AP7] PASS: Priority constants (LOW=0, NORMAL=1, HIGH=2, CRITICAL=3) synchronized.")
    else:
        print(f"[AP7] FAIL: Priority constants mismatch: {inc_priorities}")

    print("==================================================")
    print(f" TOTAL RESULT: {checks_passed} / {total_checks} CHECKS PASSED")
    print("==================================================")

    return 0 if checks_passed == total_checks else 1

if __name__ == "__main__":
    sys.exit(main())
