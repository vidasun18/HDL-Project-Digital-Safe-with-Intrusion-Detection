# CODEX - Instructions for OpenAI Codex

Read `AGENTS.md`, `docs/agentic/INTERFACE_CONTRACTS.md` and the one assigned `ROLE_DEV_*.md` before editing.

- First report current branch, `git status`, files examined, and proposed changes.
- Only implement the explicitly assigned feature; do not generate the whole system in one step.
- Match canonical module names and port declarations in `INTERFACE_CONTRACTS.md`.
- Use `iverilog -g2012`, `vvp`, waveform dumps only as secondary evidence; prioritize assertions/self-checks.
- No claim of FPGA verification without Vivado synthesis/implementation and a board demonstration.
- Stop and ask the human developer before commit, push, PR creation, merging, deleting, or altering another owner's file.
- Report blocked dependencies as an interface problem with exact expected and observed signals, not as a reason to rewrite the project.
