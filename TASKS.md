# Project Tasks — Digital Safe with Intrusion Detection

## Goal

Implement a simple, working Verilog digital safe on the Digilent Nexys A7 and demonstrate it on the FPGA. Prioritize the required behavior and a reliable demo. Do not add features outside this document without team agreement.

## Shared rules

- Use Verilog and simple synthesizable RTL. Prefer clear `always` blocks, `case` statements, registers, and counters.
- Keep one main clock domain. Derive slow timing with clock-enable pulses; do not create extra fabric clocks unless necessary.
- Use active-low board reset consistently and document reset polarity.
- Debounce push buttons before using them as events. Generate one-cycle pulses for button presses.
- Agree on top-level ports, signal names, PIN entry mapping, and parameter values before module integration.
- Keep each developer's changes within their assigned files/logic. Tell the team before changing a shared interface.
- Do not duplicate the same logic in multiple modules.
- Add a small testbench for each important behavior. Test the normal path and the failure path.
- Never claim a feature is complete until it is simulated and, where relevant, tested on the board.
- Board variant is not confirmed. Do not invent XDC pin mappings; verify the exact board model/revision first.

## Team allocation

### Developer 1 — PIN checking, button debounce, PIN capture, main FSM

**Implement**
- Debounce the buttons used for submit, manual lock, and any PIN-entry controls.
- Capture the entered PIN from the agreed switches/input method when the submit button is pressed.
- Compare the captured PIN against the configured user PIN.
- Implement the main safe FSM with only the states needed: `LOCKED`, `CHECKING`, `UNLOCKED`, and the agreed alarm/lockout hand-off states.
- Unlock only after a correct PIN.
- Return to `LOCKED` when the manual lock button is pressed.
- Keep the safe locked after reset.
- Provide clean event/status signals for the other developers, such as `pin_valid`, `pin_failed`, `unlock_request`, and `lock_request` (final names agreed by the team).

**Acceptance checks**
- Reset always starts in `LOCKED`.
- A correct PIN produces one successful unlock.
- A wrong PIN never unlocks the safe and produces one failure event.
- Button bounce does not create multiple submissions.
- Manual lock returns the safe to `LOCKED`.
- Testbench covers correct PIN, wrong PIN, repeated presses, and manual relock.

### Developer 2 — Attempt counter, clock divider, timers, alarm controller

**Implement**
- Count failed PIN events from Developer 1.
- Use a simple parameterized maximum-attempt value (team default: 3 unless agreed otherwise).
- Generate a one-cycle 1 Hz tick from the 100 MHz board clock using a counter/clock enable.
- Implement a reusable or straightforward countdown timer for alarm and lockout durations.
- Activate and blink the alarm LED when an alarm request is received.
- Signal when the alarm duration or lockout duration has finished.
- Provide clear signals to the main FSM / Developer 3 for attempt-limit reached, alarm active, and timer finished.

**Acceptance checks**
- Only a failed PIN event increments the attempt count.
- Successful authentication does not increment the count.
- Reaching the configured limit generates one alarm request.
- The 1 Hz tick has the expected rate after parameter scaling for simulation.
- Alarm LED visibly blinks while alarm is active.
- Timer expires at the configured duration and can be reset/restarted.
- Testbench covers attempts, threshold, alarm blinking, and timer expiry.

### Developer 3 — Intrusion detector, tamper behavior, admin override

**Implement**
- Read the agreed tamper input (a Nexys A7 switch or button used as a simulated sensor).
- Treat tamper activation while the safe is locked as an intrusion event.
- Ignore or handle tamper while unlocked according to the team's agreed simple rule; document that rule.
- Combine tamper intrusion and the failed-attempt alarm request into the alarm/lockout control path.
- Implement a simple admin-code entry/sequence to recover from alarm/lockout.
- Require the correct admin sequence before clearing the alarm/lockout.
- Clear attempt/tamper status only after a valid recovery action.
- Return the system to `LOCKED` after recovery; do not automatically unlock the safe.

**Acceptance checks**
- Tamper while locked requests an alarm.
- Normal operation without tamper does not trigger intrusion.
- Incorrect admin entry does not clear the alarm/lockout.
- Correct admin entry clears the alarm/lockout and returns to `LOCKED`.
- Admin recovery cannot accidentally leave the safe unlocked.
- Testbench covers tamper, wrong admin entry, and correct recovery.

### Developer 4 — Seven-segment display, board constraints, simulation automation, documentation

**Implement**
- Display the agreed status information using the Nexys A7 eight-digit seven-segment display.
- Show useful simple values such as entered PIN digits or status, attempt count, and lockout countdown. Agree on the final display format with the team; do not try to show everything at once.
- Implement display digit decoding and multiplexing, or adapt a simple verified display module.
- Map LEDs to clear states: locked, unlocked, alarm, and tamper/attempt status as agreed.
- Prepare the XDC constraints for the exact Nexys A7 variant after checking the physical board label/revision and official master XDC.
- Keep simulation commands/scripts easy to run and document required source files.
- Maintain README and short demo instructions; record known limitations.

**Acceptance checks**
- Seven-segment digits are stable and readable on the board.
- Display changes correctly for the selected status/value.
- LED meanings are documented and match the hardware.
- XDC uses verified pins and the correct board clock.
- The project can be simulated using the documented command.
- README explains how to build, simulate, program, and demonstrate the project.

## Integration order

1. Team agrees on top-level interface, PIN input mapping, button roles, tamper input, display format, and parameters.
2. Developer 1 completes the basic locked/correct PIN/wrong PIN/manual lock behavior.
3. Developer 2 connects failed-attempt counting and alarm timing.
4. Developer 3 connects tamper detection and admin recovery.
5. Developer 4 connects display, LEDs, and verified board constraints.
6. Team runs the complete testbench set, fixes integration issues, then tests on the Nexys A7.

## Minimum demo sequence

1. Reset the board and show `LOCKED`.
2. Enter the correct PIN and show `UNLOCKED`.
3. Press manual lock and show `LOCKED` again.
4. Enter an incorrect PIN until the attempt limit is reached; show the alarm and lockout.
5. Activate the tamper input while locked and show intrusion detection.
6. Enter the correct admin sequence and show recovery to `LOCKED`.

## Final checklist

- [ ] Team has agreed on shared signal names and input mapping.
- [ ] Correct PIN unlocks; wrong PIN does not.
- [ ] Manual relock works.
- [ ] Failed-attempt limit activates alarm.
- [ ] Alarm and lockout timers work.
- [ ] Tamper input triggers intrusion while locked.
- [ ] Admin recovery works and returns to locked.
- [ ] Seven-segment display and LEDs show correct status.
- [ ] Testbenches pass.
- [ ] XDC matches the exact board variant.
- [ ] FPGA demo sequence has been rehearsed.

## Out of scope

- Network connectivity, mobile/web applications, databases, cloud logging, or remote notifications.
- Cryptographic PIN storage or production-grade physical security.
- Multiple user accounts, complex menus, or unnecessary state-machine layers.
- Extra sensors or hardware not available for the class demonstration.

Keep the implementation small, understandable, synthesizable, and easy to explain in a viva.