# SUI-007: Capacity Eviction Preflight and Safety Test Plan

## Objective
Verify that capacity eviction in SUI operates under non-destructive preflight guarantees:
Before any existing hidden UI group is destroyed for an incoming capacity reservation, SUI must prove that the currently eligible eviction set can satisfy that request under the current eviction policy. If eligible capacity is insufficient, SUI must return `false`, destroy NOTHING, invoke NO eviction callbacks, and preserve all existing groups.

## Test Matrix (E1 – E14)

| Test ID | Category | Description | Success Criteria |
|---|---|---|---|
| **E1** | Sufficiency Preflight | Single eligible candidate with insufficient capacity | `ShowGroup` returns 0; candidate destroy callback = 0 calls; candidate preserved; active count unchanged. |
| **E2** | Sufficiency Preflight | Multiple eligible candidates whose sum is insufficient | `ShowGroup` returns 0; 0 destroy callbacks across all candidates; all preserved; active count unchanged. |
| **E3** | Minimal Planning | Request requires less than total eligible capacity | Exactly minimal number of candidates destroyed to satisfy requirement; no over-eviction. |
| **E4** | Multi-Candidate Eviction | Request requires multiple candidates to satisfy | Candidates evicted sequentially in deterministic order; subsequent candidates preserved once capacity is satisfied. |
| **E5** | Priority Ordering | LOW priority candidate evicted before NORMAL and HIGH | LOW priority candidate evicted despite having newer tick than NORMAL/HIGH candidates. |
| **E6** | Age Ordering | Oldest candidate evicted first within same priority | Candidate with older `lastUsedTick` evicted before candidate with newer tick. |
| **E7** | Deterministic Tie-Breaker | Alphabetical tie-breaker for identical priority & tick | "alpha" candidate evicted before "zeta" candidate deterministically. |
| **E8** | Eligibility Exclusion | `SUI_PRIORITY_CRITICAL` groups excluded | CRITICAL groups are never counted in preflight or evicted; request fails; CRITICAL group preserved. |
| **E9** | Eligibility Exclusion | Visible groups excluded | Visible groups are never counted in preflight or evicted; request fails; visible group preserved. |
| **E10** | Eligibility Exclusion | Non-evictable (`SUI_SetGroupEvictable(..., false)`) groups excluded | Non-evictable groups are excluded from preflight and eviction; request fails; group preserved. |
| **E11** | Eligibility Exclusion | Re-entrant / currently executing callback groups excluded | Group currently executing a callback cannot be counted or evicted (cannot evict itself). |
| **E12** | Destroy Callback Failure | Candidate destroy callback runtime failure | Group preserved; active count NOT decremented; replanning avoids infinite loop; request fails safely. |
| **E13** | Re-entrant Mutation | Callback mutates another group's evictable flag during eviction | Replanning discovers remaining capacity insufficient; aborts cleanly; mutated group preserved. |
| **E14** | Multi-AMX Ownership | Evicting candidate registered by Filterscript from Gamemode | Filterscript's `cbDestroy` called in its AMX context; group evicted; gamemode group shown; active count reconciled. |
