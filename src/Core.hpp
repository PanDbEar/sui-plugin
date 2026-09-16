#pragma once
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>
#include "plugincommon.h"
#include "amx/amx.h"

enum SUIPriority : uint8_t {
    SUI_PRIORITY_LOW = 0,
    SUI_PRIORITY_NORMAL = 1,
    SUI_PRIORITY_HIGH = 2,
    SUI_PRIORITY_CRITICAL = 3
};

struct SUIGroup {
    std::string name;
    uint64_t instanceId = 0;

    std::string cbCreate;
    std::string cbDestroy;
    std::string cbShow;
    std::string cbHide;

    bool isCreated = false;
    bool isVisible = false;
    uint64_t hiddenSinceTick = 0;
    uint64_t lastUsedTick = 0;
    uint32_t idleTimeoutMs = 30000;

    uint32_t estimatedSize = 1;
    uint8_t priority = SUI_PRIORITY_NORMAL;
    bool evictable = true;

    bool isExecutingCallback = false;

    // Non-owning pointer to the AMX script instance that registered this group.
    // Lifecycle is managed by the host server; purged during AmxUnload.
    AMX* ownerAmx = nullptr;
};

enum class PlayerTeardownState : uint8_t {
    None = 0,
    Cleanup,
    Reset
};

struct PlayerContext {
    int playerId = -1;
    uint32_t activeTextDrawCount = 0;
    uint32_t maxTextDraws = 256;
    uint32_t evictionThreshold = 230;

    PlayerTeardownState teardownState = PlayerTeardownState::None;

    std::unordered_map<std::string, SUIGroup> groups;
};

struct PawnCallResult {
    bool found = false;
    bool executed = false;
    int amxError = AMX_ERR_NONE;
    cell retval = 0;

    bool Success() const {
        return found && executed && amxError == AMX_ERR_NONE;
    }
};

struct EvictionCandidate {
    std::string groupName;
    uint64_t instanceId = 0;
    uint32_t estimatedSize = 0;
    uint8_t priority = 0;
    uint64_t lastUsedTick = 0;
};

class SUICore {
public:
    static std::unordered_map<int, PlayerContext> players;
    static std::vector<AMX*> activeAmxInstances;
    static std::unordered_set<AMX*> ownerCleanupActive;
    static bool debugEnabled;
    static uint64_t nextGroupInstanceId;

    static void Debug(const char* format, ...);
    static void SetDebug(bool enabled);

    static bool TryAllocateGroupInstanceId(uint64_t& outId);
    static uint64_t AllocateGroupInstanceId();
    static bool IsAmxActive(AMX* amx);
    static bool IsOwnerCleanupActive(AMX* amx);
    static void UnloadAmx(AMX* amx);
    static bool CleanupOwnerGroups(AMX* ownerAmx);

    static PlayerContext* GetPlayerContext(int playerId);
    static SUIGroup* GetPlayerGroup(int playerId, const std::string& groupName);
    static SUIGroup* GetPlayerGroupIfInstance(int playerId, const std::string& groupName, uint64_t instanceId);

    static void ProcessTick(uint64_t currentTick);
    
    static bool RegisterFactoryGroup(AMX* amx, int playerId, const std::string& group, 
                                     const std::string& cbCreate, const std::string& cbDestroy, 
                                     const std::string& cbShow, const std::string& cbHide);
                                     
    static bool ShowGroup(int playerId, const std::string& groupName);
    static bool HideGroup(int playerId, const std::string& groupName);
    
    static void SetIdleTimeout(int playerId, const std::string& groupName, uint32_t timeoutMs);
    
    static bool CleanupPlayer(int playerId);
    static bool ResetPlayer(int playerId);

    static bool SetGroupSize(int playerId, const std::string& groupName, uint32_t size);
    static uint32_t GetActiveTextDrawCount(int playerId);
    static bool TryAddActiveTextDrawCount(PlayerContext& ctx, uint32_t amount);
    static void AddActiveTextDrawCount(PlayerContext& ctx, uint32_t amount);
    static void SubtractActiveTextDrawCount(PlayerContext& ctx, uint32_t amount);
    static bool RecalculateActiveTextDrawCount(PlayerContext& ctx);
    static bool SetMaxTextDraws(int playerId, uint32_t maxCount);
    static bool SetEvictionThreshold(int playerId, uint32_t threshold);
    static void SetGroupPriority(int playerId, const std::string& groupName, uint8_t priority);
    static std::vector<EvictionCandidate> CollectEligibleEvictionCandidates(const PlayerContext& ctx);
    static bool EvictCandidate(PlayerContext& ctx, const EvictionCandidate& candidate);
    static bool EnsureCapacity(PlayerContext& ctx, uint32_t requiredSize);
    static bool EvictOneHiddenGroup(PlayerContext& ctx);
    static void MarkGroupDestroyed(PlayerContext& ctx, SUIGroup& group);
    static bool DestroyGroup(int playerId, const std::string& groupName);
    static bool DestroyGroupInternal(PlayerContext& ctx, SUIGroup& group, const std::string& groupName);
    static bool IsGroupCreated(int playerId, const std::string& groupName);
    static bool IsGroupVisible(int playerId, const std::string& groupName);
    static void PrintPlayerState(int playerId);

    static void SetGroupEvictable(int playerId, const std::string& groupName, bool enabled);
    static bool IsGroupEvictable(int playerId, const std::string& groupName);

    static bool TouchGroup(int playerId, const std::string& groupName);

    static PawnCallResult CallPawnFunction(AMX* ownerAmx, int playerId, const std::string& functionName);
};