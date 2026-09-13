#if defined _sui_included
	#endinput
#endif
#define _sui_included

/**
 * ============================================================================
 * SUI — Smart UI Virtualizer
 * Pawn Include Definitions & Helpers
 * ============================================================================
 */

/*
 * Eviction Priority Levels
 * Groups with lower priority are evicted first when the threshold is reached.
 * Groups with SUI_PRIORITY_CRITICAL are never automatically evicted.
 */
#define SUI_PRIORITY_LOW        (0)
#define SUI_PRIORITY_NORMAL     (1)
#define SUI_PRIORITY_HIGH       (2)
#define SUI_PRIORITY_CRITICAL   (3)

/*
 * ----------------------------------------------------------------------------
 * Lifecycle Natives
 * ----------------------------------------------------------------------------
 */

/**
 * Registers a UI group for a player with factory lifecycle callbacks.
 * 
 * @param playerid Target player ID
 * @param group Unique group name identifier
 * @param cbCreate Public function called when the group needs to be created: cbCreate(playerid)
 * @param cbDestroy Public function called when the group needs to be destroyed: cbDestroy(playerid)
 * @param cbShow Public function called to show created textdraws: cbShow(playerid)
 * @param cbHide Public function called to hide visible textdraws: cbHide(playerid)
 * @return 1 on success, 0 on failure
 */
native SUI_CreatePlayerFactoryGroup(playerid, const group[], const cbCreate[], const cbDestroy[], const cbShow[], const cbHide[]);

/**
 * Shows a group. If the group has not been created yet, calls the create callback first,
 * then calls the show callback.
 * 
 * @param playerid Target player ID
 * @param group Group name
 * @return 1 on success, 0 on failure
 */
native SUI_ShowGroup(playerid, const group[]);

/**
 * Hides a group and starts its idle timeout counter.
 * 
 * @param playerid Target player ID
 * @param group Group name
 * @return 1 on success, 0 on failure
 */
native SUI_HideGroup(playerid, const group[]);

/**
 * Destroys a group immediately (hiding it first if currently visible).
 * 
 * @param playerid Target player ID
 * @param group Group name
 * @return 1 on success, 0 on failure
 */
native bool:SUI_DestroyGroup(playerid, const group[]);

/**
 * Cleans up all groups for a player. Called on disconnect.
 * Hides any visible groups, destroys all created groups, and removes player state.
 * 
 * @param playerid Target player ID
 * @return 1 on success, 0 on failure
 */
native SUI_CleanupPlayer(playerid);

/**
 * Resets SUI state for an active player without disconnecting.
 * 
 * @param playerid Target player ID
 * @return 1 on success, 0 on failure
 */
native SUI_ResetPlayer(playerid);

/*
 * ----------------------------------------------------------------------------
 * Configuration & Tuning Natives
 * ----------------------------------------------------------------------------
 */

/**
 * Sets the idle timeout in milliseconds before a hidden group is automatically destroyed.
 * 
 * @param playerid Target player ID
 * @param group Group name
 * @param timeout_ms Timeout duration in milliseconds (default: 30000)
 * @return 1 on success, 0 on failure
 */
native SUI_SetIdleTimeout(playerid, const group[], timeout_ms);

/**
 * Declares the estimated PlayerTextDraw count for a group.
 * 
 * @param playerid Target player ID
 * @param group Group name
 * @param size Number of PlayerTextDraws in the group
 * @return 1 on success, 0 on failure
 */
native SUI_SetGroupSize(playerid, const group[], size);

/**
 * Sets the maximum number of PlayerTextDraws allowed per player.
 * 
 * @param playerid Target player ID
 * @param max_count Maximum count (default: 256)
 * @return 1 on success, 0 on failure
 */
native SUI_SetMaxTextDraws(playerid, max_count);

/**
 * Sets the threshold of active textdraws that triggers eviction of hidden groups.
 * 
 * @param playerid Target player ID
 * @param threshold Eviction threshold (default: 230)
 * @return 1 on success, 0 on failure
 */
native SUI_SetEvictionThreshold(playerid, threshold);

/**
 * Sets the eviction priority for a group (SUI_PRIORITY_LOW .. SUI_PRIORITY_CRITICAL).
 * 
 * @param playerid Target player ID
 * @param group Group name
 * @param priority Priority level
 * @return 1 on success, 0 on failure
 */
native SUI_SetGroupPriority(playerid, const group[], priority);

/**
 * Enables or disables automatic eviction for a group when memory/threshold limits are reached.
 * 
 * @param playerid Target player ID
 * @param group Group name
 * @param enabled True to allow eviction, false to protect from automatic eviction
 * @return 1 on success, 0 on failure
 */
native SUI_SetGroupEvictable(playerid, const group[], bool:enabled);

/*
 * ----------------------------------------------------------------------------
 * State & Inspection Natives
 * ----------------------------------------------------------------------------
 */

/**
 * Retrieves the current tracked active PlayerTextDraw count for a player.
 * 
 * @param playerid Target player ID
 * @return Number of active textdraws
 */
native SUI_GetActiveTextDrawCount(playerid);

/**
 * Checks if a group is currently created (allocated in memory).
 * 
 * @param playerid Target player ID
 * @param group Group name
 * @return true if created, false otherwise
 */
native bool:SUI_IsGroupCreated(playerid, const group[]);

/**
 * Checks if a group is currently visible on the player's screen.
 * 
 * @param playerid Target player ID
 * @param group Group name
 * @return true if visible, false otherwise
 */
native bool:SUI_IsGroupVisible(playerid, const group[]);

/**
 * Checks if a group is marked as evictable.
 * 
 * @param playerid Target player ID
 * @param group Group name
 * @return true if evictable, false otherwise
 */
native bool:SUI_IsGroupEvictable(playerid, const group[]);

/**
 * Updates the last-used timestamp for a group to prevent early LRU eviction.
 * 
 * @param playerid Target player ID
 * @param group Group name
 * @return true on success, false if group not found
 */
native bool:SUI_TouchGroup(playerid, const group[]);

/**
 * Dumps the player's full SUI state and group table to server console/log.
 * 
 * @param playerid Target player ID
 * @return 1
 */
native SUI_PrintPlayerState(playerid);

/**
 * Toggles verbose debug logging from the plugin.
 * 
 * @param enabled True to enable debug logs, false to disable
 * @return 1
 */
native SUI_SetDebug(bool:enabled);

/*
 * ----------------------------------------------------------------------------
 * Helper Stocks
 * ----------------------------------------------------------------------------
 */

/**
 * Helper stock to register and configure a factory group in a single call.
 * 
 * @param playerid Target player ID
 * @param group Unique group name
 * @param cbCreate Public create callback name
 * @param cbDestroy Public destroy callback name
 * @param cbShow Public show callback name
 * @param cbHide Public hide callback name
 * @param size Estimated textdraw count (default: 1)
 * @param timeout_ms Idle destruction timeout in ms (default: 30000)
 * @param priority Eviction priority (default: SUI_PRIORITY_NORMAL)
 * @param evictable Whether group is evictable (default: true)
 * @return 1 on success
 */
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
)
{
    SUI_CreatePlayerFactoryGroup(playerid, group, cbCreate, cbDestroy, cbShow, cbHide);
    SUI_SetGroupSize(playerid, group, size);
    SUI_SetIdleTimeout(playerid, group, timeout_ms);
    SUI_SetGroupPriority(playerid, group, priority);
    SUI_SetGroupEvictable(playerid, group, evictable);
    return 1;
}