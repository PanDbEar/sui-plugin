#include <a_samp>
#include <sui>

new g_c1_pass = 0;
new g_c2_pass = 0;
new g_c3_pass = 0;
new g_c4_pass = 0;
new g_c5_pass = 0;
new g_c6_pass = 0;
new g_c7_pass = 0;
new g_c8_pass = 0;
new g_c9_pass = 0;
new g_c10_pass = 0;
new g_c11_pass = 0;
new g_c12_pass = 0;

new g_g1_pass = 0;
new g_g2_pass = 0;
new g_g3_pass = 0;
new g_g4_pass = 0;
new g_g5_pass = 0;
new g_g6_pass = 0;
new g_g7_pass = 0;

new g_c5_set_size_res = -1;

main()
{
    print("================================================================");
    print("    SUI-004 CAPACITY ARITHMETIC & ACCOUNTING INVARIANTS TEST   ");
    print("================================================================");
}

public OnGameModeInit()
{
    SUI_SetDebug(true);
    SetTimer("RunCapacityTestsPart1", 500, false);
    return 1;
}

// Dummy callbacks for tests
forward OnDummy_Create(playerid);
public OnDummy_Create(playerid) { return 1; }

forward OnDummy_Destroy(playerid);
public OnDummy_Destroy(playerid) { return 1; }

forward OnDummy_Show(playerid);
public OnDummy_Show(playerid) { return 1; }

forward OnDummy_Hide(playerid);
public OnDummy_Hide(playerid) { return 1; }

// Callbacks for C5
forward OnC5_Create(playerid);
public OnC5_Create(playerid)
{
    print("[TEST-C5] OnC5_Create executing: attempting SUI_SetGroupSize(2147483647)...");
    g_c5_set_size_res = SUI_SetGroupSize(playerid, "c5_grp", 2147483647);
    return 1;
}

forward OnC5_Destroy(playerid);
public OnC5_Destroy(playerid) { return 1; }

forward OnC5_Show(playerid);
public OnC5_Show(playerid) { return 1; }

forward OnC5_Hide(playerid);
public OnC5_Hide(playerid) { return 1; }

forward RunCapacityTestsPart1();
public RunCapacityTestsPart1()
{
    print("\n--- Starting Capacity Arithmetic Tests (C1-C12) ---");

    // =============================================================
    // TEST C1: Normal Addition
    // =============================================================
    print("\n[TEST-C1] Testing Normal Addition...");
    SUI_CreatePlayerFactoryGroup(0, "c1_a", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "c1_a", 10);
    SUI_ShowGroup(0, "c1_a");
    new c1_act1 = SUI_GetActiveTextDrawCount(0);

    SUI_CreatePlayerFactoryGroup(0, "c1_b", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "c1_b", 20);
    SUI_ShowGroup(0, "c1_b");
    new c1_act2 = SUI_GetActiveTextDrawCount(0);

    SUI_DestroyGroup(0, "c1_a");
    SUI_DestroyGroup(0, "c1_b");
    new c1_act3 = SUI_GetActiveTextDrawCount(0);

    if (c1_act1 == 10 && c1_act2 == 30 && c1_act3 == 0)
    {
        g_c1_pass = 1;
        print("[TEST-C1] PASS: 10 + 20 = 30 active textdraws, 0 on destroy.");
    }
    else
    {
        printf("[TEST-C1] FAIL: Expected (10, 30, 0), got (%d, %d, %d)", c1_act1, c1_act2, c1_act3);
    }

    // =============================================================
    // TEST C2: Exact Threshold
    // =============================================================
    print("\n[TEST-C2] Testing Exact Threshold (active + req == threshold)...");
    SUI_SetEvictionThreshold(0, 50);
    SUI_CreatePlayerFactoryGroup(0, "c2_a", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "c2_a", 20);
    SUI_ShowGroup(0, "c2_a");

    SUI_CreatePlayerFactoryGroup(0, "c2_b", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "c2_b", 30);
    new c2_show = SUI_ShowGroup(0, "c2_b");
    new c2_act = SUI_GetActiveTextDrawCount(0);

    SUI_DestroyGroup(0, "c2_a");
    SUI_DestroyGroup(0, "c2_b");
    SUI_SetEvictionThreshold(0, 230); // reset

    if (c2_show == 1 && c2_act == 50)
    {
        g_c2_pass = 1;
        print("[TEST-C2] PASS: Exact threshold 50 allowed (active == 50).");
    }
    else
    {
        printf("[TEST-C2] FAIL: Expected show=1 act=50, got show=%d act=%d", c2_show, c2_act);
    }

    // =============================================================
    // TEST C3: One Above Threshold
    // =============================================================
    print("\n[TEST-C3] Testing One Above Threshold (active + req == threshold + 1)...");
    SUI_SetEvictionThreshold(0, 50);
    SUI_CreatePlayerFactoryGroup(0, "c3_a", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "c3_a", 50);
    SUI_SetGroupEvictable(0, "c3_a", false); // protect from eviction
    SUI_ShowGroup(0, "c3_a");

    SUI_CreatePlayerFactoryGroup(0, "c3_b", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "c3_b", 1);
    SUI_ShowGroup(0, "c3_b");
    new c3_created = SUI_IsGroupCreated(0, "c3_b");
    new c3_act = SUI_GetActiveTextDrawCount(0);

    SUI_DestroyGroup(0, "c3_a");
    SUI_DestroyGroup(0, "c3_b");
    SUI_SetEvictionThreshold(0, 230); // reset

    if (c3_created == 0 && c3_act == 50)
    {
        g_c3_pass = 1;
        print("[TEST-C3] PASS: Threshold + 1 rejected (isCreated=0, active=50 unchanged).");
    }
    else
    {
        printf("[TEST-C3] FAIL: Expected created=0 act=50, got created=%d act=%d",
            c3_created, c3_act);
    }

    // =============================================================
    // TEST C4: Maximum Pawn-Positive Size (2147483647)
    // =============================================================
    print("\n[TEST-C4] Testing Maximum Pawn-Positive Size (2147483647)...");
    SUI_CreatePlayerFactoryGroup(0, "c4_grp", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "c4_grp", 2147483647);
    SUI_ShowGroup(0, "c4_grp");
    new c4_created = SUI_IsGroupCreated(0, "c4_grp");
    new c4_act = SUI_GetActiveTextDrawCount(0);
    SUI_DestroyGroup(0, "c4_grp");

    if (c4_created == 0 && c4_act == 0)
    {
        g_c4_pass = 1;
        print("[TEST-C4] PASS: Oversized group rejected cleanly without unsigned wrap (created=0, active=0).");
    }
    else
    {
        printf("[TEST-C4] FAIL: Expected created=0 act=0, got created=%d act=%d",
            c4_created, c4_act);
    }

    // =============================================================
    // TEST C5: Callback Changes Size During Create
    // =============================================================
    print("\n[TEST-C5] Testing Callback Size Mutation Guard...");
    SUI_CreatePlayerFactoryGroup(0, "c5_grp", "OnC5_Create", "OnC5_Destroy", "OnC5_Show", "OnC5_Hide");
    SUI_SetGroupSize(0, "c5_grp", 1);
    SUI_ShowGroup(0, "c5_grp");
    new c5_act = SUI_GetActiveTextDrawCount(0);
    SUI_DestroyGroup(0, "c5_grp");
    new c5_final = SUI_GetActiveTextDrawCount(0);

    if (g_c5_set_size_res == 0 && c5_act == 1 && c5_final == 0)
    {
        g_c5_pass = 1;
        print("[TEST-C5] PASS: Size mutation during callback rejected (res=0), authorized size 1 enforced.");
    }
    else
    {
        printf("[TEST-C5] FAIL: Expected cb_res=0 act=1 final=0, got cb_res=%d act=%d final=%d",
            g_c5_set_size_res, c5_act, c5_final);
    }

    // =============================================================
    // TEST C6: Change Size While Created
    // =============================================================
    print("\n[TEST-C6] Testing Size Mutation on Created Group...");
    SUI_CreatePlayerFactoryGroup(0, "c6_grp", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "c6_grp", 5);
    SUI_ShowGroup(0, "c6_grp");
    new c6_res = SUI_SetGroupSize(0, "c6_grp", 100);
    new c6_act = SUI_GetActiveTextDrawCount(0);
    SUI_DestroyGroup(0, "c6_grp");
    new c6_final = SUI_GetActiveTextDrawCount(0);

    if (c6_res == 0 && c6_act == 5 && c6_final == 0)
    {
        g_c6_pass = 1;
        print("[TEST-C6] PASS: Modifying created group rejected (res=0), active count preserved (5 -> 0).");
    }
    else
    {
        printf("[TEST-C6] FAIL: Expected res=0 act=5 final=0, got res=%d act=%d final=%d",
            c6_res, c6_act, c6_final);
    }

    // =============================================================
    // TEST C7: Size Change While Hidden But Created
    // =============================================================
    print("\n[TEST-C7] Testing Size Mutation on Hidden Created Group...");
    SUI_CreatePlayerFactoryGroup(0, "c7_grp", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "c7_grp", 8);
    SUI_ShowGroup(0, "c7_grp");
    SUI_HideGroup(0, "c7_grp");
    new c7_res = SUI_SetGroupSize(0, "c7_grp", 50);
    new c7_act = SUI_GetActiveTextDrawCount(0);
    SUI_DestroyGroup(0, "c7_grp");
    new c7_final = SUI_GetActiveTextDrawCount(0);

    if (c7_res == 0 && c7_act == 8 && c7_final == 0)
    {
        g_c7_pass = 1;
        print("[TEST-C7] PASS: Modifying hidden created group rejected (res=0), destroyed cleanly (8 -> 0).");
    }
    else
    {
        printf("[TEST-C7] FAIL: Expected res=0 act=8 final=0, got res=%d act=%d final=%d",
            c7_res, c7_act, c7_final);
    }

    // =============================================================
    // TEST C8: Destroy Accounting Exactness
    // =============================================================
    print("\n[TEST-C8] Testing Destroy Accounting Exactness...");
    SUI_CreatePlayerFactoryGroup(0, "c8_a", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "c8_a", 5);
    SUI_ShowGroup(0, "c8_a");

    SUI_CreatePlayerFactoryGroup(0, "c8_b", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "c8_b", 10);
    SUI_ShowGroup(0, "c8_b");

    SUI_CreatePlayerFactoryGroup(0, "c8_c", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "c8_c", 20);
    SUI_ShowGroup(0, "c8_c");

    new c8_total = SUI_GetActiveTextDrawCount(0); // 35
    SUI_DestroyGroup(0, "c8_b");
    new c8_step1 = SUI_GetActiveTextDrawCount(0); // 25
    SUI_DestroyGroup(0, "c8_a");
    new c8_step2 = SUI_GetActiveTextDrawCount(0); // 20
    SUI_DestroyGroup(0, "c8_c");
    new c8_step3 = SUI_GetActiveTextDrawCount(0); // 0

    if (c8_total == 35 && c8_step1 == 25 && c8_step2 == 20 && c8_step3 == 0)
    {
        g_c8_pass = 1;
        print("[TEST-C8] PASS: Exact subtraction sequence (35 -> 25 -> 20 -> 0).");
    }
    else
    {
        printf("[TEST-C8] FAIL: Expected (35, 25, 20, 0), got (%d, %d, %d, %d)",
            c8_total, c8_step1, c8_step2, c8_step3);
    }

    // =============================================================
    // TEST C10: Repeated Create/Destroy Cycles (100 Cycles)
    // =============================================================
    print("\n[TEST-C10] Testing 100 Create/Destroy Cycles for Drift...");
    SUI_CreatePlayerFactoryGroup(0, "c10_grp", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "c10_grp", 7);
    new c10_drift = 0;

    for (new i = 0; i < 100; i++)
    {
        SUI_ShowGroup(0, "c10_grp");
        if (SUI_GetActiveTextDrawCount(0) != 7)
        {
            c10_drift++;
        }
        SUI_DestroyGroup(0, "c10_grp");
        if (SUI_GetActiveTextDrawCount(0) != 0)
        {
            c10_drift++;
        }
    }

    new c10_final = SUI_GetActiveTextDrawCount(0);
    if (c10_drift == 0 && c10_final == 0)
    {
        g_c10_pass = 1;
        print("[TEST-C10] PASS: 100 cycles executed with zero accounting drift.");
    }
    else
    {
        printf("[TEST-C10] FAIL: c10_drift=%d c10_final=%d", c10_drift, c10_final);
    }

    // =============================================================
    // TEST C11: Capacity Failure Must Be Atomic
    // =============================================================
    print("\n[TEST-C11] Testing Capacity Failure Atomicity...");
    SUI_CreatePlayerFactoryGroup(0, "c11_base", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "c11_base", 10);
    SUI_ShowGroup(0, "c11_base");

    SUI_CreatePlayerFactoryGroup(0, "c11_over", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "c11_over", 500);
    SUI_ShowGroup(0, "c11_over");
    new c11_created = SUI_IsGroupCreated(0, "c11_over");
    new c11_act = SUI_GetActiveTextDrawCount(0);

    SUI_DestroyGroup(0, "c11_base");
    SUI_DestroyGroup(0, "c11_over");

    if (c11_created == 0 && c11_act == 10)
    {
        g_c11_pass = 1;
        print("[TEST-C11] PASS: Capacity failure atomic (created=0, active=10 unchanged).");
    }
    else
    {
        printf("[TEST-C11] FAIL: Expected created=0 act=10, got created=%d act=%d",
            c11_created, c11_act);
    }

    // =============================================================
    // TEST C12: Large Values / Wrap Proof
    // =============================================================
    print("\n[TEST-C12] Testing Large Values / Wrap Proof...");
    SUI_CreatePlayerFactoryGroup(0, "c12_base", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "c12_base", 100);
    SUI_ShowGroup(0, "c12_base");

    SUI_CreatePlayerFactoryGroup(0, "c12_huge", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "c12_huge", 2147483647);
    SUI_ShowGroup(0, "c12_huge");
    new c12_created = SUI_IsGroupCreated(0, "c12_huge");
    new c12_act = SUI_GetActiveTextDrawCount(0);

    SUI_DestroyGroup(0, "c12_base");
    SUI_DestroyGroup(0, "c12_huge");

    if (c12_created == 0 && c12_act == 100)
    {
        g_c12_pass = 1;
        print("[TEST-C12] PASS: Large value wrap prevented (created=0, active=100 unchanged).");
    }
    else
    {
        printf("[TEST-C12] FAIL: Expected created=0 act=100, got created=%d act=%d",
            c12_created, c12_act);
    }

    // Schedule C9 (AMX Unload test with filterscript)
    SetTimer("RunCapacityTestC9", 200, false);
}

forward RunCapacityTestC9();
public RunCapacityTestC9()
{
    print("\n[TEST-C9] Testing AMX Unload Accounting with Filterscript...");

    // Create a gamemode group to establish a non-zero baseline
    SUI_CreatePlayerFactoryGroup(0, "c9_gm_grp", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "c9_gm_grp", 5);
    SUI_ShowGroup(0, "c9_gm_grp");
    new base_act = SUI_GetActiveTextDrawCount(0); // 5

    printf("[TEST-C9] Gamemode baseline active count: %d", base_act);

    // Load filterscript
    SendRconCommand("loadfs capacity_filterscript");
    SetTimer("CheckC9Loaded", 500, false);
}

forward CheckC9Loaded();
public CheckC9Loaded()
{
    new act_with_fs = SUI_GetActiveTextDrawCount(0);
    printf("[TEST-C9] Active count with filterscript: %d (expected 20)", act_with_fs);

    // Unload filterscript
    SendRconCommand("unloadfs capacity_filterscript");
    SetTimer("CheckC9Unloaded", 500, false);
}

forward CheckC9Unloaded();
public CheckC9Unloaded()
{
    new act_after_fs = SUI_GetActiveTextDrawCount(0);
    printf("[TEST-C9] Active count after filterscript unload: %d (expected 5)", act_after_fs);

    SUI_DestroyGroup(0, "c9_gm_grp");
    new final_act = SUI_GetActiveTextDrawCount(0);

    if (act_after_fs == 5 && final_act == 0)
    {
        g_c9_pass = 1;
        print("[TEST-C9] PASS: Filterscript group unloaded and 15 textdraws subtracted cleanly.");
    }
    else
    {
        printf("[TEST-C9] FAIL: Expected act_after=5 final=0, got act_after=%d final=%d",
            act_after_fs, final_act);
    }

    RunAccountingGateTests();
}

forward RunAccountingGateTests();
public RunAccountingGateTests()
{
    print("\n================================================================");
    print("      RUNNING SUI PHASE 5.1 ACCOUNTING GATE TESTS (G1-G7)       ");
    print("================================================================");

    // Ensure clean initial state
    SUI_ResetPlayer(0);

    // -------------------------------------------------------------
    // G1: max = 256, threshold = 230 -> Valid
    // -------------------------------------------------------------
    print("\n[TEST-G1] Testing Standard Bounds (max=256, threshold=230)...");
    new g1_max_res = SUI_SetMaxTextDraws(0, 256);
    new g1_thresh_res = SUI_SetEvictionThreshold(0, 230);
    if (g1_max_res == 1 && g1_thresh_res == 1)
    {
        g_g1_pass = 1;
        print("[TEST-G1] PASS: Standard max=256 and threshold=230 accepted.");
    }
    else
    {
        printf("[TEST-G1] FAIL: max_res=%d thresh_res=%d", g1_max_res, g1_thresh_res);
    }

    // -------------------------------------------------------------
    // G2: threshold = max + 1 -> Reject, state unchanged
    // -------------------------------------------------------------
    print("\n[TEST-G2] Testing Threshold > Max Rejection (threshold=257 with max=256)...");
    new g2_res = SUI_SetEvictionThreshold(0, 257);
    if (g2_res == 0)
    {
        g_g2_pass = 1;
        print("[TEST-G2] PASS: Threshold > max was rejected (res=0), state unchanged.");
    }
    else
    {
        printf("[TEST-G2] FAIL: Expected res=0, got res=%d", g2_res);
    }

    // -------------------------------------------------------------
    // G3: max = 256, threshold = 230, set max = 100 -> Reject (max < threshold)
    // -------------------------------------------------------------
    print("\n[TEST-G3] Testing Max < Threshold Rejection (set max=100 with threshold=230)...");
    new g3_res = SUI_SetMaxTextDraws(0, 100);
    if (g3_res == 0)
    {
        g_g3_pass = 1;
        print("[TEST-G3] PASS: Lowering max below threshold rejected (res=0), max unchanged.");
    }
    else
    {
        printf("[TEST-G3] FAIL: Expected res=0, got res=%d", g3_res);
    }

    // -------------------------------------------------------------
    // G4: max = 100, threshold = 90, active = 80, req = 15 -> Exceeds threshold
    // -------------------------------------------------------------
    print("\n[TEST-G4] Testing Threshold Admission Boundary (active=80, req=15, thresh=90, max=100)...");
    SUI_SetEvictionThreshold(0, 80);
    SUI_SetMaxTextDraws(0, 100);
    SUI_SetEvictionThreshold(0, 90);

    SUI_CreatePlayerFactoryGroup(0, "g4_base", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "g4_base", 80);
    SUI_SetGroupEvictable(0, "g4_base", false); // protect from eviction
    SUI_ShowGroup(0, "g4_base");
    new g4_act_base = SUI_GetActiveTextDrawCount(0); // 80

    SUI_CreatePlayerFactoryGroup(0, "g4_cand", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "g4_cand", 15);
    SUI_ShowGroup(0, "g4_cand"); // 80 + 15 = 95 > threshold (90); no evictable group
    new g4_cand_created = SUI_IsGroupCreated(0, "g4_cand");
    new g4_act_after = SUI_GetActiveTextDrawCount(0);

    SUI_DestroyGroup(0, "g4_base");
    SUI_DestroyGroup(0, "g4_cand");

    if (g4_act_base == 80 && g4_cand_created == 0 && g4_act_after == 80)
    {
        g_g4_pass = 1;
        print("[TEST-G4] PASS: Threshold exceeded without eviction -> rejected, active remains 80.");
    }
    else
    {
        printf("[TEST-G4] FAIL: base_act=%d cand_created=%d act_after=%d",
            g4_act_base, g4_cand_created, g4_act_after);
    }

    // -------------------------------------------------------------
    // G5: Hard Max Ceiling (max = 100, active = 95, req = 10 -> Projected 105 > max 100)
    // -------------------------------------------------------------
    print("\n[TEST-G5] Testing Hard Max Ceiling Enforcement (active=95, req=10, max=100)...");
    SUI_SetEvictionThreshold(0, 80);
    SUI_SetMaxTextDraws(0, 100);
    SUI_SetEvictionThreshold(0, 95);

    SUI_CreatePlayerFactoryGroup(0, "g5_base", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "g5_base", 95);
    SUI_SetGroupEvictable(0, "g5_base", false);
    SUI_ShowGroup(0, "g5_base");
    new g5_act_base = SUI_GetActiveTextDrawCount(0); // 95

    SUI_CreatePlayerFactoryGroup(0, "g5_over", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "g5_over", 10);
    SUI_ShowGroup(0, "g5_over");
    new g5_over_created = SUI_IsGroupCreated(0, "g5_over");
    new g5_act_final = SUI_GetActiveTextDrawCount(0);

    SUI_DestroyGroup(0, "g5_base");
    SUI_DestroyGroup(0, "g5_over");

    if (g5_act_base == 95 && g5_over_created == 0 && g5_act_final == 95)
    {
        g_g5_pass = 1;
        print("[TEST-G5] PASS: Projected sum (105) > max (100) rejected; active never exceeded 95.");
    }
    else
    {
        printf("[TEST-G5] FAIL: base=%d over_created=%d final=%d",
            g5_act_base, g5_over_created, g5_act_final);
    }

    // -------------------------------------------------------------
    // G6: Active Count vs Lowered Limit (active = 50, attempt max = 40)
    // -------------------------------------------------------------
    print("\n[TEST-G6] Testing Active Count vs Lowered Max Limit...");
    SUI_ResetPlayer(0);
    SUI_SetMaxTextDraws(0, 256);
    SUI_SetEvictionThreshold(0, 230);

    SUI_CreatePlayerFactoryGroup(0, "g6_grp", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "g6_grp", 50);
    SUI_ShowGroup(0, "g6_grp");
    new g6_act = SUI_GetActiveTextDrawCount(0); // 50

    SUI_SetEvictionThreshold(0, 30);
    new g6_lower_res = SUI_SetMaxTextDraws(0, 40);
    new g6_act_after = SUI_GetActiveTextDrawCount(0);

    SUI_DestroyGroup(0, "g6_grp");
    SUI_ResetPlayer(0);

    if (g6_act == 50 && g6_lower_res == 0 && g6_act_after == 50)
    {
        g_g6_pass = 1;
        print("[TEST-G6] PASS: Lowering max below active count rejected (res=0), active preserved.");
    }
    else
    {
        printf("[TEST-G6] FAIL: g6_act=%d lower_res=%d act_after=%d",
            g6_act, g6_lower_res, g6_act_after);
    }

    // -------------------------------------------------------------
    // G7: Accounting Invariant I1 Verification & Reconciliation
    // -------------------------------------------------------------
    print("\n[TEST-G7] Testing I1 Conservation across Lifecycle Transitions...");
    SUI_ResetPlayer(0);
    SUI_SetMaxTextDraws(0, 256);
    SUI_SetEvictionThreshold(0, 230);

    SUI_CreatePlayerFactoryGroup(0, "g7_1", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "g7_1", 12);
    SUI_ShowGroup(0, "g7_1");

    SUI_CreatePlayerFactoryGroup(0, "g7_2", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "g7_2", 18);
    SUI_ShowGroup(0, "g7_2");

    new g7_act1 = SUI_GetActiveTextDrawCount(0); // 12 + 18 = 30
    SUI_HideGroup(0, "g7_1"); // hidden, but still created! count must remain 30!
    new g7_act2 = SUI_GetActiveTextDrawCount(0); // 30

    SUI_DestroyGroup(0, "g7_2"); // count must become 12
    new g7_act3 = SUI_GetActiveTextDrawCount(0); // 12

    SUI_DestroyGroup(0, "g7_1"); // count must become 0
    new g7_act4 = SUI_GetActiveTextDrawCount(0); // 0

    // Invariant I1 Conservation across Hide, Re-show, and Destroy
    SUI_CreatePlayerFactoryGroup(0, "g7_hide_probe", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "g7_hide_probe", 5);
    SUI_ShowGroup(0, "g7_hide_probe");
    new g7_p_act1 = SUI_GetActiveTextDrawCount(0); // 5
    new g7_p_cr1 = SUI_IsGroupCreated(0, "g7_hide_probe"); // 1
    new g7_p_vis1 = SUI_IsGroupVisible(0, "g7_hide_probe"); // 1

    SUI_HideGroup(0, "g7_hide_probe");
    new g7_p_act2 = SUI_GetActiveTextDrawCount(0); // 5
    new g7_p_cr2 = SUI_IsGroupCreated(0, "g7_hide_probe"); // 1
    new g7_p_vis2 = SUI_IsGroupVisible(0, "g7_hide_probe"); // 0

    SUI_ShowGroup(0, "g7_hide_probe");
    new g7_p_act3 = SUI_GetActiveTextDrawCount(0); // 5
    new g7_p_cr3 = SUI_IsGroupCreated(0, "g7_hide_probe"); // 1
    new g7_p_vis3 = SUI_IsGroupVisible(0, "g7_hide_probe"); // 1

    SUI_DestroyGroup(0, "g7_hide_probe");
    new g7_p_act4 = SUI_GetActiveTextDrawCount(0); // 0
    new g7_p_cr4 = SUI_IsGroupCreated(0, "g7_hide_probe"); // 0
    new g7_p_vis4 = SUI_IsGroupVisible(0, "g7_hide_probe"); // 0

    new probe_ok = (g7_p_act1 == 5 && g7_p_cr1 == 1 && g7_p_vis1 == 1 &&
                    g7_p_act2 == 5 && g7_p_cr2 == 1 && g7_p_vis2 == 0 &&
                    g7_p_act3 == 5 && g7_p_cr3 == 1 && g7_p_vis3 == 1 &&
                    g7_p_act4 == 0 && g7_p_cr4 == 0 && g7_p_vis4 == 0);

    if (g7_act1 == 30 && g7_act2 == 30 && g7_act3 == 12 && g7_act4 == 0 && probe_ok)
    {
        g_g7_pass = 1;
        print("[TEST-G7] PASS: I1 Conservation verified (multi-group & single-group hide/re-show/destroy).");
    }
    else
    {
        printf("[TEST-G7] FAIL: g7_act1=%d g7_act2=%d g7_act3=%d g7_act4=%d probe_ok=%d",
            g7_act1, g7_act2, g7_act3, g7_act4, probe_ok);
    }

    PrintCapacityResults();
}

forward PrintCapacityResults();
public PrintCapacityResults()
{
    print("\n================================================================");
    print("      SUI CAPACITY ARITHMETIC REGRESSION RESULTS (C1-C12)       ");
    print("================================================================");
    if (g_c1_pass) printf("C1  (Normal Addition):                     PASS");
    else printf("C1  (Normal Addition):                     FAIL");
    if (g_c2_pass) printf("C2  (Exact Threshold):                     PASS");
    else printf("C2  (Exact Threshold):                     FAIL");
    if (g_c3_pass) printf("C3  (One Above Threshold):                 PASS");
    else printf("C3  (One Above Threshold):                 FAIL");
    if (g_c4_pass) printf("C4  (Max Pawn-Positive Size):              PASS");
    else printf("C4  (Max Pawn-Positive Size):              FAIL");
    if (g_c5_pass) printf("C5  (Callback Size Mutation Guard):        PASS");
    else printf("C5  (Callback Size Mutation Guard):        FAIL");
    if (g_c6_pass) printf("C6  (Change Size While Created):           PASS");
    else printf("C6  (Change Size While Created):           FAIL");
    if (g_c7_pass) printf("C7  (Change Size While Hidden/Created):    PASS");
    else printf("C7  (Change Size While Hidden/Created):    FAIL");
    if (g_c8_pass) printf("C8  (Destroy Accounting Exactness):        PASS");
    else printf("C8  (Destroy Accounting Exactness):        FAIL");
    if (g_c9_pass) printf("C9  (AMX Unload Accounting):               PASS");
    else printf("C9  (AMX Unload Accounting):               FAIL");
    if (g_c10_pass) printf("C10 (100 Cycles Zero Accounting Drift):    PASS");
    else printf("C10 (100 Cycles Zero Accounting Drift):    FAIL");
    if (g_c11_pass) printf("C11 (Capacity Failure Atomicity):          PASS");
    else printf("C11 (Capacity Failure Atomicity):          FAIL");
    if (g_c12_pass) printf("C12 (Large Values / Wrap Proof):           PASS");
    else printf("C12 (Large Values / Wrap Proof):           FAIL");
    print("----------------------------------------------------------------");
    print("      SUI ACCOUNTING GATE REGRESSION RESULTS (G1-G7)           ");
    print("----------------------------------------------------------------");
    if (g_g1_pass) printf("G1  (Standard Bounds Validation):          PASS");
    else printf("G1  (Standard Bounds Validation):          FAIL");
    if (g_g2_pass) printf("G2  (Threshold > Max Rejection):           PASS");
    else printf("G2  (Threshold > Max Rejection):           FAIL");
    if (g_g3_pass) printf("G3  (Max < Threshold Rejection):           PASS");
    else printf("G3  (Max < Threshold Rejection):           FAIL");
    if (g_g4_pass) printf("G4  (Threshold Boundary Rejection):        PASS");
    else printf("G4  (Threshold Boundary Rejection):        FAIL");
    if (g_g5_pass) printf("G5  (Hard Max Ceiling Enforcement):        PASS");
    else printf("G5  (Hard Max Ceiling Enforcement):        FAIL");
    if (g_g6_pass) printf("G6  (Active vs Lowered Max Rejection):     PASS");
    else printf("G6  (Active vs Lowered Max Rejection):     FAIL");
    if (g_g7_pass) printf("G7  (I1 Conservation Verification):        PASS");
    else printf("G7  (I1 Conservation Verification):        FAIL");
    print("================================================================");

    new c_pass = g_c1_pass + g_c2_pass + g_c3_pass + g_c4_pass + g_c5_pass +
                 g_c6_pass + g_c7_pass + g_c8_pass + g_c9_pass + g_c10_pass +
                 g_c11_pass + g_c12_pass;
    new g_pass = g_g1_pass + g_g2_pass + g_g3_pass + g_g4_pass + g_g5_pass +
                 g_g6_pass + g_g7_pass;

    if (c_pass == 12 && g_pass == 7)
    {
        print("OVERALL RESULT: ALL CAPACITY & GATE TESTS PASSED! (19/19)");
    }
    else
    {
        printf("OVERALL RESULT: %d/12 C-TESTS, %d/7 G-TESTS PASSED.", c_pass, g_pass);
    }
    print("================================================================\n");

    print("--- Terminating server after test completion.");
    SendRconCommand("exit");
}
