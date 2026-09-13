#include <a_samp>
#include <sui>

// Low-level raw native declarations to test address and parameter count boundaries
native Raw_ShowGroup(playerid, group_addr) = SUI_ShowGroup;
native Insufficient_CreateGroup(playerid, const group[]) = SUI_CreatePlayerFactoryGroup;

new g_v1_pass = 0;
new g_v2_pass = 0;
new g_v3_pass = 0;
new g_v4_pass = 0;
new g_v5_pass = 0;
new g_v6_pass = 0;
new g_v7_pass = 0;
new g_v8_pass = 0;
new g_v9_pass = 0;
new g_v10_pass = 0;

main()
{
    print("================================================================");
    print("      SUI-003 PAWN NATIVE INPUT VALIDATION REGRESSION TEST      ");
    print("================================================================");
}

public OnGameModeInit()
{
    SUI_SetDebug(true);
    SetTimer("RunValidationTests", 500, false);
    return 1;
}

forward RunValidationTests();
public RunValidationTests()
{
    print("\n--- Starting Native Validation Tests (V1-V10) ---");

    // Register a baseline group for setter testing
    SUI_CreatePlayerFactoryGroup(0, "valid_group", "OnV_Create", "OnV_Destroy", "OnV_Show", "OnV_Hide");
    SUI_SetGroupSize(0, "valid_group", 5);

    // -------------------------------------------------------------
    // TEST V1: Negative Group Size
    // -------------------------------------------------------------
    print("\n[TEST-V1] Testing Negative Group Size...");
    new v1_res = SUI_SetGroupSize(0, "valid_group", -1);
    if (v1_res == 0)
    {
        g_v1_pass = 1;
        print("[TEST-V1] PASS: Negative group size rejected (return 0).");
    }
    else
    {
        printf("[TEST-V1] FAIL: Expected return 0, got %d", v1_res);
    }

    // -------------------------------------------------------------
    // TEST V2: Negative Max TextDraws
    // -------------------------------------------------------------
    print("\n[TEST-V2] Testing Negative Max TextDraws...");
    new v2_res = SUI_SetMaxTextDraws(0, -1);
    if (v2_res == 0)
    {
        g_v2_pass = 1;
        print("[TEST-V2] PASS: Negative max textdraws rejected (return 0).");
    }
    else
    {
        printf("[TEST-V2] FAIL: Expected return 0, got %d", v2_res);
    }

    // -------------------------------------------------------------
    // TEST V3: Negative Eviction Threshold
    // -------------------------------------------------------------
    print("\n[TEST-V3] Testing Negative Eviction Threshold...");
    new v3_res = SUI_SetEvictionThreshold(0, -1);
    if (v3_res == 0)
    {
        g_v3_pass = 1;
        print("[TEST-V3] PASS: Negative eviction threshold rejected (return 0).");
    }
    else
    {
        printf("[TEST-V3] FAIL: Expected return 0, got %d", v3_res);
    }

    // -------------------------------------------------------------
    // TEST V4: Negative Idle Timeout
    // -------------------------------------------------------------
    print("\n[TEST-V4] Testing Negative Idle Timeout...");
    new v4_res = SUI_SetIdleTimeout(0, "valid_group", -1);
    if (v4_res == 0)
    {
        g_v4_pass = 1;
        print("[TEST-V4] PASS: Negative idle timeout rejected (return 0).");
    }
    else
    {
        printf("[TEST-V4] FAIL: Expected return 0, got %d", v4_res);
    }

    // -------------------------------------------------------------
    // TEST V5: Priority Domain Range
    // -------------------------------------------------------------
    print("\n[TEST-V5] Testing Priority Domain Range...");
    new r_neg = SUI_SetGroupPriority(0, "valid_group", -1);
    new r_low = SUI_SetGroupPriority(0, "valid_group", SUI_PRIORITY_LOW);
    new r_norm = SUI_SetGroupPriority(0, "valid_group", SUI_PRIORITY_NORMAL);
    new r_high = SUI_SetGroupPriority(0, "valid_group", SUI_PRIORITY_HIGH);
    new r_crit = SUI_SetGroupPriority(0, "valid_group", SUI_PRIORITY_CRITICAL);
    new r_above = SUI_SetGroupPriority(0, "valid_group", 4);
    new r_huge = SUI_SetGroupPriority(0, "valid_group", 9999);

    if (r_neg == 0 && r_low == 1 && r_norm == 1 && r_high == 1 && r_crit == 1 && r_above == 0 && r_huge == 0)
    {
        g_v5_pass = 1;
        print("[TEST-V5] PASS: Only priority values within [0..3] accepted.");
    }
    else
    {
        printf("[TEST-V5] FAIL: neg=%d low=%d norm=%d high=%d crit=%d above=%d huge=%d",
            r_neg, r_low, r_norm, r_high, r_crit, r_above, r_huge);
    }

    // -------------------------------------------------------------
    // TEST V6: Zero Values Semantic Validation
    // -------------------------------------------------------------
    print("\n[TEST-V6] Testing Zero Values Semantic Validation...");
    new z_size = SUI_SetGroupSize(0, "valid_group", 0);
    new z_timeout = SUI_SetIdleTimeout(0, "valid_group", 0);
    new z_max = SUI_SetMaxTextDraws(0, 0);
    new z_thresh = SUI_SetEvictionThreshold(0, 0);
    new z_prio = SUI_SetGroupPriority(0, "valid_group", 0);

    if (z_size == 1 && z_timeout == 1 && z_max == 1 && z_thresh == 1 && z_prio == 1)
    {
        g_v6_pass = 1;
        print("[TEST-V6] PASS: Zero values accepted and normalized per current API semantics.");
    }
    else
    {
        printf("[TEST-V6] FAIL: z_size=%d z_timeout=%d z_max=%d z_thresh=%d z_prio=%d",
            z_size, z_timeout, z_max, z_thresh, z_prio);
    }

    // -------------------------------------------------------------
    // TEST V7: Large Positive Cell Value (0x7FFFFFFF = 2147483647)
    // -------------------------------------------------------------
    print("\n[TEST-V7] Testing Large Positive Cell Value (2147483647)...");
    new v7_res = SUI_SetGroupSize(0, "valid_group", 2147483647);
    if (v7_res == 1)
    {
        g_v7_pass = 1;
        print("[TEST-V7] PASS: Large positive 31-bit integer correctly accepted without signed wrap.");
    }
    else
    {
        printf("[TEST-V7] FAIL: Expected return 1, got %d", v7_res);
    }

    // -------------------------------------------------------------
    // TEST V8: Invalid String Address
    // -------------------------------------------------------------
    print("\n[TEST-V8] Testing Invalid String Address (0x7FFFFFFF)...");
    new v8_res = Raw_ShowGroup(0, 0x7FFFFFFF);
    if (v8_res == 0)
    {
        g_v8_pass = 1;
        print("[TEST-V8] PASS: Invalid string address rejected safely (return 0, no crash).");
    }
    else
    {
        printf("[TEST-V8] FAIL: Expected return 0, got %d", v8_res);
    }

    // -------------------------------------------------------------
    // TEST V9: Out-of-Bounds / Negative AMX String Address (-1)
    // -------------------------------------------------------------
    print("\n[TEST-V9] Testing Out-of-Bounds String Address (-1)...");
    new v9_res = Raw_ShowGroup(0, -1);
    if (v9_res == 0)
    {
        g_v9_pass = 1;
        print("[TEST-V9] PASS: Negative string address rejected safely (return 0, no crash).");
    }
    else
    {
        printf("[TEST-V9] FAIL: Expected return 0, got %d", v9_res);
    }

    // -------------------------------------------------------------
    // TEST V10: Malformed / Insufficient Native Arguments
    // -------------------------------------------------------------
    print("\n[TEST-V10] Testing Insufficient Native Arguments...");
    new v10_res = Insufficient_CreateGroup(0, "v10_short");
    if (v10_res == 0)
    {
        g_v10_pass = 1;
        print("[TEST-V10] PASS: Native with insufficient parameters rejected safely (return 0).");
    }
    else
    {
        printf("[TEST-V10] FAIL: Expected return 0, got %d", v10_res);
    }

    // -------------------------------------------------------------
    // SUMMARY REPORT
    // -------------------------------------------------------------
    print("\n================================================================");
    print("          SUI NATIVE VALIDATION REGRESSION RESULTS (V1-V10)     ");
    print("================================================================");
    printf("V1  (Negative Group Size):                 %s", (g_v1_pass) ? ("PASS") : ("FAIL"));
    printf("V2  (Negative Max TextDraws):              %s", (g_v2_pass) ? ("PASS") : ("FAIL"));
    printf("V3  (Negative Eviction Threshold):         %s", (g_v3_pass) ? ("PASS") : ("FAIL"));
    printf("V4  (Negative Idle Timeout):               %s", (g_v4_pass) ? ("PASS") : ("FAIL"));
    printf("V5  (Priority Domain Range):               %s", (g_v5_pass) ? ("PASS") : ("FAIL"));
    printf("V6  (Zero Values Semantic Validation):     %s", (g_v6_pass) ? ("PASS") : ("FAIL"));
    printf("V7  (Large Positive Cell Value):           %s", (g_v7_pass) ? ("PASS") : ("FAIL"));
    printf("V8  (Invalid String Address):              %s", (g_v8_pass) ? ("PASS") : ("FAIL"));
    printf("V9  (Negative / Out-of-Bounds Address):    %s", (g_v9_pass) ? ("PASS") : ("FAIL"));
    printf("V10 (Insufficient Parameter Count):        %s", (g_v10_pass) ? ("PASS") : ("FAIL"));
    print("================================================================");

    if (g_v1_pass && g_v2_pass && g_v3_pass && g_v4_pass && g_v5_pass &&
        g_v6_pass && g_v7_pass && g_v8_pass && g_v9_pass && g_v10_pass)
    {
        print("OVERALL RESULT: ALL NATIVE VALIDATION TESTS PASSED!");
    }
    else
    {
        print("OVERALL RESULT: SOME TESTS FAILED!");
    }
    print("================================================================\n");

    print("--- Terminating server after test completion.");
    SendRconCommand("exit");
    return 1;
}

forward OnV_Create(playerid);
public OnV_Create(playerid) { return 1; }
forward OnV_Destroy(playerid);
public OnV_Destroy(playerid) { return 1; }
forward OnV_Show(playerid);
public OnV_Show(playerid) { return 1; }
forward OnV_Hide(playerid);
public OnV_Hide(playerid) { return 1; }
