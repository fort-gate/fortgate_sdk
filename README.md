# Fortgate SDK

SDK open source de **KYC con Zero-Knowledge Proofs**: convierte una e.firma (certificado X.509 del SAT) en un testigo ciego y artefactos verificables, sin exponer el RFC en claro.

Licencia: [Apache-2.0](LICENSE).

## Qué incluye

| Ruta | Contenido |
|------|-----------|
| `open/client-sdk/` | Crate Rust `fortgate-id-core` (parseo, Poseidon, witness, WASM/UniFFI) |
| `open/client-sdk/sp1-prover/` | Guest/host SP1 para prueba ZK |
| `open/proto/` | Circuito Noir (RSA-2048 + Poseidon) |
| `open/proto-poseidon-check/` | Smoke tests Noir de Poseidon |
| `open/docs/` | Whitepapers y plan de implementación |
| `sdk-ts/` | Empaque TypeScript / WASM |

## API pública (`fortgate-id-core`)

Exports estables pensados para consumidores (apps, enterprise, integradores):

- `create_fortgate_witness(cert_der) -> BlindedWitnessPackage`
- `parse_sp1_inputs` / `Sp1CertInputs`
- `BlindedWitnessGenerator`
- `FortgateError` / `CertParseError`
- Bindings: UniFFI (`fortgate_id.udl`) y WASM (`create_fortgate_witness_wasm`)

Invariantes criptográficos (no romper sin test vector): encoding BN254 en `field_encoding.rs`, nullifier domain `0x4647`, contrato stdin SP1 documentado en `open/client-sdk/sp1-prover/`.

## Usar como dependencia Cargo

```toml
[dependencies]
fortgate-id-core = { git = "ssh://git@github.com/fort-gate/fortgate_sdk.git", tag = "v0.1.0-alpha.1", package = "fortgate-id-core" }
```

Desarrollo local (repos hermanos):

```toml
fortgate-id-core = { path = "../fortgate_sdk/open/client-sdk" }
```

## Desarrollo

Toolchain: Rust **1.88.0** (`rust-toolchain.toml`).

```bash
# Core
cd open/client-sdk && cargo test && cargo clippy -- -D warnings

# SP1 (sin toolchain Succinct completo)
cd open/client-sdk/sp1-prover
cargo check -p fortgate-id-program
SP1_SKIP_PROGRAM_BUILD=true cargo check -p fortgate-id-script

# TypeScript / WASM
cd sdk-ts && npm install && npm run build:wasm && npm test

# Noir Poseidon smoke
cd open/proto-poseidon-check && nargo test
```

Scripts: `scripts/build_open.sh`, `scripts/generate_uniffi_bindings.sh`, `scripts/verify_sp1_local.sh`.

## Remoto

```bash
git remote add origin git@github.com:fort-gate/fortgate_sdk.git
```
