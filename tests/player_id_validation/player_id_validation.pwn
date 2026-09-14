#include <a_samp>
#include "../../pawn/sui.inc"

// ============================================================================
// SUI PHASE 11: PLAYER ID DOMAIN VALIDATION REGRESSION SUITE (PV1–PV14)
// ============================================================================

new g_test_pv1_pass = 0;
new g_test_pv2_pass = 0;
new g_test_pv3_pass = 0;
new g_test_pv4_pass = 0;
new g_test_pv5_pass = 0;
new g_test_pv6_pass = 0;
new g_test_pv7_pass = 0;
new g_test_pv8_pass = 0;
new g_test_pv9_pass = 0;
new g_test_pv10_pass = 0;
new g_test_pv11_pass = 0;
new g_test_pv12_pass = 0;
new g_test_pv13_pass = 0;
new g_test_pv14_pass = 0;

// Callbacks tracking
new g_pv6_create_calls = 0;
new g_pv6_destroy_calls = 0;
new g_pv6_show_calls = 0;
new g_pv6_hide_calls = 0;

new g_pv7_create_calls = 0;
new g_pv7_destroy_calls = 0;
new g_pv7_show_calls = 0;
new g_pv7_hide_calls = 0;

new g_pv8_create_calls = 0;
new g_pv8_destroy_calls = 0;
new g_pv8_show_calls = 0;
new g_pv8_hide_calls = 0;

main()
{
}

// Dummy callbacks
forward OnDummy_Create(playerid); public OnDummy_Create(playerid) { return 1; }
forward OnDummy_Destroy(playerid); public OnDummy_Destroy(playerid) { return 1; }
forward OnDummy_Show(playerid); public OnDummy_Show(playerid) { return 1; }
forward OnDummy_Hide(playerid); public OnDummy_Hide(playerid) { return 1; }

// PV6 callbacks (playerid = 0)
forward OnPV6_Create(playerid); public OnPV6_Create(playerid) { g_pv6_create_calls++; return 1; }
forward OnPV6_Destroy(playerid); public OnPV6_Destroy(playerid) { g_pv6_destroy_calls++; return 1; }
forward OnPV6_Show(playerid); public OnPV6_Show(playerid) { g_pv6_show_calls++; return 1; }
forward OnPV6_Hide(playerid); public OnPV6_Hide(playerid) { g_pv6_hide_calls++; return 1; }

// PV7 callbacks (playerid = 999)
forward OnPV7_Create(playerid); public OnPV7_Create(playerid) { g_pv7_create_calls++; return 1; }
forward OnPV7_Destroy(playerid); public OnPV7_Destroy(playerid) { g_pv7_destroy_calls++; return 1; }
forward OnPV7_Show(playerid); public OnPV7_Show(playerid) { g_pv7_show_calls++; return 1; }
forward OnPV7_Hide(playerid); public OnPV7_Hide(playerid) { g_pv7_hide_calls++; return 1; }

// PV8 callbacks (invalid player IDs - must NEVER be called)
forward OnPV8_Create(playerid); public OnPV8_Create(playerid) { g_pv8_create_calls++; return 1; }
forward OnPV8_Destroy(playerid); public OnPV8_Destroy(playerid) { g_pv8_destroy_calls++; return 1; }
forward OnPV8_Show(playerid); public OnPV8_Show(playerid) { g_pv8_show_calls++; return 1; }
forward OnPV8_Hide(playerid); public OnPV8_Hide(playerid) { g_pv8_hide_calls++; return 1; }

public OnGameModeInit()
{
    print("\n================================================================");
    print("   SUI PHASE 11: PLAYER ID VALIDATION REGRESSION SUITE (PV1-14)  ");
    print("================================================================\n");

    SUI_SetDebug(true);

    Test_PV1_NegativeIdRejection();
    Test_PV2_CellminRejection();
    Test_PV3_BoundaryOutOfRange();
    Test_PV4_CellmaxRejection();
    Test_PV5_InvalidPlayerIdSentinel();
    Test_PV6_PlayerZeroValidLifecycle();
    Test_PV7_Player999ValidLifecycle();
    Test_PV8_NoCallbacksOnInvalidRegistration();
    Test_PV9_NoPhantomContextViaSetters();
    Test_PV10_SideEffectFreeQueries();
    Test_PV11_ValidNoContextCleanupReset();
    Test_PV12_InvalidCleanupResetRejection();
    Test_PV13_RepeatedInvalidIdStressLoop();
    Test_PV14_FullNativeMatrixCoverage();

    PrintSummaryAndExit();
    return 1;
}

// ----------------------------------------------------------------------------
// PV1: Negative ID Rejection (-1) across all natives
// ----------------------------------------------------------------------------
Test_PV1_NegativeIdRejection()
{
    new badId = -1;
    new allZero = 1;

    if (SUI_CreatePlayerFactoryGroup(badId, "g", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide") != 0) allZero = 0;
    if (SUI_ShowGroup(badId, "g") != 0) allZero = 0;
    if (SUI_HideGroup(badId, "g") != 0) allZero = 0;
    if (SUI_SetIdleTimeout(badId, "g", 5000) != 0) allZero = 0;
    if (SUI_SetGroupSize(badId, "g", 5) != 0) allZero = 0;
    if (SUI_GetActiveTextDrawCount(badId) != 0) allZero = 0;
    if (SUI_SetMaxTextDraws(badId, 200) != 0) allZero = 0;
    if (SUI_SetEvictionThreshold(badId, 150) != 0) allZero = 0;
    if (SUI_SetGroupPriority(badId, "g", SUI_PRIORITY_HIGH) != 0) allZero = 0;
    if (SUI_SetGroupEvictable(badId, "g", false) != 0) allZero = 0;
    if (_:SUI_DestroyGroup(badId, "g") != 0) allZero = 0;
    if (_:SUI_IsGroupCreated(badId, "g") != 0) allZero = 0;
    if (_:SUI_IsGroupVisible(badId, "g") != 0) allZero = 0;
    if (_:SUI_IsGroupEvictable(badId, "g") != 0) allZero = 0;
    if (_:SUI_TouchGroup(badId, "g") != 0) allZero = 0;
    if (SUI_CleanupPlayer(badId) != 0) allZero = 0;
    if (SUI_ResetPlayer(badId) != 0) allZero = 0;
    if (SUI_PrintPlayerState(badId) != 0) allZero = 0;

    if (allZero == 1)
    {
        g_test_pv1_pass = 1;
        print("[TEST-PV1] PASS: All natives strictly reject playerId = -1.");
    }
    else
    {
        print("[TEST-PV1] FAIL: One or more natives accepted playerId = -1.");
    }
}

// ----------------------------------------------------------------------------
// PV2: Cellmin Rejection (-2147483648)
// ----------------------------------------------------------------------------
Test_PV2_CellminRejection()
{
    new allZero = 1;

    if (SUI_CreatePlayerFactoryGroup(cellmin, "g", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide") != 0) allZero = 0;
    if (SUI_ShowGroup(cellmin, "g") != 0) allZero = 0;
    if (SUI_HideGroup(cellmin, "g") != 0) allZero = 0;
    if (SUI_GetActiveTextDrawCount(cellmin) != 0) allZero = 0;
    if (SUI_SetMaxTextDraws(cellmin, 200) != 0) allZero = 0;
    if (SUI_SetEvictionThreshold(cellmin, 150) != 0) allZero = 0;
    if (SUI_CleanupPlayer(cellmin) != 0) allZero = 0;
    if (SUI_ResetPlayer(cellmin) != 0) allZero = 0;
    if (_:SUI_IsGroupCreated(cellmin, "g") != 0) allZero = 0;

    if (allZero == 1)
    {
        g_test_pv2_pass = 1;
        print("[TEST-PV2] PASS: Cellmin (-2147483648) rejected without overflow or crash.");
    }
    else
    {
        print("[TEST-PV2] FAIL: Cellmin was not rejected cleanly.");
    }
}

// ----------------------------------------------------------------------------
// PV3: Boundary Out-Of-Range (1000)
// ----------------------------------------------------------------------------
Test_PV3_BoundaryOutOfRange()
{
    new badId = 1000;
    new allZero = 1;

    if (SUI_CreatePlayerFactoryGroup(badId, "g", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide") != 0) allZero = 0;
    if (SUI_ShowGroup(badId, "g") != 0) allZero = 0;
    if (SUI_HideGroup(badId, "g") != 0) allZero = 0;
    if (SUI_SetIdleTimeout(badId, "g", 5000) != 0) allZero = 0;
    if (SUI_SetGroupSize(badId, "g", 5) != 0) allZero = 0;
    if (SUI_GetActiveTextDrawCount(badId) != 0) allZero = 0;
    if (SUI_SetMaxTextDraws(badId, 200) != 0) allZero = 0;
    if (SUI_SetEvictionThreshold(badId, 150) != 0) allZero = 0;
    if (SUI_SetGroupPriority(badId, "g", SUI_PRIORITY_HIGH) != 0) allZero = 0;
    if (SUI_SetGroupEvictable(badId, "g", false) != 0) allZero = 0;
    if (_:SUI_DestroyGroup(badId, "g") != 0) allZero = 0;
    if (_:SUI_IsGroupCreated(badId, "g") != 0) allZero = 0;
    if (_:SUI_IsGroupVisible(badId, "g") != 0) allZero = 0;
    if (_:SUI_IsGroupEvictable(badId, "g") != 0) allZero = 0;
    if (_:SUI_TouchGroup(badId, "g") != 0) allZero = 0;
    if (SUI_CleanupPlayer(badId) != 0) allZero = 0;
    if (SUI_ResetPlayer(badId) != 0) allZero = 0;
    if (SUI_PrintPlayerState(badId) != 0) allZero = 0;

    if (allZero == 1)
    {
        g_test_pv3_pass = 1;
        print("[TEST-PV3] PASS: Upper boundary playerId = 1000 strictly rejected.");
    }
    else
    {
        print("[TEST-PV3] FAIL: Upper boundary playerId = 1000 accepted.");
    }
}

// ----------------------------------------------------------------------------
// PV4: Cellmax Rejection (2147483647)
// ----------------------------------------------------------------------------
Test_PV4_CellmaxRejection()
{
    new allZero = 1;

    if (SUI_CreatePlayerFactoryGroup(cellmax, "g", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide") != 0) allZero = 0;
    if (SUI_ShowGroup(cellmax, "g") != 0) allZero = 0;
    if (SUI_HideGroup(cellmax, "g") != 0) allZero = 0;
    if (SUI_GetActiveTextDrawCount(cellmax) != 0) allZero = 0;
    if (SUI_SetMaxTextDraws(cellmax, 200) != 0) allZero = 0;
    if (SUI_SetEvictionThreshold(cellmax, 150) != 0) allZero = 0;
    if (SUI_CleanupPlayer(cellmax) != 0) allZero = 0;
    if (SUI_ResetPlayer(cellmax) != 0) allZero = 0;
    if (_:SUI_IsGroupCreated(cellmax, "g") != 0) allZero = 0;

    if (allZero == 1)
    {
        g_test_pv4_pass = 1;
        print("[TEST-PV4] PASS: Cellmax (2147483647) rejected cleanly.");
    }
    else
    {
        print("[TEST-PV4] FAIL: Cellmax was not rejected cleanly.");
    }
}

// ----------------------------------------------------------------------------
// PV5: INVALID_PLAYER_ID (65535) Sentinel Rejection
// ----------------------------------------------------------------------------
Test_PV5_InvalidPlayerIdSentinel()
{
    new badId = INVALID_PLAYER_ID;
    new allZero = 1;

    if (SUI_CreatePlayerFactoryGroup(badId, "g", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide") != 0) allZero = 0;
    if (SUI_ShowGroup(badId, "g") != 0) allZero = 0;
    if (SUI_HideGroup(badId, "g") != 0) allZero = 0;
    if (SUI_GetActiveTextDrawCount(badId) != 0) allZero = 0;
    if (SUI_SetMaxTextDraws(badId, 200) != 0) allZero = 0;
    if (SUI_SetEvictionThreshold(badId, 150) != 0) allZero = 0;
    if (SUI_CleanupPlayer(badId) != 0) allZero = 0;
    if (SUI_ResetPlayer(badId) != 0) allZero = 0;
    if (_:SUI_IsGroupCreated(badId, "g") != 0) allZero = 0;

    if (allZero == 1)
    {
        g_test_pv5_pass = 1;
        print("[TEST-PV5] PASS: INVALID_PLAYER_ID (65535) strictly rejected.");
    }
    else
    {
        print("[TEST-PV5] FAIL: INVALID_PLAYER_ID was not rejected.");
    }
}

// ----------------------------------------------------------------------------
// PV6: Player 0 Valid Lifecycle (Lower Valid Boundary)
// ----------------------------------------------------------------------------
Test_PV6_PlayerZeroValidLifecycle()
{
    new pid = 0;
    g_pv6_create_calls = 0;
    g_pv6_destroy_calls = 0;
    g_pv6_show_calls = 0;
    g_pv6_hide_calls = 0;

    new r1 = SUI_CreatePlayerFactoryGroup(pid, "pv6_grp", "OnPV6_Create", "OnPV6_Destroy", "OnPV6_Show", "OnPV6_Hide");
    new r2 = SUI_SetGroupSize(pid, "pv6_grp", 10);
    new r3 = SUI_SetIdleTimeout(pid, "pv6_grp", 20000);
    new r4 = SUI_SetGroupPriority(pid, "pv6_grp", SUI_PRIORITY_HIGH);
    new r5 = SUI_SetGroupEvictable(pid, "pv6_grp", true);

    new r6 = SUI_ShowGroup(pid, "pv6_grp");
    new cr1 = _:SUI_IsGroupCreated(pid, "pv6_grp");
    new vis1 = _:SUI_IsGroupVisible(pid, "pv6_grp");
    new act1 = SUI_GetActiveTextDrawCount(pid);
    new ev1 = _:SUI_IsGroupEvictable(pid, "pv6_grp");
    new r7 = _:SUI_TouchGroup(pid, "pv6_grp");

    new r8 = SUI_HideGroup(pid, "pv6_grp");
    new vis2 = _:SUI_IsGroupVisible(pid, "pv6_grp");
    new cr2 = _:SUI_IsGroupCreated(pid, "pv6_grp");

    new r9 = _:SUI_DestroyGroup(pid, "pv6_grp");
    new cr3 = _:SUI_IsGroupCreated(pid, "pv6_grp");
    new act2 = SUI_GetActiveTextDrawCount(pid);

    new r10 = SUI_CleanupPlayer(pid);

    if (r1 == 1 && r2 == 1 && r3 == 1 && r4 == 1 && r5 == 1 &&
        r6 == 1 && cr1 == 1 && vis1 == 1 && act1 == 10 && ev1 == 1 && r7 == 1 &&
        r8 == 1 && vis2 == 0 && cr2 == 1 &&
        r9 == 1 && cr3 == 0 && act2 == 0 &&
        r10 == 1 &&
        g_pv6_create_calls == 1 && g_pv6_show_calls == 1 && g_pv6_hide_calls == 1 && g_pv6_destroy_calls == 1)
    {
        g_test_pv6_pass = 1;
        print("[TEST-PV6] PASS: Player 0 valid lifecycle executes with full fidelity.");
    }
    else
    {
        printf("[TEST-PV6] FAIL: r1=%d r6=%d cr1=%d vis1=%d act1=%d r8=%d r9=%d r10=%d", r1, r6, cr1, vis1, act1, r8, r9, r10);
    }
}

// ----------------------------------------------------------------------------
// PV7: Player 999 Valid Lifecycle (Upper Valid Boundary)
// ----------------------------------------------------------------------------
Test_PV7_Player999ValidLifecycle()
{
    new pid = 999;
    g_pv7_create_calls = 0;
    g_pv7_destroy_calls = 0;
    g_pv7_show_calls = 0;
    g_pv7_hide_calls = 0;

    new r1 = SUI_CreatePlayerFactoryGroup(pid, "pv7_grp", "OnPV7_Create", "OnPV7_Destroy", "OnPV7_Show", "OnPV7_Hide");
    new r2 = SUI_SetGroupSize(pid, "pv7_grp", 15);
    new r3 = SUI_SetIdleTimeout(pid, "pv7_grp", 15000);
    new r4 = SUI_SetGroupPriority(pid, "pv7_grp", SUI_PRIORITY_NORMAL);
    new r5 = SUI_SetGroupEvictable(pid, "pv7_grp", true);

    new r6 = SUI_ShowGroup(pid, "pv7_grp");
    new cr1 = _:SUI_IsGroupCreated(pid, "pv7_grp");
    new vis1 = _:SUI_IsGroupVisible(pid, "pv7_grp");
    new act1 = SUI_GetActiveTextDrawCount(pid);
    new r7 = _:SUI_TouchGroup(pid, "pv7_grp");

    new r8 = SUI_HideGroup(pid, "pv7_grp");
    new vis2 = _:SUI_IsGroupVisible(pid, "pv7_grp");

    new r9 = _:SUI_DestroyGroup(pid, "pv7_grp");
    new cr2 = _:SUI_IsGroupCreated(pid, "pv7_grp");
    new act2 = SUI_GetActiveTextDrawCount(pid);

    new r10 = SUI_CleanupPlayer(pid);

    if (r1 == 1 && r2 == 1 && r3 == 1 && r4 == 1 && r5 == 1 &&
        r6 == 1 && cr1 == 1 && vis1 == 1 && act1 == 15 && r7 == 1 &&
        r8 == 1 && vis2 == 0 &&
        r9 == 1 && cr2 == 0 && act2 == 0 &&
        r10 == 1 &&
        g_pv7_create_calls == 1 && g_pv7_show_calls == 1 && g_pv7_hide_calls == 1 && g_pv7_destroy_calls == 1)
    {
        g_test_pv7_pass = 1;
        print("[TEST-PV7] PASS: Player 999 valid lifecycle executes with full fidelity.");
    }
    else
    {
        printf("[TEST-PV7] FAIL: r1=%d r6=%d cr1=%d vis1=%d act1=%d r8=%d r9=%d r10=%d", r1, r6, cr1, vis1, act1, r8, r9, r10);
    }
}

// ----------------------------------------------------------------------------
// PV8: Invalid Registration Does Not Invoke Callbacks
// ----------------------------------------------------------------------------
Test_PV8_NoCallbacksOnInvalidRegistration()
{
    g_pv8_create_calls = 0;
    g_pv8_destroy_calls = 0;
    g_pv8_show_calls = 0;
    g_pv8_hide_calls = 0;

    SUI_CreatePlayerFactoryGroup(-1, "pv8_bad", "OnPV8_Create", "OnPV8_Destroy", "OnPV8_Show", "OnPV8_Hide");
    SUI_ShowGroup(-1, "pv8_bad");
    SUI_HideGroup(-1, "pv8_bad");
    SUI_DestroyGroup(-1, "pv8_bad");

    SUI_CreatePlayerFactoryGroup(1000, "pv8_bad", "OnPV8_Create", "OnPV8_Destroy", "OnPV8_Show", "OnPV8_Hide");
    SUI_ShowGroup(1000, "pv8_bad");
    SUI_HideGroup(1000, "pv8_bad");
    SUI_DestroyGroup(1000, "pv8_bad");

    SUI_CreatePlayerFactoryGroup(cellmin, "pv8_bad", "OnPV8_Create", "OnPV8_Destroy", "OnPV8_Show", "OnPV8_Hide");
    SUI_CreatePlayerFactoryGroup(cellmax, "pv8_bad", "OnPV8_Create", "OnPV8_Destroy", "OnPV8_Show", "OnPV8_Hide");
    SUI_CreatePlayerFactoryGroup(INVALID_PLAYER_ID, "pv8_bad", "OnPV8_Create", "OnPV8_Destroy", "OnPV8_Show", "OnPV8_Hide");

    if (g_pv8_create_calls == 0 && g_pv8_destroy_calls == 0 &&
        g_pv8_show_calls == 0 && g_pv8_hide_calls == 0)
    {
        g_test_pv8_pass = 1;
        print("[TEST-PV8] PASS: Zero callbacks invoked during invalid player ID operations.");
    }
    else
    {
        printf("[TEST-PV8] FAIL: Callbacks unexpectedly invoked: create=%d destroy=%d show=%d hide=%d",
            g_pv8_create_calls, g_pv8_destroy_calls, g_pv8_show_calls, g_pv8_hide_calls);
    }
}

// ----------------------------------------------------------------------------
// PV9: Invalid Setters Do Not Create Phantom PlayerContext
// ----------------------------------------------------------------------------
Test_PV9_NoPhantomContextViaSetters()
{
    new r1 = SUI_SetMaxTextDraws(-1, 150);
    new r2 = SUI_SetEvictionThreshold(-1, 120);
    new r3 = SUI_SetMaxTextDraws(1000, 150);
    new r4 = SUI_SetEvictionThreshold(1000, 120);

    new actBad1 = SUI_GetActiveTextDrawCount(-1);
    new actBad2 = SUI_GetActiveTextDrawCount(1000);

    if (r1 == 0 && r2 == 0 && r3 == 0 && r4 == 0 && actBad1 == 0 && actBad2 == 0)
    {
        g_test_pv9_pass = 1;
        print("[TEST-PV9] PASS: Setters reject invalid player IDs without creating phantom PlayerContext.");
    }
    else
    {
        printf("[TEST-PV9] FAIL: r1=%d r2=%d r3=%d r4=%d actBad1=%d actBad2=%d", r1, r2, r3, r4, actBad1, actBad2);
    }
}

// ----------------------------------------------------------------------------
// PV10: Invalid Queries Are Side-Effect Free
// ----------------------------------------------------------------------------
Test_PV10_SideEffectFreeQueries()
{
    new act1 = SUI_GetActiveTextDrawCount(-5);
    new cr1 = _:SUI_IsGroupCreated(-5, "nonexistent");
    new vis1 = _:SUI_IsGroupVisible(-5, "nonexistent");
    new ev1 = _:SUI_IsGroupEvictable(-5, "nonexistent");
    new pr1 = SUI_PrintPlayerState(-5);

    new act2 = SUI_GetActiveTextDrawCount(1005);
    new cr2 = _:SUI_IsGroupCreated(1005, "nonexistent");
    new vis2 = _:SUI_IsGroupVisible(1005, "nonexistent");
    new ev2 = _:SUI_IsGroupEvictable(1005, "nonexistent");
    new pr2 = SUI_PrintPlayerState(1005);

    if (act1 == 0 && cr1 == 0 && vis1 == 0 && ev1 == 0 && pr1 == 0 &&
        act2 == 0 && cr2 == 0 && vis2 == 0 && ev2 == 0 && pr2 == 0)
    {
        g_test_pv10_pass = 1;
        print("[TEST-PV10] PASS: Invalid queries return 0 without side effects.");
    }
    else
    {
        printf("[TEST-PV10] FAIL: Query returned non-zero on invalid ID: pr1=%d pr2=%d", pr1, pr2);
    }
}

// ----------------------------------------------------------------------------
// PV11: Valid-No-Context Cleanup / Reset Returns 1 (Idempotent Success)
// ----------------------------------------------------------------------------
Test_PV11_ValidNoContextCleanupReset()
{
    // Players 50 and 51 have never had any groups registered or context allocated
    new r1 = SUI_CleanupPlayer(50);
    new r2 = SUI_ResetPlayer(51);

    // Repeated call should remain idempotent success
    new r3 = SUI_CleanupPlayer(50);
    new r4 = SUI_ResetPlayer(51);

    if (r1 == 1 && r2 == 1 && r3 == 1 && r4 == 1)
    {
        g_test_pv11_pass = 1;
        print("[TEST-PV11] PASS: Valid-no-context CleanupPlayer and ResetPlayer return 1 (idempotent).");
    }
    else
    {
        printf("[TEST-PV11] FAIL: r1=%d r2=%d r3=%d r4=%d", r1, r2, r3, r4);
    }
}

// ----------------------------------------------------------------------------
// PV12: Invalid Cleanup / Reset Rejection Returns 0
// ----------------------------------------------------------------------------
Test_PV12_InvalidCleanupResetRejection()
{
    new allZero = 1;

    if (SUI_CleanupPlayer(-1) != 0) allZero = 0;
    if (SUI_CleanupPlayer(1000) != 0) allZero = 0;
    if (SUI_CleanupPlayer(cellmin) != 0) allZero = 0;
    if (SUI_CleanupPlayer(cellmax) != 0) allZero = 0;
    if (SUI_CleanupPlayer(INVALID_PLAYER_ID) != 0) allZero = 0;

    if (SUI_ResetPlayer(-1) != 0) allZero = 0;
    if (SUI_ResetPlayer(1000) != 0) allZero = 0;
    if (SUI_ResetPlayer(cellmin) != 0) allZero = 0;
    if (SUI_ResetPlayer(cellmax) != 0) allZero = 0;
    if (SUI_ResetPlayer(INVALID_PLAYER_ID) != 0) allZero = 0;

    if (allZero == 1)
    {
        g_test_pv12_pass = 1;
        print("[TEST-PV12] PASS: CleanupPlayer and ResetPlayer strictly return 0 on invalid IDs.");
    }
    else
    {
        print("[TEST-PV12] FAIL: CleanupPlayer or ResetPlayer returned 1 on invalid ID.");
    }
}

// ----------------------------------------------------------------------------
// PV13: Repeated Invalid-ID Stress Loop
// ----------------------------------------------------------------------------
Test_PV13_RepeatedInvalidIdStressLoop()
{
    new invalidIds[5];
    invalidIds[0] = -100;
    invalidIds[1] = -1;
    invalidIds[2] = 1000;
    invalidIds[3] = 65535;
    invalidIds[4] = 100000;

    new stressPass = 1;

    for (new iter = 0; iter < 100; iter++)
    {
        for (new i = 0; i < 5; i++)
        {
            new badId = invalidIds[i];
            if (SUI_CreatePlayerFactoryGroup(badId, "g", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide") != 0) stressPass = 0;
            if (SUI_ShowGroup(badId, "g") != 0) stressPass = 0;
            if (SUI_HideGroup(badId, "g") != 0) stressPass = 0;
            if (SUI_GetActiveTextDrawCount(badId) != 0) stressPass = 0;
            if (SUI_SetMaxTextDraws(badId, 250) != 0) stressPass = 0;
            if (SUI_SetEvictionThreshold(badId, 200) != 0) stressPass = 0;
            if (SUI_CleanupPlayer(badId) != 0) stressPass = 0;
            if (SUI_ResetPlayer(badId) != 0) stressPass = 0;
            if (_:SUI_DestroyGroup(badId, "g") != 0) stressPass = 0;
            if (_:SUI_IsGroupCreated(badId, "g") != 0) stressPass = 0;
            if (_:SUI_IsGroupVisible(badId, "g") != 0) stressPass = 0;
            if (_:SUI_IsGroupEvictable(badId, "g") != 0) stressPass = 0;
            if (_:SUI_TouchGroup(badId, "g") != 0) stressPass = 0;
            if (SUI_PrintPlayerState(badId) != 0) stressPass = 0;
        }
    }

    if (stressPass == 1)
    {
        g_test_pv13_pass = 1;
        print("[TEST-PV13] PASS: 500 iterations of invalid ID stress test completed cleanly.");
    }
    else
    {
        print("[TEST-PV13] FAIL: Stress test detected unexpected non-zero return code.");
    }
}

// ----------------------------------------------------------------------------
// PV14: Full Matrix Coverage Across All 19 Natives
// ----------------------------------------------------------------------------
Test_PV14_FullNativeMatrixCoverage()
{
    // Native 1: SUI_SetDebug (no player ID parameter)
    new rDebug = SUI_SetDebug(true);

    // Test player ID = 500 (middle valid player ID)
    new pid = 500;

    // Natives 2-19 on invalid ID (-1) must all return 0
    new badId = -1;
    new invCount = 0;
    if (SUI_CreatePlayerFactoryGroup(badId, "m_grp", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide") == 0) invCount++;
    if (SUI_ShowGroup(badId, "m_grp") == 0) invCount++;
    if (SUI_HideGroup(badId, "m_grp") == 0) invCount++;
    if (SUI_SetIdleTimeout(badId, "m_grp", 10000) == 0) invCount++;
    if (SUI_SetGroupSize(badId, "m_grp", 4) == 0) invCount++;
    if (SUI_GetActiveTextDrawCount(badId) == 0) invCount++;
    if (SUI_SetMaxTextDraws(badId, 256) == 0) invCount++;
    if (SUI_SetEvictionThreshold(badId, 230) == 0) invCount++;
    if (SUI_SetGroupPriority(badId, "m_grp", SUI_PRIORITY_NORMAL) == 0) invCount++;
    if (SUI_SetGroupEvictable(badId, "m_grp", true) == 0) invCount++;
    if (_:SUI_DestroyGroup(badId, "m_grp") == 0) invCount++;
    if (_:SUI_IsGroupCreated(badId, "m_grp") == 0) invCount++;
    if (_:SUI_IsGroupVisible(badId, "m_grp") == 0) invCount++;
    if (_:SUI_IsGroupEvictable(badId, "m_grp") == 0) invCount++;
    if (_:SUI_TouchGroup(badId, "m_grp") == 0) invCount++;
    if (SUI_CleanupPlayer(badId) == 0) invCount++;
    if (SUI_ResetPlayer(badId) == 0) invCount++;
    if (SUI_PrintPlayerState(badId) == 0) invCount++;

    // Natives 2-19 on valid ID (500) must work correctly
    new valCount = 0;
    if (SUI_SetMaxTextDraws(pid, 256) == 1) valCount++;
    if (SUI_SetEvictionThreshold(pid, 230) == 1) valCount++;
    if (SUI_CreatePlayerFactoryGroup(pid, "m_grp", "OnDummy_Create", "OnDummy_Destroy", "OnDummy_Show", "OnDummy_Hide") == 1) valCount++;
    if (SUI_SetGroupSize(pid, "m_grp", 4) == 1) valCount++;
    if (SUI_SetIdleTimeout(pid, "m_grp", 10000) == 1) valCount++;
    if (SUI_SetGroupPriority(pid, "m_grp", SUI_PRIORITY_NORMAL) == 1) valCount++;
    if (SUI_SetGroupEvictable(pid, "m_grp", true) == 1) valCount++;
    if (SUI_ShowGroup(pid, "m_grp") == 1) valCount++;
    if (_:SUI_IsGroupCreated(pid, "m_grp") == 1) valCount++;
    if (_:SUI_IsGroupVisible(pid, "m_grp") == 1) valCount++;
    if (_:SUI_IsGroupEvictable(pid, "m_grp") == 1) valCount++;
    if (SUI_GetActiveTextDrawCount(pid) == 4) valCount++;
    if (_:SUI_TouchGroup(pid, "m_grp") == 1) valCount++;
    if (SUI_HideGroup(pid, "m_grp") == 1) valCount++;
    if (SUI_PrintPlayerState(pid) == 1) valCount++;
    if (_:SUI_DestroyGroup(pid, "m_grp") == 1) valCount++;
    if (SUI_ResetPlayer(pid) == 1) valCount++;
    if (SUI_CleanupPlayer(pid) == 1) valCount++;

    if (rDebug == 1 && invCount == 18 && valCount == 18)
    {
        g_test_pv14_pass = 1;
        print("[TEST-PV14] PASS: All 19 natives covered with 100% boundary compliance.");
    }
    else
    {
        printf("[TEST-PV14] FAIL: rDebug=%d invCount=%d/18 valCount=%d/18", rDebug, invCount, valCount);
    }
}

PrintSummaryAndExit()
{
    print("\n================================================================");
    print("   SUI PHASE 11: PLAYER ID DOMAIN VALIDATION RESULTS (PV1-PV14) ");
    print("================================================================");
    printf("PV1  (Negative ID Rejection -1):                       %s", (g_test_pv1_pass) ? ("PASS") : ("FAIL"));
    printf("PV2  (Cellmin Rejection -2147483648):                  %s", (g_test_pv2_pass) ? ("PASS") : ("FAIL"));
    printf("PV3  (Boundary Out-Of-Range 1000):                     %s", (g_test_pv3_pass) ? ("PASS") : ("FAIL"));
    printf("PV4  (Cellmax Rejection 2147483647):                   %s", (g_test_pv4_pass) ? ("PASS") : ("FAIL"));
    printf("PV5  (INVALID_PLAYER_ID Sentinel Rejection):           %s", (g_test_pv5_pass) ? ("PASS") : ("FAIL"));
    printf("PV6  (Player 0 Valid Lifecycle):                       %s", (g_test_pv6_pass) ? ("PASS") : ("FAIL"));
    printf("PV7  (Player 999 Valid Lifecycle):                     %s", (g_test_pv7_pass) ? ("PASS") : ("FAIL"));
    printf("PV8  (No Callbacks On Invalid Registration):           %s", (g_test_pv8_pass) ? ("PASS") : ("FAIL"));
    printf("PV9  (No Phantom Context Via Setters):                 %s", (g_test_pv9_pass) ? ("PASS") : ("FAIL"));
    printf("PV10 (Side-Effect Free Queries):                       %s", (g_test_pv10_pass) ? ("PASS") : ("FAIL"));
    printf("PV11 (Valid-No-Context Cleanup/Reset Idempotence):     %s", (g_test_pv11_pass) ? ("PASS") : ("FAIL"));
    printf("PV12 (Invalid Cleanup/Reset Rejection):                %s", (g_test_pv12_pass) ? ("PASS") : ("FAIL"));
    printf("PV13 (Repeated Invalid-ID Stress Loop):                %s", (g_test_pv13_pass) ? ("PASS") : ("FAIL"));
    printf("PV14 (Full Native Matrix Coverage):                    %s", (g_test_pv14_pass) ? ("PASS") : ("FAIL"));
    print("================================================================");

    new total_pass = g_test_pv1_pass + g_test_pv2_pass + g_test_pv3_pass + g_test_pv4_pass +
                     g_test_pv5_pass + g_test_pv6_pass + g_test_pv7_pass + g_test_pv8_pass +
                     g_test_pv9_pass + g_test_pv10_pass + g_test_pv11_pass + g_test_pv12_pass +
                     g_test_pv13_pass + g_test_pv14_pass;

    printf("TOTAL: %d / 14 PASSED", total_pass);
    if (total_pass == 14)
    {
        print("OVERALL RESULT: ALL PLAYER ID VALIDATION TESTS PASSED!");
    }
    else
    {
        print("OVERALL RESULT: SOME TESTS FAILED!");
    }
    print("================================================================\n");

    SendRconCommand("exit");
}
