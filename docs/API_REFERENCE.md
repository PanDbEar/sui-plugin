# SUI — Pawn API Reference

Complete documentation of all Pawn natives, helpers, and constants provided by **SUI (Smart UI Virtualizer)** in `pawn/sui.inc`.

---

## 1. Priority Constants

Used with `SUI_SetGroupPriority` and `SUI_RegisterGroup` to determine eviction order when memory limits are reached.

```pawn
#define SUI_PRIORITY_LOW        (0)
#define SUI_PRIORITY_NORMAL     (1)
#define SUI_PRIORITY_HIGH       (2)
#define SUI_PRIORITY_CRITICAL   (3)
```

| Constant | Value | Description |
| :--- | :--- | :--- |
| `SUI_PRIORITY_LOW` | `0` | First candidate for capacity eviction when hidden. |
| `SUI_PRIORITY_NORMAL` | `1` | Default priority level. Evicted after LOW priority groups. |
| `SUI_PRIORITY_HIGH` | `2` | High-importance UI. Evicted only if LOW and NORMAL pools are exhausted. |
| `SUI_PRIORITY_CRITICAL` | `3` | **Exempt from automatic eviction.** Will never be destroyed by capacity pressure. |

---

## 2. Lifecycle Natives

### `SUI_CreatePlayerFactoryGroup`
```pawn
native SUI_CreatePlayerFactoryGroup(playerid, const group[], const cbCreate[], const cbDestroy[], const cbShow[], const cbHide[]);
```
Registers a UI group for a player with four lifecycle callbacks.
- **`playerid`**: Target player ID.
- **`group[]`**: Unique group name.
- **`cbCreate[]`**: Public function `cbCreate(playerid)` called to allocate textdraws.
- **`cbDestroy[]`**: Public function `cbDestroy(playerid)` called to deallocate textdraws.
- **`cbShow[]`**: Public function `cbShow(playerid)` called to display textdraws.
- **`cbHide[]`**: Public function `cbHide(playerid)` called to hide textdraws.
- **Returns**: `1` on success, `0` on error.

> [!IMPORTANT]
> All callbacks must be declared `public` and must return `1` on success.

---

### `SUI_ShowGroup`
```pawn
native SUI_ShowGroup(playerid, const group[]);
```
Shows a group. If the group has not yet been created, SUI will:
1. Verify capacity (evicting hidden groups if needed).
2. Call `cbCreate`.
3. Call `cbShow`.
- **Returns**: `1` on success, `0` on error.

---

### `SUI_HideGroup`
```pawn
native SUI_HideGroup(playerid, const group[]);
```
Hides an active group. If visible, calls `cbHide` and initiates the idle destruction countdown.
- **Returns**: `1` on success, `0` on error.

---

### `SUI_DestroyGroup`
```pawn
native bool:SUI_DestroyGroup(playerid, const group[]);
```
Immediately destroys a group. If the group is currently visible, it calls `cbHide` first, followed by `cbDestroy`, and deducts its size from the active textdraw counter.
- **Returns**: `true` on success, `false` on error.

---

### `SUI_CleanupPlayer`
```pawn
native SUI_CleanupPlayer(playerid);
```
Cleans up all groups for a player. Intended for `OnPlayerDisconnect`. Hides all visible groups, destroys all allocated groups, and removes the player's tracking state from memory.
- **Returns**: `1`.

---

### `SUI_ResetPlayer`
```pawn
native SUI_ResetPlayer(playerid);
```
Resets all SUI groups and counters for an active player without disconnecting.
- **Returns**: `1`.

---

## 3. Configuration & Capacity Natives

### `SUI_SetIdleTimeout`
```pawn
native SUI_SetIdleTimeout(playerid, const group[], timeout_ms);
```
Configures the duration in milliseconds that a group remains allocated while hidden before being automatically destroyed.
- **`timeout_ms`**: Must be a non-negative integer (`>= 0`). Negative values are rejected and return `0`.
- **Default**: `30000` (30 seconds).
- **Returns**: `1` on success, `0` on validation error or group not found.

---

### `SUI_SetGroupSize`
```pawn
native SUI_SetGroupSize(playerid, const group[], size);
```
Specifies the number of PlayerTextDraws managed by the group. Used for capacity tracking and eviction threshold calculations.
Configures the estimated size before group creation. It cannot modify the size of an already-created group (`isCreated == true`) or a group currently executing a lifecycle callback (`isExecutingCallback == true`).
- **`size`**: Must be a non-negative integer (`>= 0`). Negative values are rejected and return `0`. A value of `0` is accepted and normalized to `1`.
- **Returns**: `1` on success, `0` on validation error, group not found, or if the group is already created / executing a lifecycle callback.

---

### `SUI_SetMaxTextDraws`
```pawn
native SUI_SetMaxTextDraws(playerid, max_count);
```
Sets the upper bound of PlayerTextDraws tracked for a player.
- **`max_count`**: Must be a non-negative integer (`>= 0`). Negative values are rejected and return `0`. A value of `0` defaults to `256`.
- **Default**: `256`.
- **Returns**: `1` on success, `0` on validation error.

---

### `SUI_SetEvictionThreshold`
```pawn
native SUI_SetEvictionThreshold(playerid, threshold);
```
Sets the threshold count of active textdraws above which SUI begins evicting hidden groups.
- **`threshold`**: Must be a non-negative integer (`>= 0`). Negative values are rejected and return `0`. A value of `0` defaults to `230`.
- **Default**: `230`.
- **Returns**: `1` on success, `0` on validation error.

---

### `SUI_SetGroupPriority`
```pawn
native SUI_SetGroupPriority(playerid, const group[], priority);
```
Assigns an eviction priority (`SUI_PRIORITY_LOW` to `SUI_PRIORITY_CRITICAL`).
- **`priority`**: Must be within the domain `0` to `3` (`SUI_PRIORITY_LOW` .. `SUI_PRIORITY_CRITICAL`). Any value outside this range is rejected and returns `0`.
- **Returns**: `1` on success, `0` on validation error or group not found.

---

### `SUI_SetGroupEvictable`
```pawn
native SUI_SetGroupEvictable(playerid, const group[], bool:enabled);
```
Enables or disables automatic capacity eviction for the specified group.
- **`enabled`**: Follows standard Pawn boolean convention (`0` = false, non-zero = true).
- **Returns**: `1` on success, `0` on error.

---

## 4. State & Inspection Natives

### `SUI_IsGroupCreated`
```pawn
native bool:SUI_IsGroupCreated(playerid, const group[]);
```
Returns `true` if the group textdraws are currently allocated in memory.

---

### `SUI_IsGroupVisible`
```pawn
native bool:SUI_IsGroupVisible(playerid, const group[]);
```
Returns `true` if the group is currently visible on the player's screen.

---

### `SUI_IsGroupEvictable`
```pawn
native bool:SUI_IsGroupEvictable(playerid, const group[]);
```
Returns `true` if the group is eligible for automatic capacity eviction.

---

### `SUI_GetActiveTextDrawCount`
```pawn
native SUI_GetActiveTextDrawCount(playerid);
```
Returns the total number of PlayerTextDraws currently tracked across all created groups for the player.

---

### `SUI_TouchGroup`
```pawn
native bool:SUI_TouchGroup(playerid, const group[]);
```
Updates the group's last-used timestamp to the current tick.

---

### `SUI_PrintPlayerState`
```pawn
native SUI_PrintPlayerState(playerid);
```
Dumps full player status (active textdraws, max limit, threshold, and group states) to the server console/log.

---

### `SUI_SetDebug`
```pawn
native SUI_SetDebug(bool:enabled);
```
Enables or disables plugin-level debug output to server logs.

---

## 5. Helper Stocks

### `SUI_RegisterGroup`
```pawn
stock SUI_RegisterGroup(
    playerid,
    const group[],
    const cbCreate[],
    const cbDestroy[],
    const cbShow[],
    const cbHide[],
    size = 1,
    timeout_ms = 30000,
    priority = SUI_PRIORITY_NORMAL,
    bool:evictable = true
);
```
Convenience function that combines registration, size declaration, idle timeout, priority, and evictability configuration into a single call.
