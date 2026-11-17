# Architecture and Functional Requirements

## The product

A four-person educational FPGA prototype of a laboratory/safe access-control system. It accepts a hexadecimal PIN from 16 slide switches, evaluates it on a debounced submit press, exposes lock/alarm status via LEDs and the onboard seven-segment display, counts failed attempts and detects tampering, provides alarm and timed lockout and permits authorized administrative recovery.

The current board interface is fixed by `digital_safe.v`. **No electric strike, motor, real door sensor, network, biometric sensor, keypad or battery-backed nonvolatile credentials are part of MVP.** Lock status is a simulated LED output only.

## Hardware and mapping

| Input | Function |
|---|---|
| `CLK100MHZ` | primary 100 MHz clock |
| `CPU_RESETN` | active-low global reset; on press return to LOCKED |
| `SW[15:0]` | 16-bit candidate PIN input, 4 hexadecimal digits |
| `BTNC` | submit PIN, one debounced pulse |
| `BTND` | manually relock |
| `BTNR` | trigger tamper alarm |
| `BTNL` | admin LEFT step |
| `BTNU` | admin UP step |
| `LED[0]` | locked indicator; high whenever not unlocked |
| `LED[1]` | simulated unlock indicator; high only UNLOCKED |
| `LED[2]` | alarm active / blinking indicator (state ALARM) |
| `LED[3]` | lockout indicator (state LOCKOUT) |
| `LED[5]` | tamper evidence latched |
| `LED[8:6]` | cumulative admin sequence progress: `001` after LEFT, `011` after LEFT-UP, `111` after LEFT-UP-LEFT; clear on final UP/recovery and reset |
| `LED[15:9]` | reserved for future integration; zero unless separately assigned |
| `SEG[6:0]`, `AN[7:0]`, `DP` | 8-digit multiplexed common-anode display; active low |

## States

`LOCKED=3'd0`, `CHECKING=3'd1`, `UNLOCKED=3'd2`, `ALARM=3'd3`, `LOCKOUT=3'd4`. Reset enters LOCKED. CHECKING is a one-/few-cycle processing state (not a timed state).

| State | Event | Next state / action |
|---|---|---|
| LOCKED | submit + correct PIN, no tamper latch | CHECKING then UNLOCKED; clear failures |
| LOCKED | submit + wrong PIN | CHECKING then LOCKED; increment failures |
| LOCKED / CHECKING | third wrong PIN | ALARM; start alarm timer |
| Any state except reset | tamper event | ALARM; latch tamper; never unlock |
| UNLOCKED | BTND relock | LOCKED |
| ALARM | alarm interval expires | LOCKOUT; start lockout timer |
| LOCKOUT | lockout interval expires | LOCKED; clear failed counter; if tamper still latched, ordinary PIN remains blocked |
| ALARM / LOCKOUT / LOCKED | authorized admin recovery | LOCKED; clear attempts and tamper latch; restart timers |

**Priority:** reset > tamper > validated admin recovery (admin must not cancel a simultaneous new tamper event) > timeouts > valid submit > manual relock. During ALARM/LOCKOUT, ordinary PIN submissions never unlock.

## Admin recovery

Button sequence LEFT, UP, LEFT, UP; each press must be debounced. Wrong step resets progress (or restarts at 1 if the wrong step is LEFT). Admin sequence confirmation additionally requires `SW[15:0] == ADMIN_CODE (16'hC0DE)` at the final UP pulse; denied attempts do not clear alarm. A valid recovery pulse always goes to LOCKED. This is a proposed safer demo rule and must be approved by the team before implementation.

## Alarm/time behavior

At 100 MHz, `tick_1hz` is high for one `CLK100MHZ` cycle approximately once per second; parameterize `CLK_HZ` to accelerate simulation. Defaults: `ALARM_SECONDS=2`, `LOCKOUT_SECONDS=15`, `DEBOUNCE_CYCLES=1_000_000`. Countdown components measure **clock-enable ticks**, not another clock domain.

## Visual display

Show state as a hexadecimal status nibble: LOCKED=1, CHECKING=C, UNLOCKED=2, ALARM=A, LOCKOUT=D. Use nibble 7 (AN7) for status, nibble 6 (AN6) for failed count (0..3), low nibbles for remaining seconds. `DP=1` (decimal points off); `AN` and `SEG` are active-low. If a more user-friendly display is added, keep a clearly documented testable encoding.

## Integration path

`buttons -> debounce -> PIN capture/compare + admin sequence + tamper latch -> safe_fsm -> status/LED/display`, while `failed_attempt_counter`, `tick_generator`, timers and blink indicator provide sideband control/status. Only Developer 4 owns final top-level instantiation and XDC.

## Definition of release

Self-checking tests pass; clock/reset/tamper behavior verified; Vivado synthesis/implementation complete for chosen 50T/100T part; pin mapping verified; real Nexys A7 demo recorded; docs accurately state prototype limitations.
