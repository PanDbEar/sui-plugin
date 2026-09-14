#include <a_samp>
#include "../../pawn/sui.inc"

// ============================================================================
// SUI PHASE 12.2: API CONTRACT & STOCK HELPER RUNTIME SUITE (AS1–AS9)
// ============================================================================

new g_test_as1_pass = 0;
new g_test_as2_pass = 0;
new g_test_as3_pass = 0;
new g_test_as4_pass = 0;
new g_test_as5_pass = 0;
new g_test_as6_pass = 0;
new g_test_as7_pass = 0;
new g_test_as8_pass = 0;
new g_test_as9_pass = 0;

main()
{
}

// Dummy callbacks
forward OnAS_Create(playerid); public OnAS_Create(playerid) { return 1; }
forward OnAS_Destroy(playerid); public OnAS_Destroy(playerid) { return 1; }
forward OnAS_Show(playerid); public OnAS_Show(playerid) { return 1; }
forward OnAS_Hide(playerid); public OnAS_Hide(playerid) { return 1; }

new g_as9_destroy_called = 0;
forward OnAS9_Destroy(playerid);
public OnAS9_Destroy(playerid)
{
    g_as9_destroy_called++;
    return 1;
}

// ----------------------------------------------------------------------------
// AS1: Valid SUI_RegisterGroup Setup
// ----------------------------------------------------------------------------
Test_AS1_ValidRegistration()
{
    SUI_CleanupPlayer(0);

    new r = SUI_RegisterGroup(0, "as1_grp", "OnAS_Create", "OnAS_Destroy", "OnAS_Show", "OnAS_Hide", 5, 10000, SUI_PRIORITY_HIGH, true);
    if (r != 1)
    {
        printf("[TEST-AS1] FAIL: SUI_RegisterGroup returned %d (1 expected)", r);
        return;
    }

    if (SUI_IsGroupCreated(0, "as1_grp"))
    {
        print("[TEST-AS1] FAIL: Group should not be created yet");
        return;
    }

    if (!SUI_IsGroupEvictable(0, "as1_grp"))
    {
        print("[TEST-AS1] FAIL: Group should be evictable");
        return;
    }

    if (!SUI_ShowGroup(0, "as1_grp"))
    {
        print("[TEST-AS1] FAIL: ShowGroup failed");
        return;
    }

    if (!SUI_IsGroupCreated(0, "as1_grp") || !SUI_IsGroupVisible(0, "as1_grp"))
    {
        print("[TEST-AS1] FAIL: Group should be created and visible");
        return;
    }

    if (SUI_GetActiveTextDrawCount(0) != 5)
    {
        printf("[TEST-AS1] FAIL: Active textdraw count is %d (5 expected)", SUI_GetActiveTextDrawCount(0));
        return;
    }

    SUI_CleanupPlayer(0);
    g_test_as1_pass = 1;
    print("[TEST-AS1] PASS: Valid SUI_RegisterGroup setup complete.");
}

// ----------------------------------------------------------------------------
// AS2: Invalid Priority Rejection
// ----------------------------------------------------------------------------
Test_AS2_InvalidPriority()
{
    SUI_CleanupPlayer(0);

    new r1 = SUI_RegisterGroup(0, "as2_grp", "OnAS_Create", "OnAS_Destroy", "OnAS_Show", "OnAS_Hide", 5, 30000, 99, true);
    new r2 = SUI_RegisterGroup(0, "as2_grp_neg", "OnAS_Create", "OnAS_Destroy", "OnAS_Show", "OnAS_Hide", 5, 30000, -1, true);
    new r3 = SUI_RegisterGroup(0, "as2_grp_high", "OnAS_Create", "OnAS_Destroy", "OnAS_Show", "OnAS_Hide", 5, 30000, 4, true);

    if (r1 != 0 || r2 != 0 || r3 != 0)
    {
        printf("[TEST-AS2] FAIL: Invalid priority accepted (r1=%d, r2=%d, r3=%d)", r1, r2, r3);
        return;
    }

    if (SUI_IsGroupCreated(0, "as2_grp") || SUI_GetActiveTextDrawCount(0) != 0)
    {
        print("[TEST-AS2] FAIL: Group created or capacity consumed after invalid priority");
        return;
    }

    g_test_as2_pass = 1;
    print("[TEST-AS2] PASS: Invalid priority strictly rejected.");
}

// ----------------------------------------------------------------------------
// AS3: Negative Size Rejection
// ----------------------------------------------------------------------------
Test_AS3_NegativeSize()
{
    SUI_CleanupPlayer(0);

    new r = SUI_RegisterGroup(0, "as3_grp", "OnAS_Create", "OnAS_Destroy", "OnAS_Show", "OnAS_Hide", -10, 30000, SUI_PRIORITY_NORMAL, true);
    if (r != 0)
    {
        printf("[TEST-AS3] FAIL: Negative size accepted (returned %d)", r);
        return;
    }

    if (SUI_GetActiveTextDrawCount(0) != 0)
    {
        print("[TEST-AS3] FAIL: Active textdraw count should be 0");
        return;
    }

    g_test_as3_pass = 1;
    print("[TEST-AS3] PASS: Negative size strictly rejected.");
}

// ----------------------------------------------------------------------------
// AS4: Negative Timeout Rejection
// ----------------------------------------------------------------------------
Test_AS4_NegativeTimeout()
{
    SUI_CleanupPlayer(0);

    new r = SUI_RegisterGroup(0, "as4_grp", "OnAS_Create", "OnAS_Destroy", "OnAS_Show", "OnAS_Hide", 3, -500, SUI_PRIORITY_NORMAL, true);
    if (r != 0)
    {
        printf("[TEST-AS4] FAIL: Negative timeout accepted (returned %d)", r);
        return;
    }

    if (SUI_GetActiveTextDrawCount(0) != 0)
    {
        print("[TEST-AS4] FAIL: Active textdraw count should be 0");
        return;
    }

    g_test_as4_pass = 1;
    print("[TEST-AS4] PASS: Negative timeout strictly rejected.");
}

// ----------------------------------------------------------------------------
// AS5: Invalid Player ID Rejection
// ----------------------------------------------------------------------------
Test_AS5_InvalidPlayerId()
{
    new r1 = SUI_RegisterGroup(-1, "as5_grp", "OnAS_Create", "OnAS_Destroy", "OnAS_Show", "OnAS_Hide", 2, 30000);
    new r2 = SUI_RegisterGroup(1000, "as5_grp", "OnAS_Create", "OnAS_Destroy", "OnAS_Show", "OnAS_Hide", 2, 30000);
    new r3 = SUI_RegisterGroup(INVALID_PLAYER_ID, "as5_grp", "OnAS_Create", "OnAS_Destroy", "OnAS_Show", "OnAS_Hide", 2, 30000);

    if (r1 != 0 || r2 != 0 || r3 != 0)
    {
        printf("[TEST-AS5] FAIL: Invalid player ID accepted (r1=%d, r2=%d, r3=%d)", r1, r2, r3);
        return;
    }

    if (SUI_GetActiveTextDrawCount(-1) != 0 || SUI_GetActiveTextDrawCount(1000) != 0)
    {
        print("[TEST-AS5] FAIL: Phantom context created for invalid player ID");
        return;
    }

    g_test_as5_pass = 1;
    print("[TEST-AS5] PASS: Invalid player IDs strictly rejected.");
}

// ----------------------------------------------------------------------------
// AS6: Re-Registration / Idempotent Update
// ----------------------------------------------------------------------------
Test_AS6_ReRegistration()
{
    SUI_CleanupPlayer(0);

    // Initial registration with size 3
    new r1 = SUI_RegisterGroup(0, "as6_grp", "OnAS_Create", "OnAS_Destroy", "OnAS_Show", "OnAS_Hide", 3, 30000, SUI_PRIORITY_NORMAL, true);
    if (r1 != 1)
    {
        printf("[TEST-AS6] FAIL: Initial registration returned %d", r1);
        return;
    }

    // Re-register same uncreated group with size 7 and new timeout
    new r2 = SUI_RegisterGroup(0, "as6_grp", "OnAS_Create", "OnAS_Destroy", "OnAS_Show", "OnAS_Hide", 7, 15000, SUI_PRIORITY_HIGH, false);
    if (r2 != 1)
    {
        printf("[TEST-AS6] FAIL: Re-registration update returned %d", r2);
        return;
    }

    // Show group and verify updated size 7 was applied
    if (!SUI_ShowGroup(0, "as6_grp"))
    {
        print("[TEST-AS6] FAIL: ShowGroup failed on updated group");
        return;
    }

    if (SUI_GetActiveTextDrawCount(0) != 7)
    {
        printf("[TEST-AS6] FAIL: Active count is %d (7 expected after update)", SUI_GetActiveTextDrawCount(0));
        return;
    }

    if (SUI_IsGroupEvictable(0, "as6_grp"))
    {
        print("[TEST-AS6] FAIL: Group should have evictable=false after update");
        return;
    }

    SUI_CleanupPlayer(0);
    g_test_as6_pass = 1;
    print("[TEST-AS6] PASS: Re-registration update verified cleanly.");
}

// ----------------------------------------------------------------------------
// AS7: Usable Configuration After Setup
// ----------------------------------------------------------------------------
Test_AS7_UsableConfig()
{
    SUI_CleanupPlayer(0);

    new r = SUI_RegisterGroup(0, "as7_grp", "OnAS_Create", "OnAS_Destroy", "OnAS_Show", "OnAS_Hide", 4, 25000, SUI_PRIORITY_HIGH, false);
    if (r != 1)
    {
        printf("[TEST-AS7] FAIL: Registration returned %d", r);
        return;
    }

    if (!SUI_ShowGroup(0, "as7_grp"))
    {
        print("[TEST-AS7] FAIL: ShowGroup failed");
        return;
    }

    if (!SUI_TouchGroup(0, "as7_grp"))
    {
        print("[TEST-AS7] FAIL: TouchGroup failed");
        return;
    }

    if (!SUI_HideGroup(0, "as7_grp"))
    {
        print("[TEST-AS7] FAIL: HideGroup failed");
        return;
    }

    if (SUI_IsGroupVisible(0, "as7_grp"))
    {
        print("[TEST-AS7] FAIL: Group should be hidden");
        return;
    }

    if (!SUI_IsGroupCreated(0, "as7_grp"))
    {
        print("[TEST-AS7] FAIL: Hidden group should remain created");
        return;
    }

    if (SUI_GetActiveTextDrawCount(0) != 4)
    {
        printf("[TEST-AS7] FAIL: Active count is %d (4 expected)", SUI_GetActiveTextDrawCount(0));
        return;
    }

    SUI_CleanupPlayer(0);
    g_test_as7_pass = 1;
    print("[TEST-AS7] PASS: Group configuration fully usable through complete lifecycle.");
}

// ----------------------------------------------------------------------------
// AS8: Prevalidation Failure Leaves No Registration
// ----------------------------------------------------------------------------
Test_AS8_NoPartialState()
{
    SUI_CleanupPlayer(0);

    // Try registering with invalid priority 99 (prevalidation must reject before registration)
    new rFail = SUI_RegisterGroup(0, "as8_grp", "OnAS_Create", "OnAS_Destroy", "OnAS_Show", "OnAS_Hide", 6, 30000, 99, true);
    if (rFail != 0)
    {
        printf("[TEST-AS8] FAIL: Initial invalid registration returned %d (0 expected)", rFail);
        return;
    }

    // Now register same group name with valid parameters
    new rClean = SUI_RegisterGroup(0, "as8_grp", "OnAS_Create", "OnAS_Destroy", "OnAS_Show", "OnAS_Hide", 6, 20000, SUI_PRIORITY_NORMAL, true);
    if (rClean != 1)
    {
        printf("[TEST-AS8] FAIL: Clean registration under same name returned %d (1 expected)", rClean);
        return;
    }

    // Show and verify complete lifecycle works
    if (!SUI_ShowGroup(0, "as8_grp"))
    {
        print("[TEST-AS8] FAIL: ShowGroup failed on clean registration");
        return;
    }

    if (SUI_GetActiveTextDrawCount(0) != 6)
    {
        printf("[TEST-AS8] FAIL: Active count is %d (6 expected)", SUI_GetActiveTextDrawCount(0));
        return;
    }

    if (!SUI_DestroyGroup(0, "as8_grp"))
    {
        print("[TEST-AS8] FAIL: DestroyGroup failed");
        return;
    }

    if (SUI_GetActiveTextDrawCount(0) != 0)
    {
        print("[TEST-AS8] FAIL: Active count should be 0 after destroy");
        return;
    }

    SUI_CleanupPlayer(0);
    g_test_as8_pass = 1;
    print("[TEST-AS8] PASS: Prevalidation failure leaves no registration; subsequent registration clean.");
}

// ----------------------------------------------------------------------------
// AS9: Existing Created Group Re-registration Safety
// ----------------------------------------------------------------------------
Test_AS9_ExistingGroupSafety()
{
    SUI_CleanupPlayer(0);
    g_as9_destroy_called = 0;

    print("[TEST-AS9] Step 1: Register and show a live group...");
    // 1. Register and show a live group
    new r1 = SUI_RegisterGroup(0, "as9_grp", "OnAS_Create", "OnAS9_Destroy", "OnAS_Show", "OnAS_Hide", 5, 30000, SUI_PRIORITY_NORMAL, true);
    if (r1 != 1)
    {
        printf("[TEST-AS9] FAIL: Initial registration returned %d", r1);
        return;
    }

    if (!SUI_ShowGroup(0, "as9_grp"))
    {
        print("[TEST-AS9] FAIL: Initial show failed");
        return;
    }

    if (!SUI_IsGroupCreated(0, "as9_grp") || !SUI_IsGroupVisible(0, "as9_grp"))
    {
        print("[TEST-AS9] FAIL: Group not created or not visible");
        return;
    }

    if (SUI_GetActiveTextDrawCount(0) != 5)
    {
        printf("[TEST-AS9] FAIL: Initial active count is %d (5 expected)", SUI_GetActiveTextDrawCount(0));
        return;
    }

    print("[TEST-AS9] Step 2: Attempting to re-register already created group with different size...");
    // 2. Attempt to re-register the ALREADY CREATED group with different size
    // SUI_SetGroupSize will fail on an already created group, so SUI_RegisterGroup returns 0.
    // Crucially: under Model B, SUI_RegisterGroup must NOT call SUI_DestroyGroup!
    new r2 = SUI_RegisterGroup(0, "as9_grp", "OnAS_Create", "OnAS9_Destroy", "OnAS_Show", "OnAS_Hide", 10, 30000, SUI_PRIORITY_NORMAL, true);
    if (r2 != 0)
    {
        printf("[TEST-AS9] FAIL: Re-registering created group with new size returned %d (0 expected)", r2);
        return;
    }

    print("[TEST-AS9] Step 3: Verifying existing live group remains intact (not destroyed by failed helper)...");
    // 3. Verify existing live group was NOT destroyed
    if (!SUI_IsGroupCreated(0, "as9_grp"))
    {
        print("[TEST-AS9] FAIL: Existing created group was destroyed by failed re-registration!");
        return;
    }

    if (!SUI_IsGroupVisible(0, "as9_grp"))
    {
        print("[TEST-AS9] FAIL: Existing created group lost visibility!");
        return;
    }

    if (SUI_GetActiveTextDrawCount(0) != 5)
    {
        printf("[TEST-AS9] FAIL: Active count corrupted: %d (5 expected)", SUI_GetActiveTextDrawCount(0));
        return;
    }

    if (g_as9_destroy_called != 0)
    {
        printf("[TEST-AS9] FAIL: Destroy callback called %d times during failed re-registration!", g_as9_destroy_called);
        return;
    }

    print("[TEST-AS9] Step 4: Normal destruction of live group...");
    // 4. Normal destruction works cleanly
    if (!SUI_DestroyGroup(0, "as9_grp"))
    {
        print("[TEST-AS9] FAIL: Final clean destroy failed");
        return;
    }

    if (g_as9_destroy_called != 1)
    {
        printf("[TEST-AS9] FAIL: Destroy callback count is %d (1 expected after clean destroy)", g_as9_destroy_called);
        return;
    }

    if (SUI_GetActiveTextDrawCount(0) != 0)
    {
        print("[TEST-AS9] FAIL: Active count not 0 after clean destroy");
        return;
    }

    SUI_CleanupPlayer(0);
    g_test_as9_pass = 1;
    print("[TEST-AS9] PASS: Re-registering created group fails safely without destroying live UI.");
}

PrintSummaryAndExit()
{
    new totalPass = g_test_as1_pass + g_test_as2_pass + g_test_as3_pass + g_test_as4_pass +
                    g_test_as5_pass + g_test_as6_pass + g_test_as7_pass + g_test_as8_pass +
                    g_test_as9_pass;

    print("\n================================================================");
    print("    SUI PHASE 12.2: STOCK HELPER RUNTIME TEST RESULTS (AS1-AS9)   ");
    print("================================================================");
    printf("AS1 (Valid SUI_RegisterGroup Setup):              %s", g_test_as1_pass ? ("PASS") : ("FAIL"));
    printf("AS2 (Invalid Priority Rejection):                 %s", g_test_as2_pass ? ("PASS") : ("FAIL"));
    printf("AS3 (Negative Size Rejection):                    %s", g_test_as3_pass ? ("PASS") : ("FAIL"));
    printf("AS4 (Negative Timeout Rejection):                 %s", g_test_as4_pass ? ("PASS") : ("FAIL"));
    printf("AS5 (Invalid Player ID Rejection):                %s", g_test_as5_pass ? ("PASS") : ("FAIL"));
    printf("AS6 (Re-Registration / Config Update):            %s", g_test_as6_pass ? ("PASS") : ("FAIL"));
    printf("AS7 (Usable Configuration Lifecycle):             %s", g_test_as7_pass ? ("PASS") : ("FAIL"));
    printf("AS8 (Prevalidation Failure Cleanliness):          %s", g_test_as8_pass ? ("PASS") : ("FAIL"));
    printf("AS9 (Existing Created Group Re-reg Safety):       %s", g_test_as9_pass ? ("PASS") : ("FAIL"));
    print("================================================================");
    printf("TOTAL: %d / 9 PASSED", totalPass);
    if (totalPass == 9)
    {
        print("OVERALL RESULT: ALL STOCK HELPER CONTRACT TESTS PASSED!");
    }
    else
    {
        print("OVERALL RESULT: SOME TESTS FAILED!");
    }
    print("================================================================\n");

    SendRconCommand("exit");
}

public OnGameModeInit()
{
    print("\n[TEST-START] Starting SUI Phase 12.2 Stock Helper Contract Suite (AS1-AS9)...");
    SUI_SetDebug(true);

    Test_AS1_ValidRegistration();
    Test_AS2_InvalidPriority();
    Test_AS3_NegativeSize();
    Test_AS4_NegativeTimeout();
    Test_AS5_InvalidPlayerId();
    Test_AS6_ReRegistration();
    Test_AS7_UsableConfig();
    Test_AS8_NoPartialState();
    Test_AS9_ExistingGroupSafety();

    PrintSummaryAndExit();
    return 1;
}
