namespace Compat {
    inline int GetString(AMX* amx, cell param, char* dest, size_t maxlen) {
        cell* addr = nullptr;
        amx_GetAddr(amx, param, &addr);
        return amx_GetString(dest, addr, 0, maxlen);

        // Fallback if your SDK has a different AMX signature:
        // return amx_GetString(amx, param, dest, maxlen);
    }

    inline int RegisterNatives(AMX* amx, const AMX_NATIVE_INFO* natives, int number) {
        return amx_Register(amx, natives, number);

        // Fallback if your SDK expects mutable AMX_NATIVE_INFO*:
        // return amx_Register(amx, const_cast<AMX_NATIVE_INFO*>(natives), number);
    }
}
