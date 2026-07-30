# fortgate_id_proto

`open/proto` contains the Noir product circuit for Fortgate ID. It verifies the
SAT e.firma RSA evidence and binds it to the same BN254/Poseidon field encoding
used by the Rust client SDK.

## Purpose

The circuit proves that a private RFC scalar belongs to a valid certificate
message without revealing the RFC string itself. The caller supplies the RSA-2048
public key, PKCS#1 v1.5 SHA-256 signature, hashed certificate message, RFC field
witness, and salt. The circuit verifies the RSA signature, checks the RFC
commitment, and returns a deterministic nullifier for the RFC.

The field conversion rules must stay aligned with
[`open/client-sdk/src/field_encoding.rs`](../client-sdk/src/field_encoding.rs):

- RFC string: `SHA256(UTF8(RFC_string))`, interpreted as a big-endian BN254 field
  element with modular reduction.
- Salt: 32 random bytes, interpreted with the same big-endian field rule.
- Nullifier domain: the small integer `0x4647` (`"FG"`) as a field element.

## Inputs

Public inputs:

- `modulus: [u32; 64]` - RSA-2048 public modulus limbs.
- `exponent: u32` - RSA public exponent.
- `hashed_message: [u8; 32]` - SHA-256 digest that the certificate signature is
  checked against.
- `rfc_commitment: pub Field` - expected Poseidon commitment for `[rfc, salt]`.

Private witness inputs:

- `signature: [u32; 64]` - RSA-2048 PKCS#1 v1.5 signature limbs.
- `rfc: Field` - RFC scalar, not the cleartext RFC string.
- `salt: Field` - random salt scalar used in the commitment.

## Assertions and output

The circuit enforces two assertions in
[`src/main.nr`](src/main.nr):

1. `rsa::verify_sha256_pkcs1v15(modulus, exponent, signature, hashed_message)`
   must return `true`.
2. `poseidon::bn254::hash_2([rfc, salt])` must equal the public
   `rfc_commitment`.

After those checks pass, the public return value is the nullifier:

```text
poseidon::bn254::hash_2([rfc, 0x4647])
```

This lets verifiers detect repeated presentations of the same RFC while keeping
both the cleartext RFC and salt private.

## Toolchain and commands

[`Nargo.toml`](Nargo.toml) requires Noir/Nargo `>=0.31.0` and pins `std` to
`v0.31.0`, so use a 0.31.x toolchain for this package.

```bash
noirup --version 0.31.0
cd open/proto
nargo check
```

`nargo check` is the product-circuit compile check. The Poseidon alignment smoke
lives separately in
[`open/proto-poseidon-check`](../proto-poseidon-check/README.md):

```bash
cd open/proto-poseidon-check
nargo test
```

## Alignment notes

- Rust canonical hex fixtures use Ark compressed field serialization in
  [`field_encoding.rs`](../client-sdk/src/field_encoding.rs).
- Noir `Field::to_be_bytes` is not byte-for-byte equivalent to Ark compressed
  serialization; the Poseidon smoke README calls out this format caveat so a
  contributor does not mistake serialization differences for hash mismatches.
- If `src/main.nr` changes any input order, public/private boundary, or domain
  separator, update the Rust vectors and the Poseidon smoke documentation in the
  same PR.
# Noir Circuit Documentation

This directory contains the Noir zero-knowledge (ZK) circuit implementation utilized for cryptographic verification within the `fortgate_sdk`.

---

## Overview

The Noir circuit handles zero-knowledge verification procedures, ensuring cryptographic checks and assertions are validated off-chain before state interactions.

---

## Circuit Architecture & Logic

### Core Components
* **Field Encoding:** Handles field conversions and cryptographic encoding rules defined in `field_encoding.rs`.
* **Poseidon Hash Checks:** Integrates Poseidon hash routines via `proto-poseidon-check` for zero-knowledge compliance.

### Specification Summary
* **Public Inputs:** State roots, public verification parameters, and commitment values.
* **Private Inputs (Witnesses):** Secret state proofs, pre-image values, and execution paths.
* **Assertions:** Mathematical constraints validating input integrity and cryptographic correctness.

---

## Development & Usage

Make sure you have [Nargo](https://noir-lang.org/docs/getting_started/installation/) installed.

### Verification Commands

Check circuit types and constraint compilation:
```bash
nargo check
