#include <a_samp>
#include "../../pawn/sui.inc"

new g_test_p1_pass = 0;
new g_test_p2_pass = 0;
new g_test_p3_pass = 0;
new g_test_p4_pass = 0;
new g_test_p5_pass = 0;
new g_test_p6_pass = 0;
new g_test_p7_pass = 0;
new g_test_p8_pass = 0;
new g_test_p9_pass = 0;
new g_test_p10_pass = 0;
new g_test_p11_pass = 0;
new g_test_p12_pass = 0;
new g_test_p13_pass = 0;

new g_gm_shared_calls = 0;
new g_p11_new_create_calls = 0;

main()
{
    print("\n================================================================");
    print("      SUI-006 CALLBACK SEMANTICS & EXECUTION STATUS TEST        ");
    print("================================================================\n");

    SUI_SetDebug(true);
    SUI_ResetPlayer(0);

    // -------------------------------------------------------------
    // TEST P1: Create Callback - Return 1
    // -------------------------------------------------------------
    print("[TEST-P1] Testing Create Callback returning 1...");
    SUI_CreatePlayerFactoryGroup(0, "p1_grp", "OnP1_Create", "OnP1_Destroy", "OnP1_Show", "OnP1_Hide");
    SUI_SetGroupSize(0, "p1_grp", 5);
    SUI_ShowGroup(0, "p1_grp");

    new p1Created = SUI_IsGroupCreated(0, "p1_grp");
    new p1Visible = SUI_IsGroupVisible(0, "p1_grp");
    new p1Active = SUI_GetActiveTextDrawCount(0);
    SUI_DestroyGroup(0, "p1_grp");
    new p1PostActive = SUI_GetActiveTextDrawCount(0);

    if (p1Created == 1 && p1Visible == 1 && p1Active == 5 && p1PostActive == 0)
    {
        g_test_p1_pass = 1;
        print("[TEST-P1] PASS: Create callback returning 1 succeeded with activeTD=5 -> 0.");
    }
    else
    {
        printf("[TEST-P1] FAIL: created=%d visible=%d active=%d postActive=%d", p1Created, p1Visible, p1Active, p1PostActive);
    }

    // -------------------------------------------------------------
    // TEST P2: Create Callback - Return 0
    // -------------------------------------------------------------
    print("\n[TEST-P2] Testing Create Callback returning 0...");
    SUI_CreatePlayerFactoryGroup(0, "p2_grp", "OnP2_Create", "OnP2_Destroy", "OnP2_Show", "OnP2_Hide");
    SUI_SetGroupSize(0, "p2_grp", 5);
    SUI_ShowGroup(0, "p2_grp");

    new p2Created = SUI_IsGroupCreated(0, "p2_grp");
    new p2Visible = SUI_IsGroupVisible(0, "p2_grp");
    new p2Active = SUI_GetActiveTextDrawCount(0);
    SUI_DestroyGroup(0, "p2_grp");
    new p2PostActive = SUI_GetActiveTextDrawCount(0);

    if (p2Created == 1 && p2Visible == 1 && p2Active == 5 && p2PostActive == 0)
    {
        g_test_p2_pass = 1;
        print("[TEST-P2] PASS: Create callback returning 0 succeeded without veto; activeTD=5 -> 0.");
    }
    else
    {
        printf("[TEST-P2] FAIL: created=%d visible=%d active=%d postActive=%d", p2Created, p2Visible, p2Active, p2PostActive);
    }

    // -------------------------------------------------------------
    // TEST P3: Create Callback - No Explicit Return
    // -------------------------------------------------------------
    print("\n[TEST-P3] Testing Create Callback with no explicit return...");
    SUI_CreatePlayerFactoryGroup(0, "p3_grp", "OnP3_Create", "OnP3_Destroy", "OnP3_Show", "OnP3_Hide");
    SUI_SetGroupSize(0, "p3_grp", 5);
    SUI_ShowGroup(0, "p3_grp");

    new p3Created = SUI_IsGroupCreated(0, "p3_grp");
    new p3Visible = SUI_IsGroupVisible(0, "p3_grp");
    new p3Active = SUI_GetActiveTextDrawCount(0);
    SUI_DestroyGroup(0, "p3_grp");

    if (p3Created == 1 && p3Visible == 1 && p3Active == 5 && SUI_GetActiveTextDrawCount(0) == 0)
    {
        g_test_p3_pass = 1;
        print("[TEST-P3] PASS: Create callback with no explicit return succeeded.");
    }
    else
    {
        printf("[TEST-P3] FAIL: created=%d visible=%d active=%d", p3Created, p3Visible, p3Active);
    }

    // -------------------------------------------------------------
    // TEST P4: Show Callback - Return 0
    // -------------------------------------------------------------
    print("\n[TEST-P4] Testing Show Callback returning 0...");
    SUI_CreatePlayerFactoryGroup(0, "p4_grp", "OnP4_Create", "OnP4_Destroy", "OnP4_Show", "OnP4_Hide");
    SUI_SetGroupSize(0, "p4_grp", 5);
    SUI_ShowGroup(0, "p4_grp");

    new p4Visible = SUI_IsGroupVisible(0, "p4_grp");
    SUI_DestroyGroup(0, "p4_grp");

    if (p4Visible == 1)
    {
        g_test_p4_pass = 1;
        print("[TEST-P4] PASS: Show callback returning 0 did not prevent group visibility.");
    }
    else
    {
        printf("[TEST-P4] FAIL: p4Visible=%d", p4Visible);
    }

    // -------------------------------------------------------------
    // TEST P5: Hide Callback - Return 0
    // -------------------------------------------------------------
    print("\n[TEST-P5] Testing Hide Callback returning 0...");
    SUI_CreatePlayerFactoryGroup(0, "p5_grp", "OnP5_Create", "OnP5_Destroy", "OnP5_Show", "OnP5_Hide");
    SUI_SetGroupSize(0, "p5_grp", 6);
    SUI_ShowGroup(0, "p5_grp");

    new p5ActiveBeforeHide = SUI_GetActiveTextDrawCount(0);
    SUI_HideGroup(0, "p5_grp");

    new p5VisibleAfterHide = SUI_IsGroupVisible(0, "p5_grp");
    new p5CreatedAfterHide = SUI_IsGroupCreated(0, "p5_grp");
    new p5ActiveAfterHide = SUI_GetActiveTextDrawCount(0);

    SUI_DestroyGroup(0, "p5_grp");

    if (p5ActiveBeforeHide == 6 && p5VisibleAfterHide == 0 && p5CreatedAfterHide == 1 && p5ActiveAfterHide == 6 && SUI_GetActiveTextDrawCount(0) == 0)
    {
        g_test_p5_pass = 1;
        print("[TEST-P5] PASS: Hide callback returning 0 hid group while preserving capacity.");
    }
    else
    {
        printf("[TEST-P5] FAIL: visible=%d created=%d active=%d", p5VisibleAfterHide, p5CreatedAfterHide, p5ActiveAfterHide);
    }

    // -------------------------------------------------------------
    // TEST P6: Destroy Callback - Return 0
    // -------------------------------------------------------------
    print("\n[TEST-P6] Testing Destroy Callback returning 0...");
    SUI_CreatePlayerFactoryGroup(0, "p6_grp", "OnP6_Create", "OnP6_Destroy", "OnP6_Show", "OnP6_Hide");
    SUI_SetGroupSize(0, "p6_grp", 4);
    SUI_ShowGroup(0, "p6_grp");

    SUI_DestroyGroup(0, "p6_grp");

    new p6Created = SUI_IsGroupCreated(0, "p6_grp");
    new p6Visible = SUI_IsGroupVisible(0, "p6_grp");
    new p6Active = SUI_GetActiveTextDrawCount(0);

    if (p6Created == 0 && p6Visible == 0 && p6Active == 0)
    {
        g_test_p6_pass = 1;
        print("[TEST-P6] PASS: Destroy callback returning 0 completed destruction and capacity release.");
    }
    else
    {
        printf("[TEST-P6] FAIL: created=%d visible=%d active=%d", p6Created, p6Visible, p6Active);
    }

    // -------------------------------------------------------------
    // TEST P8: Eviction Destroy Callback - Return 0
    // -------------------------------------------------------------
    print("\n[TEST-P8] Testing Eviction Destroy Callback returning 0...");
    SUI_ResetPlayer(0);
    SUI_SetMaxTextDraws(0, 100);
    SUI_SetEvictionThreshold(0, 50);

    SUI_CreatePlayerFactoryGroup(0, "p8_cand", "OnP8_CandCreate", "OnP8_CandDestroy", "OnP8_CandShow", "OnP8_CandHide");
    SUI_SetGroupSize(0, "p8_cand", 20);
    SUI_SetGroupPriority(0, "p8_cand", SUI_PRIORITY_LOW);
    SUI_ShowGroup(0, "p8_cand");
    SUI_HideGroup(0, "p8_cand");

    new p8ActivePre = SUI_GetActiveTextDrawCount(0);

    SUI_CreatePlayerFactoryGroup(0, "p8_req", "OnP8_ReqCreate", "OnP8_ReqDestroy", "OnP8_ReqShow", "OnP8_ReqHide");
    SUI_SetGroupSize(0, "p8_req", 40);
    SUI_ShowGroup(0, "p8_req");

    new p8CandCreated = SUI_IsGroupCreated(0, "p8_cand");
    new p8ReqCreated = SUI_IsGroupCreated(0, "p8_req");
    new p8ActivePost = SUI_GetActiveTextDrawCount(0);

    SUI_DestroyGroup(0, "p8_req");

    if (p8ActivePre == 20 && p8CandCreated == 0 && p8ReqCreated == 1 && p8ActivePost == 40 && SUI_GetActiveTextDrawCount(0) == 0)
    {
        g_test_p8_pass = 1;
        print("[TEST-P8] PASS: Eviction candidate destroy returning 0 completed eviction and accommodated new group.");
    }
    else
    {
        printf("[TEST-P8] FAIL: candCreated=%d reqCreated=%d preActive=%d postActive=%d",
            p8CandCreated, p8ReqCreated, p8ActivePre, p8ActivePost);
    }

    // Restore standard limits
    SUI_SetMaxTextDraws(0, 256);
    SUI_SetEvictionThreshold(0, 230);

    // -------------------------------------------------------------
    // TEST P9: Missing Callback Handling
    // -------------------------------------------------------------
    print("\n[TEST-P9] Testing Missing Callback...");
    SUI_CreatePlayerFactoryGroup(0, "p9_grp", "DoesNotExist_Create", "OnP9_Destroy", "OnP9_Show", "OnP9_Hide");
    SUI_SetGroupSize(0, "p9_grp", 10);
    SUI_ShowGroup(0, "p9_grp");

    new p9Created = SUI_IsGroupCreated(0, "p9_grp");
    new p9Active = SUI_GetActiveTextDrawCount(0);

    if (p9Created == 0 && p9Active == 0)
    {
        g_test_p9_pass = 1;
        print("[TEST-P9] PASS: Missing callback failed invocation safely without committing state.");
    }
    else
    {
        printf("[TEST-P9] FAIL: created=%d active=%d", p9Created, p9Active);
    }
    SUI_ResetPlayer(0);

    // -------------------------------------------------------------
    // TEST P10: Same Callback, Returning Different Values
    // -------------------------------------------------------------
    print("\n[TEST-P10] Testing Callbacks returning 0, 1, 42, -1...");
    SUI_CreatePlayerFactoryGroup(0, "p10_ret0", "OnP10_Ret0", "OnP10_Ret0", "OnP10_Ret0", "OnP10_Ret0");
    SUI_SetGroupSize(0, "p10_ret0", 2);
    SUI_CreatePlayerFactoryGroup(0, "p10_ret1", "OnP10_Ret1", "OnP10_Ret1", "OnP10_Ret1", "OnP10_Ret1");
    SUI_SetGroupSize(0, "p10_ret1", 2);
    SUI_CreatePlayerFactoryGroup(0, "p10_ret42", "OnP10_Ret42", "OnP10_Ret42", "OnP10_Ret42", "OnP10_Ret42");
    SUI_SetGroupSize(0, "p10_ret42", 2);
    SUI_CreatePlayerFactoryGroup(0, "p10_retneg1", "OnP10_RetNeg1", "OnP10_RetNeg1", "OnP10_RetNeg1", "OnP10_RetNeg1");
    SUI_SetGroupSize(0, "p10_retneg1", 2);

    SUI_ShowGroup(0, "p10_ret0");
    SUI_ShowGroup(0, "p10_ret1");
    SUI_ShowGroup(0, "p10_ret42");
    SUI_ShowGroup(0, "p10_retneg1");

    new p10ActiveShow = SUI_GetActiveTextDrawCount(0); // 8

    SUI_HideGroup(0, "p10_ret0");
    SUI_HideGroup(0, "p10_ret1");
    SUI_HideGroup(0, "p10_ret42");
    SUI_HideGroup(0, "p10_retneg1");

    new p10ActiveHide = SUI_GetActiveTextDrawCount(0); // 8

    SUI_DestroyGroup(0, "p10_ret0");
    SUI_DestroyGroup(0, "p10_ret1");
    SUI_DestroyGroup(0, "p10_ret42");
    SUI_DestroyGroup(0, "p10_retneg1");

    new p10ActiveDestroy = SUI_GetActiveTextDrawCount(0); // 0

    if (p10ActiveShow == 8 && p10ActiveHide == 8 && p10ActiveDestroy == 0)
    {
        g_test_p10_pass = 1;
        print("[TEST-P10] PASS: All return values (0, 1, 42, -1) behaved identically across lifecycle.");
    }
    else
    {
        printf("[TEST-P10] FAIL: showActive=%d hideActive=%d destroyActive=%d",
            p10ActiveShow, p10ActiveHide, p10ActiveDestroy);
    }

    // -------------------------------------------------------------
    // TEST P11: Generation Replacement + Return 0
    // -------------------------------------------------------------
    print("\n[TEST-P11] Testing Generation Replacement during Callback returning 0...");
    SUI_ResetPlayer(0);
    SUI_CreatePlayerFactoryGroup(0, "p11_grp", "OnP11_OldCreate", "OnP11_Destroy", "OnP11_Show", "OnP11_Hide");
    SUI_SetGroupSize(0, "p11_grp", 5);
    SUI_ShowGroup(0, "p11_grp");

    new p11ActiveAfterOuter = SUI_GetActiveTextDrawCount(0);
    new p11CreatedAfterOuter = SUI_IsGroupCreated(0, "p11_grp");

    // Now show replacement group explicitly
    SUI_ShowGroup(0, "p11_grp");
    new p11ActiveAfterExplicit = SUI_GetActiveTextDrawCount(0);
    new p11CreatedAfterExplicit = SUI_IsGroupCreated(0, "p11_grp");

    SUI_DestroyGroup(0, "p11_grp");

    if (p11ActiveAfterOuter == 0 && p11CreatedAfterOuter == 0 && p11ActiveAfterExplicit == 8 && p11CreatedAfterExplicit == 1 && SUI_GetActiveTextDrawCount(0) == 0 && g_p11_new_create_calls == 1)
    {
        g_test_p11_pass = 1;
        print("[TEST-P11] PASS: Generation mismatch safely aborted outer transaction despite return 0.");
    }
    else
    {
        printf("[TEST-P11] FAIL: outerActive=%d outerCreated=%d explicitActive=%d explicitCreated=%d calls=%d",
            p11ActiveAfterOuter, p11CreatedAfterOuter, p11ActiveAfterExplicit, p11CreatedAfterExplicit, g_p11_new_create_calls);
    }

    // -------------------------------------------------------------
    // TEST P12: Cross-AMX Callback Collision with Return 0
    // -------------------------------------------------------------
    print("\n[TEST-P12] Testing Cross-AMX Callback Collision with Return 0...");
    SUI_ResetPlayer(0);
    CallRemoteFunction("FS_ResetCounts", "");
    g_gm_shared_calls = 0;

    SUI_CreatePlayerFactoryGroup(0, "p12_grp", "SharedCallback_ZeroReturn", "OnP12_Destroy", "OnP12_Show", "OnP12_Hide");
    SUI_SetGroupSize(0, "p12_grp", 3);
    SUI_ShowGroup(0, "p12_grp");

    new fsSharedCalls = CallRemoteFunction("FS_GetSharedCallCount", "");
    new p12Created = SUI_IsGroupCreated(0, "p12_grp");
    new p12Visible = SUI_IsGroupVisible(0, "p12_grp");

    SUI_DestroyGroup(0, "p12_grp");

    if (g_gm_shared_calls == 1 && fsSharedCalls == 0 && p12Created == 1 && p12Visible == 1)
    {
        g_test_p12_pass = 1;
        print("[TEST-P12] PASS: Shared callback returning 0 executed only in owner AMX; zero-return treated as success.");
    }
    else
    {
        printf("[TEST-P12] FAIL: gmCalls=%d fsCalls=%d created=%d visible=%d",
            g_gm_shared_calls, fsSharedCalls, p12Created, p12Visible);
    }

    // -------------------------------------------------------------
    // TEST P13: AMX Execution Error (Division by Zero)
    // -------------------------------------------------------------
    print("\n[TEST-P13] Testing AMX Execution Error...");
    SUI_ResetPlayer(0);
    SUI_CreatePlayerFactoryGroup(0, "p13_grp", "OnP13_ErrorCreate", "OnP13_Destroy", "OnP13_Show", "OnP13_Hide");
    SUI_SetGroupSize(0, "p13_grp", 7);
    SUI_ShowGroup(0, "p13_grp");

    new p13Created = SUI_IsGroupCreated(0, "p13_grp");
    new p13Active = SUI_GetActiveTextDrawCount(0);

    if (p13Created == 0 && p13Active == 0)
    {
        g_test_p13_pass = 1;
        print("[TEST-P13] PASS: AMX runtime error in callback failed safely; state uncommitted.");
    }
    else
    {
        printf("[TEST-P13] FAIL: created=%d active=%d", p13Created, p13Active);
    }
    SUI_ResetPlayer(0);

    // -------------------------------------------------------------
    // TEST P7 SETUP: ProcessTick Idle Destroy with Return 0
    // -------------------------------------------------------------
    print("\n[TEST-P7] Setting up ProcessTick Idle Destroy with Return 0...");
    SUI_CreatePlayerFactoryGroup(0, "p7_grp", "OnP7_Create", "OnP7_Destroy", "OnP7_Show", "OnP7_Hide");
    SUI_SetGroupSize(0, "p7_grp", 3);
    SUI_SetIdleTimeout(0, "p7_grp", 50);
    SUI_ShowGroup(0, "p7_grp");
    SUI_HideGroup(0, "p7_grp");

    SetTimer("P7_VerifyStage", 250, false);
}

forward P7_VerifyStage();
public P7_VerifyStage()
{
    new p7Created = SUI_IsGroupCreated(0, "p7_grp");
    new p7Active = SUI_GetActiveTextDrawCount(0);

    if (p7Created == 0 && p7Active == 0)
    {
        g_test_p7_pass = 1;
        print("[TEST-P7] PASS: ProcessTick idle destroy completed despite callback returning 0.");
    }
    else
    {
        printf("[TEST-P7] FAIL: p7Created=%d p7Active=%d", p7Created, p7Active);
    }

    // -------------------------------------------------------------
    // SUMMARY REPORT
    // -------------------------------------------------------------
    print("\n================================================================");
    print("          SUI CALLBACK SEMANTICS REGRESSION RESULTS (P1-P13)    ");
    print("================================================================");
    printf("P1  (Create Return 1):                      %s", (g_test_p1_pass) ? ("PASS") : ("FAIL"));
    printf("P2  (Create Return 0):                      %s", (g_test_p2_pass) ? ("PASS") : ("FAIL"));
    printf("P3  (Create No Explicit Return):            %s", (g_test_p3_pass) ? ("PASS") : ("FAIL"));
    printf("P4  (Show Return 0):                        %s", (g_test_p4_pass) ? ("PASS") : ("FAIL"));
    printf("P5  (Hide Return 0):                        %s", (g_test_p5_pass) ? ("PASS") : ("FAIL"));
    printf("P6  (Destroy Return 0):                     %s", (g_test_p6_pass) ? ("PASS") : ("FAIL"));
    printf("P7  (ProcessTick Destroy Return 0):         %s", (g_test_p7_pass) ? ("PASS") : ("FAIL"));
    printf("P8  (Eviction Destroy Return 0):            %s", (g_test_p8_pass) ? ("PASS") : ("FAIL"));
    printf("P9  (Missing Callback Safe Rejection):      %s", (g_test_p9_pass) ? ("PASS") : ("FAIL"));
    printf("P10 (Different Return Values Equivalence):  %s", (g_test_p10_pass) ? ("PASS") : ("FAIL"));
    printf("P11 (Generation Replacement + Return 0):    %s", (g_test_p11_pass) ? ("PASS") : ("FAIL"));
    printf("P12 (Cross-AMX Collision + Return 0):       %s", (g_test_p12_pass) ? ("PASS") : ("FAIL"));
    printf("P13 (AMX Execution Error Safe Handling):    %s", (g_test_p13_pass) ? ("PASS") : ("FAIL"));
    print("================================================================");

    if (g_test_p1_pass && g_test_p2_pass && g_test_p3_pass && g_test_p4_pass &&
        g_test_p5_pass && g_test_p6_pass && g_test_p7_pass && g_test_p8_pass &&
        g_test_p9_pass && g_test_p10_pass && g_test_p11_pass && g_test_p12_pass &&
        g_test_p13_pass)
    {
        print("OVERALL RESULT: ALL CALLBACK SEMANTICS TESTS PASSED! (13/13)");
    }
    else
    {
        print("OVERALL RESULT: ONE OR MORE TESTS FAILED!");
    }
    print("================================================================\n");
}

// -------------------------------------------------------------
// Callback Implementations
// -------------------------------------------------------------

// P1
forward OnP1_Create(playerid);
public OnP1_Create(playerid) { return 1; }
forward OnP1_Destroy(playerid);
public OnP1_Destroy(playerid) { return 1; }
forward OnP1_Show(playerid);
public OnP1_Show(playerid) { return 1; }
forward OnP1_Hide(playerid);
public OnP1_Hide(playerid) { return 1; }

// P2
forward OnP2_Create(playerid);
public OnP2_Create(playerid) { return 0; }
forward OnP2_Destroy(playerid);
public OnP2_Destroy(playerid) { return 0; }
forward OnP2_Show(playerid);
public OnP2_Show(playerid) { return 1; }
forward OnP2_Hide(playerid);
public OnP2_Hide(playerid) { return 0; }

// P3 (No explicit return)
forward OnP3_Create(playerid);
public OnP3_Create(playerid)
{
    // No return statement
}
forward OnP3_Destroy(playerid);
public OnP3_Destroy(playerid) { return 1; }
forward OnP3_Show(playerid);
public OnP3_Show(playerid) { return 1; }
forward OnP3_Hide(playerid);
public OnP3_Hide(playerid) { return 1; }

// P4
forward OnP4_Create(playerid);
public OnP4_Create(playerid) { return 1; }
forward OnP4_Destroy(playerid);
public OnP4_Destroy(playerid) { return 1; }
forward OnP4_Show(playerid);
public OnP4_Show(playerid) { return 0; }
forward OnP4_Hide(playerid);
public OnP4_Hide(playerid) { return 1; }

// P5
forward OnP5_Create(playerid);
public OnP5_Create(playerid) { return 1; }
forward OnP5_Destroy(playerid);
public OnP5_Destroy(playerid) { return 1; }
forward OnP5_Show(playerid);
public OnP5_Show(playerid) { return 1; }
forward OnP5_Hide(playerid);
public OnP5_Hide(playerid) { return 0; }

// P6
forward OnP6_Create(playerid);
public OnP6_Create(playerid) { return 1; }
forward OnP6_Destroy(playerid);
public OnP6_Destroy(playerid) { return 0; }
forward OnP6_Show(playerid);
public OnP6_Show(playerid) { return 1; }
forward OnP6_Hide(playerid);
public OnP6_Hide(playerid) { return 1; }

// P7
forward OnP7_Create(playerid);
public OnP7_Create(playerid) { return 1; }
forward OnP7_Destroy(playerid);
public OnP7_Destroy(playerid) { return 0; }
forward OnP7_Show(playerid);
public OnP7_Show(playerid) { return 1; }
forward OnP7_Hide(playerid);
public OnP7_Hide(playerid) { return 1; }

// P8
forward OnP8_CandCreate(playerid);
public OnP8_CandCreate(playerid) { return 1; }
forward OnP8_CandDestroy(playerid);
public OnP8_CandDestroy(playerid) { return 0; }
forward OnP8_CandShow(playerid);
public OnP8_CandShow(playerid) { return 1; }
forward OnP8_CandHide(playerid);
public OnP8_CandHide(playerid) { return 1; }

forward OnP8_ReqCreate(playerid);
public OnP8_ReqCreate(playerid) { return 1; }
forward OnP8_ReqDestroy(playerid);
public OnP8_ReqDestroy(playerid) { return 1; }
forward OnP8_ReqShow(playerid);
public OnP8_ReqShow(playerid) { return 1; }
forward OnP8_ReqHide(playerid);
public OnP8_ReqHide(playerid) { return 1; }

// P9
forward OnP9_Destroy(playerid);
public OnP9_Destroy(playerid) { return 1; }
forward OnP9_Show(playerid);
public OnP9_Show(playerid) { return 1; }
forward OnP9_Hide(playerid);
public OnP9_Hide(playerid) { return 1; }

// P10
forward OnP10_Ret0(playerid);
public OnP10_Ret0(playerid) { return 0; }
forward OnP10_Ret1(playerid);
public OnP10_Ret1(playerid) { return 1; }
forward OnP10_Ret42(playerid);
public OnP10_Ret42(playerid) { return 42; }
forward OnP10_RetNeg1(playerid);
public OnP10_RetNeg1(playerid) { return -1; }

// P11
forward OnP11_OldCreate(playerid);
public OnP11_OldCreate(playerid)
{
    SUI_ResetPlayer(playerid);
    SUI_CreatePlayerFactoryGroup(playerid, "p11_grp", "OnP11_NewCreate", "OnP11_Destroy", "OnP11_Show", "OnP11_Hide");
    SUI_SetGroupSize(playerid, "p11_grp", 8);
    return 0;
}
forward OnP11_NewCreate(playerid);
public OnP11_NewCreate(playerid)
{
    g_p11_new_create_calls++;
    return 1;
}
forward OnP11_Destroy(playerid);
public OnP11_Destroy(playerid) { return 1; }
forward OnP11_Show(playerid);
public OnP11_Show(playerid) { return 1; }
forward OnP11_Hide(playerid);
public OnP11_Hide(playerid) { return 1; }

// P12
forward SharedCallback_ZeroReturn(playerid);
public SharedCallback_ZeroReturn(playerid)
{
    g_gm_shared_calls++;
    printf("[GM] SharedCallback_ZeroReturn executed for playerid=%d", playerid);
    return 0;
}
forward OnP12_Destroy(playerid);
public OnP12_Destroy(playerid) { return 1; }
forward OnP12_Show(playerid);
public OnP12_Show(playerid) { return 1; }
forward OnP12_Hide(playerid);
public OnP12_Hide(playerid) { return 1; }

// P13
forward OnP13_ErrorCreate(playerid);
public OnP13_ErrorCreate(playerid)
{
    new zero = 0;
    new val = 100 / zero;
    return val;
}
forward OnP13_Destroy(playerid);
public OnP13_Destroy(playerid) { return 1; }
forward OnP13_Show(playerid);
public OnP13_Show(playerid) { return 1; }
forward OnP13_Hide(playerid);
public OnP13_Hide(playerid) { return 1; }
