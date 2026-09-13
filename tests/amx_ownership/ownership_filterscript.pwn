#define FILTERSCRIPT
#include <a_samp>
#include <sui>

new g_fs_shared_calls = 0;
new g_fs_only_fs_calls = 0;
new g_fs_active_create_calls = 0;
new g_fs_hijack_result = -1;

public OnFilterScriptInit()
{
    print("[FS] ownership_filterscript loaded.");
    return 1;
}

public OnFilterScriptExit()
{
    print("[FS] ownership_filterscript exiting.");
    return 1;
}

forward FS_RegisterGroups();
public FS_RegisterGroups()
{
    // A2: Register group pointing to SharedCallback
    SUI_CreatePlayerFactoryGroup(0, "fs_shared_grp", "SharedCallback", "OnFsShared_Destroy", "OnFsShared_Show", "OnFsShared_Hide");
    SUI_SetGroupSize(0, "fs_shared_grp", 5);

    // A4: Attempt to hijack locked_gm_grp registered by gamemode
    g_fs_hijack_result = SUI_CreatePlayerFactoryGroup(0, "locked_gm_grp", "OnFsHijack_Create", "OnFsHijack_Destroy", "OnFsHijack_Show", "OnFsHijack_Hide");

    // A5: Register active group for unload test
    SUI_CreatePlayerFactoryGroup(0, "fs_active_grp", "OnFsActive_Create", "OnFsActive_Destroy", "OnFsActive_Show", "OnFsActive_Hide");
    SUI_SetGroupSize(0, "fs_active_grp", 15);

    return 1;
}

forward FS_ShowActiveGroup();
public FS_ShowActiveGroup()
{
    return SUI_ShowGroup(0, "fs_active_grp");
}

forward SharedCallback(playerid);
public SharedCallback(playerid)
{
    g_fs_shared_calls++;
    printf("[FS] SharedCallback called for playerid=%d (count=%d)", playerid, g_fs_shared_calls);
    return 1;
}

forward OnlyInFilterscript(playerid);
public OnlyInFilterscript(playerid)
{
    g_fs_only_fs_calls++;
    printf("[FS] OnlyInFilterscript called for playerid=%d (count=%d)", playerid, g_fs_only_fs_calls);
    return 1;
}

forward OnFsShared_Destroy(playerid);
public OnFsShared_Destroy(playerid) { return 1; }
forward OnFsShared_Show(playerid);
public OnFsShared_Show(playerid) { return 1; }
forward OnFsShared_Hide(playerid);
public OnFsShared_Hide(playerid) { return 1; }

forward OnFsActive_Create(playerid);
public OnFsActive_Create(playerid)
{
    g_fs_active_create_calls++;
    printf("[FS] OnFsActive_Create called (count=%d)", g_fs_active_create_calls);
    return 1;
}
forward OnFsActive_Destroy(playerid);
public OnFsActive_Destroy(playerid) { return 1; }
forward OnFsActive_Show(playerid);
public OnFsActive_Show(playerid) { return 1; }
forward OnFsActive_Hide(playerid);
public OnFsActive_Hide(playerid) { return 1; }

forward OnFsHijack_Create(playerid);
public OnFsHijack_Create(playerid) { return 1; }
forward OnFsHijack_Destroy(playerid);
public OnFsHijack_Destroy(playerid) { return 1; }
forward OnFsHijack_Show(playerid);
public OnFsHijack_Show(playerid) { return 1; }
forward OnFsHijack_Hide(playerid);
public OnFsHijack_Hide(playerid) { return 1; }

forward FS_GetSharedCallCount();
public FS_GetSharedCallCount()
{
    return g_fs_shared_calls;
}

forward FS_GetOnlyFsCallCount();
public FS_GetOnlyFsCallCount()
{
    return g_fs_only_fs_calls;
}

forward FS_GetHijackResult();
public FS_GetHijackResult()
{
    return g_fs_hijack_result;
}
