# AGENTS.md — Instructions for AI Coding Agents

## Project context

This repository contains a simple Verilog digital safe with intrusion detection for a Digilent Nexys A7 FPGA. The goal is a working class-project demonstration, not a production security system.

Read `README.md` and `TASKS.md` before making changes. Follow the four-person allocation in `TASKS.md`.

## Non-negotiable instructions

1. **Never add AI agents as contributors**:
   - Do NOT add AI agents (Antigravity, Codex, Copilot, ChatGPT, Claude, etc.) as contributors, authors, co-authors, or reviewers.
   - Do NOT include `Co-authored-by:` trailers mentioning AI agents in git commit messages.
   - Commits, pull requests, and documentation credits must only reflect the human repository owner/team members.
2. **Use separate branches for each feature**:
   - Never commit directly to `main` (or `dev`).
   - Every individual feature, bug fix, or task must be developed on its own dedicated branch off `main` (e.g., `feature/<feature-name>`).
   - Keep branch names lowercase with hyphens (e.g., `feature/failed-attempts-counter`, `feature/clock-enable-1hz`, `feature/countdown-timer`, `feature/tamper-detection`).
3. **Use the commit structure provided**:
   - Follow Conventional Commits: `<type>: <description>` (lowercase description, imperative mood, no ending period).
   - Use the exact commit messages agreed for planned features:
     - `feat: count failed PIN submissions`
     - `feat: generate a configurable one-second clock enable`
     - `feat: add a reusable timer for timed safe states`
     - `feat: detect intrusion requests and latch tamper events`
     - `feat: trigger alarm after three wrong PIN attempts`
     - `feat: blink the alarm indicator during alarm states`
   - For other changes, strictly use appropriate standard prefixes (`feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`).
4. Keep the implementation simple and beginner-friendly.
5. Use Verilog compatible with the team's Vivado version. Do not introduce SystemVerilog-only syntax unless the team explicitly approves it.
6. Do not redesign the whole project when a small change is enough.
7. Do not add networking, software services, databases, cryptography libraries, or unrelated features.
8. Do not silently change top-level module ports, signal polarity, state encodings, PIN input mapping, or shared interfaces.
9. Before changing a shared interface, inspect its current use and explain the proposed change.
10. Use the existing `digital_safe.v` as the integration starting point. Inspect it before editing; some signals may currently be tied to constants/placeholders.
11. Do not assume a feature works because a signal or module name exists. Trace the actual logic.
12. Use parameters/localparams for clock frequency, PIN values, attempt limit, alarm duration, and lockout duration where useful.
13. Avoid latches. Use nonblocking assignments (`<=`) in clocked sequential blocks and blocking assignments (`=`) in combinational blocks.
14. Keep reset behavior consistent. The Nexys A7 `CPU_RESETN` input is active-low; document any internal active-high reset conversion.
15. Use clock-enable pulses for slow timing. Avoid using a counter bit as a new clock.
16. Debounce physical buttons and create one-cycle press events before using them in the FSM.
17. The board family is the Digilent Nexys A7 AMD Artix-7 FPGA Trainer Board; the board documentation and schematic PDFs are in the repository. Do not invent XDC pin numbers. Confirm the exact FPGA device variant/revision from the physical board and use its official master XDC.
18. Do not overwrite another developer's work or unrelated files.

## Work process

1. Inspect the current repository and relevant RTL/testbench files.
2. Identify the task owner and the exact feature requested.
3. Create and switch to a separate feature branch (`feature/<feature-name>`) off `main` before writing any code.
4. State the files you plan to change and keep the change limited to those files.
5. Confirm module ports and signal names with existing code before coding.
6. Implement the smallest clear solution.
7. Add or update a focused testbench for the behavior.
8. Run the available simulator (`iverilog` and `vvp`). If it is unavailable, provide the exact command and state that tests were not run.
9. Review the diff for accidental changes, unused signals, inferred latches, width mismatches, and reset mistakes.
10. Commit changes using the specified commit message structure (e.g., `feat: ...`) under the user's git identity—never add agent co-author tags.
11. Summarize changed files, behavior implemented, tests run/results, and remaining work.

## Coding style

- Use descriptive but short signal names.
- Use `localparam` for FSM states.
- Keep one clear sequential block for each state/register group where practical.
- Keep combinational next-state/output logic separate when that makes the FSM easier to read.
- Use explicit bit widths and avoid unsized constants in important comparisons.
- Add comments for board-facing I/O, reset polarity, and non-obvious timing logic.
- Prefer a few small modules only when they clarify ownership or allow independent testing.
- Avoid unnecessary parameter frameworks, packages, interfaces, generated code, and complex abstractions.

## Shared interface coordination

Before integration, the team must agree on:

- PIN entry source and width: `SW[15:0]` is the 16-bit PIN.
- Button mapping: `BTNC` submits, `BTND` manually locks, `BTNU` is reserved for admin recovery, `BTNR` simulates tamper, and `BTNL` is unassigned.
- Admin code entry method and recovery behavior beyond the reserved `BTNU` input.
- Names and active levels of `pin_valid`, `pin_failed`, `alarm_request`, `tamper_event`, `admin_recover`, timer tick/done, and lock/unlock signals.
- Attempt limit, alarm duration, lockout duration, and display format.

Do not independently invent different meanings for the same signal. If the existing design does not define an interface, propose a minimal one and document it before implementation.

The board-family and input mapping above are confirmed for this project. The exact FPGA device variant/revision remains a hardware check and must be confirmed before XDC constraints are written.

## Verification expectations

At minimum, cover these cases in simulation:

- Reset -> locked.
- Correct PIN -> unlocked.
- Wrong PIN -> remains locked and reports one failed attempt.
- Manual lock -> locked.
- Attempt threshold -> alarm/lockout.
- Timer start -> tick/countdown -> done.
- Tamper while locked -> intrusion alarm request.
- Wrong admin code -> no recovery.
- Correct admin code -> clear alarm/lockout and return to locked.
- Display decoder/multiplexer -> expected segment outputs for tested digits/status.

Use small parameter values in testbenches to avoid waiting real seconds. Keep synthesizable defaults suitable for the 100 MHz board clock.

## Ownership guide

- Developer 1: PIN checking, button debounce, PIN capture, main FSM.
- Developer 2: attempt counter, clock divider, timers, alarm controller.
- Developer 3: intrusion detector, tamper behavior, admin override.
- Developer 4: seven-segment display, board constraints, simulation automation, documentation.

An agent must work only on the assigned developer's area unless explicitly asked to integrate or review the full project.

## Completion report format

At the end of each task, report:

1. **Implemented:** short list of behavior added.
2. **Files changed:** exact paths.
3. **Tests:** commands run and pass/fail results.
4. **Not tested:** anything that still needs simulation or FPGA hardware.
5. **Integration notes:** required signals, assumptions, or changes needed from another developer.
6. **Remaining tasks:** only items still necessary for the assigned feature.

Do not claim that the FPGA hardware was tested unless it was actually programmed and tested on the physical board.