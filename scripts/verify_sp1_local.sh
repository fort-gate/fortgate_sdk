#!/usr/bin/env bash
# Verifica que existan artefactos SP1 tras un `prove` real (no placeholder).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/open/client-sdk/sp1-prover/sp1_output}"

for f in proof.bin vkey.json; do
  p="$OUT/$f"
  if [[ ! -f "$p" ]]; then
    echo "Falta: $p"
    exit 1
  fi
  if [[ ! -s "$p" ]]; then
    echo "Vacío: $p"
    exit 1
  fi
done
echo "OK: $OUT contiene proof.bin y vkey.json no vacíos."
