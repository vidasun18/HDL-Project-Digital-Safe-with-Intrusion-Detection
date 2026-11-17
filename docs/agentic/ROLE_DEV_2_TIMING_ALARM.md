# Developer 2 - Failed Attempts, Timing and Alarm

**Assigned:** failed attempts, clock enable generation, reusable timers, blinking alarm. **Not assigned:** FSM ownership, tamper latch/admin logic, board display/XDC.

## Files owned

`rtl/failed_attempt_counter.v`, `rtl/tick_generator.v`, `rtl/countdown_timer.v`, `rtl/alarm_blinker.v`; `tests/tb_failed_attempt_counter.v`, `tests/tb_tick_generator.v`, `tests/tb_countdown_timer.v`, `tests/tb_alarm_blinker.v`.

## Ordered features

1. Saturating 0..3 attempt counter, `third_failure=(failed_count>=2)`. `feat(security): count failed PIN submissions`.
2. `CLK_HZ` parameter enables one-cycle `tick_1hz` every second. Default 100,000,000 cycles, test with 5/10. **No newly derived clock.** `feat(time): add configurable one-second clock enable`.
3. Countdown timer with `start_pulse`, `cancel`, tick, load/reload, one-cycle `done_pulse`, `remaining_seconds` 8-bit. Support 1..255 seconds. `feat(time): implement reusable countdown timer`.
4. Two timer contexts: alarm delay 2 sec and lockout 15 sec, integration through Dev4 top. Provide usage snippet, not top-level edits. `feat(alarm): define alarm and lockout timing behavior`.
5. Alarm LED toggles only while ALARM active and resets off when alarm ends. `feat(alarm): blink the alarm indicator`.

## Contract responsibilities

`third_failure` HIGH *before* increment when count is already 2. Dev1 FSM uses it on next wrong event. Counter increments one time per wrong event and resets on correct PIN, timer expiry (when appropriate), reset or authorized override. `clear_attempts` must win over increment.

## Required tests

Frequency exact on 5-cycle/10-cycle sim; no double enable; timer 1 sec and 3 sec; overlapping start/cancel priorities; reload mid-countdown; correct clear; saturate after five wrong events; third attempt flag; reset while counting; blink active/outside alarm.

## Manager handoff

Self-checking test logs, timing trace, zero-width/overflow parameter handling, synthesis-ready RTL, and any needs from Dev1 or Dev4. Never claim physical-second accuracy from accelerated simulation alone.
