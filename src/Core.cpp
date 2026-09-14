#include "Core.hpp"
#include "Utils.hpp"

#include <cstdarg>
#include <cstdio>

extern void (*logprintf)(const char* format, ...);

std::unordered_map<int, PlayerContext> SUICore::players;
std::vector<AMX*> SUICore::activeAmxInstances;
bool SUICore::debugEnabled = false;
uint64_t SUICore::nextGroupInstanceId = 1;

uint64_t SUICore::AllocateGroupInstanceId()
{
    if (nextGroupInstanceId == 0)
    {
        nextGroupInstanceId = 1;
    }
    uint64_t id = nextGroupInstanceId++;
    if (id == 0)
    {
        id = nextGroupInstanceId++;
    }
    return id;
}

void SUICore::SetDebug(bool enabled)
{
    debugEnabled = enabled;

    if (logprintf)
    {
        logprintf("[SUI] Debug mode %s.", enabled ? "enabled" : "disabled");
    }
}

void SUICore::Debug(const char* format, ...)
{
    if (!debugEnabled || !logprintf)
        return;

    char buffer[512];

    va_list args;
    va_start(args, format);
    vsnprintf(buffer, sizeof(buffer), format, args);
    va_end(args);

    logprintf("[SUI-DEBUG] %s", buffer);
}

bool SUICore::IsAmxActive(AMX* amx)
{
    if (!amx)
    {
        return false;
    }

    for (AMX* activeAmx : activeAmxInstances)
    {
        if (activeAmx == amx)
        {
            return true;
        }
    }
    return false;
}

void SUICore::UnloadAmx(AMX* amx)
{
    if (!amx)
    {
        return;
    }

    Debug("UnloadAmx called for amx=%p", amx);

    // 1. Purge all groups owned by this AMX across all players without invoking Pawn callbacks
    for (auto& [playerId, ctx] : players)
    {
        auto itGroup = ctx.groups.begin();
        while (itGroup != ctx.groups.end())
        {
            if (itGroup->second.ownerAmx == amx)
            {
                Debug("UnloadAmx purging group playerid=%d group=%s instance=%llu isCreated=%d size=%u",
                    playerId,
                    itGroup->first.c_str(),
                    static_cast<unsigned long long>(itGroup->second.instanceId),
                    itGroup->second.isCreated ? 1 : 0,
                    itGroup->second.estimatedSize
                );

                if (itGroup->second.isCreated)
                {
                    SubtractActiveTextDrawCount(ctx, itGroup->second.estimatedSize);
                }

                itGroup = ctx.groups.erase(itGroup);
            }
            else
            {
                ++itGroup;
            }
        }
    }

    // 2. Remove amx from activeAmxInstances
    for (auto it = activeAmxInstances.begin(); it != activeAmxInstances.end(); )
    {
        if (*it == amx)
        {
            it = activeAmxInstances.erase(it);
        }
        else
        {
            ++it;
        }
    }

    Debug("UnloadAmx finished for amx=%p, remaining activeAmxInstances=%zu",
        amx, activeAmxInstances.size());
}

PlayerContext* SUICore::GetPlayerContext(int playerId)
{
    auto it = players.find(playerId);
    return (it != players.end()) ? &it->second : nullptr;
}

SUIGroup* SUICore::GetPlayerGroup(int playerId, const std::string& groupName)
{
    auto* ctx = GetPlayerContext(playerId);
    if (!ctx)
        return nullptr;

    auto it = ctx->groups.find(groupName);
    return (it != ctx->groups.end()) ? &it->second : nullptr;
}

SUIGroup* SUICore::GetPlayerGroupIfInstance(int playerId, const std::string& groupName, uint64_t instanceId)
{
    if (instanceId == 0)
    {
        return nullptr;
    }

    auto* group = GetPlayerGroup(playerId, groupName);
    if (!group)
    {
        return nullptr;
    }

    if (group->instanceId != instanceId)
    {
        return nullptr;
    }

    return group;
}

void SUICore::ProcessTick(uint64_t currentTick)
{
    // Snapshot player IDs to prevent iterator invalidation if callbacks modify players map
    std::vector<int> playerIds;
    playerIds.reserve(players.size());
    for (const auto& [playerId, _] : players)
    {
        playerIds.push_back(playerId);
    }

    for (int playerId : playerIds)
    {
        auto* ctx = GetPlayerContext(playerId);
        if (!ctx)
        {
            continue; // Player context was removed during previous callback
        }

        // Snapshot candidate group names and instance IDs for this player
        struct GroupCandidate {
            std::string name;
            uint64_t instanceId;
        };
        std::vector<GroupCandidate> candidateGroups;
        candidateGroups.reserve(ctx->groups.size());
        for (const auto& [groupName, group] : ctx->groups)
        {
            if (!group.isVisible && group.isCreated && !group.isExecutingCallback)
            {
                if ((currentTick - group.hiddenSinceTick) > group.idleTimeoutMs)
                {
                    candidateGroups.push_back({groupName, group.instanceId});
                }
            }
        }

        for (const auto& cand : candidateGroups)
        {
            auto* currentCtx = GetPlayerContext(playerId);
            if (!currentCtx)
            {
                break; // Entire player was removed during callback
            }

            auto* group = GetPlayerGroupIfInstance(playerId, cand.name, cand.instanceId);
            if (!group)
            {
                continue; // Group was destroyed or replaced
            }

            if (group->isVisible || !group->isCreated || group->isExecutingCallback)
            {
                continue;
            }

            if ((currentTick - group->hiddenSinceTick) <= group->idleTimeoutMs)
            {
                continue;
            }

            std::string cbDestroy = group->cbDestroy;
            AMX* ownerAmx = group->ownerAmx;
            uint64_t instanceId = cand.instanceId;
            group->isExecutingCallback = true;

            Debug("Idle destroy triggered playerid=%d group=%s instance=%llu callback=%s",
                playerId,
                cand.name.c_str(),
                static_cast<unsigned long long>(instanceId),
                cbDestroy.c_str()
            );

            // Pawn callbacks may call back into SUI and mutate players/groups.
            // Never retain container references or iterators across this boundary.
            bool destroySuccess = CallPawnFunction(ownerAmx, playerId, cbDestroy);

            // Re-acquire player and group state using stable identifiers
            auto* postCtx = GetPlayerContext(playerId);
            if (postCtx)
            {
                auto* postGroup = GetPlayerGroupIfInstance(playerId, cand.name, instanceId);
                if (postGroup)
                {
                    postGroup->isExecutingCallback = false;

                    if (destroySuccess)
                    {
                        MarkGroupDestroyed(*postCtx, *postGroup);

                        Debug("Idle destroy success playerid=%d group=%s instance=%llu activeTD=%u",
                            playerId,
                            cand.name.c_str(),
                            static_cast<unsigned long long>(instanceId),
                            postCtx->activeTextDrawCount
                        );
                    }
                    else
                    {
                        Debug("Idle destroy failed playerid=%d group=%s instance=%llu",
                            playerId, cand.name.c_str(), static_cast<unsigned long long>(instanceId));
                    }
                }
                else
                {
                    Debug("[SUI] Group instance changed during idle destroy callback: playerid=%d group=%s old=%llu; aborting stale operation",
                        playerId, cand.name.c_str(), static_cast<unsigned long long>(instanceId));
                }
            }
        }
    }
}

bool SUICore::RegisterFactoryGroup(
    AMX* amx,
    int playerId,
    const std::string& group,
    const std::string& cbCreate,
    const std::string& cbDestroy,
    const std::string& cbShow,
    const std::string& cbHide
)
{
    if (!amx)
    {
        Debug("RegisterFactoryGroup failed: null amx instance playerid=%d group=%s", playerId, group.c_str());
        return false;
    }

    auto& ctx = players[playerId];
    ctx.playerId = playerId;

    auto it = ctx.groups.find(group);
    if (it != ctx.groups.end())
    {
        if (it->second.ownerAmx != nullptr && it->second.ownerAmx != amx)
        {
            Debug("RegisterFactoryGroup rejected: group %s already owned by amx=%p (caller amx=%p)",
                group.c_str(), it->second.ownerAmx, amx);
            return false;
        }
    }

    bool isNewGroup = (it == ctx.groups.end());
    bool isReplacingCallback = (it != ctx.groups.end() && it->second.isExecutingCallback);
    bool isUninitialized = (it != ctx.groups.end() && it->second.instanceId == 0);

    auto& pGroup = ctx.groups[group];
    pGroup.name = group;
    pGroup.ownerAmx = amx;
    pGroup.cbCreate = cbCreate;
    pGroup.cbDestroy = cbDestroy;
    pGroup.cbShow = cbShow;
    pGroup.cbHide = cbHide;

    if (isNewGroup || isReplacingCallback || isUninitialized)
    {
        pGroup.instanceId = AllocateGroupInstanceId();
        pGroup.isExecutingCallback = false;
        pGroup.isCreated = false;
        pGroup.isVisible = false;
        pGroup.hiddenSinceTick = 0;
        pGroup.lastUsedTick = 0;
    }

    Debug("RegisterFactoryGroup playerid=%d group=%s instanceId=%llu ownerAmx=%p create=%s destroy=%s show=%s hide=%s",
        playerId,
        group.c_str(),
        static_cast<unsigned long long>(pGroup.instanceId),
        amx,
        cbCreate.c_str(),
        cbDestroy.c_str(),
        cbShow.c_str(),
        cbHide.c_str()
    );

    return true;
}

void SUICore::ShowGroup(int playerId, const std::string& groupName)
{
    Debug("ShowGroup requested playerid=%d group=%s", playerId, groupName.c_str());

    auto* ctx = GetPlayerContext(playerId);
    if (!ctx)
    {
        Debug("ShowGroup failed: player context not found playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return;
    }

    auto it = ctx->groups.find(groupName);
    if (it == ctx->groups.end())
    {
        Debug("ShowGroup failed: group not found playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return;
    }

    auto& group = it->second;
    uint64_t instanceId = group.instanceId;

    Debug("ShowGroup state playerid=%d group=%s instance=%llu isCreated=%d isVisible=%d cbCreate=%s cbShow=%s",
        playerId,
        groupName.c_str(),
        static_cast<unsigned long long>(instanceId),
        group.isCreated ? 1 : 0,
        group.isVisible ? 1 : 0,
        group.cbCreate.c_str(),
        group.cbShow.c_str()
    );

    if (group.isExecutingCallback)
    {
        Debug("ShowGroup blocked recursion playerid=%d group=%s instance=%llu",
            playerId, groupName.c_str(), static_cast<unsigned long long>(instanceId));
        return;
    }

    group.isExecutingCallback = true;

    if (!group.isCreated)
    {
        const uint32_t authorizedSize = (group.estimatedSize == 0 ? 1 : group.estimatedSize);
        std::string cbCreate = group.cbCreate;

        // EnsureCapacity may invoke eviction callbacks that mutate player/group containers.
        if (!EnsureCapacity(*ctx, authorizedSize))
        {
            Debug("ShowGroup failed: not enough capacity playerid=%d group=%s required=%u",
                playerId,
                groupName.c_str(),
                authorizedSize
            );

            // Safely clear callback recursion flag on reacquired group only if matching instance
            auto* postGroup = GetPlayerGroupIfInstance(playerId, groupName, instanceId);
            if (postGroup)
            {
                postGroup->isExecutingCallback = false;
            }
            return;
        }

        // Re-acquire group before calling create callback
        auto* groupBeforeCreate = GetPlayerGroupIfInstance(playerId, groupName, instanceId);
        if (!groupBeforeCreate)
        {
            Debug("[SUI] ShowGroup aborted: group removed or replaced during capacity eviction playerid=%d group=%s old=%llu",
                playerId, groupName.c_str(), static_cast<unsigned long long>(instanceId));
            return;
        }

        AMX* ownerAmx = groupBeforeCreate->ownerAmx;

        Debug("Calling create callback playerid=%d group=%s instance=%llu callback=%s",
            playerId,
            groupName.c_str(),
            static_cast<unsigned long long>(instanceId),
            cbCreate.c_str()
        );

        // Pawn callbacks may call back into SUI and mutate players/groups.
        // Never retain container references across this boundary.
        bool createSuccess = CallPawnFunction(ownerAmx, playerId, cbCreate);

        // Re-acquire player and group state after create callback
        auto* postCtx = GetPlayerContext(playerId);
        if (!postCtx)
        {
            Debug("ShowGroup aborted: player context removed during create callback playerid=%d group=%s",
                playerId, groupName.c_str());
            return;
        }

        auto* postGroup = GetPlayerGroupIfInstance(playerId, groupName, instanceId);
        if (!postGroup)
        {
            Debug("[SUI] Group instance changed during callback: playerid=%d group=%s old=%llu; aborting stale operation",
                playerId, groupName.c_str(), static_cast<unsigned long long>(instanceId));
            return;
        }

        if (createSuccess)
        {
            if (postGroup->isCreated)
            {
                Debug("ShowGroup warning: group was already created during create callback playerid=%d group=%s",
                    playerId, groupName.c_str());
                postGroup->isExecutingCallback = false;
                return;
            }

            // Lock size to authorizedSize and add to accounting
            postGroup->estimatedSize = authorizedSize;
            if (TryAddActiveTextDrawCount(*postCtx, authorizedSize))
            {
                postGroup->isCreated = true;
                Debug("Create callback success playerid=%d group=%s instance=%llu activeTD=%u",
                    playerId,
                    groupName.c_str(),
                    static_cast<unsigned long long>(instanceId),
                    postCtx->activeTextDrawCount
                );
            }
            else
            {
                Debug("Create callback accounting failed playerid=%d group=%s instance=%llu activeTD=%u add=%u",
                    playerId,
                    groupName.c_str(),
                    static_cast<unsigned long long>(instanceId),
                    postCtx->activeTextDrawCount,
                    authorizedSize
                );
                postGroup->isExecutingCallback = false;
                return;
            }
        }
        else
        {
            Debug("Create callback failed playerid=%d group=%s callback=%s",
                playerId,
                groupName.c_str(),
                cbCreate.c_str()
            );
        }
    }

    // Re-acquire group state before checking show condition
    auto* groupBeforeShow = GetPlayerGroupIfInstance(playerId, groupName, instanceId);
    if (!groupBeforeShow)
    {
        Debug("[SUI] ShowGroup aborted before show: instance changed or removed playerid=%d group=%s old=%llu",
            playerId, groupName.c_str(), static_cast<unsigned long long>(instanceId));
        return;
    }

    if (groupBeforeShow->isCreated && !groupBeforeShow->isVisible)
    {
        std::string cbShow = groupBeforeShow->cbShow;
        AMX* ownerAmx = groupBeforeShow->ownerAmx;

        Debug("Calling show callback playerid=%d group=%s instance=%llu callback=%s",
            playerId,
            groupName.c_str(),
            static_cast<unsigned long long>(instanceId),
            cbShow.c_str()
        );

        bool showSuccess = CallPawnFunction(ownerAmx, playerId, cbShow);

        // Re-acquire after show callback
        auto* postGroup = GetPlayerGroupIfInstance(playerId, groupName, instanceId);
        if (postGroup)
        {
            if (showSuccess)
            {
                postGroup->isVisible = true;
                postGroup->lastUsedTick = Utils::GetTickCountMs();

                Debug("Show callback success playerid=%d group=%s instance=%llu",
                    playerId,
                    groupName.c_str(),
                    static_cast<unsigned long long>(instanceId)
                );
            }
            else
            {
                Debug("Show callback failed playerid=%d group=%s callback=%s",
                    playerId,
                    groupName.c_str(),
                    cbShow.c_str()
                );
            }
        }
        else
        {
            Debug("[SUI] Group instance changed during show callback: playerid=%d group=%s old=%llu; aborting stale operation",
                playerId, groupName.c_str(), static_cast<unsigned long long>(instanceId));
        }
    }

    // Safely clear callback recursion flag on reacquired group only if instance matches
    auto* finalGroup = GetPlayerGroupIfInstance(playerId, groupName, instanceId);
    if (finalGroup)
    {
        finalGroup->isExecutingCallback = false;
    }
}

void SUICore::HideGroup(int playerId, const std::string& groupName)
{
    Debug("HideGroup requested playerid=%d group=%s", playerId, groupName.c_str());

    auto* ctx = GetPlayerContext(playerId);
    if (!ctx)
    {
        Debug("HideGroup failed: player context not found playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return;
    }

    auto it = ctx->groups.find(groupName);
    if (it == ctx->groups.end())
    {
        Debug("HideGroup failed: group not found playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return;
    }

    auto& group = it->second;
    uint64_t instanceId = group.instanceId;

    if (group.isExecutingCallback)
    {
        Debug("HideGroup blocked recursion playerid=%d group=%s instance=%llu",
            playerId, groupName.c_str(), static_cast<unsigned long long>(instanceId));
        return;
    }

    if (group.isVisible)
    {
        group.isExecutingCallback = true;
        std::string cbHide = group.cbHide;
        AMX* ownerAmx = group.ownerAmx;

        Debug("Calling hide callback playerid=%d group=%s instance=%llu callback=%s",
            playerId,
            groupName.c_str(),
            static_cast<unsigned long long>(instanceId),
            cbHide.c_str()
        );

        // Pawn callbacks may call back into SUI and mutate players/groups.
        // Never retain container references across this boundary.
        bool hideSuccess = CallPawnFunction(ownerAmx, playerId, cbHide);

        // Re-acquire player and group state after hide callback
        auto* postGroup = GetPlayerGroupIfInstance(playerId, groupName, instanceId);
        if (postGroup)
        {
            postGroup->isExecutingCallback = false;

            if (hideSuccess)
            {
                uint64_t now = Utils::GetTickCountMs();
                postGroup->isVisible = false;
                postGroup->hiddenSinceTick = now;
                postGroup->lastUsedTick = now;

                Debug("Hide callback success playerid=%d group=%s instance=%llu",
                    playerId,
                    groupName.c_str(),
                    static_cast<unsigned long long>(instanceId)
                );
            }
            else
            {
                Debug("Hide callback failed playerid=%d group=%s callback=%s",
                    playerId,
                    groupName.c_str(),
                    cbHide.c_str()
                );
            }
        }
        else
        {
            Debug("[SUI] Group instance changed during hide callback: playerid=%d group=%s old=%llu; aborting stale operation",
                playerId, groupName.c_str(), static_cast<unsigned long long>(instanceId));
        }
    }
    else
    {
        Debug("HideGroup skipped: already hidden playerid=%d group=%s instance=%llu",
            playerId,
            groupName.c_str(),
            static_cast<unsigned long long>(instanceId)
        );
    }
}

void SUICore::SetIdleTimeout(int playerId, const std::string& groupName, uint32_t timeoutMs)
{
    auto* ctx = GetPlayerContext(playerId);
    if (!ctx)
    {
        Debug("SetIdleTimeout failed: player context not found playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return;
    }

    auto it = ctx->groups.find(groupName);
    if (it != ctx->groups.end())
    {
        it->second.idleTimeoutMs = timeoutMs;

        Debug("SetIdleTimeout playerid=%d group=%s timeout=%u",
            playerId,
            groupName.c_str(),
            timeoutMs
        );
    }
    else
    {
        Debug("SetIdleTimeout failed: group not found playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
    }
}

void SUICore::CleanupPlayer(int playerId)
{
    auto* ctx = GetPlayerContext(playerId);
    if (!ctx)
    {
        Debug("CleanupPlayer skipped: player context not found playerid=%d", playerId);
        return;
    }

    Debug("CleanupPlayer started playerid=%d groupCount=%d activeTD=%u",
        playerId,
        static_cast<int>(ctx->groups.size()),
        ctx->activeTextDrawCount
    );

    // Snapshot created group names and instance IDs to prevent iterator invalidation across callbacks
    struct GroupItem {
        std::string name;
        uint64_t instanceId;
    };
    std::vector<GroupItem> groupItems;
    groupItems.reserve(ctx->groups.size());
    for (const auto& [groupName, group] : ctx->groups)
    {
        if (group.isCreated)
        {
            groupItems.push_back({groupName, group.instanceId});
        }
    }

    for (const auto& item : groupItems)
    {
        auto* currentCtx = GetPlayerContext(playerId);
        if (!currentCtx)
        {
            // Player context was erased during a previous callback
            break;
        }

        auto* group = GetPlayerGroupIfInstance(playerId, item.name, item.instanceId);
        if (!group || !group->isCreated)
        {
            continue;
        }

        bool ok = DestroyGroupInternal(*currentCtx, *group, item.name);
        if (!ok)
        {
            Debug("CleanupPlayer warning: failed to destroy group playerid=%d group=%s instance=%llu",
                playerId,
                item.name.c_str(),
                static_cast<unsigned long long>(item.instanceId)
            );
        }
    }

    // Safely erase by stable player ID key rather than stale iterator
    players.erase(playerId);

    Debug("CleanupPlayer finished playerid=%d", playerId);
}

void SUICore::ResetPlayer(int playerId)
{
    auto* ctx = GetPlayerContext(playerId);
    if (!ctx)
    {
        Debug("ResetPlayer skipped: player context not found playerid=%d", playerId);
        return;
    }

    Debug("ResetPlayer started playerid=%d groupCount=%d activeTD=%u",
        playerId,
        static_cast<int>(ctx->groups.size()),
        ctx->activeTextDrawCount
    );

    // Snapshot created group names and instance IDs to prevent iterator invalidation across callbacks
    struct GroupItem {
        std::string name;
        uint64_t instanceId;
    };
    std::vector<GroupItem> groupItems;
    groupItems.reserve(ctx->groups.size());
    for (const auto& [groupName, group] : ctx->groups)
    {
        if (group.isCreated)
        {
            groupItems.push_back({groupName, group.instanceId});
        }
    }

    for (const auto& item : groupItems)
    {
        auto* currentCtx = GetPlayerContext(playerId);
        if (!currentCtx)
        {
            // Player context was erased during a previous callback
            break;
        }

        auto* group = GetPlayerGroupIfInstance(playerId, item.name, item.instanceId);
        if (!group || !group->isCreated)
        {
            continue;
        }

        bool ok = DestroyGroupInternal(*currentCtx, *group, item.name);
        if (!ok)
        {
            Debug("ResetPlayer warning: failed to destroy group playerid=%d group=%s instance=%llu",
                playerId,
                item.name.c_str(),
                static_cast<unsigned long long>(item.instanceId)
            );
        }
    }

    // Safely erase by stable player ID key rather than stale iterator
    players.erase(playerId);

    Debug("ResetPlayer finished playerid=%d", playerId);
}

bool SUICore::SetGroupSize(int playerId, const std::string& groupName, uint32_t size)
{
    auto* ctx = GetPlayerContext(playerId);
    if (!ctx)
    {
        Debug("SetGroupSize failed: player context not found playerid=%d group=%s", playerId, groupName.c_str());
        return false;
    }

    auto it = ctx->groups.find(groupName);
    if (it == ctx->groups.end())
    {
        Debug("SetGroupSize failed: group not found playerid=%d group=%s", playerId, groupName.c_str());
        return false;
    }

    auto& group = it->second;

    if (group.isExecutingCallback)
    {
        Debug("SetGroupSize rejected: group is executing callback playerid=%d group=%s",
            playerId, groupName.c_str());
        return false;
    }

    if (group.isCreated)
    {
        Debug("SetGroupSize rejected: group is already created playerid=%d group=%s",
            playerId, groupName.c_str());
        return false;
    }

    if (size == 0)
    {
        size = 1;
    }

    group.estimatedSize = size;

    Debug("SetGroupSize playerid=%d group=%s size=%u", playerId, groupName.c_str(), size);
    return true;
}

uint32_t SUICore::GetActiveTextDrawCount(int playerId)
{
    auto it = players.find(playerId);
    if (it == players.end())
    {
        return 0;
    }

    return it->second.activeTextDrawCount;
}

bool SUICore::TryAddActiveTextDrawCount(PlayerContext& ctx, uint32_t amount)
{
    uint64_t sum = static_cast<uint64_t>(ctx.activeTextDrawCount) + static_cast<uint64_t>(amount);
    if (sum > static_cast<uint64_t>(UINT32_MAX))
    {
        Debug("[SUI] Capacity invariant violation: activeTextDrawCount overflow playerid=%d active=%u add=%u",
            ctx.playerId, ctx.activeTextDrawCount, amount);
        return false;
    }

    if (sum > static_cast<uint64_t>(ctx.maxTextDraws))
    {
        Debug("[SUI] Capacity invariant violation: sum (%llu) exceeds hard ceiling maxTextDraws (%u) for player %d",
            sum, ctx.maxTextDraws, ctx.playerId);
        return false;
    }

    ctx.activeTextDrawCount = static_cast<uint32_t>(sum);
    return true;
}

void SUICore::AddActiveTextDrawCount(PlayerContext& ctx, uint32_t amount)
{
    TryAddActiveTextDrawCount(ctx, amount);
}

bool SUICore::RecalculateActiveTextDrawCount(PlayerContext& ctx)
{
    uint64_t sum = 0;
    for (const auto& [name, group] : ctx.groups)
    {
        if (group.isCreated)
        {
            sum += static_cast<uint64_t>(group.estimatedSize == 0 ? 1 : group.estimatedSize);
        }
    }

    if (sum > static_cast<uint64_t>(UINT32_MAX))
    {
        Debug("[SUI] RecalculateActiveTextDrawCount overflow playerid=%d", ctx.playerId);
        ctx.activeTextDrawCount = ctx.maxTextDraws;
        return false;
    }

    if (sum > static_cast<uint64_t>(ctx.maxTextDraws))
    {
        Debug("[SUI] Invariant corruption detected: tracked created groups sum (%llu) exceeds maxTextDraws (%u) playerid=%d",
            sum, ctx.maxTextDraws, ctx.playerId);
        ctx.activeTextDrawCount = ctx.maxTextDraws;
        return false;
    }

    ctx.activeTextDrawCount = static_cast<uint32_t>(sum);
    Debug("[SUI] RecalculateActiveTextDrawCount reconciled activeTextDrawCount=%u playerid=%d",
        ctx.activeTextDrawCount, ctx.playerId);
    return true;
}

void SUICore::SubtractActiveTextDrawCount(PlayerContext& ctx, uint32_t amount)
{
    if (ctx.activeTextDrawCount >= amount)
    {
        ctx.activeTextDrawCount -= amount;
    }
    else
    {
        Debug("[SUI] Capacity invariant violation: underflow subtraction playerid=%d active=%u subtract=%u. Reconciling state.",
            ctx.playerId, ctx.activeTextDrawCount, amount);
        RecalculateActiveTextDrawCount(ctx);
    }
}

bool SUICore::SetMaxTextDraws(int playerId, uint32_t maxCount)
{
    auto& ctx = players[playerId];
    ctx.playerId = playerId;

    if (maxCount == 0)
    {
        maxCount = 256;
    }

    // Invariant: cannot lower max below current active textdraws
    if (maxCount < ctx.activeTextDrawCount)
    {
        Debug("SetMaxTextDraws rejected: maxCount (%u) < activeTextDrawCount (%u) playerid=%d",
            maxCount, ctx.activeTextDrawCount, playerId);
        return false;
    }

    // Invariant: cannot lower max below current eviction threshold
    if (maxCount < ctx.evictionThreshold)
    {
        Debug("SetMaxTextDraws rejected: maxCount (%u) < evictionThreshold (%u) playerid=%d",
            maxCount, ctx.evictionThreshold, playerId);
        return false;
    }

    ctx.maxTextDraws = maxCount;

    Debug("SetMaxTextDraws playerid=%d max=%u threshold=%u",
        playerId,
        ctx.maxTextDraws,
        ctx.evictionThreshold
    );
    return true;
}

bool SUICore::SetEvictionThreshold(int playerId, uint32_t threshold)
{
    auto& ctx = players[playerId];
    ctx.playerId = playerId;

    if (threshold == 0)
    {
        threshold = 230;
    }

    // Invariant: evictionThreshold cannot exceed maxTextDraws
    if (threshold > ctx.maxTextDraws)
    {
        Debug("SetEvictionThreshold rejected: threshold (%u) > maxTextDraws (%u) playerid=%d",
            threshold, ctx.maxTextDraws, playerId);
        return false;
    }

    ctx.evictionThreshold = threshold;

    Debug("SetEvictionThreshold playerid=%d threshold=%u max=%u",
        playerId,
        ctx.evictionThreshold,
        ctx.maxTextDraws
    );
    return true;
}

void SUICore::SetGroupPriority(int playerId, const std::string& groupName, uint8_t priority)
{
    auto* ctx = GetPlayerContext(playerId);
    if (!ctx)
    {
        Debug("SetGroupPriority failed: player context not found playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return;
    }

    auto it = ctx->groups.find(groupName);
    if (it == ctx->groups.end())
    {
        Debug("SetGroupPriority failed: group not found playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return;
    }

    if (priority > SUI_PRIORITY_CRITICAL)
    {
        priority = SUI_PRIORITY_CRITICAL;
    }

    it->second.priority = priority;

    Debug("SetGroupPriority playerid=%d group=%s priority=%u",
        playerId,
        groupName.c_str(),
        static_cast<unsigned>(priority)
    );
}

void SUICore::MarkGroupDestroyed(PlayerContext& ctx, SUIGroup& group)
{
    group.isCreated = false;
    group.isVisible = false;
    group.hiddenSinceTick = 0;

    SubtractActiveTextDrawCount(ctx, group.estimatedSize);
}

bool SUICore::EnsureCapacity(PlayerContext& ctx, uint32_t requiredSize)
{
    int playerId = ctx.playerId;

    if (requiredSize == 0)
    {
        requiredSize = 1;
    }

    while (true)
    {
        auto* currentCtx = GetPlayerContext(playerId);
        if (!currentCtx)
        {
            return false;
        }

        if (requiredSize > currentCtx->maxTextDraws)
        {
            Debug("EnsureCapacity failed: requiredSize (%u) exceeds maxTextDraws (%u) playerid=%d",
                requiredSize, currentCtx->maxTextDraws, playerId);
            return false;
        }

        // Overflow-safe capacity comparison using widened 64-bit space
        uint64_t total = static_cast<uint64_t>(currentCtx->activeTextDrawCount) + static_cast<uint64_t>(requiredSize);
        if (total <= static_cast<uint64_t>(currentCtx->evictionThreshold) && total <= static_cast<uint64_t>(currentCtx->maxTextDraws))
        {
            Debug("EnsureCapacity OK playerid=%d active=%u required=%u threshold=%u max=%u",
                playerId,
                currentCtx->activeTextDrawCount,
                requiredSize,
                currentCtx->evictionThreshold,
                currentCtx->maxTextDraws
            );
            return true;
        }

        Debug("EnsureCapacity needs eviction playerid=%d active=%u required=%u threshold=%u",
            playerId,
            currentCtx->activeTextDrawCount,
            requiredSize,
            currentCtx->evictionThreshold
        );

        // EvictOneHiddenGroup executes callbacks that may mutate player/group maps
        if (!EvictOneHiddenGroup(*currentCtx))
        {
            // Re-check after eviction failure
            auto* checkCtx = GetPlayerContext(playerId);
            uint32_t activeTD = checkCtx ? checkCtx->activeTextDrawCount : 0;
            uint32_t threshold = checkCtx ? checkCtx->evictionThreshold : 0;

            Debug("EnsureCapacity failed: no evictable group playerid=%d active=%u required=%u threshold=%u",
                playerId,
                activeTD,
                requiredSize,
                threshold
            );
            return false;
        }
    }
}

bool SUICore::EvictOneHiddenGroup(PlayerContext& ctx)
{
    int playerId = ctx.playerId;
    std::string candidateName;
    uint64_t candidateInstanceId = 0;
    uint8_t candidatePriority = 0;
    uint64_t candidateLastUsed = 0;
    bool foundCandidate = false;

    // Identify candidate by stable group name key and instanceId
    for (auto& [groupName, group] : ctx.groups)
    {
        if (!group.isCreated)
            continue;

        if (group.isVisible)
            continue;

        if (group.isExecutingCallback)
            continue;

        if (!group.evictable)
            continue;

        if (group.priority >= SUI_PRIORITY_CRITICAL)
            continue;

        if (!foundCandidate)
        {
            candidateName = groupName;
            candidateInstanceId = group.instanceId;
            candidatePriority = group.priority;
            candidateLastUsed = group.lastUsedTick;
            foundCandidate = true;
            continue;
        }

        bool betterPriority = group.priority < candidatePriority;
        bool samePriorityOlder = (group.priority == candidatePriority) &&
                                 (group.lastUsedTick < candidateLastUsed);

        if (betterPriority || samePriorityOlder)
        {
            candidateName = groupName;
            candidateInstanceId = group.instanceId;
            candidatePriority = group.priority;
            candidateLastUsed = group.lastUsedTick;
        }
    }

    if (!foundCandidate)
    {
        return false;
    }

    // Re-acquire candidate before callback using instanceId
    auto* candidate = GetPlayerGroupIfInstance(playerId, candidateName, candidateInstanceId);
    if (!candidate)
    {
        return false;
    }

    std::string cbDestroy = candidate->cbDestroy;
    AMX* ownerAmx = candidate->ownerAmx;

    Debug("EvictOneHiddenGroup selected playerid=%d group=%s instance=%llu priority=%u evictable=%d lastUsed=%llu size=%u",
        playerId,
        candidateName.c_str(),
        static_cast<unsigned long long>(candidateInstanceId),
        static_cast<unsigned>(candidate->priority),
        candidate->evictable ? 1 : 0,
        static_cast<unsigned long long>(candidate->lastUsedTick),
        candidate->estimatedSize
    );

    candidate->isExecutingCallback = true;

    // Pawn callbacks may call back into SUI and mutate players/groups.
    // Never retain container references or pointers across this boundary.
    bool destroyed = CallPawnFunction(ownerAmx, playerId, cbDestroy);

    // Re-acquire player and candidate group after callback
    auto* postCtx = GetPlayerContext(playerId);
    if (!postCtx)
    {
        Debug("EvictOneHiddenGroup player removed during callback playerid=%d group=%s",
            playerId, candidateName.c_str());
        return false;
    }

    auto* postCandidate = GetPlayerGroupIfInstance(playerId, candidateName, candidateInstanceId);
    if (!postCandidate)
    {
        Debug("[SUI] EvictOneHiddenGroup candidate replaced or removed during callback playerid=%d group=%s old=%llu",
            playerId, candidateName.c_str(), static_cast<unsigned long long>(candidateInstanceId));
        return false;
    }

    postCandidate->isExecutingCallback = false;

    if (!destroyed)
    {
        Debug("EvictOneHiddenGroup failed destroy callback playerid=%d group=%s instance=%llu callback=%s",
            playerId,
            candidateName.c_str(),
            static_cast<unsigned long long>(candidateInstanceId),
            cbDestroy.c_str()
        );
        return false;
    }

    MarkGroupDestroyed(*postCtx, *postCandidate);

    Debug("EvictOneHiddenGroup success playerid=%d group=%s instance=%llu activeTD=%u",
        playerId,
        candidateName.c_str(),
        static_cast<unsigned long long>(candidateInstanceId),
        postCtx->activeTextDrawCount
    );

    return true;
}

bool SUICore::DestroyGroup(int playerId, const std::string& groupName)
{
    auto* ctx = GetPlayerContext(playerId);
    if (!ctx)
    {
        Debug("DestroyGroup failed: player context not found playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return false;
    }

    auto itGroup = ctx->groups.find(groupName);
    if (itGroup == ctx->groups.end())
    {
        Debug("DestroyGroup failed: group not found playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return false;
    }

    return DestroyGroupInternal(*ctx, itGroup->second, groupName);
}

bool SUICore::DestroyGroupInternal(PlayerContext& ctx, SUIGroup& group, const std::string& groupName)
{
    int playerId = ctx.playerId;
    uint64_t instanceId = group.instanceId;

    if (!group.isCreated)
    {
        Debug("DestroyGroupInternal skipped: not created playerid=%d group=%s instance=%llu",
            playerId,
            groupName.c_str(),
            static_cast<unsigned long long>(instanceId)
        );
        return true;
    }

    if (group.isExecutingCallback)
    {
        Debug("DestroyGroupInternal blocked: callback executing playerid=%d group=%s instance=%llu",
            playerId,
            groupName.c_str(),
            static_cast<unsigned long long>(instanceId)
        );
        return false;
    }

    group.isExecutingCallback = true;
    std::string cbHide = group.cbHide;
    std::string cbDestroy = group.cbDestroy;
    AMX* ownerAmx = group.ownerAmx;

    if (group.isVisible)
    {
        Debug("DestroyGroupInternal hiding first playerid=%d group=%s instance=%llu callback=%s",
            playerId,
            groupName.c_str(),
            static_cast<unsigned long long>(instanceId),
            cbHide.c_str()
        );

        // Pawn callbacks may call back into SUI and mutate players/groups.
        // Never retain container references across this boundary.
        bool hideSuccess = CallPawnFunction(ownerAmx, playerId, cbHide);

        // Re-acquire after hide callback
        auto* postGroup = GetPlayerGroupIfInstance(playerId, groupName, instanceId);
        if (!postGroup)
        {
            Debug("[SUI] DestroyGroupInternal aborted: group/player removed or replaced during hide callback playerid=%d group=%s old=%llu",
                playerId, groupName.c_str(), static_cast<unsigned long long>(instanceId));
            return false;
        }

        if (!hideSuccess)
        {
            Debug("DestroyGroupInternal failed: hide callback failed playerid=%d group=%s instance=%llu",
                playerId,
                groupName.c_str(),
                static_cast<unsigned long long>(instanceId)
            );

            postGroup->isExecutingCallback = false;
            return false;
        }

        postGroup->isVisible = false;
        postGroup->hiddenSinceTick = Utils::GetTickCountMs();
        postGroup->lastUsedTick = postGroup->hiddenSinceTick;
    }

    Debug("DestroyGroupInternal destroying playerid=%d group=%s instance=%llu callback=%s",
        playerId,
        groupName.c_str(),
        static_cast<unsigned long long>(instanceId),
        cbDestroy.c_str()
    );

    // Pawn callbacks may call back into SUI and mutate players/groups.
    // Never retain container references across this boundary.
    bool destroySuccess = CallPawnFunction(ownerAmx, playerId, cbDestroy);

    // Re-acquire player and group state after destroy callback
    auto* postCtx = GetPlayerContext(playerId);
    if (!postCtx)
    {
        Debug("DestroyGroupInternal player context removed during destroy callback playerid=%d group=%s instance=%llu",
            playerId, groupName.c_str(), static_cast<unsigned long long>(instanceId));
        return destroySuccess;
    }

    auto* finalGroup = GetPlayerGroupIfInstance(playerId, groupName, instanceId);
    if (!finalGroup)
    {
        Debug("[SUI] Group instance changed during destroy callback: playerid=%d group=%s old=%llu; aborting stale operation",
            playerId, groupName.c_str(), static_cast<unsigned long long>(instanceId));
        return destroySuccess;
    }

    finalGroup->isExecutingCallback = false;

    if (!destroySuccess)
    {
        Debug("DestroyGroupInternal failed: destroy callback failed playerid=%d group=%s instance=%llu",
            playerId,
            groupName.c_str(),
            static_cast<unsigned long long>(instanceId)
        );
        return false;
    }

    MarkGroupDestroyed(*postCtx, *finalGroup);

    Debug("DestroyGroupInternal success playerid=%d group=%s instance=%llu activeTD=%u",
        playerId,
        groupName.c_str(),
        static_cast<unsigned long long>(instanceId),
        postCtx->activeTextDrawCount
    );

    return true;
}

bool SUICore::IsGroupCreated(int playerId, const std::string& groupName)
{
    auto itPlayer = players.find(playerId);
    if (itPlayer == players.end())
    {
        return false;
    }

    auto& ctx = itPlayer->second;

    auto itGroup = ctx.groups.find(groupName);
    if (itGroup == ctx.groups.end())
    {
        return false;
    }

    return itGroup->second.isCreated;
}

bool SUICore::IsGroupVisible(int playerId, const std::string& groupName)
{
    auto itPlayer = players.find(playerId);
    if (itPlayer == players.end())
    {
        return false;
    }

    auto& ctx = itPlayer->second;

    auto itGroup = ctx.groups.find(groupName);
    if (itGroup == ctx.groups.end())
    {
        return false;
    }

    return itGroup->second.isVisible;
}

void SUICore::PrintPlayerState(int playerId)
{
    if (!logprintf)
        return;

    auto itPlayer = players.find(playerId);
    if (itPlayer == players.end())
    {
        logprintf("[SUI] Player %d state not found.", playerId);
        return;
    }

    auto& ctx = itPlayer->second;

    logprintf("[SUI] ================= PLAYER STATE =================");
    logprintf("[SUI] PlayerID: %d", playerId);
    logprintf("[SUI] ActiveTD: %u", ctx.activeTextDrawCount);
    logprintf("[SUI] MaxTD: %u", ctx.maxTextDraws);
    logprintf("[SUI] Threshold: %u", ctx.evictionThreshold);
    logprintf("[SUI] Groups: %d", static_cast<int>(ctx.groups.size()));
    logprintf("[SUI] ------------------------------------------------");

    for (auto& [groupName, group] : ctx.groups)
    {
        logprintf(
            "[SUI] group=%s instance=%llu created=%d visible=%d size=%u priority=%u timeout=%u hiddenSince=%llu",
            groupName.c_str(),
            static_cast<unsigned long long>(group.instanceId),
            group.isCreated ? 1 : 0,
            group.isVisible ? 1 : 0,
            group.estimatedSize,
            static_cast<unsigned>(group.priority),
            group.idleTimeoutMs,
            static_cast<unsigned long long>(group.hiddenSinceTick)
        );
    }

    logprintf("[SUI] =================================================");
}

void SUICore::SetGroupEvictable(int playerId, const std::string& groupName, bool enabled)
{
    auto* ctx = GetPlayerContext(playerId);
    if (!ctx)
    {
        Debug("SetGroupEvictable failed: player context not found playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return;
    }

    auto it = ctx->groups.find(groupName);
    if (it == ctx->groups.end())
    {
        Debug("SetGroupEvictable failed: group not found playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return;
    }

    it->second.evictable = enabled;

    Debug("SetGroupEvictable playerid=%d group=%s enabled=%d",
        playerId,
        groupName.c_str(),
        enabled ? 1 : 0
    );
}

bool SUICore::IsGroupEvictable(int playerId, const std::string& groupName)
{
    auto itPlayer = players.find(playerId);
    if (itPlayer == players.end())
    {
        return false;
    }

    auto& ctx = itPlayer->second;

    auto itGroup = ctx.groups.find(groupName);
    if (itGroup == ctx.groups.end())
    {
        return false;
    }

    return itGroup->second.evictable;
}

bool SUICore::TouchGroup(int playerId, const std::string& groupName)
{
    auto itPlayer = players.find(playerId);
    if (itPlayer == players.end())
    {
        Debug("TouchGroup failed: player context not found playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return false;
    }

    auto& ctx = itPlayer->second;

    auto itGroup = ctx.groups.find(groupName);
    if (itGroup == ctx.groups.end())
    {
        Debug("TouchGroup failed: group not found playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return false;
    }

    auto& group = itGroup->second;

    uint64_t now = Utils::GetTickCountMs();

    group.lastUsedTick = now;

    if (!group.isVisible && group.isCreated)
    {
        group.hiddenSinceTick = now;
    }

    Debug("TouchGroup success playerid=%d group=%s lastUsed=%llu hiddenSince=%llu",
        playerId,
        groupName.c_str(),
        static_cast<unsigned long long>(group.lastUsedTick),
        static_cast<unsigned long long>(group.hiddenSinceTick)
    );

    return true;
}

bool SUICore::CallPawnFunction(AMX* ownerAmx, int playerId, const std::string& functionName)
{
    if (!ownerAmx)
    {
        Debug("CallPawnFunction failed: null ownerAmx playerid=%d function=%s", playerId, functionName.c_str());
        return false;
    }

    if (!IsAmxActive(ownerAmx))
    {
        Debug("CallPawnFunction failed: ownerAmx %p is not active playerid=%d function=%s",
            ownerAmx, playerId, functionName.c_str());
        return false;
    }

    if (functionName.empty())
    {
        Debug("CallPawnFunction failed: empty function name playerid=%d", playerId);
        return false;
    }

    Debug("CallPawnFunction searching public=%s playerid=%d ownerAmx=%p",
        functionName.c_str(),
        playerId,
        ownerAmx
    );

    int index = -1;
    int findResult = amx_FindPublic(ownerAmx, functionName.c_str(), &index);

    Debug("amx_FindPublic public=%s result=%d index=%d",
        functionName.c_str(),
        findResult,
        index
    );

    if (findResult == AMX_ERR_NONE)
    {
        cell retval = 0;

        amx_Push(ownerAmx, static_cast<cell>(playerId));

        int execResult = amx_Exec(ownerAmx, &retval, index);

        Debug("amx_Exec public=%s execResult=%d retval=%d",
            functionName.c_str(),
            execResult,
            static_cast<int>(retval)
        );

        return execResult == AMX_ERR_NONE && retval != 0;
    }

    Debug("Public callback not found in owner AMX: %s", functionName.c_str());
    return false;
}