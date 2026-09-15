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

## 2. Player ID Domain & Boundary Hardening

All player-accepting Pawn natives strictly validate the `playerid` parameter at the outer native boundary before parameter decoding, memory dereferencing, or internal state mutation:
- **Authoritative Domain**: `0 <= playerid < 1000` (matching SA-MP 0.3.7-R2 `MAX_PLAYERS = 1000`).
- **Validation Order**: `CheckParams` -> `TryGetPlayerId` -> other parameter extraction -> `SUICore` dispatch.
- **Rejection Policy**: Values outside `[0..999]` (including negative numbers, `cellmin`, `INVALID_PLAYER_ID` / `65535`, `1000`, and `cellmax`) immediately fail with return code `0` (or `false`), bypassing string decoding and preventing phantom `PlayerContext` map allocations.
- **Cleanup / Reset Semantics**:
  - Valid player ID without existing context: Returns `1` (idempotent success, preserving SUI-005).
  - Invalid player ID: Returns `0` (boundary rejection).

---

## 3. Lifecycle Natives

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

> [!NOTE]
> All lifecycle callbacks must be declared `public`. The callback's Pawn return value is ignored by SUI.
> Lifecycle success is determined solely by whether the callback can be located in the owning AMX and executes without AMX runtime errors.
> Callbacks are not veto hooks; returning `0` will not abort or cancel a lifecycle transition.

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
Performs terminal cleanup of all groups for a player. Intended for `OnPlayerDisconnect`.
- Puts the player into terminal teardown state, rejecting any new group registrations, group shows, or property mutations during callbacks.
- Hides all visible groups (`cbHide`) and invokes `cbDestroy` for all created groups.
- Directly prunes uncreated group definitions without executing callbacks.
- Unconditionally purges the player context and all group tracking state from memory upon completion.
- Nested calls to `SUI_CleanupPlayer` or `SUI_ResetPlayer` during teardown are blocked and return `0`.
- **Returns**: `1` if all group destructions succeeded; `0` if any destroy callback failed, encountered an AMX error, or if called during an active teardown (context is still purged).

---

### `SUI_ResetPlayer`
```pawn
native SUI_ResetPlayer(playerid);
```
Performs non-terminal reset of all SUI groups and counters for an active connected player (e.g. gamemode transition, minigame reset).
- Puts the player into reset teardown state, rejecting any new group registrations, group shows, or property mutations during callbacks.
- Hides all visible groups (`cbHide`) and invokes `cbDestroy` for all created groups.
- Directly prunes uncreated group definitions without executing callbacks.
- Groups whose destruction callback succeeds are removed and their capacity deducted.
- If a group's `cbDestroy` fails or encounters an AMX runtime error, the group is **preserved in tracking** with conservative state (`isCreated = true`, `isVisible = false`) and its textdraw capacity remains allocated to prevent resource leakage.
- If all groups are destroyed cleanly, the player context is fully cleared. If any group fails destruction, the player context is retained with failed groups preserved, and the teardown guard is restored to allow recovery.
- Nested calls to `SUI_CleanupPlayer` or `SUI_ResetPlayer` during teardown are blocked and return `0`.
- **Returns**: `1` if all groups were destroyed cleanly and context was reset; `0` if any group failed destruction (failed groups preserved) or if called during an active teardown.

---

## 4. Configuration & Capacity Natives

### `SUI_SetIdleTimeout`
```pawn
native SUI_SetIdleTimeout(playerid, const group[], timeout_ms);
```
Configures the duration in milliseconds that a group remains allocated while hidden before being automatically destroyed.
- **`timeout_ms`**: Must be a non-negative integer (`>= 0`). Negative values are rejected and return `0`. A value of `0` schedules immediate reclamation on the next server tick where elapsed time > 0 (it does not disable idle reclamation).
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
Sets the hard upper bound of PlayerTextDraws tracked for a player.
- **`max_count`**: Must be a non-negative integer (`>= 0`). Negative values are rejected and return `0`. A value of `0` defaults to `256`. Cannot be lowered below the player's current `activeTextDrawCount` or below the current `evictionThreshold`.
- **Default**: `256`.
- **Returns**: `1` on success, `0` on validation error, if `max_count < activeTextDrawCount`, or if `max_count < evictionThreshold`.

---

### `SUI_SetEvictionThreshold`
```pawn
native SUI_SetEvictionThreshold(playerid, threshold);
```
Sets the soft threshold count of active textdraws above which SUI begins evicting hidden groups.
- **`threshold`**: Must be a non-negative integer (`>= 0`). Negative values are rejected and return `0`. A value of `0` defaults to `230`. Cannot exceed the player's configured `maxTextDraws`.
- **Default**: `230`.
- **Returns**: `1` on success, `0` on validation error or if `threshold > maxTextDraws`.

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

## 5. State & Inspection Natives

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
- **Returns**: `1` on success, `0` if `playerid` is outside the valid domain `[0..999]`.

---

### `SUI_SetDebug`
```pawn
native SUI_SetDebug(bool:enabled);
```
Enables or disables plugin-level debug output to server logs.
- **Returns**: `1` on success, `0` on parameter error.

---

## 6. Helper Stocks

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
- **Returns**: `1` on complete setup success, `0` on any prevalidation failure (e.g. negative size, negative timeout, out-of-bounds priority), registration error (invalid player ID, group already exists under another owner, or re-registration during active callback), or setter failure.
- **Safety**: If prevalidation fails, zero state is created. If the target group is already created (live), `SUI_RegisterGroup` rejects the call immediately (`return 0`) before mutating registration, ensuring existing live UI groups, active textdraw capacity, and original callback contracts remain completely intact and authoritative.
