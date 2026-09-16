#include <a_samp>
#include <sui>

new g_NpcId = -1;

new g_test_f1_pass = 0;
new g_test_f2_pass = 0;
new g_test_f3_pass = 0;
new g_test_f4_pass = 0;
new g_test_f5_pass = 0;
new g_test_f6_pass = 0;
new g_test_f7_pass = 0;
new g_test_f8_pass = 0;
new g_test_f9_pass = 0;
new g_test_f10_pass = 0;
new g_test_f11_pass = 0;
new g_test_f12_pass = 0;

// F1 state
new g_F1_CreateFired = 0;
new g_F1_DestroyFired = 0;
new g_F1_DestroyShouldFail = 1;

// F3 state
new g_F3_CreateFired = 0;
new g_F3_DestroyFired = 0;

// F4 / F5 / F6 state
new g_F4_CreateFired = 0;
new g_F4_DestroyFired = 0;
new g_F4_DestroyShouldFail = 1;
new g_F4_CreateShouldFail = 1;

// F8 state
new g_F8_CreateFired = 0;
new g_F8_DestroyFired = 0;
new g_F8_DestroyShouldFail = 1;

// F9 state
new g_F9_CreateFired = 0;
new g_F9_DestroyFired = 0;
new g_F9_DestroyShouldFail = 1;

// F10 state
new g_F10_CreateFired = 0;
new g_F10_DestroyFired = 0;
new g_F10_CreateShouldFail = 1;

// F11 GM state
new g_F11_GmCreateFired = 0;
new g_F11_GmDestroyFired = 0;

// F12 real PlayerTextDraw handle reuse state
new PlayerText:g_F12_Handle = PlayerText:INVALID_TEXT_DRAW;
new g_F12_Cycle1_Id = -1;
new g_F12_Cycle2_Id = -1;
new g_F12_Cycle3_Id = -1;
new g_F12_CreateCount = 0;
new g_F12_DestroyCount = 0;

main()
{
    print("================================================================");
    print("   SUI-018 CALLBACK ERROR RECOVERY REGRESSION TEST SUITE        ");
    print("================================================================");
}

public OnGameModeInit()
{
    SUI_SetDebug(true);
    print("[GM] Connecting TestNPC with npcidle for F12 handle testing...");
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
        SetTimer("RunAllRecoveryTests", 500, false);
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

// ------------------------------------------------------------------
// F1 Callbacks
// ------------------------------------------------------------------
forward OnF1_Create(playerid);
public OnF1_Create(playerid)
{
    g_F1_CreateFired++;
    new z = 0;
    new v = 10 / z;
    #pragma unused v
    return 1;
}

forward OnF1_Show(playerid);
public OnF1_Show(playerid) { return 1; }

forward OnF1_Hide(playerid);
public OnF1_Hide(playerid) { return 1; }

forward OnF1_Destroy(playerid);
public OnF1_Destroy(playerid)
{
    g_F1_DestroyFired++;
    if (g_F1_DestroyShouldFail)
    {
        new z = 0;
        new v = 10 / z;
        #pragma unused v
    }
    return 1;
}

// ------------------------------------------------------------------
// F3 Callbacks
// ------------------------------------------------------------------
forward OnF3_Create(playerid);
public OnF3_Create(playerid)
{
    g_F3_CreateFired++;
    new z = 0;
    new v = 10 / z;
    #pragma unused v
    return 1;
}

forward OnF3_Show(playerid);
public OnF3_Show(playerid) { return 1; }

forward OnF3_Hide(playerid);
public OnF3_Hide(playerid) { return 1; }

forward OnF3_Destroy(playerid);
public OnF3_Destroy(playerid)
{
    g_F3_DestroyFired++;
    return 1; // Cooperative compensating destroy succeeds cleanly
}

// ------------------------------------------------------------------
// F4 / F5 / F6 Callbacks
// ------------------------------------------------------------------
forward OnF4_Create(playerid);
public OnF4_Create(playerid)
{
    g_F4_CreateFired++;
    if (g_F4_CreateShouldFail)
    {
        new z = 0;
        new v = 10 / z;
        #pragma unused v
    }
    return 1;
}

forward OnF4_Show(playerid);
public OnF4_Show(playerid) { return 1; }

forward OnF4_Hide(playerid);
public OnF4_Hide(playerid) { return 1; }

forward OnF4_Destroy(playerid);
public OnF4_Destroy(playerid)
{
    g_F4_DestroyFired++;
    if (g_F4_DestroyShouldFail)
    {
        new z = 0;
        new v = 10 / z;
        #pragma unused v
    }
    return 1;
}

// ------------------------------------------------------------------
// F8 Callbacks
// ------------------------------------------------------------------
forward OnF8_Create(playerid);
public OnF8_Create(playerid)
{
    g_F8_CreateFired++;
    new z = 0;
    new v = 10 / z;
    #pragma unused v
    return 1;
}

forward OnF8_Show(playerid);
public OnF8_Show(playerid) { return 1; }

forward OnF8_Hide(playerid);
public OnF8_Hide(playerid) { return 1; }

forward OnF8_Destroy(playerid);
public OnF8_Destroy(playerid)
{
    g_F8_DestroyFired++;
    if (g_F8_DestroyShouldFail)
    {
        new z = 0;
        new v = 10 / z;
        #pragma unused v
    }
    return 1;
}

// ------------------------------------------------------------------
// F9 Callbacks
// ------------------------------------------------------------------
forward OnF9_Create(playerid);
public OnF9_Create(playerid)
{
    g_F9_CreateFired++;
    new z = 0;
    new v = 10 / z;
    #pragma unused v
    return 1;
}

forward OnF9_Show(playerid);
public OnF9_Show(playerid) { return 1; }

forward OnF9_Hide(playerid);
public OnF9_Hide(playerid) { return 1; }

forward OnF9_Destroy(playerid);
public OnF9_Destroy(playerid)
{
    g_F9_DestroyFired++;
    if (g_F9_DestroyShouldFail)
    {
        new z = 0;
        new v = 10 / z;
        #pragma unused v
    }
    return 1;
}

// ------------------------------------------------------------------
// F10 Callbacks
// ------------------------------------------------------------------
forward OnF10_Create(playerid);
public OnF10_Create(playerid)
{
    g_F10_CreateFired++;
    if (g_F10_CreateShouldFail)
    {
        new z = 0;
        new v = 10 / z;
        #pragma unused v
    }
    return 1;
}

forward OnF10_Show(playerid);
public OnF10_Show(playerid) { return 1; }

forward OnF10_Hide(playerid);
public OnF10_Hide(playerid) { return 1; }

forward OnF10_Destroy(playerid);
public OnF10_Destroy(playerid)
{
    g_F10_DestroyFired++;
    return 1;
}

// ------------------------------------------------------------------
// F11 GM Callbacks
// ------------------------------------------------------------------
forward OnGmF11_Create(playerid);
public OnGmF11_Create(playerid)
{
    g_F11_GmCreateFired++;
    return 1;
}

forward OnGmF11_Show(playerid);
public OnGmF11_Show(playerid) { return 1; }

forward OnGmF11_Hide(playerid);
public OnGmF11_Hide(playerid) { return 1; }

forward OnGmF11_Destroy(playerid);
public OnGmF11_Destroy(playerid)
{
    g_F11_GmDestroyFired++;
    return 1;
}

// ------------------------------------------------------------------
// F12 Real PlayerTextDraw Handle Reuse Callbacks
// ------------------------------------------------------------------
forward OnF12_Create(playerid);
public OnF12_Create(playerid)
{
    g_F12_CreateCount++;
    // Allocate real host PlayerTextDraw resource
    g_F12_Handle = CreatePlayerTextDraw(playerid, 320.0, 240.0, "F12_Text");
    new rawId = _:g_F12_Handle;
    printf("[F12] OnF12_Create: cycle=%d allocated PlayerTextDraw id=%d", g_F12_CreateCount, rawId);

    if (g_F12_CreateCount == 1) g_F12_Cycle1_Id = rawId;
    else if (g_F12_CreateCount == 2) g_F12_Cycle2_Id = rawId;
    else if (g_F12_CreateCount == 3) g_F12_Cycle3_Id = rawId;

    // Trigger runtime AMX error after handle allocation
    new z = 0;
    new v = 10 / z;
    #pragma unused v
    return 1;
}

forward OnF12_Show(playerid);
public OnF12_Show(playerid) { return 1; }

forward OnF12_Hide(playerid);
public OnF12_Hide(playerid) { return 1; }

forward OnF12_Destroy(playerid);
public OnF12_Destroy(playerid)
{
    g_F12_DestroyCount++;
    printf("[F12] OnF12_Destroy: cycle=%d releasing PlayerTextDraw id=%d", g_F12_DestroyCount, _:g_F12_Handle);
    if (g_F12_Handle != PlayerText:INVALID_TEXT_DRAW)
    {
        PlayerTextDrawDestroy(playerid, g_F12_Handle);
        g_F12_Handle = PlayerText:INVALID_TEXT_DRAW;
    }
    return 1;
}

// ------------------------------------------------------------------
// Main Test Runner
// ------------------------------------------------------------------
forward RunAllRecoveryTests();
public RunAllRecoveryTests()
{
    new pid = g_NpcId;
    printf("[GM] Starting Callback Error Recovery Tests on playerid=%d...", pid);

    // ==============================================================
    // F1: Failed create produces recovery quarantine
    // ==============================================================
    SUI_CreatePlayerFactoryGroup(pid, "f1_grp", "OnF1_Create", "OnF1_Destroy", "OnF1_Show", "OnF1_Hide");
    SUI_SetGroupSize(pid, "f1_grp", 5);

    new f1_res1 = SUI_ShowGroup(pid, "f1_grp");
    new f1_created1 = SUI_IsGroupCreated(pid, "f1_grp");
    new f1_visible1 = SUI_IsGroupVisible(pid, "f1_grp");

    // Second show attempt must be blocked by recovery quarantine without re-running create
    new f1_res2 = SUI_ShowGroup(pid, "f1_grp");

    if (f1_res1 == 0 && f1_created1 == 0 && f1_visible1 == 0 && f1_res2 == 0 && g_F1_CreateFired == 1)
    {
        g_test_f1_pass = 1;
        print("[TEST-F1] PASS: Failed create quarantined group; repeat show rejected without re-executing create.");
    }
    else
    {
        printf("[TEST-F1] FAIL: res1=%d created1=%d visible1=%d res2=%d createFired=%d",
            f1_res1, f1_created1, f1_visible1, f1_res2, g_F1_CreateFired);
    }

    // ==============================================================
    // F2: Failed create does not debit capacity
    // ==============================================================
    new activeTdAfterF1 = SUI_GetActiveTextDrawCount(pid);
    if (activeTdAfterF1 == 0)
    {
        g_test_f2_pass = 1;
        print("[TEST-F2] PASS: Failed create did not debit capacity (activeTextDrawCount remains 0).");
    }
    else
    {
        printf("[TEST-F2] FAIL: activeTextDrawCount=%d (expected 0)", activeTdAfterF1);
    }

    // Clean up F1 group by allowing destroy compensation
    g_F1_DestroyShouldFail = 0;
    SUI_DestroyGroup(pid, "f1_grp");

    // ==============================================================
    // F3: Immediate compensating destroy success
    // ==============================================================
    SUI_CreatePlayerFactoryGroup(pid, "f3_grp", "OnF3_Create", "OnF3_Destroy", "OnF3_Show", "OnF3_Hide");
    SUI_SetGroupSize(pid, "f3_grp", 4);

    new f3_res = SUI_ShowGroup(pid, "f3_grp");
    new f3_created = SUI_IsGroupCreated(pid, "f3_grp");
    new f3_activeTd = SUI_GetActiveTextDrawCount(pid);

    if (f3_res == 0 && g_F3_CreateFired == 1 && g_F3_DestroyFired == 1 && f3_created == 0 && f3_activeTd == 0)
    {
        g_test_f3_pass = 1;
        print("[TEST-F3] PASS: Immediate compensating destroy executed successfully upon create callback failure.");
    }
    else
    {
        printf("[TEST-F3] FAIL: res=%d createFired=%d destroyFired=%d created=%d activeTd=%d",
            f3_res, g_F3_CreateFired, g_F3_DestroyFired, f3_created, f3_activeTd);
    }

    // ==============================================================
    // F4: Compensating destroy failure retains quarantine
    // ==============================================================
    SUI_CreatePlayerFactoryGroup(pid, "f4_grp", "OnF4_Create", "OnF4_Destroy", "OnF4_Show", "OnF4_Hide");
    SUI_SetGroupSize(pid, "f4_grp", 3);

    g_F4_DestroyShouldFail = 1;
    new f4_res = SUI_ShowGroup(pid, "f4_grp");
    new f4_created = SUI_IsGroupCreated(pid, "f4_grp");

    if (f4_res == 0 && g_F4_CreateFired == 1 && g_F4_DestroyFired == 1 && f4_created == 0)
    {
        g_test_f4_pass = 1;
        print("[TEST-F4] PASS: Failed compensating destroy safely retains quarantine state.");
    }
    else
    {
        printf("[TEST-F4] FAIL: res=%d createFired=%d destroyFired=%d created=%d",
            f4_res, g_F4_CreateFired, g_F4_DestroyFired, f4_created);
    }

    // ==============================================================
    // F5: Quarantined group cannot run create again
    // ==============================================================
    new f5_try1 = SUI_ShowGroup(pid, "f4_grp");
    new f5_try2 = SUI_ShowGroup(pid, "f4_grp");

    if (f5_try1 == 0 && f5_try2 == 0 && g_F4_CreateFired == 1)
    {
        g_test_f5_pass = 1;
        print("[TEST-F5] PASS: Quarantined group blocked subsequent ShowGroup without re-running create callback.");
    }
    else
    {
        printf("[TEST-F5] FAIL: try1=%d try2=%d createFired=%d", f5_try1, f5_try2, g_F4_CreateFired);
    }

    // ==============================================================
    // F6: Manual DestroyGroup retries compensation and clears quarantine
    // ==============================================================
    g_F4_DestroyShouldFail = 0; // Allow compensating destroy to succeed now
    new f6_destroyRes = SUI_DestroyGroup(pid, "f4_grp");

    // Once quarantine is cleared, group should be eligible to attempt ShowGroup again
    g_F4_CreateShouldFail = 0; // Allow subsequent create to succeed
    new f6_retryShow = SUI_ShowGroup(pid, "f4_grp");
    new bool:f6_created = SUI_IsGroupCreated(pid, "f4_grp");

    if (f6_destroyRes == 1 && g_F4_DestroyFired == 2 && f6_retryShow == 1 && f6_created && g_F4_CreateFired == 2)
    {
        g_test_f6_pass = 1;
        print("[TEST-F6] PASS: Manual DestroyGroup retried compensation and cleared quarantine.");
    }
    else
    {
        printf("[TEST-F6] FAIL: destroyRes=%d destroyFired=%d createFired=%d retryShow=%d created=%d",
            f6_destroyRes, g_F4_DestroyFired, g_F4_CreateFired, f6_retryShow, f6_created ? 1 : 0);
    }
    // Clean up f4_grp
    SUI_DestroyGroup(pid, "f4_grp");

    // ==============================================================
    // F7: Filterscript owner cleanup retries compensation
    // ==============================================================
    new f7_ok = CallRemoteFunction("FS_RunF7", "i", pid);
    if (f7_ok == 1)
    {
        g_test_f7_pass = 1;
        print("[TEST-F7] PASS: SUI_CleanupOwnerGroups retried compensating destroy for quarantined group.");
    }
    else
    {
        printf("[TEST-F7] FAIL: FS_RunF7 returned %d", f7_ok);
    }

    // ==============================================================
    // F8: CleanupPlayer terminal compensation
    // ==============================================================
    // Use player 1 for isolated CleanupPlayer test
    new testPid8 = 1;
    SUI_CreatePlayerFactoryGroup(testPid8, "f8_grp", "OnF8_Create", "OnF8_Destroy", "OnF8_Show", "OnF8_Hide");
    SUI_SetGroupSize(testPid8, "f8_grp", 5);

    g_F8_DestroyShouldFail = 1;
    SUI_ShowGroup(testPid8, "f8_grp"); // enters quarantine, destroyFired = 1

    g_F8_DestroyShouldFail = 0; // allow terminal cleanup compensation to succeed
    new f8_cleanupRes = SUI_CleanupPlayer(testPid8);
    new f8_activeTd = SUI_GetActiveTextDrawCount(testPid8);

    if (f8_cleanupRes == 1 && g_F8_DestroyFired == 2 && f8_activeTd == 0)
    {
        g_test_f8_pass = 1;
        print("[TEST-F8] PASS: CleanupPlayer performed terminal compensating destroy before erasing context.");
    }
    else
    {
        printf("[TEST-F8] FAIL: cleanupRes=%d destroyFired=%d activeTd=%d",
            f8_cleanupRes, g_F8_DestroyFired, f8_activeTd);
    }

    // ==============================================================
    // F9: ResetPlayer preserves failed recovery group
    // ==============================================================
    // Use player 2 for isolated ResetPlayer test
    new testPid9 = 2;
    SUI_CreatePlayerFactoryGroup(testPid9, "f9_grp", "OnF9_Create", "OnF9_Destroy", "OnF9_Show", "OnF9_Hide");
    SUI_SetGroupSize(testPid9, "f9_grp", 5);

    g_F9_DestroyShouldFail = 1;
    SUI_ShowGroup(testPid9, "f9_grp"); // enters quarantine, destroyFired = 1

    // ResetPlayer should attempt compensation, fail, preserve group, return 0
    new f9_resetRes = SUI_ResetPlayer(testPid9);
    new f9_created = SUI_IsGroupCreated(testPid9, "f9_grp");
    new f9_showRejected = SUI_ShowGroup(testPid9, "f9_grp");

    if (f9_resetRes == 0 && g_F9_DestroyFired == 2 && f9_created == 0 && f9_showRejected == 0)
    {
        g_test_f9_pass = 1;
        print("[TEST-F9] PASS: ResetPlayer preserved failed recovery group in quarantined state.");
    }
    else
    {
        printf("[TEST-F9] FAIL: resetRes=%d destroyFired=%d created=%d showRejected=%d",
            f9_resetRes, g_F9_DestroyFired, f9_created, f9_showRejected);
    }
    // Clean up testPid9
    g_F9_DestroyShouldFail = 0;
    SUI_DestroyGroup(testPid9, "f9_grp");
    SUI_CleanupPlayer(testPid9);

    // ==============================================================
    // F10: Instance replacement / ABA protection during compensation
    // ==============================================================
    g_F10_CreateShouldFail = 1;
    SUI_CreatePlayerFactoryGroup(pid, "f10_grp", "OnF10_Create", "OnF10_Destroy", "OnF10_Show", "OnF10_Hide");
    SUI_SetGroupSize(pid, "f10_grp", 4);
    SUI_ShowGroup(pid, "f10_grp"); // fails create, compensates, uncreated

    // Re-register group with same name (generates new instance ID)
    g_F10_CreateShouldFail = 0; // next create will succeed
    SUI_CreatePlayerFactoryGroup(pid, "f10_grp", "OnF10_Create", "OnF10_Destroy", "OnF10_Show", "OnF10_Hide");
    SUI_SetGroupSize(pid, "f10_grp", 4);
    new f10_showOk = SUI_ShowGroup(pid, "f10_grp");
    new f10_created = SUI_IsGroupCreated(pid, "f10_grp");
    new f10_destroyOk = SUI_DestroyGroup(pid, "f10_grp");

    if (f10_showOk == 1 && f10_created == 1 && f10_destroyOk == 1 && g_F10_CreateFired == 2 && g_F10_DestroyFired == 2)
    {
        g_test_f10_pass = 1;
        print("[TEST-F10] PASS: Re-registered group allocated fresh instance ID; new instance operated cleanly.");
    }
    else
    {
        printf("[TEST-F10] FAIL: showOk=%d created=%d destroyOk=%d createFired=%d destroyFired=%d",
            f10_showOk, f10_created, f10_destroyOk, g_F10_CreateFired, g_F10_DestroyFired);
    }

    // ==============================================================
    // F11: Cross-AMX isolation during recovery
    // ==============================================================
    new f11_setupOk = CallRemoteFunction("FS_SetupF11", "i", pid);

    // Gamemode operates healthy group concurrently
    SUI_CreatePlayerFactoryGroup(pid, "gm_f11_grp", "OnGmF11_Create", "OnGmF11_Destroy", "OnGmF11_Show", "OnGmF11_Hide");
    SUI_SetGroupSize(pid, "gm_f11_grp", 7);

    new f11_gmShow = SUI_ShowGroup(pid, "gm_f11_grp");
    new f11_gmCreated = SUI_IsGroupCreated(pid, "gm_f11_grp");
    new f11_gmActive = SUI_GetActiveTextDrawCount(pid);
    new f11_gmDestroy = SUI_DestroyGroup(pid, "gm_f11_grp");
    new f11_gmActiveAfter = SUI_GetActiveTextDrawCount(pid);

    new f11_fsCheckOk = CallRemoteFunction("FS_CheckF11", "i", pid);
    CallRemoteFunction("FS_Cleanup", "");

    if (f11_setupOk == 1 && f11_gmShow == 1 && f11_gmCreated == 1 && f11_gmActive == 7 &&
        f11_gmDestroy == 1 && f11_gmActiveAfter == 0 && f11_fsCheckOk == 1)
    {
        g_test_f11_pass = 1;
        print("[TEST-F11] PASS: Cross-AMX isolation preserved; Gamemode UI healthy while Filterscript group quarantined.");
    }
    else
    {
        printf("[TEST-F11] FAIL: setupOk=%d gmShow=%d gmCreated=%d gmActive=%d gmDestroy=%d activeAfter=%d fsCheckOk=%d",
            f11_setupOk, f11_gmShow, f11_gmCreated, f11_gmActive, f11_gmDestroy, f11_gmActiveAfter, f11_fsCheckOk);
    }

    // ==============================================================
    // F12: Real PlayerTextDraw handle reuse after recovered failure
    // ==============================================================
    SUI_CreatePlayerFactoryGroup(pid, "f12_grp", "OnF12_Create", "OnF12_Destroy", "OnF12_Show", "OnF12_Hide");
    SUI_SetGroupSize(pid, "f12_grp", 1);

    // Cycle 1
    SUI_ShowGroup(pid, "f12_grp");

    // Cycle 2
    SUI_ShowGroup(pid, "f12_grp");

    // Cycle 3
    SUI_ShowGroup(pid, "f12_grp");

    printf("[F12] Handle verification: cycle1=%d cycle2=%d cycle3=%d",
        g_F12_Cycle1_Id, g_F12_Cycle2_Id, g_F12_Cycle3_Id);

    if (g_F12_Cycle1_Id != -1 &&
        g_F12_Cycle1_Id == g_F12_Cycle2_Id &&
        g_F12_Cycle2_Id == g_F12_Cycle3_Id &&
        g_F12_CreateCount == 3 &&
        g_F12_DestroyCount == 3)
    {
        g_test_f12_pass = 1;
        print("[TEST-F12] PASS: Exact handle reuse observed across tested recovery cycles (zero slot creep).");
    }
    else
    {
        printf("[TEST-F12] FAIL: cycle1=%d cycle2=%d cycle3=%d createCount=%d destroyCount=%d",
            g_F12_Cycle1_Id, g_F12_Cycle2_Id, g_F12_Cycle3_Id, g_F12_CreateCount, g_F12_DestroyCount);
    }
    // Clean up f12
    SUI_DestroyGroup(pid, "f12_grp");

    // ==============================================================
    // Final Tally
    // ==============================================================
    new totalPassed = g_test_f1_pass + g_test_f2_pass + g_test_f3_pass + g_test_f4_pass +
                      g_test_f5_pass + g_test_f6_pass + g_test_f7_pass + g_test_f8_pass +
                      g_test_f9_pass + g_test_f10_pass + g_test_f11_pass + g_test_f12_pass;

    print("================================================================");
    printf("   SUI CALLBACK ERROR RECOVERY RESULTS: %d / 12 PASSED", totalPassed);
    print("================================================================");

    if (totalPassed == 12)
    {
        print("ALL CALLBACK ERROR RECOVERY TESTS PASSED");
    }
    else
    {
        print("SOME CALLBACK ERROR RECOVERY TESTS FAILED!");
    }

    SetTimer("TerminateServer", 500, false);
    return 1;
}

forward TerminateServer();
public TerminateServer()
{
    print("[GM] Shutting down test server.");
    SendRconCommand("exit");
    return 1;
}
