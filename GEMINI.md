# Antigravity Agent Guidelines — Digital Safe with Intrusion Detection

## Core Project Context
- **Target Hardware**: Digilent Nexys A7 FPGA Trainer Board (AMD Artix-7).
- **Clock & Reset**: 100 MHz clock (`CLK100MHZ`), active-low CPU reset (`CPU_RESETN`, converted to internal synchronous active-high `rst = ~CPU_RESETN`).
- **I/O Mapping**:
  - `SW[15:0]`: 16-bit PIN / code entry (`USER_PIN = 16'hA5C3`, `ADMIN_CODE = 16'hC0DE`).
  - `BTNC`: Submit PIN.
  - `BTND`: Manual lock.
  - `BTNU`: Admin recovery path.
  - `BTNR`: Tamper sensor input.
  - `BTNL`: Unassigned.
  - `LED[15:0]`: `LED[0]` locked, `LED[1]` unlocked, `LED[2]` / alarm blinking.
  - `SEG[6:0]`, `AN[7:0]`, `DP`: Seven-segment display.

---

## Mandatory Non-Negotiable Rules

### 1. Never Add Agents as Contributors
- **NEVER** add Antigravity, Gemini, or any AI assistant as a contributor, author, co-author, or reviewer.
- **DO NOT** add git trailers such as `Co-authored-by: ...` referencing AI agents.
- All commits, pull requests, and documentation must only use the repository owner's / human team member's credentials.

### 2. Use Separate Branches for Each Feature
- **DO NOT** commit directly to `main` (or `dev`).
- Always create a dedicated branch off `main` for each feature:
  `git checkout -b feature/<feature-name>`
- Feature branch naming examples:
  - `feature/failed-attempts-counter`
  - `feature/clock-enable-1hz`
  - `feature/countdown-timer`
  - `feature/intrusion-tamper-detection`
  - `feature/alarm-controller`
  - `feature/alarm-led-blink`

### 3. Use the Provided Commit Structure
- Strictly adhere to Conventional Commits: `<type>: <description>` (all lowercase description, imperative mood, no ending period).
- When implementing Developer 2's features (per project task specification), use the exact required commit messages:
  - `feat: count failed PIN submissions`
  - `feat: generate a configurable one-second clock enable`
  - `feat: add a reusable timer for timed safe states`
  - `feat: detect intrusion requests and latch tamper events`
  - `feat: trigger alarm after three wrong PIN attempts`
  - `feat: blink the alarm indicator during alarm states`
- For other changes, use standard types: `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `chore:`.

---

## Design and Synthesis Rules
1. **Clock Domain**: Maintain a single 100 MHz clock domain (`CLK100MHZ`). Slow timing (1 Hz) must be generated via clock-enable pulses (`tick_1hz`), never as divided ripple clocks in FPGA fabric.
2. **Synchronous Reset**: Use synchronous active-high `rst` derived from `~CPU_RESETN`.
3. **Button Debounce**: All physical buttons must be debounced and generate one-cycle press pulses before triggering state transitions.
4. **No Latches**:
   - Clocked sequential logic (`always @(posedge CLK100MHZ)`) uses non-blocking assignments (`<=`).
   - Combinational logic uses blocking assignments (`=`) with complete branch coverage (default assignments).
5. **Role Boundaries**: Work strictly within the assigned developer scope in `TASKS.md` (e.g., Developer 2 owns failed-attempt counter, timers, 1 Hz tick, and alarm blinking). Do not overwrite or alter other developers' modules without coordination.

---

## Verification Requirements
- Test every new feature with a targeted testbench before committing.
- Use Icarus Verilog (`iverilog`) and VVP:
  ```bash
  iverilog -g2012 -o test.vvp digital_safe.v tests/<testbench_name>.v
  vvp test.vvp
  ```
- Use scaled parameters (e.g., `CLK_HZ = 100`, small `DEBOUNCE_CYCLES`) in testbenches for fast simulation runs while keeping hardware defaults synthesizable.
