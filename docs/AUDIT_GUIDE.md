# Fortgate ID Audit Guide

## 1. ZK Circuit Auditing
The Noir circuits in `open/proto/` must be audited for:
- **Soundness**: No invalid certificate should generate a valid proof.
- **Zero-Knowledge**: No PII (CURP, RFC, etc.) should be leaked through public inputs.
- **Completeness**: All valid certificates should be provable.

## 2. SP1 Proof Verification
Ensure that the `sp1-prover` program corresponds exactly to the audited Noir circuit. The hash of the ELF file should be verified against the official release.

## 3. Aligned Layer Verification
Confirm that the verification task on Aligned Layer correctly references the expected verification key for the Fortgate ID circuit.

## 4. NOM-151 Compliance
For Enterprise users, verify the integrity of the conservation certificates issued by the authorized provider. These should match the hash of the original (but blinded) data submitted by the SDK.
