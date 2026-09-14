#include <a_samp>
#include "../../pawn/sui.inc"

// ============================================================================
// SUI-008: SHOW FAILURE LIFECYCLE AND TIMEOUT REGRESSION SUITE (F1-F10)
// ============================================================================

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

// Callbacks tracking
new g_f1_destroy_calls = 0;
new g_f2_destroy_calls = 0;
new g_f3_destroy_calls = 0;
new g_f4_destroy_calls = 0;
new g_f5_destroy_calls = 0;
new g_f6_destroy_calls = 0;
new g_f10_destroy_calls = 0;

main()
{
}

// Dummy callbacks
forward OnDummy_Create(playerid); public OnDummy_Create(playerid) { return 1; }
forward OnDummy_Destroy(playerid); public OnDummy_Destroy(playerid) { return 1; }
forward OnDummy_Show(playerid); public OnDummy_Show(playerid) { return 1; }
forward OnDummy_Hide(playerid); public OnDummy_Hide(playerid) { return 1; }

// F1 callbacks
forward OnF1_Destroy(playerid); public OnF1_Destroy(playerid) { g_f1_destroy_calls++; return 1; }

// F2 callbacks
forward OnF2_Destroy(playerid); public OnF2_Destroy(playerid) { g_f2_destroy_calls++; return 1; }

// F3 callbacks
forward OnF3_Destroy(playerid); public OnF3_Destroy(playerid) { g_f3_destroy_calls++; return 1; }

// F4 callbacks
forward OnF4_Destroy(playerid); public OnF4_Destroy(playerid) { g_f4_destroy_calls++; return 1; }

// F5 callbacks
forward OnF5_Destroy(playerid); public OnF5_Destroy(playerid) { g_f5_destroy_calls++; return 1; }

// F6 callbacks
forward OnF6_Destroy(playerid); public OnF6_Destroy(playerid) { g_f6_destroy_calls++; return 1; }

// F7 callbacks (missing create)

// F8 callbacks (return 0 in show)
forward OnF8_Show(playerid);
public OnF8_Show(playerid)
{
    // Explicit return 0 must be treated as successful execution
    return 0;
}

// F9 callbacks (ABA replacement during create)
forward OnF9_Create(playerid);
public OnF9_Create(playerid)
{
    // Re-entrant replacement during create callback
    SUI_ResetPlayer(playerid);
    SUI_CreatePlayerFactoryGroup(playerid, "f9_grp", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(playerid, "f9_grp", 4);
    return 1;
}

// F10 callbacks
forward OnF10_Destroy(playerid); public OnF10_Destroy(playerid) { g_f10_destroy_calls++; return 1; }

public OnGameModeInit()
{
    print("\n================================================================");
    print("      SUI PHASE 10: SHOW FAILURE LIFECYCLE REGRESSION SUITE     ");
    print("================================================================\n");

    SUI_SetDebug(true);

    // Run synchronous tests first: F7, F8, F9
    RunSyncTests();

    // Begin asynchronous timer chain for F1..F6, F10
    StartF1();
    return 1;
}

RunSyncTests()
{
    // -------------------------------------------------------------
    // F7: Create Failure Invariant (No Created-Resource Timer)
    // -------------------------------------------------------------
    print("[TEST-F7] Testing Create Failure Invariant...");
    SUI_ResetPlayer(0);
    SUI_SetMaxTextDraws(0, 50);
    SUI_SetEvictionThreshold(0, 50);

    SUI_CreatePlayerFactoryGroup(0, "f7_grp", "OnF7_NonExistentCreate", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "f7_grp", 10);
    SUI_SetIdleTimeout(0, "f7_grp", 50);

    new f7_show_res = SUI_ShowGroup(0, "f7_grp");
    new f7_cr = SUI_IsGroupCreated(0, "f7_grp");
    new f7_act = SUI_GetActiveTextDrawCount(0);

    if (f7_show_res == 0 && f7_cr == 0 && f7_act == 0)
    {
        g_test_f7_pass = 1;
        print("[TEST-F7] PASS: Create failure left group uncreated with zero active textdraws.");
    }
    else
    {
        printf("[TEST-F7] FAIL: show_res=%d cr=%d act=%d", f7_show_res, f7_cr, f7_act);
    }
    SUI_ResetPlayer(0);

    // -------------------------------------------------------------
    // F8: Return 0 Callback Success
    // -------------------------------------------------------------
    print("\n[TEST-F8] Testing Return 0 Callback Success...");
    SUI_ResetPlayer(0);
    SUI_SetMaxTextDraws(0, 50);
    SUI_SetEvictionThreshold(0, 50);

    SUI_CreatePlayerFactoryGroup(0, "f8_grp", "OnDummy_Create", "OnDummy_Destroy", "OnF8_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "f8_grp", 10);

    new f8_show_res = SUI_ShowGroup(0, "f8_grp");
    new f8_cr = SUI_IsGroupCreated(0, "f8_grp");
    new f8_vis = SUI_IsGroupVisible(0, "f8_grp");
    new f8_act = SUI_GetActiveTextDrawCount(0);

    if (f8_show_res == 1 && f8_cr == 1 && f8_vis == 1 && f8_act == 10)
    {
        g_test_f8_pass = 1;
        print("[TEST-F8] PASS: Callback returning 0 treated as success; group is created and visible.");
    }
    else
    {
        printf("[TEST-F8] FAIL: show_res=%d cr=%d vis=%d act=%d", f8_show_res, f8_cr, f8_vis, f8_act);
    }
    SUI_ResetPlayer(0);

    // -------------------------------------------------------------
    // F9: Generation ABA Safety
    // -------------------------------------------------------------
    print("\n[TEST-F9] Testing Generation ABA Safety During Callback...");
    SUI_ResetPlayer(0);
    SUI_SetMaxTextDraws(0, 50);
    SUI_SetEvictionThreshold(0, 50);

    SUI_CreatePlayerFactoryGroup(0, "f9_grp", "OnF9_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "f9_grp", 10);

    new f9_show_res = SUI_ShowGroup(0, "f9_grp");
    new f9_cr = SUI_IsGroupCreated(0, "f9_grp");
    new f9_act = SUI_GetActiveTextDrawCount(0);

    // Outer ShowGroup must abort (return 0); replacement f9_grp remains uncreated (size 4, act 0)
    if (f9_show_res == 0 && f9_cr == 0 && f9_act == 0)
    {
        g_test_f9_pass = 1;
        print("[TEST-F9] PASS: Generation replacement aborted outer ShowGroup; replacement remains intact.");
    }
    else
    {
        printf("[TEST-F9] FAIL: show_res=%d cr=%d act=%d", f9_show_res, f9_cr, f9_act);
    }
    SUI_ResetPlayer(0);
}

// ============================================================================
// F1: Fresh Create + Show Failure Does Not Immediately Expire
// ============================================================================
StartF1()
{
    print("\n[TEST-F1] Testing Fresh Create + Show Failure Does Not Prematurely Expire...");
    SUI_ResetPlayer(0);
    SUI_SetMaxTextDraws(0, 50);
    SUI_SetEvictionThreshold(0, 50);

    g_f1_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "f1_grp", "OnDummy_Create", "OnF1_Destroy", "OnF1_MissingShow", "OnDummy_Hide");
    SUI_SetGroupSize(0, "f1_grp", 10);
    SUI_SetIdleTimeout(0, "f1_grp", 5000); // 5 seconds timeout

    new res = SUI_ShowGroup(0, "f1_grp");
    new cr = SUI_IsGroupCreated(0, "f1_grp");
    new vis = SUI_IsGroupVisible(0, "f1_grp");
    new act = SUI_GetActiveTextDrawCount(0);

    if (res == 0 && cr == 1 && vis == 0 && act == 10 && g_f1_destroy_calls == 0)
    {
        // Wait 150ms: ProcessTick will run, group MUST NOT be destroyed
        SetTimer("VerifyF1", 150, false);
    }
    else
    {
        printf("[TEST-F1] FAIL on immediate state: res=%d cr=%d vis=%d act=%d dest=%d",
            res, cr, vis, act, g_f1_destroy_calls);
        StartF2();
    }
}

forward VerifyF1();
public VerifyF1()
{
    new cr = SUI_IsGroupCreated(0, "f1_grp");
    new vis = SUI_IsGroupVisible(0, "f1_grp");
    new act = SUI_GetActiveTextDrawCount(0);

    if (cr == 1 && vis == 0 && act == 10 && g_f1_destroy_calls == 0)
    {
        g_test_f1_pass = 1;
        print("[TEST-F1] PASS: Group with 5s timeout survived 150ms without premature destruction.");
    }
    else
    {
        printf("[TEST-F1] FAIL: cr=%d vis=%d act=%d dest=%d", cr, vis, act, g_f1_destroy_calls);
    }
    SUI_ResetPlayer(0);
    StartF2();
}

// ============================================================================
// F2: Failed Show Expires After Real Idle Interval
// ============================================================================
StartF2()
{
    print("\n[TEST-F2] Testing Failed Show Expires After Real Idle Interval (50ms)...");
    SUI_ResetPlayer(0);
    SUI_SetMaxTextDraws(0, 50);
    SUI_SetEvictionThreshold(0, 50);

    g_f2_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "f2_grp", "OnDummy_Create", "OnF2_Destroy", "OnF2_MissingShow", "OnDummy_Hide");
    SUI_SetGroupSize(0, "f2_grp", 10);
    SUI_SetIdleTimeout(0, "f2_grp", 50); // 50ms timeout

    new res = SUI_ShowGroup(0, "f2_grp");
    new cr = SUI_IsGroupCreated(0, "f2_grp");

    if (res == 0 && cr == 1)
    {
        // Wait 200ms (> 50ms): ProcessTick must destroy group and free capacity
        SetTimer("VerifyF2", 200, false);
    }
    else
    {
        printf("[TEST-F2] FAIL on immediate state: res=%d cr=%d", res, cr);
        StartF3();
    }
}

forward VerifyF2();
public VerifyF2()
{
    new cr = SUI_IsGroupCreated(0, "f2_grp");
    new act = SUI_GetActiveTextDrawCount(0);

    if (cr == 0 && act == 0 && g_f2_destroy_calls == 1)
    {
        g_test_f2_pass = 1;
        print("[TEST-F2] PASS: Group expired after real idle interval and freed capacity exactly once.");
    }
    else
    {
        printf("[TEST-F2] FAIL: cr=%d act=%d dest=%d", cr, act, g_f2_destroy_calls);
    }
    SUI_ResetPlayer(0);
    StartF3();
}

// ============================================================================
// F3: Continuous Hidden Preservation (Failed Show Preserves Existing Timer)
// ============================================================================
StartF3()
{
    print("\n[TEST-F3] Testing Continuous Hidden Preservation on Failed Show...");
    SUI_ResetPlayer(0);
    SUI_SetMaxTextDraws(0, 50);
    SUI_SetEvictionThreshold(0, 50);

    g_f3_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "f3_grp", "OnDummy_Create", "OnF3_Destroy", "OnF3_ToggleShow", "OnDummy_Hide");
    SUI_SetGroupSize(0, "f3_grp", 10);
    SUI_SetIdleTimeout(0, "f3_grp", 250); // 250ms timeout

    // Show then hide: hiddenSinceTick = T0
    SUI_ShowGroup(0, "f3_grp");
    SUI_HideGroup(0, "f3_grp");

    // Wait 100ms, then attempt ShowGroup with failing show callback
    SetTimer("F3_FailedShowAttempt", 100, false);
}

new g_f3_fail_show = 0;
forward OnF3_ToggleShow(playerid);
public OnF3_ToggleShow(playerid)
{
    if (g_f3_fail_show) return 0; // return 0 or runtime error? Wait, SUI-006: missing callback is failure
    return 1;
}

forward F3_FailedShowAttempt();
public F3_FailedShowAttempt()
{
    // Re-register or make show fail by calling with missing callback
    // Or simpler: change factory group to non-existent show callback
    SUI_CreatePlayerFactoryGroup(0, "f3_grp", "OnDummy_Create", "OnF3_Destroy", "OnF3_MissingShow", "OnDummy_Hide");
    new res = SUI_ShowGroup(0, "f3_grp"); // fails!
    new cr = SUI_IsGroupCreated(0, "f3_grp");

    printf("[TEST-F3] Attempted show at +100ms: res=%d cr=%d. Waiting another 180ms (total 280ms > 250ms)...", res, cr);

    // Total elapsed from initial hide = 100 + 180 = 280ms > 250ms.
    // Elapsed from failed show attempt = only 180ms < 250ms.
    // If timer was preserved, group expires! If timer was erroneously reset, group is still created.
    SetTimer("VerifyF3", 180, false);
}

forward VerifyF3();
public VerifyF3()
{
    new cr = SUI_IsGroupCreated(0, "f3_grp");
    new act = SUI_GetActiveTextDrawCount(0);

    if (cr == 0 && act == 0 && g_f3_destroy_calls == 1)
    {
        g_test_f3_pass = 1;
        print("[TEST-F3] PASS: Continuous hidden interval preserved; expired based on original hide time.");
    }
    else
    {
        printf("[TEST-F3] FAIL: cr=%d act=%d dest=%d (timer erroneously reset by failed show)",
            cr, act, g_f3_destroy_calls);
    }
    SUI_ResetPlayer(0);
    StartF4();
}

// ============================================================================
// F4: Show Success Inactivates Hidden Interval
// ============================================================================
StartF4()
{
    print("\n[TEST-F4] Testing Show Success Inactivates Hidden Interval...");
    SUI_ResetPlayer(0);
    SUI_SetMaxTextDraws(0, 50);
    SUI_SetEvictionThreshold(0, 50);

    g_f4_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "f4_grp", "OnDummy_Create", "OnF4_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "f4_grp", 10);
    SUI_SetIdleTimeout(0, "f4_grp", 50); // 50ms timeout

    // Show group: isVisible becomes true, hiddenSinceTick becomes 0
    SUI_ShowGroup(0, "f4_grp");

    // Wait 150ms (> 50ms). Visible group must NOT be destroyed!
    SetTimer("VerifyF4", 150, false);
}

forward VerifyF4();
public VerifyF4()
{
    new cr = SUI_IsGroupCreated(0, "f4_grp");
    new vis = SUI_IsGroupVisible(0, "f4_grp");

    if (cr == 1 && vis == 1 && g_f4_destroy_calls == 0)
    {
        g_test_f4_pass = 1;
        print("[TEST-F4] PASS: Visible group remained active without idle expiration.");
    }
    else
    {
        printf("[TEST-F4] FAIL: cr=%d vis=%d dest=%d", cr, vis, g_f4_destroy_calls);
    }
    SUI_ResetPlayer(0);
    StartF5();
}

// ============================================================================
// F5: Hide Success Starts New Timer
// ============================================================================
StartF5()
{
    print("\n[TEST-F5] Testing Hide Success Starts New Timer...");
    SUI_ResetPlayer(0);
    SUI_SetMaxTextDraws(0, 50);
    SUI_SetEvictionThreshold(0, 50);

    g_f5_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "f5_grp", "OnDummy_Create", "OnF5_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "f5_grp", 10);
    SUI_SetIdleTimeout(0, "f5_grp", 80); // 80ms timeout

    // Show group and wait 100ms while visible
    SUI_ShowGroup(0, "f5_grp");

    SetTimer("F5_HideStage", 100, false);
}

forward F5_HideStage();
public F5_HideStage()
{
    // Now hide group. Timer starts from this moment!
    SUI_HideGroup(0, "f5_grp");

    // Wait 150ms (> 80ms from hide). Must be destroyed!
    SetTimer("VerifyF5", 150, false);
}

forward VerifyF5();
public VerifyF5()
{
    new cr = SUI_IsGroupCreated(0, "f5_grp");
    new act = SUI_GetActiveTextDrawCount(0);

    if (cr == 0 && act == 0 && g_f5_destroy_calls == 1)
    {
        g_test_f5_pass = 1;
        print("[TEST-F5] PASS: Idle timer properly measured from hide transition.");
    }
    else
    {
        printf("[TEST-F5] FAIL: cr=%d act=%d dest=%d", cr, act, g_f5_destroy_calls);
    }
    SUI_ResetPlayer(0);
    StartF6();
}

// ============================================================================
// F6: Hide Failure Does Not Start Hidden Timer
// ============================================================================
StartF6()
{
    print("\n[TEST-F6] Testing Hide Failure Does Not Start Hidden Timer...");
    SUI_ResetPlayer(0);
    SUI_SetMaxTextDraws(0, 50);
    SUI_SetEvictionThreshold(0, 50);

    g_f6_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "f6_grp", "OnDummy_Create", "OnF6_Destroy", "OnDummy_Show", "OnF6_MissingHide");
    SUI_SetGroupSize(0, "f6_grp", 10);
    SUI_SetIdleTimeout(0, "f6_grp", 50); // 50ms timeout

    SUI_ShowGroup(0, "f6_grp"); // visible = 1

    // Attempt hide with missing callback: HideGroup fails, remains visible
    new hide_res = SUI_HideGroup(0, "f6_grp");
    new vis = SUI_IsGroupVisible(0, "f6_grp");

    if (hide_res == 0 && vis == 1)
    {
        // Wait 150ms (> 50ms). Visible group must NOT be destroyed!
        SetTimer("VerifyF6", 150, false);
    }
    else
    {
        printf("[TEST-F6] FAIL on immediate hide state: res=%d vis=%d", hide_res, vis);
        StartF10();
    }
}

forward VerifyF6();
public VerifyF6()
{
    new cr = SUI_IsGroupCreated(0, "f6_grp");
    new vis = SUI_IsGroupVisible(0, "f6_grp");

    if (cr == 1 && vis == 1 && g_f6_destroy_calls == 0)
    {
        g_test_f6_pass = 1;
        print("[TEST-F6] PASS: Hide failure left group visible; not idle destroyed.");
    }
    else
    {
        printf("[TEST-F6] FAIL: cr=%d vis=%d dest=%d", cr, vis, g_f6_destroy_calls);
    }
    SUI_CleanupPlayer(0);
    StartF10();
}

// ============================================================================
// F10: Idle Timeout Zero Contract
// ============================================================================
StartF10()
{
    print("\n[TEST-F10] Testing Idle Timeout Zero Contract...");
    SUI_CleanupPlayer(0);
    SUI_SetMaxTextDraws(0, 50);
    SUI_SetEvictionThreshold(0, 50);

    g_f10_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "f10_grp", "OnDummy_Create", "OnF10_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "f10_grp", 10);
    SUI_SetIdleTimeout(0, "f10_grp", 0); // 0ms timeout

    SUI_ShowGroup(0, "f10_grp");
    SUI_HideGroup(0, "f10_grp");

    // Wait 150ms: ProcessTick will observe currentTick - hiddenSinceTick > 0 and destroy
    SetTimer("VerifyF10", 150, false);
}

forward VerifyF10();
public VerifyF10()
{
    new cr = SUI_IsGroupCreated(0, "f10_grp");
    new act = SUI_GetActiveTextDrawCount(0);

    if (cr == 0 && act == 0 && g_f10_destroy_calls == 1)
    {
        g_test_f10_pass = 1;
        print("[TEST-F10] PASS: idleTimeoutMs = 0 immediately destroyed on next tick.");
    }
    else
    {
        printf("[TEST-F10] FAIL: cr=%d act=%d dest=%d", cr, act, g_f10_destroy_calls);
    }
    SUI_ResetPlayer(0);

    PrintSummaryAndExit();
}

PrintSummaryAndExit()
{
    print("\n================================================================");
    print("      SUI PHASE 10: SHOW FAILURE LIFECYCLE RESULTS (F1-F10)     ");
    print("================================================================");
    printf("F1  (Fresh Create + Failed Show No Premature Destroy): %s", (g_test_f1_pass) ? ("PASS") : ("FAIL"));
    printf("F2  (Real Idle Expiration After Timeout):              %s", (g_test_f2_pass) ? ("PASS") : ("FAIL"));
    printf("F3  (Continuous Hidden Preservation):                  %s", (g_test_f3_pass) ? ("PASS") : ("FAIL"));
    printf("F4  (Show Success Inactivates Hidden Interval):        %s", (g_test_f4_pass) ? ("PASS") : ("FAIL"));
    printf("F5  (Hide Success Starts New Timer):                   %s", (g_test_f5_pass) ? ("PASS") : ("FAIL"));
    printf("F6  (Hide Failure Does Not Start Hidden Timer):        %s", (g_test_f6_pass) ? ("PASS") : ("FAIL"));
    printf("F7  (Create Failure Leaves Group Uncreated):           %s", (g_test_f7_pass) ? ("PASS") : ("FAIL"));
    printf("F8  (Return 0 Callback Treated as Success):            %s", (g_test_f8_pass) ? ("PASS") : ("FAIL"));
    printf("F9  (Generation ABA Safety During Callback):           %s", (g_test_f9_pass) ? ("PASS") : ("FAIL"));
    printf("F10 (Idle Timeout Zero Expiration Contract):           %s", (g_test_f10_pass) ? ("PASS") : ("FAIL"));
    print("================================================================");

    new total_pass = g_test_f1_pass + g_test_f2_pass + g_test_f3_pass + g_test_f4_pass +
                     g_test_f5_pass + g_test_f6_pass + g_test_f7_pass + g_test_f8_pass +
                     g_test_f9_pass + g_test_f10_pass;

    printf("TOTAL: %d / 10 PASSED", total_pass);
    if (total_pass == 10)
    {
        print("OVERALL RESULT: ALL SHOW FAILURE LIFECYCLE TESTS PASSED!");
    }
    else
    {
        print("OVERALL RESULT: SOME TESTS FAILED!");
    }
    print("================================================================\n");

    SendRconCommand("exit");
}
