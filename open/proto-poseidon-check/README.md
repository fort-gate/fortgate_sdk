# fortgate_poseidon_check

Paquete `nargo test` sobre el **binding Poseidon BN254 `hash_2`** que usa `open/proto/src/main.nr`:
compromiso `Poseidon(rfc, salt)`, nullifier `Poseidon(rfc, 0x4647)`, y los casos negativos en los que
el compromiso no abre a `(rfc, salt)`.

Los vectores del happy path son los **existentes** en Rust
(`open/client-sdk/tests/fixtures/poseidon_vectors.json`, verificados por
`open/client-sdk/tests/poseidon_vectors.rs`). Aquí no se re-deriva `Fr`: la codificación sigue
siendo la de `open/client-sdk/src/field_encoding.rs`.

## Toolchain

Verificado con **Nargo 0.31.x y 0.32.x**. Ejemplo con [noirup](https://github.com/noir-lang/noirup):

```bash
noirup --version 0.31.0
cd open/proto-poseidon-check && nargo test
```

Noir 1.x (p. ej. beta.19) usa otra `stdlib` y **no** compila este paquete sin migración.

## Bytes: Rust ↔ Noir

Los hex de `poseidon_vectors.json` usan **serialización comprimida Ark** (`fr_to_canonical_hex`),
que es **little-endian**. Noir expone `Field::to_be_bytes`, que es **big-endian**. Es el mismo
elemento de campo con los bytes en orden inverso, así que los vectores de Rust **sí se pueden
anclar aquí**: basta invertir el hex, sin recalcular nada.

| | JSON (LE, Ark) | Aquí (BE, entero canónico) |
|---|---|---|
| `expected_rfc_commitment_hex` | `b46d4f1f…97af1829` | `0x2918af97…1f4f6db4` |
| `expected_nullifier_hex` | `7fe17133…d78d9428` | `0x28948dd7…3371e17f` |

Esto convierte el paquete en una comprobación real de interoperabilidad entre los dos lenguajes,
no solo en un smoke: si Rust y Noir dejaran de coincidir, `commitment_matches_rust_vector` y
`nullifier_matches_rust_vector` se ponen rojos.

## Tests negativos

Los negativos se anclan con `should_fail_with` al **mensaje concreto** del assert que deben violar:

```noir
#[test(should_fail_with = "poseidon: commitment mismatch")]
```

Sin el mensaje, un negativo se pone verde en cuanto falla *cualquier* restricción del circuito y
deja de probar lo que dice probar. Que el anclaje funciona se comprueba cambiando el mensaje del
assert: los tres negativos pasan a `FAIL` con `Test failed with the wrong message`.

## Alcance

Este paquete cubre la mitad Poseidon del circuito. Los casos negativos de **RSA** viven en
`open/proto`, que hoy no compila (dependencia rota; ver el issue #4). Cuando `open/proto` vuelva a
compilar, el mismo patrón — mensaje distinto por assert + `should_fail_with` — es directamente
aplicable a `assert(is_valid == true)`.
