# START HERE - Digital Safe Agent Pack

**Project:** FPGA-Based Laboratory Access Control and Intrusion Detection Prototype  
**Board:** Digilent Nexys A7 (Artix-7; 50T/100T variant **not yet confirmed** — inspect board markings and match Vivado part before hardware implementation)  
**Repository:** https://github.com/vidasun18/HDL-Project-Digital-Safe-with-Intrusion-Detection  
**Prepared:** 9 November 2026  
**Status:** Recovery kit for a four-developer team; not a completed implementation.
**Original deadline:** Friday, **13 November 2026**. **Requested extended deadline:** Friday, **20 November 2026** (one additional week; **awaiting supervisor approval**).
**Hardware goal:** **Nexys A7 onboard demonstration only**, using switches, buttons, LEDs and seven-segment display; no physical laboratory lock or electrical actuator.

## Why this package exists

The existing repository currently has `README.md` and a top-level `digital_safe.v`. The top-level defines board ports and parameters but leaves most behavior tied to constants. Do **not** mistake this scaffold for a functioning safe. `main` is one commit ahead of `dev` as observed on 9 Nov 2026; synchronize before assigning feature branches.

## Installation - manager only

1. Back up any uncommitted work: `git status`. Commit or stash your own changes before changing branches.
2. Run `git fetch origin`, then inspect `git log --oneline --graph --decorate --all -12` and `git diff origin/dev..origin/main`.
3. Bring `dev` up to date with `main` through your normal reviewed Git process, then base new feature branches on updated `dev`. **Do not force-push.**
4. Extract this ZIP **into the repository root**, beside the existing `digital_safe.v`. Keep the existing RTL and README intact.
5. Commit only the kit's new files on a `docs/agent-handoff` branch; open a PR targeting `dev` for review. Do not auto-merge or post to GitHub without a human decision.
6. Distribute `docs/agentic/ROLE_DEV_*.md` plus `docs/agentic/AI_START_PROMPTS.md` and tell each developer to read `AGENTS.md` and `docs/agentic/INTERFACE_CONTRACTS.md` first.
7. Decide whether the demo should **require the admin code in addition to the button sequence** (recommended). This pack assumes both, with default `ADMIN_CODE=16'hC0DE`.
8. Follow `docs/agentic/SPRINT_RECOVERY_PLAN.md`: developer branches and first test evidence by **11 Nov**, integrated simulation by **16 Nov**, Vivado/board checks by **18–19 Nov**, submit by **20 Nov** if extension is approved.

## Initial developer work order

- **Developer 1:** synchronizers, button debounce, PIN capture and comparison, safe main FSM.
- **Developer 2:** 1-second tick, failed attempt counter, countdown timing, alarm blink.
- **Developer 3:** tamper latch, LEFT-UP-LEFT-UP admin recognition, authorized recovery event.
- **Developer 4 (manager):** seven-segment display, LED/status mapping, top-level integration, XDC, tests, CI, documentation.

## Dates and priorities

The extension is exactly **seven calendar days: 13 -> 20 November 2026**; do not write a four-week plan. Prioritize a verified onboard demo. Treat confirmed 50T/100T Vivado part selection as a mandatory gate before generating or programming a bitstream. The 20 November deadline is **requested**, not yet officially granted. If the extension is denied, request supervisor guidance on scope and submission; do not claim it was approved.

## Non-negotiables

- Board I/O on `digital_safe.v` remains stable; see `INTERFACE_CONTRACTS.md`.
- No developer independently rewrites `digital_safe.v` except Developer 4 during reviewed integration.
- Implement and unit-test own modules; **do not claim board-tested unless actually tested on Nexys A7**.
- No AI agent identity needs GitHub collaborator access. Human members own commits, PRs and review.
- Do not drive a door actuator or solenoid directly from FPGA pins. The current target is a **demonstration prototype with LED-based lock status**; a real laboratory installation requires an approved security/electrical design.

## Files

- `AGENTS.md` - master instructions compatible with agent-aware tools.
- `CODEX.md`, `GEMINI.md`, `.agent/rules.md` - lightweight tool-specific guides.
- `docs/agentic/` - architecture, exact ports, roles, sprint, tests, safety, Git workflow, copy/paste prompts.
- `.github/workflows/hdl-ci.yml` - Icarus Verilog simulation checks; initially fails until RTL works.
- `tests/tb_top_smoke.v` - initial **functional** top-level test, not a fake compile-only check.
- `scripts/run_tests.sh` - common local/CI simulation entrypoint.
- `constraints/nexys_a7_demo.xdc` - Nexys A7 verified onboard pin mapping for current top-level ports, not a Vivado project file.

## Honest status reporting

A generated code file, a syntax check, passing simulation, successful synthesis, and a real board demo are **five different milestones**. Record which one was actually achieved for each PR.
