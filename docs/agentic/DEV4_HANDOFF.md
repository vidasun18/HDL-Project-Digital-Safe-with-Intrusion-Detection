# Developer 4 Handoff

## Delivered on `feature/display-board`

- Integrated the existing top-level submodules and retained the top-level port and parameter contract.
- Added the active-low hexadecimal decoder, eight-digit multiplexing, and status/attempt/countdown formatting.
- Added display and end-to-end regression benches, a Linux Icarus test runner, CI workflow, Nexys A7 constraints, and project handoff documentation.
- Aligned admin progress LEDs to `LED[8:6]` and tamper evidence to `LED[5]`, matching `INTERFACE_CONTRACTS.md`.
- The display exposes the state nibble, failed-attempt count, and timer seconds; it does not display the submitted PIN.

## Verification evidence

The local simulation binaries produced these results:

- `vvp build/tb_top_smoke.vvp` — PASS: reset, valid PIN unlock, manual relock, and wrong PIN rejection.
- `vvp build/tb_display.vvp` — PASS: all 16 glyphs, formatter fields, one active-low anode, and decimal point off.
- `vvp build/tb_top_regression.vvp` — PASS: reset, unlock, relock, third-failure alarm, lockout, tamper latch, blocked PIN unlock, and admin recovery to LOCKED.

Host limitations: `bash scripts/run_tests.sh` could not start because the configured Windows Bash launchers are blocked by the host (`Access is denied`). The installed Icarus Verilog 12.0 development build generated runnable VVP files but then returned Windows access-violation code `-1073741819`; therefore a clean local compiler exit has not been established. Run the committed script in Linux CI before merge.

## Remaining gates

- The Dev 1-3 RTL dependencies existed as untracked local files during the simulations and are not part of this Dev 4 branch. The test runner reports the missing integration modules and skips top-level tests when run on an incomplete feature branch. Merge only after those owners' reviewed RTL and unit tests are available.
- Nexys A7 50T/100T has not been physically identified. No Vivado part selection, synthesis, implementation, bitstream, or board result is claimed.
- The 20 November deadline remains requested and unapproved per project records.
