#define FILTERSCRIPT
#include <a_samp>
#include <sui>

new g_fs_id7_create_calls = 0;
new g_fs_id7_destroy_calls = 0;
new g_fs_id7_show_calls = 0;
new g_fs_id7_hide_calls = 0;

public OnFilterScriptInit()
{
    print("[FS-IDENTITY] SUI-017 Group Identity Filterscript loaded.");
    return 1;
}

public OnFilterScriptExit()
{
    print("[FS-IDENTITY] SUI-017 Group Identity Filterscript unloaded.");
    return 1;
}

forward FS_SetupID7(playerid);
public FS_SetupID7(playerid)
{
    g_fs_id7_create_calls = 0;
    g_fs_id7_destroy_calls = 0;
    g_fs_id7_show_calls = 0;
    g_fs_id7_hide_calls = 0;

    new res = SUI_CreatePlayerFactoryGroup(
        playerid,
        "id7_fs",
        "FS_OnID7_Create",
        "FS_OnID7_Destroy",
        "FS_OnID7_Show",
        "FS_OnID7_Hide"
    );
    SUI_SetGroupSize(playerid, "id7_fs", 5);
    return res;
}

forward FS_GetDestroyCalls();
public FS_GetDestroyCalls()
{
    return g_fs_id7_destroy_calls;
}

forward FS_OnID7_Create(playerid);
public FS_OnID7_Create(playerid)
{
    g_fs_id7_create_calls++;
    return 1;
}

forward FS_OnID7_Show(playerid);
public FS_OnID7_Show(playerid)
{
    g_fs_id7_show_calls++;
    return 1;
}

forward FS_OnID7_Hide(playerid);
public FS_OnID7_Hide(playerid)
{
    g_fs_id7_hide_calls++;
    return 1;
}

forward FS_OnID7_Destroy(playerid);
public FS_OnID7_Destroy(playerid)
{
    g_fs_id7_destroy_calls++;

    // During FS destroy callback, reset player and trigger Gamemode to register same name
    SUI_ResetPlayer(playerid);
    CallRemoteFunction("GM_RegisterID7", "d", playerid);

    return 1;
}

new g_fs_cross_create_calls = 0;
new g_fs_cross_show_calls = 0;

forward FS_SetupCrossAmx(playerid);
public FS_SetupCrossAmx(playerid)
{
    g_fs_cross_create_calls = 0;
    g_fs_cross_show_calls = 0;

    new res = SUI_CreatePlayerFactoryGroup(
        playerid,
        "cross_amx_grp",
        "FS_OnCross_Create",
        "FS_OnCross_Destroy",
        "FS_OnCross_Show",
        "FS_OnCross_Hide"
    );
    SUI_SetGroupSize(playerid, "cross_amx_grp", 8);
    return res;
}

forward FS_OnCross_Create(playerid);
public FS_OnCross_Create(playerid) { g_fs_cross_create_calls++; return 1; }

forward FS_OnCross_Show(playerid);
public FS_OnCross_Show(playerid) { g_fs_cross_show_calls++; return 1; }

forward FS_OnCross_Hide(playerid);
public FS_OnCross_Hide(playerid) { return 1; }

forward FS_OnCross_Destroy(playerid);
public FS_OnCross_Destroy(playerid) { return 1; }

forward FS_GetCrossCreateCalls();
public FS_GetCrossCreateCalls() { return g_fs_cross_create_calls; }

forward FS_GetCrossShowCalls();
public FS_GetCrossShowCalls() { return g_fs_cross_show_calls; }

// -------------------------------------------------------------
// O1: Callback-Window Anti-Hijack
// -------------------------------------------------------------
new g_fs_o1_hijack_result = -1;
new g_fs_o1_create_calls = 0;
new g_fs_o1_show_calls = 0;

forward FS_TryHijackO1(playerid);
public FS_TryHijackO1(playerid)
{
    g_fs_o1_create_calls = 0;
    g_fs_o1_show_calls = 0;
    g_fs_o1_hijack_result = SUI_CreatePlayerFactoryGroup(
        playerid,
        "owner_lock",
        "FS_OnO1_Create",
        "FS_OnO1_Destroy",
        "FS_OnO1_Show",
        "FS_OnO1_Hide"
    );
    printf("[FS] FS_TryHijackO1 playerid=%d result=%d", playerid, g_fs_o1_hijack_result);
    return g_fs_o1_hijack_result;
}

forward FS_GetO1HijackResult();
public FS_GetO1HijackResult() { return g_fs_o1_hijack_result; }

forward FS_GetO1CreateCalls();
public FS_GetO1CreateCalls() { return g_fs_o1_create_calls; }

forward FS_GetO1ShowCalls();
public FS_GetO1ShowCalls() { return g_fs_o1_show_calls; }

forward FS_OnO1_Create(playerid);
public FS_OnO1_Create(playerid) { g_fs_o1_create_calls++; return 1; }
forward FS_OnO1_Destroy(playerid);
public FS_OnO1_Destroy(playerid) { return 1; }
forward FS_OnO1_Show(playerid);
public FS_OnO1_Show(playerid) { g_fs_o1_show_calls++; return 1; }
forward FS_OnO1_Hide(playerid);
public FS_OnO1_Hide(playerid) { return 1; }

// -------------------------------------------------------------
// O2: Legitimate Cross-AMX Reuse After Removal
// -------------------------------------------------------------
new g_fs_o2_create_calls = 0;
new g_fs_o2_show_calls = 0;

forward FS_SetupReuseO2(playerid);
public FS_SetupReuseO2(playerid)
{
    g_fs_o2_create_calls = 0;
    g_fs_o2_show_calls = 0;
    new res = SUI_CreatePlayerFactoryGroup(
        playerid,
        "owner_reuse",
        "FS_OnO2_Create",
        "FS_OnO2_Destroy",
        "FS_OnO2_Show",
        "FS_OnO2_Hide"
    );
    SUI_SetGroupSize(playerid, "owner_reuse", 8);
    printf("[FS] FS_SetupReuseO2 playerid=%d result=%d", playerid, res);
    return res;
}

forward FS_ShowReuseO2(playerid);
public FS_ShowReuseO2(playerid)
{
    return SUI_ShowGroup(playerid, "owner_reuse");
}

forward FS_DestroyReuseO2(playerid);
public FS_DestroyReuseO2(playerid)
{
    return SUI_DestroyGroup(playerid, "owner_reuse");
}

forward FS_GetO2CreateCalls();
public FS_GetO2CreateCalls() { return g_fs_o2_create_calls; }

forward FS_GetO2ShowCalls();
public FS_GetO2ShowCalls() { return g_fs_o2_show_calls; }

forward FS_OnO2_Create(playerid);
public FS_OnO2_Create(playerid) { g_fs_o2_create_calls++; return 1; }
forward FS_OnO2_Destroy(playerid);
public FS_OnO2_Destroy(playerid) { return 1; }
forward FS_OnO2_Show(playerid);
public FS_OnO2_Show(playerid) { g_fs_o2_show_calls++; return 1; }
forward FS_OnO2_Hide(playerid);
public FS_OnO2_Hide(playerid) { return 1; }

// -------------------------------------------------------------
// RAG2: Cross-AMX Hijack During Callback
// -------------------------------------------------------------
new g_fs_rag2_hijack_result = -1;

forward FS_TryHijackRAG2(playerid);
public FS_TryHijackRAG2(playerid)
{
    g_fs_rag2_hijack_result = SUI_CreatePlayerFactoryGroup(
        playerid,
        "rag2_grp",
        "FS_OnRAG2_Create",
        "FS_OnRAG2_Destroy",
        "FS_OnRAG2_Show",
        "FS_OnRAG2_Hide"
    );
    printf("[FS] FS_TryHijackRAG2 playerid=%d result=%d", playerid, g_fs_rag2_hijack_result);
    return g_fs_rag2_hijack_result;
}

forward FS_GetRAG2HijackResult();
public FS_GetRAG2HijackResult() { return g_fs_rag2_hijack_result; }

forward FS_OnRAG2_Create(playerid);
public FS_OnRAG2_Create(playerid) { return 1; }
forward FS_OnRAG2_Destroy(playerid);
public FS_OnRAG2_Destroy(playerid) { return 1; }
forward FS_OnRAG2_Show(playerid);
public FS_OnRAG2_Show(playerid) { return 1; }
forward FS_OnRAG2_Hide(playerid);
public FS_OnRAG2_Hide(playerid) { return 1; }


