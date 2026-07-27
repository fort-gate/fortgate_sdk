# Noir Circuit Documentation

This directory contains the Noir zero-knowledge (ZK) circuit implementation utilized for cryptographic verification within the `fortgate_sdk`.

---

## Overview

The Noir circuit handles zero-knowledge verification procedures, ensuring cryptographic checks and assertions are validated off-chain before state interactions.

---

## Circuit Architecture & Logic

### Core Components
* **Field Encoding:** Handles field conversions and cryptographic encoding rules defined in `field_encoding.rs`.
* **Poseidon Hash Checks:** Integrates Poseidon hash routines via `proto-poseidon-check` for zero-knowledge compliance.

### Specification Summary
* **Public Inputs:** State roots, public verification parameters, and commitment values.
* **Private Inputs (Witnesses):** Secret state proofs, pre-image values, and execution paths.
* **Assertions:** Mathematical constraints validating input integrity and cryptographic correctness.

---

## Development & Usage

Make sure you have [Nargo](https://noir-lang.org/docs/getting_started/installation/) installed.

### Verification Commands

Check circuit types and constraint compilation:
```bash
nargo check