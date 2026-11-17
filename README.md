# HDL Project - Digital Safe with Intrusion Detection

Educational Nexys A7 access-control demonstration using onboard switches,
pushbuttons, LEDs, and the seven-segment display. The FPGA only reports a
simulated lock state; this design does not control a physical lock, relay, or
other actuator.

## Project status

The board variant (Nexys A7-50T or Nexys A7-100T) must be confirmed from the
physical board before selecting a Vivado part or generating a bitstream. The
current integration branch may depend on separately owned RTL modules that
have not yet landed on `dev`; check the regression output for an explicit
integration skip before treating simulation as complete.

Read [`START_HERE.md`](START_HERE.md), the binding
[`INTERFACE_CONTRACTS.md`](docs/agentic/INTERFACE_CONTRACTS.md), and
[`BOARD_SETUP.md`](docs/agentic/BOARD_SETUP.md) before hardware work.

## Simulation

On Linux with Icarus Verilog installed, run:

```sh
bash scripts/run_tests.sh
```

When all required RTL dependencies are present, this runs the top-level smoke
test and every `tests/tb_*.v` testbench. On an incomplete feature branch, the
script still runs display checks and reports the missing integration modules;
that output is not a passing integration gate.
