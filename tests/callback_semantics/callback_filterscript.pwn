#define FILTERSCRIPT
#include <a_samp>
#include "../../pawn/sui.inc"

new g_fs_shared_calls = 0;

forward SharedCallback_ZeroReturn(playerid);
public SharedCallback_ZeroReturn(playerid)
{
    g_fs_shared_calls++;
    printf("[FS] SharedCallback_ZeroReturn executed for playerid=%d", playerid);
    return 0;
}

forward FS_GetSharedCallCount();
public FS_GetSharedCallCount()
{
    return g_fs_shared_calls;
}

forward FS_ResetCounts();
public FS_ResetCounts()
{
    g_fs_shared_calls = 0;
    return 1;
}

public OnFilterScriptInit()
{
    print("[FS] SUI Callback Semantics Filterscript Loaded.");
    return 1;
}

public OnFilterScriptExit()
{
    print("[FS] SUI Callback Semantics Filterscript Unloaded.");
    return 1;
}
