#include "Core.hpp"
#include "Utils.hpp"

#include <algorithm>
#include <cstdarg>
#include <cstdio>
#include <utility>

extern void (*logprintf)(const char* format, ...);

std::unordered_map<int, PlayerContext> SUICore::players;
std::vector<AMX*> SUICore::activeAmxInstances;
std::unordered_set<AMX*> SUICore::ownerCleanupActive;
bool SUICore::debugEnabled = false;
uint64_t SUICore::nextGroupInstanceId = 1;

namespace {
    struct OwnerCleanupGuard {
        AMX* amx;
        explicit OwnerCleanupGuard(AMX* a) : amx(a) {
            if (amx) {
                SUICore::ownerCleanupActive.insert(amx);
            }
        }
        ~OwnerCleanupGuard() {
            if (amx) {
                SUICore::ownerCleanupActive.erase(amx);
            }
        }
    };
}

bool SUICore::TryAllocateGroupInstanceId(uint64_t& outId)
{
    if (nextGroupInstanceId == 0)
    {
        outId = 0;
        return false;
    }
    outId = nextGroupInstanceId++;
    return true;
}

uint64_t SUICore::AllocateGroupInstanceId()
{
    uint64_t id = 0;
    if (!TryAllocateGroupInstanceId(id))
    {
        return 0;
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

bool SUICore::IsOwnerCleanupActive(AMX* amx)
{
    if (!amx)
    {
        return false;
    }
    return ownerCleanupActive.count(amx) > 0;
}

bool SUICore::CleanupOwnerGroups(AMX* ownerAmx)
{
    if (!ownerAmx)
    {
        Debug("[SUI-DEBUG] CleanupOwnerGroups rejected: null amx");
        return false;
    }

    if (!IsAmxActive(ownerAmx))
    {
        Debug("[SUI-DEBUG] CleanupOwnerGroups rejected: inactive amx %p", ownerAmx);
        return false;
    }

    if (IsOwnerCleanupActive(ownerAmx))
    {
        Debug("[SUI-DEBUG] CleanupOwnerGroups rejected: owner cleanup already active for amx %p", ownerAmx);
        return false;
    }

    OwnerCleanupGuard guard(ownerAmx);

    Debug("[SUI-DEBUG] CleanupOwnerGroups started for amx=%p", ownerAmx);

    // 1. Build deterministic snapshot of groups owned by ownerAmx
    struct OwnerGroupSnapshot {
        int playerId;
        std::string groupName;
        uint64_t instanceId;
    };
    std::vector<OwnerGroupSnapshot> snapshots;

    for (const auto& [playerId, ctx] : players)
    {
        for (const auto& [groupName, group] : ctx.groups)
        {
            if (group.ownerAmx == ownerAmx)
            {
                snapshots.push_back({playerId, groupName, group.instanceId});
            }
        }
    }

    // Sort deterministically: playerId ascending, groupName lexicographical ascending
    std::sort(snapshots.begin(), snapshots.end(), [](const OwnerGroupSnapshot& a, const OwnerGroupSnapshot& b) {
        if (a.playerId != b.playerId)
        {
            return a.playerId < b.playerId;
        }
        return a.groupName < b.groupName;
    });

    bool allCallbacksSucceeded = true;

    // 2. Process each snapshot
    for (const auto& snap : snapshots)
    {
        // Reacquire PlayerContext and group
        auto* ctx = GetPlayerContext(snap.playerId);
        if (!ctx)
        {
            continue;
        }

        auto* group = GetPlayerGroupIfInstance(snap.playerId, snap.groupName, snap.instanceId);
        if (!group || group->ownerAmx != ownerAmx)
        {
            continue;
        }

        // UNCREATED GROUP (Section 16):
        // For isCreated == false: no hide callback, no destroy callback.
        // Leave it for final terminal metadata sweep. No capacity subtraction.
        if (!group->isCreated)
        {
            Debug("[SUI-DEBUG] CleanupOwnerGroups snapshot skipped uncreated group playerid=%d group=%s",
                snap.playerId, snap.groupName.c_str());
            continue;
        }

        // HIDDEN CREATED GROUP (Section 17):
        // For isCreated == true && isVisible == false: attempt cbDestroy. No cbHide.
        // VISIBLE CREATED GROUP (Section 18 & 19):
        // For isCreated == true && isVisible == true: attempt cbHide, then cbDestroy.
        // TERMINAL HIDE FAILURE SEMANTICS (Section 19):
        // If cbHide execution fails, still attempt cbDestroy if same owned group still exists and AMX remains active.
        
        bool hideFailed = false;
        if (group->isVisible)
        {
            group->isExecutingCallback = true;
            std::string cbHide = group->cbHide;

            Debug("[SUI-DEBUG] CleanupOwnerGroups calling cbHide playerid=%d group=%s callback=%s",
                snap.playerId, snap.groupName.c_str(), cbHide.c_str());

            PawnCallResult hideRes = CallPawnFunction(ownerAmx, snap.playerId, cbHide);
            if (!hideRes.Success())
            {
                Debug("[SUI-DEBUG] CleanupOwnerGroups cbHide failed playerid=%d group=%s callback=%s amxErr=%d",
                    snap.playerId, snap.groupName.c_str(), cbHide.c_str(), hideRes.amxError);
                allCallbacksSucceeded = false;
                hideFailed = true;
            }

            // Reacquire after hide callback
            auto* postGroup = GetPlayerGroupIfInstance(snap.playerId, snap.groupName, snap.instanceId);
            if (!postGroup || postGroup->ownerAmx != ownerAmx || !IsAmxActive(ownerAmx))
            {
                Debug("[SUI-DEBUG] CleanupOwnerGroups group removed, replaced or AMX inactive after cbHide playerid=%d group=%s",
                    snap.playerId, snap.groupName.c_str());
                continue;
            }

            postGroup->isExecutingCallback = false;
            if (!hideFailed)
            {
                postGroup->isVisible = false;
                postGroup->hiddenSinceTick = Utils::GetTickCountMs();
                postGroup->lastUsedTick = postGroup->hiddenSinceTick;
            }
        }

        // Now attempt cbDestroy if group is still created
        auto* groupBeforeDestroy = GetPlayerGroupIfInstance(snap.playerId, snap.groupName, snap.instanceId);
        if (!groupBeforeDestroy || groupBeforeDestroy->ownerAmx != ownerAmx || !IsAmxActive(ownerAmx))
        {
            continue;
        }

        if (!groupBeforeDestroy->isCreated)
        {
            // Already destroyed (e.g. during cbHide or another callback)
            continue;
        }

        groupBeforeDestroy->isExecutingCallback = true;
        std::string cbDestroy = groupBeforeDestroy->cbDestroy;

        Debug("[SUI-DEBUG] CleanupOwnerGroups calling cbDestroy playerid=%d group=%s callback=%s",
            snap.playerId, snap.groupName.c_str(), cbDestroy.c_str());

        PawnCallResult destroyRes = CallPawnFunction(ownerAmx, snap.playerId, cbDestroy);
        if (!destroyRes.Success())
        {
            Debug("[SUI-DEBUG] CleanupOwnerGroups cbDestroy failed playerid=%d group=%s callback=%s amxErr=%d",
                snap.playerId, snap.groupName.c_str(), cbDestroy.c_str(), destroyRes.amxError);
            allCallbacksSucceeded = false;
        }

        // Reacquire after destroy callback
        auto* postCtx = GetPlayerContext(snap.playerId);
        auto* postGroup = GetPlayerGroupIfInstance(snap.playerId, snap.groupName, snap.instanceId);
        if (postGroup && postGroup->ownerAmx == ownerAmx)
        {
            postGroup->isExecutingCallback = false;
            if (postGroup->isCreated && postCtx)
            {
                // Transition isCreated: true -> false, subtract capacity exactly once
                MarkGroupDestroyed(*postCtx, *postGroup);
            }
        }
    }

    // 3. TERMINAL FINAL SWEEP (Section 24, 25)
    // For every remaining group where group.ownerAmx == ownerAmx:
    // If group.isCreated: subtract tracked estimatedSize exactly once.
    // Erase group metadata.
    // Uncreated: erase only.
    for (auto& [playerId, ctx] : players)
    {
        auto itGroup = ctx.groups.begin();
        while (itGroup != ctx.groups.end())
        {
            if (itGroup->second.ownerAmx == ownerAmx)
            {
                if (itGroup->second.isCreated)
                {
                    Debug("[SUI-DEBUG] CleanupOwnerGroups terminal sweep subtracting capacity playerid=%d group=%s size=%u",
                        playerId, itGroup->first.c_str(), itGroup->second.estimatedSize);
                    SubtractActiveTextDrawCount(ctx, itGroup->second.estimatedSize);
                    itGroup->second.isCreated = false;
                }
                Debug("[SUI-DEBUG] CleanupOwnerGroups terminal sweep erasing group metadata playerid=%d group=%s",
                    playerId, itGroup->first.c_str());
                itGroup = ctx.groups.erase(itGroup);
            }
            else
            {
                ++itGroup;
            }
        }
    }

    Debug("[SUI-DEBUG] CleanupOwnerGroups finished for amx=%p result=%d",
        ownerAmx, allCallbacksSucceeded ? 1 : 0);

    return allCallbacksSucceeded;
}

PlayerContext* SUICore::GetPlayerContext(int playerId)
{
    if (!Utils::IsValidPlayerId(playerId))
        return nullptr;

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
            bool destroySuccess = CallPawnFunction(ownerAmx, playerId, cbDestroy).Success();

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
    if (!Utils::IsValidPlayerId(playerId))
    {
        Debug("RegisterFactoryGroup rejected: invalid playerId=%d", playerId);
        return false;
    }

    if (!amx)
    {
        Debug("RegisterFactoryGroup failed: null amx instance playerid=%d group=%s", playerId, group.c_str());
        return false;
    }

    if (IsOwnerCleanupActive(amx))
    {
        Debug("RegisterFactoryGroup rejected: amx=%p is undergoing owner cleanup playerid=%d group=%s",
            amx, playerId, group.c_str());
        return false;
    }

    auto itPlayer = players.find(playerId);
    if (itPlayer != players.end())
    {
        // Invariant 0: Mutation / registration during active player teardown is REJECTED
        if (itPlayer->second.teardownState != PlayerTeardownState::None)
        {
            Debug("RegisterFactoryGroup rejected: player %d is undergoing teardown", playerId);
            return false;
        }

        auto itGroup = itPlayer->second.groups.find(group);
        if (itGroup != itPlayer->second.groups.end())
        {
            if (IsOwnerCleanupActive(itGroup->second.ownerAmx))
            {
                Debug("RegisterFactoryGroup rejected: existing group %s owner amx=%p is undergoing owner cleanup",
                    group.c_str(), itGroup->second.ownerAmx);
                return false;
            }

            // Invariant 1: Different-owner registration is ALWAYS rejected while old group exists
            if (itGroup->second.ownerAmx != nullptr && itGroup->second.ownerAmx != amx)
            {
                Debug("RegisterFactoryGroup rejected: group %s already owned by amx=%p (caller amx=%p)",
                    group.c_str(), itGroup->second.ownerAmx, amx);
                return false;
            }

            // Invariant 2: Re-registration during active callback execution is REJECTED
            // Both same-owner and cross-owner cannot mutate/replace an active group while
            // it is participating in an outer callback transaction.
            if (itGroup->second.isExecutingCallback)
            {
                Debug("RegisterFactoryGroup rejected: group %s is currently executing a callback playerid=%d",
                    group.c_str(), playerId);
                return false;
            }

            // Updating callback configuration for existing group outside of callbacks
            auto& pGroup = itGroup->second;
            pGroup.ownerAmx = amx;
            pGroup.cbCreate = cbCreate;
            pGroup.cbDestroy = cbDestroy;
            pGroup.cbShow = cbShow;
            pGroup.cbHide = cbHide;

            Debug("RegisterFactoryGroup updated existing group playerid=%d group=%s instanceId=%llu ownerAmx=%p",
                playerId, group.c_str(), static_cast<unsigned long long>(pGroup.instanceId), amx);
            return true;
        }
    }

    // New group creation: Allocate fresh instance ID FIRST before modifying state
    uint64_t newId = 0;
    if (!TryAllocateGroupInstanceId(newId))
    {
        Debug("RegisterFactoryGroup failed: instance ID allocation failure playerid=%d group=%s",
            playerId, group.c_str());
        return false;
    }

    auto& ctx = players[playerId];
    ctx.playerId = playerId;

    auto& pGroup = ctx.groups[group];
    pGroup = SUIGroup();
    pGroup.name = group;
    pGroup.instanceId = newId;
    pGroup.ownerAmx = amx;
    pGroup.cbCreate = cbCreate;
    pGroup.cbDestroy = cbDestroy;
    pGroup.cbShow = cbShow;
    pGroup.cbHide = cbHide;
    pGroup.isCreated = false;
    pGroup.isVisible = false;
    pGroup.hiddenSinceTick = 0;
    pGroup.lastUsedTick = 0;
    pGroup.idleTimeoutMs = 30000;
    pGroup.estimatedSize = 1;
    pGroup.priority = SUI_PRIORITY_NORMAL;
    pGroup.evictable = true;
    pGroup.isExecutingCallback = false;

    Debug("RegisterFactoryGroup registered new group playerid=%d group=%s instanceId=%llu ownerAmx=%p create=%s destroy=%s show=%s hide=%s",
        playerId,
        group.c_str(),
        static_cast<unsigned long long>(newId),
        amx,
        cbCreate.c_str(),
        cbDestroy.c_str(),
        cbShow.c_str(),
        cbHide.c_str()
    );

    return true;
}

bool SUICore::ShowGroup(int playerId, const std::string& groupName)
{
    Debug("ShowGroup requested playerid=%d group=%s", playerId, groupName.c_str());

    auto* ctx = GetPlayerContext(playerId);
    if (!ctx)
    {
        Debug("ShowGroup failed: player context not found playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return false;
    }

    if (ctx->teardownState != PlayerTeardownState::None)
    {
        Debug("ShowGroup rejected: player %d is undergoing teardown", playerId);
        return false;
    }

    auto it = ctx->groups.find(groupName);
    if (it == ctx->groups.end())
    {
        Debug("ShowGroup failed: group not found playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return false;
    }

    auto& group = it->second;
    if (IsOwnerCleanupActive(group.ownerAmx))
    {
        Debug("ShowGroup rejected: group %s owner amx=%p is undergoing owner cleanup playerid=%d",
            groupName.c_str(), group.ownerAmx, playerId);
        return false;
    }

    uint64_t instanceId = group.instanceId;
    bool wasCreatedBeforeShow = group.isCreated;

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
        return false;
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
            return false;
        }

        // Re-acquire group before calling create callback
        auto* groupBeforeCreate = GetPlayerGroupIfInstance(playerId, groupName, instanceId);
        if (!groupBeforeCreate)
        {
            Debug("[SUI] ShowGroup aborted: group removed or replaced during capacity eviction playerid=%d group=%s old=%llu",
                playerId, groupName.c_str(), static_cast<unsigned long long>(instanceId));
            return false;
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
        bool createSuccess = CallPawnFunction(ownerAmx, playerId, cbCreate).Success();

        // Re-acquire player and group state after create callback
        auto* postCtx = GetPlayerContext(playerId);
        if (!postCtx)
        {
            Debug("ShowGroup aborted: player context removed during create callback playerid=%d group=%s",
                playerId, groupName.c_str());
            return false;
        }

        auto* postGroup = GetPlayerGroupIfInstance(playerId, groupName, instanceId);
        if (!postGroup)
        {
            Debug("[SUI] Group instance changed during callback: playerid=%d group=%s old=%llu; aborting stale operation",
                playerId, groupName.c_str(), static_cast<unsigned long long>(instanceId));
            return false;
        }

        if (createSuccess)
        {
            if (postGroup->isCreated)
            {
                Debug("ShowGroup warning: group was already created during create callback playerid=%d group=%s",
                    playerId, groupName.c_str());
                postGroup->isExecutingCallback = false;
                return false;
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
                return false;
            }
        }
        else
        {
            Debug("Create callback failed playerid=%d group=%s callback=%s",
                playerId,
                groupName.c_str(),
                cbCreate.c_str()
            );
            postGroup->isExecutingCallback = false;
            return false;
        }
    }

    // Re-acquire group state before checking show condition
    auto* groupBeforeShow = GetPlayerGroupIfInstance(playerId, groupName, instanceId);
    if (!groupBeforeShow)
    {
        Debug("[SUI] ShowGroup aborted before show: instance changed or removed playerid=%d group=%s old=%llu",
            playerId, groupName.c_str(), static_cast<unsigned long long>(instanceId));
        return false;
    }

    bool showSuccess = true;
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

        showSuccess = CallPawnFunction(ownerAmx, playerId, cbShow).Success();

        // Re-acquire after show callback
        auto* postGroup = GetPlayerGroupIfInstance(playerId, groupName, instanceId);
        if (postGroup)
        {
            if (showSuccess)
            {
                postGroup->isVisible = true;
                postGroup->hiddenSinceTick = 0;
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

                if (!wasCreatedBeforeShow && postGroup->isCreated && !postGroup->isVisible)
                {
                    uint64_t now = Utils::GetTickCountMs();
                    postGroup->hiddenSinceTick = now;
                    postGroup->lastUsedTick = now;

                    Debug("Show callback failure initialized hidden interval playerid=%d group=%s instance=%llu hiddenSince=%llu",
                        playerId,
                        groupName.c_str(),
                        static_cast<unsigned long long>(instanceId),
                        static_cast<unsigned long long>(now)
                    );
                }
            }
        }
        else
        {
            Debug("[SUI] Group instance changed during show callback: playerid=%d group=%s old=%llu; aborting stale operation",
                playerId, groupName.c_str(), static_cast<unsigned long long>(instanceId));
            return false;
        }
    }

    // Safely clear callback recursion flag on reacquired group only if instance matches
    auto* finalGroup = GetPlayerGroupIfInstance(playerId, groupName, instanceId);
    if (finalGroup)
    {
        finalGroup->isExecutingCallback = false;
    }
    return showSuccess;
}

bool SUICore::HideGroup(int playerId, const std::string& groupName)
{
    Debug("HideGroup requested playerid=%d group=%s", playerId, groupName.c_str());

    auto* ctx = GetPlayerContext(playerId);
    if (!ctx)
    {
        Debug("HideGroup failed: player context not found playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return false;
    }

    if (ctx->teardownState != PlayerTeardownState::None)
    {
        Debug("HideGroup rejected: player %d is undergoing teardown", playerId);
        return false;
    }

    auto it = ctx->groups.find(groupName);
    if (it == ctx->groups.end())
    {
        Debug("HideGroup failed: group not found playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return false;
    }

    auto& group = it->second;
    if (IsOwnerCleanupActive(group.ownerAmx))
    {
        Debug("HideGroup rejected: group %s owner amx=%p is undergoing owner cleanup playerid=%d",
            groupName.c_str(), group.ownerAmx, playerId);
        return false;
    }

    uint64_t instanceId = group.instanceId;

    if (group.isExecutingCallback)
    {
        Debug("HideGroup blocked recursion playerid=%d group=%s instance=%llu",
            playerId, groupName.c_str(), static_cast<unsigned long long>(instanceId));
        return false;
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
        bool hideSuccess = CallPawnFunction(ownerAmx, playerId, cbHide).Success();

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
                return true;
            }
            else
            {
                Debug("Hide callback failed playerid=%d group=%s callback=%s",
                    playerId,
                    groupName.c_str(),
                    cbHide.c_str()
                );
                return false;
            }
        }
        else
        {
            Debug("[SUI] Group instance changed during hide callback: playerid=%d group=%s old=%llu; aborting stale operation",
                playerId, groupName.c_str(), static_cast<unsigned long long>(instanceId));
            return false;
        }
    }
    else
    {
        Debug("HideGroup skipped: already hidden playerid=%d group=%s instance=%llu",
            playerId,
            groupName.c_str(),
            static_cast<unsigned long long>(instanceId)
        );
        return true;
    }
}

bool SUICore::SetIdleTimeout(int playerId, const std::string& groupName, uint32_t timeoutMs)
{
    auto* ctx = GetPlayerContext(playerId);
    if (!ctx || ctx->teardownState != PlayerTeardownState::None)
    {
        Debug("SetIdleTimeout failed: player context not found or in teardown playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return false;
    }

    auto it = ctx->groups.find(groupName);
    if (it != ctx->groups.end())
    {
        if (IsOwnerCleanupActive(it->second.ownerAmx))
        {
            Debug("SetIdleTimeout rejected: group %s owner amx=%p is undergoing owner cleanup playerid=%d",
                groupName.c_str(), it->second.ownerAmx, playerId);
            return false;
        }

        it->second.idleTimeoutMs = timeoutMs;

        Debug("SetIdleTimeout playerid=%d group=%s timeout=%u",
            playerId,
            groupName.c_str(),
            timeoutMs
        );
        return true;
    }
    else
    {
        Debug("SetIdleTimeout failed: group not found playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return false;
    }
}

bool SUICore::CleanupPlayer(int playerId)
{
    if (!Utils::IsValidPlayerId(playerId))
    {
        Debug("CleanupPlayer rejected: invalid playerId=%d", playerId);
        return false;
    }

    auto itPlayer = players.find(playerId);
    if (itPlayer == players.end())
    {
        Debug("CleanupPlayer skipped: player context not found playerid=%d", playerId);
        return true;
    }

    auto& ctx = itPlayer->second;

    for (const auto& [gName, grp] : ctx.groups)
    {
        if (IsOwnerCleanupActive(grp.ownerAmx))
        {
            Debug("CleanupPlayer rejected: playerid=%d contains group '%s' with active owner cleanup amx=%p",
                playerId, gName.c_str(), grp.ownerAmx);
            return false;
        }
    }

    if (ctx.teardownState != PlayerTeardownState::None)
    {
        Debug("CleanupPlayer rejected: playerid=%d already in teardown state", playerId);
        return false;
    }

    ctx.teardownState = PlayerTeardownState::Cleanup;

    Debug("CleanupPlayer started playerid=%d groupCount=%d activeTD=%u",
        playerId,
        static_cast<int>(ctx.groups.size()),
        ctx.activeTextDrawCount
    );

    // Snapshot created group names and instance IDs to prevent iterator invalidation across callbacks
    struct GroupItem {
        std::string name;
        uint64_t instanceId;
    };
    std::vector<GroupItem> groupItems;
    groupItems.reserve(ctx.groups.size());
    for (const auto& [groupName, group] : ctx.groups)
    {
        if (group.isCreated)
        {
            groupItems.push_back({groupName, group.instanceId});
        }
    }

    // Direct erasure of uncreated groups without callbacks (T10)
    for (auto it = ctx.groups.begin(); it != ctx.groups.end(); )
    {
        if (!it->second.isCreated)
        {
            it = ctx.groups.erase(it);
        }
        else
        {
            ++it;
        }
    }

    bool allDestroyedSuccessfully = true;

    for (const auto& item : groupItems)
    {
        auto* currentCtx = GetPlayerContext(playerId);
        if (!currentCtx)
        {
            allDestroyedSuccessfully = false;
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
            allDestroyedSuccessfully = false;
            Debug("CleanupPlayer warning: failed to destroy group playerid=%d group=%s instance=%llu",
                playerId,
                item.name.c_str(),
                static_cast<unsigned long long>(item.instanceId)
            );
        }
        else
        {
            currentCtx->groups.erase(item.name);
        }
    }

    // Terminal purge: erase player context unconditionally
    players.erase(playerId);

    Debug("CleanupPlayer finished playerid=%d allDestroyed=%d", playerId, allDestroyedSuccessfully ? 1 : 0);
    return allDestroyedSuccessfully;
}

bool SUICore::ResetPlayer(int playerId)
{
    if (!Utils::IsValidPlayerId(playerId))
    {
        Debug("ResetPlayer rejected: invalid playerId=%d", playerId);
        return false;
    }

    auto itPlayer = players.find(playerId);
    if (itPlayer == players.end())
    {
        Debug("ResetPlayer skipped: player context not found playerid=%d", playerId);
        return true;
    }

    auto& ctx = itPlayer->second;

    for (const auto& [gName, grp] : ctx.groups)
    {
        if (IsOwnerCleanupActive(grp.ownerAmx))
        {
            Debug("ResetPlayer rejected: playerid=%d contains group '%s' with active owner cleanup amx=%p",
                playerId, gName.c_str(), grp.ownerAmx);
            return false;
        }
    }

    if (ctx.teardownState != PlayerTeardownState::None)
    {
        Debug("ResetPlayer rejected: playerid=%d already in teardown state", playerId);
        return false;
    }

    ctx.teardownState = PlayerTeardownState::Reset;

    Debug("ResetPlayer started playerid=%d groupCount=%d activeTD=%u",
        playerId,
        static_cast<int>(ctx.groups.size()),
        ctx.activeTextDrawCount
    );

    // Snapshot created group names and instance IDs to prevent iterator invalidation across callbacks
    struct GroupItem {
        std::string name;
        uint64_t instanceId;
    };
    std::vector<GroupItem> groupItems;
    groupItems.reserve(ctx.groups.size());
    for (const auto& [groupName, group] : ctx.groups)
    {
        if (group.isCreated)
        {
            groupItems.push_back({groupName, group.instanceId});
        }
    }

    // Direct erasure of uncreated groups without callbacks (T10)
    for (auto it = ctx.groups.begin(); it != ctx.groups.end(); )
    {
        if (!it->second.isCreated)
        {
            it = ctx.groups.erase(it);
        }
        else
        {
            ++it;
        }
    }

    for (const auto& item : groupItems)
    {
        auto* currentCtx = GetPlayerContext(playerId);
        if (!currentCtx)
        {
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
        else
        {
            currentCtx->groups.erase(item.name);
        }
    }

    auto* currentCtx = GetPlayerContext(playerId);
    if (!currentCtx)
    {
        Debug("ResetPlayer finished playerid=%d (context was erased)", playerId);
        return true;
    }

    if (currentCtx->groups.empty())
    {
        players.erase(playerId);
        Debug("ResetPlayer finished success playerid=%d", playerId);
        return true;
    }
    else
    {
        // Preserve failed groups in context; clear teardown state to allow recovery (T16)
        currentCtx->teardownState = PlayerTeardownState::None;
        Debug("ResetPlayer finished with preserved failed groups playerid=%d remainingGroups=%zu activeTD=%u",
            playerId, currentCtx->groups.size(), currentCtx->activeTextDrawCount);
        return false;
    }
}

bool SUICore::SetGroupSize(int playerId, const std::string& groupName, uint32_t size)
{
    auto* ctx = GetPlayerContext(playerId);
    if (!ctx || ctx->teardownState != PlayerTeardownState::None)
    {
        Debug("SetGroupSize failed: player context not found or in teardown playerid=%d group=%s", playerId, groupName.c_str());
        return false;
    }

    auto it = ctx->groups.find(groupName);
    if (it == ctx->groups.end())
    {
        Debug("SetGroupSize failed: group not found playerid=%d group=%s", playerId, groupName.c_str());
        return false;
    }

    auto& group = it->second;

    if (IsOwnerCleanupActive(group.ownerAmx))
    {
        Debug("SetGroupSize rejected: group %s owner amx=%p is undergoing owner cleanup playerid=%d",
            groupName.c_str(), group.ownerAmx, playerId);
        return false;
    }

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
    if (!Utils::IsValidPlayerId(playerId))
    {
        return 0;
    }

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
    if (!Utils::IsValidPlayerId(playerId))
    {
        Debug("SetMaxTextDraws rejected: invalid playerId=%d", playerId);
        return false;
    }

    auto itPlayer = players.find(playerId);
    if (itPlayer != players.end() && itPlayer->second.teardownState != PlayerTeardownState::None)
    {
        Debug("SetMaxTextDraws rejected: player %d is undergoing teardown", playerId);
        return false;
    }

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
    if (!Utils::IsValidPlayerId(playerId))
    {
        Debug("SetEvictionThreshold rejected: invalid playerId=%d", playerId);
        return false;
    }

    auto itPlayer = players.find(playerId);
    if (itPlayer != players.end() && itPlayer->second.teardownState != PlayerTeardownState::None)
    {
        Debug("SetEvictionThreshold rejected: player %d is undergoing teardown", playerId);
        return false;
    }

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

bool SUICore::SetGroupPriority(int playerId, const std::string& groupName, uint8_t priority)
{
    auto* ctx = GetPlayerContext(playerId);
    if (!ctx || ctx->teardownState != PlayerTeardownState::None)
    {
        Debug("SetGroupPriority failed: player context not found or in teardown playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return false;
    }

    auto it = ctx->groups.find(groupName);
    if (it == ctx->groups.end())
    {
        Debug("SetGroupPriority failed: group not found playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return false;
    }

    if (IsOwnerCleanupActive(it->second.ownerAmx))
    {
        Debug("SetGroupPriority rejected: group %s owner amx=%p is undergoing owner cleanup playerid=%d",
            groupName.c_str(), it->second.ownerAmx, playerId);
        return false;
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
    return true;
}

void SUICore::MarkGroupDestroyed(PlayerContext& ctx, SUIGroup& group)
{
    group.isCreated = false;
    group.isVisible = false;
    group.hiddenSinceTick = 0;

    SubtractActiveTextDrawCount(ctx, group.estimatedSize);
}

std::vector<EvictionCandidate> SUICore::CollectEligibleEvictionCandidates(const PlayerContext& ctx)
{
    std::vector<EvictionCandidate> candidates;

    for (const auto& [groupName, group] : ctx.groups)
    {
        if (!group.isCreated)
            continue;

        if (IsOwnerCleanupActive(group.ownerAmx))
            continue;

        if (group.isVisible)
            continue;

        if (group.isExecutingCallback)
            continue;

        if (!group.evictable)
            continue;

        if (group.priority >= SUI_PRIORITY_CRITICAL)
            continue;

        EvictionCandidate cand;
        cand.groupName = groupName;
        cand.instanceId = group.instanceId;
        cand.estimatedSize = group.estimatedSize;
        cand.priority = group.priority;
        cand.lastUsedTick = group.lastUsedTick;
        candidates.push_back(cand);
    }

    std::sort(candidates.begin(), candidates.end(), [](const EvictionCandidate& a, const EvictionCandidate& b) {
        if (a.priority != b.priority)
        {
            return a.priority < b.priority;
        }
        if (a.lastUsedTick != b.lastUsedTick)
        {
            return a.lastUsedTick < b.lastUsedTick;
        }
        return a.groupName < b.groupName;
    });

    return candidates;
}

bool SUICore::EvictCandidate(PlayerContext& ctx, const EvictionCandidate& cand)
{
    int playerId = ctx.playerId;

    // Re-acquire candidate before callback using instanceId
    auto* candidate = GetPlayerGroupIfInstance(playerId, cand.groupName, cand.instanceId);
    if (!candidate)
    {
        return false;
    }

    if (!candidate->isCreated || candidate->isVisible || candidate->isExecutingCallback ||
        !candidate->evictable || candidate->priority >= SUI_PRIORITY_CRITICAL ||
        IsOwnerCleanupActive(candidate->ownerAmx))
    {
        return false;
    }

    std::string cbDestroy = candidate->cbDestroy;
    AMX* ownerAmx = candidate->ownerAmx;

    Debug("EvictCandidate selected playerid=%d group=%s instance=%llu priority=%u evictable=%d lastUsed=%llu size=%u",
        playerId,
        cand.groupName.c_str(),
        static_cast<unsigned long long>(cand.instanceId),
        static_cast<unsigned>(candidate->priority),
        candidate->evictable ? 1 : 0,
        static_cast<unsigned long long>(candidate->lastUsedTick),
        candidate->estimatedSize
    );

    candidate->isExecutingCallback = true;

    // Pawn callbacks may call back into SUI and mutate players/groups.
    // Never retain container references or pointers across this boundary.
    bool destroyed = CallPawnFunction(ownerAmx, playerId, cbDestroy).Success();

    // Re-acquire player and candidate group after callback
    auto* postCtx = GetPlayerContext(playerId);
    if (!postCtx)
    {
        Debug("EvictCandidate player removed during callback playerid=%d group=%s",
            playerId, cand.groupName.c_str());
        return false;
    }

    auto* postCandidate = GetPlayerGroupIfInstance(playerId, cand.groupName, cand.instanceId);
    if (!postCandidate)
    {
        Debug("[SUI] EvictCandidate candidate replaced or removed during callback playerid=%d group=%s old=%llu",
            playerId, cand.groupName.c_str(), static_cast<unsigned long long>(cand.instanceId));
        return false;
    }

    postCandidate->isExecutingCallback = false;

    if (!destroyed)
    {
        Debug("EvictCandidate failed destroy callback playerid=%d group=%s instance=%llu callback=%s",
            playerId,
            cand.groupName.c_str(),
            static_cast<unsigned long long>(cand.instanceId),
            cbDestroy.c_str()
        );
        return false;
    }

    MarkGroupDestroyed(*postCtx, *postCandidate);

    Debug("EvictCandidate success playerid=%d group=%s instance=%llu activeTD=%u",
        playerId,
        cand.groupName.c_str(),
        static_cast<unsigned long long>(cand.instanceId),
        postCtx->activeTextDrawCount
    );

    return true;
}

bool SUICore::EvictOneHiddenGroup(PlayerContext& ctx)
{
    auto candidates = CollectEligibleEvictionCandidates(ctx);
    if (candidates.empty())
    {
        return false;
    }
    return EvictCandidate(ctx, candidates.front());
}

bool SUICore::EnsureCapacity(PlayerContext& ctx, uint32_t requiredSize)
{
    int playerId = ctx.playerId;

    if (requiredSize == 0)
    {
        requiredSize = 1;
    }

    auto* currentCtx = GetPlayerContext(playerId);
    if (!currentCtx || currentCtx->teardownState != PlayerTeardownState::None)
    {
        return false;
    }

    if (requiredSize > currentCtx->maxTextDraws)
    {
        Debug("EnsureCapacity failed: requiredSize (%u) exceeds maxTextDraws (%u) playerid=%d",
            requiredSize, currentCtx->maxTextDraws, playerId);
        return false;
    }

    // Keep track of attempted candidate instance IDs so we don't attempt the same failed candidate in an infinite loop
    std::vector<std::pair<std::string, uint64_t>> attemptedCandidates;

    while (true)
    {
        currentCtx = GetPlayerContext(playerId);
        if (!currentCtx || currentCtx->teardownState != PlayerTeardownState::None)
        {
            return false;
        }

        uint64_t total = static_cast<uint64_t>(currentCtx->activeTextDrawCount) + static_cast<uint64_t>(requiredSize);
        uint64_t targetCeiling = std::min(static_cast<uint64_t>(currentCtx->evictionThreshold), static_cast<uint64_t>(currentCtx->maxTextDraws));

        if (total <= targetCeiling)
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

        uint64_t capacityNeeded = total - targetCeiling;

        Debug("EnsureCapacity needs eviction playerid=%d active=%u required=%u threshold=%u targetCeiling=%llu needed=%llu",
            playerId,
            currentCtx->activeTextDrawCount,
            requiredSize,
            currentCtx->evictionThreshold,
            static_cast<unsigned long long>(targetCeiling),
            static_cast<unsigned long long>(capacityNeeded)
        );

        auto candidates = CollectEligibleEvictionCandidates(*currentCtx);

        // Filter out any candidates that have already been attempted
        std::vector<EvictionCandidate> viableCandidates;
        uint64_t totalEligibleCapacity = 0;
        for (const auto& cand : candidates)
        {
            bool alreadyAttempted = false;
            for (const auto& att : attemptedCandidates)
            {
                if (att.first == cand.groupName && att.second == cand.instanceId)
                {
                    alreadyAttempted = true;
                    break;
                }
            }
            if (!alreadyAttempted)
            {
                viableCandidates.push_back(cand);
                totalEligibleCapacity += cand.estimatedSize;
            }
        }

        // PREFLIGHT CHECK: Can viable candidates satisfy the needed capacity?
        if (totalEligibleCapacity < capacityNeeded)
        {
            Debug("EnsureCapacity preflight failed: total eligible capacity (%llu) < capacity needed (%llu) playerid=%d active=%u required=%u threshold=%u",
                static_cast<unsigned long long>(totalEligibleCapacity),
                static_cast<unsigned long long>(capacityNeeded),
                playerId,
                currentCtx->activeTextDrawCount,
                requiredSize,
                currentCtx->evictionThreshold
            );
            return false;
        }

        const auto& nextToEvict = viableCandidates.front();
        attemptedCandidates.push_back({nextToEvict.groupName, nextToEvict.instanceId});

        if (!EvictCandidate(*currentCtx, nextToEvict))
        {
            Debug("EnsureCapacity: candidate eviction failed or group was mutated during callback playerid=%d group=%s instance=%llu",
                playerId,
                nextToEvict.groupName.c_str(),
                static_cast<unsigned long long>(nextToEvict.instanceId)
            );
        }
    }
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

    if (ctx->teardownState != PlayerTeardownState::None)
    {
        Debug("DestroyGroup rejected: player %d is undergoing teardown", playerId);
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

    if (IsOwnerCleanupActive(itGroup->second.ownerAmx))
    {
        Debug("DestroyGroup rejected: group %s owner amx=%p is undergoing owner cleanup playerid=%d",
            groupName.c_str(), itGroup->second.ownerAmx, playerId);
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
        bool hideSuccess = CallPawnFunction(ownerAmx, playerId, cbHide).Success();

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
    bool destroySuccess = CallPawnFunction(ownerAmx, playerId, cbDestroy).Success();

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
    if (!Utils::IsValidPlayerId(playerId))
    {
        return false;
    }

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
    if (!Utils::IsValidPlayerId(playerId))
    {
        return false;
    }

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

    if (!Utils::IsValidPlayerId(playerId))
    {
        logprintf("[SUI] PrintPlayerState: invalid playerId %d.", playerId);
        return;
    }

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

bool SUICore::SetGroupEvictable(int playerId, const std::string& groupName, bool enabled)
{
    auto* ctx = GetPlayerContext(playerId);
    if (!ctx || ctx->teardownState != PlayerTeardownState::None)
    {
        Debug("SetGroupEvictable failed: player context not found or in teardown playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return false;
    }

    auto it = ctx->groups.find(groupName);
    if (it == ctx->groups.end())
    {
        Debug("SetGroupEvictable failed: group not found playerid=%d group=%s",
            playerId,
            groupName.c_str()
        );
        return false;
    }

    if (IsOwnerCleanupActive(it->second.ownerAmx))
    {
        Debug("SetGroupEvictable rejected: group %s owner amx=%p is undergoing owner cleanup playerid=%d",
            groupName.c_str(), it->second.ownerAmx, playerId);
        return false;
    }

    it->second.evictable = enabled;

    Debug("SetGroupEvictable playerid=%d group=%s enabled=%d",
        playerId,
        groupName.c_str(),
        enabled ? 1 : 0
    );
    return true;
}

bool SUICore::IsGroupEvictable(int playerId, const std::string& groupName)
{
    if (!Utils::IsValidPlayerId(playerId))
    {
        return false;
    }

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
    if (!Utils::IsValidPlayerId(playerId))
    {
        Debug("TouchGroup rejected: invalid playerId=%d", playerId);
        return false;
    }

    auto itPlayer = players.find(playerId);
    if (itPlayer == players.end() || itPlayer->second.teardownState != PlayerTeardownState::None)
    {
        Debug("TouchGroup failed: player context not found or in teardown playerid=%d group=%s",
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

    if (IsOwnerCleanupActive(group.ownerAmx))
    {
        Debug("TouchGroup rejected: group %s owner amx=%p is undergoing owner cleanup playerid=%d",
            groupName.c_str(), group.ownerAmx, playerId);
        return false;
    }

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

PawnCallResult SUICore::CallPawnFunction(AMX* ownerAmx, int playerId, const std::string& functionName)
{
    PawnCallResult result;

    if (!ownerAmx)
    {
        Debug("CallPawnFunction failed: null ownerAmx playerid=%d function=%s", playerId, functionName.c_str());
        return result;
    }

    if (!IsAmxActive(ownerAmx))
    {
        Debug("CallPawnFunction failed: ownerAmx %p is not active playerid=%d function=%s",
            ownerAmx, playerId, functionName.c_str());
        return result;
    }

    if (functionName.empty())
    {
        Debug("CallPawnFunction failed: empty function name playerid=%d", playerId);
        return result;
    }

    Debug("CallPawnFunction searching public=%s playerid=%d ownerAmx=%p",
        functionName.c_str(),
        playerId,
        ownerAmx
    );

    int index = -1;
    int findResult = amx_FindPublic(ownerAmx, functionName.c_str(), &index);

    if (findResult != AMX_ERR_NONE)
    {
        result.found = false;
        result.amxError = findResult;
        Debug("CallPawnFunction failed: public callback not found in owner AMX: %s (err=%d)",
            functionName.c_str(), findResult);
        return result;
    }

    result.found = true;
    amx_Push(ownerAmx, static_cast<cell>(playerId));

    cell retval = 0;
    int execResult = amx_Exec(ownerAmx, &retval, index);

    result.executed = true;
    result.amxError = execResult;
    result.retval = retval;

    if (execResult == AMX_ERR_NONE)
    {
        Debug("CallPawnFunction success: public=%s playerid=%d retval=%d",
            functionName.c_str(),
            playerId,
            static_cast<int>(retval)
        );
    }
    else
    {
        Debug("CallPawnFunction failed: amx_Exec error public=%s playerid=%d err=%d retval=%d",
            functionName.c_str(),
            playerId,
            execResult,
            static_cast<int>(retval)
        );
    }

    return result;
}