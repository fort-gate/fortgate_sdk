# Fortgate ID System Architecture

## 1. Overview
The architecture is divided into the **Open Core** (open source) and the **Enterprise** (closed/commercial) modules.

## 2. Open Core Components
- **Noir Circuits**: The source code for the ZK circuits used to verify X.509 certificates.
- **Client SDK**: A Rust crate for certificate parsing, blinded witness generation, and SP1 proof creation.
- **On-chain Verifier**: Solidity contracts for verifying SP1 proofs and Aligned Layer verification results.

## 3. Enterprise Components
- **NOM-151 Bridge**: Interfacing with regulated entities to ensure the legal preservation of data.
- **XAI Compliance Layer**: Advanced reporting using Explainable AI to explain ZK proof verification results to regulators without leaking PII.

## 4. Flow Diagram
1. User provides X.509 certificate to **Client SDK**.
2. SDK parses the certificate and generates a **Blinded Witness**.
3. **SP1 Prover** generates a ZK proof of validity.
4. Proof is submitted to **Aligned Layer** for verification.
5. On-chain **FortgateRegistry** updates the user's status.
6. (Enterprise only) **NOM-151 Bridge** secures a conservation certificate for legal validity.
