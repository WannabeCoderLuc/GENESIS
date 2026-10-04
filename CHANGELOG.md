# Changelog

Human-readable record of schema, generator, contract and tooling changes (`04-AI-DEVELOPMENT-WORKFLOW.md`).
Golden-vector changes always get an entry explaining why.

## Unreleased — Phase 0 foundation

### 2026-10-04 — checkpoint 1

Added
- Repository skeleton and Rojo project (`default.project.json`), git repository wired to `origin`
  (`https://github.com/WannabeCoderLuc/GENESIS.git`); commits and pushes authorised by the owner.
- Toolchain: **Rojo 7.7.1** and **Selene 0.32.0** installed and hash-pinned (`tools/bootstrap`); Node-based repo tools
  (policy lint, golden-vector generator, Studio sync); `docs/TOOLCHAIN.md`.
- Shared deterministic core: `Result`, `ErrorCodes`, `Bytes`, `Uint64`, `Hash64`, `SplitMix64`, `Versions`, `Ids`, `Units`,
  `Seed` (UC-SEED-V1), `Rng` and `RngStreams` (UC-RNG-V1), `CanonicalEncode` (UC-CANON-V1).
- Independent BigInt reference model and generated golden vectors (vector set v1, 5 modules + manifest).
- Test runner, assertion helpers and specs for the core; Studio sync tooling.
- Docs: `docs/specs/DETERMINISM.md`, ADR-001..003, `AGENTS.md` repository-operations section, README status.

Fixed
- `Rng.nextInt` range guard rounded at 2^53 (`hi - lo + 1`); now guards on the exact `hi - lo`. Found by the misuse test.
- `Versions` used a chained cast (`1 :: any :: T`) that does not parse in Luau; found by Studio load failure and now
  prevented by the `chained-cast` policy rule.

Verification state: see `docs/tasks/2026-10-04-phase0-foundation.md`.
