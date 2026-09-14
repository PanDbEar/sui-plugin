#include <a_samp>
#include "../../pawn/sui.inc"

new g_test_e1_pass = 0;
new g_test_e2_pass = 0;
new g_test_e3_pass = 0;
new g_test_e4_pass = 0;
new g_test_e5_pass = 0;
new g_test_e6_pass = 0;
new g_test_e7_pass = 0;
new g_test_e8_pass = 0;
new g_test_e9_pass = 0;
new g_test_e10_pass = 0;
new g_test_e11_pass = 0;
new g_test_e12_pass = 0;
new g_test_e13_pass = 0;
new g_test_e14_pass = 0;

main()
{
}

// ============================================================================
// DUMMY / GENERAL CALLBACKS
// ============================================================================
forward OnDummy_Create(playerid); public OnDummy_Create(playerid) { return 1; }
forward OnDummy_Destroy(playerid); public OnDummy_Destroy(playerid) { return 1; }
forward OnDummy_Show(playerid); public OnDummy_Show(playerid) { return 1; }
forward OnDummy_Hide(playerid); public OnDummy_Hide(playerid) { return 1; }

// ============================================================================
// E1 CALLBACKS
// ============================================================================
new g_e1_cand_destroy_calls = 0;
forward OnE1_CandCreate(playerid); public OnE1_CandCreate(playerid) { return 1; }
forward OnE1_CandDestroy(playerid); public OnE1_CandDestroy(playerid) { g_e1_cand_destroy_calls++; return 1; }
forward OnE1_CandShow(playerid); public OnE1_CandShow(playerid) { return 1; }
forward OnE1_CandHide(playerid); public OnE1_CandHide(playerid) { return 1; }

forward OnE1_ReqCreate(playerid); public OnE1_ReqCreate(playerid) { return 1; }
forward OnE1_ReqDestroy(playerid); public OnE1_ReqDestroy(playerid) { return 1; }
forward OnE1_ReqShow(playerid); public OnE1_ReqShow(playerid) { return 1; }
forward OnE1_ReqHide(playerid); public OnE1_ReqHide(playerid) { return 1; }

// ============================================================================
// E2 CALLBACKS
// ============================================================================
new g_e2_canda_destroy_calls = 0;
new g_e2_candb_destroy_calls = 0;
forward OnE2_CandACreate(playerid); public OnE2_CandACreate(playerid) { return 1; }
forward OnE2_CandADestroy(playerid); public OnE2_CandADestroy(playerid) { g_e2_canda_destroy_calls++; return 1; }
forward OnE2_CandAShow(playerid); public OnE2_CandAShow(playerid) { return 1; }
forward OnE2_CandAHide(playerid); public OnE2_CandAHide(playerid) { return 1; }

forward OnE2_CandBCreate(playerid); public OnE2_CandBCreate(playerid) { return 1; }
forward OnE2_CandBDestroy(playerid); public OnE2_CandBDestroy(playerid) { g_e2_candb_destroy_calls++; return 1; }
forward OnE2_CandBShow(playerid); public OnE2_CandBShow(playerid) { return 1; }
forward OnE2_CandBHide(playerid); public OnE2_CandBHide(playerid) { return 1; }

forward OnE2_ReqCreate(playerid); public OnE2_ReqCreate(playerid) { return 1; }
forward OnE2_ReqDestroy(playerid); public OnE2_ReqDestroy(playerid) { return 1; }
forward OnE2_ReqShow(playerid); public OnE2_ReqShow(playerid) { return 1; }
forward OnE2_ReqHide(playerid); public OnE2_ReqHide(playerid) { return 1; }

// ============================================================================
// E3 CALLBACKS
// ============================================================================
new g_e3_c1_destroy_calls = 0;
new g_e3_c2_destroy_calls = 0;
new g_e3_c3_destroy_calls = 0;
forward OnE3_C1Destroy(playerid); public OnE3_C1Destroy(playerid) { g_e3_c1_destroy_calls++; return 1; }
forward OnE3_C2Destroy(playerid); public OnE3_C2Destroy(playerid) { g_e3_c2_destroy_calls++; return 1; }
forward OnE3_C3Destroy(playerid); public OnE3_C3Destroy(playerid) { g_e3_c3_destroy_calls++; return 1; }

// ============================================================================
// E4 CALLBACKS
// ============================================================================
new g_e4_c1_destroy_calls = 0;
new g_e4_c2_destroy_calls = 0;
new g_e4_c3_destroy_calls = 0;
forward OnE4_C1Destroy(playerid); public OnE4_C1Destroy(playerid) { g_e4_c1_destroy_calls++; return 1; }
forward OnE4_C2Destroy(playerid); public OnE4_C2Destroy(playerid) { g_e4_c2_destroy_calls++; return 1; }
forward OnE4_C3Destroy(playerid); public OnE4_C3Destroy(playerid) { g_e4_c3_destroy_calls++; return 1; }

// ============================================================================
// E5 CALLBACKS
// ============================================================================
new g_e5_low_destroy_calls = 0;
new g_e5_norm_destroy_calls = 0;
new g_e5_high_destroy_calls = 0;
forward OnE5_LowDestroy(playerid); public OnE5_LowDestroy(playerid) { g_e5_low_destroy_calls++; return 1; }
forward OnE5_NormDestroy(playerid); public OnE5_NormDestroy(playerid) { g_e5_norm_destroy_calls++; return 1; }
forward OnE5_HighDestroy(playerid); public OnE5_HighDestroy(playerid) { g_e5_high_destroy_calls++; return 1; }

// ============================================================================
// E6 CALLBACKS
// ============================================================================
new g_e6_older_destroy_calls = 0;
new g_e6_newer_destroy_calls = 0;
forward OnE6_OlderDestroy(playerid); public OnE6_OlderDestroy(playerid) { g_e6_older_destroy_calls++; return 1; }
forward OnE6_NewerDestroy(playerid); public OnE6_NewerDestroy(playerid) { g_e6_newer_destroy_calls++; return 1; }

// ============================================================================
// E7 CALLBACKS
// ============================================================================
new g_e7_alpha_destroy_calls = 0;
new g_e7_zeta_destroy_calls = 0;
forward OnE7_AlphaDestroy(playerid); public OnE7_AlphaDestroy(playerid) { g_e7_alpha_destroy_calls++; return 1; }
forward OnE7_ZetaDestroy(playerid); public OnE7_ZetaDestroy(playerid) { g_e7_zeta_destroy_calls++; return 1; }

// ============================================================================
// E8, E9, E10 CALLBACKS
// ============================================================================
new g_e8_crit_destroy_calls = 0;
forward OnE8_CritDestroy(playerid); public OnE8_CritDestroy(playerid) { g_e8_crit_destroy_calls++; return 1; }

new g_e9_vis_destroy_calls = 0;
forward OnE9_VisDestroy(playerid); public OnE9_VisDestroy(playerid) { g_e9_vis_destroy_calls++; return 1; }

new g_e10_noevict_destroy_calls = 0;
forward OnE10_NoEvictDestroy(playerid); public OnE10_NoEvictDestroy(playerid) { g_e10_noevict_destroy_calls++; return 1; }

// ============================================================================
// E11 CALLBACKS
// ============================================================================
new g_e11_req_create_calls = 0;
forward OnE11_ReqCreate(playerid);
public OnE11_ReqCreate(playerid)
{
    g_e11_req_create_calls++;
    return 1;
}

// ============================================================================
// E12 CALLBACKS (Missing / failing destroy callback)
// ============================================================================
// Intentionally no public OnE12_BadDestroy forward/implementation so AMX returns not found/error

// ============================================================================
// E13 CALLBACKS (Re-entrant state mutation during eviction)
// ============================================================================
new g_e13_canda_destroy_calls = 0;
new g_e13_candb_destroy_calls = 0;
forward OnE13_CandADestroy(playerid);
public OnE13_CandADestroy(playerid)
{
    g_e13_canda_destroy_calls++;
    // Re-entrantly mutate cand_b to be non-evictable during eviction of cand_a
    SUI_SetGroupEvictable(playerid, "e13_cand_b", false);
    return 1;
}
forward OnE13_CandBDestroy(playerid);
public OnE13_CandBDestroy(playerid)
{
    g_e13_candb_destroy_calls++;
    return 1;
}

// ============================================================================
// E14 CALLBACKS
// ============================================================================
forward FS_RegisterE14(playerid);
forward FS_ShowHideE14(playerid);
forward FS_GetDestroyCalls();

public OnGameModeInit()
{
    print("\n================================================================");
    print("      SUI PHASE 9: CAPACITY EVICTION PREFLIGHT TEST SUITE       ");
    print("================================================================\n");

    // -------------------------------------------------------------
    // E1: Single Candidate Insufficient Capacity (Zero Destruction)
    // -------------------------------------------------------------
    print("[TEST-E1] Testing Single Candidate Insufficient Capacity...");
    SUI_ResetPlayer(0);
    SUI_SetMaxTextDraws(0, 100);
    SUI_SetEvictionThreshold(0, 100);

    // Visible background group (size 60)
    SUI_CreatePlayerFactoryGroup(0, "e1_bg", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e1_bg", 60);
    SUI_ShowGroup(0, "e1_bg"); // active = 60

    // Hidden candidate group (size 20)
    g_e1_cand_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "e1_cand", "OnE1_CandCreate", "OnE1_CandDestroy", "OnE1_CandShow", "OnE1_CandHide");
    SUI_SetGroupSize(0, "e1_cand", 20);
    SUI_SetGroupPriority(0, "e1_cand", SUI_PRIORITY_LOW);
    SUI_SetGroupEvictable(0, "e1_cand", true);
    SUI_ShowGroup(0, "e1_cand");
    SUI_HideGroup(0, "e1_cand"); // active = 80, eligible = 20

    // Request group (size 50). Total projected: 80 + 50 = 130. Needed = 30. Eligible = 20 < 30!
    SUI_CreatePlayerFactoryGroup(0, "e1_req", "OnE1_ReqCreate", "OnE1_ReqDestroy", "OnE1_ReqShow", "OnE1_ReqHide");
    SUI_SetGroupSize(0, "e1_req", 50);

    new e1_show_res = SUI_ShowGroup(0, "e1_req");
    new e1_cand_cr = SUI_IsGroupCreated(0, "e1_cand");
    new e1_req_cr = SUI_IsGroupCreated(0, "e1_req");
    new e1_act = SUI_GetActiveTextDrawCount(0);

    if (e1_show_res == 0 &&
        g_e1_cand_destroy_calls == 0 &&
        e1_cand_cr == 1 &&
        e1_req_cr == 0 &&
        e1_act == 80)
    {
        g_test_e1_pass = 1;
        print("[TEST-E1] PASS: Insufficient capacity rejected with zero candidate destruction.");
    }
    else
    {
        printf("[TEST-E1] FAIL: show_res=%d dest_c=%d cand_cr=%d req_cr=%d act=%d",
            e1_show_res, g_e1_cand_destroy_calls, e1_cand_cr, e1_req_cr, e1_act);
    }
    SUI_ResetPlayer(0);

    // -------------------------------------------------------------
    // E2: Multiple Candidates Insufficient Capacity (Zero Destruction)
    // -------------------------------------------------------------
    print("\n[TEST-E2] Testing Multiple Candidates Insufficient Capacity...");
    SUI_ResetPlayer(0);
    SUI_SetMaxTextDraws(0, 100);
    SUI_SetEvictionThreshold(0, 100);

    SUI_CreatePlayerFactoryGroup(0, "e2_bg", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e2_bg", 60);
    SUI_ShowGroup(0, "e2_bg"); // active = 60

    g_e2_canda_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "e2_cand_a", "OnE2_CandACreate", "OnE2_CandADestroy", "OnE2_CandAShow", "OnE2_CandAHide");
    SUI_SetGroupSize(0, "e2_cand_a", 10);
    SUI_SetGroupPriority(0, "e2_cand_a", SUI_PRIORITY_LOW);
    SUI_SetGroupEvictable(0, "e2_cand_a", true);
    SUI_ShowGroup(0, "e2_cand_a");
    SUI_HideGroup(0, "e2_cand_a"); // active = 70

    g_e2_candb_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "e2_cand_b", "OnE2_CandBCreate", "OnE2_CandBDestroy", "OnE2_CandBShow", "OnE2_CandBHide");
    SUI_SetGroupSize(0, "e2_cand_b", 10);
    SUI_SetGroupPriority(0, "e2_cand_b", SUI_PRIORITY_LOW);
    SUI_SetGroupEvictable(0, "e2_cand_b", true);
    SUI_ShowGroup(0, "e2_cand_b");
    SUI_HideGroup(0, "e2_cand_b"); // active = 80, eligible = 20

    // Request group (size 45). Projected: 80 + 45 = 125. Needed = 25. Eligible = 20 < 25!
    SUI_CreatePlayerFactoryGroup(0, "e2_req", "OnE2_ReqCreate", "OnE2_ReqDestroy", "OnE2_ReqShow", "OnE2_ReqHide");
    SUI_SetGroupSize(0, "e2_req", 45);

    new e2_show_res = SUI_ShowGroup(0, "e2_req");
    new e2_canda_cr = SUI_IsGroupCreated(0, "e2_cand_a");
    new e2_candb_cr = SUI_IsGroupCreated(0, "e2_cand_b");
    new e2_req_cr = SUI_IsGroupCreated(0, "e2_req");
    new e2_act = SUI_GetActiveTextDrawCount(0);

    if (e2_show_res == 0 &&
        g_e2_canda_destroy_calls == 0 &&
        g_e2_candb_destroy_calls == 0 &&
        e2_canda_cr == 1 &&
        e2_candb_cr == 1 &&
        e2_req_cr == 0 &&
        e2_act == 80)
    {
        g_test_e2_pass = 1;
        print("[TEST-E2] PASS: Multi-candidate insufficient capacity rejected with zero destruction.");
    }
    else
    {
        printf("[TEST-E2] FAIL: show_res=%d a_dest=%d b_dest=%d a_cr=%d b_cr=%d req_cr=%d act=%d",
            e2_show_res, g_e2_canda_destroy_calls, g_e2_candb_destroy_calls, e2_canda_cr, e2_candb_cr, e2_req_cr, e2_act);
    }
    SUI_ResetPlayer(0);

    // -------------------------------------------------------------
    // E3: Minimal Eviction Count (No Over-Eviction)
    // -------------------------------------------------------------
    print("\n[TEST-E3] Testing Minimal Eviction Count (No Over-Eviction)...");
    SUI_ResetPlayer(0);
    SUI_SetMaxTextDraws(0, 100);
    SUI_SetEvictionThreshold(0, 100);

    g_e3_c1_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "e3_c1", "OnDummy_Create", "OnE3_C1Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e3_c1", 20);
    SUI_SetGroupPriority(0, "e3_c1", SUI_PRIORITY_LOW);
    SUI_SetGroupEvictable(0, "e3_c1", true);
    SUI_ShowGroup(0, "e3_c1");
    SUI_HideGroup(0, "e3_c1");

    g_e3_c2_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "e3_c2", "OnDummy_Create", "OnE3_C2Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e3_c2", 20);
    SUI_SetGroupPriority(0, "e3_c2", SUI_PRIORITY_LOW);
    SUI_SetGroupEvictable(0, "e3_c2", true);
    SUI_ShowGroup(0, "e3_c2");
    SUI_HideGroup(0, "e3_c2");

    g_e3_c3_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "e3_c3", "OnDummy_Create", "OnE3_C3Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e3_c3", 20);
    SUI_SetGroupPriority(0, "e3_c3", SUI_PRIORITY_LOW);
    SUI_SetGroupEvictable(0, "e3_c3", true);
    SUI_ShowGroup(0, "e3_c3");
    SUI_HideGroup(0, "e3_c3"); // active = 60

    // Request group (size 50). Projected: 60 + 50 = 110. Needed = 10.
    // Evicting e3_c1 frees 20 >= 10. Only e3_c1 should be evicted!
    SUI_CreatePlayerFactoryGroup(0, "e3_req", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e3_req", 50);

    new e3_show_res = SUI_ShowGroup(0, "e3_req");
    new e3_c1_cr = SUI_IsGroupCreated(0, "e3_c1");
    new e3_c2_cr = SUI_IsGroupCreated(0, "e3_c2");
    new e3_c3_cr = SUI_IsGroupCreated(0, "e3_c3");
    new e3_act = SUI_GetActiveTextDrawCount(0); // 20 + 20 + 50 = 90

    if (e3_show_res == 1 &&
        g_e3_c1_destroy_calls == 1 &&
        g_e3_c2_destroy_calls == 0 &&
        g_e3_c3_destroy_calls == 0 &&
        e3_c1_cr == 0 &&
        e3_c2_cr == 1 &&
        e3_c3_cr == 1 &&
        e3_act == 90)
    {
        g_test_e3_pass = 1;
        print("[TEST-E3] PASS: Minimal eviction executed; exactly one candidate evicted, no over-eviction.");
    }
    else
    {
        printf("[TEST-E3] FAIL: show_res=%d c1_dest=%d c2_dest=%d c3_dest=%d c1_cr=%d c2_cr=%d c3_cr=%d act=%d",
            e3_show_res, g_e3_c1_destroy_calls, g_e3_c2_destroy_calls, g_e3_c3_destroy_calls,
            e3_c1_cr, e3_c2_cr, e3_c3_cr, e3_act);
    }
    SUI_ResetPlayer(0);

    // -------------------------------------------------------------
    // E4: Multi-Candidate Eviction in Deterministic Order
    // -------------------------------------------------------------
    print("\n[TEST-E4] Testing Multi-Candidate Eviction in Deterministic Order...");
    SUI_ResetPlayer(0);
    SUI_SetMaxTextDraws(0, 100);
    SUI_SetEvictionThreshold(0, 100);

    g_e4_c1_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "e4_c1", "OnDummy_Create", "OnE4_C1Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e4_c1", 15);
    SUI_SetGroupPriority(0, "e4_c1", SUI_PRIORITY_LOW);
    SUI_SetGroupEvictable(0, "e4_c1", true);
    SUI_ShowGroup(0, "e4_c1");
    SUI_HideGroup(0, "e4_c1");

    g_e4_c2_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "e4_c2", "OnDummy_Create", "OnE4_C2Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e4_c2", 15);
    SUI_SetGroupPriority(0, "e4_c2", SUI_PRIORITY_LOW);
    SUI_SetGroupEvictable(0, "e4_c2", true);
    SUI_ShowGroup(0, "e4_c2");
    SUI_HideGroup(0, "e4_c2");

    g_e4_c3_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "e4_c3", "OnDummy_Create", "OnE4_C3Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e4_c3", 30);
    SUI_SetGroupPriority(0, "e4_c3", SUI_PRIORITY_NORMAL);
    SUI_SetGroupEvictable(0, "e4_c3", true);
    SUI_ShowGroup(0, "e4_c3");
    SUI_HideGroup(0, "e4_c3"); // active = 60

    // Request group (size 65). Projected: 60 + 65 = 125. Needed = 25.
    // e4_c1 (15) + e4_c2 (15) = 30 >= 25. e4_c3 (NORMAL) must be preserved!
    SUI_CreatePlayerFactoryGroup(0, "e4_req", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e4_req", 65);

    new e4_show_res = SUI_ShowGroup(0, "e4_req");
    new e4_c1_cr = SUI_IsGroupCreated(0, "e4_c1");
    new e4_c2_cr = SUI_IsGroupCreated(0, "e4_c2");
    new e4_c3_cr = SUI_IsGroupCreated(0, "e4_c3");
    new e4_act = SUI_GetActiveTextDrawCount(0); // 30 + 65 = 95

    if (e4_show_res == 1 &&
        g_e4_c1_destroy_calls == 1 &&
        g_e4_c2_destroy_calls == 1 &&
        g_e4_c3_destroy_calls == 0 &&
        e4_c1_cr == 0 &&
        e4_c2_cr == 0 &&
        e4_c3_cr == 1 &&
        e4_act == 95)
    {
        g_test_e4_pass = 1;
        print("[TEST-E4] PASS: Multi-candidate eviction succeeded; LOW candidates evicted, NORMAL candidate preserved.");
    }
    else
    {
        printf("[TEST-E4] FAIL: show_res=%d c1_dest=%d c2_dest=%d c3_dest=%d c1_cr=%d c2_cr=%d c3_cr=%d act=%d",
            e4_show_res, g_e4_c1_destroy_calls, g_e4_c2_destroy_calls, g_e4_c3_destroy_calls,
            e4_c1_cr, e4_c2_cr, e4_c3_cr, e4_act);
    }
    SUI_ResetPlayer(0);

    // -------------------------------------------------------------
    // E5: Priority Ordering (LOW before NORMAL before HIGH)
    // -------------------------------------------------------------
    print("\n[TEST-E5] Testing Priority Ordering...");
    SUI_ResetPlayer(0);
    SUI_SetMaxTextDraws(0, 100);
    SUI_SetEvictionThreshold(0, 100);

    g_e5_high_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "e5_high", "OnDummy_Create", "OnE5_HighDestroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e5_high", 25);
    SUI_SetGroupPriority(0, "e5_high", SUI_PRIORITY_HIGH);
    SUI_SetGroupEvictable(0, "e5_high", true);
    SUI_ShowGroup(0, "e5_high");
    SUI_HideGroup(0, "e5_high");

    g_e5_norm_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "e5_norm", "OnDummy_Create", "OnE5_NormDestroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e5_norm", 25);
    SUI_SetGroupPriority(0, "e5_norm", SUI_PRIORITY_NORMAL);
    SUI_SetGroupEvictable(0, "e5_norm", true);
    SUI_ShowGroup(0, "e5_norm");
    SUI_HideGroup(0, "e5_norm");

    g_e5_low_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "e5_low", "OnDummy_Create", "OnE5_LowDestroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e5_low", 25);
    SUI_SetGroupPriority(0, "e5_low", SUI_PRIORITY_LOW);
    SUI_SetGroupEvictable(0, "e5_low", true);
    SUI_ShowGroup(0, "e5_low");
    SUI_HideGroup(0, "e5_low"); // active = 75

    // Request group (size 35). Projected: 75 + 35 = 110. Needed = 10.
    // e5_low should be evicted despite being created most recently!
    SUI_CreatePlayerFactoryGroup(0, "e5_req", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e5_req", 35);

    new e5_show_res = SUI_ShowGroup(0, "e5_req");
    new e5_low_cr = SUI_IsGroupCreated(0, "e5_low");
    new e5_norm_cr = SUI_IsGroupCreated(0, "e5_norm");
    new e5_high_cr = SUI_IsGroupCreated(0, "e5_high");
    new e5_act = SUI_GetActiveTextDrawCount(0); // 25 + 25 + 35 = 85

    if (e5_show_res == 1 &&
        g_e5_low_destroy_calls == 1 &&
        g_e5_norm_destroy_calls == 0 &&
        g_e5_high_destroy_calls == 0 &&
        e5_low_cr == 0 &&
        e5_norm_cr == 1 &&
        e5_high_cr == 1 &&
        e5_act == 85)
    {
        g_test_e5_pass = 1;
        print("[TEST-E5] PASS: Priority ordering respected; LOW priority evicted first.");
    }
    else
    {
        printf("[TEST-E5] FAIL: show_res=%d low_d=%d norm_d=%d high_d=%d low_cr=%d norm_cr=%d high_cr=%d act=%d",
            e5_show_res, g_e5_low_destroy_calls, g_e5_norm_destroy_calls, g_e5_high_destroy_calls,
            e5_low_cr, e5_norm_cr, e5_high_cr, e5_act);
    }
    SUI_ResetPlayer(0);

    // -------------------------------------------------------------
    // E6: Age Ordering Tie-Breaker (Older Before Newer)
    // -------------------------------------------------------------
    print("\n[TEST-E6] Testing Age Ordering Tie-Breaker...");
    SUI_CleanupPlayer(0);
    SUI_SetMaxTextDraws(0, 100);
    SUI_SetEvictionThreshold(0, 100);

    g_e6_older_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "z_older", "OnDummy_Create", "OnE6_OlderDestroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "z_older", 25);
    SUI_SetGroupPriority(0, "z_older", SUI_PRIORITY_NORMAL);
    SUI_SetGroupEvictable(0, "z_older", true);
    SUI_ShowGroup(0, "z_older");
    SUI_HideGroup(0, "z_older");

    new e6_tick = GetTickCount();
    while (GetTickCount() - e6_tick < 20) {}

    g_e6_newer_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "a_newer", "OnDummy_Create", "OnE6_NewerDestroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "a_newer", 25);
    SUI_SetGroupPriority(0, "a_newer", SUI_PRIORITY_NORMAL);
    SUI_SetGroupEvictable(0, "a_newer", true);
    SUI_ShowGroup(0, "a_newer");
    SUI_HideGroup(0, "a_newer");

    // Request group (size 60). Projected: 50 + 60 = 110. Needed = 10.
    // In alphabetical order "a_newer" < "z_older", but "z_older" is 20ms older!
    // Age ordering MUST take precedence over alphabetical tie-breaker!
    SUI_CreatePlayerFactoryGroup(0, "e6_req", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e6_req", 60);

    new e6_show_res = SUI_ShowGroup(0, "e6_req");
    new e6_older_cr = SUI_IsGroupCreated(0, "z_older");
    new e6_newer_cr = SUI_IsGroupCreated(0, "a_newer");
    new e6_act = SUI_GetActiveTextDrawCount(0); // 25 + 60 = 85

    if (e6_show_res == 1 &&
        g_e6_older_destroy_calls == 1 &&
        g_e6_newer_destroy_calls == 0 &&
        e6_older_cr == 0 &&
        e6_newer_cr == 1 &&
        e6_act == 85)
    {
        g_test_e6_pass = 1;
        print("[TEST-E6] PASS: Age ordering tie-breaker respected; older candidate evicted first.");
    }
    else
    {
        printf("[TEST-E6] FAIL: show_res=%d older_d=%d newer_d=%d older_cr=%d newer_cr=%d act=%d",
            e6_show_res, g_e6_older_destroy_calls, g_e6_newer_destroy_calls, e6_older_cr, e6_newer_cr, e6_act);
    }
    SUI_CleanupPlayer(0);

    // -------------------------------------------------------------
    // E7: Alphabetical Tie-Breaker for Identical Priority and Age
    // -------------------------------------------------------------
    print("\n[TEST-E7] Testing Alphabetical Tie-Breaker...");
    SUI_ResetPlayer(0);
    SUI_SetMaxTextDraws(0, 100);
    SUI_SetEvictionThreshold(0, 100);

    g_e7_alpha_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "cand_alpha", "OnDummy_Create", "OnE7_AlphaDestroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "cand_alpha", 25);
    SUI_SetGroupPriority(0, "cand_alpha", SUI_PRIORITY_NORMAL);
    SUI_SetGroupEvictable(0, "cand_alpha", true);

    g_e7_zeta_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "cand_zeta", "OnDummy_Create", "OnE7_ZetaDestroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "cand_zeta", 25);
    SUI_SetGroupPriority(0, "cand_zeta", SUI_PRIORITY_NORMAL);
    SUI_SetGroupEvictable(0, "cand_zeta", true);

    SUI_ShowGroup(0, "cand_alpha");
    SUI_HideGroup(0, "cand_alpha");
    SUI_ShowGroup(0, "cand_zeta");
    SUI_HideGroup(0, "cand_zeta");

    // Request group (size 60). Projected: 50 + 60 = 110. Needed = 10.
    SUI_CreatePlayerFactoryGroup(0, "e7_req", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e7_req", 60);

    new e7_show_res = SUI_ShowGroup(0, "e7_req");
    new e7_alpha_cr = SUI_IsGroupCreated(0, "cand_alpha");
    new e7_zeta_cr = SUI_IsGroupCreated(0, "cand_zeta");
    new e7_act = SUI_GetActiveTextDrawCount(0); // 25 + 60 = 85

    if (e7_show_res == 1 &&
        g_e7_alpha_destroy_calls == 1 &&
        g_e7_zeta_destroy_calls == 0 &&
        e7_alpha_cr == 0 &&
        e7_zeta_cr == 1 &&
        e7_act == 85)
    {
        g_test_e7_pass = 1;
        print("[TEST-E7] PASS: Alphabetical tie-breaker respected; 'cand_alpha' evicted before 'cand_zeta'.");
    }
    else
    {
        printf("[TEST-E7] FAIL: show_res=%d alpha_d=%d zeta_d=%d alpha_cr=%d zeta_cr=%d act=%d",
            e7_show_res, g_e7_alpha_destroy_calls, g_e7_zeta_destroy_calls, e7_alpha_cr, e7_zeta_cr, e7_act);
    }
    SUI_ResetPlayer(0);

    // -------------------------------------------------------------
    // E8: Critical Priority Exclusion from Preflight and Eviction
    // -------------------------------------------------------------
    print("\n[TEST-E8] Testing Critical Priority Exclusion...");
    SUI_ResetPlayer(0);
    SUI_SetMaxTextDraws(0, 50);
    SUI_SetEvictionThreshold(0, 50);

    g_e8_crit_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "e8_crit", "OnDummy_Create", "OnE8_CritDestroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e8_crit", 50);
    SUI_SetGroupPriority(0, "e8_crit", SUI_PRIORITY_CRITICAL);
    SUI_SetGroupEvictable(0, "e8_crit", true);
    SUI_ShowGroup(0, "e8_crit");
    SUI_HideGroup(0, "e8_crit"); // active = 50

    // Request group (size 20). Projected: 50 + 20 = 70 > 50. Needed = 20.
    // e8_crit is CRITICAL -> excluded from preflight -> eligible = 0 < 20.
    SUI_CreatePlayerFactoryGroup(0, "e8_req", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e8_req", 20);

    new e8_show_res = SUI_ShowGroup(0, "e8_req");
    new e8_crit_cr = SUI_IsGroupCreated(0, "e8_crit");
    new e8_req_cr = SUI_IsGroupCreated(0, "e8_req");
    new e8_act = SUI_GetActiveTextDrawCount(0);

    if (e8_show_res == 0 &&
        g_e8_crit_destroy_calls == 0 &&
        e8_crit_cr == 1 &&
        e8_req_cr == 0 &&
        e8_act == 50)
    {
        g_test_e8_pass = 1;
        print("[TEST-E8] PASS: CRITICAL priority group excluded from preflight and eviction.");
    }
    else
    {
        printf("[TEST-E8] FAIL: show_res=%d crit_d=%d crit_cr=%d req_cr=%d act=%d",
            e8_show_res, g_e8_crit_destroy_calls, e8_crit_cr, e8_req_cr, e8_act);
    }
    SUI_ResetPlayer(0);

    // -------------------------------------------------------------
    // E9: Visible Group Exclusion from Preflight and Eviction
    // -------------------------------------------------------------
    print("\n[TEST-E9] Testing Visible Group Exclusion...");
    SUI_ResetPlayer(0);
    SUI_SetMaxTextDraws(0, 50);
    SUI_SetEvictionThreshold(0, 50);

    g_e9_vis_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "e9_vis", "OnDummy_Create", "OnE9_VisDestroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e9_vis", 50);
    SUI_SetGroupPriority(0, "e9_vis", SUI_PRIORITY_LOW);
    SUI_SetGroupEvictable(0, "e9_vis", true);
    SUI_ShowGroup(0, "e9_vis"); // visible = 1, active = 50

    SUI_CreatePlayerFactoryGroup(0, "e9_req", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e9_req", 20);

    new e9_show_res = SUI_ShowGroup(0, "e9_req");
    new e9_vis_cr = SUI_IsGroupCreated(0, "e9_vis");
    new e9_vis_vis = SUI_IsGroupVisible(0, "e9_vis");
    new e9_req_cr = SUI_IsGroupCreated(0, "e9_req");
    new e9_act = SUI_GetActiveTextDrawCount(0);

    if (e9_show_res == 0 &&
        g_e9_vis_destroy_calls == 0 &&
        e9_vis_cr == 1 &&
        e9_vis_vis == 1 &&
        e9_req_cr == 0 &&
        e9_act == 50)
    {
        g_test_e9_pass = 1;
        print("[TEST-E9] PASS: Visible group excluded from preflight and eviction.");
    }
    else
    {
        printf("[TEST-E9] FAIL: show_res=%d vis_d=%d vis_cr=%d vis_vis=%d req_cr=%d act=%d",
            e9_show_res, g_e9_vis_destroy_calls, e9_vis_cr, e9_vis_vis, e9_req_cr, e9_act);
    }
    SUI_ResetPlayer(0);

    // -------------------------------------------------------------
    // E10: Non-Evictable Flag Exclusion
    // -------------------------------------------------------------
    print("\n[TEST-E10] Testing Non-Evictable Flag Exclusion...");
    SUI_ResetPlayer(0);
    SUI_SetMaxTextDraws(0, 50);
    SUI_SetEvictionThreshold(0, 50);

    g_e10_noevict_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "e10_noevict", "OnDummy_Create", "OnE10_NoEvictDestroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e10_noevict", 50);
    SUI_SetGroupPriority(0, "e10_noevict", SUI_PRIORITY_LOW);
    SUI_SetGroupEvictable(0, "e10_noevict", false);
    SUI_ShowGroup(0, "e10_noevict");
    SUI_HideGroup(0, "e10_noevict"); // active = 50, evictable = false

    SUI_CreatePlayerFactoryGroup(0, "e10_req", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e10_req", 20);

    new e10_show_res = SUI_ShowGroup(0, "e10_req");
    new e10_cr = SUI_IsGroupCreated(0, "e10_noevict");
    new e10_req_cr = SUI_IsGroupCreated(0, "e10_req");
    new e10_act = SUI_GetActiveTextDrawCount(0);

    if (e10_show_res == 0 &&
        g_e10_noevict_destroy_calls == 0 &&
        e10_cr == 1 &&
        e10_req_cr == 0 &&
        e10_act == 50)
    {
        g_test_e10_pass = 1;
        print("[TEST-E10] PASS: Non-evictable group excluded from preflight and eviction.");
    }
    else
    {
        printf("[TEST-E10] FAIL: show_res=%d noevict_d=%d cr=%d req_cr=%d act=%d",
            e10_show_res, g_e10_noevict_destroy_calls, e10_cr, e10_req_cr, e10_act);
    }
    SUI_ResetPlayer(0);

    // -------------------------------------------------------------
    // E11: Executing Callback Guard Exclusion
    // -------------------------------------------------------------
    print("\n[TEST-E11] Testing Executing Callback Guard Exclusion...");
    SUI_ResetPlayer(0);
    SUI_SetMaxTextDraws(0, 50);
    SUI_SetEvictionThreshold(0, 50);

    // Requesting group cannot evict itself during ShowGroup -> EnsureCapacity
    g_e11_req_create_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "e11_req", "OnE11_ReqCreate", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e11_req", 60); // 60 > maxTextDraws(50)
    SUI_SetGroupPriority(0, "e11_req", SUI_PRIORITY_LOW);
    SUI_SetGroupEvictable(0, "e11_req", true);

    new e11_show_res = SUI_ShowGroup(0, "e11_req");
    new e11_req_cr = SUI_IsGroupCreated(0, "e11_req");
    new e11_act = SUI_GetActiveTextDrawCount(0);

    if (e11_show_res == 0 &&
        g_e11_req_create_calls == 0 &&
        e11_req_cr == 0 &&
        e11_act == 0)
    {
        g_test_e11_pass = 1;
        print("[TEST-E11] PASS: Executing callback guard properly excludes self from eviction.");
    }
    else
    {
        printf("[TEST-E11] FAIL: show_res=%d req_c=%d req_cr=%d act=%d",
            e11_show_res, g_e11_req_create_calls, e11_req_cr, e11_act);
    }
    SUI_ResetPlayer(0);

    // -------------------------------------------------------------
    // E12: Destroy Callback Failure Preserves Group & Doesn't Leak Accounting
    // -------------------------------------------------------------
    print("\n[TEST-E12] Testing Destroy Callback Failure Preservation...");
    SUI_ResetPlayer(0);
    SUI_SetMaxTextDraws(0, 50);
    SUI_SetEvictionThreshold(0, 50);

    // Register group with missing destroy callback "OnE12_NonExistentDestroy"
    SUI_CreatePlayerFactoryGroup(0, "e12_bad", "OnDummy_Create", "OnE12_NonExistentDestroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e12_bad", 50);
    SUI_SetGroupPriority(0, "e12_bad", SUI_PRIORITY_LOW);
    SUI_SetGroupEvictable(0, "e12_bad", true);
    SUI_ShowGroup(0, "e12_bad");
    SUI_HideGroup(0, "e12_bad"); // active = 50

    SUI_CreatePlayerFactoryGroup(0, "e12_req", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e12_req", 20);

    new e12_show_res = SUI_ShowGroup(0, "e12_req");
    new e12_bad_cr = SUI_IsGroupCreated(0, "e12_bad");
    new e12_req_cr = SUI_IsGroupCreated(0, "e12_req");
    new e12_act = SUI_GetActiveTextDrawCount(0);

    if (e12_show_res == 0 &&
        e12_bad_cr == 1 &&
        e12_req_cr == 0 &&
        e12_act == 50)
    {
        g_test_e12_pass = 1;
        print("[TEST-E12] PASS: Destroy callback failure safely preserved candidate and prevented accounting corruption.");
    }
    else
    {
        printf("[TEST-E12] FAIL: show_res=%d bad_cr=%d req_cr=%d act=%d",
            e12_show_res, e12_bad_cr, e12_req_cr, e12_act);
    }
    SUI_CleanupPlayer(0);

    // -------------------------------------------------------------
    // E13: Re-entrant State Mutation During Eviction (Safe Replanning)
    // -------------------------------------------------------------
    print("\n[TEST-E13] Testing Re-entrant State Mutation During Eviction...");
    SUI_CleanupPlayer(0);
    SUI_SetMaxTextDraws(0, 60);
    SUI_SetEvictionThreshold(0, 60);

    // Background group
    SUI_CreatePlayerFactoryGroup(0, "e13_bg", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e13_bg", 20);
    SUI_ShowGroup(0, "e13_bg"); // active = 20

    // Two candidates (20 each)
    g_e13_canda_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "e13_cand_a", "OnDummy_Create", "OnE13_CandADestroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e13_cand_a", 20);
    SUI_SetGroupPriority(0, "e13_cand_a", SUI_PRIORITY_LOW);
    SUI_SetGroupEvictable(0, "e13_cand_a", true);
    SUI_ShowGroup(0, "e13_cand_a");
    SUI_HideGroup(0, "e13_cand_a");

    new e13_tick = GetTickCount();
    while (GetTickCount() - e13_tick < 20) {}

    g_e13_candb_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "e13_cand_b", "OnDummy_Create", "OnE13_CandBDestroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e13_cand_b", 20);
    SUI_SetGroupPriority(0, "e13_cand_b", SUI_PRIORITY_LOW);
    SUI_SetGroupEvictable(0, "e13_cand_b", true);
    SUI_ShowGroup(0, "e13_cand_b");
    SUI_HideGroup(0, "e13_cand_b"); // active = 60

    // Request group (size 35). Projected: 60 + 35 = 95. Needed = 35.
    // Initial preflight: eligible = 20 + 20 = 40 >= 35.
    // e13_cand_a is evicted. In its cbDestroy, it sets e13_cand_b evictable = false!
    // Next replan: remaining eligible = 0 < remaining needed (15).
    // EnsureCapacity aborts safely!
    SUI_CreatePlayerFactoryGroup(0, "e13_req", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e13_req", 35);

    new e13_show_res = SUI_ShowGroup(0, "e13_req");
    new e13_canda_cr = SUI_IsGroupCreated(0, "e13_cand_a");
    new e13_candb_cr = SUI_IsGroupCreated(0, "e13_cand_b");
    new e13_candb_ev = SUI_IsGroupEvictable(0, "e13_cand_b");
    new e13_req_cr = SUI_IsGroupCreated(0, "e13_req");
    new e13_act = SUI_GetActiveTextDrawCount(0); // 20 (bg) + 20 (cand_b) = 40

    if (e13_show_res == 0 &&
        g_e13_canda_destroy_calls == 1 &&
        g_e13_candb_destroy_calls == 0 &&
        e13_canda_cr == 0 &&
        e13_candb_cr == 1 &&
        e13_candb_ev == 0 &&
        e13_req_cr == 0 &&
        e13_act == 40)
    {
        g_test_e13_pass = 1;
        print("[TEST-E13] PASS: Re-entrant mutation safely aborted subsequent eviction during replanning.");
    }
    else
    {
        printf("[TEST-E13] FAIL: show_res=%d a_dest=%d b_dest=%d a_cr=%d b_cr=%d b_ev=%d req_cr=%d act=%d",
            e13_show_res, g_e13_canda_destroy_calls, g_e13_candb_destroy_calls,
            e13_canda_cr, e13_candb_cr, e13_candb_ev, e13_req_cr, e13_act);
    }
    SUI_CleanupPlayer(0);

    // -------------------------------------------------------------
    // E14: Multi-AMX Ownership During Eviction
    // -------------------------------------------------------------
    print("\n[TEST-E14] Testing Multi-AMX Ownership During Eviction...");
    SUI_CleanupPlayer(0);
    SUI_SetMaxTextDraws(0, 30);
    SUI_SetEvictionThreshold(0, 30);

    // Filterscript registers and hides group (size 25, LOW priority)
    CallRemoteFunction("FS_RegisterE14", "d", 0);
    CallRemoteFunction("FS_ShowHideE14", "d", 0); // active = 25

    // Gamemode requests capacity of size 20. Projected: 25 + 20 = 45 > 30. Needed = 15.
    // FS group (25) is evicted. FS cbDestroy must be called in FS context!
    SUI_CreatePlayerFactoryGroup(0, "e14_gm_req", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide");
    SUI_SetGroupSize(0, "e14_gm_req", 20);

    new e14_show_res = SUI_ShowGroup(0, "e14_gm_req");
    new e14_fs_destroy_calls = CallRemoteFunction("FS_GetDestroyCalls", "");
    new e14_fs_cr = SUI_IsGroupCreated(0, "e14_fs_grp");
    new e14_gm_cr = SUI_IsGroupCreated(0, "e14_gm_req");
    new e14_gm_vis = SUI_IsGroupVisible(0, "e14_gm_req");
    new e14_act = SUI_GetActiveTextDrawCount(0); // 20

    if (e14_show_res == 1 &&
        e14_fs_destroy_calls == 1 &&
        e14_fs_cr == 0 &&
        e14_gm_cr == 1 &&
        e14_gm_vis == 1 &&
        e14_act == 20)
    {
        g_test_e14_pass = 1;
        print("[TEST-E14] PASS: Multi-AMX candidate evicted correctly in Filterscript AMX context.");
    }
    else
    {
        printf("[TEST-E14] FAIL: show_res=%d fs_dest=%d fs_cr=%d gm_cr=%d gm_vis=%d act=%d",
            e14_show_res, e14_fs_destroy_calls, e14_fs_cr, e14_gm_cr, e14_gm_vis, e14_act);
    }
    SUI_ResetPlayer(0);

    // =============================================================
    // RESULTS SUMMARY
    // =============================================================
    print("\n================================================================");
    print("           EVICTION PREFLIGHT TEST RESULTS SUMMARY             ");
    print("================================================================");
    printf("E1  (Single Candidate Insufficient Preflight):     %s", (g_test_e1_pass) ? ("PASS") : ("FAIL"));
    printf("E2  (Multi Candidate Insufficient Preflight):      %s", (g_test_e2_pass) ? ("PASS") : ("FAIL"));
    printf("E3  (Minimal Eviction Count / No Over-Eviction):   %s", (g_test_e3_pass) ? ("PASS") : ("FAIL"));
    printf("E4  (Multi-Candidate Eviction Determinism):        %s", (g_test_e4_pass) ? ("PASS") : ("FAIL"));
    printf("E5  (Priority Ordering LOW < NORMAL < HIGH):       %s", (g_test_e5_pass) ? ("PASS") : ("FAIL"));
    printf("E6  (Age Ordering Older Before Newer):             %s", (g_test_e6_pass) ? ("PASS") : ("FAIL"));
    printf("E7  (Alphabetical Tie-Breaker):                    %s", (g_test_e7_pass) ? ("PASS") : ("FAIL"));
    printf("E8  (Critical Priority Exclusion):                 %s", (g_test_e8_pass) ? ("PASS") : ("FAIL"));
    printf("E9  (Visible Group Exclusion):                     %s", (g_test_e9_pass) ? ("PASS") : ("FAIL"));
    printf("E10 (Non-Evictable Flag Exclusion):                %s", (g_test_e10_pass) ? ("PASS") : ("FAIL"));
    printf("E11 (Executing Callback Guard Exclusion):          %s", (g_test_e11_pass) ? ("PASS") : ("FAIL"));
    printf("E12 (Destroy Callback Failure Preservation):       %s", (g_test_e12_pass) ? ("PASS") : ("FAIL"));
    printf("E13 (Re-entrant Mutation Replanning):              %s", (g_test_e13_pass) ? ("PASS") : ("FAIL"));
    printf("E14 (Multi-AMX Eviction Ownership):                %s", (g_test_e14_pass) ? ("PASS") : ("FAIL"));
    print("================================================================");

    new total_pass = g_test_e1_pass + g_test_e2_pass + g_test_e3_pass + g_test_e4_pass +
                     g_test_e5_pass + g_test_e6_pass + g_test_e7_pass + g_test_e8_pass +
                     g_test_e9_pass + g_test_e10_pass + g_test_e11_pass + g_test_e12_pass +
                     g_test_e13_pass + g_test_e14_pass;

    printf("TOTAL: %d / 14 PASSED", total_pass);
    if (total_pass == 14)
    {
        print("OVERALL RESULT: ALL EVICTION PREFLIGHT TESTS PASSED!");
    }
    else
    {
        print("OVERALL RESULT: SOME TESTS FAILED!");
    }
    print("================================================================\n");

    SendRconCommand("exit");
    return 1;
}

public OnGameModeExit()
{
    return 1;
}
