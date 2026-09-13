#include "plugincommon.h"
#include "amx/amx.h"
#include "amx/amx2.h"

#include "Core.hpp"
#include "Natives.hpp"
#include "Utils.hpp"

#include <algorithm>

extern void *pAMXFunctions;
void (*logprintf)(const char* format, ...) = nullptr;

AMX_NATIVE_INFO natives[] = {
    {"SUI_CreatePlayerFactoryGroup", Natives::SUI_CreatePlayerFactoryGroup},
    {"SUI_ShowGroup", Natives::SUI_ShowGroup},
    {"SUI_HideGroup", Natives::SUI_HideGroup},
    {"SUI_DestroyGroup", Natives::SUI_DestroyGroup},
    {"SUI_CleanupPlayer", Natives::SUI_CleanupPlayer},
    {"SUI_ResetPlayer", Natives::SUI_ResetPlayer},

    {"SUI_SetDebug", Natives::SUI_SetDebug},
    {"SUI_SetIdleTimeout", Natives::SUI_SetIdleTimeout},

    {"SUI_SetGroupSize", Natives::SUI_SetGroupSize},
    {"SUI_GetActiveTextDrawCount", Natives::SUI_GetActiveTextDrawCount},
    {"SUI_SetMaxTextDraws", Natives::SUI_SetMaxTextDraws},
    {"SUI_SetEvictionThreshold", Natives::SUI_SetEvictionThreshold},
    {"SUI_SetGroupPriority", Natives::SUI_SetGroupPriority},

    {"SUI_IsGroupCreated", Natives::SUI_IsGroupCreated},
    {"SUI_IsGroupVisible", Natives::SUI_IsGroupVisible},
    {"SUI_PrintPlayerState", Natives::SUI_PrintPlayerState},

    {"SUI_SetGroupEvictable", Natives::SUI_SetGroupEvictable},
    {"SUI_IsGroupEvictable", Natives::SUI_IsGroupEvictable},
    {"SUI_TouchGroup", Natives::SUI_TouchGroup},

    {nullptr, nullptr}
};

PLUGIN_EXPORT unsigned int PLUGIN_CALL Supports()
{
    return SUPPORTS_VERSION | SUPPORTS_AMX_NATIVES | SUPPORTS_PROCESS_TICK;
}

PLUGIN_EXPORT bool PLUGIN_CALL Load(void **ppData)
{
    pAMXFunctions = ppData[PLUGIN_DATA_AMX_EXPORTS];
    logprintf = (void (*)(const char*, ...))ppData[PLUGIN_DATA_LOGPRINTF];

    logprintf(" ");
    logprintf("========================================");
    logprintf("Smart UI Virtualizer Loaded");
    logprintf("Mode    : Legacy Factory");
    logprintf("Version : 1.0.0");
    logprintf("Author  : Pandbear");
    logprintf("========================================");
    logprintf(" ");
    return true;
}

PLUGIN_EXPORT void PLUGIN_CALL Unload()
{
    if (logprintf)
    {
        logprintf("[SUI] Smart UI Virtualizer unloaded.");
    }
}

PLUGIN_EXPORT void PLUGIN_CALL ProcessTick()
{
    SUICore::ProcessTick(Utils::GetTickCountMs());
}

PLUGIN_EXPORT int PLUGIN_CALL AmxLoad(AMX *amx)
{
    SUICore::activeAmxInstances.push_back(amx);

    SUICore::Debug("AmxLoad called. Redirecting SUI natives manually.");

    for (int i = 0; natives[i].name != nullptr; i++)
    {
        int index = -1;
        int findResult = amx_FindNative(amx, natives[i].name, &index);

        if (findResult == AMX_ERR_NONE)
        {
            amx_Redirect(
                amx,
                const_cast<char*>(natives[i].name),
                reinterpret_cast<ucell>(natives[i].func),
                nullptr
            );

            SUICore::Debug("Redirected native %s index=%d", natives[i].name, index);
        }
        else
        {
            SUICore::Debug("Native %s not found in AMX table result=%d", natives[i].name, findResult);
        }
    }

    return AMX_ERR_NONE;
}

PLUGIN_EXPORT int PLUGIN_CALL AmxUnload(AMX *amx)
{
    auto& amxList = SUICore::activeAmxInstances;
    amxList.erase(std::remove(amxList.begin(), amxList.end(), amx), amxList.end());

    SUICore::Debug("AmxUnload called. AMX removed.");

    return AMX_ERR_NONE;
}