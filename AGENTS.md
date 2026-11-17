# AGENTS.md - Master Agentic Development Guide for Digital-Safe-with-Intrusion-Detection HDL
> **project** Digital-Safe-with-Intrusion-Detection HDL
> **Repository**: https://github.com/vidasun18/HDL-Project-Digital-Safe-with-Intrusion-Detection  
> **Hardware**: Digilent Nexys A7, Artix-7 FPGA, 100 MHz `CLK100MHZ`  
> **Language**: synthesizable Verilog, testbenches in Verilog/SystemVerilog supported by `iverilog -g2012`  
> Mission: deliver a verified **onboard-only educational access-control demonstration**, not an approved production door lock.
> Dates: original **13 Nov 2026**; requested **20 Nov 2026**, pending formal approval. Follow dated gates in `docs/agentic/SPRINT_RECOVERY_PLAN.md`.
> FPGA variant: **50T or 100T unknown**. Do not select a specific Vivado part or claim hardware results until the physical board has been identified.

## 1. Read-first order

1. `START_HERE.md`.
2. `docs/agentic/INTERFACE_CONTRACTS.md` (binding interface contract).
3. `docs/agentic/PROJECT_ARCHITECTURE.md` (system behavior).
4. Your assigned `docs/agentic/ROLE_DEV_*.md`.
5. `docs/agentic/TEST_PLAN.md` and `docs/agentic/GIT_CONVENTIONS.md`.
6. Existing `digital_safe.v` before making any code change.
7. `docs/agentic/SPRINT_RECOVERY_PLAN.md` for dated integration and submission gates.

## 2. Project reality

The initial `digital_safe.v` is a scaffold: all five buttons, PIN comparison, timers, tamper paths, override paths and display are currently inactive placeholders. The top-level ports and parameters already exist. Never report placeholder constants as implemented features. There is no proof of working hardware until a bitstream is loaded and witnessed on an actual board.

## 3. Shared architecture and ownership

| Owner | Modules / areas | Excluded areas |
|---|---|---|
| Dev 1 | `rtl/button_debounce.v`, `rtl/pin_capture.v`, `rtl/pin_compare.v`, `rtl/safe_fsm.v`; unit tests | Top-level wiring, counters, XDC, display |
| Dev 2 | `rtl/tick_generator.v`, `rtl/failed_attempt_counter.v`, `rtl/countdown_timer.v`, `rtl/alarm_blinker.v`; unit tests | Main FSM, tamper admin logic, board pins |
| Dev 3 | `rtl/tamper_detector.v`, `rtl/admin_sequence.v`, `rtl/recovery_controller.v`; unit tests | Main FSM, timers, XDC, display |
| Dev 4 | `digital_safe.v` integration, `rtl/hex7seg.v`, `rtl/sevenseg_mux.v`, `rtl/display_formatter.v`, `constraints/`, integration tests, CI/docs | Do not silently alter another owner's internals |

`rtl/` files are created by developers as they implement features; they are **not present in the starting repository**. Development is not blocked while files do not yet exist.

## 4. Invariants agents must never break

1. `CPU_RESETN` is active-low; pressing reset locks the safe and clears volatile state. On hardware, reset must assert safely; remove reset synchronously within normal logic where appropriate.
2. `CLK100MHZ` 100 MHz is the only clock domain. Use 1-cycle enable pulses, **not a fabric-generated second clock**.
3. `BTNC` submits switch PIN; `BTND` manually relocks; `BTNR` signals tamper; `BTNL`,`BTNU` form `LEFT-UP-LEFT-UP` admin sequence.
4. `SW[15:0]` is a demo PIN input. Never display the PIN on LEDs or seven-segment outputs; beware source-code hardcoded credentials.
5. Failed count is saturated at 3. Third invalid submission triggers alarm. Valid PIN clears failure count.
6. Alarm runs for `ALARM_SECONDS`, then lockout for `LOCKOUT_SECONDS`, using tick enable. Timer clear/restart requirements are explicit.
7. Tamper raises alarm and latches evidence until reset or authorized admin recovery. It must never cause an unlock. If lockout expires but tamper is still latched, keep safe locked and reject ordinary PIN unlock until admin recovery.
8. Admin recovery resets to **LOCKED**, never UNLOCKED. Require sequence and `SW==ADMIN_CODE` as a deliberate added security condition; project manager must approve any change.
9. State transitions and authentication decisions are synchronous; lock/unlock indication defaults to locked after reset.
10. Each reset/debounce/timer width must work for small simulation parameters and FPGA-scale values. Guard `clog2` widths against zero.
11. Seven-segment `SEG`, `AN`, `DP` are active-low; the eight digits are multiplexed. `LED[1]` is a simulated unlock indicator, **not an actuator output**. All final demonstration I/O remains on the Nexys A7 board; do not connect a physical lock.
12. Keep top-level names and widths from `digital_safe.v` unchanged unless approved by the manager and documented in interface change review.

## 5. Agent working contract

For each feature: (a) inspect repo and spec, (b) state file-level plan, (c) change only owned files, (d) write meaningful assertions with self-checking testbench, (e) run tests and attach exact command/result, (f) show diff summary and known limitations, (g) ask human owner to commit/push/open PR. Don't edit files outside scope, do not silently replace in-progress code, and do not make up test outcomes.

Do not create GitHub collaborators, impersonate humans, request access tokens, disable branch protection, push automatically, force-push, merge, or alter repository settings. If an agent can submit PRs, the human developer explicitly approves every external action.

## 6. Definition of Done for every module

- Verilog compiles without errors (and warnings investigated).
- At least one dedicated self-checking unit test has realistic reset, normal, and boundary cases.
- Signal polarity/timing documented, with no latches or unintended clocks.
- Interface matches `INTERFACE_CONTRACTS.md` exactly.
- Simulation results included in PR; CI passes on the feature branch when integration is complete.
- Human reviewer accepts change. Synthesis and board checks are separately reported by Dev 4.

## 7. Integration rule

`main` = reviewed release; `dev` = shared integration; feature branches are short-lived off `dev`. Dev 4 integrates after contracts and unit tests pass. No generic long-lived `developer1` branches. Do not integrate a subsystem by replacing the entire top-level design.
