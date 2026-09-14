#define FILTERSCRIPT
#include <a_samp>
#include <sui>

new g_fs_id7_create_calls = 0;
new g_fs_id7_destroy_calls = 0;
new g_fs_id7_show_calls = 0;
new g_fs_id7_hide_calls = 0;

public OnFilterScriptInit()
{
    print("[FS-IDENTITY] SUI-017 Group Identity Filterscript loaded.");
    return 1;
}

public OnFilterScriptExit()
{
    print("[FS-IDENTITY] SUI-017 Group Identity Filterscript unloaded.");
    return 1;
}

forward FS_SetupID7(playerid);
public FS_SetupID7(playerid)
{
    g_fs_id7_create_calls = 0;
    g_fs_id7_destroy_calls = 0;
    g_fs_id7_show_calls = 0;
    g_fs_id7_hide_calls = 0;

    new res = SUI_CreatePlayerFactoryGroup(
        playerid,
        "id7_fs",
        "FS_OnID7_Create",
        "FS_OnID7_Destroy",
        "FS_OnID7_Show",
        "FS_OnID7_Hide"
    );
    SUI_SetGroupSize(playerid, "id7_fs", 5);
    return res;
}

forward FS_GetDestroyCalls();
public FS_GetDestroyCalls()
{
    return g_fs_id7_destroy_calls;
}

forward FS_OnID7_Create(playerid);
public FS_OnID7_Create(playerid)
{
    g_fs_id7_create_calls++;
    return 1;
}

forward FS_OnID7_Show(playerid);
public FS_OnID7_Show(playerid)
{
    g_fs_id7_show_calls++;
    return 1;
}

forward FS_OnID7_Hide(playerid);
public FS_OnID7_Hide(playerid)
{
    g_fs_id7_hide_calls++;
    return 1;
}

forward FS_OnID7_Destroy(playerid);
public FS_OnID7_Destroy(playerid)
{
    g_fs_id7_destroy_calls++;

    // During FS destroy callback, reset player and trigger Gamemode to register same name
    SUI_ResetPlayer(playerid);
    CallRemoteFunction("GM_RegisterID7", "d", playerid);

    return 1;
}

new g_fs_cross_create_calls = 0;
new g_fs_cross_show_calls = 0;

forward FS_SetupCrossAmx(playerid);
public FS_SetupCrossAmx(playerid)
{
    g_fs_cross_create_calls = 0;
    g_fs_cross_show_calls = 0;

    new res = SUI_CreatePlayerFactoryGroup(
        playerid,
        "cross_amx_grp",
        "FS_OnCross_Create",
        "FS_OnCross_Destroy",
        "FS_OnCross_Show",
        "FS_OnCross_Hide"
    );
    SUI_SetGroupSize(playerid, "cross_amx_grp", 8);
    return res;
}

forward FS_OnCross_Create(playerid);
public FS_OnCross_Create(playerid) { g_fs_cross_create_calls++; return 1; }

forward FS_OnCross_Show(playerid);
public FS_OnCross_Show(playerid) { g_fs_cross_show_calls++; return 1; }

forward FS_OnCross_Hide(playerid);
public FS_OnCross_Hide(playerid) { return 1; }

forward FS_OnCross_Destroy(playerid);
public FS_OnCross_Destroy(playerid) { return 1; }

forward FS_GetCrossCreateCalls();
public FS_GetCrossCreateCalls() { return g_fs_cross_create_calls; }

forward FS_GetCrossShowCalls();
public FS_GetCrossShowCalls() { return g_fs_cross_show_calls; }

