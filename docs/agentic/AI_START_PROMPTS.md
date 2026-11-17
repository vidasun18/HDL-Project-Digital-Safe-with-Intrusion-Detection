# Copy/Paste AI-Agent Start Prompts

Run your agent from the cloned project root after the manager installs this pack. Choose exactly one role. The AI should use a human-reviewed feature branch; no automatic push/merge. **Deadlines: original 13 Nov; extension requested until 20 Nov 2026 (not yet approved). The goal is a board-only demonstration. Board variant remains unknown.**

## Universal kickoff prompt

> You are collaborating on the Verilog FPGA Digital Safe with Intrusion Detection repository. Read `AGENTS.md`, `START_HERE.md`, `docs/agentic/PROJECT_ARCHITECTURE.md`, `docs/agentic/INTERFACE_CONTRACTS.md`, and my specific role file **before writing code**. Inspect `digital_safe.v`, identify scaffold placeholders, check my current Git branch and local changes. Keep module names/ports exact and ownership boundaries strict. Propose an incremental plan. Implement one submodule and a self-checking Icarus Verilog testbench at a time. Do not change `digital_safe.v` unless I am Developer 4 and explicitly ask. Run tests and report exact commands, pass/fail evidence and known limitations. Follow dated gates in `docs/agentic/SPRINT_RECOVERY_PLAN.md` and prioritize a verified board-only demonstration by 19 November. Never commit, push, open PR, modify repo settings or merge without my explicit approval.

## Developer 1

> I am Developer 1. Read `docs/agentic/ROLE_DEV_1_PIN_FSM.md`. Start with `rtl/pin_compare.v` + `tests/tb_pin_compare.v`, then debounce, capture and `safe_fsm.v` in separate logical units. Respect `third_failure` timing, tamper precedence, reset, and manual relock. Do not edit another developer's files. Give me tested incremental diffs and recommended Conventional Commit messages.

## Developer 2

> I am Developer 2. Read `docs/agentic/ROLE_DEV_2_TIMING_ALARM.md`. Start with the saturation counter and tests, then `tick_generator.v`, `countdown_timer.v`, and `alarm_blinker.v`. Use `tick_1hz` as a **clock enable**, not an FPGA fabric-generated clock. Prove timing with small simulation parameters. Do not edit `digital_safe.v` or other developers' RTL.

## Developer 3

> I am Developer 3. Read `docs/agentic/ROLE_DEV_3_TAMPER_ADMIN.md`. Begin with `tamper_detector.v`, then the debounced LEFT-UP-LEFT-UP `admin_sequence.v`, then `recovery_controller.v` requiring ADMIN_CODE. Verify wrong sequence, wrong code, reset and priority cases. Do not modify the main FSM or top-level.

## Developer 4 (manager)

> I am Developer 4 and project manager. Read `docs/agentic/ROLE_DEV_4_DISPLAY_INTEGRATION.md`. First inspect GitHub branch divergence and freeze interfaces. Implement `hex7seg.v`, `sevenseg_mux.v`, `display_formatter.v` with tests. Confirm 50T vs 100T board part. When other modules arrive, integrate in `digital_safe.v` without rewriting their internals, run full regression, verify vendor XDC, then Vivado synthesis and actual board tests. Track evidence and report blockers distinctly.

## Human reviewer prompt

> Review this PR against `AGENTS.md` and `INTERFACE_CONTRACTS.md`. Check ownership, resets and priority, event pulse widths, clock-domain safety, 100 MHz vs tiny-sim parameters, test assertions, synthesizability and security limits. Identify concrete blocking defects and propose smallest fixes; do not merge.
