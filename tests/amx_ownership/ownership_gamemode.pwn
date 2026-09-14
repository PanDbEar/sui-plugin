#include <a_samp>
#include <sui>

new g_gm_group_create_calls = 0;
new g_gm_group_show_calls = 0;
new g_gm_shared_calls = 0;
new g_gm_locked_create_calls = 0;
new g_gm_perm_create_calls = 0;
new g_gm_reclaim_create_calls = 0;

new g_test_a1_pass = 0;
new g_test_a2_pass = 0;
new g_test_a3_pass = 0;
new g_test_a4_pass = 0;
new g_test_a5_pass = 0;
new g_test_a6_pass = 0;
new g_test_a7_pass = 0;

new g_gm_a7_create_calls = 0;

new g_active_count_before_unload = 0;

main()
{
    print("================================================================");
    print("      SUI-002 AMX OWNERSHIP & ISOLATION REGRESSION TEST         ");
    print("================================================================");
}

public OnGameModeInit()
{
    SUI_SetDebug(true);
    SetTimer("RunOwnershipTests", 500, false);
    return 1;
}

forward RunOwnershipTests();
public RunOwnershipTests()
{
    print("\n--- Starting AMX Ownership Tests ---");

    // Pre-registration: Gamemode registers locked_gm_grp FIRST so Filterscript cannot hijack it
    SUI_CreatePlayerFactoryGroup(0, "locked_gm_grp", "OnGmLocked_Create", "OnGmLocked_Destroy", "OnGmLocked_Show", "OnGmLocked_Hide");
    SUI_SetGroupSize(0, "locked_gm_grp", 4);

    // Filterscript registers its groups (and tries to hijack locked_gm_grp)
    CallRemoteFunction("FS_RegisterGroups", "");

    // Gamemode registers other test groups
    SUI_CreatePlayerFactoryGroup(0, "gm_group", "OnGmGroup_Create", "OnGmGroup_Destroy", "OnGmGroup_Show", "OnGmGroup_Hide");
    SUI_SetGroupSize(0, "gm_group", 2);

    SUI_CreatePlayerFactoryGroup(0, "gm_shared_grp", "SharedCallback", "OnGmShared_Destroy", "OnGmShared_Show", "OnGmShared_Hide");
    SUI_SetGroupSize(0, "gm_shared_grp", 3);

    // Missing callback group: points to OnlyInFilterscript (does NOT exist in Gamemode)
    SUI_CreatePlayerFactoryGroup(0, "gm_missing_cb", "OnlyInFilterscript", "OnGmMissing_Destroy", "OnGmMissing_Show", "OnGmMissing_Hide");
    SUI_SetGroupSize(0, "gm_missing_cb", 1);

    // Perm group for unload test
    SUI_CreatePlayerFactoryGroup(0, "gm_perm_grp", "OnGmPerm_Create", "OnGmPerm_Destroy", "OnGmPerm_Show", "OnGmPerm_Hide");
    SUI_SetGroupSize(0, "gm_perm_grp", 10);

    // -------------------------------------------------------------
    // TEST A1: Gamemode Owner Dispatch
    // -------------------------------------------------------------
    print("\n[TEST-A1] Testing Gamemode Owner Dispatch...");
    SUI_ShowGroup(0, "gm_group");

    if (g_gm_group_create_calls == 1 && g_gm_group_show_calls == 1 && SUI_IsGroupVisible(0, "gm_group"))
    {
        g_test_a1_pass = 1;
        print("[TEST-A1] PASS: Gamemode callbacks executed correctly.");
    }
    else
    {
        printf("[TEST-A1] FAIL: create=%d show=%d visible=%d", g_gm_group_create_calls, g_gm_group_show_calls, SUI_IsGroupVisible(0, "gm_group"));
    }

    // -------------------------------------------------------------
    // TEST A2: Callback Name Collision Isolation
    // -------------------------------------------------------------
    print("\n[TEST-A2] Testing Callback Collision Isolation (SharedCallback)...");
    g_gm_shared_calls = 0;

    // Show gamemode's shared group
    SUI_ShowGroup(0, "gm_shared_grp");
    new fsSharedCallsAfterGm = CallRemoteFunction("FS_GetSharedCallCount", "");

    // Show filterscript's shared group
    SUI_ShowGroup(0, "fs_shared_grp");
    new fsSharedCallsAfterFs = CallRemoteFunction("FS_GetSharedCallCount", "");

    if (g_gm_shared_calls == 1 && fsSharedCallsAfterGm == 0 && fsSharedCallsAfterFs == 1)
    {
        g_test_a2_pass = 1;
        print("[TEST-A2] PASS: SharedCallback executed strictly within owning AMX.");
    }
    else
    {
        printf("[TEST-A2] FAIL: gm_calls=%d fs_after_gm=%d fs_after_fs=%d", g_gm_shared_calls, fsSharedCallsAfterGm, fsSharedCallsAfterFs);
    }

    // -------------------------------------------------------------
    // TEST A3: Missing Callback in Owner (No Cross-AMX Fallback)
    // -------------------------------------------------------------
    print("\n[TEST-A3] Testing Missing Callback in Owner...");
    new fsOnlyCallsBefore = CallRemoteFunction("FS_GetOnlyFsCallCount", "");
    SUI_ShowGroup(0, "gm_missing_cb");
    new fsOnlyCallsAfter = CallRemoteFunction("FS_GetOnlyFsCallCount", "");
    new isMissingCreated = SUI_IsGroupCreated(0, "gm_missing_cb");

    if (fsOnlyCallsBefore == 0 && fsOnlyCallsAfter == 0 && isMissingCreated == 0)
    {
        g_test_a3_pass = 1;
        print("[TEST-A3] PASS: Missing callback did NOT fall back to Filterscript.");
    }
    else
    {
        printf("[TEST-A3] FAIL: fs_before=%d fs_after=%d isCreated=%d", fsOnlyCallsBefore, fsOnlyCallsAfter, isMissingCreated);
    }

    // -------------------------------------------------------------
    // TEST A4: Anti-Hijacking Registration Guard
    // -------------------------------------------------------------
    print("\n[TEST-A4] Testing Anti-Hijacking Guard...");
    new hijackResult = CallRemoteFunction("FS_GetHijackResult", "");
    SUI_ShowGroup(0, "locked_gm_grp");

    if (hijackResult == 0 && g_gm_locked_create_calls == 1)
    {
        g_test_a4_pass = 1;
        print("[TEST-A4] PASS: Filterscript hijack rejected (return 0), Gamemode owns group.");
    }
    else
    {
        printf("[TEST-A4] FAIL: hijackResult=%d gm_locked_calls=%d", hijackResult, g_gm_locked_create_calls);
    }

    // -------------------------------------------------------------
    // TEST A7: Anti-Hijacking Guard During Callback Execution
    // -------------------------------------------------------------
    print("\n[TEST-A7] Testing Anti-Hijacking Guard During Callback Execution...");
    SUI_CreatePlayerFactoryGroup(0, "a7_gm_grp", "OnGmA7_Create", "OnGmA7_Destroy", "OnGmA7_Show", "OnGmA7_Hide");
    SUI_SetGroupSize(0, "a7_gm_grp", 3);
    SUI_ShowGroup(0, "a7_gm_grp");

    new a7HijackResult = CallRemoteFunction("FS_GetA7HijackResult", "");
    new a7IsCreated = SUI_IsGroupCreated(0, "a7_gm_grp");
    new a7IsVisible = SUI_IsGroupVisible(0, "a7_gm_grp");

    // Clean up A7 group before unload test
    SUI_DestroyGroup(0, "a7_gm_grp");

    if (a7HijackResult == 0 && g_gm_a7_create_calls == 1 && a7IsCreated == 1 && a7IsVisible == 1)
    {
        g_test_a7_pass = 1;
        print("[TEST-A7] PASS: Filterscript hijack during callback rejected (return 0), Gamemode retains group.");
    }
    else
    {
        printf("[TEST-A7] FAIL: a7HijackResult=%d gm_a7_calls=%d isCreated=%d isVisible=%d",
            a7HijackResult, g_gm_a7_create_calls, a7IsCreated, a7IsVisible);
    }

    // -------------------------------------------------------------
    // TEST A5 & A6 SETUP: Safe Dynamic AMX Unload & Capacity Repair
    // -------------------------------------------------------------
    print("\n[TEST-A5] Preparing AMX Unload test...");
    SUI_ShowGroup(0, "gm_perm_grp"); // size 10
    CallRemoteFunction("FS_ShowActiveGroup", ""); // size 15

    g_active_count_before_unload = SUI_GetActiveTextDrawCount(0);
    printf("[TEST-A5] Active textdraw count before unload: %d", g_active_count_before_unload);

    print("[TEST-A5] Unloading filterscript ownership_filterscript...");
    SendRconCommand("unloadfs ownership_filterscript");

    SetTimer("VerifyUnloadStage", 500, false);
    return 1;
}

forward VerifyUnloadStage();
public VerifyUnloadStage()
{
    print("\n--- Verifying Post-Unload State ---");
    new activeCountAfter = SUI_GetActiveTextDrawCount(0);
    printf("[TEST-A5] Active textdraw count after unload: %d (expected %d)", activeCountAfter, g_active_count_before_unload - 20);

    new fsActiveCreated = SUI_IsGroupCreated(0, "fs_active_grp");
    new fsSharedCreated = SUI_IsGroupCreated(0, "fs_shared_grp");
    new gmPermCreated = SUI_IsGroupCreated(0, "gm_perm_grp");

    if (activeCountAfter == (g_active_count_before_unload - 20) && fsActiveCreated == 0 && fsSharedCreated == 0 && gmPermCreated == 1)
    {
        g_test_a5_pass = 1;
        print("[TEST-A5] PASS: Filterscript groups purged and capacity repaired cleanly.");
    }
    else
    {
        printf("[TEST-A5] FAIL: activeAfter=%d (expected %d) fsActiveCreated=%d fsSharedCreated=%d gmPermCreated=%d",
            activeCountAfter, g_active_count_before_unload - 20, fsActiveCreated, fsSharedCreated, gmPermCreated);
    }

    // -------------------------------------------------------------
    // TEST A6: Post-Unload Group Re-registration
    // -------------------------------------------------------------
    print("\n[TEST-A6] Testing Reclaiming Freed Group Name After Owner Unloaded...");
    new reclaimRegResult = SUI_CreatePlayerFactoryGroup(0, "fs_active_grp", "OnGmReclaim_Create", "OnGmReclaim_Destroy", "OnGmReclaim_Show", "OnGmReclaim_Hide");
    SUI_ShowGroup(0, "fs_active_grp");

    if (reclaimRegResult == 1 && g_gm_reclaim_create_calls == 1 && SUI_IsGroupCreated(0, "fs_active_grp"))
    {
        g_test_a6_pass = 1;
        print("[TEST-A6] PASS: Previously owned group successfully registered and shown by Gamemode.");
    }
    else
    {
        printf("[TEST-A6] FAIL: reclaimReg=%d calls=%d created=%d", reclaimRegResult, g_gm_reclaim_create_calls, SUI_IsGroupCreated(0, "fs_active_grp"));
    }

    // -------------------------------------------------------------
    // SUMMARY REPORT
    // -------------------------------------------------------------
    print("\n================================================================");
    print("          SUI AMX OWNERSHIP REGRESSION RESULTS (A1-A7)          ");
    print("================================================================");
    printf("A1 (Gamemode Owner Dispatch):              %s", (g_test_a1_pass) ? ("PASS") : ("FAIL"));
    printf("A2 (Callback Name Collision Isolation):    %s", (g_test_a2_pass) ? ("PASS") : ("FAIL"));
    printf("A3 (No Fallback on Missing Callback):      %s", (g_test_a3_pass) ? ("PASS") : ("FAIL"));
    printf("A4 (Anti-Hijacking Registration Guard):    %s", (g_test_a4_pass) ? ("PASS") : ("FAIL"));
    printf("A5 (Safe AMX Unload & Capacity Repair):    %s", (g_test_a5_pass) ? ("PASS") : ("FAIL"));
    printf("A6 (Post-Unload Re-registration):          %s", (g_test_a6_pass) ? ("PASS") : ("FAIL"));
    printf("A7 (Anti-Hijack During Owner Callback):    %s", (g_test_a7_pass) ? ("PASS") : ("FAIL"));
    print("================================================================");

    if (g_test_a1_pass && g_test_a2_pass && g_test_a3_pass && g_test_a4_pass && g_test_a5_pass && g_test_a6_pass && g_test_a7_pass)
    {
        print("OVERALL RESULT: ALL AMX OWNERSHIP TESTS PASSED! (7/7)");
    }
    else
    {
        print("OVERALL RESULT: SOME TESTS FAILED!");
    }
    print("================================================================\n");

    print("--- Terminating server after test completion.");
    SendRconCommand("exit");
    return 1;
}

// Callbacks
forward OnGmGroup_Create(playerid);
public OnGmGroup_Create(playerid)
{
    g_gm_group_create_calls++;
    return 1;
}

forward OnGmGroup_Show(playerid);
public OnGmGroup_Show(playerid)
{
    g_gm_group_show_calls++;
    return 1;
}

forward OnGmGroup_Destroy(playerid);
public OnGmGroup_Destroy(playerid) { return 1; }
forward OnGmGroup_Hide(playerid);
public OnGmGroup_Hide(playerid) { return 1; }

forward SharedCallback(playerid);
public SharedCallback(playerid)
{
    g_gm_shared_calls++;
    printf("[GM] SharedCallback called for playerid=%d (count=%d)", playerid, g_gm_shared_calls);
    return 1;
}

forward OnGmShared_Destroy(playerid);
public OnGmShared_Destroy(playerid) { return 1; }
forward OnGmShared_Show(playerid);
public OnGmShared_Show(playerid) { return 1; }
forward OnGmShared_Hide(playerid);
public OnGmShared_Hide(playerid) { return 1; }

forward OnGmLocked_Create(playerid);
public OnGmLocked_Create(playerid)
{
    g_gm_locked_create_calls++;
    return 1;
}
forward OnGmLocked_Destroy(playerid);
public OnGmLocked_Destroy(playerid) { return 1; }
forward OnGmLocked_Show(playerid);
public OnGmLocked_Show(playerid) { return 1; }
forward OnGmLocked_Hide(playerid);
public OnGmLocked_Hide(playerid) { return 1; }

forward OnGmMissing_Destroy(playerid);
public OnGmMissing_Destroy(playerid) { return 1; }
forward OnGmMissing_Show(playerid);
public OnGmMissing_Show(playerid) { return 1; }
forward OnGmMissing_Hide(playerid);
public OnGmMissing_Hide(playerid) { return 1; }

forward OnGmPerm_Create(playerid);
public OnGmPerm_Create(playerid)
{
    g_gm_perm_create_calls++;
    return 1;
}
forward OnGmPerm_Destroy(playerid);
public OnGmPerm_Destroy(playerid) { return 1; }
forward OnGmPerm_Show(playerid);
public OnGmPerm_Show(playerid) { return 1; }
forward OnGmPerm_Hide(playerid);
public OnGmPerm_Hide(playerid) { return 1; }

forward OnGmReclaim_Create(playerid);
public OnGmReclaim_Create(playerid)
{
    g_gm_reclaim_create_calls++;
    return 1;
}
forward OnGmReclaim_Destroy(playerid);
public OnGmReclaim_Destroy(playerid) { return 1; }
forward OnGmReclaim_Show(playerid);
public OnGmReclaim_Show(playerid) { return 1; }
forward OnGmReclaim_Hide(playerid);
public OnGmReclaim_Hide(playerid) { return 1; }

forward OnGmA7_Create(playerid);
public OnGmA7_Create(playerid)
{
    g_gm_a7_create_calls++;
    // Trigger filterscript hijack attempt during callback
    CallRemoteFunction("FS_TryHijackA7", "d", playerid);
    return 1;
}
forward OnGmA7_Destroy(playerid);
public OnGmA7_Destroy(playerid) { return 1; }
forward OnGmA7_Show(playerid);
public OnGmA7_Show(playerid) { return 1; }
forward OnGmA7_Hide(playerid);
public OnGmA7_Hide(playerid) { return 1; }

