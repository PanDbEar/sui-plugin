#include <a_samp>
#include "../../pawn/sui.inc"

new g_test_t1_pass = 0;
new g_test_t2_pass = 0;
new g_test_t3_pass = 0;
new g_test_t4_pass = 0;
new g_test_t5_pass = 0;
new g_test_t6_pass = 0;
new g_test_t7_pass = 0;
new g_test_t8_pass = 0;
new g_test_t9_pass = 0;
new g_test_t10_pass = 0;
new g_test_t11_pass = 0;
new g_test_t12_pass = 0;
new g_test_t13_pass = 0;
new g_test_t14_pass = 0;
new g_test_t15_pass = 0;
new g_test_t16_pass = 0;

// Callbacks for T1
forward OnT1_Vis_Create(playerid); public OnT1_Vis_Create(playerid) { return 1; }
forward OnT1_Vis_Destroy(playerid); public OnT1_Vis_Destroy(playerid) { return 1; }
forward OnT1_Vis_Show(playerid); public OnT1_Vis_Show(playerid) { return 1; }
forward OnT1_Vis_Hide(playerid); public OnT1_Vis_Hide(playerid) { return 1; }

forward OnT1_Hid_Create(playerid); public OnT1_Hid_Create(playerid) { return 1; }
forward OnT1_Hid_Destroy(playerid); public OnT1_Hid_Destroy(playerid) { return 1; }
forward OnT1_Hid_Show(playerid); public OnT1_Hid_Show(playerid) { return 1; }
forward OnT1_Hid_Hide(playerid); public OnT1_Hid_Hide(playerid) { return 1; }

forward OnT1_Unc_Create(playerid); public OnT1_Unc_Create(playerid) { return 1; }
forward OnT1_Unc_Destroy(playerid); public OnT1_Unc_Destroy(playerid) { return 1; }
forward OnT1_Unc_Show(playerid); public OnT1_Unc_Show(playerid) { return 1; }
forward OnT1_Unc_Hide(playerid); public OnT1_Unc_Hide(playerid) { return 1; }

// Callbacks for T2
new g_t2_reg_res = -1;
forward OnT2_Old_Create(playerid); public OnT2_Old_Create(playerid) { return 1; }
forward OnT2_Old_Destroy(playerid);
public OnT2_Old_Destroy(playerid)
{
    g_t2_reg_res = SUI_CreatePlayerFactoryGroup(playerid, "t2_spawned", "OnT2_Sp_Create", "OnT2_Sp_Destroy", "OnT2_Sp_Show", "OnT2_Sp_Hide");
    printf("[TEST-T2] Inside OnT2_Old_Destroy, registration of t2_spawned returned: %d", g_t2_reg_res);
    return 1;
}
forward OnT2_Old_Show(playerid); public OnT2_Old_Show(playerid) { return 1; }
forward OnT2_Old_Hide(playerid); public OnT2_Old_Hide(playerid) { return 1; }

forward OnT2_Sp_Create(playerid); public OnT2_Sp_Create(playerid) { return 1; }
forward OnT2_Sp_Destroy(playerid); public OnT2_Sp_Destroy(playerid) { return 1; }
forward OnT2_Sp_Show(playerid); public OnT2_Sp_Show(playerid) { return 1; }
forward OnT2_Sp_Hide(playerid); public OnT2_Sp_Hide(playerid) { return 1; }

// Callbacks for T3
new g_t3_reg_res = -1;
forward OnT3_Old_Create(playerid); public OnT3_Old_Create(playerid) { return 1; }
forward OnT3_Old_Destroy(playerid);
public OnT3_Old_Destroy(playerid)
{
    g_t3_reg_res = SUI_CreatePlayerFactoryGroup(playerid, "t3_spawned", "OnT3_Sp_Create", "OnT3_Sp_Destroy", "OnT3_Sp_Show", "OnT3_Sp_Hide");
    printf("[TEST-T3] Inside OnT3_Old_Destroy, registration of t3_spawned returned: %d", g_t3_reg_res);
    return 1;
}
forward OnT3_Old_Show(playerid); public OnT3_Old_Show(playerid) { return 1; }
forward OnT3_Old_Hide(playerid); public OnT3_Old_Hide(playerid) { return 1; }

forward OnT3_Sp_Create(playerid); public OnT3_Sp_Create(playerid) { return 1; }
forward OnT3_Sp_Destroy(playerid); public OnT3_Sp_Destroy(playerid) { return 1; }
forward OnT3_Sp_Show(playerid); public OnT3_Sp_Show(playerid) { return 1; }
forward OnT3_Sp_Hide(playerid); public OnT3_Sp_Hide(playerid) { return 1; }

// Callbacks for T4
forward OnT4_Good_Create(playerid); public OnT4_Good_Create(playerid) { return 1; }
forward OnT4_Good_Destroy(playerid); public OnT4_Good_Destroy(playerid) { return 1; }
forward OnT4_Good_Show(playerid); public OnT4_Good_Show(playerid) { return 1; }
forward OnT4_Good_Hide(playerid); public OnT4_Good_Hide(playerid) { return 1; }

forward OnT4_Err_Create(playerid); public OnT4_Err_Create(playerid) { return 1; }
forward OnT4_Err_Destroy(playerid);
public OnT4_Err_Destroy(playerid)
{
    printf("[TEST-T4] Triggering intentional divide-by-zero runtime error in OnT4_Err_Destroy...");
    new zero = 0;
    new err = 100 / zero;
    #pragma unused err
    return 1;
}
forward OnT4_Err_Show(playerid); public OnT4_Err_Show(playerid) { return 1; }
forward OnT4_Err_Hide(playerid); public OnT4_Err_Hide(playerid) { return 1; }

// Callbacks for T5
forward OnT5_Good_Create(playerid); public OnT5_Good_Create(playerid) { return 1; }
forward OnT5_Good_Destroy(playerid); public OnT5_Good_Destroy(playerid) { return 1; }
forward OnT5_Good_Show(playerid); public OnT5_Good_Show(playerid) { return 1; }
forward OnT5_Good_Hide(playerid); public OnT5_Good_Hide(playerid) { return 1; }

forward OnT5_Err_Create(playerid); public OnT5_Err_Create(playerid) { return 1; }
forward OnT5_Err_Destroy(playerid);
public OnT5_Err_Destroy(playerid)
{
    printf("[TEST-T5] Triggering intentional divide-by-zero runtime error in OnT5_Err_Destroy...");
    new zero = 0;
    new err = 100 / zero;
    #pragma unused err
    return 1;
}
forward OnT5_Err_Show(playerid); public OnT5_Err_Show(playerid) { return 1; }
forward OnT5_Err_Hide(playerid); public OnT5_Err_Hide(playerid) { return 1; }

// Callbacks for T6
new g_t6_nested_res = -1;
forward OnT6_Create(playerid); public OnT6_Create(playerid) { return 1; }
forward OnT6_Destroy(playerid);
public OnT6_Destroy(playerid)
{
    g_t6_nested_res = SUI_CleanupPlayer(playerid);
    printf("[TEST-T6] Nested SUI_CleanupPlayer returned: %d", g_t6_nested_res);
    return 1;
}
forward OnT6_Show(playerid); public OnT6_Show(playerid) { return 1; }
forward OnT6_Hide(playerid); public OnT6_Hide(playerid) { return 1; }

// Callbacks for T7
new g_t7_nested_res = -1;
forward OnT7_Create(playerid); public OnT7_Create(playerid) { return 1; }
forward OnT7_Destroy(playerid);
public OnT7_Destroy(playerid)
{
    g_t7_nested_res = SUI_ResetPlayer(playerid);
    printf("[TEST-T7] Nested SUI_ResetPlayer returned: %d", g_t7_nested_res);
    return 1;
}
forward OnT7_Show(playerid); public OnT7_Show(playerid) { return 1; }
forward OnT7_Hide(playerid); public OnT7_Hide(playerid) { return 1; }

// Callbacks for T8
new g_t8_show_res = -1;
forward OnT8_Create(playerid); public OnT8_Create(playerid) { return 1; }
forward OnT8_Destroy(playerid);
public OnT8_Destroy(playerid)
{
    g_t8_show_res = SUI_ShowGroup(playerid, "t8_other");
    printf("[TEST-T8] SUI_ShowGroup during teardown returned: %d", g_t8_show_res);
    return 1;
}
forward OnT8_Show(playerid); public OnT8_Show(playerid) { return 1; }
forward OnT8_Hide(playerid); public OnT8_Hide(playerid) { return 1; }

forward OnT8_Oth_Create(playerid); public OnT8_Oth_Create(playerid) { return 1; }
forward OnT8_Oth_Destroy(playerid); public OnT8_Oth_Destroy(playerid) { return 1; }
forward OnT8_Oth_Show(playerid); public OnT8_Oth_Show(playerid) { return 1; }
forward OnT8_Oth_Hide(playerid); public OnT8_Oth_Hide(playerid) { return 1; }

// Callbacks for T9
new g_t9_rereg_res = -1;
forward OnT9_Create(playerid); public OnT9_Create(playerid) { return 1; }
forward OnT9_Destroy(playerid);
public OnT9_Destroy(playerid)
{
    g_t9_rereg_res = SUI_CreatePlayerFactoryGroup(playerid, "t9_grp", "OnT9_Create", "OnT9_Destroy", "OnT9_Show", "OnT9_Hide");
    printf("[TEST-T9] Same-name re-registration during teardown returned: %d", g_t9_rereg_res);
    return 1;
}
forward OnT9_Show(playerid); public OnT9_Show(playerid) { return 1; }
forward OnT9_Hide(playerid); public OnT9_Hide(playerid) { return 1; }

// Callbacks for T10
new g_t10_create_calls = 0;
new g_t10_destroy_calls = 0;
forward OnT10_Create(playerid);
public OnT10_Create(playerid)
{
    g_t10_create_calls++;
    return 1;
}
forward OnT10_Destroy(playerid);
public OnT10_Destroy(playerid)
{
    g_t10_destroy_calls++;
    return 1;
}
forward OnT10_Show(playerid); public OnT10_Show(playerid) { return 1; }
forward OnT10_Hide(playerid); public OnT10_Hide(playerid) { return 1; }

// Callbacks for T11
new g_t11_vis_hide_calls = 0;
new g_t11_vis_destroy_calls = 0;
new g_t11_hid_hide_calls = 0;
new g_t11_hid_destroy_calls = 0;

forward OnT11_Vis_Create(playerid); public OnT11_Vis_Create(playerid) { return 1; }
forward OnT11_Vis_Destroy(playerid);
public OnT11_Vis_Destroy(playerid)
{
    g_t11_vis_destroy_calls++;
    return 1;
}
forward OnT11_Vis_Show(playerid); public OnT11_Vis_Show(playerid) { return 1; }
forward OnT11_Vis_Hide(playerid);
public OnT11_Vis_Hide(playerid)
{
    g_t11_vis_hide_calls++;
    return 1;
}

forward OnT11_Hid_Create(playerid); public OnT11_Hid_Create(playerid) { return 1; }
forward OnT11_Hid_Destroy(playerid);
public OnT11_Hid_Destroy(playerid)
{
    g_t11_hid_destroy_calls++;
    return 1;
}
forward OnT11_Hid_Show(playerid); public OnT11_Hid_Show(playerid) { return 1; }
forward OnT11_Hid_Hide(playerid);
public OnT11_Hid_Hide(playerid)
{
    g_t11_hid_hide_calls++;
    return 1;
}

// Callbacks for T13
new g_t13_gm_destroy_calls = 0;
forward OnT13_GM_Create(playerid); public OnT13_GM_Create(playerid) { return 1; }
forward OnT13_GM_Destroy(playerid);
public OnT13_GM_Destroy(playerid)
{
    g_t13_gm_destroy_calls++;
    return 1;
}
forward OnT13_GM_Show(playerid); public OnT13_GM_Show(playerid) { return 1; }
forward OnT13_GM_Hide(playerid); public OnT13_GM_Hide(playerid) { return 1; }

// Callbacks for T14 & T15
forward OnT14_Create(playerid); public OnT14_Create(playerid) { return 1; }
forward OnT14_Show(playerid); public OnT14_Show(playerid) { return 1; }
forward OnT14_Hide(playerid); public OnT14_Hide(playerid) { return 1; }

forward OnT15_Create(playerid); public OnT15_Create(playerid) { return 1; }
forward OnT15_Show(playerid); public OnT15_Show(playerid) { return 1; }
forward OnT15_Hide(playerid); public OnT15_Hide(playerid) { return 1; }

// Callbacks for T16
forward OnT16_Fail_Create(playerid); public OnT16_Fail_Create(playerid) { return 1; }
forward OnT16_Fail_Show(playerid); public OnT16_Fail_Show(playerid) { return 1; }
forward OnT16_Fail_Hide(playerid); public OnT16_Fail_Hide(playerid) { return 1; }

forward OnT16_Recov_Create(playerid); public OnT16_Recov_Create(playerid) { return 1; }
forward OnT16_Recov_Destroy(playerid); public OnT16_Recov_Destroy(playerid) { return 1; }
forward OnT16_Recov_Show(playerid); public OnT16_Recov_Show(playerid) { return 1; }
forward OnT16_Recov_Hide(playerid); public OnT16_Recov_Hide(playerid) { return 1; }

public OnGameModeInit()
{
    print("\n================================================================");
    print("      SUI PHASE 8: PLAYER TEARDOWN & RE-ENTRANCY (T1-T16)      ");
    print("================================================================\n");

    SUI_SetDebug(true);

    // -------------------------------------------------------------
    // T1: Normal Cleanup
    // -------------------------------------------------------------
    print("[TEST-T1] Starting T1 (Normal Cleanup)...");
    SUI_CleanupPlayer(0);
    SUI_CreatePlayerFactoryGroup(0, "t1_vis", "OnT1_Vis_Create", "OnT1_Vis_Destroy", "OnT1_Vis_Show", "OnT1_Vis_Hide");
    SUI_SetGroupSize(0, "t1_vis", 4);
    SUI_ShowGroup(0, "t1_vis");

    SUI_CreatePlayerFactoryGroup(0, "t1_hid", "OnT1_Hid_Create", "OnT1_Hid_Destroy", "OnT1_Hid_Show", "OnT1_Hid_Hide");
    SUI_SetGroupSize(0, "t1_hid", 6);
    SUI_ShowGroup(0, "t1_hid");
    SUI_HideGroup(0, "t1_hid");

    SUI_CreatePlayerFactoryGroup(0, "t1_unc", "OnT1_Unc_Create", "OnT1_Unc_Destroy", "OnT1_Unc_Show", "OnT1_Unc_Hide");
    SUI_SetGroupSize(0, "t1_unc", 5);

    new t1_act_pre = SUI_GetActiveTextDrawCount(0); // 10
    new t1_res = SUI_CleanupPlayer(0);
    new t1_act_post = SUI_GetActiveTextDrawCount(0); // 0
    new t1_cr_vis = SUI_IsGroupCreated(0, "t1_vis");
    new t1_cr_hid = SUI_IsGroupCreated(0, "t1_hid");
    new t1_cr_unc = SUI_IsGroupCreated(0, "t1_unc");

    if (t1_act_pre == 10 && t1_res == 1 && t1_act_post == 0 && t1_cr_vis == 0 && t1_cr_hid == 0 && t1_cr_unc == 0)
    {
        g_test_t1_pass = 1;
        print("[TEST-T1] PASS: Normal cleanup purged all groups and context cleanly.");
    }
    else
    {
        printf("[TEST-T1] FAIL: t1_act_pre=%d t1_res=%d t1_act_post=%d vis=%d hid=%d unc=%d",
            t1_act_pre, t1_res, t1_act_post, t1_cr_vis, t1_cr_hid, t1_cr_unc);
    }

    // -------------------------------------------------------------
    // T2: Cleanup Callback Tries New Registration
    // -------------------------------------------------------------
    print("\n[TEST-T2] Starting T2 (Cleanup Callback Tries New Registration)...");
    SUI_CleanupPlayer(0);
    g_t2_reg_res = -1;
    SUI_CreatePlayerFactoryGroup(0, "t2_old", "OnT2_Old_Create", "OnT2_Old_Destroy", "OnT2_Old_Show", "OnT2_Old_Hide");
    SUI_SetGroupSize(0, "t2_old", 3);
    SUI_ShowGroup(0, "t2_old");

    new t2_res = SUI_CleanupPlayer(0);
    new t2_sp_cr = SUI_IsGroupCreated(0, "t2_spawned");
    new t2_act = SUI_GetActiveTextDrawCount(0);

    if (t2_res == 1 && g_t2_reg_res == 0 && t2_sp_cr == 0 && t2_act == 0)
    {
        g_test_t2_pass = 1;
        print("[TEST-T2] PASS: Registration during cleanup was rejected (ret=0).");
    }
    else
    {
        printf("[TEST-T2] FAIL: t2_res=%d g_t2_reg_res=%d t2_sp_cr=%d t2_act=%d",
            t2_res, g_t2_reg_res, t2_sp_cr, t2_act);
    }

    // -------------------------------------------------------------
    // T3: Reset Callback Tries New Registration
    // -------------------------------------------------------------
    print("\n[TEST-T3] Starting T3 (Reset Callback Tries New Registration)...");
    SUI_CleanupPlayer(0);
    g_t3_reg_res = -1;
    SUI_CreatePlayerFactoryGroup(0, "t3_old", "OnT3_Old_Create", "OnT3_Old_Destroy", "OnT3_Old_Show", "OnT3_Old_Hide");
    SUI_SetGroupSize(0, "t3_old", 3);
    SUI_ShowGroup(0, "t3_old");

    new t3_res = SUI_ResetPlayer(0);
    new t3_sp_cr = SUI_IsGroupCreated(0, "t3_spawned");
    new t3_act = SUI_GetActiveTextDrawCount(0);

    if (t3_res == 1 && g_t3_reg_res == 0 && t3_sp_cr == 0 && t3_act == 0)
    {
        g_test_t3_pass = 1;
        print("[TEST-T3] PASS: Registration during reset was rejected (ret=0).");
    }
    else
    {
        printf("[TEST-T3] FAIL: t3_res=%d g_t3_reg_res=%d t3_sp_cr=%d t3_act=%d",
            t3_res, g_t3_reg_res, t3_sp_cr, t3_act);
    }

    // -------------------------------------------------------------
    // T4: Reset Destroy Callback Execution Error
    // -------------------------------------------------------------
    print("\n[TEST-T4] Starting T4 (Reset Destroy Callback Execution Error)...");
    SUI_CleanupPlayer(0);
    SUI_CreatePlayerFactoryGroup(0, "t4_good", "OnT4_Good_Create", "OnT4_Good_Destroy", "OnT4_Good_Show", "OnT4_Good_Hide");
    SUI_SetGroupSize(0, "t4_good", 3);
    SUI_ShowGroup(0, "t4_good");

    SUI_CreatePlayerFactoryGroup(0, "t4_err", "OnT4_Err_Create", "OnT4_Err_Destroy", "OnT4_Err_Show", "OnT4_Err_Hide");
    SUI_SetGroupSize(0, "t4_err", 5);
    SUI_ShowGroup(0, "t4_err");

    new t4_res = SUI_ResetPlayer(0);
    new t4_good_cr = SUI_IsGroupCreated(0, "t4_good");
    new t4_err_cr = SUI_IsGroupCreated(0, "t4_err");
    new t4_act = SUI_GetActiveTextDrawCount(0);

    if (t4_res == 0 && t4_good_cr == 0 && t4_err_cr == 1 && t4_act == 5)
    {
        g_test_t4_pass = 1;
        print("[TEST-T4] PASS: Reset preserved failed group state and capacity (ret=0).");
    }
    else
    {
        printf("[TEST-T4] FAIL: t4_res=%d good_cr=%d err_cr=%d act=%d",
            t4_res, t4_good_cr, t4_err_cr, t4_act);
    }
    SUI_CleanupPlayer(0);

    // -------------------------------------------------------------
    // T5: Cleanup Destroy Callback Execution Error
    // -------------------------------------------------------------
    print("\n[TEST-T5] Starting T5 (Cleanup Destroy Callback Execution Error)...");
    SUI_CleanupPlayer(0);
    SUI_CreatePlayerFactoryGroup(0, "t5_good", "OnT5_Good_Create", "OnT5_Good_Destroy", "OnT5_Good_Show", "OnT5_Good_Hide");
    SUI_SetGroupSize(0, "t5_good", 3);
    SUI_ShowGroup(0, "t5_good");

    SUI_CreatePlayerFactoryGroup(0, "t5_err", "OnT5_Err_Create", "OnT5_Err_Destroy", "OnT5_Err_Show", "OnT5_Err_Hide");
    SUI_SetGroupSize(0, "t5_err", 5);
    SUI_ShowGroup(0, "t5_err");

    new t5_res = SUI_CleanupPlayer(0);
    new t5_err_cr = SUI_IsGroupCreated(0, "t5_err");
    new t5_act = SUI_GetActiveTextDrawCount(0);

    if (t5_res == 0 && t5_err_cr == 0 && t5_act == 0)
    {
        g_test_t5_pass = 1;
        print("[TEST-T5] PASS: Cleanup reported failure (ret=0) and purged context.");
    }
    else
    {
        printf("[TEST-T5] FAIL: t5_res=%d err_cr=%d act=%d", t5_res, t5_err_cr, t5_act);
    }

    // -------------------------------------------------------------
    // T6: Nested CleanupPlayer
    // -------------------------------------------------------------
    print("\n[TEST-T6] Starting T6 (Nested CleanupPlayer)...");
    SUI_CleanupPlayer(0);
    g_t6_nested_res = -1;
    SUI_CreatePlayerFactoryGroup(0, "t6_grp", "OnT6_Create", "OnT6_Destroy", "OnT6_Show", "OnT6_Hide");
    SUI_SetGroupSize(0, "t6_grp", 3);
    SUI_ShowGroup(0, "t6_grp");

    new t6_res = SUI_CleanupPlayer(0);
    new t6_act = SUI_GetActiveTextDrawCount(0);

    if (t6_res == 1 && g_t6_nested_res == 0 && t6_act == 0)
    {
        g_test_t6_pass = 1;
        print("[TEST-T6] PASS: Nested CleanupPlayer rejected (ret=0), outer succeeded.");
    }
    else
    {
        printf("[TEST-T6] FAIL: t6_res=%d nested=%d act=%d", t6_res, g_t6_nested_res, t6_act);
    }

    // -------------------------------------------------------------
    // T7: Nested ResetPlayer
    // -------------------------------------------------------------
    print("\n[TEST-T7] Starting T7 (Nested ResetPlayer)...");
    SUI_CleanupPlayer(0);
    g_t7_nested_res = -1;
    SUI_CreatePlayerFactoryGroup(0, "t7_grp", "OnT7_Create", "OnT7_Destroy", "OnT7_Show", "OnT7_Hide");
    SUI_SetGroupSize(0, "t7_grp", 3);
    SUI_ShowGroup(0, "t7_grp");

    new t7_res = SUI_ResetPlayer(0);
    new t7_act = SUI_GetActiveTextDrawCount(0);

    if (t7_res == 1 && g_t7_nested_res == 0 && t7_act == 0)
    {
        g_test_t7_pass = 1;
        print("[TEST-T7] PASS: Nested ResetPlayer rejected (ret=0), outer succeeded.");
    }
    else
    {
        printf("[TEST-T7] FAIL: t7_res=%d nested=%d act=%d", t7_res, g_t7_nested_res, t7_act);
    }

    // -------------------------------------------------------------
    // T8: ShowGroup During Teardown
    // -------------------------------------------------------------
    print("\n[TEST-T8] Starting T8 (ShowGroup During Teardown)...");
    SUI_CleanupPlayer(0);
    g_t8_show_res = -1;
    SUI_CreatePlayerFactoryGroup(0, "t8_grp", "OnT8_Create", "OnT8_Destroy", "OnT8_Show", "OnT8_Hide");
    SUI_SetGroupSize(0, "t8_grp", 3);
    SUI_ShowGroup(0, "t8_grp");

    SUI_CreatePlayerFactoryGroup(0, "t8_other", "OnT8_Oth_Create", "OnT8_Oth_Destroy", "OnT8_Oth_Show", "OnT8_Oth_Hide");
    SUI_SetGroupSize(0, "t8_other", 4);

    new t8_res = SUI_ResetPlayer(0);
    new t8_oth_cr = SUI_IsGroupCreated(0, "t8_other");

    if (t8_res == 1 && g_t8_show_res == 0 && t8_oth_cr == 0)
    {
        g_test_t8_pass = 1;
        print("[TEST-T8] PASS: ShowGroup rejected during teardown (ret=0).");
    }
    else
    {
        printf("[TEST-T8] FAIL: t8_res=%d show_res=%d oth_cr=%d", t8_res, g_t8_show_res, t8_oth_cr);
    }

    // -------------------------------------------------------------
    // T9: Same-Name Re-Registration During Teardown
    // -------------------------------------------------------------
    print("\n[TEST-T9] Starting T9 (Same-Name Re-Registration During Teardown)...");
    SUI_CleanupPlayer(0);
    g_t9_rereg_res = -1;
    SUI_CreatePlayerFactoryGroup(0, "t9_grp", "OnT9_Create", "OnT9_Destroy", "OnT9_Show", "OnT9_Hide");
    SUI_SetGroupSize(0, "t9_grp", 3);
    SUI_ShowGroup(0, "t9_grp");

    new t9_res = SUI_CleanupPlayer(0);
    new t9_cr = SUI_IsGroupCreated(0, "t9_grp");

    if (t9_res == 1 && g_t9_rereg_res == 0 && t9_cr == 0)
    {
        g_test_t9_pass = 1;
        print("[TEST-T9] PASS: Same-name re-registration rejected during teardown.");
    }
    else
    {
        printf("[TEST-T9] FAIL: t9_res=%d rereg_res=%d cr=%d", t9_res, g_t9_rereg_res, t9_cr);
    }

    // -------------------------------------------------------------
    // T10: Uncreated Group Cleanup
    // -------------------------------------------------------------
    print("\n[TEST-T10] Starting T10 (Uncreated Group Cleanup)...");
    SUI_CleanupPlayer(0);
    g_t10_create_calls = 0;
    g_t10_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "t10_grp", "OnT10_Create", "OnT10_Destroy", "OnT10_Show", "OnT10_Hide");
    SUI_SetGroupSize(0, "t10_grp", 10);

    new t10_res = SUI_ResetPlayer(0);
    new t10_cr = SUI_IsGroupCreated(0, "t10_grp");
    new t10_act = SUI_GetActiveTextDrawCount(0);

    if (t10_res == 1 && g_t10_create_calls == 0 && g_t10_destroy_calls == 0 && t10_cr == 0 && t10_act == 0)
    {
        g_test_t10_pass = 1;
        print("[TEST-T10] PASS: Uncreated group cleaned without callbacks or capacity change.");
    }
    else
    {
        printf("[TEST-T10] FAIL: t10_res=%d c_calls=%d d_calls=%d cr=%d act=%d",
            t10_res, g_t10_create_calls, g_t10_destroy_calls, t10_cr, t10_act);
    }

    // -------------------------------------------------------------
    // T11: Visible + Hidden Destroy Exactness
    // -------------------------------------------------------------
    print("\n[TEST-T11] Starting T11 (Visible + Hidden Destroy Exactness)...");
    SUI_CleanupPlayer(0);
    g_t11_vis_hide_calls = 0;
    g_t11_vis_destroy_calls = 0;
    g_t11_hid_hide_calls = 0;
    g_t11_hid_destroy_calls = 0;

    SUI_CreatePlayerFactoryGroup(0, "t11_vis", "OnT11_Vis_Create", "OnT11_Vis_Destroy", "OnT11_Vis_Show", "OnT11_Vis_Hide");
    SUI_SetGroupSize(0, "t11_vis", 5);
    SUI_ShowGroup(0, "t11_vis");

    SUI_CreatePlayerFactoryGroup(0, "t11_hid", "OnT11_Hid_Create", "OnT11_Hid_Destroy", "OnT11_Hid_Show", "OnT11_Hid_Hide");
    SUI_SetGroupSize(0, "t11_hid", 7);
    SUI_ShowGroup(0, "t11_hid");
    SUI_HideGroup(0, "t11_hid");

    new t11_act_pre = SUI_GetActiveTextDrawCount(0); // 12
    new t11_res = SUI_CleanupPlayer(0);
    new t11_act_post = SUI_GetActiveTextDrawCount(0); // 0

    if (t11_act_pre == 12 && t11_res == 1 && t11_act_post == 0 &&
        g_t11_vis_hide_calls == 1 && g_t11_vis_destroy_calls == 1 &&
        g_t11_hid_hide_calls == 1 && g_t11_hid_destroy_calls == 1)
    {
        g_test_t11_pass = 1;
        print("[TEST-T11] PASS: Exact single hide and destroy per group with exact capacity release.");
    }
    else
    {
        printf("[TEST-T11] FAIL: pre=%d res=%d post=%d v_hide=%d v_dest=%d h_hide=%d h_dest=%d",
            t11_act_pre, t11_res, t11_act_post, g_t11_vis_hide_calls, g_t11_vis_destroy_calls,
            g_t11_hid_hide_calls, g_t11_hid_destroy_calls);
    }

    // -------------------------------------------------------------
    // T12: Empty Player Context
    // -------------------------------------------------------------
    print("\n[TEST-T12] Starting T12 (Empty Player Context)...");
    new t12_c = SUI_CleanupPlayer(99);
    new t12_r = SUI_ResetPlayer(99);

    if (t12_c == 1 && t12_r == 1)
    {
        g_test_t12_pass = 1;
        print("[TEST-T12] PASS: Empty context Cleanup and Reset return 1 idempotently.");
    }
    else
    {
        printf("[TEST-T12] FAIL: t12_c=%d t12_r=%d", t12_c, t12_r);
    }

    // -------------------------------------------------------------
    // T13: Multi-AMX Player Teardown
    // -------------------------------------------------------------
    print("\n[TEST-T13] Starting T13 (Multi-AMX Player Teardown)...");
    SUI_CleanupPlayer(0);
    g_t13_gm_destroy_calls = 0;

    SUI_CreatePlayerFactoryGroup(0, "t13_gm", "OnT13_GM_Create", "OnT13_GM_Destroy", "OnT13_GM_Show", "OnT13_GM_Hide");
    SUI_SetGroupSize(0, "t13_gm", 4);
    SUI_ShowGroup(0, "t13_gm");

    CallRemoteFunction("FS_RegisterT13", "d", 0);
    CallRemoteFunction("FS_ShowT13", "d", 0);

    new t13_act_pre = SUI_GetActiveTextDrawCount(0); // 10
    new t13_res = SUI_ResetPlayer(0);
    new t13_act_post = SUI_GetActiveTextDrawCount(0); // 0
    new t13_fs_calls = CallRemoteFunction("FS_GetDestroyCalls", "");

    if (t13_act_pre == 10 && t13_res == 1 && t13_act_post == 0 &&
        g_t13_gm_destroy_calls == 1 && t13_fs_calls == 1)
    {
        g_test_t13_pass = 1;
        print("[TEST-T13] PASS: Multi-AMX groups destroyed in respective owner AMXs cleanly.");
    }
    else
    {
        printf("[TEST-T13] FAIL: pre=%d res=%d post=%d gm_calls=%d fs_calls=%d",
            t13_act_pre, t13_res, t13_act_post, g_t13_gm_destroy_calls, t13_fs_calls);
    }

    // -------------------------------------------------------------
    // T14: Missing Destroy Callback During Reset
    // -------------------------------------------------------------
    print("\n[TEST-T14] Starting T14 (Missing Destroy Callback During Reset)...");
    SUI_CleanupPlayer(0);
    SUI_CreatePlayerFactoryGroup(0, "t14_grp", "OnT14_Create", "NonExistent_Destroy", "OnT14_Show", "OnT14_Hide");
    SUI_SetGroupSize(0, "t14_grp", 4);
    SUI_ShowGroup(0, "t14_grp");

    new t14_res = SUI_ResetPlayer(0);
    new t14_cr = SUI_IsGroupCreated(0, "t14_grp");
    new t14_act = SUI_GetActiveTextDrawCount(0);

    if (t14_res == 0 && t14_cr == 1 && t14_act == 4)
    {
        g_test_t14_pass = 1;
        print("[TEST-T14] PASS: Reset failed safely (ret=0) and preserved group/capacity.");
    }
    else
    {
        printf("[TEST-T14] FAIL: t14_res=%d cr=%d act=%d", t14_res, t14_cr, t14_act);
    }
    SUI_CleanupPlayer(0);

    // -------------------------------------------------------------
    // T15: Missing Destroy Callback During Cleanup
    // -------------------------------------------------------------
    print("\n[TEST-T15] Starting T15 (Missing Destroy Callback During Cleanup)...");
    SUI_CleanupPlayer(0);
    SUI_CreatePlayerFactoryGroup(0, "t15_grp", "OnT15_Create", "NonExistent_Destroy", "OnT15_Show", "OnT15_Hide");
    SUI_SetGroupSize(0, "t15_grp", 4);
    SUI_ShowGroup(0, "t15_grp");

    new t15_res = SUI_CleanupPlayer(0);
    new t15_cr = SUI_IsGroupCreated(0, "t15_grp");
    new t15_act = SUI_GetActiveTextDrawCount(0);

    if (t15_res == 0 && t15_cr == 0 && t15_act == 0)
    {
        g_test_t15_pass = 1;
        print("[TEST-T15] PASS: Cleanup reported failure (ret=0) and purged context.");
    }
    else
    {
        printf("[TEST-T15] FAIL: t15_res=%d cr=%d act=%d", t15_res, t15_cr, t15_act);
    }

    // -------------------------------------------------------------
    // T16: Teardown Flag Recovery
    // -------------------------------------------------------------
    print("\n[TEST-T16] Starting T16 (Teardown Flag Recovery)...");
    SUI_CleanupPlayer(0);
    SUI_CreatePlayerFactoryGroup(0, "t16_fail", "OnT16_Fail_Create", "NonExistent_Destroy", "OnT16_Fail_Show", "OnT16_Fail_Hide");
    SUI_SetGroupSize(0, "t16_fail", 4);
    SUI_ShowGroup(0, "t16_fail");

    new t16_res = SUI_ResetPlayer(0);
    new t16_fail_cr = SUI_IsGroupCreated(0, "t16_fail");

    // Player context remains. Now verify teardownState was reset to None by performing new operations:
    new t16_reg_ok = SUI_CreatePlayerFactoryGroup(0, "t16_recov", "OnT16_Recov_Create", "OnT16_Recov_Destroy", "OnT16_Recov_Show", "OnT16_Recov_Hide");
    SUI_SetGroupSize(0, "t16_recov", 3);
    new t16_show_ok = SUI_ShowGroup(0, "t16_recov");
    new t16_recov_cr = SUI_IsGroupCreated(0, "t16_recov");

    SUI_DestroyGroup(0, "t16_recov");
    SUI_CleanupPlayer(0);
    new t16_final_act = SUI_GetActiveTextDrawCount(0);

    if (t16_res == 0 && t16_fail_cr == 1 && t16_reg_ok == 1 && t16_show_ok == 1 && t16_recov_cr == 1 && t16_final_act == 0)
    {
        g_test_t16_pass = 1;
        print("[TEST-T16] PASS: Teardown flag recovered to None after failed reset, allowing normal operations.");
    }
    else
    {
        printf("[TEST-T16] FAIL: t16_res=%d fail_cr=%d reg_ok=%d show_ok=%d recov_cr=%d final_act=%d",
            t16_res, t16_fail_cr, t16_reg_ok, t16_show_ok, t16_recov_cr, t16_final_act);
    }

    // -------------------------------------------------------------
    // Results Summary
    // -------------------------------------------------------------
    print("\n================================================================");
    print("           SUI PLAYER TEARDOWN TEST RESULTS (T1-T16)           ");
    print("================================================================");
    printf("T1  (Normal Cleanup):                         %s", (g_test_t1_pass) ? ("PASS") : ("FAIL"));
    printf("T2  (Cleanup Re-entrant Registration Block):  %s", (g_test_t2_pass) ? ("PASS") : ("FAIL"));
    printf("T3  (Reset Re-entrant Registration Block):    %s", (g_test_t3_pass) ? ("PASS") : ("FAIL"));
    printf("T4  (Reset Destroy Execution Error):          %s", (g_test_t4_pass) ? ("PASS") : ("FAIL"));
    printf("T5  (Cleanup Destroy Execution Error):        %s", (g_test_t5_pass) ? ("PASS") : ("FAIL"));
    printf("T6  (Nested CleanupPlayer Block):             %s", (g_test_t6_pass) ? ("PASS") : ("FAIL"));
    printf("T7  (Nested ResetPlayer Block):               %s", (g_test_t7_pass) ? ("PASS") : ("FAIL"));
    printf("T8  (ShowGroup During Teardown Block):        %s", (g_test_t8_pass) ? ("PASS") : ("FAIL"));
    printf("T9  (Same-Name Re-Registration Block):        %s", (g_test_t9_pass) ? ("PASS") : ("FAIL"));
    printf("T10 (Uncreated Group Direct Pruning):         %s", (g_test_t10_pass) ? ("PASS") : ("FAIL"));
    printf("T11 (Visible + Hidden Exact Destruction):     %s", (g_test_t11_pass) ? ("PASS") : ("FAIL"));
    printf("T12 (Empty Player Context Idempotence):       %s", (g_test_t12_pass) ? ("PASS") : ("FAIL"));
    printf("T13 (Multi-AMX Player Teardown):              %s", (g_test_t13_pass) ? ("PASS") : ("FAIL"));
    printf("T14 (Missing Destroy Callback in Reset):      %s", (g_test_t14_pass) ? ("PASS") : ("FAIL"));
    printf("T15 (Missing Destroy Callback in Cleanup):    %s", (g_test_t15_pass) ? ("PASS") : ("FAIL"));
    printf("T16 (Teardown Flag Recovery After Error):     %s", (g_test_t16_pass) ? ("PASS") : ("FAIL"));
    print("================================================================");

    new total_pass = g_test_t1_pass + g_test_t2_pass + g_test_t3_pass + g_test_t4_pass +
                     g_test_t5_pass + g_test_t6_pass + g_test_t7_pass + g_test_t8_pass +
                     g_test_t9_pass + g_test_t10_pass + g_test_t11_pass + g_test_t12_pass +
                     g_test_t13_pass + g_test_t14_pass + g_test_t15_pass + g_test_t16_pass;

    printf("TOTAL: %d / 16 PASSED", total_pass);
    if (total_pass == 16)
    {
        print("OVERALL RESULT: ALL PLAYER TEARDOWN TESTS PASSED!");
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
