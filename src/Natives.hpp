#pragma once
#include "plugincommon.h"
#include "amx/amx.h"

namespace Natives {
    cell AMX_NATIVE_CALL SUI_SetDebug(AMX* amx, cell* params);
    cell AMX_NATIVE_CALL SUI_CreatePlayerFactoryGroup(AMX* amx, cell* params);
    cell AMX_NATIVE_CALL SUI_ShowGroup(AMX* amx, cell* params);
    cell AMX_NATIVE_CALL SUI_HideGroup(AMX* amx, cell* params);
    cell AMX_NATIVE_CALL SUI_SetIdleTimeout(AMX* amx, cell* params);
    cell AMX_NATIVE_CALL SUI_CleanupPlayer(AMX* amx, cell* params);
    cell AMX_NATIVE_CALL SUI_ResetPlayer(AMX* amx, cell* params);
    cell AMX_NATIVE_CALL SUI_SetGroupSize(AMX* amx, cell* params);
    cell AMX_NATIVE_CALL SUI_GetActiveTextDrawCount(AMX* amx, cell* params);
    cell AMX_NATIVE_CALL SUI_SetMaxTextDraws(AMX* amx, cell* params);
    cell AMX_NATIVE_CALL SUI_SetEvictionThreshold(AMX* amx, cell* params);
    cell AMX_NATIVE_CALL SUI_SetGroupPriority(AMX* amx, cell* params);
    cell AMX_NATIVE_CALL SUI_DestroyGroup(AMX* amx, cell* params);
    cell AMX_NATIVE_CALL SUI_IsGroupCreated(AMX* amx, cell* params);
    cell AMX_NATIVE_CALL SUI_IsGroupVisible(AMX* amx, cell* params);
    cell AMX_NATIVE_CALL SUI_PrintPlayerState(AMX* amx, cell* params);
    cell AMX_NATIVE_CALL SUI_SetGroupEvictable(AMX* amx, cell* params);
    cell AMX_NATIVE_CALL SUI_IsGroupEvictable(AMX* amx, cell* params);
    cell AMX_NATIVE_CALL SUI_TouchGroup(AMX* amx, cell* params);
    cell AMX_NATIVE_CALL SUI_CleanupOwnerGroups(AMX* amx, cell* params);
}