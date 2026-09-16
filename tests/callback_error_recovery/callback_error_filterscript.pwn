#define FILTERSCRIPT
#include <a_samp>
#include <sui>

new g_F7_CreateFired = 0;
new g_F7_DestroyFired = 0;
new g_F7_DestroyShouldFail = 1;

new g_F11_CreateFired = 0;
new g_F11_DestroyFired = 0;
new g_F11_DestroyShouldFail = 1;

public OnFilterScriptInit()
{
    print("[FS] callback_error_filterscript loaded.");
    return 1;
}

public OnFilterScriptExit()
{
    print("[FS] callback_error_filterscript exiting.");
    return 1;
}

// ------------------------------------------------------------------
// F7: Filterscript Owner Cleanup Retries Compensating Destroy
// ------------------------------------------------------------------
forward OnFsF7_Create(playerid);
public OnFsF7_Create(playerid)
{
    g_F7_CreateFired++;
    // Deliberate AMX runtime fault injection
    new z = 0;
    new v = 10 / z;
    #pragma unused v
    return 1;
}

forward OnFsF7_Show(playerid);
public OnFsF7_Show(playerid)
{
    return 1;
}

forward OnFsF7_Hide(playerid);
public OnFsF7_Hide(playerid)
{
    return 1;
}

forward OnFsF7_Destroy(playerid);
public OnFsF7_Destroy(playerid)
{
    g_F7_DestroyFired++;
    if (g_F7_DestroyShouldFail)
    {
        new z = 0;
        new v = 10 / z;
        #pragma unused v
    }
    return 1;
}

forward FS_RunF7(playerid);
public FS_RunF7(playerid)
{
    g_F7_CreateFired = 0;
    g_F7_DestroyFired = 0;
    g_F7_DestroyShouldFail = 1;

    SUI_CreatePlayerFactoryGroup(playerid, "fs_f7_grp", "OnFsF7_Create", "OnFsF7_Destroy", "OnFsF7_Show", "OnFsF7_Hide");
    SUI_SetGroupSize(playerid, "fs_f7_grp", 6);

    // Initial show: create fails, immediate destroy fails, group enters quarantine
    new showRes = SUI_ShowGroup(playerid, "fs_f7_grp");
    if (showRes != 0 || g_F7_CreateFired != 1 || g_F7_DestroyFired != 1)
    {
        printf("[FS-F7] Initial quarantine setup failed: showRes=%d createFired=%d destroyFired=%d",
            showRes, g_F7_CreateFired, g_F7_DestroyFired);
        return 0;
    }

    // Clear failure flag so subsequent compensating destroy succeeds
    g_F7_DestroyShouldFail = 0;

    // Trigger owner cleanup: should retry compensating destroy and succeed
    new cleanupRes = SUI_CleanupOwnerGroups();
    if (cleanupRes != 1 || g_F7_DestroyFired != 2)
    {
        printf("[FS-F7] Cleanup retry failed: cleanupRes=%d destroyFired=%d (expected 2)",
            cleanupRes, g_F7_DestroyFired);
        return 0;
    }

    return 1;
}

// ------------------------------------------------------------------
// F11: Cross-AMX Recovery Isolation
// ------------------------------------------------------------------
forward OnFsF11_Create(playerid);
public OnFsF11_Create(playerid)
{
    g_F11_CreateFired++;
    new z = 0;
    new v = 10 / z;
    #pragma unused v
    return 1;
}

forward OnFsF11_Show(playerid);
public OnFsF11_Show(playerid)
{
    return 1;
}

forward OnFsF11_Hide(playerid);
public OnFsF11_Hide(playerid)
{
    return 1;
}

forward OnFsF11_Destroy(playerid);
public OnFsF11_Destroy(playerid)
{
    g_F11_DestroyFired++;
    if (g_F11_DestroyShouldFail)
    {
        new z = 0;
        new v = 10 / z;
        #pragma unused v
    }
    return 1;
}

forward FS_SetupF11(playerid);
public FS_SetupF11(playerid)
{
    g_F11_CreateFired = 0;
    g_F11_DestroyFired = 0;
    g_F11_DestroyShouldFail = 1;

    SUI_CreatePlayerFactoryGroup(playerid, "fs_f11_grp", "OnFsF11_Create", "OnFsF11_Destroy", "OnFsF11_Show", "OnFsF11_Hide");
    SUI_SetGroupSize(playerid, "fs_f11_grp", 8);

    new showRes = SUI_ShowGroup(playerid, "fs_f11_grp");
    if (showRes != 0 || g_F11_CreateFired != 1 || g_F11_DestroyFired != 1)
    {
        return 0;
    }
    return 1;
}

forward FS_CheckF11(playerid);
public FS_CheckF11(playerid)
{
    // Group fs_f11_grp should still be quarantined in FS
    if (SUI_IsGroupCreated(playerid, "fs_f11_grp"))
    {
        return 0;
    }
    new retryShow = SUI_ShowGroup(playerid, "fs_f11_grp");
    if (retryShow != 0 || g_F11_CreateFired != 1)
    {
        return 0;
    }
    return 1;
}

forward FS_Cleanup();
public FS_Cleanup()
{
    g_F11_DestroyShouldFail = 0;
    SUI_CleanupOwnerGroups();
    return 1;
}
