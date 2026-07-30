//! Tests del binding Poseidon BN254 (`hash_2`) que usa `open/proto/src/main.nr`.
//!
//! Los vectores del happy path se toman de los existentes en Rust
//! ([`open/client-sdk/tests/fixtures/poseidon_vectors.json`](../../client-sdk/tests/fixtures/poseidon_vectors.json),
//! verificados por `open/client-sdk/tests/poseidon_vectors.rs`). **No se re-deriva `Fr` aquí**:
//! la codificación sigue siendo la de `open/client-sdk/src/field_encoding.rs`
//! (`UTF-8 → SHA-256 → 32 bytes → Fr` big-endian `mod r`), que en Noir es
//! `bytes32_to_field(sha256(...))`.
//!
//! ## Cómo se relacionan los hex de Rust con los de aquí
//!
//! El JSON guarda los valores con serialización comprimida de Ark (`fr_to_canonical_hex`),
//! que es **little-endian**. Noir expone `Field::to_be_bytes`, que es **big-endian**. Son el
//! mismo elemento de campo con los bytes en orden inverso, así que el vector de Rust se ancla
//! aquí invirtiendo el hex, no re-calculándolo:
//!
//! | | JSON (LE, Ark) | Aquí (BE, entero canónico) |
//! |---|---|---|
//! | commitment | `b46d4f1f…97af1829` | `0x2918af97…1f4f6db4` |
//! | nullifier | `7fe17133…d78d9428` | `0x28948dd7…3371e17f` |
//!
//! Ejecutar con **Nargo 0.31.x o 0.32.x**: `nargo test`

use std::hash::poseidon::bn254::hash_2;
use std::hash::sha256;

/// Separador de dominio del nullifier: `"FG"` en ASCII.
/// Debe coincidir con `open/proto/src/main.nr` y con `domain_separator_fr()` en
/// `open/client-sdk/src/field_encoding.rs`.
global DOMAIN_SEPARATOR: Field = 0x4647;

/// `expected_rfc_commitment_hex` del JSON, con los bytes en orden big-endian.
global VECTOR_COMMITMENT: Field =
    0x2918af9707525bdac0e1f9d9b2f75ea4f0eea76fec319df988f9c88c1f4f6db4;

/// `expected_nullifier_hex` del JSON, con los bytes en orden big-endian.
global VECTOR_NULLIFIER: Field =
    0x28948dd793b9482c6e7f80ddc8ad11a2e4d59c99fe6e53d9e146b22c3371e17f;

/// `rfc` y `salt` del vector, reducidos a `Field` con la codificación de `field_encoding.rs`.
fn vector_inputs() -> (Field, Field) {
    // rfc = "VECTOR_RFC_DEMO_01" en UTF-8
    let utf8_rfc: [u8; 18] = [
        0x56, 0x45, 0x43, 0x54, 0x4f, 0x52, 0x5f, 0x52, 0x46, 0x43, 0x5f, 0x44, 0x45, 0x4d, 0x4f,
        0x5f, 0x30, 0x31,
    ];
    let rfc_fr = std::field::bytes32_to_field(sha256(utf8_rfc));

    // salt_hex = "01000000...000000ab"
    let mut salt: [u8; 32] = [0; 32];
    salt[0] = 0x01;
    salt[31] = 0xab;
    let salt_fr = std::field::bytes32_to_field(salt);

    (rfc_fr, salt_fr)
}

/// Mismo binding que `open/proto/src/main.nr`:
/// `assert(Poseidon(rfc, salt) == rfc_commitment)`.
///
/// El mensaje del assert es lo que permite anclar los negativos con `should_fail_with`: sin él,
/// un test negativo se pone verde en cuanto falla *cualquier* restricción, no necesariamente esta.
fn assert_commitment_binding(rfc: Field, salt: Field, rfc_commitment: Field) {
    let computed_commitment = hash_2([rfc, salt]);
    assert(computed_commitment == rfc_commitment, "poseidon: commitment mismatch");
}

/// Mismo nullifier que `open/proto/src/main.nr`: `Poseidon(rfc, 0x4647)`.
fn nullifier_of(rfc: Field) -> Field {
    hash_2([rfc, DOMAIN_SEPARATOR])
}

// ─────────────────────────── happy path ───────────────────────────

/// El compromiso calculado en Noir coincide **exactamente** con el vector de Rust.
#[test]
fn commitment_matches_rust_vector() {
    let (rfc, salt) = vector_inputs();
    assert(hash_2([rfc, salt]) == VECTOR_COMMITMENT);
}

/// El nullifier calculado en Noir coincide **exactamente** con el vector de Rust.
/// Fija de paso el separador de dominio: cambiar `0x4647` rompe este test.
#[test]
fn nullifier_matches_rust_vector() {
    let (rfc, _salt) = vector_inputs();
    assert(nullifier_of(rfc) == VECTOR_NULLIFIER);
}

/// El separador de dominio es el literal documentado (`"FG"` en ASCII).
#[test]
fn domain_separator_is_pinned() {
    assert(DOMAIN_SEPARATOR == 0x4647);
}

/// El binding del circuito acepta la terna coherente del vector.
#[test]
fn commitment_binding_accepts_vector() {
    let (rfc, salt) = vector_inputs();
    assert_commitment_binding(rfc, salt, VECTOR_COMMITMENT);
}

// ─────────────────────────── negativos ───────────────────────────
//
// Cada negativo se ancla con `should_fail_with` al mensaje de SU restricción, de modo que el
// test sea demostrablemente rojo por el binding Poseidon y no por otra cosa.

/// Un `rfc_commitment` que no abre a `(rfc, salt)` es rechazado.
#[test(should_fail_with = "poseidon: commitment mismatch")]
fn commitment_mismatch_is_rejected() {
    let (rfc, salt) = vector_inputs();
    assert_commitment_binding(rfc, salt, VECTOR_COMMITMENT + 1);
}

/// Cambiar el salt invalida el compromiso: el binding depende del salt de verdad.
#[test(should_fail_with = "poseidon: commitment mismatch")]
fn commitment_with_wrong_salt_is_rejected() {
    let (rfc, salt) = vector_inputs();
    assert_commitment_binding(rfc, salt + 1, VECTOR_COMMITMENT);
}

/// Cambiar el RFC invalida el compromiso: el binding depende del RFC de verdad.
#[test(should_fail_with = "poseidon: commitment mismatch")]
fn commitment_with_wrong_rfc_is_rejected() {
    let (rfc, salt) = vector_inputs();
    assert_commitment_binding(rfc + 1, salt, VECTOR_COMMITMENT);
}

// ─────────────────────── separación de dominios ───────────────────────

/// Compromiso y nullifier del mismo RFC no colisionan (smoke original del paquete).
#[test]
fn poseidon_vectors_smoke_distinct_outputs() {
    let (rfc, salt) = vector_inputs();
    assert(hash_2([rfc, salt]) != nullifier_of(rfc));
}
