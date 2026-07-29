# `open/proto` — circuito Noir de Fortgate ID

Circuito de producto: verificación RSA-2048 (PKCS#1 v1.5 + SHA-256) sobre la e.firma,
más el binding Poseidon BN254 que ata el RFC a un compromiso público y emite el nullifier.

## Toolchain pinneada

| Herramienta | Versión | Dónde se fija |
|---|---|---|
| Noir / `nargo` | **0.32.0** | `noirup --version 0.32.0` en `.github/workflows/ci.yml` |
| `compiler_version` | `>=0.32.0` | `Nargo.toml` de este paquete |

**Por qué 0.32.0 y no 0.31.0:** la dependencia RSA (`noir-lang/noir_rsa` v0.1) declara
`compiler_version = ">=0.32.0"` y no compila con 0.31.0. No existe ninguna librería RSA de
Noir compatible con 0.31.x: las anteriores (`richardliang/noir-rsa` v0.1.0) exigen 0.10.1 y
las basadas en `noir-bignum` exigen 0.32.0 o superior. 0.32.0 es el salto mínimo.

El pin es el mismo para los dos jobs Noir de CI (`noir-poseidon-check` y `noir-proto-check`),
que instalan su propia toolchain: los jobs de GitHub Actions no comparten runner ni `PATH`.

## Reproducir CI en local

```bash
curl -L https://raw.githubusercontent.com/noir-lang/noirup/main/install | bash
export PATH="$HOME/.nargo/bin:$PATH"
noirup --version 0.32.0

cd open/proto && nargo check
```

`nargo check` es un job **obligatorio**: si este circuito deja de compilar, CI falla.

## Interfaz del circuito

```noir
fn main(
    modulus: [Field; 18],       // módulo RSA-2048 en limbs de 120 bits
    redc_param: [Field; 18],    // parámetro de reducción de Barrett del módulo
    hashed_message: [u8; 32],   // SHA-256 del mensaje firmado
    rfc_commitment: pub Field,  // Poseidon(rfc, salt)
    signature: [u8; 256],       // firma RSA, big-endian
    rfc: Field,
    salt: Field
) -> pub Field                  // nullifier = Poseidon(rfc, 0x4647)
```

Notas de codificación:

- `modulus` y `redc_param` usan la representación de `noir-bignum` (18 limbs de 120 bits).
  El parámetro de Barrett se deriva del módulo **fuera del circuito**; el crate Rust
  `noir-bignum-paramgen` genera ambos en el formato esperado.
- `noir_rsa` v0.1 asume exponente público `e = 65537`, por lo que el exponente **no es un
  input** del circuito.
- La codificación de `rfc` y `salt` a `Field` debe seguir coincidiendo con
  `open/client-sdk/src/field_encoding.rs`. No introducir una segunda ruta de reducción `Fr`.
