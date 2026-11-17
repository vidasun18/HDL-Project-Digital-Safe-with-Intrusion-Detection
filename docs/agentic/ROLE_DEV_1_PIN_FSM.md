# Developer 1 - PIN Entry and Basic Safe Control

**Assigned:** PIN checking, button debounce, PIN capture, main FSM. **Not assigned:** top-level wiring, timers, intrusions, display, XDC.

## Files owned

`rtl/button_debounce.v`, `rtl/pin_capture.v`, `rtl/pin_compare.v`, `rtl/safe_fsm.v`, and unit tests in `tests/tb_button_debounce.v`, `tests/tb_pin_capture.v`, `tests/tb_safe_fsm.v`.

## Implementation sequence and reviewable commits

1. Reset outputs: FSM reset state LOCKED and never unlock on reset. `feat(fsm): initialize the safe in locked state`.
2. PIN matcher: 16-bit configurable `USER_PIN`, no hidden hardcoded comparison. `feat(pin): compare a captured hexadecimal PIN`.
3. Debouncer: 2-flop input synchronizer, configurable stable cycles, one pulse per press including held/released/bouncy transitions. `feat(input): debounce board buttons into one-cycle pulses`.
4. Capture: take a stable sampled SW value on `submit_pulse`, issue `captured_valid` exactly once. `feat(pin): capture switches when submit is pressed`.
5. Unlock: enter CHECKING and unlock only when valid PIN, no alarm/lockout/tamper. `feat(fsm): unlock after a verified PIN`.
6. Manual relock: BTND event sends UNLOCKED -> LOCKED. `feat(fsm): relock on down-button pulse`.
7. Alarm and recovery integration: accept `third_failure`, `tamper_pulse`, `tamper_latched`, timer-done signals, admin_recover_pulse per contract; state sequence must satisfy architecture.

## Tests you must implement

Reset from each state; incorrect PIN never unlocks; correct PIN unlocks exactly once; switch changes without submission cannot unlock; two held submit cycles create only one capture; bounce transitions create no false pulses; third wrong submission enters ALARM not fourth; wrong PIN ignored in ALARM/LOCKOUT; relock works; tamper has priority; authorized recovery ends LOCKED not UNLOCKED; tamper latch blocks ordinary PIN.

## Start command for agent

Read `AGENTS.md`, `docs/agentic/INTERFACE_CONTRACTS.md` and this file. Inspect existing top-level first. Build ONLY one owned module at a time with a self-checking testbench. Do not rewrite `digital_safe.v`. Show exact compiler/test invocation and a diff summary; ask human approval before Git write.

## Handoff to manager

Module ports + timing diagram of capture/compare/CHECKING; how wrong/correct pulses align; `third_failure` timing; own test logs; documented assumptions and exact dependency list.
