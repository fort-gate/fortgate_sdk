# Fortgate ID Implementation Plan (EN)

## Phase 1: Privacy Core (Month 1)
- Noir circuit implementation for X.509 certificate parsing.
- Blinded witness generation in Rust.
- Unit tests for cryptographic signature validity without PII exposure.

## Phase 2: SP1 and Aligned Integration (Month 2)
- Circuit compilation to SP1 for local or server-side proof generation.
- Scripts for submitting proofs to Aligned Layer for low-cost verification.
- Deployment of `FortgateRegistry.sol` contract on Monad Testnet/Mainnet.

## Phase 3: Enterprise Ecosystem (Month 3)
- Development of the bridge for NOM-151 providers (e.g., Seguridata, Advantage).
- Implementation of XAI reports for regulatory compliance (CNBV/SAT).
- Integration tests with Mexican financial institutions.

## Phase 4: Launch and Scaling (Month 4+)
- Developer bounty program for the SDK-TS.
- Implementation of GovTech use cases with municipalities.
- Expansion to other Latin American markets with similar standards.
