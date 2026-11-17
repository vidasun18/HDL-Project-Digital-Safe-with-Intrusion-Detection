# Codex Instructions — Digital Safe with Intrusion Detection

## Project Overview
This repository contains a simple synthesizable Verilog implementation of a Digital Safe with Intrusion Detection for the Digilent Nexys A7 FPGA (AMD Artix-7).

- **Clock**: 100 MHz (`CLK100MHZ`).
- **Reset**: `CPU_RESETN` (active-low push button, mapped to internal synchronous active-high `rst = ~CPU_RESETN`).
- **Inputs**:
  - `SW[15:0]`: 16-bit PIN input. Default `USER_PIN = 16'hA5C3`, `ADMIN_CODE = 16'hC0DE`.
  - `BTNC`: Submit PIN.
  - `BTND`: Lock safe.
  - `BTNU`: Admin recovery sequence.
  - `BTNR`: Tamper sensor.
- **Outputs**:
  - `LED[15:0]`: `LED[0]` (locked), `LED[1]` (unlocked), `LED[2]` / alarm blinking.
  - `SEG[6:0]`, `AN[7:0]`, `DP`: 8-digit multiplexed seven-segment display.

---

## Strict Mandatory Requirements

### 1. Never Add Agents as Contributors
- **NEVER** credit Codex, OpenAI, Antigravity, or any AI assistant as a contributor or author.
- **DO NOT** use `Co-authored-by:` git commit trailers referencing AI.
- Commits and pull requests must only be attributed to the human user/repository owner.

### 2. Use Separate Branches for Each Feature
- **NEVER** push or commit directly to `main` or `dev`.
- Develop each feature on an isolated branch created from `main`:
  ```bash
  git checkout -b feature/<feature-name>
  ```
- Naming format: lowercase with hyphens, e.g.:
  - `feature/failed-attempts-counter`
  - `feature/clock-enable-1hz`
  - `feature/countdown-timer`
  - `feature/intrusion-tamper-detection`
  - `feature/three-strike-alarm`
  - `feature/alarm-indicator-blink`

### 3. Use the Provided Commit Structure
- All commits must follow the Conventional Commits specification (`<type>: <description>` in lowercase, imperative mood).
- For planned features, use the exact commit messages specified in the project task allocation:
  - `feat: count failed PIN submissions`
  - `feat: generate a configurable one-second clock enable`
  - `feat: add a reusable timer for timed safe states`
  - `feat: detect intrusion requests and latch tamper events`
  - `feat: trigger alarm after three wrong PIN attempts`
  - `feat: blink the alarm indicator during alarm states`
- For other changes, use standard prefixes: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`.

---

## Technical Constraints & Guidelines
1. **Clocking**: Single 100 MHz clock domain. Use a clock-enable tick (`tick_1hz`) for 1-second timing; do not create ripple clocks using counter bits.
2. **Debounce**: All mechanical buttons must pass through `safe_button_debounce` to produce single-cycle press pulses.
3. **Coding Standards**:
   - Sequential blocks: `always @(posedge CLK100MHZ)` with nonblocking assignments (`<=`).
   - Combinational logic: blocking assignments (`=`).
   - Prevent inferred latches by fully specifying conditions or setting defaults.
   - Use explicit widths (e.g. `16'h0000`, `3'd0`).
4. **Scope Isolation**: Adhere strictly to the task boundaries in `TASKS.md`. Do not modify other team members' modules or interfaces without coordination.

---

## Verification
- Before finishing any task, run the simulator and ensure all tests pass:
  ```bash
  iverilog -g2012 -o test.vvp digital_safe.v tests/<testbench_file>.v
  vvp test.vvp
  ```
- Fast simulation: use scaled parameters in testbenches (e.g. `CLK_HZ = 100`, short debounce cycles) while keeping production defaults synthesizable.
