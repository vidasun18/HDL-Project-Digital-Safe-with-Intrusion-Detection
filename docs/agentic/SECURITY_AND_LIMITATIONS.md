# Educational Prototype Security Boundary

This design is a **teaching demonstration** and is not appropriate as the sole security control for an occupied university laboratory.

Known limitations:
- A hardcoded 16-bit USER_PIN and ADMIN_CODE in publicly accessible Verilog are not secure secrets.
- Slide switches reveal submitted PIN bits and allow shoulder surfing; no tamper-resistant keypad or lock sensor exists.
- FPGA configuration is volatile unless external configuration memory is used and managed.
- The current top-level has **no door actuator driver** and no approved emergency egress interface.
- Tamper is a pushbutton simulation, not a monitored door/contact sensor.
- FPGA power loss, fault handling, emergency exit, and accessibility requirements need a separate safety design.

Deployment gate: obtain university/facilities approval, access-control security review, engineering design for isolated drivers/voltage, independent emergency egress, mechanical fail-safe/fail-secure policy, audit logging and operational maintenance before any connection to a real lab door. Never connect a solenoid to an FPGA GPIO.

For this deliverable, use onboard LEDs and seven-segment display to represent lock status only.
