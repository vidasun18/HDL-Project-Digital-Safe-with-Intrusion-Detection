# Local Tool Setup (Windows / Linux)

## Icarus Verilog

- Windows: install Icarus Verilog and ensure `iverilog` and `vvp` are on PATH. MSYS2 users can use UCRT64 package `mingw-w64-ucrt-x86_64-iverilog` if available in their configured repositories; verify actual package name in pacman. WSL Ubuntu is also supported.
- Ubuntu/WSL: `sudo apt update && sudo apt install -y iverilog`.
- Verify: `iverilog -V` and `vvp -V`.
- From repo root: `bash scripts/run_tests.sh`; on PowerShell without bash use WSL or Git Bash.

## Vivado

- Use current AMD Vivado installation with Artix-7 support and correct 50T/100T target.
- Create an RTL project, import `digital_safe.v` plus `rtl/*.v`, add `constraints/nexys_a7_demo.xdc`, top=`digital_safe`.
- Check warnings, I/O banks and pin mapping before generating bitstream.

## AI-agent tools

Use any agent supporting repository instructions (`AGENTS.md`, `GEMINI.md`, `.agent/rules.md`). No MCP tools, Figma accounts, databases or agents-as-GitHub-collaborators are needed. Agent output requires human review and tests.
