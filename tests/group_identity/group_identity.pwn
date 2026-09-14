#include <a_samp>
#include <sui>

// Results flags for ID1 - ID10
new g_id1_pass = 0;
new g_id2_pass = 0;
new g_id3_pass = 0;
new g_id4_pass = 0;
new g_id5_pass = 0;
new g_id6_pass = 0;
new g_id7_pass = 0;
new g_id8_pass = 0;
new g_id9_pass = 0;
new g_id10_pass = 0;

// Call counters for ID1
new g_id1_old_create_calls = 0;
new g_id1_old_show_calls = 0;
new g_id1_new_create_calls = 0;
new g_id1_new_show_calls = 0;

// Call counters for ID2
new g_id2_old_hide_calls = 0;
new g_id2_new_create_calls = 0;
new g_id2_new_show_calls = 0;

// Call counters for ID3
new g_id3_old_destroy_calls = 0;
new g_id3_new_create_calls = 0;
new g_id3_new_show_calls = 0;

// Call counters for ID4
new g_id4_old_destroy_calls = 0;
new g_id4_new_create_calls = 0;
new g_id4_new_show_calls = 0;

// Call counters for ID5
new g_id5_cand_destroy_calls = 0;
new g_id5_req_create_calls = 0;

// Call counters for ID6
new g_id6_c_calls = 0;
new g_id6_s_calls = 0;

// Call counters for ID7
new g_id7_gm_create_calls = 0;
new g_id7_gm_show_calls = 0;

// Call counters for ID9
new g_id9_a_create = 0;
new g_id9_b_create = 0;
new g_id9_c_create = 0;
new g_id9_c_show = 0;

// Call counters for ID10
new g_id10_create_calls = 0;
new g_id10_destroy_calls = 0;

main()
{
    print("================================================================");
    print("      SUI-017 GROUP IDENTITY & LIFECYCLE GENERATION TEST        ");
    print("================================================================");
}

public OnGameModeInit()
{
    SUI_SetDebug(true);
    SetTimer("RunIdentityTests", 500, false);
    return 1;
}

// ----------------------------------------------------------------------------
// ID1 Callbacks
// ----------------------------------------------------------------------------
forward OnID1_OldCreate(playerid);
public OnID1_OldCreate(playerid)
{
    g_id1_old_create_calls++;
    // Re-entrant reset and same-name replacement during cbCreate
    SUI_ResetPlayer(playerid);
    SUI_CreatePlayerFactoryGroup(playerid, "id1", "OnID1_NewCreate", "OnID1_NewDestroy", "OnID1_NewShow", "OnID1_NewHide");
    SUI_SetGroupSize(playerid, "id1", 10);
    return 1;
}

forward OnID1_OldDestroy(playerid);
public OnID1_OldDestroy(playerid) { return 1; }
forward OnID1_OldShow(playerid);
public OnID1_OldShow(playerid) { g_id1_old_show_calls++; return 1; }
forward OnID1_OldHide(playerid);
public OnID1_OldHide(playerid) { return 1; }

forward OnID1_NewCreate(playerid);
public OnID1_NewCreate(playerid) { g_id1_new_create_calls++; return 1; }
forward OnID1_NewDestroy(playerid);
public OnID1_NewDestroy(playerid) { return 1; }
forward OnID1_NewShow(playerid);
public OnID1_NewShow(playerid) { g_id1_new_show_calls++; return 1; }
forward OnID1_NewHide(playerid);
public OnID1_NewHide(playerid) { return 1; }

// ----------------------------------------------------------------------------
// ID2 Callbacks
// ----------------------------------------------------------------------------
forward OnID2_OldCreate(playerid);
public OnID2_OldCreate(playerid) { return 1; }
forward OnID2_OldDestroy(playerid);
public OnID2_OldDestroy(playerid) { return 1; }
forward OnID2_OldShow(playerid);
public OnID2_OldShow(playerid) { return 1; }
forward OnID2_OldHide(playerid);
public OnID2_OldHide(playerid)
{
    g_id2_old_hide_calls++;
    // Re-entrant reset and same-name replacement during cbHide
    SUI_ResetPlayer(playerid);
    SUI_CreatePlayerFactoryGroup(playerid, "id2", "OnID2_NewCreate", "OnID2_NewDestroy", "OnID2_NewShow", "OnID2_NewHide");
    SUI_SetGroupSize(playerid, "id2", 10);
    return 1;
}

forward OnID2_NewCreate(playerid);
public OnID2_NewCreate(playerid) { g_id2_new_create_calls++; return 1; }
forward OnID2_NewDestroy(playerid);
public OnID2_NewDestroy(playerid) { return 1; }
forward OnID2_NewShow(playerid);
public OnID2_NewShow(playerid) { g_id2_new_show_calls++; return 1; }
forward OnID2_NewHide(playerid);
public OnID2_NewHide(playerid) { return 1; }

// ----------------------------------------------------------------------------
// ID3 Callbacks
// ----------------------------------------------------------------------------
forward OnID3_OldCreate(playerid);
public OnID3_OldCreate(playerid) { return 1; }
forward OnID3_OldShow(playerid);
public OnID3_OldShow(playerid) { return 1; }
forward OnID3_OldHide(playerid);
public OnID3_OldHide(playerid) { return 1; }
forward OnID3_OldDestroy(playerid);
public OnID3_OldDestroy(playerid)
{
    g_id3_old_destroy_calls++;
    // Re-entrant reset and same-name replacement during cbDestroy
    SUI_ResetPlayer(playerid);
    SUI_CreatePlayerFactoryGroup(playerid, "id3", "OnID3_NewCreate", "OnID3_NewDestroy", "OnID3_NewShow", "OnID3_NewHide");
    SUI_SetGroupSize(playerid, "id3", 10);
    return 1;
}

forward OnID3_NewCreate(playerid);
public OnID3_NewCreate(playerid) { g_id3_new_create_calls++; return 1; }
forward OnID3_NewDestroy(playerid);
public OnID3_NewDestroy(playerid) { return 1; }
forward OnID3_NewShow(playerid);
public OnID3_NewShow(playerid) { g_id3_new_show_calls++; return 1; }
forward OnID3_NewHide(playerid);
public OnID3_NewHide(playerid) { return 1; }

// ----------------------------------------------------------------------------
// ID4 Callbacks
// ----------------------------------------------------------------------------
forward OnID4_OldCreate(playerid);
public OnID4_OldCreate(playerid) { return 1; }
forward OnID4_OldShow(playerid);
public OnID4_OldShow(playerid) { return 1; }
forward OnID4_OldHide(playerid);
public OnID4_OldHide(playerid) { return 1; }
forward OnID4_OldDestroy(playerid);
public OnID4_OldDestroy(playerid)
{
    g_id4_old_destroy_calls++;
    // Replace during idle destroy
    SUI_ResetPlayer(playerid);
    SUI_CreatePlayerFactoryGroup(playerid, "id4", "OnID4_NewCreate", "OnID4_NewDestroy", "OnID4_NewShow", "OnID4_NewHide");
    SUI_SetGroupSize(playerid, "id4", 10);
    return 1;
}

forward OnID4_NewCreate(playerid);
public OnID4_NewCreate(playerid) { g_id4_new_create_calls++; return 1; }
forward OnID4_NewDestroy(playerid);
public OnID4_NewDestroy(playerid) { return 1; }
forward OnID4_NewShow(playerid);
public OnID4_NewShow(playerid) { g_id4_new_show_calls++; return 1; }
forward OnID4_NewHide(playerid);
public OnID4_NewHide(playerid) { return 1; }

// ----------------------------------------------------------------------------
// ID5 Callbacks
// ----------------------------------------------------------------------------
forward OnID5_CandCreate(playerid);
public OnID5_CandCreate(playerid) { return 1; }
forward OnID5_CandShow(playerid);
public OnID5_CandShow(playerid) { return 1; }
forward OnID5_CandHide(playerid);
public OnID5_CandHide(playerid) { return 1; }
forward OnID5_CandDestroy(playerid);
public OnID5_CandDestroy(playerid)
{
    g_id5_cand_destroy_calls++;
    // Replace candidate during eviction cbDestroy
    SUI_ResetPlayer(playerid);
    SUI_CreatePlayerFactoryGroup(playerid, "id5_cand", "OnID5_CandCreate", "OnID5_CandDestroy", "OnID5_CandShow", "OnID5_CandHide");
    SUI_SetGroupSize(playerid, "id5_cand", 50);
    return 1;
}

forward OnID5_ReqCreate(playerid);
public OnID5_ReqCreate(playerid) { g_id5_req_create_calls++; return 1; }
forward OnID5_ReqShow(playerid);
public OnID5_ReqShow(playerid) { return 1; }
forward OnID5_ReqHide(playerid);
public OnID5_ReqHide(playerid) { return 1; }
forward OnID5_ReqDestroy(playerid);
public OnID5_ReqDestroy(playerid) { return 1; }

// ----------------------------------------------------------------------------
// ID6 Callbacks (Identical Callback Names)
// ----------------------------------------------------------------------------
forward OnID6_C(playerid);
public OnID6_C(playerid)
{
    g_id6_c_calls++;
    if (g_id6_c_calls == 1)
    {
        // First execution: reset and re-register with identical callback names
        SUI_ResetPlayer(playerid);
        SUI_CreatePlayerFactoryGroup(playerid, "id6", "OnID6_C", "OnID6_D", "OnID6_S", "OnID6_H");
        SUI_SetGroupSize(playerid, "id6", 10);
    }
    return 1;
}
forward OnID6_D(playerid);
public OnID6_D(playerid) { return 1; }
forward OnID6_S(playerid);
public OnID6_S(playerid) { g_id6_s_calls++; return 1; }
forward OnID6_H(playerid);
public OnID6_H(playerid) { return 1; }

// ----------------------------------------------------------------------------
// ID7 Callbacks (Cross-AMX)
// ----------------------------------------------------------------------------
forward GM_RegisterID7(playerid);
public GM_RegisterID7(playerid)
{
    // Gamemode registers same group name after FS resets player in its destroy callback
    SUI_CreatePlayerFactoryGroup(playerid, "id7_fs", "OnGmID7_Create", "OnGmID7_Destroy", "OnGmID7_Show", "OnGmID7_Hide");
    SUI_SetGroupSize(playerid, "id7_fs", 8);
    return 1;
}

forward OnGmID7_Create(playerid);
public OnGmID7_Create(playerid) { g_id7_gm_create_calls++; return 1; }
forward OnGmID7_Destroy(playerid);
public OnGmID7_Destroy(playerid) { return 1; }
forward OnGmID7_Show(playerid);
public OnGmID7_Show(playerid) { g_id7_gm_show_calls++; return 1; }
forward OnGmID7_Hide(playerid);
public OnGmID7_Hide(playerid) { return 1; }

// ----------------------------------------------------------------------------
// ID8 Callbacks (Normal Path)
// ----------------------------------------------------------------------------
new g_id8_c = 0;
new g_id8_d = 0;
new g_id8_s = 0;
new g_id8_h = 0;

forward OnID8_Create(playerid);
public OnID8_Create(playerid) { g_id8_c++; return 1; }
forward OnID8_Destroy(playerid);
public OnID8_Destroy(playerid) { g_id8_d++; return 1; }
forward OnID8_Show(playerid);
public OnID8_Show(playerid) { g_id8_s++; return 1; }
forward OnID8_Hide(playerid);
public OnID8_Hide(playerid) { g_id8_h++; return 1; }

// ----------------------------------------------------------------------------
// ID9 Callbacks (A -> B -> C multiple replacements)
// ----------------------------------------------------------------------------
forward OnID9_ACreate(playerid);
public OnID9_ACreate(playerid)
{
    g_id9_a_create++;
    SUI_ResetPlayer(playerid);
    SUI_CreatePlayerFactoryGroup(playerid, "id9", "OnID9_BCreate", "OnID9_BDestroy", "OnID9_BShow", "OnID9_BHide");
    return 1;
}
forward OnID9_ADestroy(playerid);
public OnID9_ADestroy(playerid) { return 1; }
forward OnID9_AShow(playerid);
public OnID9_AShow(playerid) { return 1; }
forward OnID9_AHide(playerid);
public OnID9_AHide(playerid) { return 1; }

forward OnID9_BCreate(playerid);
public OnID9_BCreate(playerid)
{
    g_id9_b_create++;
    SUI_ResetPlayer(playerid);
    SUI_CreatePlayerFactoryGroup(playerid, "id9", "OnID9_CCreate", "OnID9_CDestroy", "OnID9_CShow", "OnID9_CHide");
    return 1;
}
forward OnID9_BDestroy(playerid);
public OnID9_BDestroy(playerid) { return 1; }
forward OnID9_BShow(playerid);
public OnID9_BShow(playerid) { return 1; }
forward OnID9_BHide(playerid);
public OnID9_BHide(playerid) { return 1; }

forward OnID9_CCreate(playerid);
public OnID9_CCreate(playerid) { g_id9_c_create++; return 1; }
forward OnID9_CDestroy(playerid);
public OnID9_CDestroy(playerid) { return 1; }
forward OnID9_CShow(playerid);
public OnID9_CShow(playerid) { g_id9_c_show++; return 1; }
forward OnID9_CHide(playerid);
public OnID9_CHide(playerid) { return 1; }

// ----------------------------------------------------------------------------
// ID10 Callbacks (100 rapid cycles)
// ----------------------------------------------------------------------------
forward OnID10_Create(playerid);
public OnID10_Create(playerid) { g_id10_create_calls++; return 1; }
forward OnID10_Destroy(playerid);
public OnID10_Destroy(playerid) { g_id10_destroy_calls++; return 1; }
forward OnID10_Show(playerid);
public OnID10_Show(playerid) { return 1; }
forward OnID10_Hide(playerid);
public OnID10_Hide(playerid) { return 1; }

// ----------------------------------------------------------------------------
// Test Execution Pipeline
// ----------------------------------------------------------------------------
forward RunIdentityTests();
public RunIdentityTests()
{
    print("\n================================================================");
    print("             STARTING SUI-017 IDENTITY SUITE                    ");
    print("================================================================");

    // -------------------------------------------------------------
    // ID1: Create Callback Reset + Same-Name Replacement
    // -------------------------------------------------------------
    print("\n[TEST-ID1] Testing Create Callback Reset + Same-Name Replacement...");
    SUI_ResetPlayer(0);
    SUI_CreatePlayerFactoryGroup(0, "id1", "OnID1_OldCreate", "OnID1_OldDestroy", "OnID1_OldShow", "OnID1_OldHide");
    SUI_SetGroupSize(0, "id1", 10);
    SUI_ShowGroup(0, "id1");

    new id1_created_mid = SUI_IsGroupCreated(0, "id1");
    new id1_visible_mid = SUI_IsGroupVisible(0, "id1");
    new id1_act_mid = SUI_GetActiveTextDrawCount(0);

    // Explicitly show replacement group
    SUI_ShowGroup(0, "id1");
    new id1_created_final = SUI_IsGroupCreated(0, "id1");
    new id1_visible_final = SUI_IsGroupVisible(0, "id1");
    new id1_act_final = SUI_GetActiveTextDrawCount(0);

    SUI_DestroyGroup(0, "id1");
    SUI_ResetPlayer(0);

    if (g_id1_old_create_calls == 1 &&
        g_id1_old_show_calls == 0 &&
        id1_created_mid == 0 &&
        id1_visible_mid == 0 &&
        id1_act_mid == 0 &&
        g_id1_new_create_calls == 1 &&
        g_id1_new_show_calls == 1 &&
        id1_created_final == 1 &&
        id1_visible_final == 1 &&
        id1_act_final == 10)
    {
        g_id1_pass = 1;
        print("[TEST-ID1] PASS: Old ShowGroup cleanly aborted on replacement; new group operates normally.");
    }
    else
    {
        printf("[TEST-ID1] FAIL: old_c=%d old_s=%d mid_c=%d mid_v=%d mid_act=%d new_c=%d new_s=%d fin_c=%d fin_v=%d fin_act=%d",
            g_id1_old_create_calls, g_id1_old_show_calls, id1_created_mid, id1_visible_mid, id1_act_mid,
            g_id1_new_create_calls, g_id1_new_show_calls, id1_created_final, id1_visible_final, id1_act_final);
    }

    // -------------------------------------------------------------
    // ID2: Hide Callback Same-Name Replacement
    // -------------------------------------------------------------
    print("\n[TEST-ID2] Testing Hide Callback Same-Name Replacement...");
    SUI_ResetPlayer(0);
    SUI_CreatePlayerFactoryGroup(0, "id2", "OnID2_OldCreate", "OnID2_OldDestroy", "OnID2_OldShow", "OnID2_OldHide");
    SUI_SetGroupSize(0, "id2", 10);
    SUI_ShowGroup(0, "id2"); // created and visible

    SUI_HideGroup(0, "id2"); // triggers OnID2_OldHide -> reset + re-register replacement

    new id2_created_mid = SUI_IsGroupCreated(0, "id2");
    new id2_visible_mid = SUI_IsGroupVisible(0, "id2");
    new id2_act_mid = SUI_GetActiveTextDrawCount(0);

    // Show replacement
    SUI_ShowGroup(0, "id2");
    new id2_created_final = SUI_IsGroupCreated(0, "id2");
    new id2_visible_final = SUI_IsGroupVisible(0, "id2");
    new id2_act_final = SUI_GetActiveTextDrawCount(0);

    SUI_DestroyGroup(0, "id2");
    SUI_ResetPlayer(0);

    if (g_id2_old_hide_calls == 1 &&
        id2_created_mid == 0 &&
        id2_visible_mid == 0 &&
        id2_act_mid == 0 &&
        g_id2_new_create_calls == 1 &&
        g_id2_new_show_calls == 1 &&
        id2_created_final == 1 &&
        id2_visible_final == 1 &&
        id2_act_final == 10)
    {
        g_id2_pass = 1;
        print("[TEST-ID2] PASS: Outer HideGroup did not mutate replacement; replacement operates cleanly.");
    }
    else
    {
        printf("[TEST-ID2] FAIL: hide_c=%d mid_c=%d mid_v=%d mid_act=%d new_c=%d new_s=%d fin_c=%d fin_v=%d fin_act=%d",
            g_id2_old_hide_calls, id2_created_mid, id2_visible_mid, id2_act_mid,
            g_id2_new_create_calls, g_id2_new_show_calls, id2_created_final, id2_visible_final, id2_act_final);
    }

    // -------------------------------------------------------------
    // ID3: Destroy Callback Same-Name Replacement
    // -------------------------------------------------------------
    print("\n[TEST-ID3] Testing Destroy Callback Same-Name Replacement...");
    SUI_ResetPlayer(0);
    SUI_CreatePlayerFactoryGroup(0, "id3", "OnID3_OldCreate", "OnID3_OldDestroy", "OnID3_OldShow", "OnID3_OldHide");
    SUI_SetGroupSize(0, "id3", 10);
    SUI_ShowGroup(0, "id3");

    SUI_DestroyGroup(0, "id3"); // triggers OnID3_OldDestroy -> reset + re-register replacement

    new id3_created_mid = SUI_IsGroupCreated(0, "id3");
    new id3_act_mid = SUI_GetActiveTextDrawCount(0);

    // Show replacement
    SUI_ShowGroup(0, "id3");
    new id3_created_final = SUI_IsGroupCreated(0, "id3");
    new id3_visible_final = SUI_IsGroupVisible(0, "id3");
    new id3_act_final = SUI_GetActiveTextDrawCount(0);

    SUI_DestroyGroup(0, "id3");
    SUI_ResetPlayer(0);

    if (g_id3_old_destroy_calls == 1 &&
        id3_created_mid == 0 &&
        id3_act_mid == 0 &&
        g_id3_new_create_calls == 1 &&
        g_id3_new_show_calls == 1 &&
        id3_created_final == 1 &&
        id3_visible_final == 1 &&
        id3_act_final == 10)
    {
        g_id3_pass = 1;
        print("[TEST-ID3] PASS: Outer DestroyGroup did not destroy replacement or corrupt capacity.");
    }
    else
    {
        printf("[TEST-ID3] FAIL: dest_c=%d mid_c=%d mid_act=%d new_c=%d new_s=%d fin_c=%d fin_v=%d fin_act=%d",
            g_id3_old_destroy_calls, id3_created_mid, id3_act_mid,
            g_id3_new_create_calls, g_id3_new_show_calls, id3_created_final, id3_visible_final, id3_act_final);
    }

    // -------------------------------------------------------------
    // ID5: Eviction Same-Name Replacement
    // -------------------------------------------------------------
    print("\n[TEST-ID5] Testing Eviction Candidate Same-Name Replacement...");
    SUI_ResetPlayer(0);
    SUI_SetEvictionThreshold(0, 80);
    SUI_SetMaxTextDraws(0, 100);
    SUI_SetEvictionThreshold(0, 80);

    SUI_CreatePlayerFactoryGroup(0, "id5_cand", "OnID5_CandCreate", "OnID5_CandDestroy", "OnID5_CandShow", "OnID5_CandHide");
    SUI_SetGroupSize(0, "id5_cand", 50);
    SUI_SetGroupPriority(0, "id5_cand", SUI_PRIORITY_LOW);
    SUI_ShowGroup(0, "id5_cand");
    SUI_HideGroup(0, "id5_cand"); // created, hidden, active=50

    SUI_CreatePlayerFactoryGroup(0, "id5_req", "OnID5_ReqCreate", "OnID5_ReqDestroy", "OnID5_ReqShow", "OnID5_ReqHide");
    SUI_SetGroupSize(0, "id5_req", 40);

    // 50 + 40 = 90 > threshold (80) -> triggers eviction of id5_cand.
    // Inside OnID5_CandDestroy, id5_cand is reset & replaced.
    SUI_ShowGroup(0, "id5_req");

    new id5_cand_exists = SUI_IsGroupCreated(0, "id5_cand");
    new id5_act = SUI_GetActiveTextDrawCount(0);

    SUI_ResetPlayer(0);

    if (g_id5_cand_destroy_calls == 1 && id5_cand_exists == 0 && id5_act == 0)
    {
        g_id5_pass = 1;
        print("[TEST-ID5] PASS: Eviction candidate replacement handled safely without memory or accounting corruption.");
    }
    else
    {
        printf("[TEST-ID5] FAIL: cand_dest_calls=%d cand_exists=%d act=%d",
            g_id5_cand_destroy_calls, id5_cand_exists, id5_act);
    }

    // -------------------------------------------------------------
    // ID6: Same Owner / Same Callback Names
    // -------------------------------------------------------------
    print("\n[TEST-ID6] Testing Same Owner / Same Callback Names Replacement...");
    SUI_ResetPlayer(0);
    g_id6_c_calls = 0;
    g_id6_s_calls = 0;

    SUI_CreatePlayerFactoryGroup(0, "id6", "OnID6_C", "OnID6_D", "OnID6_S", "OnID6_H");
    SUI_SetGroupSize(0, "id6", 10);
    SUI_ShowGroup(0, "id6"); // triggers OnID6_C (calls=1) -> reset + re-register identical callbacks

    new id6_mid_created = SUI_IsGroupCreated(0, "id6");
    new id6_mid_visible = SUI_IsGroupVisible(0, "id6");

    // Explicitly show replacement group
    SUI_ShowGroup(0, "id6");
    new id6_fin_created = SUI_IsGroupCreated(0, "id6");
    new id6_fin_visible = SUI_IsGroupVisible(0, "id6");
    new id6_fin_act = SUI_GetActiveTextDrawCount(0);

    SUI_DestroyGroup(0, "id6");
    SUI_ResetPlayer(0);

    if (g_id6_c_calls == 2 &&
        g_id6_s_calls == 1 &&
        id6_mid_created == 0 &&
        id6_mid_visible == 0 &&
        id6_fin_created == 1 &&
        id6_fin_visible == 1 &&
        id6_fin_act == 10)
    {
        g_id6_pass = 1;
        print("[TEST-ID6] PASS: SUI distinguished identical callback names purely via instanceId.");
    }
    else
    {
        printf("[TEST-ID6] FAIL: c_calls=%d s_calls=%d mid_c=%d mid_v=%d fin_c=%d fin_v=%d fin_act=%d",
            g_id6_c_calls, g_id6_s_calls, id6_mid_created, id6_mid_visible, id6_fin_created, id6_fin_visible, id6_fin_act);
    }

    // -------------------------------------------------------------
    // ID7: Cross-AMX Replacement
    // -------------------------------------------------------------
    print("\n[TEST-ID7] Testing Cross-AMX Replacement Isolation...");
    SUI_ResetPlayer(0);
    g_id7_gm_create_calls = 0;
    g_id7_gm_show_calls = 0;

    // Filterscript registers id7_fs
    new fs_setup_ok = CallRemoteFunction("FS_SetupID7", "d", 0);
    SUI_ShowGroup(0, "id7_fs"); // FS shows group (active = 5)
    new id7_fs_act = SUI_GetActiveTextDrawCount(0);

    // Destroy id7_fs -> triggers FS_OnID7_Destroy -> calls GM_RegisterID7 -> Gamemode registers id7_fs
    SUI_DestroyGroup(0, "id7_fs");
    new fs_dest_calls = CallRemoteFunction("FS_GetDestroyCalls", "");

    // Gamemode now shows its own generation of id7_fs
    SUI_ShowGroup(0, "id7_fs");
    new id7_gm_created = SUI_IsGroupCreated(0, "id7_fs");
    new id7_gm_visible = SUI_IsGroupVisible(0, "id7_fs");
    new id7_gm_act = SUI_GetActiveTextDrawCount(0);

    SUI_DestroyGroup(0, "id7_fs");
    SUI_ResetPlayer(0);

    if (fs_setup_ok == 1 &&
        id7_fs_act == 5 &&
        fs_dest_calls == 1 &&
        g_id7_gm_create_calls == 1 &&
        g_id7_gm_show_calls == 1 &&
        id7_gm_created == 1 &&
        id7_gm_visible == 1 &&
        id7_gm_act == 8)
    {
        g_id7_pass = 1;
        print("[TEST-ID7] PASS: Cross-AMX replacement succeeded with full instance isolation.");
    }
    else
    {
        printf("[TEST-ID7] FAIL: fs_ok=%d fs_act=%d fs_dest=%d gm_c=%d gm_s=%d gm_c_flag=%d gm_v_flag=%d gm_act=%d",
            fs_setup_ok, id7_fs_act, fs_dest_calls, g_id7_gm_create_calls, g_id7_gm_show_calls,
            id7_gm_created, id7_gm_visible, id7_gm_act);
    }

    // -------------------------------------------------------------
    // ID8: Normal No-Replacement Path
    // -------------------------------------------------------------
    print("\n[TEST-ID8] Testing Normal No-Replacement Lifecycle Path...");
    SUI_ResetPlayer(0);
    g_id8_c = 0; g_id8_d = 0; g_id8_s = 0; g_id8_h = 0;

    SUI_CreatePlayerFactoryGroup(0, "id8", "OnID8_Create", "OnID8_Destroy", "OnID8_Show", "OnID8_Hide");
    SUI_SetGroupSize(0, "id8", 8);

    SUI_ShowGroup(0, "id8");
    new id8_c1 = SUI_IsGroupCreated(0, "id8");
    new id8_v1 = SUI_IsGroupVisible(0, "id8");
    new id8_act1 = SUI_GetActiveTextDrawCount(0);

    SUI_HideGroup(0, "id8");
    new id8_c2 = SUI_IsGroupCreated(0, "id8");
    new id8_v2 = SUI_IsGroupVisible(0, "id8");
    new id8_act2 = SUI_GetActiveTextDrawCount(0);

    SUI_ShowGroup(0, "id8");
    new id8_c3 = SUI_IsGroupCreated(0, "id8");
    new id8_v3 = SUI_IsGroupVisible(0, "id8");
    new id8_act3 = SUI_GetActiveTextDrawCount(0);

    SUI_DestroyGroup(0, "id8");
    new id8_c4 = SUI_IsGroupCreated(0, "id8");
    new id8_v4 = SUI_IsGroupVisible(0, "id8");
    new id8_act4 = SUI_GetActiveTextDrawCount(0);

    SUI_ResetPlayer(0);

    if (id8_c1 == 1 && id8_v1 == 1 && id8_act1 == 8 &&
        id8_c2 == 1 && id8_v2 == 0 && id8_act2 == 8 &&
        id8_c3 == 1 && id8_v3 == 1 && id8_act3 == 8 &&
        id8_c4 == 0 && id8_v4 == 0 && id8_act4 == 0 &&
        g_id8_c == 1 && g_id8_s == 2 && g_id8_h == 2 && g_id8_d == 1)
    {
        g_id8_pass = 1;
        print("[TEST-ID8] PASS: Normal lifecycle transitions remain 100% intact.");
    }
    else
    {
        printf("[TEST-ID8] FAIL: c1=%d v1=%d act1=%d c2=%d v2=%d act2=%d c3=%d v3=%d act3=%d c4=%d v4=%d act4=%d calls=(%d,%d,%d,%d)",
            id8_c1, id8_v1, id8_act1, id8_c2, id8_v2, id8_act2, id8_c3, id8_v3, id8_act3, id8_c4, id8_v4, id8_act4,
            g_id8_c, g_id8_s, g_id8_h, g_id8_d);
    }

    // -------------------------------------------------------------
    // ID9: Reset + Register Same Name Multiple Times (A -> B -> C)
    // -------------------------------------------------------------
    print("\n[TEST-ID9] Testing Multi-Generation Chain Replacement (A -> B -> C)...");
    SUI_ResetPlayer(0);
    g_id9_a_create = 0; g_id9_b_create = 0; g_id9_c_create = 0; g_id9_c_show = 0;

    SUI_CreatePlayerFactoryGroup(0, "id9", "OnID9_ACreate", "OnID9_ADestroy", "OnID9_AShow", "OnID9_AHide");
    SUI_ShowGroup(0, "id9"); // triggers A -> reset -> registers B

    SUI_ShowGroup(0, "id9"); // triggers B -> reset -> registers C

    SUI_ShowGroup(0, "id9"); // triggers C create + C show
    new id9_fin_vis = SUI_IsGroupVisible(0, "id9");

    SUI_DestroyGroup(0, "id9");
    SUI_ResetPlayer(0);

    if (g_id9_a_create == 1 && g_id9_b_create == 1 && g_id9_c_create == 1 && g_id9_c_show == 1 && id9_fin_vis == 1)
    {
        g_id9_pass = 1;
        print("[TEST-ID9] PASS: Multi-generation replacement chain executed with exact identity discrimination.");
    }
    else
    {
        printf("[TEST-ID9] FAIL: a_c=%d b_c=%d c_c=%d c_s=%d fin_vis=%d",
            g_id9_a_create, g_id9_b_create, g_id9_c_create, g_id9_c_show, id9_fin_vis);
    }

    // -------------------------------------------------------------
    // ID10: 100 Rapid Replacement Cycles
    // -------------------------------------------------------------
    print("\n[TEST-ID10] Testing 100 Rapid Replacement Cycles...");
    SUI_ResetPlayer(0);
    g_id10_create_calls = 0;
    g_id10_destroy_calls = 0;

    for (new i = 0; i < 100; i++)
    {
        SUI_ResetPlayer(0);
        SUI_CreatePlayerFactoryGroup(0, "id10", "OnID10_Create", "OnID10_Destroy", "OnID10_Show", "OnID10_Hide");
        SUI_SetGroupSize(0, "id10", 7);
        SUI_ShowGroup(0, "id10");
        SUI_DestroyGroup(0, "id10");
    }

    new id10_act_after = SUI_GetActiveTextDrawCount(0);

    // Verify 101st registration functions normally
    SUI_CreatePlayerFactoryGroup(0, "id10", "OnID10_Create", "OnID10_Destroy", "OnID10_Show", "OnID10_Hide");
    SUI_SetGroupSize(0, "id10", 7);
    SUI_ShowGroup(0, "id10");
    new id10_fin_act = SUI_GetActiveTextDrawCount(0);
    SUI_DestroyGroup(0, "id10");
    SUI_ResetPlayer(0);

    if (g_id10_create_calls == 101 &&
        g_id10_destroy_calls == 101 &&
        id10_act_after == 0 &&
        id10_fin_act == 7)
    {
        g_id10_pass = 1;
        print("[TEST-ID10] PASS: 100 rapid replacement cycles executed without drift or corruption.");
    }
    else
    {
        printf("[TEST-ID10] FAIL: c_calls=%d d_calls=%d act_after=%d fin_act=%d",
            g_id10_create_calls, g_id10_destroy_calls, id10_act_after, id10_fin_act);
    }

    // -------------------------------------------------------------
    // ID4: ProcessTick Same-Name Replacement (Deferred Timer)
    // -------------------------------------------------------------
    print("\n[TEST-ID4] Setting up ProcessTick Same-Name Replacement (short timeout)...");
    SUI_ResetPlayer(0);
    SUI_CreatePlayerFactoryGroup(0, "id4", "OnID4_OldCreate", "OnID4_OldDestroy", "OnID4_OldShow", "OnID4_OldHide");
    SUI_SetGroupSize(0, "id4", 10);
    SUI_SetIdleTimeout(0, "id4", 50); // 50ms timeout
    SUI_ShowGroup(0, "id4");
    SUI_HideGroup(0, "id4");

    // Wait 150ms for server ProcessTick to trigger idle destroy callback
    SetTimer("Step_ID4_Check", 200, false);
}

forward Step_ID4_Check();
public Step_ID4_Check()
{
    new id4_created_mid = SUI_IsGroupCreated(0, "id4");
    new id4_act_mid = SUI_GetActiveTextDrawCount(0);

    // Show replacement group
    SUI_ShowGroup(0, "id4");
    new id4_created_final = SUI_IsGroupCreated(0, "id4");
    new id4_visible_final = SUI_IsGroupVisible(0, "id4");
    new id4_act_final = SUI_GetActiveTextDrawCount(0);

    SUI_DestroyGroup(0, "id4");
    SUI_ResetPlayer(0);

    if (g_id4_old_destroy_calls == 1 &&
        id4_created_mid == 0 &&
        id4_act_mid == 0 &&
        g_id4_new_create_calls == 1 &&
        g_id4_new_show_calls == 1 &&
        id4_created_final == 1 &&
        id4_visible_final == 1 &&
        id4_act_final == 10)
    {
        g_id4_pass = 1;
        print("[TEST-ID4] PASS: ProcessTick idle destroy did not erase replacement group.");
    }
    else
    {
        printf("[TEST-ID4] FAIL: dest_c=%d mid_c=%d mid_act=%d new_c=%d new_s=%d fin_c=%d fin_v=%d fin_act=%d",
            g_id4_old_destroy_calls, id4_created_mid, id4_act_mid,
            g_id4_new_create_calls, g_id4_new_show_calls, id4_created_final, id4_visible_final, id4_act_final);
    }

    PrintIdentityResults();
}

forward PrintIdentityResults();
public PrintIdentityResults()
{
    print("\n================================================================");
    print("      SUI-017 GROUP IDENTITY REGRESSION RESULTS (ID1-ID10)      ");
    print("================================================================");
    if (g_id1_pass) printf("ID1  (Create Callback Reset + Replacement): PASS");
    else printf("ID1  (Create Callback Reset + Replacement): FAIL");
    if (g_id2_pass) printf("ID2  (Hide Callback Same-Name Replacement): PASS");
    else printf("ID2  (Hide Callback Same-Name Replacement): FAIL");
    if (g_id3_pass) printf("ID3  (Destroy Callback Same-Name Replace):  PASS");
    else printf("ID3  (Destroy Callback Same-Name Replace):  FAIL");
    if (g_id4_pass) printf("ID4  (ProcessTick Same-Name Replacement):   PASS");
    else printf("ID4  (ProcessTick Same-Name Replacement):   FAIL");
    if (g_id5_pass) printf("ID5  (Eviction Candidate Replacement):      PASS");
    else printf("ID5  (Eviction Candidate Replacement):      FAIL");
    if (g_id6_pass) printf("ID6  (Same Owner / Same Callback Names):    PASS");
    else printf("ID6  (Same Owner / Same Callback Names):    FAIL");
    if (g_id7_pass) printf("ID7  (Cross-AMX Replacement Isolation):     PASS");
    else printf("ID7  (Cross-AMX Replacement Isolation):     FAIL");
    if (g_id8_pass) printf("ID8  (Normal No-Replacement Path):          PASS");
    else printf("ID8  (Normal No-Replacement Path):          FAIL");
    if (g_id9_pass) printf("ID9  (Multi-Generation Chain Replacement):  PASS");
    else printf("ID9  (Multi-Generation Chain Replacement):  FAIL");
    if (g_id10_pass) printf("ID10 (100 Rapid Replacement Cycles):        PASS");
    else printf("ID10 (100 Rapid Replacement Cycles):        FAIL");
    print("================================================================");

    new total_pass = g_id1_pass + g_id2_pass + g_id3_pass + g_id4_pass + g_id5_pass +
                     g_id6_pass + g_id7_pass + g_id8_pass + g_id9_pass + g_id10_pass;

    if (total_pass == 10)
    {
        print("OVERALL RESULT: ALL GROUP IDENTITY TESTS PASSED! (10/10)");
    }
    else
    {
        printf("OVERALL RESULT: %d/10 TESTS PASSED.", total_pass);
    }
    print("================================================================\n");
}
