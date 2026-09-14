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
new g_h1_pass = 0;
new g_h2_pass = 0;
new g_h3_pass = 0;
new g_h4_pass = 0;
new g_id_evict_pass = 0;
new g_o1_pass = 0;
new g_o2_pass = 0;
new g_rag1_pass = 0;
new g_rag2_pass = 0;
new g_rag3_pass = 0;

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
// H1 - H4 Callbacks
// ----------------------------------------------------------------------------
forward OnH1_Create(playerid);
public OnH1_Create(playerid) { return 1; }
forward OnH1_Destroy(playerid);
public OnH1_Destroy(playerid) { return 1; }
forward OnH1_Show(playerid);
public OnH1_Show(playerid) { return 1; }
forward OnH1_Hide(playerid);
public OnH1_Hide(playerid) { return 1; }

new g_h2_hide_calls = 0;
new g_h2_destroy_calls = 0;
forward OnH2_Create(playerid);
public OnH2_Create(playerid) { return 1; }
forward OnH2_Show(playerid);
public OnH2_Show(playerid) { return 1; }
forward OnH2_Hide(playerid);
public OnH2_Hide(playerid) { g_h2_hide_calls++; return 1; }
forward OnH2_Destroy(playerid);
public OnH2_Destroy(playerid) { g_h2_destroy_calls++; return 1; }

new g_h3_hide_calls = 0;
new g_h3_destroy_calls = 0;
forward OnH3_Create(playerid);
public OnH3_Create(playerid) { return 1; }
forward OnH3_Show(playerid);
public OnH3_Show(playerid) { return 1; }
forward OnH3_Hide(playerid);
public OnH3_Hide(playerid) { g_h3_hide_calls++; return 1; }
forward OnH3_Destroy(playerid);
public OnH3_Destroy(playerid) { g_h3_destroy_calls++; return 1; }

new g_h4_old_create_calls = 0;
new g_h4_new_create_calls = 0;
new g_h4_new_show_calls = 0;
new g_h4_inplace_res = -1;
new g_h4_repl_res = -1;

forward OnH4_OldCreate(playerid);
public OnH4_OldCreate(playerid)
{
    g_h4_old_create_calls++;
    // 1. In-place re-registration WITHOUT ResetPlayer must be REJECTED (returns 0)
    g_h4_inplace_res = SUI_CreatePlayerFactoryGroup(playerid, "h4_grp", "OnH4_NewCreate", "OnH4_NewDestroy", "OnH4_NewShow", "OnH4_NewHide");

    // 2. Legitimate replacement after ResetPlayer
    SUI_ResetPlayer(playerid);
    g_h4_repl_res = SUI_CreatePlayerFactoryGroup(playerid, "h4_grp", "OnH4_NewCreate", "OnH4_NewDestroy", "OnH4_NewShow", "OnH4_NewHide");
    SUI_SetGroupSize(playerid, "h4_grp", 6);
    return 1;
}
forward OnH4_OldDestroy(playerid);
public OnH4_OldDestroy(playerid) { return 1; }
forward OnH4_OldShow(playerid);
public OnH4_OldShow(playerid) { return 1; }
forward OnH4_OldHide(playerid);
public OnH4_OldHide(playerid) { return 1; }

forward OnH4_NewCreate(playerid);
public OnH4_NewCreate(playerid) { g_h4_new_create_calls++; return 1; }
forward OnH4_NewDestroy(playerid);
public OnH4_NewDestroy(playerid) { return 1; }
forward OnH4_NewShow(playerid);
public OnH4_NewShow(playerid) { g_h4_new_show_calls++; return 1; }
forward OnH4_NewHide(playerid);
public OnH4_NewHide(playerid) { return 1; }

// ----------------------------------------------------------------------------
// ID-EVICT Callbacks
// ----------------------------------------------------------------------------
new g_idevict_cand_destroy_calls = 0;
new g_idevict_new_create_calls = 0;
new g_idevict_new_show_calls = 0;
new g_idevict_req_create_calls = 0;
new g_idevict_inplace_res = -1;
new g_idevict_repl_res = -1;

forward OnIDEvict_CandCreate(playerid);
public OnIDEvict_CandCreate(playerid) { return 1; }
forward OnIDEvict_CandShow(playerid);
public OnIDEvict_CandShow(playerid) { return 1; }
forward OnIDEvict_CandHide(playerid);
public OnIDEvict_CandHide(playerid) { return 1; }
forward OnIDEvict_CandDestroy(playerid);
public OnIDEvict_CandDestroy(playerid)
{
    g_idevict_cand_destroy_calls++;
    // 1. In-place re-registration WITHOUT ResetPlayer must be REJECTED (returns 0)
    g_idevict_inplace_res = SUI_CreatePlayerFactoryGroup(playerid, "evict_cand_grp", "OnIDEvict_NewCreate", "OnIDEvict_NewDestroy", "OnIDEvict_NewShow", "OnIDEvict_NewHide");

    // 2. Legitimate replacement after ResetPlayer
    SUI_ResetPlayer(playerid);
    g_idevict_repl_res = SUI_CreatePlayerFactoryGroup(playerid, "evict_cand_grp", "OnIDEvict_NewCreate", "OnIDEvict_NewDestroy", "OnIDEvict_NewShow", "OnIDEvict_NewHide");
    SUI_SetGroupSize(playerid, "evict_cand_grp", 15);
    return 1;
}

forward OnIDEvict_NewCreate(playerid);
public OnIDEvict_NewCreate(playerid) { g_idevict_new_create_calls++; return 1; }
forward OnIDEvict_NewDestroy(playerid);
public OnIDEvict_NewDestroy(playerid) { return 1; }
forward OnIDEvict_NewShow(playerid);
public OnIDEvict_NewShow(playerid) { g_idevict_new_show_calls++; return 1; }
forward OnIDEvict_NewHide(playerid);
public OnIDEvict_NewHide(playerid) { return 1; }

forward OnIDEvict_ReqCreate(playerid);
public OnIDEvict_ReqCreate(playerid) { g_idevict_req_create_calls++; return 1; }
forward OnIDEvict_ReqDestroy(playerid);
public OnIDEvict_ReqDestroy(playerid) { return 1; }
forward OnIDEvict_ReqShow(playerid);
public OnIDEvict_ReqShow(playerid) { return 1; }
forward OnIDEvict_ReqHide(playerid);
public OnIDEvict_ReqHide(playerid) { return 1; }

// -------------------------------------------------------------
// O1 & O2 Callbacks
// -------------------------------------------------------------
new g_o1_gm_create_calls = 0;
new g_o1_gm_show_calls = 0;

forward OnO1_GM_Create(playerid);
public OnO1_GM_Create(playerid)
{
    g_o1_gm_create_calls++;
    // Filterscript attempts to hijack owner_lock during callback
    CallRemoteFunction("FS_TryHijackO1", "d", playerid);
    return 1;
}
forward OnO1_GM_Destroy(playerid);
public OnO1_GM_Destroy(playerid) { return 1; }
forward OnO1_GM_Show(playerid);
public OnO1_GM_Show(playerid) { g_o1_gm_show_calls++; return 1; }
forward OnO1_GM_Hide(playerid);
public OnO1_GM_Hide(playerid) { return 1; }

// -------------------------------------------------------------
// RAG1 & RAG2 Callbacks
// -------------------------------------------------------------
new g_rag1_create_calls = 0;
new g_rag1_rereg_result = -1;

forward OnRAG1_Create(playerid);
public OnRAG1_Create(playerid)
{
    g_rag1_create_calls++;
    // Same owner attempts re-registration during callback WITHOUT prior removal
    g_rag1_rereg_result = SUI_CreatePlayerFactoryGroup(playerid, "rag1_grp", "OnRAG1_NewC", "OnRAG1_NewD", "OnRAG1_NewS", "OnRAG1_NewH");
    return 1;
}
forward OnRAG1_Destroy(playerid);
public OnRAG1_Destroy(playerid) { return 1; }
forward OnRAG1_Show(playerid);
public OnRAG1_Show(playerid) { return 1; }
forward OnRAG1_Hide(playerid);
public OnRAG1_Hide(playerid) { return 1; }

forward OnRAG1_NewC(playerid); public OnRAG1_NewC(playerid) { return 1; }
forward OnRAG1_NewD(playerid); public OnRAG1_NewD(playerid) { return 1; }
forward OnRAG1_NewS(playerid); public OnRAG1_NewS(playerid) { return 1; }
forward OnRAG1_NewH(playerid); public OnRAG1_NewH(playerid) { return 1; }

new g_rag2_create_calls = 0;

forward OnRAG2_Create(playerid);
public OnRAG2_Create(playerid)
{
    g_rag2_create_calls++;
    // Different owner attempts takeover during callback
    CallRemoteFunction("FS_TryHijackRAG2", "d", playerid);
    return 1;
}
forward OnRAG2_Destroy(playerid);
public OnRAG2_Destroy(playerid) { return 1; }
forward OnRAG2_Show(playerid);
public OnRAG2_Show(playerid) { return 1; }
forward OnRAG2_Hide(playerid);
public OnRAG2_Hide(playerid) { return 1; }


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
    // H1: Hide Must Preserve Created Capacity
    // -------------------------------------------------------------
    print("\n[TEST-H1] Testing Hide Must Preserve Created Capacity...");
    SUI_ResetPlayer(0);
    SUI_CreatePlayerFactoryGroup(0, "h1_grp", "OnH1_Create", "OnH1_Destroy", "OnH1_Show", "OnH1_Hide");
    SUI_SetGroupSize(0, "h1_grp", 5);

    SUI_ShowGroup(0, "h1_grp");
    new h1_act1 = SUI_GetActiveTextDrawCount(0);
    new h1_cr1 = SUI_IsGroupCreated(0, "h1_grp");
    new h1_vis1 = SUI_IsGroupVisible(0, "h1_grp");

    SUI_HideGroup(0, "h1_grp");
    new h1_act2 = SUI_GetActiveTextDrawCount(0);
    new h1_cr2 = SUI_IsGroupCreated(0, "h1_grp");
    new h1_vis2 = SUI_IsGroupVisible(0, "h1_grp");

    SUI_ShowGroup(0, "h1_grp");
    new h1_act3 = SUI_GetActiveTextDrawCount(0);
    new h1_cr3 = SUI_IsGroupCreated(0, "h1_grp");
    new h1_vis3 = SUI_IsGroupVisible(0, "h1_grp");

    SUI_DestroyGroup(0, "h1_grp");
    new h1_act4 = SUI_GetActiveTextDrawCount(0);
    new h1_cr4 = SUI_IsGroupCreated(0, "h1_grp");
    new h1_vis4 = SUI_IsGroupVisible(0, "h1_grp");
    SUI_ResetPlayer(0);

    if (h1_act1 == 5 && h1_cr1 == 1 && h1_vis1 == 1 &&
        h1_act2 == 5 && h1_cr2 == 1 && h1_vis2 == 0 &&
        h1_act3 == 5 && h1_cr3 == 1 && h1_vis3 == 1 &&
        h1_act4 == 0 && h1_cr4 == 0 && h1_vis4 == 0)
    {
        g_h1_pass = 1;
        print("[TEST-H1] PASS: Hide preserved created capacity (5 -> 5 -> 5 -> 0).");
    }
    else
    {
        printf("[TEST-H1] FAIL: act=(%d,%d,%d,%d) cr=(%d,%d,%d,%d) vis=(%d,%d,%d,%d)",
            h1_act1, h1_act2, h1_act3, h1_act4, h1_cr1, h1_cr2, h1_cr3, h1_cr4, h1_vis1, h1_vis2, h1_vis3, h1_vis4);
    }

    // -------------------------------------------------------------
    // H2: Visible Destroy Accounting Order
    // -------------------------------------------------------------
    print("\n[TEST-H2] Testing Visible Destroy Accounting Order...");
    SUI_ResetPlayer(0);
    g_h2_hide_calls = 0;
    g_h2_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "h2_grp", "OnH2_Create", "OnH2_Destroy", "OnH2_Show", "OnH2_Hide");
    SUI_SetGroupSize(0, "h2_grp", 5);
    SUI_ShowGroup(0, "h2_grp");
    new h2_act_before = SUI_GetActiveTextDrawCount(0);

    SUI_DestroyGroup(0, "h2_grp");
    new h2_act_after = SUI_GetActiveTextDrawCount(0);
    new h2_cr = SUI_IsGroupCreated(0, "h2_grp");
    new h2_vis = SUI_IsGroupVisible(0, "h2_grp");
    SUI_ResetPlayer(0);

    if (h2_act_before == 5 && h2_act_after == 0 && h2_cr == 0 && h2_vis == 0 &&
        g_h2_hide_calls == 1 && g_h2_destroy_calls == 1)
    {
        g_h2_pass = 1;
        print("[TEST-H2] PASS: Visible group destroyed cleanly (hide=1, dest=1, active 5 -> 0).");
    }
    else
    {
        printf("[TEST-H2] FAIL: act_before=%d act_after=%d cr=%d vis=%d hide_c=%d dest_c=%d",
            h2_act_before, h2_act_after, h2_cr, h2_vis, g_h2_hide_calls, g_h2_destroy_calls);
    }

    // -------------------------------------------------------------
    // H3: Hidden Destroy Accounting (No Double Subtraction)
    // -------------------------------------------------------------
    print("\n[TEST-H3] Testing Hidden Destroy Accounting (No Double Subtraction)...");
    SUI_ResetPlayer(0);
    g_h3_hide_calls = 0;
    g_h3_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "h3_grp", "OnH3_Create", "OnH3_Destroy", "OnH3_Show", "OnH3_Hide");
    SUI_SetGroupSize(0, "h3_grp", 5);
    SUI_ShowGroup(0, "h3_grp");
    SUI_HideGroup(0, "h3_grp");
    new h3_act_hidden = SUI_GetActiveTextDrawCount(0);

    SUI_DestroyGroup(0, "h3_grp");
    new h3_act_after = SUI_GetActiveTextDrawCount(0);
    new h3_cr = SUI_IsGroupCreated(0, "h3_grp");
    new h3_vis = SUI_IsGroupVisible(0, "h3_grp");
    SUI_ResetPlayer(0);

    if (h3_act_hidden == 5 && h3_act_after == 0 && h3_cr == 0 && h3_vis == 0 &&
        g_h3_hide_calls == 1 && g_h3_destroy_calls == 1)
    {
        g_h3_pass = 1;
        print("[TEST-H3] PASS: Hidden group destroyed without double subtraction (active 5 -> 0).");
    }
    else
    {
        printf("[TEST-H3] FAIL: act_hidden=%d act_after=%d cr=%d vis=%d hide_c=%d dest_c=%d",
            h3_act_hidden, h3_act_after, h3_cr, h3_vis, g_h3_hide_calls, g_h3_destroy_calls);
    }

    // -------------------------------------------------------------
    // H4: Replacement Callback Guard Ownership
    // -------------------------------------------------------------
    print("\n[TEST-H4] Testing Replacement Callback Guard Ownership (No Stuck Lock)...");
    SUI_ResetPlayer(0);
    g_h4_old_create_calls = 0;
    g_h4_new_create_calls = 0;
    g_h4_new_show_calls = 0;
    g_h4_inplace_res = -1;
    g_h4_repl_res = -1;

    SUI_CreatePlayerFactoryGroup(0, "h4_grp", "OnH4_OldCreate", "OnH4_OldDestroy", "OnH4_OldShow", "OnH4_OldHide");
    SUI_SetGroupSize(0, "h4_grp", 6);
    SUI_ShowGroup(0, "h4_grp"); // OnH4_OldCreate: in-place rejected (0), reset + new generation created (1)

    new h4_mid_cr = SUI_IsGroupCreated(0, "h4_grp");
    new h4_mid_act = SUI_GetActiveTextDrawCount(0);

    // Explicitly show replacement group
    SUI_ShowGroup(0, "h4_grp");
    new h4_fin_cr = SUI_IsGroupCreated(0, "h4_grp");
    new h4_fin_vis = SUI_IsGroupVisible(0, "h4_grp");
    new h4_fin_act = SUI_GetActiveTextDrawCount(0);
    SUI_DestroyGroup(0, "h4_grp");
    SUI_ResetPlayer(0);

    if (g_h4_inplace_res == 0 &&
        g_h4_repl_res == 1 &&
        g_h4_old_create_calls == 1 &&
        g_h4_new_create_calls == 1 &&
        g_h4_new_show_calls == 1 &&
        h4_mid_cr == 0 &&
        h4_mid_act == 0 &&
        h4_fin_cr == 1 &&
        h4_fin_vis == 1 &&
        h4_fin_act == 6)
    {
        g_h4_pass = 1;
        print("[TEST-H4] PASS: In-place re-reg rejected; genuine replacement guard is clean.");
    }
    else
    {
        printf("[TEST-H4] FAIL: in_pl=%d repl=%d old_c=%d new_c=%d new_s=%d mid_cr=%d mid_act=%d fin_cr=%d fin_vis=%d fin_act=%d",
            g_h4_inplace_res, g_h4_repl_res, g_h4_old_create_calls, g_h4_new_create_calls, g_h4_new_show_calls,
            h4_mid_cr, h4_mid_act, h4_fin_cr, h4_fin_vis, h4_fin_act);
    }

    // -------------------------------------------------------------
    // ID-EVICT: Eviction Candidate Genuine ABA Replacement
    // -------------------------------------------------------------
    print("\n[TEST-ID-EVICT] Testing Eviction Candidate Genuine ABA Replacement...");
    SUI_ResetPlayer(0);
    SUI_SetMaxTextDraws(0, 256);
    SUI_SetEvictionThreshold(0, 200);
    g_idevict_cand_destroy_calls = 0;
    g_idevict_new_create_calls = 0;
    g_idevict_req_create_calls = 0;
    g_idevict_inplace_res = -1;
    g_idevict_repl_res = -1;

    // Register and show candidate group (size 50, priority LOW)
    SUI_CreatePlayerFactoryGroup(0, "evict_cand_grp", "OnIDEvict_CandCreate", "OnIDEvict_CandDestroy", "OnIDEvict_CandShow", "OnIDEvict_CandHide");
    SUI_SetGroupSize(0, "evict_cand_grp", 50);
    SUI_SetGroupPriority(0, "evict_cand_grp", SUI_PRIORITY_LOW);
    SUI_SetGroupEvictable(0, "evict_cand_grp", true);
    SUI_ShowGroup(0, "evict_cand_grp");
    SUI_HideGroup(0, "evict_cand_grp"); // hidden, created, size 50, active = 50

    // Trigger eviction with group size 180 (50 + 180 = 230 > 200 threshold)
    SUI_CreatePlayerFactoryGroup(0, "evict_req_grp", "OnIDEvict_ReqCreate", "OnIDEvict_ReqDestroy", "OnIDEvict_ReqShow", "OnIDEvict_ReqHide");
    SUI_SetGroupSize(0, "evict_req_grp", 180);
    SUI_ShowGroup(0, "evict_req_grp"); // Triggers EvictOneHiddenGroup -> OnIDEvict_CandDestroy: in-place rejected, replaced after reset

    new evict_req_cr = SUI_IsGroupCreated(0, "evict_req_grp");
    new evict_cand_cr_mid = SUI_IsGroupCreated(0, "evict_cand_grp");
    new evict_act_mid = SUI_GetActiveTextDrawCount(0);

    // Show replacement group
    SUI_ShowGroup(0, "evict_cand_grp");
    new evict_cand_cr_fin = SUI_IsGroupCreated(0, "evict_cand_grp");
    new evict_cand_vis_fin = SUI_IsGroupVisible(0, "evict_cand_grp");
    new evict_act_fin = SUI_GetActiveTextDrawCount(0);

    SUI_DestroyGroup(0, "evict_cand_grp");
    SUI_DestroyGroup(0, "evict_req_grp");
    SUI_ResetPlayer(0);

    if (g_idevict_inplace_res == 0 &&
        g_idevict_repl_res == 1 &&
        g_idevict_cand_destroy_calls == 1 &&
        g_idevict_req_create_calls == 0 &&
        g_idevict_new_create_calls == 1 &&
        g_idevict_new_show_calls == 1 &&
        evict_req_cr == 0 &&
        evict_cand_cr_mid == 0 &&
        evict_act_mid == 0 &&
        evict_cand_cr_fin == 1 &&
        evict_cand_vis_fin == 1 &&
        evict_act_fin == 15)
    {
        g_id_evict_pass = 1;
        print("[TEST-ID-EVICT] PASS: In-place rejected; genuine ABA replacement preserved without corruption.");
    }
    else
    {
        printf("[TEST-ID-EVICT] FAIL: in_pl=%d repl=%d dest_c=%d req_c=%d new_c=%d new_s=%d req_cr=%d mid_cr=%d mid_act=%d fin_cr=%d fin_vis=%d fin_act=%d",
            g_idevict_inplace_res, g_idevict_repl_res, g_idevict_cand_destroy_calls, g_idevict_req_create_calls, g_idevict_new_create_calls, g_idevict_new_show_calls,
            evict_req_cr, evict_cand_cr_mid, evict_act_mid, evict_cand_cr_fin, evict_cand_vis_fin, evict_act_fin);
    }

    // -------------------------------------------------------------
    // O1: Callback-Window Anti-Hijack
    // -------------------------------------------------------------
    print("\n[TEST-O1] Testing Callback-Window Anti-Hijack...");
    SUI_ResetPlayer(0);
    g_o1_gm_create_calls = 0;
    g_o1_gm_show_calls = 0;

    SUI_CreatePlayerFactoryGroup(0, "owner_lock", "OnO1_GM_Create", "OnO1_GM_Destroy", "OnO1_GM_Show", "OnO1_GM_Hide");
    SUI_SetGroupSize(0, "owner_lock", 4);
    SUI_ShowGroup(0, "owner_lock"); // triggers OnO1_GM_Create -> FS_TryHijackO1

    new o1_hijack_res = CallRemoteFunction("FS_GetO1HijackResult", "");
    new o1_cr = SUI_IsGroupCreated(0, "owner_lock");
    new o1_vis = SUI_IsGroupVisible(0, "owner_lock");
    new o1_act = SUI_GetActiveTextDrawCount(0); // 4

    new fs_o1_c = CallRemoteFunction("FS_GetO1CreateCalls", "");
    new fs_o1_s = CallRemoteFunction("FS_GetO1ShowCalls", "");

    SUI_DestroyGroup(0, "owner_lock");
    new o1_act_post = SUI_GetActiveTextDrawCount(0); // 0
    SUI_ResetPlayer(0);

    if (o1_hijack_res == 0 &&
        g_o1_gm_create_calls == 1 &&
        g_o1_gm_show_calls == 1 &&
        o1_cr == 1 &&
        o1_vis == 1 &&
        o1_act == 4 &&
        o1_act_post == 0 &&
        fs_o1_c == 0 &&
        fs_o1_s == 0)
    {
        g_o1_pass = 1;
        print("[TEST-O1] PASS: Callback-window hijack rejected (0); GM owns group; FS never executes.");
    }
    else
    {
        printf("[TEST-O1] FAIL: hijack_res=%d gm_c=%d gm_s=%d cr=%d vis=%d act=%d post_act=%d fs_c=%d fs_s=%d",
            o1_hijack_res, g_o1_gm_create_calls, g_o1_gm_show_calls, o1_cr, o1_vis, o1_act, o1_act_post, fs_o1_c, fs_o1_s);
    }

    // -------------------------------------------------------------
    // O2: Legitimate Cross-AMX Reuse After Removal
    // -------------------------------------------------------------
    print("\n[TEST-O2] Testing Legitimate Cross-AMX Reuse After Removal...");
    SUI_ResetPlayer(0);

    // Gamemode registers and shows owner_reuse
    SUI_CreatePlayerFactoryGroup(0, "owner_reuse", "OnO1_GM_Create", "OnO1_GM_Destroy", "OnO1_GM_Show", "OnO1_GM_Hide");
    SUI_SetGroupSize(0, "owner_reuse", 5);
    SUI_ShowGroup(0, "owner_reuse");
    SUI_DestroyGroup(0, "owner_reuse");
    SUI_ResetPlayer(0); // fully removed from SUI tracking

    // Filterscript registers owner_reuse
    new fs_o2_setup_res = CallRemoteFunction("FS_SetupReuseO2", "d", 0);
    new fs_o2_show_res = CallRemoteFunction("FS_ShowReuseO2", "d", 0);

    new o2_cr = SUI_IsGroupCreated(0, "owner_reuse");
    new o2_vis = SUI_IsGroupVisible(0, "owner_reuse");
    new o2_act = SUI_GetActiveTextDrawCount(0); // 8

    new fs_o2_c = CallRemoteFunction("FS_GetO2CreateCalls", "");
    new fs_o2_s = CallRemoteFunction("FS_GetO2ShowCalls", "");

    CallRemoteFunction("FS_DestroyReuseO2", "d", 0);
    new o2_act_post = SUI_GetActiveTextDrawCount(0); // 0
    SUI_ResetPlayer(0);

    if (fs_o2_setup_res == 1 &&
        fs_o2_show_res == 1 &&
        o2_cr == 1 &&
        o2_vis == 1 &&
        o2_act == 8 &&
        o2_act_post == 0 &&
        fs_o2_c == 1 &&
        fs_o2_s == 1)
    {
        g_o2_pass = 1;
        print("[TEST-O2] PASS: Legitimate cross-AMX reuse after removal succeeded with new owner.");
    }
    else
    {
        printf("[TEST-O2] FAIL: setup_res=%d show_res=%d cr=%d vis=%d act=%d post_act=%d fs_c=%d fs_s=%d",
            fs_o2_setup_res, fs_o2_show_res, o2_cr, o2_vis, o2_act, o2_act_post, fs_o2_c, fs_o2_s);
    }

    // -------------------------------------------------------------
    // RAG1: Same-Owner Callback Re-registration Rejected
    // -------------------------------------------------------------
    print("\n[TEST-RAG1] Testing Resource Accounting: Same-Owner Callback Re-reg Rejected...");
    SUI_ResetPlayer(0);
    g_rag1_create_calls = 0;
    g_rag1_rereg_result = -1;

    SUI_CreatePlayerFactoryGroup(0, "rag1_grp", "OnRAG1_Create", "OnRAG1_Destroy", "OnRAG1_Show", "OnRAG1_Hide");
    SUI_SetGroupSize(0, "rag1_grp", 5);
    SUI_ShowGroup(0, "rag1_grp"); // OnRAG1_Create attempts re-registration

    new rag1_cr_mid = SUI_IsGroupCreated(0, "rag1_grp");
    new rag1_vis_mid = SUI_IsGroupVisible(0, "rag1_grp");
    new rag1_act_mid = SUI_GetActiveTextDrawCount(0); // 5

    SUI_DestroyGroup(0, "rag1_grp");
    new rag1_act_post = SUI_GetActiveTextDrawCount(0); // 0
    SUI_ResetPlayer(0);

    if (g_rag1_rereg_result == 0 &&
        g_rag1_create_calls == 1 &&
        rag1_cr_mid == 1 &&
        rag1_vis_mid == 1 &&
        rag1_act_mid == 5 &&
        rag1_act_post == 0)
    {
        g_rag1_pass = 1;
        print("[TEST-RAG1] PASS: Same-owner re-reg during callback rejected (0); capacity conserved (5 -> 0).");
    }
    else
    {
        printf("[TEST-RAG1] FAIL: rereg_res=%d calls=%d cr=%d vis=%d act=%d post_act=%d",
            g_rag1_rereg_result, g_rag1_create_calls, rag1_cr_mid, rag1_vis_mid, rag1_act_mid, rag1_act_post);
    }

    // -------------------------------------------------------------
    // RAG2: Cross-AMX Hijack During Callback Rejected
    // -------------------------------------------------------------
    print("\n[TEST-RAG2] Testing Resource Accounting: Cross-AMX Hijack During Callback Rejected...");
    SUI_ResetPlayer(0);
    g_rag2_create_calls = 0;

    SUI_CreatePlayerFactoryGroup(0, "rag2_grp", "OnRAG2_Create", "OnRAG2_Destroy", "OnRAG2_Show", "OnRAG2_Hide");
    SUI_SetGroupSize(0, "rag2_grp", 5);
    SUI_ShowGroup(0, "rag2_grp"); // OnRAG2_Create triggers FS_TryHijackRAG2

    new rag2_hijack_res = CallRemoteFunction("FS_GetRAG2HijackResult", "");
    new rag2_cr_mid = SUI_IsGroupCreated(0, "rag2_grp");
    new rag2_vis_mid = SUI_IsGroupVisible(0, "rag2_grp");
    new rag2_act_mid = SUI_GetActiveTextDrawCount(0); // 5

    SUI_DestroyGroup(0, "rag2_grp");
    new rag2_act_post = SUI_GetActiveTextDrawCount(0); // 0
    SUI_ResetPlayer(0);

    if (rag2_hijack_res == 0 &&
        g_rag2_create_calls == 1 &&
        rag2_cr_mid == 1 &&
        rag2_vis_mid == 1 &&
        rag2_act_mid == 5 &&
        rag2_act_post == 0)
    {
        g_rag2_pass = 1;
        print("[TEST-RAG2] PASS: Cross-AMX hijack during callback rejected (0); capacity conserved (5 -> 0).");
    }
    else
    {
        printf("[TEST-RAG2] FAIL: hijack_res=%d calls=%d cr=%d vis=%d act=%d post_act=%d",
            rag2_hijack_res, g_rag2_create_calls, rag2_cr_mid, rag2_vis_mid, rag2_act_mid, rag2_act_post);
    }

    // -------------------------------------------------------------
    // RAG3: Legitimate Replacement Resource Accounting Reuse
    // -------------------------------------------------------------
    print("\n[TEST-RAG3] Testing Resource Accounting: Legitimate Replacement Resource Reuse...");
    SUI_ResetPlayer(0);
    new rag3_act_init = SUI_GetActiveTextDrawCount(0); // 0

    new rag3_reg_res = SUI_CreatePlayerFactoryGroup(0, "rag3_grp", "OnRAG1_Create", "OnRAG1_Destroy", "OnRAG1_Show", "OnRAG1_Hide");
    SUI_SetGroupSize(0, "rag3_grp", 7);
    SUI_ShowGroup(0, "rag3_grp");

    new rag3_cr = SUI_IsGroupCreated(0, "rag3_grp");
    new rag3_vis = SUI_IsGroupVisible(0, "rag3_grp");
    new rag3_act_shown = SUI_GetActiveTextDrawCount(0); // 7

    SUI_DestroyGroup(0, "rag3_grp");
    new rag3_act_post = SUI_GetActiveTextDrawCount(0); // 0
    SUI_ResetPlayer(0);

    if (rag3_act_init == 0 &&
        rag3_reg_res == 1 &&
        rag3_cr == 1 &&
        rag3_vis == 1 &&
        rag3_act_shown == 7 &&
        rag3_act_post == 0)
    {
        g_rag3_pass = 1;
        print("[TEST-RAG3] PASS: Legitimate replacement resource accounting clean (0 -> 7 -> 0).");
    }
    else
    {
        printf("[TEST-RAG3] FAIL: init=%d reg=%d cr=%d vis=%d shown=%d post=%d",
            rag3_act_init, rag3_reg_res, rag3_cr, rag3_vis, rag3_act_shown, rag3_act_post);
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
    print("----------------------------------------------------------------");
    print("      SUI-017 LIFECYCLE RECONCILIATION RESULTS (H1-H4)          ");
    print("----------------------------------------------------------------");
    if (g_h1_pass) printf("H1   (Hide Preserves Created Capacity):     PASS");
    else printf("H1   (Hide Preserves Created Capacity):     FAIL");
    if (g_h2_pass) printf("H2   (Visible Destroy Accounting Order):    PASS");
    else printf("H2   (Visible Destroy Accounting Order):    FAIL");
    if (g_h3_pass) printf("H3   (Hidden Destroy Accounting Order):     PASS");
    else printf("H3   (Hidden Destroy Accounting Order):     FAIL");
    if (g_h4_pass) printf("H4   (Replacement Callback Guard Ownership):PASS");
    else printf("H4   (Replacement Callback Guard Ownership):FAIL");
    print("----------------------------------------------------------------");
    print("      SUI-017 EXTENDED ABA ACCEPTANCE SCENARIOS                 ");
    print("----------------------------------------------------------------");
    if (g_id_evict_pass) printf("ID-EVICT     (Eviction ABA Candidate Replace): PASS");
    else printf("ID-EVICT     (Eviction ABA Candidate Replace): FAIL");
    print("----------------------------------------------------------------");
    print("      SUI-002 / SUI-017 OWNERSHIP & ANTI-HIJACK (O1-O2)         ");
    print("----------------------------------------------------------------");
    if (g_o1_pass) printf("O1   (Callback-Window Anti-Hijack Guard):   PASS");
    else printf("O1   (Callback-Window Anti-Hijack Guard):   FAIL");
    if (g_o2_pass) printf("O2   (Legitimate Cross-AMX Group Reuse):    PASS");
    else printf("O2   (Legitimate Cross-AMX Group Reuse):    FAIL");
    print("----------------------------------------------------------------");
    print("      RESOURCE ACCOUNTING GATE TESTS (RAG1-RAG3)                ");
    print("----------------------------------------------------------------");
    if (g_rag1_pass) printf("RAG1 (Same-Owner Re-reg Rejected / Conserved):PASS");
    else printf("RAG1 (Same-Owner Re-reg Rejected / Conserved):FAIL");
    if (g_rag2_pass) printf("RAG2 (Cross-AMX Hijack Rejected / Conserved): PASS");
    else printf("RAG2 (Cross-AMX Hijack Rejected / Conserved): FAIL");
    if (g_rag3_pass) printf("RAG3 (Legitimate Replacement Accounting):     PASS");
    else printf("RAG3 (Legitimate Replacement Accounting):     FAIL");
    print("================================================================");

    new total_pass = g_id1_pass + g_id2_pass + g_id3_pass + g_id4_pass + g_id5_pass +
                     g_id6_pass + g_id7_pass + g_id8_pass + g_id9_pass + g_id10_pass +
                     g_h1_pass + g_h2_pass + g_h3_pass + g_h4_pass +
                     g_id_evict_pass +
                     g_o1_pass + g_o2_pass +
                     g_rag1_pass + g_rag2_pass + g_rag3_pass;

    if (total_pass == 20)
    {
        print("OVERALL RESULT: ALL GROUP IDENTITY, LIFECYCLE & OWNERSHIP TESTS PASSED! (20/20)");
    }
    else
    {
        printf("OVERALL RESULT: %d/20 TESTS PASSED.", total_pass);
    }
    print("================================================================\n");
}
