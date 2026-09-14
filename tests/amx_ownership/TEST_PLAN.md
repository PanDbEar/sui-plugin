# SUI-002 AMX Ownership & Callback Isolation Test Plan

This document defines the multi-AMX test suite designed to verify **SUI-002** (AMX Ownership, Callback Isolation, and Safe AMX Unload).

---

## 1. Objectives

1. **Owner-Bound Callback Dispatch**:
   Verify that callbacks registered by an AMX instance (Gamemode or Filterscript) are dispatched exclusively to that specific AMX instance.
2. **Strict Callback Isolation**:
   Verify that when two distinct scripts (e.g. Gamemode and Filterscript) register groups pointing to identical public callback names (e.g., SharedCallback), SUI never crosses script boundaries.
3. **No Cross-Script Fallback on Missing Callback**:
   Verify that if an owner script registers a callback name that does not exist in the owner AMX but exists in another loaded AMX, SUI fails gracefully and never invokes the callback in the foreign AMX.
4. **Safe AMX Unload & Resource Accounting**:
   Verify that when a filterscript is dynamically unloaded:
   - All SUI groups owned by the unloading AMX are purged.
   - ctiveTextDrawCount is decremented by the estimated size of created groups owned by the unloaded AMX.
   - Other AMX instances (e.g., the Gamemode) and their groups remain completely unharmed and functional.
   - SUI does not crash or execute dangling callbacks.
5. **Anti-Hijacking Registration Protection**:
   Verify that if an AMX attempts to register a group name that is already owned by a different active AMX, SUI rejects the registration (SUI_CreatePlayerFactoryGroup returns 0).

---

## 2. Test Suite Architecture

The test suite consists of two scripts running simultaneously in a live SA-MP server:

1. **ownership_gamemode.pwn**:
   The primary test harness. Manages the test state machine, executes test cases A1 through A6, inspects counters, issues RCON commands to unload the filterscript, and reports final PASS/FAIL results.
2. **ownership_filterscript.pwn**:
   A secondary AMX instance. Registers filterscript-owned groups, defines callbacks (including identical names like SharedCallback and exclusive callbacks like OnlyInFilterscript), and logs its lifecycle events.

---

## 3. Test Cases Specification

### Test A1: Gamemode-Owned Group Callback
- **Action**: Gamemode registers gm_group with OnGmGroup_Create, OnGmGroup_Show. Calls SUI_ShowGroup(0, gm_group).
- **Assertion**: Gamemode callback counters increment. Filterscript callbacks are not invoked. Group becomes created and visible.

### Test A2: Callback Name Collision Isolation
- **Action**: Both Gamemode and Filterscript define a public callback named SharedCallback(playerid).
  - Gamemode registers gm_shared_grp with SharedCallback.
  - Filterscript registers s_shared_grp with SharedCallback.
  - Gamemode shows gm_shared_grp, then shows s_shared_grp.
- **Assertion**: Showing gm_shared_grp increments ONLY Gamemode's counter. Showing s_shared_grp increments ONLY Filterscript's counter. Neither script leaks into the other.

### Test A3: Missing Callback in Owner (No Cross-AMX Fallback)
- **Action**: Filterscript defines OnlyInFilterscript(playerid). Gamemode does NOT define it.
  - Gamemode registers gm_missing_cb specifying OnlyInFilterscript as cbCreate.
  - Gamemode calls SUI_ShowGroup(0, gm_missing_cb).
- **Assertion**: SUI fails to find the callback in Gamemode's AMX and returns failure. Filterscript's OnlyInFilterscript is NEVER called (counter remains 0).

### Test A4: Anti-Hijacking Registration Guard
- **Action**: Gamemode registers locked_gm_grp. Filterscript attempts to register locked_gm_grp with its own callbacks.
- **Assertion**: Filterscript's SUI_CreatePlayerFactoryGroup call returns 0. Gamemode retains sole ownership.

### Test A5: Safe Dynamic AMX Unload & Capacity Repair
- **Action**:
  - Filterscript registers and shows s_active_grp with size = 15.
  - Gamemode registers and shows gm_perm_grp with size = 10.
  - Initial active textdraw count is 25.
  - Gamemode executes SendRconCommand(unloadfs ownership_filterscript).
- **Assertion**:
  - Filterscript AmxUnload triggers SUICore::UnloadAmx.
  - s_active_grp is purged from player context.
  - ctiveTextDrawCount drops by 15 to exactly 10.
  - gm_perm_grp remains created and visible.
  - SUI_IsGroupCreated(0, fs_active_grp) returns 0.
  - SUI_IsGroupCreated(0, gm_perm_grp) returns 1.

### Test A6: Post-Unload Group Re-registration & Immunity
- **Action**: After Filterscript unloads, Gamemode attempts to register a new group using the previously freed name fs_active_grp.
- **Assertion**: Registration succeeds because the previous owner AMX is gone and the group was purged. Showing the new group works properly.

### Test A7: Anti-Hijacking Guard During Callback Execution
- **Action**: Gamemode registers `a7_gm_grp`. While Gamemode's `OnGmA7_Create` callback is actively executing, Filterscript calls `SUI_CreatePlayerFactoryGroup` attempting to hijack `a7_gm_grp`.
- **Assertion**: Filterscript's registration returns 0. Gamemode retains sole ownership, completes callback execution, and group becomes created/visible. Callback-window hijacking is completely blocked.

