# Digital Safe with Intrusion Detection (Nexys A7)

A small Verilog project for the Digilent Nexys A7 FPGA. The safe uses a PIN to unlock, detects repeated incorrect PIN entries and tamper activity, and provides an alarm and timed lockout. The seven-segment display and LEDs show the system status.

## Project goal

Build and demonstrate a working digital safe using simple synthesizable HDL. Keep the design focused on the proposed features; do not add networking, databases, software applications, or unnecessary security features.

## Hardware

- Board: Digilent Nexys A7 AMD Artix-7 FPGA Trainer Board
- Clock: 100 MHz (`CLK100MHZ`)
- Inputs: active-low board reset, push buttons, and switches
- Outputs: LEDs and the eight-digit seven-segment display
- The exact FPGA device variant/revision still needs to be checked on the physical board before finalizing XDC constraints.
- Board references: [Digilent Nexys A7 FPGA board Documentation.pdf](./Digilent%20Nexys%20A7%20FPGA%20board%20Documentation.pdf) and [nexys-a7-d3-schematics.pdf](./nexys-a7-d3-schematics.pdf).

### Input mapping

| Input | Role |
|---|---|
| `SW[15:0]` | 16-bit PIN entry |
| `BTNC` | Submit the PIN |
| `BTND` | Manually lock the safe |
| `BTNU` | Reserved for the admin recovery path |
| `BTNR` | Simulated tamper input |
| `BTNL` | Reserved; no behavior assigned |

Button presses are debounced before they are used as events. The default PIN and debounce timing are parameters in `digital_safe.v`.

## Team task allocation

The detailed, agent-ready checklist is in [TASKS.md](TASKS.md). Instructions for coding agents are in [AGENTS.md](AGENTS.md).

| Member | Main responsibility |
|---|---|
| Developer 1 | PIN checking, button debouncing, PIN capture, main FSM |
| Developer 2 | Failed-attempt counter, clock divider, timers, alarm controller |
| Developer 3 | Intrusion detector, tamper behavior, admin override |
| Developer 4 | Seven-segment display, board constraints, simulation automation, documentation |

Each developer should work only on their assigned area unless the team agrees otherwise. Coordinate signal names and interfaces before integrating modules.

## Basic expected operation

1. After reset, the safe is locked.
2. The user enters a PIN using the agreed switches/buttons and submits it.
3. A correct PIN unlocks the safe. A lock button returns it to the locked state.
4. An incorrect PIN increments the failed-attempt count.
5. Reaching the agreed attempt limit activates the alarm and lockout.
6. A tamper input while locked also requests an intrusion alarm.
7. The admin sequence can clear the alarm/lockout and return the safe to the locked state.
8. LEDs and the seven-segment display show useful status.

The exact PIN, admin code, attempt limit, alarm duration, lockout duration, and button/switch mapping should be constants or parameters agreed by the team and documented before the final demo.

## Repository structure

```text
.
├── digital_safe.v       # Top-level FPGA design
├── tests/               # Verilog testbenches
├── TASKS.md             # Team task checklist and acceptance criteria
└── AGENTS.md            # Instructions for coding agents
```

Add extra RTL files only when they make the design easier to understand or test. Keep the top-level module and its board-facing ports clear.

## Build and simulation

Use Vivado for synthesis, implementation, and programming the Nexys A7. Use the testbench workflow selected by the team (for example, Icarus Verilog with GTKWave) for quick simulation.

Example Icarus Verilog commands, when the testbench and source files are ready:

```bash
iverilog -g2012 -o safe_tb.vvp digital_safe.v tests/tb_reset_locked.v
vvp safe_tb.vvp
```

The command above is only a starting example; include any additional RTL files required by the final design.

## Definition of done

- [ ] Reset puts the safe into the locked state.
- [ ] Correct PIN unlocks the safe.
- [ ] Incorrect PIN increments the attempt count.
- [ ] The configured failed-attempt limit activates the alarm/lockout.
- [ ] Tamper input while locked activates intrusion handling.
- [ ] Admin recovery clears the alarm/lockout safely.
- [ ] Lock button locks the safe again.
- [ ] Display and LEDs show the required states.
- [ ] Testbenches cover normal and intrusion cases.
- [ ] XDC pin assignments match the exact Nexys A7 board variant.
- [ ] The team demonstrates the design on the FPGA.

## Current implementation note

The initial `digital_safe.v` contains the top-level ports and state/status placeholders, but several inputs and logic signals are currently tied to constants. Treat it as a starting scaffold, not as a completed safe. Check the current source before assuming a feature is implemented.
