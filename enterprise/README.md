# Fortgate ID — Enterprise

Este directorio agrupa **componentes y prototipos orientados a producto comercial** (por ejemplo scoring avanzado, informes, integración con redes institucionales) que se **acoplan al SDK de código abierto** sin sustituir su modelo de privacidad ni su auditabilidad.

## Documentación principal

| Documento | Contenido |
|-----------|-----------|
| [**docs/INTEGRATION_MODEL.md**](docs/INTEGRATION_MODEL.md) | Modelo combinado **plugins inyectables** + **servicios en red** (sidecar/SaaS), principios de separación OSS/Enterprise y guía para auditores e instituciones. |

## Contenido actual (orientativo)

- **`pope-advanced/`** — Prototipos Rust de señales de hardware, GPS y motor de riesgo (no integrados en el build público del core).
- **`xai-reports/`** — Generación de informes de auditoría operativa (prototipo).
- **`contracts/`** — Contratos Solidity / scripts Foundry para despliegues opcionales.

El despliegue comercial de estos módulos debe seguir el modelo descrito en `docs/INTEGRATION_MODEL.md`: **contratos estables con el OSS** y, donde aplique, **APIs Enterprise** con límites de datos explícitos.

## Core open source

El núcleo auditable y forkeable vive fuera de esta carpeta: **`open/client-sdk/`**, **`open/proto/`**, **`open/docs/`**.
