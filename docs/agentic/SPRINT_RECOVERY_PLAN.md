# Compressed Recovery Sprint - 9 to 20 November 2026

**Original deadline:** Friday **13 November 2026**.  
**Requested extension:** **7 calendar days**, until Friday **20 November 2026**.  
**Approval status:** **Requested, not confirmed**.  
**Final hardware:** Onboard **Nexys A7 demonstration only** (LED, switches, buttons, 7-segment).  
**Board type:** **50T/100T unknown**; confirm silkscreen/part before Vivado implementation or bitstream generation.

This is a **high-risk, 12-day inclusive recovery window**, not a four-week plan. Four developers must work concurrently on the frozen `INTERFACE_CONTRACTS.md`. The repository was only a scaffold when reviewed on 9 Nov. Do not describe planned work as done.

## Dated milestones and evidence

| Date(s) | Deliverable | Evidence / acceptance gate | Responsibility |
|---|---|---|---|
| **9 Nov (Mon)** | Manager installs pack, synchronizes dev baseline, assigns ownership and confirms group communication. | Four acknowledgements, branch strategy, no destructive overwrite. | Dev 4 + all |
| **10 Nov (Tue)** | Developers branch from updated `dev`; agree ports, reset/event timing; first isolated feature/test. | Branch links, compilable unit + self-checking test in each workstream. | All |
| **11 Nov (Wed), 48h gate** | Early proof of progress: no silent inactivity. | Every owner posts commit, test command/result and blocker. Reassign smallest blocked tasks if needed. | Dev 4 reviews |
| **12-13 Nov (Thu-Fri)** | Complete highest-priority RTL: PIN/FSM, counters/timers/alarm, tamper/admin, decoder/display. | Owner-specific tests pass; failing tests clearly logged; no fake production placeholders. | Devs 1-3; Dev 4 display |
| **14-16 Nov (Sat-Mon)** | Integrate functional modules, reset and state priorities; run end-to-end test matrix. Identify 50T/100T board by **16 Nov**. | Full regression (valid PIN, relock, 3 failures, alarm-to-lockout, tamper, admin recovery); human-reviewed merges. | Dev 4 + all |
| **17-18 Nov (Tue-Wed)** | Vivado synthesis, implementation, DRC, timing; program confirmed Nexys A7 variant; fix board-only faults. | Reports and successful program logs. If hardware inaccessible, honestly record a blocked gate. | Dev 4 with all |
| **19 Nov (Thu)** | Demonstrate onboard behavior and collect evidence; freeze code. | Demo video/photos, observed board checklist, final unit/integration test logs. | All; Dev 4 leads |
| **20 Nov (Fri)** | Final supervisor-approved submission. | Repo release/commit, report/proposal, test summary, constraints, board evidence. | Dev 4 submits |

## Priority order for deadline protection

1. **Core system:** reset locked by default, correct PIN unlock indicator, failed PIN behavior, manual relock, debounced single submit.
2. **Security behaviors:** three-attempt alarm, timed lockout, tamper latch and restricted admin recovery.
3. **Presentation and release:** seven-segment status/countdown, LEDs, XDC, Vivado proof, recorded FPGA demonstration, final report.

All items remain planned requirements; if a lower-priority item slips, **do not silently drop it or imply completion**. Escalate to the supervisor with documented impact. If 50T/100T remains unconfirmed on 16 Nov, do not invent part selection or claim a successful bitstream; continue simulation until verified.

## 48-hour inactivity escalation

Each developer sends: `role | feature branch URL | module/test completed | exact test command and pass/fail | blocker | next action`. If no evidence by **11 Nov**, Dev 4 requests a narrow working patch and unit test, then records the delay in `MANAGER_TRACKER.md`. AI output alone is **not** evidence.

## Dependencies and safety

Dev 1 main FSM consumes Dev 2 event/timer interfaces and Dev 3 tamper/override events. Dev 4 owns integration. Stub only inside local testbenches if needed. No FPGA pin may drive a physical lock or relay: this is an onboard educational mock-up only. A submitted request for an extension **does not equal approval**. If the extension is not approved, seek supervisor guidance for the 13 Nov deadline and scope.
