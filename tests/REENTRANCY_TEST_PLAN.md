# SUI Re-entrancy & Memory Safety Test Plan (SUI-001)

This document specifies regression testing scenarios designed to verify that SUI handles arbitrary Pawn callback re-entrancy, container modifications, and player teardown without memory corruption, iterator invalidation, or server crashes.

---

## Invariant Under Test

> **Phase 1 Memory Safety Invariant:**  
> No SUI runtime code may dereference or continue using an iterator, pointer, or reference into `players` or a player's `groups` container after executing arbitrary Pawn code unless the object has been safely revalidated and reacquired from stable identifiers (`playerId`, `groupName`).

---

## Scenario Specifications

### R1: Create Callback Calls `SUI_ResetPlayer`
- **Initial State:** Player `0` has group `"dialog_a"` registered but uncreated.
- **Trigger:** Server calls `SUI_ShowGroup(0, "dialog_a")`. SUI invokes `cbCreate`.
- **Re-entrant Action:** Inside `cbCreate`, the Pawn script invokes `SUI_ResetPlayer(0)`.
- **Hazard:** Erases player context from `players` map while `ShowGroup` holds active references.
- **Expected Result:**
  - `ShowGroup` detects `GetPlayerContext(0) == nullptr` immediately after `cbCreate`.
  - Terminates gracefully without dereferencing a dangling `PlayerContext` or `SUIGroup`.
  - No crash, no use-after-free.

---

### R2: Show Callback Calls `SUI_CleanupPlayer`
- **Initial State:** Player `0` has group `"dialog_a"` created (`isCreated == true`, `isVisible == false`).
- **Trigger:** SUI invokes `cbShow` during `SUI_ShowGroup(0, "dialog_a")`.
- **Re-entrant Action:** Inside `cbShow`, the Pawn script invokes `SUI_CleanupPlayer(0)`.
- **Hazard:** Player context is erased from `players`.
- **Expected Result:**
  - `ShowGroup` re-queries `GetPlayerGroup(0, "dialog_a")`, finding `nullptr`.
  - Skips updating `isVisible` or `lastUsedTick` on deallocated memory.
  - Returns safely without accessing freed memory.

---

### R3: Hide Callback Destroys Its Own Group
- **Initial State:** Group `"menu"` is visible (`isVisible == true`).
- **Trigger:** Script calls `SUI_HideGroup(0, "menu")`. SUI invokes `cbHide`.
- **Re-entrant Action:** Inside `cbHide`, the script calls `SUI_DestroyGroup(0, "menu")`.
- **Hazard:** The group being hidden is destroyed and marked uncreated/unallocated inside its own hide callback.
- **Expected Result:**
  - `HideGroup` re-acquires the group via `GetPlayerGroup(0, "menu")`.
  - If group was destroyed or altered, updates only valid fields or exits gracefully.
  - Clears recursion flag `isExecutingCallback = false`.

---

### R4: Destroy Callback Registers Another Group
- **Initial State:** Group `"login"` is destroyed (via `SUI_DestroyGroup` or idle timeout).
- **Trigger:** SUI invokes `cbDestroy` for `"login"`.
- **Re-entrant Action:** Inside `cbDestroy`, the script calls `SUI_CreatePlayerFactoryGroup(0, "main_hud", ...)`.
- **Hazard:** Inserting a new element into `ctx.groups` can trigger an `std::unordered_map` bucket rehash, invalidating all existing node pointers and iterators.
- **Expected Result:**
  - Calling function re-acquires `GetPlayerContext(0)` and re-finds `"login"` by key.
  - Traversal or caller continues cleanly.
  - Newly registered group `"main_hud"` remains valid and uncorrupted.

---

### R5: Destroy Callback Resets Player
- **Initial State:** Player `0` has groups `"g1"`, `"g2"`, `"g3"`. SUI is cleaning up or destroying `"g1"`.
- **Trigger:** SUI invokes `cbDestroy` for `"g1"`.
- **Re-entrant Action:** Inside `cbDestroy`, the script calls `SUI_ResetPlayer(0)`.
- **Hazard:** Outer cleanup loops holding iterators into `players` or `ctx.groups` encounter erased maps.
- **Expected Result:**
  - Key snapshotting in `CleanupPlayer` / `ResetPlayer` / `ProcessTick` detects `GetPlayerContext(0) == nullptr`.
  - Traversal breaks immediately; `players.erase(playerId)` by key avoids iterator invalidation.
  - No crash.

---

### R6: Callback Registers Enough Groups to Force Rehash
- **Initial State:** Group `"loader"` is created.
- **Trigger:** SUI invokes `cbCreate` or `cbShow`.
- **Re-entrant Action:** Pawn script executes a loop registering 50 new groups: `SUI_CreatePlayerFactoryGroup(0, "extra_X", ...)`.
- **Hazard:** Forces multiple bucket reallocations and rehashes of `ctx.groups`.
- **Expected Result:**
  - SUI does not retain raw references across the callback.
  - SUI re-acquires the original group using `GetPlayerGroup(0, "loader")`.
  - Operation completes successfully on the rehashed container.

---

### R7: ProcessTick Idle Destruction Invokes Callback That Mutates Groups
- **Initial State:** Multiple players and multiple groups in hidden idle state.
- **Trigger:** `ProcessTick` runs and finds group `"hud_idle"` has exceeded `idleTimeoutMs`.
- **Re-entrant Action:** Inside `cbDestroy`, the script calls `SUI_ShowGroup(0, "hud_active")` or `SUI_DestroyGroup(0, "other_group")`.
- **Hazard:** The active group map being traversed in `ProcessTick` is modified.
- **Expected Result:**
  - `ProcessTick` uses key snapshotting (`std::vector<std::string> candidateGroups`).
  - Re-evaluates each group's existence and state via `GetPlayerContext` and `ctx->groups.find(groupName)`.
  - Iteration proceeds through remaining candidates safely without iterator invalidation crashes.

---

### R8: ProcessTick Callback Removes Current Player Context
- **Initial State:** Group `"afk_ui"` reaches idle timeout during `ProcessTick`.
- **Trigger:** SUI invokes `cbDestroy`.
- **Re-entrant Action:** Inside `cbDestroy`, the script kicks or disconnects the player, calling `SUI_CleanupPlayer(playerid)`.
- **Hazard:** The current player's entry in `players` is erased while `ProcessTick` is processing that player.
- **Expected Result:**
  - `ProcessTick` re-checks `GetPlayerContext(playerId)`.
  - Detects `nullptr`, aborts processing for that player, and continues safely to the next `playerId` in `playerIds` snapshot.

---

### R9: Nested Same-Group Operation
- **Initial State:** Group `"profile"` is uncreated.
- **Trigger:** `SUI_ShowGroup(0, "profile")` invokes `cbCreate`.
- **Re-entrant Action:** Inside `cbCreate`, the script calls `SUI_ShowGroup(0, "profile")` again.
- **Hazard:** Infinite recursion leading to stack overflow.
- **Expected Result:**
  - SUI detects `group.isExecutingCallback == true`.
  - Logs `[SUI-DEBUG] ShowGroup blocked recursion` and returns immediately.
  - No stack overflow, no state corruption.

---

### R10: Nested Operation Affecting a Different Group
- **Initial State:** Group `"inventory"` is being shown; group `"equipment"` is currently hidden.
- **Trigger:** `SUI_ShowGroup(0, "inventory")` invokes `cbShow`.
- **Re-entrant Action:** Inside `cbShow`, the script calls `SUI_ShowGroup(0, "equipment")`.
- **Hazard:** Cross-group state updates altering `PlayerContext::activeTextDrawCount` and capacity thresholds.
- **Expected Result:**
  - `"equipment"` executes its show routine cleanly.
  - Outer `"inventory"` show routine resumes, re-acquires its own context, and finalizes its state without conflict.
