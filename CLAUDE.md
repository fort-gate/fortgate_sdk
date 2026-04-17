# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Fortgate ID is a KYC SDK that proves identity attributes from government digital signatures (starting with Mexico's SAT e.firma) using zero-knowledge proofs. The repo is a multi-language workspace built around one Rust core with three proving/binding frontends.

- `open/client-sdk/` — `fortgate-id-core` Rust crate: X.509 parser, BN254 field encoding, Poseidon commitments, blinded-witness generator, WASM + UniFFI bindings.
- `open/client-sdk/sp1-prover/` — Separate Cargo workspace with an SP1 guest (`program/`), host orchestrator (`script/`), and shared serde types (`sp1-shared/`).
- `open/proto/` — Noir circuit (`fortgate_id_proto`) that verifies RSA-2048 PKCS#1 v1.5 + SHA-256 and re-computes the Poseidon commitment.
- `sdk-ts/` — Thin TypeScript package that consumes the WASM build of the core.
- `open/docs/` — Whitepapers and the implementation plan. Read `WHITEPAPER_ES_MX.md` or the `EN_US` variant before making design-affecting changes.

Toolchain is pinned by `rust-toolchain.toml` (Rust 1.88.0 with rustfmt + clippy). `enterprise/` is gitignored IP — do not create files there unless asked.

## Common commands

Rust core (primary workspace):

```bash
cd open/client-sdk && cargo test                  # unit + integration tests
cd open/client-sdk && cargo clippy -- -D warnings # lint gate used by CI
cargo test --test openssl_fixture                 # single integration test
cargo test <name> -- --nocapture                  # single test by name
```

SP1 prover (separate workspace under `open/client-sdk/sp1-prover/`):

```bash
cargo check -p fortgate-id-program                # guest-only check
SP1_SKIP_PROGRAM_BUILD=true cargo check -p fortgate-id-script  # host check w/o SP1 toolchain
cargo build --release -p fortgate-id-script       # real build; requires cargo-prove
./target/release/fortgate-id-script <cert.der>    # or set FORTGATE_CERT_DER
```

The host **must** be built in `--release` — `ProverClient::new()` panics in debug. CI uses `SP1_SKIP_PROGRAM_BUILD=true` plus the committed ELF placeholder at `program/elf/riscv32im-succinct-zkvm-elf`; a real proving run must not set that flag so `sp1_build` regenerates the RISC-V ELF.

WASM + TypeScript SDK:

```bash
cd sdk-ts && npm run build:wasm   # wasm-pack build ../open/client-sdk --target nodejs --out-dir ../../sdk-ts/pkg
cd sdk-ts && npm test             # node tests/smoke_test.js; needs tests/fixtures/mock.der
./scripts/build_open.sh           # cargo build --release + wasm-pack build --target web
```

Generate a dev fixture cert (see `sdk-ts/README.md` for OID details):

```bash
openssl req -x509 -newkey rsa:2048 -nodes -keyout /tmp/fg.key \
  -out sdk-ts/tests/fixtures/mock.der -outform DER -days 365 \
  -subj "/uniqueIdentifier=TESTRFC12345678901"
```

UniFFI mobile bindings (requires `cargo install uniffi_bindgen --version 0.28.3`):

```bash
./scripts/generate_uniffi_bindings.sh [kotlin_out] [swift_out]
```

Noir circuit:

```bash
cd open/proto && nargo check
```

## Architecture invariants

Three implementations must stay byte-for-byte aligned; breaking one silently invalidates proofs.

**Field encoding (BN254 `Fr`).** Defined in `open/client-sdk/src/field_encoding.rs` and mirrored in `open/proto/src/main.nr`:
- `rfc` scalar = `Fr::from_be_bytes_mod_order(SHA256(utf8(rfc_string)))`.
- `salt` scalar = 32 random bytes reduced the same way.
- Nullifier domain separator = literal `0x4647` ("FG").
- Commitments/nullifiers are serialized as 64-char hex (`ark_serialize` compressed, 32 bytes).

**SP1 stdin contract.** Host writes (`script/src/main.rs`) and guest reads (`program/src/main.rs`) in this exact order: `Limbs64 modulus`, `u32 exponent`, `Limbs64 signature`, `[u8; 32] hashed_message` (SHA-256 of TBSCertificate DER), `[u8; 32] rfc_commitment` (canonical `Fr` bytes). `Limbs64` lives in `fortgate-sp1-shared` and is 64 × `u32` little-endian limbs; the same layout backs `modulus_limbs` / `signature_limbs` in the core via `bigint_to_limbs`.

**Certificate parsing (`cert_parser.rs`).** RSA-2048 is the only accepted key size (`InvalidModulusBits` otherwise). RFC extraction accepts three OIDs in order: `2.5.4.45` (SAT e.firma, canonical), `0.9.2342.19200300.100.1.1` (`uid`), and `0.9.2342.19200300.100.1.44` (what `openssl req -subj "/uniqueIdentifier=..."` actually emits — required for test fixtures).

**Host ↔ core coupling.** `fortgate-id-script` depends on `fortgate-id-core` via `path = "../.."`, so changes to the core's public API (`create_fortgate_witness`, `parse_sp1_inputs`, `field_encoding::hex_decode_fr_bytes`) must keep the SP1 host compiling. `lib.rs` re-exports `parse_sp1_inputs` and `Sp1CertInputs` for this reason.

**UniFFI scaffolding.** `src/fortgate_id.udl` is the source of truth for mobile bindings; `build.rs` runs `uniffi_build::generate_scaffolding` and `lib.rs` calls `uniffi::include_scaffolding!`. Editing the UDL requires regenerating bindings via `scripts/generate_uniffi_bindings.sh`.

## CI (`.github/workflows/ci.yml`)

Three jobs on Rust 1.88.0: `rust-core` (`cargo test` + `cargo clippy -- -D warnings` in `open/client-sdk`), `sp1-guest-check` (`cargo check` for guest, then host with `SP1_SKIP_PROGRAM_BUILD=true`), and `noir-proto` (best-effort `nargo check`, `continue-on-error: true`). Match these locally before pushing.
