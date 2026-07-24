# Development DER fixture and witness smoke flow

This guide walks a clean development machine from a throwaway OpenSSL
certificate to the Rust `create_fortgate_witness` smoke path.

The same OpenSSL fixture flow is mentioned in
[`sdk-ts/README.md`](../../sdk-ts/README.md). This page keeps the Rust core path
in one place and links the parser checks that make the fixture valid.

## Prerequisites

- OpenSSL on `PATH`.
- Rust 1.88.0 from the repository `rust-toolchain.toml`.
- The repository root as the current working directory.

## Generate `mock.der`

Create a self-signed RSA-2048 certificate with an RFC-like test identifier in the
OpenSSL `uniqueIdentifier` subject attribute:

```bash
mkdir -p sdk-ts/tests/fixtures
openssl req -x509 -newkey rsa:2048 -nodes -keyout /tmp/fg.key \
  -out sdk-ts/tests/fixtures/mock.der -outform DER -days 365 \
  -subj "/uniqueIdentifier=TESTRFC12345678901"
```

Expected output:

- `/tmp/fg.key` contains the throwaway private key.
- `sdk-ts/tests/fixtures/mock.der` contains the DER certificate consumed by the
  Rust and TypeScript smoke tests.

Do not commit real keys, real certificates, or production identity data. The
fixture above is only for local development and CI-style smoke checks.

## Accepted RFC subject attributes

The Rust parser scans the certificate subject in
[`open/client-sdk/src/cert_parser.rs`](../client-sdk/src/cert_parser.rs). It
accepts the RFC value from these OIDs:

| Subject form | OID | Code constant |
| --- | --- | --- |
| SAT e.firma unique identifier | `2.5.4.45` | `OID_X509_UNIQUE_IDENTIFIER` |
| OpenSSL `uid=` / RFC 4519 userid | `0.9.2342.19200300.100.1.1` | `OID_USERID` |
| OpenSSL `-subj "/uniqueIdentifier=..."` fixture form | `0.9.2342.19200300.100.1.44` | `OID_OPENSSL_SUBJ_UNIQUE_IDENTIFIER` |

The same parser also requires an RSA public key and a 2048-bit modulus before the
certificate can become witness input.

## Run the Rust fixture test

The existing test
[`open/client-sdk/tests/openssl_fixture.rs`](../client-sdk/tests/openssl_fixture.rs)
loads `sdk-ts/tests/fixtures/mock.der`, checks that the fixture subject contains
`TESTRFC12345678901`, and calls `parse_sat_certificate`.

```bash
cd open/client-sdk
cargo test --test openssl_fixture
```

A successful run proves the DER fixture can be parsed and that the accepted OID
path produces the expected RFC string and 64 RSA modulus limbs.

## Call `create_fortgate_witness`

The public Rust helper lives in
[`open/client-sdk/src/lib.rs`](../client-sdk/src/lib.rs):

```rust
let der = std::fs::read("../../sdk-ts/tests/fixtures/mock.der")?;
let witness = fortgate_id::create_fortgate_witness(&der)?;
println!("commitment = {}", witness.rfc_commitment);
println!("nullifier = {}", witness.nullifier_hash);
```

For an in-repo smoke, the parser fixture test is the shortest happy path. If you
add an example binary later, it should call the same `create_fortgate_witness`
entrypoint after reading `sdk-ts/tests/fixtures/mock.der`.

Expected successful witness outcome:

- `rfc_commitment` is a 64-character hex string for the blinded RFC commitment.
- `salt` is a generated 32-byte salt encoded as hex.
- `nullifier_hash` is a 64-character hex string derived from the RFC and the
  Fortgate nullifier domain.
- `modulus_limbs` contains 64 little-endian `u32` limbs for the RSA-2048 modulus.
- `exponent` is the certificate RSA public exponent.

## TypeScript smoke path

After building the WASM package, the same DER fixture is also used by the
TypeScript smoke tests documented in [`sdk-ts/README.md`](../../sdk-ts/README.md):

```bash
cd sdk-ts
npm run build:wasm
npm test
```

Use the Rust fixture test first when you only need to confirm the DER and core
witness path; use the TypeScript path when changing WASM or SDK packaging.