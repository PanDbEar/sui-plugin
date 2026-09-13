#pragma once
#include <chrono>
#include <string>
#include "plugincommon.h"
#include "amx/amx.h"

namespace Utils {
    inline uint64_t GetTickCountMs() {
        auto now = std::chrono::steady_clock::now();
        return std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()).count();
    }

    inline std::string GetStringParam(AMX* amx, cell param) {
        cell* addr = nullptr;
        amx_GetAddr(amx, param, &addr);
        
        int len = 0;
        amx_StrLen(addr, &len);
        if (len <= 0) return "";
        
        std::string str(len + 1, '\0');
        amx_GetString(str.data(), addr, 0, len + 1);
        str.resize(len);
        return str;
    }

    inline bool CheckParams(cell* params, int expected) {
        return (params[0] / sizeof(cell)) >= expected;
    }
}