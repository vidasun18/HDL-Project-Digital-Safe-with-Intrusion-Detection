# Interface Contracts - Freeze Before Parallel Coding

**Canonical naming is mandatory** so modules compile together without edits. Verilog/SystemVerilog `wire` input/output signals unless declared `reg`. All sequential modules use `clk` positive edge and **active-high** `rst` (derived from top-level active-low `CPU_RESETN`). `rst` must clear state to locked/zero. Event signals (`*_pulse`, `*_done`) are high for exactly one clock period, unless explicitly marked as a level.

The root `digital_safe.v` top-level ports and parameters must remain exactly as in the current GitHub version. Existing `ADMIN_CODE` and `USER_PIN` are used, not removed.

## Top-level LED mapping

Preserve this mapping during display integration:

| Output | Function |
|---|---|
| `LED[0]` | locked indicator |
| `LED[1]` | simulated unlock indicator |
| `LED[2]` | alarm indicator |
| `LED[3]` | lockout indicator |
| `LED[4]` | reserved / unchanged |
| `LED[5]` | latched tamper evidence |
| `LED[6]` | admin progress after first LEFT |
| `LED[7]` | admin progress after LEFT-UP |
| `LED[8]` | admin progress after LEFT-UP-LEFT |
| `LED[15:9]` | reserved for final integration |

Admin progress LEDs are cumulative and clear when the final UP completes recovery, returning the safe to LOCKED. Do not repurpose LED5 or LED6-LED8 for seven-segment status.

## Shared state values

```verilog
localparam [2:0] LOCKED=3'd0, CHECKING=3'd1, UNLOCKED=3'd2,
                 ALARM=3'd3, LOCKOUT=3'd4;
```

## Developer 1: PIN and main FSM

```verilog
module button_debounce #(parameter integer DEBOUNCE_CYCLES=1000000)(
 input wire clk, input wire rst, input wire button_raw,
 output reg stable_level, output reg press_pulse);
// Synchronize button_raw with two flops inside the module.

module pin_capture(input wire clk, input wire rst,
 input wire submit_pulse, input wire [15:0] switch_value,
 output reg [15:0] captured_pin, output reg captured_valid);
// captured_valid pulses 1 cycle after a submit capture.

module pin_compare #(parameter [15:0] USER_PIN=16'hA5C3)(
 input wire [15:0] captured_pin, output wire pin_match);
// combinational, no bypass on state changes.

module safe_fsm(input wire clk, input wire rst,
 input wire submit_valid, input wire pin_match,
 input wire third_failure, input wire tamper_latched,
 input wire tamper_pulse, input wire admin_recover_pulse,
 input wire alarm_done, input wire lockout_done,
 input wire manual_relock_pulse,
 output reg [2:0] state,
 output reg wrong_pin_pulse, output reg correct_pin_pulse,
 output reg start_alarm_pulse, output reg start_lockout_pulse);
```

**FSM timing:** On `submit_valid` while LOCKED, transition to CHECKING and process `pin_match` on a registered next step (do not pulse before capture is valid). `wrong_pin_pulse` increments counter once per unsuccessful submission; `third_failure` is a combinational warning that the next wrong submission reaches 3, calculated by counter with `failed_count>=2`, so FSM enters ALARM at that event. `correct_pin_pulse` clears attempts. If tamper is latched, ordinary PIN cannot unlock even after lockout expiry; tamper always takes precedence. `start_alarm_pulse`/`start_lockout_pulse` start timers. These event pulses may be consumed in following clock cycle; write tests around exact registered pipeline latency.

## Developer 2: timing, attempts, alarm blink

```verilog
module tick_generator #(parameter integer CLK_HZ=100000000)(
 input wire clk, input wire rst, output reg tick_1hz);
// 1-cycle clock enable once every CLK_HZ positive edges.

module failed_attempt_counter(input wire clk, input wire rst,
 input wire wrong_pin_pulse, input wire clear_attempts,
 output reg [1:0] failed_count, output wire third_failure);
// third_failure HIGH when failed_count>=2, i.e., the NEXT wrong event is third.
// saturates at 3. clear_attempts wins over increment.

module countdown_timer #(parameter integer MAX_SECONDS=15)(
 input wire clk, input wire rst, input wire tick_1hz,
 input wire start_pulse, input wire cancel,
 input wire [7:0] duration_seconds,
 output reg [7:0] remaining_seconds, output reg done_pulse);
// Load duration on start; decrement at each tick; done once on last tick.
// Priority rst > cancel > start > tick; start cancels prior countdown.

module alarm_blinker(input wire clk, input wire rst,
 input wire tick_1hz, input wire alarm_active, output reg blink_led);
// blink_led = 0 outside ALARM; toggle on tick while alarm_active.
```

Use **two instances** of countdown_timer in the top-level: one for alarm, one for lockout. Both use the same tick enable. `duration_seconds` passes the truncated or clamped value of the top-level parameters; document the range 1..255 seconds (recommended). Do not generate a new clock.

## Developer 3: intrusion and admin

```verilog
module tamper_detector(input wire clk, input wire rst,
 input wire tamper_press_pulse, input wire clear_tamper,
 output reg tamper_latched, output reg tamper_event_pulse);
// clear_tamper only on reset or VALIDATED admin recovery.

module admin_sequence(input wire clk, input wire rst,
 input wire left_press_pulse, input wire up_press_pulse,
 output reg [1:0] progress, output reg sequence_done_pulse);
// LEFT -> UP -> LEFT -> UP. Wrong event restarts or resets.

module recovery_controller #(parameter [15:0] ADMIN_CODE=16'hC0DE)(
 input wire clk, input wire rst,
 input wire sequence_done_pulse, input wire [15:0] switch_value,
 output reg admin_recover_pulse);
// Must require code AND sequence. No recovery from buttons alone.
```

Suggested deconfliction: Manager owns debouncers and switch synchronizers in `digital_safe.v`; Dev3 consumes their pulses, never raw pushbuttons. `clear_tamper = admin_recover_pulse` (or reset).

## Developer 4: display + top-level

```verilog
module hex7seg(input wire [3:0] hex_digit, output reg [6:0] seg_n);
// seg_n[6:0] = {g,f,e,d,c,b,a} active LOW.

module sevenseg_mux #(parameter integer REFRESH_DIV=100000)(
 input wire clk, input wire rst, input wire [31:0] digits,
 output reg [6:0] SEG, output reg [7:0] AN, output wire DP);
// AN digit select is active LOW, DP=1. Divide must be >=1.

module display_formatter(input wire [2:0] state,
 input wire [1:0] failed_count,
 input wire [7:0] remaining_seconds,
 output reg [31:0] digits);
// digits[31:28] status; [27:24] failed count; [7:0] remaining hex seconds;
// remaining high display positions may show zero.
```

Top-level still named `digital_safe` with unchanged ports:

```verilog
module digital_safe #(
 parameter integer CLK_HZ=100_000_000,
 parameter integer DEBOUNCE_CYCLES=1_000_000,
 parameter integer ALARM_SECONDS=2,
 parameter integer LOCKOUT_SECONDS=15,
 parameter [15:0] USER_PIN=16'hA5C3,
 parameter [15:0] ADMIN_CODE=16'hC0DE
)(input wire CLK100MHZ, CPU_RESETN, input wire [15:0] SW,
 input wire BTNC,BTNU,BTNL,BTNR,BTND,
 output reg [15:0] LED, output wire [6:0] SEG,
 output wire [7:0] AN, output wire DP);
```

## Contract handling - IMPORTANT

This spec deliberately establishes ownership and expected events. There is one timing design choice requiring integration review: the exact CHECKING-to-UNLOCKED latency and registered counter interaction. Developers must publish a testbench timing trace with their PR; the manager may coordinate **small reviewed contract amendments** rather than independently renaming ports. Do not wire the third-failure flag after increment if it causes a fourth-attempt alarm.

**Potential clock crossing:** top-level slide switches and push buttons are asynchronous. Every button must pass the debouncer's two-flop synchronization. `SW` should pass a two-stage vector synchronizer in the top-level; allow inputs to settle before submission. The administrative code is sampled on sequence completion; document this sampling timing.
