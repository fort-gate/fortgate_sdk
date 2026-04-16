#!/usr/bin/env bash
# Genera bindings Kotlin y Swift desde el UDL (requiere uniffi-bindgen en PATH).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
UDL="$ROOT/open/client-sdk/src/fortgate_id.udl"
OUT_KT="${1:-$ROOT/sdk-bindings/kotlin}"
OUT_SWIFT="${2:-$ROOT/sdk-bindings/swift}"

command -v uniffi-bindgen >/dev/null 2>&1 || {
  echo "Install: cargo install uniffi_bindgen --version 0.28.3"
  exit 1
}

mkdir -p "$OUT_KT" "$OUT_SWIFT"
uniffi-bindgen generate "$UDL" --language kotlin --out-dir "$OUT_KT"
uniffi-bindgen generate "$UDL" --language swift --out-dir "$OUT_SWIFT"
echo "Kotlin: $OUT_KT"
echo "Swift: $OUT_SWIFT"
