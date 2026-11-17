#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if ! command -v iverilog >/dev/null 2>&1 || ! command -v vvp >/dev/null 2>&1; then
  echo "ERROR: Install Icarus Verilog (iverilog and vvp)." >&2
  exit 2
fi
if [ ! -f digital_safe.v ]; then echo "ERROR: digital_safe.v is missing" >&2; exit 2; fi
mkdir -p build
shopt -s nullglob
rtl_files=(rtl/*.v)
# Compile the integrated top and its display RTL before running the smoke test.
iverilog -g2012 -Wall -s tb_top_smoke -o build/tb_top_smoke.vvp digital_safe.v "${rtl_files[@]}" tests/tb_top_smoke.v
vvp build/tb_top_smoke.vvp
# New unit tests, when present, are discovered automatically by tb_* naming.
unit_count=0
for tb in tests/tb_*.v; do
  if [ "$tb" = "tests/tb_top_smoke.v" ]; then continue; fi
  name="$(basename "$tb" .v)"
  iverilog -g2012 -Wall -s "$name" -o "build/$name.vvp" digital_safe.v "${rtl_files[@]}" "$tb"
  vvp "build/$name.vvp"
  unit_count=$((unit_count+1))
done
echo "PASS: top smoke and ${unit_count} additional unit testbenches."
