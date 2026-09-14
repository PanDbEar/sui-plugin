#define FILTERSCRIPT
#include <a_samp>
#include "../../pawn/sui.inc"

new g_fs_t13_destroy_calls = 0;

forward OnT13_FS_Create(playerid);
public OnT13_FS_Create(playerid)
{
    printf("[FS] OnT13_FS_Create invoked playerid=%d", playerid);
    return 1;
}

forward OnT13_FS_Destroy(playerid);
public OnT13_FS_Destroy(playerid)
{
    g_fs_t13_destroy_calls++;
    printf("[FS] OnT13_FS_Destroy invoked playerid=%d (calls=%d)", playerid, g_fs_t13_destroy_calls);
    return 1;
}

forward OnT13_FS_Show(playerid);
public OnT13_FS_Show(playerid)
{
    printf("[FS] OnT13_FS_Show invoked playerid=%d", playerid);
    return 1;
}

forward OnT13_FS_Hide(playerid);
public OnT13_FS_Hide(playerid)
{
    printf("[FS] OnT13_FS_Hide invoked playerid=%d", playerid);
    return 1;
}

forward FS_RegisterT13(playerid);
public FS_RegisterT13(playerid)
{
    new res = SUI_CreatePlayerFactoryGroup(playerid, "t13_fs", "OnT13_FS_Create", "OnT13_FS_Destroy", "OnT13_FS_Show", "OnT13_FS_Hide");
    SUI_SetGroupSize(playerid, "t13_fs", 6);
    return res;
}

forward FS_ShowT13(playerid);
public FS_ShowT13(playerid)
{
    return SUI_ShowGroup(playerid, "t13_fs");
}

forward FS_GetDestroyCalls();
public FS_GetDestroyCalls()
{
    return g_fs_t13_destroy_calls;
}

public OnFilterScriptInit()
{
    print("[FS] SUI Player Teardown Filterscript Loaded.");
    return 1;
}

public OnFilterScriptExit()
{
    print("[FS] SUI Player Teardown Filterscript Unloaded.");
    return 1;
}
