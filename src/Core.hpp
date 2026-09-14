#pragma once
#include <string>
#include <unordered_map>
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

struct PlayerContext {
    int playerId = -1;
    uint32_t activeTextDrawCount = 0;
    uint32_t maxTextDraws = 256;
    uint32_t evictionThreshold = 230;

    std::unordered_map<std::string, SUIGroup> groups;
};

class SUICore {
public:
    static std::unordered_map<int, PlayerContext> players;
    static std::vector<AMX*> activeAmxInstances;
    static bool debugEnabled;

    static void Debug(const char* format, ...);
    static void SetDebug(bool enabled);

    static bool IsAmxActive(AMX* amx);
    static void UnloadAmx(AMX* amx);

    static PlayerContext* GetPlayerContext(int playerId);
    static SUIGroup* GetPlayerGroup(int playerId, const std::string& groupName);

    static void ProcessTick(uint64_t currentTick);
    
    static bool RegisterFactoryGroup(AMX* amx, int playerId, const std::string& group, 
                                     const std::string& cbCreate, const std::string& cbDestroy, 
                                     const std::string& cbShow, const std::string& cbHide);
                                     
    static void ShowGroup(int playerId, const std::string& groupName);
    static void HideGroup(int playerId, const std::string& groupName);
    
    static void SetIdleTimeout(int playerId, const std::string& groupName, uint32_t timeoutMs);
    
    static void CleanupPlayer(int playerId);
    static void ResetPlayer(int playerId);

    static bool SetGroupSize(int playerId, const std::string& groupName, uint32_t size);
    static uint32_t GetActiveTextDrawCount(int playerId);
    static bool TryAddActiveTextDrawCount(PlayerContext& ctx, uint32_t amount);
    static void AddActiveTextDrawCount(PlayerContext& ctx, uint32_t amount);
    static void SubtractActiveTextDrawCount(PlayerContext& ctx, uint32_t amount);
    static bool RecalculateActiveTextDrawCount(PlayerContext& ctx);
    static bool SetMaxTextDraws(int playerId, uint32_t maxCount);
    static bool SetEvictionThreshold(int playerId, uint32_t threshold);
    static void SetGroupPriority(int playerId, const std::string& groupName, uint8_t priority);
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

    static bool CallPawnFunction(AMX* ownerAmx, int playerId, const std::string& functionName);
};