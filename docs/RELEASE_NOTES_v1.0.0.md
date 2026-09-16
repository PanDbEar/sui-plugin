# SUI (Smart UI Virtualizer) — Release Notes v1.0.0 (Release Candidate Draft)

**Release Target:** v1.0.0  
**Target Platform:** SA-MP 0.3.7-R2 Linux x86 (ELF32 / Intel 80386 / -m32)  
**License:** MIT License (Copyright (c) 2026 PanDbEar)

---

## Overview

**SUI (Smart UI Virtualizer)** is an intelligent lifecycle manager and PlayerTextDraw virtualizer designed for SA-MP 0.3.7-R2 and legacy open.mp server environments.

In standard SA-MP servers, the host engine enforces a hard limit of 256 PlayerTextDraw allocations per player (`MAX_PLAYER_TEXT_DRAWS = 256`). Complex user interfaces (inventory systems, custom HUDs, speedometers, interactive dialogs, character creation menus) easily exhaust this limit when multiple systems allocate textdraws simultaneously.

SUI resolves this limitation by virtualizing UI groups. Groups are allocated on demand, hidden when inactive, automatically destroyed after configurable idle timeouts, and prioritized for non-destructive LRU capacity eviction under memory pressure. SUI operates without hooking, binary patching, or intercepting native textdraw calls: the gamemode retains complete control over visual formatting and native creation.

---

## Target Platform & Architecture

- **Operating System:** Linux x86 (32-bit ELF, Intel 80386).
- **Toolchain:** GCC multilib with mandatory `-m32`.
- **Interface:** Canonical SA-MP 0.3.7-R2 legacy plugin architecture.
- **Canonical Exports (6):** `Supports`, `Load`, `Unload`, `AmxLoad`, `AmxUnload`, `ProcessTick`.
- **Platform Scope:** Native open.mp components (`IComponent`), Windows native builds, and 64-bit architectures are not supported.

---

## Key Features

1. **Lazy On-Demand Allocation**: Textdraws are instantiated via `cbCreate` only when a group is first shown to a player.
2. **Idle Destruction**: Inactive, hidden UI groups automatically destroy their allocated textdraws after a configurable duration, reclaiming host slots for active UI.
3. **Non-Destructive LRU Capacity Eviction**: When textdraw capacity nears exhaustion, SUI deterministically evicts least-recently-used, evictable hidden groups. Preflight sufficiency checks ensure no groups are destroyed if capacity needs cannot be fully met.
4. **Fine-Grained Priorities**: Groups can be configured with eviction priority levels (`LOW`, `NORMAL`, `HIGH`, `CRITICAL`) to shield critical HUD elements from eviction while allowing background menus to release resources.
5. **Multi-AMX Ownership Isolation**: Groups are owned by the specific script (gamemode or filterscript) that registers them. Callbacks dispatch strictly to the owner AMX, preventing cross-script hijacking.
6. **Owner-AMX Pre-Unload Cleanup (`SUI_CleanupOwnerGroups`)**: Provides an explicit terminal cleanup native for filterscripts and gamemodes, invoking lifecycle callbacks and purging metadata while the calling script AMX is still fully valid.
7. **Callback Failure Quarantine & Recovery (SUI-018)**: Protects against unhandled Pawn runtime errors during creation by attempting best-effort compensating destroy transactions and quarantining failed groups from unbounded handle accumulation.

---

## Public API Surface (20 C++ Natives + 1 Stock Helper)

### Core Lifecycle & Virtualization Natives
- `SUI_CreatePlayerFactoryGroup(playerid, const group[], const cbCreate[], const cbDestroy[], const cbShow[], const cbHide[])`
- `SUI_ShowGroup(playerid, const group[])`
- `SUI_HideGroup(playerid, const group[])`
- `SUI_DestroyGroup(playerid, const group[])`
- `SUI_TouchGroup(playerid, const group[])`
- `SUI_CleanupPlayer(playerid)`
- `SUI_ResetPlayer(playerid)`
- `SUI_CleanupOwnerGroups()`

### Configuration Setters & Diagnostics
- `SUI_SetGroupSize(playerid, const group[], size)`
- `SUI_SetIdleTimeout(playerid, const group[], timeout_ms)`
- `SUI_SetGroupPriority(playerid, const group[], priority)`
- `SUI_SetGroupEvictable(playerid, const group[], bool:evictable)`
- `SUI_SetMaxTextDraws(playerid, max)`
- `SUI_SetEvictionThreshold(playerid, threshold)`
- `SUI_SetDebug(bool:enable)`

### Inspection Queries
- `SUI_GetActiveTextDrawCount(playerid)`
- `bool:SUI_IsGroupCreated(playerid, const group[])`
- `bool:SUI_IsGroupVisible(playerid, const group[])`
- `bool:SUI_IsGroupEvictable(playerid, const group[])`
- `SUI_PrintPlayerState(playerid)`

### Shipped Stock Helper
- `stock SUI_RegisterGroup(playerid, const group[], const cbCreate[], const cbDestroy[], const cbShow[], const cbHide[], size, timeout_ms, priority, bool:evictable)`  
  Prevalidates parameters, registers factory group, and configures size, timeout, priority, and eviction eligibility in a single atomic call.

---

## Critical Lifecycle Requirements

### Explicit Owner Pre-Unload Cleanup (SUI-016)
In SA-MP architecture, plugin `AmxUnload` is invoked **after** the host AMX instance has already been torn down. Pawn callbacks cannot execute safely inside `AmxUnload`.

Therefore, scripts that dynamically load or unload (e.g. filterscripts) **MUST** invoke `SUI_CleanupOwnerGroups()` in `OnFilterScriptExit` or `OnGameModeExit` before terminating:

```pawn
public OnFilterScriptExit()
{
    // Executes cbHide and cbDestroy callbacks for all groups owned by this script
    SUI_CleanupOwnerGroups();
    return 1;
}
```

If a script unloads without calling `SUI_CleanupOwnerGroups()`, SUI passive safety nets will purge internal tracking and balance capacity accounting, but external host textdraw handles allocated by that script cannot be destroyed via Pawn callbacks and will remain allocated in the host until server shutdown.

---

## Known Limitations & Boundaries (SUI-018)

> [!IMPORTANT]
> **SUI-018 Mitigation Boundary**:
> SUI virtualizes high-level UI groups and does not own or intercept individual host SA-MP `PlayerTextDraw` allocation handles.
> 
> Under SUI-018, SUI implements callback error quarantine and best-effort compensating destruction. However, **SUI cannot recover raw external `PlayerTextDraw` handles that were never stored anywhere accessible to cooperative cleanup code** (for example, handles stored only in local variables that are aborted by an unhandled AMX runtime error before assignment to module-level state).
> 
> SUI does not market or guarantee zero host-resource leakage under arbitrary script crashes. Gamemode authors must write fail-safe creation callbacks that record allocated handles into array/global state immediately upon allocation.

---

## Verification Evidence

SUI v1.0.0 is verified across **Four Formal Evidence Layers**:

- **Layer A (Static Contracts):**
  - `AP1–AP7`: 7 / 7 PASS (`check_api_surface.py`)
  - `RC1–RC6`: 6 / 6 PASS (`check_source_surface.py`)
- **Layer B (Build & Compilation):**
  - Plugin Binary: Linux x86 ELF32, Intel 80386, DYN, `-m32` mandatory
  - Canonical Exports: All 6 canonical entry points present
  - Pawn Compilation: 23 / 23 scripts PASS with 0 errors and 0 emitted warnings under pinned policy (`-w239`)
- **Layer C (Live Runtime Regression):**
  - **179 / 179 executed runtime assertions passed across 13 permanent suites** on headless SA-MP 0.3.7-R2 server
  - Zero crashes, zero iterator invalidations, zero capacity leaks across all suites
- **Layer D (Release Packaging & Smoke):**
  - `PK1–PK12`: 12 / 12 PASS (`check_release_package.py`)
  - Package Smoke: PASS (isolated boundary boot and shutdown using only packaged assets)

---

## Distribution Package Layout

Official release packages bundle only canonical distribution files:

```text
sui-plugin-1.0.0/
├── plugins/
│   └── sui-plugin-legacy.so      # Validated ELF32 Intel 80386 shared object
├── pawno/
│   └── include/
│       └── sui.inc               # Public Pawn API include (20 C++ natives + 1 stock helper)
├── examples/
│   └── factory_login_example.pwn # Reference factory UI implementation
├── docs/
│   ├── API_REFERENCE.md          # Complete public API reference
│   └── BUILD.md                  # Source compilation & multilib toolchain guide
├── README.md                     # Project overview and quick start
├── CHANGELOG.md                  # Project version history and issue ledger
├── LICENSE                       # Canonical MIT License
├── BUILD_INFO.txt                # Build traceability metadata (Git commit, SDK pin, epoch)
└── SHA256SUMS                    # Internal SHA-256 manifest of all packaged files
```

---

## Installation Guide

1. Extract `sui-plugin-1.0.0-linux-x86.tar.gz` into your SA-MP server directory.
2. Copy `plugins/sui-plugin-legacy.so` to your server's `plugins/` directory.
3. Add `sui-plugin-legacy.so` to your `server.cfg` `plugins` line:
   ```text
   plugins sui-plugin-legacy.so
   ```
4. Copy `pawno/include/sui.inc` to your Pawn compiler include directory.
5. In your gamemode or filterscript:
   ```pawn
   #include <sui>
   ```
