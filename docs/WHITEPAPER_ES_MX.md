# Whitepaper de Fortgate ID (Versión ES-MX)

## 1. Visión General
Fortgate ID es un protocolo de identidad soberana (Self-Sovereign Identity, SSI) basado en pruebas de conocimiento cero (Zero-Knowledge Proofs, ZK) diseñado para el cumplimiento legal en México y mercados globales. Permite a los usuarios demostrar atributos de identidad (e.g., mayoría de edad, nacionalidad, domicilio) sin revelar su información personal privada (PII).

## 2. El Problema: Privacidad vs. Cumplimiento
En México, las instituciones financieras (FinTechs) y plataformas de intercambio de activos digitales deben cumplir con normativas de Prevención de Lavado de Dinero (PLD) y Conocimiento del Cliente (KYC). Sin embargo, el almacenamiento masivo de documentos de identidad (INE, Pasaporte) expone a las empresas a riesgos de ciberseguridad y a los usuarios a robo de identidad.

## 3. La Solución: ZK y NOM-151
Fortgate ID combina la criptografía de Noir y SP1 con el estándar legal mexicano **NOM-151-SCFI-2016** para la digitalización y conservación de mensajes de datos.
- **Pruebas ZK**: El usuario genera una prueba local de que posee un certificado válido (firmado por el SAT o RENAPO) sin enviar el archivo original.
- **NOM-151**: Asegura que la integridad del documento verificado es legalmente vinculante ante tribunales mexicanos.

## 4. Arquitectura Open Core
- **Open Core**: Circuitos Noir, SDK de cliente en Rust para generación de pruebas con SP1, y contratos de registro público.
- **Enterprise**: Bridge para proveedores de NOM-151 (Constancias de Conservación) y reportes de XAI (Explainable AI) para auditorías de cumplimiento.

## 5. Casos de Uso
1. **Acceso a DeFi**: Verificación de residencia para cumplimiento fiscal (LISR Art. 1, 3, 6).
2. **GovTech**: Votaciones seguras y trámites gubernamentales sin exposición de datos.
3. **FinTech**: Onboarding instantáneo con cumplimiento legal NOM-151.
