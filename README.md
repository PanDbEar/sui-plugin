# SUI — Smart UI Virtualizer

[![C++ Standard](https://img.shields.io/badge/C%2B%2B-20-blue.svg)](https://en.wikipedia.org/wiki/C%2B%2B20)
[![Platform](https://img.shields.io/badge/Platform-Linux%20x86%20(32--bit)-orange.svg)](docs/BUILD.md)
[![CI](https://img.shields.io/badge/CI-Automated%20Gates%20(4--Layer)-brightgreen.svg)](docs/CI.md)
[![Version](https://img.shields.io/badge/Version-v1.0.0-brightgreen.svg)](docs/RELEASE.md)

**SUI (Smart UI Virtualizer)** is an intelligent UI lifecycle manager and PlayerTextDraw virtualizer designed for SA-MP and open.mp legacy plugin environments.

SUI prevents PlayerTextDraw exhaustion (`MAX_PLAYER_TEXT_DRAWS = 256`) by decoupling UI logic from permanent allocation. TextDraw pools are lazily allocated on demand, hidden when inactive, automatically destroyed after an idle period, and prioritized for eviction under memory pressure.

SUI **does not hook or intercept native textdraw calls**. All rendering, allocation, and destruction remain fully controlled by your gamemode via standard Pawn callbacks.

---

## Target Platform & Compatibility

- **Primary Target:** Legacy SA-MP/open.mp-compatible plugin interface on **Linux x86 / 32-bit**.
- **Windows / MSVC:** Not currently verified.
- **Native open.mp Component (`IComponent`):** Not supported. SUI strictly targets the legacy SA-MP/open.mp 32-bit plugin interface. Experimental prototypes were audited and removed under SUI-012.
- **64-bit:** Not supported. SA-MP and legacy open.mp plugin hosts run strictly as 32-bit processes.

---

## Key Features

- **Lazy Group Allocation**: TextDraws are created only when first shown to the player.
- **Idle Destruction**: Hidden UI groups automatically destroy their textdraws after a configurable timeout (freeing server and client slots).
- **Capacity & Eviction Engine**: Monitors player textdraw count against an eviction threshold; automatically evicts least-recently-used, non-critical hidden groups when capacity is needed.
- **Eviction Priorities**: Fine-grained priority levels (`LOW`, `NORMAL`, `HIGH`, `CRITICAL`) to protect vital HUD elements while allowing background dialogs to evict.
- **Safe Disconnect Cleanup**: Comprehensive player cleanup on disconnect hides and destroys all allocated groups.
- **Dynamic Diagnostics**: Runtime state inspection and detailed debug logging.

---

## Core Concept: Factory UI Groups

SUI operates on one foundational rule:

$$\text{1 UI Pool} = \text{1 SUI Group}$$

For example:
- `login` $\rightarrow$ `CreateLoginTD` / `DestroyLoginTD` / `ShowLoginTD` / `HideLoginTD`
- `inventory` $\rightarrow$ `CreateInvTD` / `DestroyInvTD` / `ShowInvTD` / `HideInvTD`
- `speedometer` $\rightarrow$ `CreateSpeedoTD` / `DestroySpeedoTD` / `ShowSpeedoTD` / `HideSpeedoTD`

```
                      +-------------------+
                      |   SUI_ShowGroup   |
                      +---------+---------+
                                |
                   Is Group Created in Memory?
                                |
                     +----------+----------+
                  NO |                     | YES
                     v                     |
              +--------------+             |
              |   cbCreate   |             |
              +------+-------+             |
                     |                     |
                     +---------->+<--------+
                                 |
                                 v
                          +--------------+
                          |    cbShow    |
                          +--------------+
                                 |
                                 v
                           Group Visible
```

When a group is hidden with `SUI_HideGroup`:
1. `cbHide` is called immediately.
2. Group enters `hidden` state and an idle timer starts.
3. If not re-shown within `idleTimeoutMs`, `cbDestroy` is called and memory is reclaimed.

---

## Quick Start Guide

### 1. Define Public Callbacks in Pawn

Callbacks **must** be declared `public`. In accordance with SUI-006, lifecycle state transitions depend strictly on AMX execution success (`AMX_ERR_NONE`), not Pawn return values (return values are informational and do not veto transitions):

```pawn
new PlayerText:gLoginUI[MAX_PLAYERS] = { INVALID_PLAYER_TEXT_DRAW, ... };

forward CreateLoginTD(playerid);
public CreateLoginTD(playerid)
{
    if (gLoginUI[playerid] != INVALID_PLAYER_TEXT_DRAW) return 1;

    gLoginUI[playerid] = CreatePlayerTextDraw(playerid, 320.0, 240.0, "Welcome to SUI!");
    PlayerTextDrawAlignment(playerid, gLoginUI[playerid], TEXT_DRAW_ALIGN_CENTER);
    return 1;
}

forward DestroyLoginTD(playerid);
public DestroyLoginTD(playerid)
{
    if (gLoginUI[playerid] != INVALID_PLAYER_TEXT_DRAW)
    {
        PlayerTextDrawDestroy(playerid, gLoginUI[playerid]);
        gLoginUI[playerid] = INVALID_PLAYER_TEXT_DRAW;
    }
    return 1;
}

forward ShowLoginTD(playerid);
public ShowLoginTD(playerid)
{
    if (gLoginUI[playerid] == INVALID_PLAYER_TEXT_DRAW) return 0;
    PlayerTextDrawShow(playerid, gLoginUI[playerid]);
    return 1;
}

forward HideLoginTD(playerid);
public HideLoginTD(playerid)
{
    if (gLoginUI[playerid] == INVALID_PLAYER_TEXT_DRAW) return 1;
    PlayerTextDrawHide(playerid, gLoginUI[playerid]);
    return 1;
}
```

### 2. Register & Show Group

```pawn
public OnPlayerConnect(playerid)
{
    // Register group with 1 TD, 5s timeout, HIGH priority, non-evictable
    SUI_RegisterGroup(
        playerid,
        "login",
        "CreateLoginTD",
        "DestroyLoginTD",
        "ShowLoginTD",
        "HideLoginTD",
        .size = 1,
        .timeout_ms = 5000,
        .priority = SUI_PRIORITY_HIGH,
        .evictable = false
    );

    SUI_ShowGroup(playerid, "login");
    return 1;
}
```

### 3. Hide on Spawn & Cleanup on Disconnect

```pawn
public OnPlayerSpawn(playerid)
{
    // Hides immediately; auto-destroys after 5 seconds idle
    SUI_HideGroup(playerid, "login");
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    // Hides and destroys all groups, cleans player context
    SUI_CleanupPlayer(playerid);
    return 1;
}
```

---

## Pawn API Overview

| Function / Native | Description |
| :--- | :--- |
| `SUI_CreatePlayerFactoryGroup` | Register a group with custom lifecycle callbacks |
| `SUI_RegisterGroup` | Helper stock to register and configure in one call |
| `SUI_ShowGroup` | Show group (creating if not yet created) |
| `SUI_HideGroup` | Hide group and begin idle destruction timer |
| `SUI_DestroyGroup` | Immediately hide and destroy a group |
| `SUI_TouchGroup` | Touch group to refresh LRU eviction activity timestamp |
| `SUI_CleanupPlayer` | Clean up all groups when player disconnects |
| `SUI_ResetPlayer` | Reset all groups for an active player |
| `SUI_SetIdleTimeout` | Configure idle destruction duration (ms) |
| `SUI_SetGroupSize` | Declare number of textdraws in group |
| `SUI_SetGroupPriority` | Set eviction priority (`LOW`, `NORMAL`, `HIGH`, `CRITICAL`) |
| `SUI_SetGroupEvictable` | Toggle automatic capacity eviction eligibility |
| `SUI_SetMaxTextDraws` | Configure maximum active player textdraw budget |
| `SUI_SetEvictionThreshold` | Configure eviction high-water mark trigger threshold |
| `SUI_GetActiveTextDrawCount` | Query current active textdraw count |
| `SUI_IsGroupCreated` | Check if group textdraws are allocated |
| `SUI_IsGroupVisible` | Check if group is currently visible |
| `SUI_IsGroupEvictable` | Check if group is eligible for eviction |
| `SUI_PrintPlayerState` | Print debug snapshot of player state |
| `SUI_SetDebug` | Enable / disable verbose debug logs |
| `SUI_CleanupOwnerGroups` | Safely execute lifecycle cleanup and purge all groups owned by calling AMX before script unload |

For complete signatures and parameter details, see [API Reference](docs/API_REFERENCE.md).  
For the engineering synchronization ledger, see [API Inventory](docs/API_INVENTORY.md).

---

## Project Structure

```text
sui-plugin/
├── CMakeLists.txt                # CMake build configuration (32-bit legacy plugin)
├── README.md                     # Project documentation
├── CONTRIBUTING.md               # Contribution rules & API sync checklist
├── SECURITY.md                   # Security & stability report policy
├── CHANGELOG.md                  # Project change log (Keep a Changelog format)
├── .gitignore                    # Build and artifact exclusions
├── pawn/
│   └── sui.inc                   # Pawn include file with natives, constants & helpers
├── examples/
│   └── factory_login_example.pwn # Working sample gamemode / script
├── docs/
│   ├── API_INVENTORY.md          # Engineering synchronization ledger
│   ├── API_REFERENCE.md          # Comprehensive Pawn API reference
│   ├── ARCHITECTURE_AUDIT.md     # Phase 0 architectural & runtime audit
│   ├── KNOWN_ISSUES.md           # Authoritative issue tracker (SUI-001..SUI-018)
│   └── BUILD.md                  # Compilation & installation guide
├── lib/
│   └── samp-plugin-sdk/          # SA-MP legacy plugin SDK (contains nested .git)
└── src/
    ├── main.cpp                  # Plugin entry points (Supports, Load, AmxLoad)
    ├── Core.hpp / Core.cpp       # Virtualizer state store & lifecycle engine
    ├── Natives.hpp / Natives.cpp # AMX native parameter dispatchers
    └── Utils.hpp                 # Tick & string parameter helpers
```

---

## Building & Installation

See [Build Guide](docs/BUILD.md) for full Linux (multilib) build instructions and platform notes.

```bash
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . --config Release -j4
```

### Package Installation (Prebuilt Release)

For SA-MP 0.3.7-R2 Linux x86 servers:

1. Download and extract the official release archive (`sui-plugin-<VERSION>-linux-x86.tar.gz` or `.zip`).
2. Copy `plugins/sui-plugin-legacy.so` to your server's `plugins/` directory:
   ```bash
   cp plugins/sui-plugin-legacy.so /path/to/server/plugins/
   ```
3. Add `sui-plugin-legacy.so` to your `server.cfg` plugins directive:
   ```text
   plugins sui-plugin-legacy.so
   ```
4. Copy `pawno/include/sui.inc` into your Pawn compiler include directory:
   ```bash
   cp pawno/include/sui.inc /path/to/pawno/include/
   ```
5. Include SUI in your gamemode or filterscript:
   ```pawn
   #include <sui>
   ```

---

## Engineering Status & Roadmap

This project is currently verified across **13 permanent runtime test suites (179 assertions, 100% PASS)** across 4 verification layers:

- [x] **Phase 0 / 0.1**: Truthful baseline, repository hygiene, synchronized API inventory, issue ledger, build documentation.
- [x] **Phase 1**: Critical runtime stability — resolve re-entrancy / iterator invalidation (SUI-001), AMX ownership (SUI-002), return code trap (SUI-006), and registration behavior (SUI-011).
- [x] **Phase 2**: Capacity engine & validation — non-destructive eviction (SUI-007), overflow safety (SUI-004), automated test harness and CI (SUI-014).
- [x] **Phase 3**: Platform & ecosystem — release packaging (SUI-015).
- [x] **Phase 4**: Owner-AMX lifecycle cleanup — explicit pre-unload group cleanup (SUI-016).
- [x] **Phase 5**: Callback error recovery — best-effort compensation & quarantine mitigation (SUI-018, classified `MITIGATED`).

Review the test and CI architecture in [docs/CI.md](docs/CI.md) and active issue ledger in [docs/KNOWN_ISSUES.md](docs/KNOWN_ISSUES.md).

---

## License

This project is licensed under the [MIT License](LICENSE).

Copyright (c) 2026 PanDbEar. Third-party licensing and attribution information is documented separately where applicable.
