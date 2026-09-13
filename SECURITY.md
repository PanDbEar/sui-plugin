# Security Policy

## Pre-Release Notice

**SUI (Smart UI Virtualizer)** is currently in active pre-release development (Phase 0 / Phase 1).

Because this plugin runs in-process with the multiplayer game server, memory or concurrency defects can compromise server stability or lead to arbitrary crashes.

---

## Scope of Security & Stability Reports

The following conditions should be treated as high-priority security and stability issues:

- **Server Crashes & Denial of Service:** Segmentation faults, unhandled exceptions, access violations, or server hangs triggered by UI lifecycle events.
- **Memory Corruption & Use-After-Free:** Dangling pointers, invalid iterator reads/writes, buffer overflows during string parameter extraction.
- **Container / Iterator Invalidation:** Hash map mutations occurring during active callback iterations (e.g. `ProcessTick`).
- **AMX Misuse & State Corruption:** Unsafe `amx_Exec` parameter stack handling or cross-script callback pollution.
- **Unsafe Native Parameter Handling:** Out-of-bounds player IDs, negative buffer sizes or timeouts resulting in unsigned wraparound, or malformed strings.
- **Plugin-Induced Server Instability:** Resource leaks leading to memory exhaustion.

---

## Reporting a Security or Stability Issue

Please do **NOT** post publicly exploitable server crash vectors or zero-day vulnerabilities in public GitHub issues.

Instead:
1. Use **GitHub Private Vulnerability Reporting** via the repository's **Security** tab (if enabled).
2. Or contact the repository maintainers through private communication channels established on the project's official repository.

When reporting, include:
- Server version (SA-MP 0.3.7, open.mp version, etc.).
- Operating system and architecture (e.g. Linux x86 Ubuntu 22.04).
- A minimal reproducible gamemode/filterscript demonstrating the issue.
- Relevant server console / crash logs (`crashinfo.txt`, `server_log.txt`).
