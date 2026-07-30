# Poseidon Rust / Noir alignment

This note explains how to verify the BN254 Poseidon path used by Fortgate ID
without confusing cryptographic alignment with hex serialization differences.

## Canonical Rust vector

The source of truth for byte-for-byte expected values is
[`open/client-sdk/tests/fixtures/poseidon_vectors.json`](../client-sdk/tests/fixtures/poseidon_vectors.json),
validated by [`open/client-sdk/tests/poseidon_vectors.rs`](../client-sdk/tests/poseidon_vectors.rs).

| RFC input | Salt hex | Domain | Expected RFC commitment hex | Expected nullifier hex |
| --- | --- | --- | --- | --- |
| `VECTOR_RFC_DEMO_01` | `01000000000000000000000000000000000000000000000000000000000000ab` | `0x4647` (`FG`) | `b46d4f1f8cc8f988f99d31ec6fa7eef0a45ef7b2d9f9e1c0da5b520797af1829` | `7fe171332cb246e1d9536efe999cd5e4a211adc8dd807f6e2c48b993d78d9428` |

The Rust test recomputes both values through
`BlindedWitnessGenerator::commitment_nullifier_hex(rfc, &salt)` and compares the
result against the JSON fixture.

## Verify the Rust side

From the repository root:

```bash
cd open/client-sdk
cargo test --test poseidon_vectors
```

That command verifies the production Rust field conversion and Poseidon output:

- RFC string -> UTF-8 bytes -> SHA-256 -> BN254 field element.
- Salt bytes -> BN254 field element.
- Commitment = `hash_2([rfc, salt])`.
- Nullifier = `hash_2([rfc, 0x4647])`.

## Verify the Noir smoke package

The Noir smoke package lives in
[`open/proto-poseidon-check`](../proto-poseidon-check/README.md). It checks that
Nargo 0.31.x can execute the same conceptual Poseidon pipeline and that the
commitment and nullifier are distinct values.

```bash
noirup --version 0.31.0
cd open/proto-poseidon-check
nargo test
```

The product circuit in [`open/proto/src/main.nr`](../proto/src/main.nr) uses the
same `hash_2([rfc, salt])` commitment and `hash_2([rfc, 0x4647])` nullifier
shape after RSA verification.

## Hex serialization caveat

Do not compare Noir `Field::to_be_bytes` output directly to the JSON fixture
hex. The fixture values are Rust-side Ark BN254 compressed field serialization,
produced by `fr_to_canonical_hex` in
[`open/client-sdk/src/field_encoding.rs`](../client-sdk/src/field_encoding.rs).
Noir's `Field::to_be_bytes` representation can differ even when the underlying
field element and Poseidon computation are correct.

Use this rule of thumb:

- Rust fixture equality belongs in `cargo test --test poseidon_vectors`.
- Noir execution sanity belongs in `cd open/proto-poseidon-check && nargo test`.
- A hex mismatch between Ark compressed bytes and Noir `Field::to_be_bytes` is a
  serialization-format mismatch unless the field computation itself changed.

If the RFC field encoding, salt encoding, domain separator, or Poseidon input
order changes, update the Rust JSON fixture, Rust vector test, Noir smoke README,
and product-circuit documentation together.