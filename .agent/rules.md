# Workspace Rules - FPGA Digital Safe

1. Scope: FPGA educational prototype on Nexys A7; no web-stack assumptions or inherited UTAAS processes.
2. Read master `AGENTS.md` and role-specific docs before generating code.
3. Top-level `digital_safe.v` is managed by Developer 4; other developers create standalone RTL under `rtl/`.
4. Follow exact ports/polarities from `docs/agentic/INTERFACE_CONTRACTS.md`.
5. New features need isolated, self-checking simulation tests. No tests may hide failures with unconditional success.
6. Work on short-lived feature branches from updated `dev`; human review before merge into `dev`; `main` only for release.
7. No AI/bot GitHub collaborator accounts or auto-commits/pushes/PRs.
8. Demo PIN on switches is not suitable for a real security door; no direct lock actuator on FPGA GPIO.
