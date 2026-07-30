# ADR-0001: Public assert alignment between the Noir circuit and the SP1 guest

**Status:** Proposed
**Scope:** Analysis and recommendation only. This ADR does not change any circuit, guest or
encoding. Midnight is explicitly out of scope.
**Verified against:** commit `be7e879`, read on a local checkout.

## Context

Fortgate ID proves one product claim — *"this e.firma belongs to the RFC behind this
commitment"* — through two independent backends. The Noir circuit (`open/proto`) verifies RSA,
recomputes the Poseidon commitment and emits a nullifier. The SP1 guest verifies RSA and
commits `rfc_commitment`. Because the two were written separately, the same product claim is
backed by different sets of constraints, and the difference is not written down anywhere.

This ADR writes it down: what each backend actually proves, where each gap is merely
documentation debt and where it is soundness-relevant, and what the minimum alignment would be.

## 1. What each backend proves today

| # | Claim | Noir circuit | SP1 guest | Off-circuit (Rust host) | Public input / output |
|---|---|---|---|---|---|
| C1 | An RSA-2048 PKCS#1 v1.5 + SHA-256 signature is valid over `hashed_message` | ✅ `main.nr:23-24` | ✅ `program/src/main.rs:27-29` | — | neither backend exposes the modulus publicly |
| C2 | `rfc_commitment == Poseidon(rfc, salt)` | ✅ `main.nr:26-27` | ❌ never recomputed | ✅ `blinded_witness.rs:44` | Noir: public input `rfc_commitment`. SP1: committed at `program/src/main.rs:31` **without being proven** |
| C3 | `nullifier == Poseidon(rfc, 0x4647)` | ✅ `main.nr:29-30`, returned public at `main.nr:32` | ❌ not computed at all | ✅ `blinded_witness.rs:45`, surfaced at `lib.rs:52` | Noir: public output. SP1: none |
| C4 | The signed message corresponds to the RFC inside the commitment | ❌ | ❌ | ❌ | — |
| C5 | The RSA modulus belongs to the SAT certification authority | ❌ | ❌ | ❌ — no chain, issuer or validity check exists in `cert_parser.rs` | modulus enters as an unauthenticated input (`program/src/main.rs:12`) |

The SP1 host writes stdin in this order (`script/src/main.rs:28-32`): modulus, exponent,
signature, `tbs_sha256`, `rfc_commitment`. **`salt` is never sent to the guest**, which is why C2
cannot be proven there even in principle as currently wired.

## 2. Gaps

Each gap is marked **doc-only** (the backends differ but no security property is lost) or
**soundness-relevant** (a verifier could accept a proof that does not support the product claim).

### G1 — SP1 publishes `rfc_commitment` without proving its opening · **soundness-relevant**

`program/src/main.rs:16` reads `rfc_commitment` as a private `[u8; 32]` and line 31 commits it
verbatim. Nothing proves the blob opens to any `(rfc, salt)`. A prover can supply an arbitrary
32-byte value, pass RSA verification with a genuine signature, and obtain a valid proof binding a
real e.firma to a commitment of its choosing. On the SP1 path the RSA signature and the
commitment are **not cryptographically bound**.

### G2 — The nullifier is unproven on the SP1 path · **soundness-relevant**

Noir computes it on-circuit and returns it as a public output (`main.nr:30-32`). The guest never
computes it. The Rust SDK computes it off-circuit (`blinded_witness.rs:45`) and hands it to the
caller as a plain string (`lib.rs:52`). Whatever uniqueness or anti-replay property the nullifier
is meant to give exists only on the Noir path; on the SP1 path it is an unverified host claim.

### G3 — Neither backend binds `hashed_message` to `rfc_commitment` · **soundness-relevant**

Noir asserts RSA over `hashed_message` (`main.nr:23-24`) and Poseidon over `(rfc, salt)`
(`main.nr:26-27`), but no constraint connects the two. The circuit proves *"a valid signature
exists"* **and** *"a commitment opens to some RFC"* — never that they concern the same identity.
This is the strongest backend (Noir) still leaving C4 unproven.

### G4 — No trust anchor in either backend · **soundness-relevant**

The modulus arrives as an ordinary input on both sides. `cert_parser.rs` performs no issuer,
chain or validity check — the parser extracts `modulus_limbs`, `exponent`, `signature_limbs` and
`tbs_sha256` (`cert_parser.rs:42-48`) and nothing else. Both backends therefore prove *"some RSA
key signed this hash"*, not *"the SAT signed it"*. Any self-signed certificate satisfies them.

### G5 — Public field-element encodings are not byte-comparable across backends · **soundness-relevant for verifiers**

`field_encoding.rs:36-42` serialises `Fr` with `ark_serialize::CanonicalSerialize`
(`serialize_compressed`), which is **little-endian**; that is the 32-byte value SP1 commits.
Noir's `Field` serialises **big-endian**. The same field element therefore has two different byte
representations across the boundary. A verifier comparing an SP1 public output against a Noir
public input byte-for-byte will see a mismatch for identical values — and, worse, could be made
to accept a mismatch as a match if either side is byte-reversed to "fix" it. This is a formatting
difference, not a value difference, and must not be resolved by inventing a second reduction path
(see §4).

### G6 — The `0x4647` domain separator is duplicated with nothing enforcing it · **doc-only**

It appears as a literal in `main.nr:29` and as `Fr::from(0x4647u64)` in `field_encoding.rs:31-33`.
No test compares them. Changing one silently desynchronises the nullifier across backends.

### G7 — The Noir column above is currently aspirational · **doc-only**

`open/proto` does not compile at `be7e879` (`nargo check` fails while parsing `Nargo.toml`), so
none of the Noir asserts have ever been exercised. Tracked by issue #4 / PR #11, which also
changes the circuit's input shape: `modulus` becomes `[Field; 18]`, `exponent` disappears
(`noir_rsa` fixes `e = 65537`) and a Barrett `redc_param` is added. If that PR lands, G5 widens —
the two backends would no longer even agree on how the modulus is represented — and `redc_param`
enters as a witness that no constraint ties back to the modulus.

## 3. Minimal alignment proposal

What must stay on-circuit in each backend for the two to support the same product claim, ordered
by ratio of soundness gained to work required. None of this is implemented here.

| # | Change | Backend | Closes |
|---|---|---|---|
| P1 | Send `salt` through stdin and recompute `Poseidon(rfc, salt)` inside the guest; commit the **recomputed** value instead of echoing the input | SP1 | G1 |
| P2 | Compute the nullifier in the guest with the same `0x4647` separator and commit it as a second public value | SP1 | G2 |
| P3 | Make `hashed_message` a public input on **both** backends, so a verifier can check that the signature and the commitment belong to the same proof instance | Noir + SP1 | G3 (partially) |
| P4 | Make the modulus public (or commit to its hash) so the verifier can compare it against a known SAT CA key off-circuit | Noir + SP1 | G4 (without on-circuit X.509) |
| P5 | Fix one canonical byte encoding for every field element crossing the boundary, and document it next to `field_encoding.rs` | both | G5 |
| P6 | Add a test asserting the Noir literal and `domain_separator_fr()` agree | either | G6 |

P3 and P4 are deliberately the cheap versions. Fully closing C4 would require deriving `rfc` from
the certificate **inside** the circuit — X.509 parsing on-circuit, which is expensive and a
separate design decision. Making `hashed_message` and the modulus public inputs is the smallest
change that lets the verifier close the gap outside the circuit without weakening anything.

## 4. Encoding: do not reinvent the `Fr` path

`open/client-sdk/src/field_encoding.rs` is the single source of truth:

- RFC: `UTF-8 → SHA-256 → 32 bytes → Fr` big-endian `mod r` (`field_encoding.rs:16-25`).
- Salt: 32 random bytes under the same rule (`field_encoding.rs:27-29`).
- Domain separator: `0x4647` (`field_encoding.rs:31-33`).

Any alignment work must call these functions rather than re-deriving the reduction. A second
reduction path agrees with this one everywhere **except** on inputs that wrap the field modulus —
it would pass every ordinary test and diverge exactly where correctness matters.

Likewise, the Ark-compressed vs `to_be_bytes` difference in G5 is a **representation** difference.
It is fixed by choosing one representation at the boundary, never by re-encoding a field element
through a different reduction.

## 5. Recommendation for the next circuit/guest change

1. Land P1 first. It is the only gap where a prover can currently bind a genuine e.firma to a
   commitment of their choosing, and it is a contained change to the guest plus one extra stdin
   write in `script/src/main.rs`.
2. Land P2 with it — the guest already has `rfc` at that point, so the marginal cost is one
   Poseidon call, and it removes an unverified value from the public API surface.
3. Treat P3 and P4 as one change to the public-input surface of both backends, so the two are
   redesigned together rather than drifting again.
4. Do not "align" the encodings by touching the reduction (§4). Pick a boundary representation,
   write it down here, and keep `field_encoding.rs` authoritative.

## References

| File | Lines | What |
|---|---|---|
| `open/proto/src/main.nr` | 23-24 | RSA assert |
| `open/proto/src/main.nr` | 26-27 | Poseidon commitment assert |
| `open/proto/src/main.nr` | 29-32 | nullifier and public return |
| `open/client-sdk/sp1-prover/program/src/main.rs` | 12-16 | guest stdin reads |
| `open/client-sdk/sp1-prover/program/src/main.rs` | 27-29 | RSA verification |
| `open/client-sdk/sp1-prover/program/src/main.rs` | 31 | `commit(&rfc_commitment)` — unproven |
| `open/client-sdk/sp1-prover/program/src/main.rs` | 34-39 | little-endian `u32` limb decoding |
| `open/client-sdk/sp1-prover/script/src/main.rs` | 28-32 | stdin order, no `salt` |
| `open/client-sdk/src/field_encoding.rs` | 16-33 | canonical `Fr` encoding |
| `open/client-sdk/src/field_encoding.rs` | 36-42 | Ark compressed serialisation |
| `open/client-sdk/src/blinded_witness.rs` | 44-45 | commitment and nullifier computed off-circuit |
| `open/client-sdk/src/lib.rs` | 48-56 | `nullifier_hash` exposed to callers |
| `open/client-sdk/src/cert_parser.rs` | 42-48 | `Sp1CertInputs` — no chain or issuer check |
