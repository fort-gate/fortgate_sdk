# Fortgate ID SDK

### Visión general

Fortgate ID es un SDK de identidad digital enfocado en **KYC con Zero-Knowledge Proofs (ZKP)**.  
Su objetivo es permitir a instituciones reguladas:

- Validar atributos de identidad usando **firmas digitales emitidas por el gobierno** (por ejemplo, e.firma en México).
- Conservar un **expediente probatorio** con valor legal (por ejemplo, usando sellado de tiempo NOM-151).
- Minimizar la exposición de datos personales mediante **atestaciones ZK** en lugar de compartir documentos completos.

El enfoque inicial es **México**, con una arquitectura lista para extenderse a otros países de **LATAM** mediante adaptadores regulatorios.

---

## ¿Para quién es este repositorio?

- **Ingenieros de ZK / criptografía**
  - Trabajan en el circuito Noir, el programa SP1 (zkVM) y la integración con la Succinct Prover Network y Aligned Layer.
- **Desarrolladores de SDK / producto**
  - Integran el core Rust en bindings (TS, móviles), exponen APIs hacia aplicaciones bancarias/fintech y mantienen la demo app.
- **Equipos de cumplimiento / legal**
  - Definen el marco de **validez legal**, revisan cómo se mapea el flujo técnico a KYC y evalúan el modelo de auditoría/evidencia.

Cada perfil tiene secciones dedicadas más abajo.

---

## Componentes principales del proyecto

- `open/docs/`
  - `WHITEPAPER_EN_US.md` y `WHITEPAPER_ES_MX.md`: visión y posicionamiento de Fortgate ID (KYC, base legal en México, expansión LATAM).
- `open/client-sdk/`
  - `sp1-prover/`: integración con **SP1** (guest/host, generación de pruebas, scripts de orquestación).
  - `tests/`: pruebas relacionadas con criptografía/firmas (por ejemplo, fixtures de OpenSSL).
- `sdk-ts/`
  - SDK TypeScript para integrarse desde aplicaciones y servicios que consumen Fortgate ID.
- `enterprise/`
  - Prototipos y piezas comerciales acopladas al core open source; modelo de integración en [`enterprise/docs/INTEGRATION_MODEL.md`](enterprise/docs/INTEGRATION_MODEL.md).

> Tip: para entender la película completa, leer primero el whitepaper (`WHITEPAPER_ES_MX` o `WHITEPAPER_EN_US`), luego el plan de implementación y finalmente el manual de integración SP1.

---

## Resumen de arquitectura (alto nivel)

1. **Captura y validación de credenciales**
   - El usuario firma con su **firma digital gubernamental** (ej. e.firma en MX).
   - El core Rust parsea la estructura ASN.1, calcula hashes y prepara los datos para el circuito ZK.

2. **Generación de prueba ZK**
   - El circuito Noir y el programa SP1 verifican la firma RSA, el mensaje asociado y un compromiso (`commit`) de atributos como el RFC.
   - El resultado es una **prueba ZK** y, opcionalmente, una **verification key** exportable.

3. **Sellado y registro**
   - Los artefactos de evidencia (hashes, metadatos, prueba ZK) pueden sellarse con **NOM-151** y, en iteraciones futuras, registrarse en Monad / Aligned.

4. **Verificación por terceros**
   - Bancos, reguladores y auditores pueden validar la prueba usando **claves de verificación públicas**, sin depender de la infraestructura operativa de Fortgate.

---

## Guía rápida por rol

### Para ingenieros ZK / criptografía

- Leer:
  - `open/docs/WHITEPAPER_EN_US.md` (visión y requisitos de privacidad/validez legal).
  - `open/docs/INTEGRATION_MANUAL_SUCCINCT_SP1.md` (contrato host↔guest, stdin, herramientas SP1).
- Objetivos clave:
  - Mantener un **único proyecto SP1 canónico** (guest + script host) basado en la plantilla oficial de Succinct.
  - Garantizar que el contrato de IO (`stdin.write(...)` en host ↔ `io::read()` en guest) se mantiene estable y testeado.
  - Evaluar trade-offs de rendimiento (tiempo de prueba, coste en la red de provers) vs. experiencia de onboarding.

### Para desarrolladores de SDK / producto

- Leer:
  - Whitepaper (`ES` o `EN`) para entender el scope de producto y las promesas al cliente.
  - `IMPLEMENTATION_PLAN_EN.md` para ver el roadmap Alpha (3 semanas).
- Objetivos clave:
  - Exponer APIs simples para:
    - iniciar un flujo de verificación KYC,
    - obtener el estado/progreso de la prueba,
    - recuperar identificadores de atestación y evidencias.
  - Mantener **bindings** coherentes (TS, móviles) sobre el mismo núcleo Rust.
  - Integrar la demo app (wallet/cliente) como referencia para bancos/partners.

### Para equipos de compliance / legal

- Leer:
  - `open/docs/WHITEPAPER_ES_MX.md` (o `WHITEPAPER_EN_US.md` para inglés).
  - Sección de alineación legal y modelo LATAM en esos documentos.
- Puntos de evaluación:
  - Cómo se soporta la **validez legal en México**:
    - uso de **e.firma** como ancla de identidad,
    - sellado y conservación NOM-151.
  - Qué información **no** se expone gracias a ZK, y cómo impacta en:
    - protección de datos personales,
    - capacidad de auditoría y reconstrucción probatoria.
  - Estrategia para extender el modelo a otros países de LATAM mediante adaptadores regulatorios.

---

## Cómo empezar (desarrollo)

- Requisitos generales:
  - Rust instalado (ver versiones recomendadas en `INTEGRATION_MANUAL_SUCCINCT_SP1.md`).
  - Tooling de Succinct SP1 según la documentación oficial.

Pasos típicos:

1. Clonar el repositorio y revisar `open/docs/`.
2. Configurar el entorno SP1 y ejecutar el flujo local descrito en `INTEGRATION_MANUAL_SUCCINCT_SP1.md`.
3. Ejecutar pruebas y scripts del directorio `open/client-sdk/sp1-prover/`.
4. Integrar o probar el SDK TS desde `sdk-ts/` en una app de ejemplo.

---

## Próximos pasos y decisiones abiertas

- Definir y documentar el **registro on-chain**
- Consolidar la **demo app** de referencia y flujos de KYC end-to-end.
- Profundizar en anexos regulatorios por país para la expansión LATAM.

Este `README` es una entrada rápida al proyecto; para detalles profundos, usa los documentos de `open/docs/` según tu rol. 

