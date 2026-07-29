//! Fortgate ID — verificación RSA-2048 (PKCS#1 v1.5 + SHA-256) y binding Poseidon BN254.
//!
//! Codificación de `Field` (debe coincidir con `open/client-sdk/src/field_encoding.rs`):
//! - **RFC**: `SHA256(UTF8(RFC_string))` interpretado como entero big-endian módulo el orden del campo.
//! - **Salt**: 32 bytes aleatorios, misma regla.
//! - **Nullifier (dominio)**: escalar `0x4647` ("FG").
//!
//! Los valores `rfc` y `salt` aquí son los **escalares** `Fr` usados en Poseidon, no la cadena RFC en claro.
//!
//! Codificación RSA (impuesta por `noir_rsa` v0.1 sobre `noir-bignum`):
//! - **`modulus`**: el módulo RSA-2048 en 18 limbs de 120 bits, little-endian por limb.
//! - **`redc_param`**: parámetro de reducción de Barrett del mismo módulo, misma representación.
//!   Se deriva del módulo fuera del circuito (crate `noir-bignum-paramgen`).
//! - **`signature`**: 256 bytes big-endian.
//! - El exponente público **no es un input**: `noir_rsa` asume `e = 65537`.

use dep::std;
use dep::noir_rsa::bignum::BigNum;
use dep::noir_rsa::bignum::runtime_bignum::BigNumInstance;
use dep::noir_rsa::bignum::fields::Params2048;
use dep::noir_rsa::RSA;

type BN2048 = BigNum<18, Params2048>;
type BNInstance = BigNumInstance<18, Params2048>;
type RSA2048 = RSA<BN2048, BNInstance, 256>;

fn main(
    modulus: [Field; 18],
    redc_param: [Field; 18],
    hashed_message: [u8; 32],
    rfc_commitment: pub Field,

    signature: [u8; 256],
    rfc: Field,
    salt: Field
) -> pub Field {
    let instance: BNInstance = BigNumInstance::new(modulus, redc_param);
    let signature_bn: BN2048 = BigNum::from_byte_be(signature);
    let rsa: RSA2048 = RSA {};

    let is_valid = rsa.verify_sha256_pkcs1v15(instance, hashed_message, signature_bn);
    assert(is_valid == true);

    let computed_commitment = std::hash::poseidon::bn254::hash_2([rfc, salt]);
    assert(computed_commitment == rfc_commitment);

    let domain_separator = 0x4647;
    let nullifier = std::hash::poseidon::bn254::hash_2([rfc, domain_separator]);

    nullifier
}
