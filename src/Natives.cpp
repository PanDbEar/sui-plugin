#include "Natives.hpp"
#include "Core.hpp"
#include "Utils.hpp"

extern void (*logprintf)(const char* format, ...);

cell AMX_NATIVE_CALL Natives::SUI_SetDebug(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 1)) return 0;

    SUICore::SetDebug(params[1] != 0);
    return 1;
}

cell AMX_NATIVE_CALL Natives::SUI_CreatePlayerFactoryGroup(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 6)) return 0;

    int playerId = params[1];
    std::string group, cbCreate, cbDestroy, cbShow, cbHide;

    if (!Utils::TryGetStringParam(amx, params[2], group) ||
        !Utils::TryGetStringParam(amx, params[3], cbCreate) ||
        !Utils::TryGetStringParam(amx, params[4], cbDestroy) ||
        !Utils::TryGetStringParam(amx, params[5], cbShow) ||
        !Utils::TryGetStringParam(amx, params[6], cbHide))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_CreatePlayerFactoryGroup failed to extract string parameter(s)");
        return 0;
    }

    bool ok = SUICore::RegisterFactoryGroup(amx, playerId, group, cbCreate, cbDestroy, cbShow, cbHide);
    return ok ? 1 : 0;
}

cell AMX_NATIVE_CALL Natives::SUI_ShowGroup(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 2)) {
        SUICore::Debug("[SUI-DEBUG] SUI_ShowGroup invalid params");
        return 0;
    }

    int playerId = params[1];
    std::string group;
    if (!Utils::TryGetStringParam(amx, params[2], group))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_ShowGroup failed to extract group string");
        return 0;
    }

    SUICore::Debug("[SUI-DEBUG] Native SUI_ShowGroup called. playerid=%d group=%s", playerId, group.c_str());

    SUICore::ShowGroup(playerId, group);
    return 1;
}

cell AMX_NATIVE_CALL Natives::SUI_HideGroup(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 2)) return 0;

    int playerId = params[1];
    std::string group;
    if (!Utils::TryGetStringParam(amx, params[2], group))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_HideGroup failed to extract group string");
        return 0;
    }

    SUICore::HideGroup(playerId, group);
    return 1;
}

cell AMX_NATIVE_CALL Natives::SUI_SetIdleTimeout(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 3)) return 0;

    int playerId = params[1];
    std::string group;
    if (!Utils::TryGetStringParam(amx, params[2], group))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_SetIdleTimeout failed to extract group string");
        return 0;
    }

    uint32_t timeoutMs = 0;
    if (!Utils::TryGetNonNegativeUInt32(params[3], timeoutMs))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_SetIdleTimeout rejected negative timeout=%d", params[3]);
        return 0;
    }

    SUICore::SetIdleTimeout(playerId, group, timeoutMs);
    return 1;
}

cell AMX_NATIVE_CALL Natives::SUI_CleanupPlayer(AMX* amx, cell* params)
{
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
    std::string group;
    if (!Utils::TryGetStringParam(amx, params[2], group))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_SetGroupSize failed to extract group string");
        return 0;
    }

    uint32_t size = 0;
    if (!Utils::TryGetNonNegativeUInt32(params[3], size))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_SetGroupSize rejected negative size=%d", params[3]);
        return 0;
    }

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
    uint32_t maxCount = 0;
    if (!Utils::TryGetNonNegativeUInt32(params[2], maxCount))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_SetMaxTextDraws rejected negative maxCount=%d", params[2]);
        return 0;
    }

    SUICore::SetMaxTextDraws(playerId, maxCount);
    return 1;
}

cell AMX_NATIVE_CALL Natives::SUI_SetEvictionThreshold(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 2)) return 0;

    int playerId = params[1];
    uint32_t threshold = 0;
    if (!Utils::TryGetNonNegativeUInt32(params[2], threshold))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_SetEvictionThreshold rejected negative threshold=%d", params[2]);
        return 0;
    }

    SUICore::SetEvictionThreshold(playerId, threshold);
    return 1;
}

cell AMX_NATIVE_CALL Natives::SUI_SetGroupPriority(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 3)) return 0;

    int playerId = params[1];
    std::string group;
    if (!Utils::TryGetStringParam(amx, params[2], group))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_SetGroupPriority failed to extract group string");
        return 0;
    }

    uint8_t priority = 0;
    if (!Utils::TryGetPriority(params[3], priority))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_SetGroupPriority rejected invalid priority=%d", params[3]);
        return 0;
    }

    SUICore::SetGroupPriority(playerId, group, priority);
    return 1;
}

cell AMX_NATIVE_CALL Natives::SUI_DestroyGroup(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 2)) return 0;

    int playerId = params[1];
    std::string group;
    if (!Utils::TryGetStringParam(amx, params[2], group))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_DestroyGroup failed to extract group string");
        return 0;
    }

    return SUICore::DestroyGroup(playerId, group) ? 1 : 0;
}

cell AMX_NATIVE_CALL Natives::SUI_IsGroupCreated(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 2)) return 0;

    int playerId = params[1];
    std::string group;
    if (!Utils::TryGetStringParam(amx, params[2], group))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_IsGroupCreated failed to extract group string");
        return 0;
    }

    return SUICore::IsGroupCreated(playerId, group) ? 1 : 0;
}

cell AMX_NATIVE_CALL Natives::SUI_IsGroupVisible(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 2)) return 0;

    int playerId = params[1];
    std::string group;
    if (!Utils::TryGetStringParam(amx, params[2], group))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_IsGroupVisible failed to extract group string");
        return 0;
    }

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
    std::string group;
    if (!Utils::TryGetStringParam(amx, params[2], group))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_SetGroupEvictable failed to extract group string");
        return 0;
    }

    bool enabled = (params[3] != 0);

    SUICore::SetGroupEvictable(playerId, group, enabled);
    return 1;
}

cell AMX_NATIVE_CALL Natives::SUI_IsGroupEvictable(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 2)) return 0;

    int playerId = params[1];
    std::string group;
    if (!Utils::TryGetStringParam(amx, params[2], group))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_IsGroupEvictable failed to extract group string");
        return 0;
    }

    return SUICore::IsGroupEvictable(playerId, group) ? 1 : 0;
}

cell AMX_NATIVE_CALL Natives::SUI_TouchGroup(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 2)) return 0;

    int playerId = params[1];
    std::string group;
    if (!Utils::TryGetStringParam(amx, params[2], group))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_TouchGroup failed to extract group string");
        return 0;
    }

    return SUICore::TouchGroup(playerId, group) ? 1 : 0;
}