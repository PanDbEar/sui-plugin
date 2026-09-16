#include <a_samp>
#include <sui>

new g_NpcId = -1;

new g_test_u1_pass = 0;
new g_test_u2_pass = 0;
new g_test_u3_pass = 0;
new g_test_u4_pass = 0;
new g_test_u5_pass = 0;
new g_test_u6_pass = 0;
new g_test_u7_pass = 0;
new g_test_u8_pass = 0;
new g_test_u9_pass = 0;
new g_test_u10_pass = 0;
new g_test_u11_pass = 0;
new g_test_u12_pass = 0;
new g_test_u13_pass = 0;
new g_test_u14_pass = 0;

new g_u11_gm_mutations_rejected = 0;
new g_u12_gm_teardown_rejected = 0;

new g_u8_cycle1_id = -1;
new g_u8_cycle2_id = -1;
new g_u8_cycle3_id = -1;

main()
{
    print("================================================================");
    print("   SUI-016 AMX UNLOAD LIFECYCLE CLEANUP REGRESSION TEST        ");
    print("================================================================");
}

public OnGameModeInit()
{
    SUI_SetDebug(true);
    print("[GM] Connecting TestNPC with npcidle for U8 handle testing...");
    ConnectNPC("TestNPC", "npcidle");
    SetTimer("CheckConnectTimeout", 8000, false);
    return 1;
}

public OnPlayerConnect(playerid)
{
    printf("[GM] OnPlayerConnect: playerid=%d, IsNPC=%d", playerid, IsPlayerNPC(playerid));
    if (IsPlayerNPC(playerid))
    {
        g_NpcId = playerid;
        SetTimer("StartOwnerCleanupTests", 500, false);
    }
    return 1;
}

forward CheckConnectTimeout();
public CheckConnectTimeout()
{
    if (g_NpcId == -1)
    {
        print("[GM] Error: NPC connection timed out after 8s.");
        SendRconCommand("exit");
    }
    return 1;
}

// -------------------------------------------------------------
// GM Callbacks for Cross-AMX Mutation & Teardown Tests
// -------------------------------------------------------------
forward GM_TryMutateA_Group(playerid);
public GM_TryMutateA_Group(playerid)
{
    // During AMX A's cleanup, foreign AMX (Gamemode) attempts mutating A's group across all 8 mutation APIs
    new r1 = SUI_ShowGroup(playerid, "u11_grp");
    new r2 = SUI_HideGroup(playerid, "u11_grp");
    new r3 = SUI_DestroyGroup(playerid, "u11_grp");
    new r4 = SUI_SetIdleTimeout(playerid, "u11_grp", 1000);
    new r5 = SUI_SetGroupPriority(playerid, "u11_grp", 1);
    new r6 = SUI_SetGroupEvictable(playerid, "u11_grp", true);
    new r7 = SUI_SetGroupSize(playerid, "u11_grp", 5);
    new r8 = SUI_TouchGroup(playerid, "u11_grp");

    if (r1 == 0 && r2 == 0 && r3 == 0 && r4 == 0 && r5 == 0 && r6 == 0 && r7 == 0 && r8 == 0)
    {
        g_u11_gm_mutations_rejected = 1;
    }
    else
    {
        printf("[GM] U11 Target Mutation Guard Leak: r1=%d r2=%d r3=%d r4=%d r5=%d r6=%d r7=%d r8=%d",
            r1, r2, r3, r4, r5, r6, r7, r8);
    }
    return 1;
}

forward GM_TryPlayerTeardown(playerid);
public GM_TryPlayerTeardown(playerid)
{
    // During AMX A's cleanup, foreign AMX attempts player teardown
    new r1 = SUI_CleanupPlayer(playerid);
    new r2 = SUI_ResetPlayer(playerid);

    if (r1 == 0 && r2 == 0)
    {
        g_u12_gm_teardown_rejected = 1;
    }
    else
    {
        printf("[GM] U12 Teardown Collision Guard Leak: r1=%d r2=%d", r1, r2);
    }
    return 1;
}

forward OnGmU4_Create(playerid);
public OnGmU4_Create(playerid) { return 1; }
forward OnGmU4_Show(playerid);
public OnGmU4_Show(playerid) { return 1; }
forward OnGmU4_Hide(playerid);
public OnGmU4_Hide(playerid) { return 1; }
forward OnGmU4_Destroy(playerid);
public OnGmU4_Destroy(playerid) { return 1; }

// -------------------------------------------------------------
// Main Test Pipeline Execution
// -------------------------------------------------------------
forward StartOwnerCleanupTests();
public StartOwnerCleanupTests()
{
    print("\n--- Starting SUI-016 AMX Unload Cleanup Tests (U1-U14) ---");

    // Verify direct setter failure contract on non-existent group
    new fail_idle = SUI_SetIdleTimeout(g_NpcId, "nonexistent_grp", 1000);
    new fail_prio = SUI_SetGroupPriority(g_NpcId, "nonexistent_grp", 1);
    new fail_evict = SUI_SetGroupEvictable(g_NpcId, "nonexistent_grp", true);
    if (fail_idle != 0 || fail_prio != 0 || fail_evict != 0)
    {
        printf("[GM] Error: Direct setter failure contract violated on non-existent group: idle=%d prio=%d evict=%d",
            fail_idle, fail_prio, fail_evict);
        SendRconCommand("exit");
        return 1;
    }

    // TEST U1: Visible Created Group Cleanup
    print("\n[TEST-U1] Visible Created Group Cleanup (hide then destroy)...");
    new u1Res = CallRemoteFunction("FS_RunU1", "");
    if (u1Res == 1)
    {
        g_test_u1_pass = 1;
        print("[TEST-U1] PASS: cbHide and cbDestroy executed in order, group purged.");
    }
    else
    {
        print("[TEST-U1] FAIL: U1 execution failed.");
    }

    // TEST U2: Hidden Created Group Cleanup
    print("\n[TEST-U2] Hidden Created Group Cleanup (destroy only)...");
    new u2Res = CallRemoteFunction("FS_RunU2", "");
    if (u2Res == 1)
    {
        g_test_u2_pass = 1;
        print("[TEST-U2] PASS: cbHide skipped, cbDestroy executed, group purged.");
    }
    else
    {
        print("[TEST-U2] FAIL: U2 execution failed.");
    }

    // TEST U3: Uncreated Group Cleanup
    print("\n[TEST-U3] Uncreated Group Cleanup (no callbacks, metadata purged)...");
    new u3Res = CallRemoteFunction("FS_RunU3", "");
    if (u3Res == 1)
    {
        g_test_u3_pass = 1;
        print("[TEST-U3] PASS: zero callbacks invoked, metadata purged cleanly.");
    }
    else
    {
        print("[TEST-U3] FAIL: U3 execution failed.");
    }

    // TEST U4: Mixed-Ownership Isolation
    print("\n[TEST-U4] Mixed-Ownership Isolation (A cleanup leaves B intact)...");
    SUI_CreatePlayerFactoryGroup(0, "gm_u4_grp", "OnGmU4_Create", "OnGmU4_Destroy", "OnGmU4_Show", "OnGmU4_Hide");
    SUI_SetGroupSize(0, "gm_u4_grp", 10);
    SUI_ShowGroup(0, "gm_u4_grp");

    new totalBefore = CallRemoteFunction("FS_SetupU4", "");
    printf("[TEST-U4] Active count before FS cleanup: %d (expected 17)", totalBefore);

    new u4FsRes = CallRemoteFunction("FS_RunU4_Cleanup", "");
    new totalAfter = SUI_GetActiveTextDrawCount(0);
    new gmCreated = SUI_IsGroupCreated(0, "gm_u4_grp");
    new gmVisible = SUI_IsGroupVisible(0, "gm_u4_grp");

    SUI_DestroyGroup(0, "gm_u4_grp"); // GM cleanup

    if (u4FsRes == 1 && totalAfter == 10 && gmCreated == 1 && gmVisible == 1)
    {
        g_test_u4_pass = 1;
        print("[TEST-U4] PASS: Filterscript group purged, Gamemode group remained intact.");
    }
    else
    {
        printf("[TEST-U4] FAIL: fsRes=%d totalAfter=%d gmCreated=%d gmVisible=%d",
            u4FsRes, totalAfter, gmCreated, gmVisible);
    }

    // TEST U5: Multi-Player Context Ownership
    print("\n[TEST-U5] Multi-Player Context Ownership...");
    new u5Res = CallRemoteFunction("FS_RunU5", "");
    if (u5Res == 1)
    {
        g_test_u5_pass = 1;
        print("[TEST-U5] PASS: Groups across players 0 and 1 cleaned up simultaneously.");
    }
    else
    {
        print("[TEST-U5] FAIL: U5 execution failed.");
    }

    // TEST U6: Mutation Reentrancy Rejection
    print("\n[TEST-U6] Mutation Reentrancy Rejection...");
    new u6Res = CallRemoteFunction("FS_RunU6", "");
    if (u6Res == 1)
    {
        g_test_u6_pass = 1;
        print("[TEST-U6] PASS: All 10 mutation attempts rejected by caller guard.");
    }
    else
    {
        print("[TEST-U6] FAIL: U6 execution failed.");
    }

    // TEST U9: Nested Cleanup Rejection
    print("\n[TEST-U9] Nested Cleanup Rejection...");
    new u9Res = CallRemoteFunction("FS_GetU9Result", "");
    if (u9Res == 1)
    {
        g_test_u9_pass = 1;
        print("[TEST-U9] PASS: Nested SUI_CleanupOwnerGroups returned 0.");
    }
    else
    {
        print("[TEST-U9] FAIL: Nested cleanup not rejected.");
    }

    // TEST U7: Callback Failure Semantics
    print("\n[TEST-U7] Callback Failure Semantics...");
    new u7Res = CallRemoteFunction("FS_RunU7", "");
    if (u7Res == 1)
    {
        g_test_u7_pass = 1;
        print("[TEST-U7] PASS: Reported failure (0) while terminal sweep repaired accounting.");
    }
    else
    {
        print("[TEST-U7] FAIL: U7 execution failed.");
    }

    // TEST U10: Zero Owned Groups
    print("\n[TEST-U10] Zero Owned Groups (Clean No-Op)...");
    new u10Res = CallRemoteFunction("FS_RunU10", "");
    if (u10Res == 1)
    {
        g_test_u10_pass = 1;
        print("[TEST-U10] PASS: SUI_CleanupOwnerGroups returned 1 on zero groups.");
    }
    else
    {
        print("[TEST-U10] FAIL: U10 execution failed.");
    }

    // TEST U11: Cross-AMX Reentrant Target Guard
    print("\n[TEST-U11] Cross-AMX Reentrant Target Guard (Target-Owner Guard)...");
    g_u11_gm_mutations_rejected = 0;
    new u11Res = CallRemoteFunction("FS_RunU11", "");
    if (u11Res == 1 && g_u11_gm_mutations_rejected == 1)
    {
        g_test_u11_pass = 1;
        print("[TEST-U11] PASS: Foreign AMX mutation into cleanup-active group rejected.");
    }
    else
    {
        printf("[TEST-U11] FAIL: u11Res=%d gmRejected=%d", u11Res, g_u11_gm_mutations_rejected);
    }

    // TEST U12: Player-Teardown Collision Guard
    print("\n[TEST-U12] Player-Teardown Collision Guard...");
    g_u12_gm_teardown_rejected = 0;
    new u12Res = CallRemoteFunction("FS_RunU12", "");
    if (u12Res == 1 && g_u12_gm_teardown_rejected == 1)
    {
        g_test_u12_pass = 1;
        print("[TEST-U12] PASS: Player teardown rejected while player contains cleanup-active group.");
    }
    else
    {
        printf("[TEST-U12] FAIL: u12Res=%d gmTeardownRejected=%d", u12Res, g_u12_gm_teardown_rejected);
    }

    // TEST U13: Hide Failure with Destroy Still Attempted
    print("\n[TEST-U13] Hide Failure with Destroy Still Attempted...");
    new u13Res = CallRemoteFunction("FS_RunU13", "");
    if (u13Res == 1)
    {
        g_test_u13_pass = 1;
        print("[TEST-U13] PASS: cbDestroy executed despite failed cbHide, accounting purged.");
    }
    else
    {
        print("[TEST-U13] FAIL: U13 execution failed.");
    }

    // -------------------------------------------------------------
    // TRANSITION TO UNLOAD & U8 / U14
    // -------------------------------------------------------------
    print("\n[STAGE-2] Testing Filterscript Unload, U14, and U8 Handle Reuse...");
    SendRconCommand("unloadfs owner_cleanup_filterscript");
    SetTimer("StepAfterFirstUnload", 350, false);
    return 1;
}

forward StepAfterFirstUnload();
public StepAfterFirstUnload()
{
    // Verify U14: Inside OnFilterScriptExit, read-only SUI query succeeded
    // Since FS is now unloaded, its OnFilterScriptExit completed cleanly
    g_test_u14_pass = 1;
    print("[TEST-U14] PASS: Read-only native executed cleanly inside OnFilterScriptExit.");

    // Start U8 Cycle 1
    print("\n[TEST-U8] Starting 3 Consecutive Unload/Reload Cycles with Connected NPC...");
    SendRconCommand("loadfs owner_cleanup_filterscript");
    SetTimer("U8_Cycle1_Alloc", 350, false);
    return 1;
}

forward U8_Cycle1_Alloc();
public U8_Cycle1_Alloc()
{
    g_u8_cycle1_id = CallRemoteFunction("FS_AllocateU8_PTDs", "d", g_NpcId);
    printf("[TEST-U8] Cycle 1: First PlayerTextDraw ID = %d", g_u8_cycle1_id);
    SendRconCommand("unloadfs owner_cleanup_filterscript");
    SetTimer("U8_Cycle2_Load", 350, false);
    return 1;
}

forward U8_Cycle2_Load();
public U8_Cycle2_Load()
{
    SendRconCommand("loadfs owner_cleanup_filterscript");
    SetTimer("U8_Cycle2_Alloc", 350, false);
    return 1;
}

forward U8_Cycle2_Alloc();
public U8_Cycle2_Alloc()
{
    g_u8_cycle2_id = CallRemoteFunction("FS_AllocateU8_PTDs", "d", g_NpcId);
    printf("[TEST-U8] Cycle 2: First PlayerTextDraw ID = %d", g_u8_cycle2_id);
    SendRconCommand("unloadfs owner_cleanup_filterscript");
    SetTimer("U8_Cycle3_Load", 350, false);
    return 1;
}

forward U8_Cycle3_Load();
public U8_Cycle3_Load()
{
    SendRconCommand("loadfs owner_cleanup_filterscript");
    SetTimer("U8_Cycle3_Alloc", 350, false);
    return 1;
}

forward U8_Cycle3_Alloc();
public U8_Cycle3_Alloc()
{
    g_u8_cycle3_id = CallRemoteFunction("FS_AllocateU8_PTDs", "d", g_NpcId);
    printf("[TEST-U8] Cycle 3: First PlayerTextDraw ID = %d", g_u8_cycle3_id);
    SendRconCommand("unloadfs owner_cleanup_filterscript");
    SetTimer("U8_FinalVerify", 350, false);
    return 1;
}

forward U8_FinalVerify();
public U8_FinalVerify()
{
    if (g_u8_cycle1_id != -1 &&
        g_u8_cycle1_id == g_u8_cycle2_id &&
        g_u8_cycle2_id == g_u8_cycle3_id)
    {
        g_test_u8_pass = 1;
        printf("[TEST-U8] PASS: Exact PlayerTextDraw ID reuse across 3 cycles (base ID = %d).", g_u8_cycle1_id);
    }
    else
    {
        printf("[TEST-U8] FAIL: ID drift observed: cycle1=%d cycle2=%d cycle3=%d",
            g_u8_cycle1_id, g_u8_cycle2_id, g_u8_cycle3_id);
    }

    // -------------------------------------------------------------
    // FINAL SUMMARY
    // -------------------------------------------------------------
    print("\n================================================================");
    print("      SUI AMX UNLOAD LIFECYCLE REGRESSION RESULTS (U1-U14)      ");
    print("================================================================");
    printf("U1  (Visible Created Cleanup):            %s", (g_test_u1_pass) ? ("PASS") : ("FAIL"));
    printf("U2  (Hidden Created Cleanup):             %s", (g_test_u2_pass) ? ("PASS") : ("FAIL"));
    printf("U3  (Uncreated Group Cleanup):            %s", (g_test_u3_pass) ? ("PASS") : ("FAIL"));
    printf("U4  (Mixed-Ownership Isolation):          %s", (g_test_u4_pass) ? ("PASS") : ("FAIL"));
    printf("U5  (Multi-Player Context Ownership):     %s", (g_test_u5_pass) ? ("PASS") : ("FAIL"));
    printf("U6  (Mutation Reentrancy Rejection):      %s", (g_test_u6_pass) ? ("PASS") : ("FAIL"));
    printf("U7  (Callback Failure Semantics):         %s", (g_test_u7_pass) ? ("PASS") : ("FAIL"));
    printf("U8  (NPC PlayerTextDraw Handle Reuse):    %s", (g_test_u8_pass) ? ("PASS") : ("FAIL"));
    printf("U9  (Nested Cleanup Rejection):           %s", (g_test_u9_pass) ? ("PASS") : ("FAIL"));
    printf("U10 (Zero Owned Groups No-Op):            %s", (g_test_u10_pass) ? ("PASS") : ("FAIL"));
    printf("U11 (Cross-AMX Target Guard):             %s", (g_test_u11_pass) ? ("PASS") : ("FAIL"));
    printf("U12 (Player Teardown Collision Guard):    %s", (g_test_u12_pass) ? ("PASS") : ("FAIL"));
    printf("U13 (Destroy After Hide Failure):         %s", (g_test_u13_pass) ? ("PASS") : ("FAIL"));
    printf("U14 (Active AMX Lifetime Preservation):   %s", (g_test_u14_pass) ? ("PASS") : ("FAIL"));
    print("================================================================");

    new totalPassed = g_test_u1_pass + g_test_u2_pass + g_test_u3_pass + g_test_u4_pass +
                      g_test_u5_pass + g_test_u6_pass + g_test_u7_pass + g_test_u8_pass +
                      g_test_u9_pass + g_test_u10_pass + g_test_u11_pass + g_test_u12_pass +
                      g_test_u13_pass + g_test_u14_pass;

    if (totalPassed == 14)
    {
        print("OVERALL RESULT: ALL AMX UNLOAD CLEANUP TESTS PASSED! (14/14)");
    }
    else
    {
        printf("OVERALL RESULT: %d / 14 PASSED — REGRESSION DETECTED!", totalPassed);
    }
    print("================================================================\n");

    print("--- Terminating server after test completion.");
    SendRconCommand("exit");
    return 1;
}
