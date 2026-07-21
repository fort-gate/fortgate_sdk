# AGENTS.md

Guidance for coding agents working on the Fortgate public SDK (`fort-gate/fortgate_sdk`).

## Project overview

Open-source KYC SDK: prove identity attributes from government digital signatures (Mexico SAT e.firma) using ZK proofs.

- `open/client-sdk/` — `fortgate-id-core`: X.509 parser, BN254 encoding, Poseidon, blinded witness, WASM + UniFFI.
- `open/client-sdk/sp1-prover/` — SP1 guest, host, shared types.
- `open/proto/` — Noir circuit (`fortgate_id_proto`).
- `sdk-ts/` — TypeScript package over WASM.
- `open/docs/` — Whitepapers and implementation plan.

Toolchain: `rust-toolchain.toml` (Rust 1.88.0 + rustfmt + clippy).

## Common commands

```bash
cd open/client-sdk && cargo test
cd open/client-sdk && cargo clippy -- -D warnings
cd open/client-sdk/sp1-prover && cargo check -p fortgate-id-program
SP1_SKIP_PROGRAM_BUILD=true cargo check -p fortgate-id-script
cd sdk-ts && npm run build:wasm && npm test
cd open/proto-poseidon-check && nargo test
```

## Architecture invariants

Keep Rust core, Noir, and SP1 byte-for-byte aligned.

- RFC scalar = `Fr::from_be_bytes_mod_order(SHA256(utf8(rfc)))`.
- Salt = 32 random bytes, same reduction.
- Nullifier domain separator = `0x4647` ("FG").
- SP1 stdin order: Limbs64 modulus, u32 exponent, Limbs64 signature, `[u8;32]` hashed_message, `[u8;32]` rfc_commitment.
- RSA-2048 only; RFC OIDs: `2.5.4.45`, uid, uniqueIdentifier fixture OID.
