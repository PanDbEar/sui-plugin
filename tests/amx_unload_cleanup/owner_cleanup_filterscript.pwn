#define FILTERSCRIPT
#include <a_samp>
#include <sui>

new g_u1_hide_calls = 0;
new g_u1_destroy_calls = 0;
new g_u1_hide_tick = 0;
new g_u1_destroy_tick = 0;

new g_u2_hide_calls = 0;
new g_u2_destroy_calls = 0;

new g_u3_hide_calls = 0;
new g_u3_destroy_calls = 0;

new g_u4_fs_destroy_calls = 0;

new g_u6_reentrancy_all_rejected = 0;
new g_u6_destroy_calls = 0;

new g_u9_nested_rejected = 0;

new g_u11_destroy_calls = 0;
new g_u12_destroy_calls = 0;

new g_u13_destroy_calls = 0;

new PlayerText:g_u8_ptds[256];
new g_u8_ptd_count = 0;
new g_u8_first_ptd_id = -1;

new g_u14_read_only_success = 0;

public OnFilterScriptInit()
{
    print("[FS] owner_cleanup_filterscript loaded.");
    return 1;
}

public OnFilterScriptExit()
{
    print("[FS] OnFilterScriptExit: executing SUI_CleanupOwnerGroups()...");
    new cleanupRes = SUI_CleanupOwnerGroups();
    printf("[FS] OnFilterScriptExit: SUI_CleanupOwnerGroups() returned %d", cleanupRes);

    // U14 test: Read-only native verification immediately following cleanup
    new activeCount = SUI_GetActiveTextDrawCount(0);
    new isCreated = SUI_IsGroupCreated(0, "u1_grp");
    if (activeCount >= 0 && isCreated == 0)
    {
        g_u14_read_only_success = 1;
        print("[U14] Inside OnFilterScriptExit: read-only query executed successfully (activeCount >= 0, isCreated == 0).");
    }
    else
    {
        g_u14_read_only_success = 0;
        printf("[U14] Inside OnFilterScriptExit: FAILED read-only query (activeCount=%d, isCreated=%d)", activeCount, isCreated);
    }
    return 1;
}

// -------------------------------------------------------------
// U1: Visible Created Cleanup
// -------------------------------------------------------------
forward OnU1_Create(playerid);
public OnU1_Create(playerid) { return 1; }

forward OnU1_Show(playerid);
public OnU1_Show(playerid) { return 1; }

forward OnU1_Hide(playerid);
public OnU1_Hide(playerid)
{
    g_u1_hide_calls++;
    g_u1_hide_tick = GetTickCount();
    return 1;
}

forward OnU1_Destroy(playerid);
public OnU1_Destroy(playerid)
{
    g_u1_destroy_calls++;
    g_u1_destroy_tick = GetTickCount();
    return 1;
}

forward FS_RunU1();
public FS_RunU1()
{
    g_u1_hide_calls = 0;
    g_u1_destroy_calls = 0;
    g_u1_hide_tick = 0;
    g_u1_destroy_tick = 0;

    SUI_CreatePlayerFactoryGroup(0, "u1_grp", "OnU1_Create", "OnU1_Destroy", "OnU1_Show", "OnU1_Hide");
    SUI_SetGroupSize(0, "u1_grp", 5);
    SUI_ShowGroup(0, "u1_grp");

    new createdBefore = SUI_IsGroupCreated(0, "u1_grp");
    new visibleBefore = SUI_IsGroupVisible(0, "u1_grp");
    new countBefore = SUI_GetActiveTextDrawCount(0);

    new res = SUI_CleanupOwnerGroups();

    new createdAfter = SUI_IsGroupCreated(0, "u1_grp");
    new visibleAfter = SUI_IsGroupVisible(0, "u1_grp");
    new countAfter = SUI_GetActiveTextDrawCount(0);

    if (res == 1 &&
        createdBefore == 1 && visibleBefore == 1 &&
        g_u1_hide_calls == 1 && g_u1_destroy_calls == 1 &&
        g_u1_hide_tick <= g_u1_destroy_tick &&
        createdAfter == 0 && visibleAfter == 0 &&
        countAfter == (countBefore - 5))
    {
        return 1;
    }
    printf("[FS] U1 FAIL: res=%d cbHide=%d cbDestroy=%d order=%d createdAfter=%d visibleAfter=%d countDelta=%d",
        res, g_u1_hide_calls, g_u1_destroy_calls, (g_u1_hide_tick <= g_u1_destroy_tick),
        createdAfter, visibleAfter, countBefore - countAfter);
    return 0;
}

// -------------------------------------------------------------
// U2: Hidden Created Cleanup
// -------------------------------------------------------------
forward OnU2_Create(playerid);
public OnU2_Create(playerid) { return 1; }

forward OnU2_Show(playerid);
public OnU2_Show(playerid) { return 1; }

forward OnU2_Hide(playerid);
public OnU2_Hide(playerid)
{
    g_u2_hide_calls++;
    return 1;
}

forward OnU2_Destroy(playerid);
public OnU2_Destroy(playerid)
{
    g_u2_destroy_calls++;
    return 1;
}

forward FS_RunU2();
public FS_RunU2()
{
    g_u2_hide_calls = 0;
    g_u2_destroy_calls = 0;

    SUI_CreatePlayerFactoryGroup(0, "u2_grp", "OnU2_Create", "OnU2_Destroy", "OnU2_Show", "OnU2_Hide");
    SUI_SetGroupSize(0, "u2_grp", 3);
    SUI_ShowGroup(0, "u2_grp");
    SUI_HideGroup(0, "u2_grp");

    new createdBefore = SUI_IsGroupCreated(0, "u2_grp");
    new visibleBefore = SUI_IsGroupVisible(0, "u2_grp");
    new countBefore = SUI_GetActiveTextDrawCount(0);

    g_u2_hide_calls = 0;
    g_u2_destroy_calls = 0;

    new res = SUI_CleanupOwnerGroups();

    new createdAfter = SUI_IsGroupCreated(0, "u2_grp");
    new visibleAfter = SUI_IsGroupVisible(0, "u2_grp");
    new countAfter = SUI_GetActiveTextDrawCount(0);

    if (res == 1 &&
        createdBefore == 1 && visibleBefore == 0 &&
        g_u2_hide_calls == 0 && g_u2_destroy_calls == 1 &&
        createdAfter == 0 && visibleAfter == 0 &&
        countAfter == (countBefore - 3))
    {
        return 1;
    }
    printf("[FS] U2 FAIL: res=%d cbHide=%d cbDestroy=%d createdAfter=%d visibleAfter=%d countDelta=%d",
        res, g_u2_hide_calls, g_u2_destroy_calls, createdAfter, visibleAfter, countBefore - countAfter);
    return 0;
}

// -------------------------------------------------------------
// U3: Uncreated Cleanup
// -------------------------------------------------------------
forward OnU3_Create(playerid);
public OnU3_Create(playerid) { return 1; }

forward OnU3_Show(playerid);
public OnU3_Show(playerid) { return 1; }

forward OnU3_Hide(playerid);
public OnU3_Hide(playerid)
{
    g_u3_hide_calls++;
    return 1;
}

forward OnU3_Destroy(playerid);
public OnU3_Destroy(playerid)
{
    g_u3_destroy_calls++;
    return 1;
}

forward FS_RunU3();
public FS_RunU3()
{
    g_u3_hide_calls = 0;
    g_u3_destroy_calls = 0;

    SUI_CreatePlayerFactoryGroup(0, "u3_grp", "OnU3_Create", "OnU3_Destroy", "OnU3_Show", "OnU3_Hide");
    SUI_SetGroupSize(0, "u3_grp", 4);

    new countBefore = SUI_GetActiveTextDrawCount(0);
    new res = SUI_CleanupOwnerGroups();

    new countAfter = SUI_GetActiveTextDrawCount(0);
    new reReg = SUI_CreatePlayerFactoryGroup(0, "u3_grp", "OnU3_Create", "OnU3_Destroy", "OnU3_Show", "OnU3_Hide");
    SUI_CleanupOwnerGroups();

    if (res == 1 && g_u3_hide_calls == 0 && g_u3_destroy_calls == 0 &&
        countBefore == countAfter && reReg == 1)
    {
        return 1;
    }
    printf("[FS] U3 FAIL: res=%d cbHide=%d cbDestroy=%d reReg=%d countDelta=%d",
        res, g_u3_hide_calls, g_u3_destroy_calls, reReg, countBefore - countAfter);
    return 0;
}

// -------------------------------------------------------------
// U4: Mixed-Ownership Isolation
// -------------------------------------------------------------
forward OnU4_FS_Create(playerid);
public OnU4_FS_Create(playerid) { return 1; }

forward OnU4_FS_Show(playerid);
public OnU4_FS_Show(playerid) { return 1; }

forward OnU4_FS_Hide(playerid);
public OnU4_FS_Hide(playerid) { return 1; }

forward OnU4_FS_Destroy(playerid);
public OnU4_FS_Destroy(playerid)
{
    g_u4_fs_destroy_calls++;
    return 1;
}

forward FS_SetupU4();
public FS_SetupU4()
{
    g_u4_fs_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "fs_u4_grp", "OnU4_FS_Create", "OnU4_FS_Destroy", "OnU4_FS_Show", "OnU4_FS_Hide");
    SUI_SetGroupSize(0, "fs_u4_grp", 7);
    SUI_ShowGroup(0, "fs_u4_grp");
    return SUI_GetActiveTextDrawCount(0);
}

forward FS_RunU4_Cleanup();
public FS_RunU4_Cleanup()
{
    new res = SUI_CleanupOwnerGroups();
    new fsCreated = SUI_IsGroupCreated(0, "fs_u4_grp");
    if (res == 1 && g_u4_fs_destroy_calls == 1 && fsCreated == 0)
    {
        return 1;
    }
    return 0;
}

// -------------------------------------------------------------
// U5: Multi-Player Context Ownership
// -------------------------------------------------------------
forward OnU5_Create(playerid);
public OnU5_Create(playerid) { return 1; }
forward OnU5_Show(playerid);
public OnU5_Show(playerid) { return 1; }
forward OnU5_Hide(playerid);
public OnU5_Hide(playerid) { return 1; }
forward OnU5_Destroy(playerid);
public OnU5_Destroy(playerid) { return 1; }

forward FS_RunU5();
public FS_RunU5()
{
    SUI_CreatePlayerFactoryGroup(0, "fs_p0_grp", "OnU5_Create", "OnU5_Destroy", "OnU5_Show", "OnU5_Hide");
    SUI_SetGroupSize(0, "fs_p0_grp", 2);
    SUI_ShowGroup(0, "fs_p0_grp");

    SUI_CreatePlayerFactoryGroup(1, "fs_p1_grp", "OnU5_Create", "OnU5_Destroy", "OnU5_Show", "OnU5_Hide");
    SUI_SetGroupSize(1, "fs_p1_grp", 3);
    SUI_ShowGroup(1, "fs_p1_grp");

    new res = SUI_CleanupOwnerGroups();

    new p0Created = SUI_IsGroupCreated(0, "fs_p0_grp");
    new p1Created = SUI_IsGroupCreated(1, "fs_p1_grp");
    new p0Count = SUI_GetActiveTextDrawCount(0);
    new p1Count = SUI_GetActiveTextDrawCount(1);

    if (res == 1 && p0Created == 0 && p1Created == 0 && p0Count == 0 && p1Count == 0)
    {
        return 1;
    }
    printf("[FS] U5 FAIL: res=%d p0Created=%d p1Created=%d p0Count=%d p1Count=%d",
        res, p0Created, p1Created, p0Count, p1Count);
    return 0;
}

// -------------------------------------------------------------
// U6: Mutation Reentrancy Rejection & U9 Nested Cleanup Rejection
// -------------------------------------------------------------
forward OnU6_Create(playerid);
public OnU6_Create(playerid) { return 1; }
forward OnU6_Show(playerid);
public OnU6_Show(playerid) { return 1; }
forward OnU6_Hide(playerid);
public OnU6_Hide(playerid) { return 1; }

forward OnU6_Destroy(playerid);
public OnU6_Destroy(playerid)
{
    g_u6_destroy_calls++;

    // Attempt 10 mutating calls during cleanup callback
    new r1 = SUI_ShowGroup(playerid, "u6_grp");
    new r2 = SUI_HideGroup(playerid, "u6_grp");
    new r3 = SUI_DestroyGroup(playerid, "u6_grp");
    new r4 = SUI_CreatePlayerFactoryGroup(playerid, "u6_new", "OnU6_Create", "OnU6_Destroy", "OnU6_Show", "OnU6_Hide");
    new r5 = SUI_SetGroupSize(playerid, "u6_grp", 8);
    new r6 = SUI_SetIdleTimeout(playerid, "u6_grp", 10);
    new r7 = SUI_SetGroupPriority(playerid, "u6_grp", 2);
    new r8 = SUI_SetGroupEvictable(playerid, "u6_grp", false);
    new r9 = SUI_TouchGroup(playerid, "u6_grp");
    new r10 = SUI_CleanupOwnerGroups(); // U9: Nested cleanup attempt

    if (r10 == 0)
    {
        g_u9_nested_rejected = 1;
    }

    if (r1 == 0 && r2 == 0 && r3 == 0 && r4 == 0 && r5 == 0 &&
        r6 == 0 && r7 == 0 && r8 == 0 && r9 == 0 && r10 == 0)
    {
        g_u6_reentrancy_all_rejected = 1;
    }
    else
    {
        printf("[FS] U6 Reentrancy Leak: r1=%d r2=%d r3=%d r4=%d r5=%d r6=%d r7=%d r8=%d r9=%d r10=%d",
            r1, r2, r3, r4, r5, r6, r7, r8, r9, r10);
    }
    return 1;
}

forward FS_RunU6();
public FS_RunU6()
{
    g_u6_destroy_calls = 0;
    g_u6_reentrancy_all_rejected = 0;
    g_u9_nested_rejected = 0;

    SUI_CreatePlayerFactoryGroup(0, "u6_grp", "OnU6_Create", "OnU6_Destroy", "OnU6_Show", "OnU6_Hide");
    SUI_SetGroupSize(0, "u6_grp", 4);
    SUI_ShowGroup(0, "u6_grp");

    new res = SUI_CleanupOwnerGroups();
    new isCreated = SUI_IsGroupCreated(0, "u6_grp");

    if (res == 1 && g_u6_destroy_calls == 1 && g_u6_reentrancy_all_rejected == 1 && isCreated == 0)
    {
        return 1;
    }
    printf("[FS] U6 FAIL: res=%d destroyCalls=%d allRejected=%d isCreated=%d",
        res, g_u6_destroy_calls, g_u6_reentrancy_all_rejected, isCreated);
    return 0;
}

forward FS_GetU9Result();
public FS_GetU9Result()
{
    return g_u9_nested_rejected;
}

// -------------------------------------------------------------
// U7: Callback Failure Semantics
// -------------------------------------------------------------
forward OnU7_Create(playerid);
public OnU7_Create(playerid) { return 1; }
forward OnU7_Show(playerid);
public OnU7_Show(playerid) { return 1; }
forward OnU7_Hide(playerid);
public OnU7_Hide(playerid) { return 1; }

forward FS_RunU7();
public FS_RunU7()
{
    // Register group with NON-EXISTENT cbDestroy
    SUI_CreatePlayerFactoryGroup(0, "u7_grp", "OnU7_Create", "NonExistentCb_U7", "OnU7_Show", "OnU7_Hide");
    SUI_SetGroupSize(0, "u7_grp", 6);
    SUI_ShowGroup(0, "u7_grp");

    new countBefore = SUI_GetActiveTextDrawCount(0);
    new res = SUI_CleanupOwnerGroups();

    new countAfter = SUI_GetActiveTextDrawCount(0);
    new isCreated = SUI_IsGroupCreated(0, "u7_grp");
    new reReg = SUI_CreatePlayerFactoryGroup(0, "u7_grp", "OnU7_Create", "OnU7_Hide", "OnU7_Show", "OnU7_Hide");
    SUI_CleanupOwnerGroups();

    if (res == 0 && isCreated == 0 && countAfter == (countBefore - 6) && reReg == 1)
    {
        return 1;
    }
    printf("[FS] U7 FAIL: res=%d (expected 0) isCreated=%d countDelta=%d reReg=%d",
        res, isCreated, countBefore - countAfter, reReg);
    return 0;
}

// -------------------------------------------------------------
// U10: Zero Owned Groups
// -------------------------------------------------------------
forward FS_RunU10();
public FS_RunU10()
{
    // Calling AMX has 0 owned groups right now
    new res = SUI_CleanupOwnerGroups();
    return (res == 1) ? 1 : 0;
}

// -------------------------------------------------------------
// U11: Cross-AMX Reentrant Target Guard
// -------------------------------------------------------------
forward OnU11_Create(playerid);
public OnU11_Create(playerid) { return 1; }
forward OnU11_Show(playerid);
public OnU11_Show(playerid) { return 1; }
forward OnU11_Hide(playerid);
public OnU11_Hide(playerid) { return 1; }

forward OnU11_Destroy(playerid);
public OnU11_Destroy(playerid)
{
    g_u11_destroy_calls++;
    // Synchronously invoke Gamemode (AMX B) to attempt mutating this group
    CallRemoteFunction("GM_TryMutateA_Group", "d", playerid);
    return 1;
}

forward FS_RunU11();
public FS_RunU11()
{
    g_u11_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "u11_grp", "OnU11_Create", "OnU11_Destroy", "OnU11_Show", "OnU11_Hide");
    SUI_SetGroupSize(0, "u11_grp", 4);
    SUI_ShowGroup(0, "u11_grp");

    new res = SUI_CleanupOwnerGroups();
    new isCreated = SUI_IsGroupCreated(0, "u11_grp");

    if (res == 1 && g_u11_destroy_calls == 1 && isCreated == 0)
    {
        return 1;
    }
    return 0;
}

// -------------------------------------------------------------
// U12: Player-Teardown Collision Guard
// -------------------------------------------------------------
forward OnU12_Create(playerid);
public OnU12_Create(playerid) { return 1; }
forward OnU12_Show(playerid);
public OnU12_Show(playerid) { return 1; }
forward OnU12_Hide(playerid);
public OnU12_Hide(playerid) { return 1; }

forward OnU12_Destroy(playerid);
public OnU12_Destroy(playerid)
{
    g_u12_destroy_calls++;
    // Synchronously invoke Gamemode (AMX B) to attempt teardown on playerid
    CallRemoteFunction("GM_TryPlayerTeardown", "d", playerid);
    return 1;
}

forward FS_RunU12();
public FS_RunU12()
{
    g_u12_destroy_calls = 0;
    SUI_CreatePlayerFactoryGroup(0, "u12_grp", "OnU12_Create", "OnU12_Destroy", "OnU12_Show", "OnU12_Hide");
    SUI_SetGroupSize(0, "u12_grp", 4);
    SUI_ShowGroup(0, "u12_grp");

    new res = SUI_CleanupOwnerGroups();
    new isCreated = SUI_IsGroupCreated(0, "u12_grp");

    if (res == 1 && g_u12_destroy_calls == 1 && isCreated == 0)
    {
        return 1;
    }
    return 0;
}

// -------------------------------------------------------------
// U13: Hide Failure with Destroy Still Attempted
// -------------------------------------------------------------
forward OnU13_Create(playerid);
public OnU13_Create(playerid) { return 1; }
forward OnU13_Show(playerid);
public OnU13_Show(playerid) { return 1; }

forward OnU13_Destroy(playerid);
public OnU13_Destroy(playerid)
{
    g_u13_destroy_calls++;
    return 1;
}

forward FS_RunU13();
public FS_RunU13()
{
    g_u13_destroy_calls = 0;
    // Missing cbHide ("NonExistent_U13_Hide"), valid cbDestroy ("OnU13_Destroy")
    SUI_CreatePlayerFactoryGroup(0, "u13_grp", "OnU13_Create", "OnU13_Destroy", "OnU13_Show", "NonExistent_U13_Hide");
    SUI_SetGroupSize(0, "u13_grp", 5);
    SUI_ShowGroup(0, "u13_grp");

    new countBefore = SUI_GetActiveTextDrawCount(0);
    new res = SUI_CleanupOwnerGroups();

    new countAfter = SUI_GetActiveTextDrawCount(0);
    new isCreated = SUI_IsGroupCreated(0, "u13_grp");

    if (res == 0 && g_u13_destroy_calls == 1 && isCreated == 0 && countAfter == (countBefore - 5))
    {
        return 1;
    }
    printf("[FS] U13 FAIL: res=%d cbDestroy=%d isCreated=%d countDelta=%d",
        res, g_u13_destroy_calls, isCreated, countBefore - countAfter);
    return 0;
}

// -------------------------------------------------------------
// U8: Real Connected NPC & PlayerTextDraw Allocation / Destruction
// -------------------------------------------------------------
forward OnU8_Create(playerid);
public OnU8_Create(playerid)
{
    g_u8_ptd_count = 0;
    g_u8_first_ptd_id = -1;
    for (new i = 0; i < 5; i++)
    {
        new PlayerText:ptd = CreatePlayerTextDraw(playerid, 100.0, 100.0 + (float(i) * 10.0), "U8_PTD");
        if (_:ptd != 0xFFFF && _:ptd != -1)
        {
            if (g_u8_first_ptd_id == -1)
            {
                g_u8_first_ptd_id = _:ptd;
            }
            g_u8_ptds[g_u8_ptd_count++] = ptd;
        }
    }
    printf("[FS] OnU8_Create: allocated %d PTDs, firstId=%d for playerid=%d",
        g_u8_ptd_count, g_u8_first_ptd_id, playerid);
    return 1;
}

forward OnU8_Show(playerid);
public OnU8_Show(playerid)
{
    for (new i = 0; i < g_u8_ptd_count; i++)
    {
        PlayerTextDrawShow(playerid, g_u8_ptds[i]);
    }
    return 1;
}

forward OnU8_Hide(playerid);
public OnU8_Hide(playerid)
{
    for (new i = 0; i < g_u8_ptd_count; i++)
    {
        PlayerTextDrawHide(playerid, g_u8_ptds[i]);
    }
    return 1;
}

forward OnU8_Destroy(playerid);
public OnU8_Destroy(playerid)
{
    printf("[FS] OnU8_Destroy: destroying %d PTDs for playerid=%d", g_u8_ptd_count, playerid);
    for (new i = 0; i < g_u8_ptd_count; i++)
    {
        if (g_u8_ptds[i] != PlayerText:INVALID_TEXT_DRAW)
        {
            PlayerTextDrawDestroy(playerid, g_u8_ptds[i]);
            g_u8_ptds[i] = PlayerText:INVALID_TEXT_DRAW;
        }
    }
    g_u8_ptd_count = 0;
    return 1;
}

forward FS_AllocateU8_PTDs(npcid);
public FS_AllocateU8_PTDs(npcid)
{
    SUI_CreatePlayerFactoryGroup(npcid, "u8_pawn_grp", "OnU8_Create", "OnU8_Destroy", "OnU8_Show", "OnU8_Hide");
    SUI_SetGroupSize(npcid, "u8_pawn_grp", 5);
    SUI_ShowGroup(npcid, "u8_pawn_grp");
    return g_u8_first_ptd_id;
}

forward FS_GetU14Result();
public FS_GetU14Result()
{
    return g_u14_read_only_success;
}
