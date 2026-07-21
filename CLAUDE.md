# CLAUDE.md

Guidance for Claude Code when working in `fort-gate/fortgate_sdk`.

## Project overview

Open-source Fortgate ID SDK: e.firma + ZK (Poseidon / Noir / SP1).

- `open/client-sdk/` — `fortgate-id-core`
- `open/client-sdk/sp1-prover/` — SP1 workspace
- `open/proto/` — Noir circuit
- `sdk-ts/` — WASM TypeScript package
- `open/docs/` — product docs

Pinned toolchain: Rust 1.88.0 (`rust-toolchain.toml`).

## Commands

```bash
cd open/client-sdk && cargo test && cargo clippy -- -D warnings
cd open/client-sdk/sp1-prover && cargo check -p fortgate-id-program
SP1_SKIP_PROGRAM_BUILD=true cargo check -p fortgate-id-script
cd sdk-ts && npm run build:wasm && npm test
```

## Invariants

Field encoding and SP1 stdin must stay aligned across Rust, Noir, and SP1 guest/host. See `open/client-sdk/src/field_encoding.rs` and `AGENTS.md`.
