# Nexys A7 Setup and XDC Notes

**Board choice:** The team has **not yet established whether its Nexys A7 is 50T or 100T**. Official 50T and 100T master XDC references exist, and the mapped onboard pins in this pack were cross-checked against both for current top-level ports. This is **not** a verified Vivado part selection. Identify the actual board before selecting an FPGA part, running implementation or generating a bitstream (target confirmation by **16 November 2026**).

Sources:
- Official 100T XDC: https://github.com/Digilent/digilent-xdc/blob/master/Nexys-A7-100T-Master.xdc
- Official 50T XDC: https://github.com/Digilent/digilent-xdc/blob/master/Nexys-A7-50T-Master.xdc
- Board manual: https://digilent.com/reference/_media/reference/programmable-logic/nexys-a7/nexys-a7_rm.pdf

## Checklist

1. Identify FPGA marking: 50T or 100T; document Vivado version and selected FPGA part.
2. Create a Vivado RTL project; set `digital_safe` as top; add all `rtl/*.v` submodules once present.
3. Import `constraints/nexys_a7_demo.xdc` and inspect constraints with Vivado DRC. The file defines all current top-level pins, matching official master port mappings.
4. Check `CLK100MHZ` 10 ns period and no unconstrained top-level ports.
5. Run synthesis, implementation, timing report and bitstream generation; report real results, not assumed.
6. Program the board and verify reset, good PIN, manual relock, three wrong attempts, alarm, lockout, tamper, administrator recovery.
7. Observe each active-low SEG/AN scan output and display text visually; check button bounce behavior on physical board.

## Demo-only objective and release gate

Use onboard switches for demo PIN, onboard buttons for submit/relock/tamper/admin, LEDs for locked/unlocked/alarm status and onboard seven-segment display for state/counters. **No real laboratory door, lock, relay, motor or solenoid is in project scope.** The hardware demonstration is planned for **19 November 2026**, and the **20 November** due date is requested, not yet approved. Do not claim a board demo without witnessed hardware test results.

## Hardware specifics

- Switches 0..15, five directional buttons, active-low CPU reset and 16 LEDs are on board.
- CPU RESET is **active-low**; the five directional buttons are active-high when pressed.
- `SEG`, `AN` and `DP` are driven low to turn on display elements/digits; 8 digits share segment lines.
- Official Digilent XDC assigns `SW[8]` and `SW[9]` **LVCMOS18**, not LVCMOS33.
- `LED[1]` is an indicator for 'unlock'; it cannot power a door strike. Any external lock requires properly isolated electronics and institutional approval.
