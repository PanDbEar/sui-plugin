#include "Natives.hpp"
#include "Core.hpp"
#include "Utils.hpp"

extern void (*logprintf)(const char* format, ...);

cell AMX_NATIVE_CALL Natives::SUI_SetDebug(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 1)) return 0;

    SUICore::SetDebug(static_cast<bool>(params[1]));
    return 1;
}

cell AMX_NATIVE_CALL Natives::SUI_CreatePlayerFactoryGroup(AMX* amx, cell* params) {
    if (!Utils::CheckParams(params, 6)) return 0;
    
    int playerId = params[1];
    SUICore::RegisterFactoryGroup(
        playerId, 
        Utils::GetStringParam(amx, params[2]), 
        Utils::GetStringParam(amx, params[3]), 
        Utils::GetStringParam(amx, params[4]), 
        Utils::GetStringParam(amx, params[5]), 
        Utils::GetStringParam(amx, params[6])
    );
    return 1;
}

cell AMX_NATIVE_CALL Natives::SUI_ShowGroup(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 2)) {
        SUICore::Debug("[SUI-DEBUG] SUI_ShowGroup invalid params");
        return 0;
    }

    int playerId = params[1];
    std::string group = Utils::GetStringParam(amx, params[2]);

    SUICore::Debug("[SUI-DEBUG] Native SUI_ShowGroup called. playerid=%d group=%s", playerId, group.c_str());

    SUICore::ShowGroup(playerId, group);
    return 1;
}

cell AMX_NATIVE_CALL Natives::SUI_HideGroup(AMX* amx, cell* params) {
    if (!Utils::CheckParams(params, 2)) return 0;
    SUICore::HideGroup(params[1], Utils::GetStringParam(amx, params[2]));
    return 1;
}

cell AMX_NATIVE_CALL Natives::SUI_SetIdleTimeout(AMX* amx, cell* params) {
    if (!Utils::CheckParams(params, 3)) return 0;
    SUICore::SetIdleTimeout(params[1], Utils::GetStringParam(amx, params[2]), params[3]);
    return 1;
}

cell AMX_NATIVE_CALL Natives::SUI_CleanupPlayer(AMX* amx, cell* params) {
    if (!Utils::CheckParams(params, 1)) return 0;
    SUICore::CleanupPlayer(params[1]);
    return 1;
}

cell AMX_NATIVE_CALL Natives::SUI_ResetPlayer(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 1)) return 0;

    int playerId = params[1];

    SUICore::ResetPlayer(playerId);
    return 1;
}

cell AMX_NATIVE_CALL Natives::SUI_SetGroupSize(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 3)) return 0;

    int playerId = params[1];
    std::string group = Utils::GetStringParam(amx, params[2]);
    uint32_t size = static_cast<uint32_t>(params[3]);

    SUICore::SetGroupSize(playerId, group, size);
    return 1;
}

cell AMX_NATIVE_CALL Natives::SUI_GetActiveTextDrawCount(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 1)) return 0;

    int playerId = params[1];
    return static_cast<cell>(SUICore::GetActiveTextDrawCount(playerId));
}

cell AMX_NATIVE_CALL Natives::SUI_SetMaxTextDraws(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 2)) return 0;

    int playerId = params[1];
    uint32_t maxCount = static_cast<uint32_t>(params[2]);

    SUICore::SetMaxTextDraws(playerId, maxCount);
    return 1;
}

cell AMX_NATIVE_CALL Natives::SUI_SetEvictionThreshold(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 2)) return 0;

    int playerId = params[1];
    uint32_t threshold = static_cast<uint32_t>(params[2]);

    SUICore::SetEvictionThreshold(playerId, threshold);
    return 1;
}

cell AMX_NATIVE_CALL Natives::SUI_SetGroupPriority(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 3)) return 0;

    int playerId = params[1];
    std::string group = Utils::GetStringParam(amx, params[2]);
    uint8_t priority = static_cast<uint8_t>(params[3]);

    SUICore::SetGroupPriority(playerId, group, priority);
    return 1;
}

cell AMX_NATIVE_CALL Natives::SUI_DestroyGroup(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 2)) return 0;

    int playerId = params[1];
    std::string group = Utils::GetStringParam(amx, params[2]);

    return SUICore::DestroyGroup(playerId, group) ? 1 : 0;
}

cell AMX_NATIVE_CALL Natives::SUI_IsGroupCreated(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 2)) return 0;

    int playerId = params[1];
    std::string group = Utils::GetStringParam(amx, params[2]);

    return SUICore::IsGroupCreated(playerId, group) ? 1 : 0;
}

cell AMX_NATIVE_CALL Natives::SUI_IsGroupVisible(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 2)) return 0;

    int playerId = params[1];
    std::string group = Utils::GetStringParam(amx, params[2]);

    return SUICore::IsGroupVisible(playerId, group) ? 1 : 0;
}

cell AMX_NATIVE_CALL Natives::SUI_PrintPlayerState(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 1)) return 0;

    int playerId = params[1];

    SUICore::PrintPlayerState(playerId);
    return 1;
}

cell AMX_NATIVE_CALL Natives::SUI_SetGroupEvictable(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 3)) return 0;

    int playerId = params[1];
    std::string group = Utils::GetStringParam(amx, params[2]);
    bool enabled = static_cast<bool>(params[3]);

    SUICore::SetGroupEvictable(playerId, group, enabled);
    return 1;
}

cell AMX_NATIVE_CALL Natives::SUI_IsGroupEvictable(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 2)) return 0;

    int playerId = params[1];
    std::string group = Utils::GetStringParam(amx, params[2]);

    return SUICore::IsGroupEvictable(playerId, group) ? 1 : 0;
}

cell AMX_NATIVE_CALL Natives::SUI_TouchGroup(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 2)) return 0;

    int playerId = params[1];
    std::string group = Utils::GetStringParam(amx, params[2]);

    return SUICore::TouchGroup(playerId, group) ? 1 : 0;
}