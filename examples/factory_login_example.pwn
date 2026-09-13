/**
 * ============================================================================
 * SUI — Smart UI Virtualizer
 * Example: Factory Login UI Lifecycle
 * ============================================================================
 * 
 * This example demonstrates:
 * 1. Registering a PlayerTextDraw pool using SUI factory callbacks.
 * 2. Lazy initialization: UI is only created when SUI_ShowGroup is called.
 * 3. Idle timeout: UI is destroyed automatically after being hidden for 5 seconds.
 * 4. Automatic cleanup when the player disconnects.
 */

#include <open.mp>
#include <sui>

// Static PlayerTextDraw handle storage
static PlayerText:gLoginUI[MAX_PLAYERS] = { INVALID_PLAYER_TEXT_DRAW, ... };

/*
 * ----------------------------------------------------------------------------
 * SUI Factory Callbacks
 * 
 * NOTE: SUI requires these callbacks to be public.
 * IMPORTANT: Callbacks must return 1 on success. If a callback returns 0,
 * SUI treats the operation as failed.
 * ----------------------------------------------------------------------------
 */

forward CreateLoginTD(playerid);
public CreateLoginTD(playerid)
{
    if (gLoginUI[playerid] != INVALID_PLAYER_TEXT_DRAW)
    {
        return 1;
    }

    gLoginUI[playerid] = CreatePlayerTextDraw(playerid, 320.0, 240.0, "Welcome to Smart UI Virtualizer!");
    PlayerTextDrawAlignment(playerid, gLoginUI[playerid], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawLetterSize(playerid, gLoginUI[playerid], 0.5, 1.5);
    PlayerTextDrawSetShadow(playerid, gLoginUI[playerid], 1);
    PlayerTextDrawSetOutline(playerid, gLoginUI[playerid], 1);
    PlayerTextDrawColor(playerid, gLoginUI[playerid], -1);

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
    if (gLoginUI[playerid] == INVALID_PLAYER_TEXT_DRAW)
    {
        return 0; // Cannot show an uncreated textdraw
    }

    PlayerTextDrawShow(playerid, gLoginUI[playerid]);
    return 1;
}

forward HideLoginTD(playerid);
public HideLoginTD(playerid)
{
    if (gLoginUI[playerid] == INVALID_PLAYER_TEXT_DRAW)
    {
        return 1;
    }

    PlayerTextDrawHide(playerid, gLoginUI[playerid]);
    return 1;
}

/*
 * ----------------------------------------------------------------------------
 * Player Event Handlers
 * ----------------------------------------------------------------------------
 */

public OnPlayerConnect(playerid)
{
    gLoginUI[playerid] = INVALID_PLAYER_TEXT_DRAW;

    /*
     * Register group "login":
     * - group name       : "login"
     * - create callback  : "CreateLoginTD"
     * - destroy callback : "DestroyLoginTD"
     * - show callback    : "ShowLoginTD"
     * - hide callback    : "HideLoginTD"
     * - size             : 1 PlayerTextDraw
     * - timeout_ms       : 5000 ms idle timeout
     * - priority         : SUI_PRIORITY_HIGH
     * - evictable        : false (protected from automatic capacity eviction)
     */
    SUI_RegisterGroup(
        playerid,
        "login",
        "CreateLoginTD",
        "DestroyLoginTD",
        "ShowLoginTD",
        "HideLoginTD",
        1,
        5000,
        SUI_PRIORITY_HIGH,
        false
    );

    // Show the login UI (triggers CreateLoginTD -> ShowLoginTD)
    SUI_ShowGroup(playerid, "login");

    printf("[SUI-EXAMPLE] Login UI shown for playerid=%d (created=%d, visible=%d, activeTD=%d)",
        playerid,
        SUI_IsGroupCreated(playerid, "login"),
        SUI_IsGroupVisible(playerid, "login"),
        SUI_GetActiveTextDrawCount(playerid)
    );

    return 1;
}

public OnPlayerSpawn(playerid)
{
    /*
     * Hide login UI upon spawning:
     * - Hides immediately via HideLoginTD
     * - Automatically calls DestroyLoginTD after 5000 ms idle
     */
    SUI_HideGroup(playerid, "login");
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    /*
     * SUI_CleanupPlayer:
     * - Hides any visible groups
     * - Destroys all created groups
     * - Clears player context in plugin
     */
    SUI_CleanupPlayer(playerid);

    gLoginUI[playerid] = INVALID_PLAYER_TEXT_DRAW;
    return 1;
}

/*
 * ----------------------------------------------------------------------------
 * Test Commands (Standard SA-MP / open.mp Command Processor)
 * ----------------------------------------------------------------------------
 */

public OnPlayerCommandText(playerid, cmdtext[])
{
    if (!strcmp(cmdtext, "/showlogin", true))
    {
        SUI_ShowGroup(playerid, "login");
        SendClientMessage(playerid, -1, "[SUI] SUI_ShowGroup('login') called.");
        return 1;
    }
    if (!strcmp(cmdtext, "/hidelogin", true))
    {
        SUI_HideGroup(playerid, "login");
        SendClientMessage(playerid, -1, "[SUI] SUI_HideGroup('login') called. Auto-destroys in 5s.");
        return 1;
    }
    if (!strcmp(cmdtext, "/destroylogin", true))
    {
        SUI_DestroyGroup(playerid, "login");
        SendClientMessage(playerid, -1, "[SUI] SUI_DestroyGroup('login') called.");
        return 1;
    }
    if (!strcmp(cmdtext, "/suistate", true))
    {
        SUI_PrintPlayerState(playerid);
        SendClientMessage(playerid, -1, "[SUI] State dumped to server console/log.");
        return 1;
    }
    return 0;
}