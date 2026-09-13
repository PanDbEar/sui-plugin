# SUI-003 Pawn Native Input Validation Test Plan

This document defines the regression test suite for **SUI-003** (Pawn Native Input Validation and Safe Type Conversion).

---

## 1. Objectives

1. **Signed-to-Unsigned Guarding**: Verify that negative values passed to unsigned parameters (`size`, `max_count`, `threshold`, `timeout_ms`) are strictly rejected (`return 0`) without being wrapped into huge unsigned integers (`4294967295`).
2. **Priority Domain Verification**: Verify that the eviction priority parameter is validated against the defined enum range (`SUI_PRIORITY_LOW` (0) .. `SUI_PRIORITY_CRITICAL` (3)) before conversion.
3. **AMX Memory Safety**: Verify that invalid, corrupted, or out-of-bounds AMX string addresses are safely detected via AMX API return codes (`amx_GetAddr`, `amx_StrLen`, `amx_GetString`) without causing `SIGSEGV` or memory corruption.
4. **Parameter Count Verification**: Verify that calls with insufficient native parameters fail safely without out-of-bounds `params[n]` accesses.
5. **No Partial Mutation**: Verify that native calls failing validation do not alter internal state or leave phantom records.

---

## 2. Test Cases Specification (V1?V10)

### Test V1: Negative Group Size
- **Call**: `SUI_SetGroupSize(0, "v1_group", -1)`
- **Expected Result**: Returns `0`. Group size remains unchanged. No unsigned wrap-around (`4294967295`).

### Test V2: Negative Max TextDraws
- **Call**: `SUI_SetMaxTextDraws(0, -1)`
- **Expected Result**: Returns `0`. Configuration unchanged.

### Test V3: Negative Eviction Threshold
- **Call**: `SUI_SetEvictionThreshold(0, -1)`
- **Expected Result**: Returns `0`. Configuration unchanged.

### Test V4: Negative Idle Timeout
- **Call**: `SUI_SetIdleTimeout(0, "v4_group", -1)`
- **Expected Result**: Returns `0`. Timeout configuration unchanged.

### Test V5: Priority Domain Validation
- **Calls**:
  - `SUI_SetGroupPriority(0, "v5_group", -1)` -> Expected: `0` (REJECTED)
  - `SUI_SetGroupPriority(0, "v5_group", SUI_PRIORITY_LOW)` (0) -> Expected: `1` (ACCEPTED)
  - `SUI_SetGroupPriority(0, "v5_group", SUI_PRIORITY_NORMAL)` (1) -> Expected: `1` (ACCEPTED)
  - `SUI_SetGroupPriority(0, "v5_group", SUI_PRIORITY_HIGH)` (2) -> Expected: `1` (ACCEPTED)
  - `SUI_SetGroupPriority(0, "v5_group", SUI_PRIORITY_CRITICAL)` (3) -> Expected: `1` (ACCEPTED)
  - `SUI_SetGroupPriority(0, "v5_group", 4)` -> Expected: `0` (REJECTED)
  - `SUI_SetGroupPriority(0, "v5_group", 9999)` -> Expected: `0` (REJECTED)
- **Expected Result**: Only values within `[0, 3]` are accepted.

### Test V6: Zero Values Semantic Verification
Analysis of current SUI API semantics for zero values:
- `size = 0`: **VALID** (SUI normalizes zero size to minimum `1`).
  - Call: `SUI_SetGroupSize(0, "v6_group", 0)` -> Returns `1`.
- `timeout_ms = 0`: **VALID** (SUI treats 0 as immediate eviction when hidden on next tick).
  - Call: `SUI_SetIdleTimeout(0, "v6_group", 0)` -> Returns `1`.
- `max_count = 0`: **VALID** (SUI normalizes 0 to default `256`).
  - Call: `SUI_SetMaxTextDraws(0, 0)` -> Returns `1`.
- `threshold = 0`: **VALID** (SUI normalizes 0 to default `230`).
  - Call: `SUI_SetEvictionThreshold(0, 0)` -> Returns `1`.
- `priority = 0`: **VALID** (`SUI_PRIORITY_LOW` is defined as 0).
  - Call: `SUI_SetGroupPriority(0, "v6_group", 0)` -> Returns `1`.

### Test V7: Large Positive Cell Value
- **Call**: `SUI_SetGroupSize(0, "v7_group", 2147483647)` (cell max `0x7FFFFFFF`)
- **Expected Result**: Accepted by SUI-003 (`return 1`) as a valid non-negative integer. Demonstrates that SUI-003 correctly handles large signed 31-bit integers without treating them as negative. (Subsequent arithmetic overflow risks remain tracked under **SUI-004**).

### Test V8: Invalid AMX String Address
- **Call**: `Raw_ShowGroup(0, 0x7FFFFFFF)` (using low-level native alias bypass)
- **Expected Result**: `amx_GetAddr` returns `AMX_ERR_MEMACCESS`. SUI safely rejects the call (`return 0`) without segmentation fault (`SIGSEGV`).

### Test V9: Out-of-Bounds / Negative AMX String Address
- **Call**: `Raw_ShowGroup(0, -1)`
- **Expected Result**: `amx_GetAddr` returns error for negative address. SUI returns `0` safely without crash.

### Test V10: Malformed / Insufficient Native Arguments
- **Call**: `Insufficient_CreateGroup(0, "v10_group")` (passing 2 arguments to native expecting 6)
- **Expected Result**: `Utils::CheckParams(params, 6)` detects parameter count deficit (`params[0] == 8 < 24`). Returns `0` safely without out-of-bounds parameter reads or memory corruption.
