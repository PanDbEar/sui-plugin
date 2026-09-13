#include "Core.hpp"
#include "Utils.hpp"

#include <cstdarg>
#include <cstdio>

extern void (*logprintf)(const char* format, ...);

std::unordered_map<int, PlayerContext> SUICore::players;
std::vector<AMX*> SUICore::activeAmxInstances;
bool SUICore::debugEnabled = false;

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

        // Snapshot candidate group names for this player
        std::vector<std::string> candidateGroups;
        candidateGroups.reserve(ctx->groups.size());
        for (const auto& [groupName, group] : ctx->groups)
        {
            if (!group.isVisible && group.isCreated && !group.isExecutingCallback)
            {
                if ((currentTick - group.hiddenSinceTick) > group.idleTimeoutMs)
                {
                    candidateGroups.push_back(groupName);
                }
            }
        }

        for (const auto& groupName : candidateGroups)
        {
            auto* currentCtx = GetPlayerContext(playerId);
            if (!currentCtx)
            {
                break; // Entire player was removed during callback
            }

            auto itGroup = currentCtx->groups.find(groupName);
            if (itGroup == currentCtx->groups.end())
            {
                continue; // Group was destroyed or removed
            }

            auto& group = itGroup->second;
            if (group.isVisible || !group.isCreated || group.isExecutingCallback)
            {
                continue;
            }

            if ((currentTick - group.hiddenSinceTick) <= group.idleTimeoutMs)
            {
                continue;
            }

            std::string cbDestroy = group.cbDestroy;
            group.isExecutingCallback = true;

            Debug("Idle destroy triggered playerid=%d group=%s callback=%s",
                playerId,
                groupName.c_str(),
                cbDestroy.c_str()
            );

            // Pawn callbacks may call back into SUI and mutate players/groups.
            // Never retain container references or iterators across this boundary.
            bool destroySuccess = CallPawnFunction(playerId, cbDestroy);

            // Re-acquire player and group state using stable identifiers
            auto* postCtx = GetPlayerContext(playerId);
            if (postCtx)
            {
                auto itPostGroup = postCtx->groups.find(groupName);
                if (itPostGroup != postCtx->groups.end())
                {
                    auto& postGroup = itPostGroup->second;
                    postGroup.isExecutingCallback = false;

                    if (destroySuccess)
                    {
                        MarkGroupDestroyed(*postCtx, postGroup);

                        Debug("Idle destroy success playerid=%d group=%s activeTD=%u",
                            playerId,
                            groupName.c_str(),
                            postCtx->activeTextDrawCount
                        );
                    }
                    else
                    {
                        Debug("Idle destroy failed playerid=%d group=%s", playerId, groupName.c_str());
                    }
                }
            }
        }
    }
}

void SUICore::RegisterFactoryGroup(
    int playerId,
    const std::string& group,
    const std::string& cbCreate,
    const std::string& cbDestroy,
    const std::string& cbShow,
    const std::string& cbHide
)
{
    auto& ctx = players[playerId];
    ctx.playerId = playerId;

    auto& pGroup = ctx.groups[group];
    pGroup.name = group;
    pGroup.cbCreate = cbCreate;
    pGroup.cbDestroy = cbDestroy;
    pGroup.cbShow = cbShow;
    pGroup.cbHide = cbHide;

    Debug("RegisterFactoryGroup playerid=%d group=%s create=%s destroy=%s show=%s hide=%s",
        playerId,
        group.c_str(),
        cbCreate.c_str(),
        cbDestroy.c_str(),
        cbShow.c_str(),
        cbHide.c_str()
    );
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

    Debug("ShowGroup state playerid=%d group=%s isCreated=%d isVisible=%d cbCreate=%s cbShow=%s",
        playerId,
        groupName.c_str(),
        group.isCreated ? 1 : 0,
        group.isVisible ? 1 : 0,
        group.cbCreate.c_str(),
        group.cbShow.c_str()
    );

    if (group.isExecutingCallback)
    {
        Debug("ShowGroup blocked recursion playerid=%d group=%s", playerId, groupName.c_str());
        return;
    }

    group.isExecutingCallback = true;

    if (!group.isCreated)
    {
        uint32_t estimatedSize = group.estimatedSize;
        std::string cbCreate = group.cbCreate;

        // EnsureCapacity may invoke eviction callbacks that mutate player/group containers.
        if (!EnsureCapacity(*ctx, estimatedSize))
        {
            Debug("ShowGroup failed: not enough capacity playerid=%d group=%s required=%u",
                playerId,
                groupName.c_str(),
                estimatedSize
            );

            // Safely clear callback recursion flag on reacquired group
            auto* postGroup = GetPlayerGroup(playerId, groupName);
            if (postGroup)
            {
                postGroup->isExecutingCallback = false;
            }
            return;
        }

        // Re-acquire group before calling create callback
        auto* groupBeforeCreate = GetPlayerGroup(playerId, groupName);
        if (!groupBeforeCreate)
        {
            Debug("ShowGroup aborted: group removed during capacity eviction playerid=%d group=%s",
                playerId, groupName.c_str());
            return;
        }

        Debug("Calling create callback playerid=%d group=%s callback=%s",
            playerId,
            groupName.c_str(),
            cbCreate.c_str()
        );

        // Pawn callbacks may call back into SUI and mutate players/groups.
        // Never retain container references across this boundary.
        bool createSuccess = CallPawnFunction(playerId, cbCreate);

        // Re-acquire player and group state after create callback
        auto* postCtx = GetPlayerContext(playerId);
        if (!postCtx)
        {
            Debug("ShowGroup aborted: player context removed during create callback playerid=%d group=%s",
                playerId, groupName.c_str());
            return;
        }

        auto itGroup = postCtx->groups.find(groupName);
        if (itGroup == postCtx->groups.end())
        {
            Debug("ShowGroup aborted: group removed during create callback playerid=%d group=%s",
                playerId, groupName.c_str());
            return;
        }

        auto& postGroup = itGroup->second;

        if (createSuccess)
        {
            postGroup.isCreated = true;
            AddActiveTextDrawCount(*postCtx, postGroup.estimatedSize);

            Debug("Create callback success playerid=%d group=%s activeTD=%u",
                playerId,
                groupName.c_str(),
                postCtx->activeTextDrawCount
            );
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
    auto* groupBeforeShow = GetPlayerGroup(playerId, groupName);
    if (!groupBeforeShow)
    {
        return;
    }

    if (groupBeforeShow->isCreated && !groupBeforeShow->isVisible)
    {
        std::string cbShow = groupBeforeShow->cbShow;

        Debug("Calling show callback playerid=%d group=%s callback=%s",
            playerId,
            groupName.c_str(),
            cbShow.c_str()
        );

        // Pawn callbacks may call back into SUI and mutate players/groups.
        // Never retain container references across this boundary.
        bool showSuccess = CallPawnFunction(playerId, cbShow);

        // Re-acquire after show callback
        auto* postGroup = GetPlayerGroup(playerId, groupName);
        if (postGroup)
        {
            if (showSuccess)
            {
                postGroup->isVisible = true;
                postGroup->lastUsedTick = Utils::GetTickCountMs();

                Debug("Show callback success playerid=%d group=%s",
                    playerId,
                    groupName.c_str()
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
    }

    // Safely clear callback recursion flag on reacquired group
    auto* finalGroup = GetPlayerGroup(playerId, groupName);
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

    if (group.isExecutingCallback)
    {
        Debug("HideGroup blocked recursion playerid=%d group=%s", playerId, groupName.c_str());
        return;
    }

    if (group.isVisible)
    {
        group.isExecutingCallback = true;
        std::string cbHide = group.cbHide;

        Debug("Calling hide callback playerid=%d group=%s callback=%s",
            playerId,
            groupName.c_str(),
            cbHide.c_str()
        );

        // Pawn callbacks may call back into SUI and mutate players/groups.
        // Never retain container references across this boundary.
        bool hideSuccess = CallPawnFunction(playerId, cbHide);

        // Re-acquire player and group state after hide callback
        auto* postGroup = GetPlayerGroup(playerId, groupName);
        if (postGroup)
        {
            postGroup->isExecutingCallback = false;

            if (hideSuccess)
            {
                uint64_t now = Utils::GetTickCountMs();
                postGroup->isVisible = false;
                postGroup->hiddenSinceTick = now;
                postGroup->lastUsedTick = now;

                Debug("Hide callback success playerid=%d group=%s",
                    playerId,
                    groupName.c_str()
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
    }
    else
    {
        Debug("HideGroup skipped: already hidden playerid=%d group=%s",
            playerId,
            groupName.c_str()
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

    // Snapshot created group names to prevent iterator invalidation across callbacks
    std::vector<std::string> groupNames;
    groupNames.reserve(ctx->groups.size());
    for (const auto& [groupName, group] : ctx->groups)
    {
        if (group.isCreated)
        {
            groupNames.push_back(groupName);
        }
    }

    for (const auto& groupName : groupNames)
    {
        auto* currentCtx = GetPlayerContext(playerId);
        if (!currentCtx)
        {
            // Player context was erased during a previous callback
            break;
        }

        auto itGroup = currentCtx->groups.find(groupName);
        if (itGroup == currentCtx->groups.end() || !itGroup->second.isCreated)
        {
            continue;
        }

        bool ok = DestroyGroupInternal(*currentCtx, itGroup->second, groupName);
        if (!ok)
        {
            Debug("CleanupPlayer warning: failed to destroy group playerid=%d group=%s",
                playerId,
                groupName.c_str()
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

    // Snapshot created group names to prevent iterator invalidation across callbacks
    std::vector<std::string> groupNames;
    groupNames.reserve(ctx->groups.size());
    for (const auto& [groupName, group] : ctx->groups)
    {
        if (group.isCreated)
        {
            groupNames.push_back(groupName);
        }
    }

    for (const auto& groupName : groupNames)
    {
        auto* currentCtx = GetPlayerContext(playerId);
        if (!currentCtx)
        {
            // Player context was erased during a previous callback
            break;
        }

        auto itGroup = currentCtx->groups.find(groupName);
        if (itGroup == currentCtx->groups.end() || !itGroup->second.isCreated)
        {
            continue;
        }

        bool ok = DestroyGroupInternal(*currentCtx, itGroup->second, groupName);
        if (!ok)
        {
            Debug("ResetPlayer warning: failed to destroy group playerid=%d group=%s",
                playerId,
                groupName.c_str()
            );
        }
    }

    // Safely erase by stable player ID key rather than stale iterator
    players.erase(playerId);

    Debug("ResetPlayer finished playerid=%d", playerId);
}

void SUICore::SetGroupSize(int playerId, const std::string& groupName, uint32_t size)
{
    auto* ctx = GetPlayerContext(playerId);
    if (!ctx)
    {
        Debug("SetGroupSize failed: player context not found playerid=%d group=%s", playerId, groupName.c_str());
        return;
    }

    auto it = ctx->groups.find(groupName);
    if (it == ctx->groups.end())
    {
        Debug("SetGroupSize failed: group not found playerid=%d group=%s", playerId, groupName.c_str());
        return;
    }

    if (size == 0)
    {
        size = 1;
    }

    it->second.estimatedSize = size;

    Debug("SetGroupSize playerid=%d group=%s size=%u", playerId, groupName.c_str(), size);
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

void SUICore::AddActiveTextDrawCount(PlayerContext& ctx, uint32_t amount)
{
    ctx.activeTextDrawCount += amount;
}

void SUICore::SubtractActiveTextDrawCount(PlayerContext& ctx, uint32_t amount)
{
    if (ctx.activeTextDrawCount >= amount)
    {
        ctx.activeTextDrawCount -= amount;
    }
    else
    {
        ctx.activeTextDrawCount = 0;
    }
}

void SUICore::SetMaxTextDraws(int playerId, uint32_t maxCount)
{
    auto& ctx = players[playerId];
    ctx.playerId = playerId;

    if (maxCount == 0)
    {
        maxCount = 256;
    }

    ctx.maxTextDraws = maxCount;

    if (ctx.evictionThreshold > ctx.maxTextDraws)
    {
        ctx.evictionThreshold = ctx.maxTextDraws;
    }

    Debug("SetMaxTextDraws playerid=%d max=%u threshold=%u",
        playerId,
        ctx.maxTextDraws,
        ctx.evictionThreshold
    );
}

void SUICore::SetEvictionThreshold(int playerId, uint32_t threshold)
{
    auto& ctx = players[playerId];
    ctx.playerId = playerId;

    if (threshold == 0)
    {
        threshold = 230;
    }

    if (threshold > ctx.maxTextDraws)
    {
        threshold = ctx.maxTextDraws;
    }

    ctx.evictionThreshold = threshold;

    Debug("SetEvictionThreshold playerid=%d threshold=%u max=%u",
        playerId,
        ctx.evictionThreshold,
        ctx.maxTextDraws
    );
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

        if (currentCtx->activeTextDrawCount + requiredSize <= currentCtx->evictionThreshold)
        {
            Debug("EnsureCapacity OK playerid=%d active=%u required=%u threshold=%u",
                playerId,
                currentCtx->activeTextDrawCount,
                requiredSize,
                currentCtx->evictionThreshold
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
    uint8_t candidatePriority = 0;
    uint64_t candidateLastUsed = 0;
    bool foundCandidate = false;

    // Identify candidate by stable group name key
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
            candidatePriority = group.priority;
            candidateLastUsed = group.lastUsedTick;
        }
    }

    if (!foundCandidate)
    {
        return false;
    }

    // Re-acquire candidate before callback
    auto* candidate = GetPlayerGroup(playerId, candidateName);
    if (!candidate)
    {
        return false;
    }

    std::string cbDestroy = candidate->cbDestroy;

    Debug("EvictOneHiddenGroup selected playerid=%d group=%s priority=%u evictable=%d lastUsed=%llu size=%u",
        playerId,
        candidateName.c_str(),
        static_cast<unsigned>(candidate->priority),
        candidate->evictable ? 1 : 0,
        static_cast<unsigned long long>(candidate->lastUsedTick),
        candidate->estimatedSize
    );

    candidate->isExecutingCallback = true;

    // Pawn callbacks may call back into SUI and mutate players/groups.
    // Never retain container references or pointers across this boundary.
    bool destroyed = CallPawnFunction(playerId, cbDestroy);

    // Re-acquire player and candidate group after callback
    auto* postCtx = GetPlayerContext(playerId);
    if (!postCtx)
    {
        Debug("EvictOneHiddenGroup player removed during callback playerid=%d group=%s",
            playerId, candidateName.c_str());
        return false;
    }

    auto itCandidate = postCtx->groups.find(candidateName);
    if (itCandidate == postCtx->groups.end())
    {
        Debug("EvictOneHiddenGroup candidate removed during callback playerid=%d group=%s",
            playerId, candidateName.c_str());
        return destroyed;
    }

    auto& postCandidate = itCandidate->second;
    postCandidate.isExecutingCallback = false;

    if (!destroyed)
    {
        Debug("EvictOneHiddenGroup failed destroy callback playerid=%d group=%s callback=%s",
            playerId,
            candidateName.c_str(),
            cbDestroy.c_str()
        );
        return false;
    }

    MarkGroupDestroyed(*postCtx, postCandidate);

    Debug("EvictOneHiddenGroup success playerid=%d group=%s activeTD=%u",
        playerId,
        candidateName.c_str(),
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

    if (!group.isCreated)
    {
        Debug("DestroyGroupInternal skipped: not created playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return true;
    }

    if (group.isExecutingCallback)
    {
        Debug("DestroyGroupInternal blocked: callback executing playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return false;
    }

    group.isExecutingCallback = true;
    std::string cbHide = group.cbHide;
    std::string cbDestroy = group.cbDestroy;

    if (group.isVisible)
    {
        Debug("DestroyGroupInternal hiding first playerid=%d group=%s callback=%s",
            playerId,
            groupName.c_str(),
            cbHide.c_str()
        );

        // Pawn callbacks may call back into SUI and mutate players/groups.
        // Never retain container references across this boundary.
        bool hideSuccess = CallPawnFunction(playerId, cbHide);

        // Re-acquire after hide callback
        auto* postGroup = GetPlayerGroup(playerId, groupName);
        if (!postGroup)
        {
            Debug("DestroyGroupInternal aborted: group/player removed during hide callback playerid=%d group=%s",
                playerId, groupName.c_str());
            return false;
        }

        if (!hideSuccess)
        {
            Debug("DestroyGroupInternal failed: hide callback failed playerid=%d group=%s",
                playerId,
                groupName.c_str()
            );

            postGroup->isExecutingCallback = false;
            return false;
        }

        postGroup->isVisible = false;
        postGroup->hiddenSinceTick = Utils::GetTickCountMs();
        postGroup->lastUsedTick = postGroup->hiddenSinceTick;
    }

    Debug("DestroyGroupInternal destroying playerid=%d group=%s callback=%s",
        playerId,
        groupName.c_str(),
        cbDestroy.c_str()
    );

    // Pawn callbacks may call back into SUI and mutate players/groups.
    // Never retain container references across this boundary.
    bool destroySuccess = CallPawnFunction(playerId, cbDestroy);

    // Re-acquire player and group state after destroy callback
    auto* postCtx = GetPlayerContext(playerId);
    if (!postCtx)
    {
        Debug("DestroyGroupInternal player context removed during destroy callback playerid=%d group=%s",
            playerId, groupName.c_str());
        return destroySuccess;
    }

    auto itGroup = postCtx->groups.find(groupName);
    if (itGroup == postCtx->groups.end())
    {
        Debug("DestroyGroupInternal group removed during destroy callback playerid=%d group=%s",
            playerId, groupName.c_str());
        return destroySuccess;
    }

    auto& finalGroup = itGroup->second;
    finalGroup.isExecutingCallback = false;

    if (!destroySuccess)
    {
        Debug("DestroyGroupInternal failed: destroy callback failed playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return false;
    }

    MarkGroupDestroyed(*postCtx, finalGroup);

    Debug("DestroyGroupInternal success playerid=%d group=%s activeTD=%u",
        playerId,
        groupName.c_str(),
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
            "[SUI] group=%s created=%d visible=%d size=%u priority=%u timeout=%u hiddenSince=%llu",
            groupName.c_str(),
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

bool SUICore::CallPawnFunction(int playerId, const std::string& functionName)
{
    if (functionName.empty())
    {
        Debug("CallPawnFunction failed: empty function name playerid=%d", playerId);
        return false;
    }

    Debug("CallPawnFunction searching public=%s playerid=%d activeAmx=%d",
        functionName.c_str(),
        playerId,
        static_cast<int>(activeAmxInstances.size())
    );

    for (AMX* amx : activeAmxInstances)
    {
        int index = -1;
        int findResult = amx_FindPublic(amx, functionName.c_str(), &index);

        Debug("amx_FindPublic public=%s result=%d index=%d",
            functionName.c_str(),
            findResult,
            index
        );

        if (findResult == AMX_ERR_NONE)
        {
            cell retval = 0;

            amx_Push(amx, static_cast<cell>(playerId));

            int execResult = amx_Exec(amx, &retval, index);

            Debug("amx_Exec public=%s execResult=%d retval=%d",
                functionName.c_str(),
                execResult,
                static_cast<int>(retval)
            );

            return execResult == AMX_ERR_NONE && retval != 0;
        }
    }

    Debug("Public callback not found: %s", functionName.c_str());
    return false;
}