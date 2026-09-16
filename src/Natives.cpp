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

    if (SUICore::IsOwnerCleanupActive(amx))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_CreatePlayerFactoryGroup rejected: caller amx=%p is in active owner cleanup", amx);
        return 0;
    }

    int playerId = 0;
    if (!Utils::TryGetPlayerId(params[1], playerId))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_CreatePlayerFactoryGroup rejected invalid playerId=%d", params[1]);
        return 0;
    }

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

    if (SUICore::IsOwnerCleanupActive(amx))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_ShowGroup rejected: caller amx=%p is in active owner cleanup", amx);
        return 0;
    }

    int playerId = 0;
    if (!Utils::TryGetPlayerId(params[1], playerId))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_ShowGroup rejected invalid playerId=%d", params[1]);
        return 0;
    }

    std::string group;
    if (!Utils::TryGetStringParam(amx, params[2], group))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_ShowGroup failed to extract group string");
        return 0;
    }

    SUICore::Debug("[SUI-DEBUG] Native SUI_ShowGroup called. playerid=%d group=%s", playerId, group.c_str());

    bool ok = SUICore::ShowGroup(playerId, group);
    return ok ? 1 : 0;
}

cell AMX_NATIVE_CALL Natives::SUI_HideGroup(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 2)) return 0;

    if (SUICore::IsOwnerCleanupActive(amx))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_HideGroup rejected: caller amx=%p is in active owner cleanup", amx);
        return 0;
    }

    int playerId = 0;
    if (!Utils::TryGetPlayerId(params[1], playerId))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_HideGroup rejected invalid playerId=%d", params[1]);
        return 0;
    }

    std::string group;
    if (!Utils::TryGetStringParam(amx, params[2], group))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_HideGroup failed to extract group string");
        return 0;
    }

    bool ok = SUICore::HideGroup(playerId, group);
    return ok ? 1 : 0;
}

cell AMX_NATIVE_CALL Natives::SUI_SetIdleTimeout(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 3)) return 0;

    if (SUICore::IsOwnerCleanupActive(amx))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_SetIdleTimeout rejected: caller amx=%p is in active owner cleanup", amx);
        return 0;
    }

    int playerId = 0;
    if (!Utils::TryGetPlayerId(params[1], playerId))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_SetIdleTimeout rejected invalid playerId=%d", params[1]);
        return 0;
    }

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

    if (SUICore::IsOwnerCleanupActive(amx))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_CleanupPlayer rejected: caller amx=%p is in active owner cleanup", amx);
        return 0;
    }

    int playerId = 0;
    if (!Utils::TryGetPlayerId(params[1], playerId))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_CleanupPlayer rejected invalid playerId=%d", params[1]);
        return 0;
    }

    return SUICore::CleanupPlayer(playerId) ? 1 : 0;
}

cell AMX_NATIVE_CALL Natives::SUI_ResetPlayer(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 1)) return 0;

    if (SUICore::IsOwnerCleanupActive(amx))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_ResetPlayer rejected: caller amx=%p is in active owner cleanup", amx);
        return 0;
    }

    int playerId = 0;
    if (!Utils::TryGetPlayerId(params[1], playerId))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_ResetPlayer rejected invalid playerId=%d", params[1]);
        return 0;
    }

    return SUICore::ResetPlayer(playerId) ? 1 : 0;
}

cell AMX_NATIVE_CALL Natives::SUI_SetGroupSize(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 3)) return 0;

    if (SUICore::IsOwnerCleanupActive(amx))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_SetGroupSize rejected: caller amx=%p is in active owner cleanup", amx);
        return 0;
    }

    int playerId = 0;
    if (!Utils::TryGetPlayerId(params[1], playerId))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_SetGroupSize rejected invalid playerId=%d", params[1]);
        return 0;
    }

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

    return SUICore::SetGroupSize(playerId, group, size) ? 1 : 0;
}

cell AMX_NATIVE_CALL Natives::SUI_GetActiveTextDrawCount(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 1)) return 0;

    int playerId = 0;
    if (!Utils::TryGetPlayerId(params[1], playerId))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_GetActiveTextDrawCount rejected invalid playerId=%d", params[1]);
        return 0;
    }

    return static_cast<cell>(SUICore::GetActiveTextDrawCount(playerId));
}

cell AMX_NATIVE_CALL Natives::SUI_SetMaxTextDraws(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 2)) return 0;

    if (SUICore::IsOwnerCleanupActive(amx))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_SetMaxTextDraws rejected: caller amx=%p is in active owner cleanup", amx);
        return 0;
    }

    int playerId = 0;
    if (!Utils::TryGetPlayerId(params[1], playerId))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_SetMaxTextDraws rejected invalid playerId=%d", params[1]);
        return 0;
    }

    uint32_t maxCount = 0;
    if (!Utils::TryGetNonNegativeUInt32(params[2], maxCount))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_SetMaxTextDraws rejected negative maxCount=%d", params[2]);
        return 0;
    }

    return SUICore::SetMaxTextDraws(playerId, maxCount) ? 1 : 0;
}

cell AMX_NATIVE_CALL Natives::SUI_SetEvictionThreshold(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 2)) return 0;

    if (SUICore::IsOwnerCleanupActive(amx))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_SetEvictionThreshold rejected: caller amx=%p is in active owner cleanup", amx);
        return 0;
    }

    int playerId = 0;
    if (!Utils::TryGetPlayerId(params[1], playerId))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_SetEvictionThreshold rejected invalid playerId=%d", params[1]);
        return 0;
    }

    uint32_t threshold = 0;
    if (!Utils::TryGetNonNegativeUInt32(params[2], threshold))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_SetEvictionThreshold rejected negative threshold=%d", params[2]);
        return 0;
    }

    return SUICore::SetEvictionThreshold(playerId, threshold) ? 1 : 0;
}

cell AMX_NATIVE_CALL Natives::SUI_SetGroupPriority(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 3)) return 0;

    if (SUICore::IsOwnerCleanupActive(amx))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_SetGroupPriority rejected: caller amx=%p is in active owner cleanup", amx);
        return 0;
    }

    int playerId = 0;
    if (!Utils::TryGetPlayerId(params[1], playerId))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_SetGroupPriority rejected invalid playerId=%d", params[1]);
        return 0;
    }

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

    if (SUICore::IsOwnerCleanupActive(amx))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_DestroyGroup rejected: caller amx=%p is in active owner cleanup", amx);
        return 0;
    }

    int playerId = 0;
    if (!Utils::TryGetPlayerId(params[1], playerId))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_DestroyGroup rejected invalid playerId=%d", params[1]);
        return 0;
    }

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

    int playerId = 0;
    if (!Utils::TryGetPlayerId(params[1], playerId))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_IsGroupCreated rejected invalid playerId=%d", params[1]);
        return 0;
    }

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

    int playerId = 0;
    if (!Utils::TryGetPlayerId(params[1], playerId))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_IsGroupVisible rejected invalid playerId=%d", params[1]);
        return 0;
    }

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

    int playerId = 0;
    if (!Utils::TryGetPlayerId(params[1], playerId))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_PrintPlayerState rejected invalid playerId=%d", params[1]);
        return 0;
    }

    SUICore::PrintPlayerState(playerId);
    return 1;
}

cell AMX_NATIVE_CALL Natives::SUI_SetGroupEvictable(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 3)) return 0;

    if (SUICore::IsOwnerCleanupActive(amx))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_SetGroupEvictable rejected: caller amx=%p is in active owner cleanup", amx);
        return 0;
    }

    int playerId = 0;
    if (!Utils::TryGetPlayerId(params[1], playerId))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_SetGroupEvictable rejected invalid playerId=%d", params[1]);
        return 0;
    }

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

    int playerId = 0;
    if (!Utils::TryGetPlayerId(params[1], playerId))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_IsGroupEvictable rejected invalid playerId=%d", params[1]);
        return 0;
    }

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

    if (SUICore::IsOwnerCleanupActive(amx))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_TouchGroup rejected: caller amx=%p is in active owner cleanup", amx);
        return 0;
    }

    int playerId = 0;
    if (!Utils::TryGetPlayerId(params[1], playerId))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_TouchGroup rejected invalid playerId=%d", params[1]);
        return 0;
    }

    std::string group;
    if (!Utils::TryGetStringParam(amx, params[2], group))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_TouchGroup failed to extract group string");
        return 0;
    }

    return SUICore::TouchGroup(playerId, group) ? 1 : 0;
}

cell AMX_NATIVE_CALL Natives::SUI_CleanupOwnerGroups(AMX* amx, cell* params)
{
    if (!Utils::CheckParams(params, 0)) return 0;
    if (!amx) return 0;

    if (SUICore::IsOwnerCleanupActive(amx))
    {
        SUICore::Debug("[SUI-DEBUG] SUI_CleanupOwnerGroups rejected: nested cleanup already active for amx=%p", amx);
        return 0;
    }

    return SUICore::CleanupOwnerGroups(amx) ? 1 : 0;
}