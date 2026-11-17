# Manager Standup and PR Review Tracker

Use this tracker **daily through 20 November 2026**. Original deadline is **13 November**; requested one-week extension is **20 November**, **not yet approved**. Status requires evidence (branch, commit, test log, review or demo). Final goal is an **onboard FPGA demonstration**, not a physical lock.

| Developer | Primary output | Current status | Branch / PR | Test evidence | Blocker | Next review |
|---|---|---|---|---|---|---|
| 1 | PIN, debounce, capture, safe FSM | Not verified | TBD | TBD | TBD | TBD |
| 2 | counter, tick, timers, alarm | Not verified | TBD | TBD | TBD | TBD |
| 3 | tamper, admin, override | Not verified | TBD | TBD | TBD | TBD |
| 4 | display, pinout, integration, tests, docs | `feature/display-board` work in progress; Dev 4 files prepared locally | local branch; commit/push pending | Display and top-level VVP simulations pass from local RTL; Windows Icarus compiler exits abnormally after emitting VVP; Linux CI pending | Board part remains unknown; Dev 1-3 RTL files are present only as untracked local work and are not included in this feature branch | Linux CI and dependency integration review |

## Mandatory dated check-ins

- **10 Nov:** feature branch and scope acknowledgement from every developer.
- **11 Nov:** 48-hour proof: one working module/test and a branch link per developer.
- **13 Nov:** module-level tests reviewed.
- **16 Nov:** integrated simulation and confirmed board variant (50T/100T).
- **18 Nov:** Vivado hardware implementation status and timing/DRC evidence.
- **19 Nov:** recorded onboard demo and report review.
- **20 Nov:** final submission, conditional on supervisor granting the extension.

## Lightweight daily report format

`Developer/branch | completed module | test command + outcome | next module | blocker | request to manager`

## PR review checklist

- [ ] Does code stay inside owner's paths?
- [ ] Are ports exactly per contract (or approved change recorded)?
- [ ] Does RTL synthesize? Any latch or generated clock?
- [ ] Does self-checking test cover normal, reset, failure, boundaries?
- [ ] Does timing work for tiny sim CLK_HZ and board CLK_HZ?
- [ ] Does the PR accurately distinguish simulation/synthesis/board outcomes?
- [ ] Does it avoid printing secrets, unsafe direct GPIO actuator wiring, and invented hardware claims?
- [ ] Is human review recorded before merge?
