# Dev fixture: OpenSSL DER → `create_fortgate_witness`

End-to-end **happy path** for a clean machine: generate a synthetic RSA-2048 X.509 cert with OpenSSL, then produce a blinded witness via the Rust core.

This is for **local development / smoke only**. Do not use real e.firma private keys.

## Prerequisites

- OpenSSL (`openssl version`)
- Rust toolchain from repo root `rust-toolchain.toml` (1.88.0)
- Clone of this repo

## 1. Generate `mock.der`

From the **repository root**:

```bash
mkdir -p sdk-ts/tests/fixtures
openssl req -x509 -newkey rsa:2048 -nodes -keyout /tmp/fg.key \
  -out sdk-ts/tests/fixtures/mock.der -outform DER -days 365 \
  -subj "/uniqueIdentifier=TESTRFC12345678901"
```

Notes:

- Key size **must** be RSA-2048 (parser rejects other sizes).
- Subject value is a stand-in RFC string; change it if you need another fixture value.
- Private key `/tmp/fg.key` is only needed to mint the self-signed cert — the SDK path below consumes the **public DER only**.
- A committed fixture already lives at `sdk-ts/tests/fixtures/mock.der` if you prefer not to regenerate.

Same OpenSSL recipe is documented in [`sdk-ts/README.md`](../../sdk-ts/README.md) and [`CONTRIBUTING.md`](../../CONTRIBUTING.md).

## 2. Accepted RFC subject OIDs (where enforced)

The parser extracts the RFC / identifier from the certificate **subject DN**. Supported OIDs are defined in [`open/client-sdk/src/cert_parser.rs`](../client-sdk/src/cert_parser.rs):

| OID | Meaning | How you get it |
|-----|---------|----------------|
| `2.5.4.45` | X.509 uniqueIdentifier (SAT e.firma style) | Real / SAT-like certs |
| `0.9.2342.19200300.100.1.1` | `uid` (RFC 4519) | OpenSSL `-subj "/uid=..."` |
| `0.9.2342.19200300.100.1.44` | OpenSSL `uniqueIdentifier` short name | OpenSSL `-subj "/uniqueIdentifier=..."` (command above) |

Code anchors:

- Constants: `OID_X509_UNIQUE_IDENTIFIER`, `OID_USERID`, `OID_OPENSSL_SUBJ_UNIQUE_IDENTIFIER` in `cert_parser.rs`
- Lookup: `extract_rfc()` walks `cert.subject().iter_attributes()` and accepts those three OIDs
- Errors: `CertParseError::RfcNotFound` if none match; `InvalidModulusBits` if not RSA-2048

## 3. Happy path A — integration test (recommended)

Parses the committed (or regenerated) fixture and asserts the RFC + 64 modulus limbs:

```bash
cd open/client-sdk
cargo test --test openssl_fixture
```

Expected:

```
running 1 test
test parse_mock_der_fixture ... ok
```

Test source: [`open/client-sdk/tests/openssl_fixture.rs`](../client-sdk/tests/openssl_fixture.rs)  
Fixture path used by the test: `sdk-ts/tests/fixtures/mock.der` (via `include_bytes!`).

## 4. Happy path B — call `create_fortgate_witness` yourself

Public API in [`open/client-sdk/src/lib.rs`](../client-sdk/src/lib.rs):

```rust
// cargo test / bin / example that depends on fortgate-id-core
let der = std::fs::read("sdk-ts/tests/fixtures/mock.der")?;
// or: include_bytes!("../../sdk-ts/tests/fixtures/mock.der");

let package = fortgate_id::create_fortgate_witness(&der)?;
// package.rfc_commitment  — hex commitment
// package.salt            — blinding salt
// package.nullifier_hash  — nullifier
// package.modulus_limbs   — 64 × u32 RSA limbs
// package.exponent        — RSA public exponent
// package.detected_tier   — hardware tier hint
```

Flow inside the crate:

1. `parse_sat_certificate(cert_der)` → RFC + RSA limbs/exponent  
2. `BlindedWitnessGenerator::generate_package(...)` → commitments  
3. Return `BlindedWitnessPackage`

### Minimal one-shot check (optional)

From `open/client-sdk`, you can temporarily assert the full witness path in a local test (not required for merge of this doc):

```rust
let der = include_bytes!("../../../sdk-ts/tests/fixtures/mock.der");
let pkg = fortgate_id::create_fortgate_witness(der).expect("witness");
assert_eq!(pkg.modulus_limbs.len(), 64);
assert!(!pkg.rfc_commitment.is_empty());
```

## 5. TypeScript / WASM smoke (optional)

Same DER, after WASM build:

```bash
cd sdk-ts
npm install
npm run build:wasm   # needs wasm-pack
npm test             # expects sdk-ts/tests/fixtures/mock.der
```

## Expected successful outcome

| Step | Success signal |
|------|----------------|
| OpenSSL | `sdk-ts/tests/fixtures/mock.der` exists, ~800 bytes DER |
| `cargo test --test openssl_fixture` | `parse_mock_der_fixture ... ok` |
| `create_fortgate_witness` | `Ok(BlindedWitnessPackage)` with non-empty commitment/salt/nullifier and **64** modulus limbs |
| Failure modes | Wrong key size → `InvalidAlgorithm` / `InvalidModulusBits`; subject without accepted OID → `RfcNotFound` |

## One-liner sequence (copy-paste)

```bash
# from repo root
mkdir -p sdk-ts/tests/fixtures
openssl req -x509 -newkey rsa:2048 -nodes -keyout /tmp/fg.key \
  -out sdk-ts/tests/fixtures/mock.der -outform DER -days 365 \
  -subj "/uniqueIdentifier=TESTRFC12345678901"
cd open/client-sdk && cargo test --test openssl_fixture
```

## Related docs

- [`CONTRIBUTING.md`](../../CONTRIBUTING.md) — fixture + core test setup  
- [`sdk-ts/README.md`](../../sdk-ts/README.md) — OpenSSL command + OID notes  
- [`open/client-sdk/tests/fixtures/README.md`](../client-sdk/tests/fixtures/README.md) — other DER fixtures (negative cases)  
- [`AGENTS.md`](../../AGENTS.md) — crypto invariants (do not change without tests)
