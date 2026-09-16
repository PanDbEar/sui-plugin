# Permanent Test Suite 13: Callback Error Recovery (F1–F14)

## Purpose
Validates lifecycle recovery, internal quarantine, and compensating destroy when an AMX callback (specifically `cbCreate`) starts executing, mutates external host UI state (such as allocating SA-MP `PlayerTextDraw` handles), and aborts due to an unhandled AMX runtime error or accounting commit rejection before completion (SUI-018).

## Test Matrix (F1–F14)
- **F1**: Failed cbCreate produces recovery quarantine
- **F2**: Failed cbCreate does not debit capacity
- **F3**: Immediate compensating destroy success
- **F4**: Compensating destroy failure retains quarantine
- **F5**: Quarantined group rejects repeated ShowGroup
- **F6**: Manual DestroyGroup retries compensation and clears quarantine
- **F7**: CleanupOwnerGroups retries compensation
- **F8**: CleanupPlayer terminal compensation
- **F9**: ResetPlayer preserves failed recovery group
- **F10**: TRUE ABA / replacement-generation isolation
- **F11**: Cross-AMX isolation during recovery
- **F12**: Real PlayerTextDraw exact-handle reuse across cooperative recovery cycles
- **F13**: Untracked-local-handle limitation reproduction
- **F14**: Post-create accounting-commit failure compensation
