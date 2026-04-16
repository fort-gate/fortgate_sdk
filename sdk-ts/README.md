# @fortgate/id-sdk (TypeScript / Node)

## Requisitos

- Rust toolchain (ver `rust-toolchain.toml` en la raíz del monorepo).
- `wasm-pack`: `cargo install wasm-pack`

## Build WASM

Desde la raíz del repo o desde `sdk-ts`:

```bash
npm run build:wasm
```

Esto genera `sdk-ts/pkg/` con el export `create_fortgate_witness_wasm` (definido en `open/client-sdk/src/wasm.rs`).

## Prueba

Coloca un certificado DER de prueba con RFC en OID 2.5.4.45 y RSA-2048 en `sdk-ts/tests/fixtures/mock.der`, luego:

```bash
npm test
```

Para generar un certificado de desarrollo (OpenSSL):

```bash
mkdir -p sdk-ts/tests/fixtures
openssl req -x509 -newkey rsa:2048 -nodes -keyout /tmp/fg.key \
  -out sdk-ts/tests/fixtures/mock.der -outform DER -days 365 \
  -subj "/uniqueIdentifier=TESTRFC12345678901"
```

Ajusta el `subject` según tu política de pruebas. El parser acepta el RFC en **2.5.4.45** (SAT), `uid` (0.9.2342.19200300.100.1.1) y el `uniqueIdentifier` que OpenSSL genera con `-subj "/uniqueIdentifier=..."` (0.9.2342.19200300.100.1.44). El módulo RSA debe ser 2048 bits.
