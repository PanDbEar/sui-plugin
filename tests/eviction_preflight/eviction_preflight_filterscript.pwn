#define FILTERSCRIPT
#include <a_samp>
#include "../../pawn/sui.inc"

new g_fs_e14_destroy_calls = 0;

forward OnE14_FS_Create(playerid);
public OnE14_FS_Create(playerid)
{
    printf("[FS] OnE14_FS_Create invoked playerid=%d", playerid);
    return 1;
}

forward OnE14_FS_Destroy(playerid);
public OnE14_FS_Destroy(playerid)
{
    g_fs_e14_destroy_calls++;
    printf("[FS] OnE14_FS_Destroy invoked playerid=%d (calls=%d)", playerid, g_fs_e14_destroy_calls);
    return 1;
}

forward OnE14_FS_Show(playerid);
public OnE14_FS_Show(playerid)
{
    printf("[FS] OnE14_FS_Show invoked playerid=%d", playerid);
    return 1;
}

forward OnE14_FS_Hide(playerid);
public OnE14_FS_Hide(playerid)
{
    printf("[FS] OnE14_FS_Hide invoked playerid=%d", playerid);
    return 1;
}

forward FS_RegisterE14(playerid);
public FS_RegisterE14(playerid)
{
    new res = SUI_CreatePlayerFactoryGroup(playerid, "e14_fs_grp", "OnE14_FS_Create", "OnE14_FS_Destroy", "OnE14_FS_Show", "OnE14_FS_Hide");
    SUI_SetGroupSize(playerid, "e14_fs_grp", 25);
    SUI_SetGroupPriority(playerid, "e14_fs_grp", SUI_PRIORITY_LOW);
    SUI_SetGroupEvictable(playerid, "e14_fs_grp", true);
    return res;
}

forward FS_ShowHideE14(playerid);
public FS_ShowHideE14(playerid)
{
    new s = SUI_ShowGroup(playerid, "e14_fs_grp");
    new h = SUI_HideGroup(playerid, "e14_fs_grp");
    return (s && h);
}

forward FS_GetDestroyCalls();
public FS_GetDestroyCalls()
{
    return g_fs_e14_destroy_calls;
}

public OnFilterScriptInit()
{
    print("[FS] SUI Eviction Preflight Filterscript Loaded.");
    return 1;
}

public OnFilterScriptExit()
{
    print("[FS] SUI Eviction Preflight Filterscript Unloaded.");
    return 1;
}
