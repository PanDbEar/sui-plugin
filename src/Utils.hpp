#pragma once
#include <chrono>
#include <string>
#include <vector>
#include "plugincommon.h"
#include "amx/amx.h"
#include "Core.hpp"

namespace Utils {
    inline uint64_t GetTickCountMs() {
        auto now = std::chrono::steady_clock::now();
        return std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()).count();
    }

    inline bool CheckParams(cell* params, int expected) {
        if (!params) return false;
        if (params[0] < 0) return false;
        return (params[0] / static_cast<cell>(sizeof(cell))) >= expected;
    }

    inline bool TryGetNonNegativeUInt32(cell value, uint32_t& out) {
        if (value < 0) {
            return false;
        }
        out = static_cast<uint32_t>(value);
        return true;
    }

    inline bool TryGetPriority(cell value, uint8_t& out) {
        if (value < SUI_PRIORITY_LOW || value > SUI_PRIORITY_CRITICAL) {
            return false;
        }
        out = static_cast<uint8_t>(value);
        return true;
    }

    inline bool TryGetStringParam(AMX* amx, cell param, std::string& out) {
        if (!amx) return false;

        cell* addr = nullptr;
        int err = amx_GetAddr(amx, param, &addr);
        if (err != AMX_ERR_NONE || addr == nullptr) {
            return false;
        }

        int len = 0;
        err = amx_StrLen(addr, &len);
        if (err != AMX_ERR_NONE || len < 0) {
            return false;
        }

        if (len == 0) {
            out.clear();
            return true;
        }

        std::vector<char> buffer(static_cast<size_t>(len) + 1, '\0');
        err = amx_GetString(buffer.data(), addr, 0, buffer.size());
        if (err != AMX_ERR_NONE) {
            out.clear();
            return false;
        }

        out.assign(buffer.data(), static_cast<size_t>(len));
        return true;
    }

    inline std::string GetStringParam(AMX* amx, cell param) {
        std::string res;
        TryGetStringParam(amx, param, res);
        return res;
    }
}