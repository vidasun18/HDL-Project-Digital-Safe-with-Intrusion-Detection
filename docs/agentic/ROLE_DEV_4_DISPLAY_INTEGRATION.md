# Developer 4 - Display, Board Setup, CI and Project Management

**You are the project manager and Developer 4.** Own display, pin constraints, test automation, integration and documentation. Keep each other contributor responsible for their own module and verification. **Original deadline: 13 Nov 2026; requested revised deadline: 20 Nov 2026 (unapproved). Hardware scope: onboard demo only. Board variant: unknown until confirmed.**

## Files owned

`digital_safe.v` **top-level integration only**, `rtl/hex7seg.v`, `rtl/sevenseg_mux.v`, `rtl/display_formatter.v`, `constraints/nexys_a7_demo.xdc`, `.github/workflows/hdl-ci.yml`, `scripts/run_tests.sh`, top-level regression, architecture/proposal/hardware documentation.

## Ordered feature tasks

1. Confirm **50T vs 100T FPGA device** by reading board markings **by 16 Nov**; select matching Vivado board/part (no guessing). Do not generate a final bitstream without confirmation.
2. Review inherited scaffold, branch divergence, and publish interface freeze for all 4 people.
3. Create/verify 7-segment decoder: active-low SEG bit order `{g,f,e,d,c,b,a}` and 0-F glyphs.
4. Multiplex 8-digit display via single `CLK100MHZ`, active-low AN, DP off; test refresh and no multiple active anodes.
5. Format nibble values: status, wrong-attempt count, remaining alarm/lockout seconds. Never display secret PIN.
   Clamp timer parameters to the supported 1-255 second display range.
6. Verify XDC against Digilent official master for selected board; **SW8/SW9 are LVCMOS18**, others vary by bank, so never blindly apply LVCMOS33 to every switch.
7. Integrate 4 owners' submodules under `digital_safe.v`, preserving existing top-level ports and parameters.
8. Wire `LED[0]` locked, `LED[1]` simulated unlock, `LED[2]` alarm blink, `LED[3]` lockout, `LED[5]` latched tamper, and cumulative admin progress on `LED[8:6]`, matching `INTERFACE_CONTRACTS.md`.
9. Run self-checking top-level simulator (`bash scripts/run_tests.sh`), then Vivado synthesis, implementation and timing checks.
10. Demonstrate hardware behavior on Nexys A7, capture screenshots/terminal commands and complete report. Keep evidence distinguishable from AI-generated text.

## Your management tasks

- By **11 Nov 2026**, get each developer to acknowledge their role and provide their feature-branch link and first tested changes. Track gates for **13, 16, 18, 19 and 20 Nov** (see sprint plan).
- Use `MANAGER_TRACKER.md` daily: owner, scope, test proof, blockers, next checkpoint, review decision.
- Never merge a PR solely because it compiles; require assertions and change review.
- Keep `main` release-only; combine to `dev` after CI and peer review.
- Preserve human attribution. Do not add bots to the repository as collaborators.

## Required tests

All hex segments; blank/refresh conventions; only one AN low at once; clock 100 MHz XDC constraint; 16 SW + five directional buttons + reset mapped; normal unlock/relock; third wrong alarm; alarm->lockout->locked; tamper latch and recovery; async reset; no secret on display; default locked state.

## Hardware restriction

Never attach a relay, motor, lock strike, or door solenoid directly to an FPGA pin. A production system requires approved driver circuitry, power isolation, electrical safety, fail-safe/fail-secure behavior, and threat modeling. This project pack only maps the existing onboard LEDs and display.
