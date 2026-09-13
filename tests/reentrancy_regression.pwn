/**
 * ============================================================================
 * SUI — Smart UI Virtualizer
 * DEVELOPMENT / REGRESSION TEST ONLY: Re-entrancy & Memory Safety (SUI-001)
 * ============================================================================
 * 
 * WARNING: This script contains intentionally destructive re-entrant callback
 * patterns designed to stress-test C++ container safety and memory boundaries.
 * DO NOT USE THIS SCRIPT AS A PRODUCTION EXAMPLE.
 */

#if defined _INC_open_mp
    // open.mp include
#elseif !defined _samp_included
    #include <a_samp>
#endif
#include <sui>

// Regression assertion flags
static gR1_Pass = 0;
static gR2_Pass = 0;
static gR3_Pass = 0;
static gR4_Pass = 0;
static gR5_Pass = 0;
static gR6_Pass = 0;
static gR7_Pass = 0;
static gR8_Pass = 0;
static gR9_Pass = 0;
static gR10_Pass = 0;

forward OnDummy(playerid);
public OnDummy(playerid)
{
    return 1;
}

/*
 * ----------------------------------------------------------------------------
 * Scenario R1: Create callback calls SUI_ResetPlayer
 * ----------------------------------------------------------------------------
 */
forward OnR1_Create(playerid);
public OnR1_Create(playerid)
{
    printf("[TEST-R1] OnR1_Create invoked. Calling SUI_ResetPlayer(%d)...", playerid);
    SUI_ResetPlayer(playerid);
    gR1_Pass = 1;
    printf("[TEST-R1] SUI_ResetPlayer completed inside callback.");
    return 1;
}

/*
 * ----------------------------------------------------------------------------
 * Scenario R2: Show callback calls SUI_CleanupPlayer
 * ----------------------------------------------------------------------------
 */
forward OnR2_Show(playerid);
public OnR2_Show(playerid)
{
    printf("[TEST-R2] OnR2_Show invoked. Calling SUI_CleanupPlayer(%d)...", playerid);
    SUI_CleanupPlayer(playerid);
    gR2_Pass = 1;
    printf("[TEST-R2] SUI_CleanupPlayer completed inside callback.");
    return 1;
}

/*
 * ----------------------------------------------------------------------------
 * Scenario R3: Hide callback destroys its own group
 * ----------------------------------------------------------------------------
 */
forward OnR3_Hide(playerid);
public OnR3_Hide(playerid)
{
    printf("[TEST-R3] OnR3_Hide invoked. Calling SUI_DestroyGroup(%d, 'r3_group')...", playerid);
    SUI_DestroyGroup(playerid, "r3_group");
    gR3_Pass = 1;
    printf("[TEST-R3] SUI_DestroyGroup completed inside hide callback.");
    return 1;
}

/*
 * ----------------------------------------------------------------------------
 * Scenario R4: Destroy callback registers another group
 * ----------------------------------------------------------------------------
 */
forward OnR4_Destroy(playerid);
public OnR4_Destroy(playerid)
{
    printf("[TEST-R4] OnR4_Destroy invoked. Registering new group 'r4_spawned'...");
    SUI_CreatePlayerFactoryGroup(playerid, "r4_spawned", "OnDummy", "OnDummy", "OnDummy", "OnDummy");
    gR4_Pass = 1;
    printf("[TEST-R4] Group 'r4_spawned' registered successfully inside destroy callback.");
    return 1;
}

/*
 * ----------------------------------------------------------------------------
 * Scenario R5: Destroy callback resets player
 * ----------------------------------------------------------------------------
 */
forward OnR5_Destroy(playerid);
public OnR5_Destroy(playerid)
{
    printf("[TEST-R5] OnR5_Destroy invoked. Calling SUI_ResetPlayer(%d)...", playerid);
    SUI_ResetPlayer(playerid);
    gR5_Pass = 1;
    printf("[TEST-R5] SUI_ResetPlayer completed inside destroy callback.");
    return 1;
}

/*
 * ----------------------------------------------------------------------------
 * Scenario R6: Callback registers 50 groups to trigger hash table rehash
 * ----------------------------------------------------------------------------
 */
forward OnR6_Create(playerid);
public OnR6_Create(playerid)
{
    printf("[TEST-R6] OnR6_Create invoked. Registering 50 groups to force rehash...");
    new nameBuf[32];
    for (new i = 0; i < 50; i++)
    {
        format(nameBuf, sizeof(nameBuf), "r6_extra_%d", i);
        SUI_CreatePlayerFactoryGroup(playerid, nameBuf, "OnDummy", "OnDummy", "OnDummy", "OnDummy");
    }
    gR6_Pass = 1;
    printf("[TEST-R6] 50 groups registered inside callback.");
    return 1;
}

/*
 * ----------------------------------------------------------------------------
 * Scenario R7: ProcessTick idle destruction invokes callback mutating groups
 * ----------------------------------------------------------------------------
 */
forward OnR7_Destroy(playerid);
public OnR7_Destroy(playerid)
{
    printf("[TEST-R7] OnR7_Destroy invoked during ProcessTick. Calling SUI_DestroyGroup for r7_other...");
    SUI_DestroyGroup(playerid, "r7_other");
    gR7_Pass = 1;
    printf("[TEST-R7] SUI_DestroyGroup completed inside ProcessTick callback.");
    return 1;
}

/*
 * ----------------------------------------------------------------------------
 * Scenario R8: ProcessTick callback removes current player context
 * ----------------------------------------------------------------------------
 */
forward OnR8_Destroy(playerid);
public OnR8_Destroy(playerid)
{
    printf("[TEST-R8] OnR8_Destroy invoked during ProcessTick. Calling SUI_CleanupPlayer(%d)...", playerid);
    SUI_CleanupPlayer(playerid);
    gR8_Pass = 1;
    printf("[TEST-R8] SUI_CleanupPlayer completed inside ProcessTick callback.");
    return 1;
}

/*
 * ----------------------------------------------------------------------------
 * Scenario R9: Nested same-group operation (recursion guard)
 * ----------------------------------------------------------------------------
 */
forward OnR9_Create(playerid);
public OnR9_Create(playerid)
{
    printf("[TEST-R9] OnR9_Create invoked. Calling recursive SUI_ShowGroup on self...");
    SUI_ShowGroup(playerid, "r9_group");
    gR9_Pass = 1;
    printf("[TEST-R9] Recursive SUI_ShowGroup returned safely without infinite loop.");
    return 1;
}

/*
 * ----------------------------------------------------------------------------
 * Scenario R10: Nested operation affecting a different group
 * ----------------------------------------------------------------------------
 */
forward OnR10_ShowA(playerid);
public OnR10_ShowA(playerid)
{
    printf("[TEST-R10] OnR10_ShowA invoked. Calling SUI_ShowGroup for r10_b...");
    SUI_ShowGroup(playerid, "r10_b");
    gR10_Pass = 1;
    printf("[TEST-R10] SUI_ShowGroup for r10_b returned inside OnR10_ShowA.");
    return 1;
}

forward OnR10_ShowB(playerid);
public OnR10_ShowB(playerid)
{
    printf("[TEST-R10] OnR10_ShowB invoked successfully.");
    return 1;
}

/*
 * ----------------------------------------------------------------------------
 * Headless Test Runner
 * ----------------------------------------------------------------------------
 */
forward FinishRegressionSuite();
public FinishRegressionSuite()
{
    printf(" ");
    printf("================================================================");
    printf("         SUI RE-ENTRANCY REGRESSION TEST RESULTS (R1-R10)       ");
    printf("================================================================");
    if (gR1_Pass) printf("R1  (Create -> ResetPlayer):                 PASS");
    else printf("R1  (Create -> ResetPlayer):                 FAIL");

    if (gR2_Pass) printf("R2  (Show -> CleanupPlayer):                  PASS");
    else printf("R2  (Show -> CleanupPlayer):                  FAIL");

    if (gR3_Pass) printf("R3  (Hide -> Destroy Self):                   PASS");
    else printf("R3  (Hide -> Destroy Self):                   FAIL");

    if (gR4_Pass) printf("R4  (Destroy -> Register New):                PASS");
    else printf("R4  (Destroy -> Register New):                FAIL");

    if (gR5_Pass) printf("R5  (Destroy -> ResetPlayer):                 PASS");
    else printf("R5  (Destroy -> ResetPlayer):                 FAIL");

    if (gR6_Pass) printf("R6  (Rehash via 50 Inserts):                  PASS");
    else printf("R6  (Rehash via 50 Inserts):                  FAIL");

    if (gR7_Pass) printf("R7  (ProcessTick Idle -> Mutate Groups):      PASS");
    else printf("R7  (ProcessTick Idle -> Mutate Groups):      FAIL");

    if (gR8_Pass) printf("R8  (ProcessTick Idle -> Cleanup Player):     PASS");
    else printf("R8  (ProcessTick Idle -> Cleanup Player):     FAIL");

    if (gR9_Pass) printf("R9  (Same-Group Recursion Guard):             PASS");
    else printf("R9  (Same-Group Recursion Guard):             FAIL");

    if (gR10_Pass) printf("R10 (Cross-Group Nested Show):                PASS");
    else printf("R10 (Cross-Group Nested Show):                FAIL");
    printf("================================================================");

    new allPassed = gR1_Pass && gR2_Pass && gR3_Pass && gR4_Pass && gR5_Pass &&
                    gR6_Pass && gR7_Pass && gR8_Pass && gR9_Pass && gR10_Pass;

    if (allPassed)
    {
        printf("OVERALL RESULT: ALL RE-ENTRANCY REGRESSION TESTS PASSED!");
    }
    else
    {
        printf("OVERALL RESULT: SOME REGRESSION TESTS FAILED!");
    }
    printf("================================================================");
    printf(" ");

    // Gracefully terminate test server
    SendRconCommand("exit");
    return 1;
}

main()
{
    printf("[SUI-TEST] Main entry point invoked.");
}

public OnGameModeInit()
{
    printf("================================================================");
    printf("STARTING SUI RE-ENTRANCY REGRESSION SUITE (HEADLESS)");
    printf("================================================================");

    SUI_SetDebug(true);

    // --- TEST R1: Create -> ResetPlayer ---
    printf("[RUNNING] Test R1: Create -> ResetPlayer...");
    SUI_CreatePlayerFactoryGroup(0, "r1_group", "OnR1_Create", "OnDummy", "OnDummy", "OnDummy");
    SUI_ShowGroup(0, "r1_group");
    printf("[COMPLETED] Test R1.\n");

    // --- TEST R2: Show -> CleanupPlayer ---
    printf("[RUNNING] Test R2: Show -> CleanupPlayer...");
    SUI_CreatePlayerFactoryGroup(0, "r2_group", "OnDummy", "OnDummy", "OnR2_Show", "OnDummy");
    SUI_ShowGroup(0, "r2_group");
    printf("[COMPLETED] Test R2.\n");

    // --- TEST R3: Hide -> Destroy Self ---
    printf("[RUNNING] Test R3: Hide -> Destroy Self...");
    SUI_CreatePlayerFactoryGroup(0, "r3_group", "OnDummy", "OnDummy", "OnDummy", "OnR3_Hide");
    SUI_ShowGroup(0, "r3_group");
    SUI_HideGroup(0, "r3_group");
    printf("[COMPLETED] Test R3.\n");

    // --- TEST R4: Destroy -> Register New ---
    printf("[RUNNING] Test R4: Destroy -> Register New...");
    SUI_CreatePlayerFactoryGroup(0, "r4_group", "OnDummy", "OnR4_Destroy", "OnDummy", "OnDummy");
    SUI_ShowGroup(0, "r4_group");
    SUI_DestroyGroup(0, "r4_group");
    printf("[COMPLETED] Test R4.\n");

    // --- TEST R5: Destroy -> ResetPlayer ---
    printf("[RUNNING] Test R5: Destroy -> ResetPlayer...");
    SUI_CreatePlayerFactoryGroup(0, "r5_group", "OnDummy", "OnR5_Destroy", "OnDummy", "OnDummy");
    SUI_ShowGroup(0, "r5_group");
    SUI_DestroyGroup(0, "r5_group");
    printf("[COMPLETED] Test R5.\n");

    // --- TEST R6: Rehash via 50 Inserts ---
    printf("[RUNNING] Test R6: Rehash via 50 Inserts...");
    SUI_CreatePlayerFactoryGroup(0, "r6_group", "OnR6_Create", "OnDummy", "OnDummy", "OnDummy");
    SUI_ShowGroup(0, "r6_group");
    printf("[COMPLETED] Test R6.\n");

    // --- TEST R9: Same-Group Recursion Guard ---
    printf("[RUNNING] Test R9: Same-Group Recursion Guard...");
    SUI_CreatePlayerFactoryGroup(0, "r9_group", "OnR9_Create", "OnDummy", "OnDummy", "OnDummy");
    SUI_ShowGroup(0, "r9_group");
    printf("[COMPLETED] Test R9.\n");

    // --- TEST R10: Cross-Group Nested Show ---
    printf("[RUNNING] Test R10: Cross-Group Nested Show...");
    SUI_CreatePlayerFactoryGroup(0, "r10_a", "OnDummy", "OnDummy", "OnR10_ShowA", "OnDummy");
    SUI_CreatePlayerFactoryGroup(0, "r10_b", "OnDummy", "OnDummy", "OnR10_ShowB", "OnDummy");
    SUI_ShowGroup(0, "r10_a");
    printf("[COMPLETED] Test R10.\n");

    // --- SETUP R7 & R8: ProcessTick Idle Destruction ---
    printf("[SETUP] Scheduling R7 & R8 for ProcessTick evaluation...");
    // R7 for player 0
    SUI_CreatePlayerFactoryGroup(0, "r7_idle", "OnDummy", "OnR7_Destroy", "OnDummy", "OnDummy");
    SUI_CreatePlayerFactoryGroup(0, "r7_other", "OnDummy", "OnDummy", "OnDummy", "OnDummy");
    SUI_SetIdleTimeout(0, "r7_idle", 1); // 1 millisecond timeout
    SUI_ShowGroup(0, "r7_idle");
    SUI_HideGroup(0, "r7_idle"); // Starts idle clock

    // R8 for player 1
    SUI_CreatePlayerFactoryGroup(1, "r8_idle", "OnDummy", "OnR8_Destroy", "OnDummy", "OnDummy");
    SUI_SetIdleTimeout(1, "r8_idle", 1); // 1 millisecond timeout
    SUI_ShowGroup(1, "r8_idle");
    SUI_HideGroup(1, "r8_idle"); // Starts idle clock

    // Schedule test finish after 1500ms to allow ProcessTick to fire repeatedly
    SetTimer("FinishRegressionSuite", 1500, false);
    return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    return 0;
}
