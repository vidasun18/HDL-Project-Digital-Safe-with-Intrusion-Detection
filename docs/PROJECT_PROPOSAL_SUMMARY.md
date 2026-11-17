# Revised Project Proposal: FPGA-Based Laboratory Access Control and Intrusion Detection

**Platform:** Digilent Nexys A7, Artix-7 FPGA, 100 MHz; **50T/100T variant to be confirmed against the physical board**.  
**Team:** Four developers (Developer 4 is project manager).  
**Prepared:** 9 November 2026.  
**Original submission deadline:** **Friday, 13 November 2026**.  
**Requested extended submission deadline:** **Friday, 20 November 2026** (one week / 7 calendar days, **subject to supervisor approval**).  
**Hardware scope:** **FPGA-board demonstration only** using switches, directional pushbuttons, LEDs and eight-digit seven-segment display; no motor, relay, solenoid, real door mechanism or external security sensor.

## Problem and current position

The repository contains `digital_safe.v` with a preserved top-level board interface, but core signals remain placeholders rather than a verified end-to-end controller. The revision is a concentrated, test-driven recovery plan, not a claim of completed functionality.

## Educational MVP

Synchronous 16-bit demo PIN capture/comparison; synchronized and debounced inputs; LOCKED/CHECKING/UNLOCKED/ALARM/LOCKOUT FSM; failed-attempt counter; one-second clock enable, alarm and lockout timing; simulated tamper latch; LEFT-UP-LEFT-UP sequence plus admin code; visible LED lock/alarm state and seven-segment status/countdown; integration tests and a Nexys A7 board demonstration.

## Developer responsibilities

- **Developer 1:** PIN, debounce, capture, main FSM, relock and unit tests.
- **Developer 2:** Failed-attempt counter, 1-second enable tick, countdown timer, alarm blink and tests.
- **Developer 3:** Tamper latch, sequence recognizer, authorized admin recovery and tests.
- **Developer 4 / manager:** Display, exact board variant identification, XDC/Vivado configuration, top-level integration, CI, evidence and documentation.

## One-week extension recovery checkpoints

| Dates (2026) | Gate |
|---|---|
| **9-10 Nov** | Four roles acknowledged; contracts frozen; updated `dev` baseline; unit-test branches started. |
| **11-13 Nov** | Developer modules and self-checking unit tests; first evidence/branch links by 11 Nov. |
| **14-16 Nov** | Integrate submodules and display; top-level self-checking regression; confirm 50T/100T by 16 Nov. |
| **17-18 Nov** | Vivado synthesis, implementation, DRC/timing review and board bring-up for **confirmed** variant. |
| **19 Nov** | End-to-end onboard FPGA demonstration and final documentation review. |
| **20 Nov** | Final verification, archive and submission **if extension approved**. |

## Requested approval and acceptance

Request an extension **from 13 November to 20 November 2026**. Evidence should include reviewed RTL and testbenches, test logs, actual Vivado results when available, and physical board demonstration evidence. No FPGA device variant, timing closure or working board demo should be represented as verified before testing. If the extension is declined or a gate slips, disclose the status and obtain supervisor direction instead of silently reducing requirements.
