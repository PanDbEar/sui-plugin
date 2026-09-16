# Permanent Test Suite 13: Callback Error Recovery (F1–F12)

## Purpose
Validates lifecycle recovery, internal quarantine, and compensating destroy when an AMX callback (specifically `cbCreate`) starts executing, mutates external host UI state (such as allocating SA-MP `PlayerTextDraw` handles), and aborts due to an unhandled AMX runtime error before completion (SUI-018).

## Test Matrix (F1–F12)
- **F1**: Failed create produces recovery quarantine
- **F2**: Failed create does not debit capacity
- **F3**: Immediate compensating destroy success
- **F4**: Compensating destroy failure retains quarantine
- **F5**: Quarantined group cannot run create again
- **F6**: Manual DestroyGroup retries compensation and clears quarantine
- **F7**: Filterscript owner cleanup retries compensation
- **F8**: CleanupPlayer terminal compensation
- **F9**: ResetPlayer preserves failed recovery group
- **F10**: Instance replacement / ABA protection during compensation
- **F11**: Cross-AMX isolation during recovery
- **F12**: Real PlayerTextDraw handle reuse after recovered failure (exact handle reuse across 3 cycles)
