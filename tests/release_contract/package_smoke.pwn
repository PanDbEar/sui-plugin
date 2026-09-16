#include <a_samp>
#include <sui>

new gCreate;
new gDestroy;
new gShow;
new gHide;

forward SmokeCreate(playerid);
public SmokeCreate(playerid)
{
    gCreate++;
    return 1;
}

forward SmokeDestroy(playerid);
public SmokeDestroy(playerid)
{
    gDestroy++;
    return 1;
}

forward SmokeShow(playerid);
public SmokeShow(playerid)
{
    gShow++;
    return 1;
}

forward SmokeHide(playerid);
public SmokeHide(playerid)
{
    gHide++;
    return 1;
}

main()
{
}

public OnGameModeInit()
{
    print("\n========================================================");
    print(" SUI PACKAGE-ONLY DEPLOYMENT SMOKE TEST (SUI-015)");
    print("========================================================");

    SUI_SetDebug(true);

    new regOk = SUI_RegisterGroup(
        0,
        "package_smoke",
        "SmokeCreate",
        "SmokeDestroy",
        "SmokeShow",
        "SmokeHide",
        1,
        30000,
        SUI_PRIORITY_NORMAL,
        true
    );

    if (!regOk)
    {
        print("[SMOKE-FAIL] SUI_RegisterGroup failed");
        SendRconCommand("exit");
        return 0;
    }

    // After register: created = 0, callbacks = 0
    if (SUI_IsGroupCreated(0, "package_smoke"))
    {
        print("[SMOKE-FAIL] Group is created immediately after register (expected uncreated)");
        SendRconCommand("exit");
        return 0;
    }

    if (gCreate != 0 || gShow != 0 || gHide != 0 || gDestroy != 0)
    {
        printf("[SMOKE-FAIL] Callbacks invoked during registration: c=%d s=%d h=%d d=%d", gCreate, gShow, gHide, gDestroy);
        SendRconCommand("exit");
        return 0;
    }

    // After Show: created = 1, activeTD = 1, createCalls = 1, showCalls = 1
    if (!SUI_ShowGroup(0, "package_smoke"))
    {
        print("[SMOKE-FAIL] SUI_ShowGroup returned 0");
        SendRconCommand("exit");
        return 0;
    }

    if (!SUI_IsGroupCreated(0, "package_smoke"))
    {
        print("[SMOKE-FAIL] Group not created after ShowGroup");
        SendRconCommand("exit");
        return 0;
    }

    new actCount = SUI_GetActiveTextDrawCount(0);
    if (actCount != 1)
    {
        printf("[SMOKE-FAIL] Active textdraw count is %d (expected 1)", actCount);
        SendRconCommand("exit");
        return 0;
    }

    if (gCreate != 1 || gShow != 1)
    {
        printf("[SMOKE-FAIL] Callback counts mismatch after show: create=%d (exp 1), show=%d (exp 1)", gCreate, gShow);
        SendRconCommand("exit");
        return 0;
    }

    // After Hide: hideCalls = 1
    if (!SUI_HideGroup(0, "package_smoke"))
    {
        print("[SMOKE-FAIL] SUI_HideGroup returned 0");
        SendRconCommand("exit");
        return 0;
    }

    if (gHide != 1)
    {
        printf("[SMOKE-FAIL] Hide callback count is %d (expected 1)", gHide);
        SendRconCommand("exit");
        return 0;
    }

    // After Destroy: destroyCalls = 1, activeTD = 0
    if (!SUI_DestroyGroup(0, "package_smoke"))
    {
        print("[SMOKE-FAIL] SUI_DestroyGroup returned 0");
        SendRconCommand("exit");
        return 0;
    }

    if (gDestroy != 1)
    {
        printf("[SMOKE-FAIL] Destroy callback count is %d (expected 1)", gDestroy);
        SendRconCommand("exit");
        return 0;
    }

    new finalAct = SUI_GetActiveTextDrawCount(0);
    if (finalAct != 0)
    {
        printf("[SMOKE-FAIL] Active textdraw count after destroy is %d (expected 0)", finalAct);
        SendRconCommand("exit");
        return 0;
    }

    print("========================================================");
    print(" SUI package deployment smoke test PASS");
    print("========================================================\n");

    SendRconCommand("exit");
    return 1;
}
