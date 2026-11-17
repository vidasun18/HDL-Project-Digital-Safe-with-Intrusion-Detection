# Verification Matrix and Minimum Exit Criteria

## Simulation toolchain

Install Icarus Verilog (`iverilog` and `vvp`) for unit/integration tests. For hardware: use AMD/Xilinx Vivado with actual Nexys A7 board part. Run `bash scripts/run_tests.sh` from the repo root. CI uses Ubuntu's `iverilog` package.

## Unit tests

| Owner | Module | At least these assertions |
|---|---|---|
| Dev1 | debounce | delayed stable press, exactly one pulse per hold, no noise trigger, clean release |
| Dev1 | pin capture/compare | captured 16-bit value, valid timing, correct/wrong PIN, no implicit capture |
| Dev1 | FSM | reset to locked, successful unlock, wrong stays locked, threshold alarm, relock, precedence |
| Dev2 | tick generator | exactly one tick each `CLK_HZ` cycles, no extra ticks, reset phase |
| Dev2 | attempt counter | 0 to 3 saturating, third warning, simultaneous clear wins |
| Dev2 | countdown | load, count ticks, done exactly once, cancel and reset |
| Dev2 | blink | LED toggles in ALARM and off outside |
| Dev3 | tamper detector | latches first event; clear only on authorized pulse/reset |
| Dev3 | admin sequence | exact order and wrong-step handling; held-button single pulse |
| Dev3 | recovery | sequence+correct admin code required; no bypass |
| Dev4 | seven-segment | 0-F active-low truth table, scan one digit at a time |
| Dev4 | integration | reset, correct PIN, manual relock, 3 failures, alarm/lockout, tamper, admin recovery |

## Top-level smoke test shipped with this kit

`tests/tb_top_smoke.v` verifies initial reset status, correct PIN unlock, manual relock, and wrong PIN not unlocking. It is intentionally expected to **FAIL** on the current placeholder `digital_safe.v`; the point is to prevent false-green demos. Add complete alarm/tamper/admin integration tests before release.

## Gate definitions

- **Gate 0:** sources compile; no incomplete stub reported as feature.
- **Gate 1:** module tests pass locally and in CI.
- **Gate 2:** integrated self-checking simulation passes full matrix.
- **Gate 3:** Vivado synthesis + implementation + timing closes, chosen board pinout validated.
- **Gate 4:** actual board demo demonstrates buttons, switches, LEDs and seven-segment display.
- **Gate 5:** documentation, limitations, evidence, presentation archived; human approval for main release.

Never treat passing a testbench as evidence the FPGA is programmed or that a real electric lock is safe.

## Simulation artifacts to report

Command, tool version, commit SHA, pass/fail summary, optional GTKWave VCD, one paragraph explaining timing evidence. If a PR changes an interface, manager review must be explicit.
