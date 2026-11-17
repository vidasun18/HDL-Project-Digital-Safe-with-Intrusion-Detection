# Developer 3 - Tamper Detection and Administrative Recovery

**Assigned:** tamper detection, admin sequence recognizer and authorized recovery event. **Not assigned:** safe FSM implementation, timing controller, top-level wiring.

## Files owned

`rtl/tamper_detector.v`, `rtl/admin_sequence.v`, `rtl/recovery_controller.v`, plus `tests/tb_tamper_detector.v`, `tests/tb_admin_sequence.v`, `tests/tb_recovery_controller.v`.

## Ordered features

1. Register/latch tamper button pulses so an event cannot be lost; latch remains until reset or validated override. `feat(tamper): latch detected tamper presses`.
2. Admin progress 0,1,2,3 and completion after **LEFT, UP, LEFT, UP**. Wrong press resets or restarts on LEFT; no repeated completion when button held. `feat(admin): recognize left-up-left-up sequence`.
3. `recovery_controller` accepts admin sequence *and* 16-bit `ADMIN_CODE` match, produces exactly one clock pulse when authorized. `feat(admin): require code with admin sequence`.
4. Verification: ensure tamper priority; recovery only clears tamper/attempt counters, never causes UNLOCKED. State transition logic remains Dev1-owned; Dev4 wires the parts. `test(admin): cover unauthorized recovery and tamper priority`.

## Tests

LEFT UP LEFT UP success; LEFT LEFT UP fails; LEFT UP RIGHT UP fails (manager decides how right tamper affects progress); debounced input should generate only 1 event per hold; wrong code cannot recover; correct code without sequence cannot recover; simultaneous tamper and recovery must not unlock; recovery clears tamper only via validated event; after lockout expiry ordinary PIN still blocked while tamper latched.

## Integration note

Consume pulses from Dev1's debouncers instantiated by Dev4; do **not** attach raw BTNL/BTNU/BTNR inside these modules. Use interface from `INTERFACE_CONTRACTS.md` exactly. Admin sequence alone is not sufficient for real security; this system remains a demonstration.

## Handoff

Transition table, sequence traces, tests, wrong-code behavior, exact clear signal polarity. Mention any human-approved change to the admin policy.
