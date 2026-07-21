# Contributing to Fortgate SDK

Thanks for helping improve the open-source Fortgate identity SDK. This guide covers how to set up the repo, run the same checks as CI, and open a useful pull request.

## Before you start

1. Read the [README](README.md) for scope and the public Rust API.
2. Skim architecture invariants in [AGENTS.md](AGENTS.md) (field encoding, SP1 stdin order, nullifier domain `0x4647`).
3. Prefer small, focused PRs. Changes that touch crypto encoding or circuit IO need tests or updated vectors.

**License:** by contributing you agree your work is licensed under [Apache-2.0](LICENSE).

## Prerequisites

| Tool | Required for | Notes |
|------|----------------|-------|
| **Git** | Everything | Clone from [fort-gate/fortgate_sdk](https://github.com/fort-gate/fortgate_sdk) |
| **Rust 1.88.0** | Core, SP1 check, WASM | Pinned in [`rust-toolchain.toml`](rust-toolchain.toml); rustup installs it automatically |
| **rustfmt + clippy** | Core CI | Bundled via the toolchain file |
| **Node.js 20+** | `sdk-ts` | Only if you touch TypeScript / WASM smoke |
| **wasm-pack** | `sdk-ts` | `cargo install wasm-pack --locked` |
| **Noir / nargo 0.31.x** | Poseidon / Noir work | Via [noirup](https://github.com/noir-lang/noirup); see below |
| **OpenSSL** | Optional fixture certs | For generating `mock.der` |
| **Succinct / cargo-prove** | Optional real SP1 prove | **Not** required for first contributions; CI uses `SP1_SKIP_PROGRAM_BUILD=true` |

Minimum path for most first issues: **Rust 1.88** + clone + `cargo test` in `open/client-sdk`.

## Clone

```bash
git clone git@github.com:fort-gate/fortgate_sdk.git
cd fortgate_sdk
```

HTTPS:

```bash
git clone https://github.com/fort-gate/fortgate_sdk.git
cd fortgate_sdk
```

## Project map (where to work)

| Path | What it is |
|------|------------|
| `open/client-sdk/` | Rust crate `fortgate-id-core` — start here for parsers, Poseidon, witness |
| `open/client-sdk/sp1-prover/` | SP1 guest + host (separate Cargo workspace) |
| `open/proto/` | Noir product circuit (RSA + Poseidon) |
| `open/proto-poseidon-check/` | Noir smoke tests for Poseidon alignment |
| `sdk-ts/` | WASM build + Node smoke test |
| `open/docs/` | Whitepapers and design docs |
| `scripts/` | Helper scripts (`build_open.sh`, UniFFI, local SP1 verify) |

## Setup and tests by area

Run checks from the **repository root** unless noted. Match CI in [`.github/workflows/ci.yml`](.github/workflows/ci.yml).

### 1) Rust core (required for most PRs)

```bash
cd open/client-sdk
cargo test
cargo clippy -- -D warnings
cargo fmt --check
```

Useful single-test examples:

```bash
cargo test --test openssl_fixture
cargo test poseidon -- --nocapture
```

### 2) SP1 (compile check without Succinct toolchain)

Enough for CI and most guest/host refactors:

```bash
cd open/client-sdk/sp1-prover
cargo check -p fortgate-id-program
SP1_SKIP_PROGRAM_BUILD=true cargo check -p fortgate-id-script
```

**Real proving** needs the Succinct toolchain and a rebuilt ELF (not the committed placeholder). See [`open/client-sdk/sp1-prover/README.md`](open/client-sdk/sp1-prover/README.md). Host must be built with `--release` for `ProverClient`.

### 3) TypeScript / WASM

```bash
# once
cargo install wasm-pack --locked

cd sdk-ts
npm install
npm run build:wasm
```

Smoke test expects a DER fixture:

```bash
mkdir -p tests/fixtures
openssl req -x509 -newkey rsa:2048 -nodes -keyout /tmp/fg.key \
  -out tests/fixtures/mock.der -outform DER -days 365 \
  -subj "/uniqueIdentifier=TESTRFC12345678901"

npm test
```

Details and accepted RFC OIDs: [`sdk-ts/README.md`](sdk-ts/README.md).

### 4) Noir — Poseidon smoke (CI hard gate)

```bash
curl -L https://raw.githubusercontent.com/noir-lang/noirup/main/install | bash
export PATH="$HOME/.nargo/bin:$PATH"
noirup --version 0.31.0

cd open/proto-poseidon-check
nargo test
```

### 5) Noir — product circuit `open/proto` (best effort today)

```bash
cd open/proto
nargo check
```

CI currently treats this job as **non-blocking** (`continue-on-error`). Prefer keeping it green when you touch `main.nr`.

### 6) Optional: UniFFI bindings

```bash
cargo install uniffi_bindgen --version 0.28.3 --locked
./scripts/generate_uniffi_bindings.sh
```

Not required for merge unless you change [`open/client-sdk/src/fortgate_id.udl`](open/client-sdk/src/fortgate_id.udl).

## Suggested “first contribution” checklist

Before opening a PR that only touches docs or core tests:

- [ ] `cd open/client-sdk && cargo test`
- [ ] `cd open/client-sdk && cargo clippy -- -D warnings`

If you change WASM / `sdk-ts`:

- [ ] `npm run build:wasm && npm test` (with `mock.der`)

If you change Poseidon encoding or Noir hash usage:

- [ ] `cargo test` (poseidon vectors) **and** `nargo test` in `proto-poseidon-check`

If you change SP1 guest/host IO:

- [ ] `cargo check -p fortgate-id-program`
- [ ] `SP1_SKIP_PROGRAM_BUILD=true cargo check -p fortgate-id-script`
- [ ] Update docs if stdin order or public commits change

## Pull requests

1. Fork (or branch from `main`), keep changes focused.
2. Do not commit secrets, `.env`, large proving keys, or unrelated binaries.
3. Do not change crypto invariants (BN254 encoding, nullifier domain, SP1 stdin order, RSA-2048-only policy) without tests and an explanation in the PR.
4. Describe **why** the change is needed; link related issues.
5. Ensure CI is green on your PR.

### Crypto-sensitive changes

Anything under:

- `open/client-sdk/src/field_encoding.rs`
- `open/client-sdk/src/blinded_witness.rs`
- `open/proto/src/main.nr`
- `open/client-sdk/sp1-prover/program/`
- shared Limb / stdin types

…must call out impact on proof compatibility and include or update test vectors when possible.

## Issues and good first tasks

Look for labels such as `good-first-issue`, `area:noir`, `area:sp1`, `area:core`, `area:docs` on the GitHub issue tracker.

If something in this guide is wrong or outdated relative to CI, open a docs PR — that is a valuable contribution.

## Questions

Open a GitHub Discussion or issue with:

- OS and toolchain versions (`rustc --version`, `nargo --version` if relevant)
- Exact command you ran
- Full error output
