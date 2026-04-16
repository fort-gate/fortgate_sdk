#!/bin/bash
echo "🛡️ Building Open Core: Fortgate ID SDK"
cd open/client-sdk
cargo build --release
wasm-pack build --target web
echo "✅ Open Core build complete."
