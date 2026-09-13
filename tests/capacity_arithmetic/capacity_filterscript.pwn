#define FILTERSCRIPT
#include <a_samp>
#include <sui>

forward OnFsCap_Create(playerid);
forward OnFsCap_Destroy(playerid);
forward OnFsCap_Show(playerid);
forward OnFsCap_Hide(playerid);

public OnFilterScriptInit()
{
    print("[FS-CAP] Filterscript loaded. Registering and showing fs_cap_grp (size=15)...");
    SUI_CreatePlayerFactoryGroup(0, "fs_cap_grp", "OnFsCap_Create", "OnFsCap_Destroy", "OnFsCap_Show", "OnFsCap_Hide");
    SUI_SetGroupSize(0, "fs_cap_grp", 15);
    SUI_ShowGroup(0, "fs_cap_grp");
    return 1;
}

public OnFilterScriptExit()
{
    print("[FS-CAP] Filterscript exiting.");
    return 1;
}

public OnFsCap_Create(playerid)
{
    print("[FS-CAP] OnFsCap_Create executed.");
    return 1;
}

public OnFsCap_Destroy(playerid)
{
    print("[FS-CAP] OnFsCap_Destroy executed.");
    return 1;
}

public OnFsCap_Show(playerid)
{
    print("[FS-CAP] OnFsCap_Show executed.");
    return 1;
}

public OnFsCap_Hide(playerid)
{
    print("[FS-CAP] OnFsCap_Hide executed.");
    return 1;
}
