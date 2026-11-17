# Git Collaboration and Review Conventions

## Branches

- `main`: release snapshots only.
- `dev`: integration branch.
- Developer features start **from current `origin/dev`**: `feature/pin-fsm`, `feature/attempts-timers`, `feature/tamper-admin`, `feature/display-board`, `test/safe-regression`, `docs/proposal`.
- `docs/agent-handoff` contains this starter kit first, and is merged into `dev` after review.
- Avoid permanent `dev1`, `dev2`, `frontend`, `backend` or `mvp` branches.

## First-time safe commands

```bash
git clone https://github.com/vidasun18/HDL-Project-Digital-Safe-with-Intrusion-Detection.git
cd HDL-Project-Digital-Safe-with-Intrusion-Detection
git fetch origin
git status
git log --oneline --graph --decorate --all -12
# Manager: review one-commit difference between origin/main and origin/dev before sync.
git switch dev
git pull --ff-only origin dev
# AFTER manager syncs dev with main and merges starter-kit PR:
git switch -c feature/pin-fsm
```

## Typical feature PR workflow

```bash
git status
git add rtl/pin_compare.v tests/tb_pin_compare.v
git commit -m "feat(pin): compare submitted pin against parameter"
git push -u origin feature/pin-fsm
# Open PR: feature/pin-fsm -> dev; attach terminal tests and expected waveforms.
```

Do not paste prompt symbols like `PS C:\...>` when entering commands. Never force-push or merge without explicit project-manager approval. If local changes exist, do not overwrite them or use `git reset --hard`.

## Conventional commit examples for the 4 roles

| Developer | Feature | Example message |
|---|---|---|
| 1 | safe reset | `feat(fsm): initialize the safe in locked state` |
| 1 | configurable PIN | `feat(pin): compare a captured hexadecimal PIN` |
| 1 | debouncing | `feat(input): debounce board buttons into one-cycle pulses` |
| 1 | capture | `feat(pin): capture switches when submit is pressed` |
| 1 | unlock | `feat(fsm): unlock after a verified PIN` |
| 1 | relock | `feat(fsm): relock on down-button pulse` |
| 2 | failed attempts | `feat(security): count failed PIN attempts` |
| 2 | timebase | `feat(time): add configurable one-second enable` |
| 2 | timer | `feat(time): implement reusable countdown timer` |
| 2 | alarm trigger | `feat(alarm): request alarm after third failure` |
| 2 | blinking | `feat(alarm): blink indicator while alarm is active` |
| 3 | tamper | `feat(tamper): latch detected tamper presses` |
| 3 | admin input | `feat(admin): recognize left-up-left-up sequence` |
| 3 | admin guard | `feat(admin): require administrator code for recovery` |
| 3 | recovery | `feat(admin): emit authorized recovery pulse` |
| 4 | segment decoder | `feat(display): decode hexadecimal segments` |
| 4 | multiplexing | `feat(display): multiplex eight seven-segment digits` |
| 4 | status UI | `feat(display): show state attempts and countdown` |
| 4 | board pinout | `build(board): add verified Nexys A7 XDC mapping` |
| 4 | simulation | `ci(test): add self-checking safe regression` |
| 4 | handover | `docs(project): record architecture test evidence and board demo` |

## Pull request requirements

Scope and user story; files changed; exact test command and output; assertions covered; known limitations; interface modifications; oscilloscope/board photo **only if genuinely measured**. Ask for at least one human reviewer; Dev 4 merges to `dev` after CI passes, then release review to `main`.

## Recovery baseline (9 Nov 2026)

Observed `main` ahead of `dev` by one commit; both branches contain `README.md` and `digital_safe.v`. Do not infer that active team work exists just from screenshots; confirm updates through PRs, commits and tests.
