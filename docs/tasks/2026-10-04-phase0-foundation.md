# Task: Phase 0 foundation vertical slice

Date: 2026-10-04. Status: **in progress** (checkpoint 1). Owner instruction: build the first safe, testable Phase 0
deliverables autonomously. Spec sources: `06-IMPLEMENTATION-PLAN.md` (first 20 tasks, 1-9 here), `07-PHASES-AND-MILESTONES.md`.

## Narrow deliverable

A working repository/source skeleton with strict-typed Luau domain code, deterministic seed and named-RNG tests, versioned
contracts, an in-memory persistence repository with a migration harness, a service lifecycle skeleton, a Horus adapter
boundary and compatibility plan (upstream untouched), and a minimal Studio server/client startup playtest.

## Acceptance criteria

1. Identical input gives identical output; iteration order, stream access order and unrelated streams cannot change results.
2. All generated numbers are finite and within declared bounds.
3. Luau output equals an independent reference for every golden vector.
4. Tests, lint and policy checks run from documented, pinned commands; unavailable gates are reported as pending.
5. No client-trust path, no `math.random` in canonical code, no live DataStore/commerce/Robux/publish actions.

## Status

| # | Item | State |
|---|---|---|
| 1 | Project audit | done: `artifacts/audits/phase0-state-audit-20261004.md` |
| 2 | Source-controlled layout | done (`default.project.json`, Rojo build + sourcemap succeed) |
| 3 | test / tools / generated / adr / audit structure | done |
| 4 | Toolchain selected from what is installed, pinned, documented | done: `docs/TOOLCHAIN.md`, ADR-001 |
| 5 | Strict shared types: IDs, units, versions, Result/Error | done: `Ids`, `Units`, `Versions`, `Result`, `ErrorCodes` (UniverseAddress with the contracts, below) |
| 6 | Deterministic seed derivation | done: `Seed` (UC-SEED-V1) |
| 7 | Named RNG streams (cosmetic cannot alter canonical) | done: `Rng`, `RngStreams` |
| 8 | Golden vectors + determinism tests | done: 58 tests, see below |
| 9 | Versioned contracts (PlayerProfileV1, UniverseManifestV1, CommandEnvelopeV1, UniverseAddressV1) | done |
| 10 | In-memory persistence repository + migration harness | done |
| 11 | Service composition / lifecycle skeleton | done |
| 12 | Horus adapter boundary + compatibility test plan | done |
| 13 | Studio bootstrap + playtest | done |
| 14 | ADRs and docs | ongoing (ADR-001..003 written) |
| 15 | All gates | partial, see table |

## Verified (checkpoint 1)

| Check | Result | Command / evidence |
|---|---|---|
| Luau specs in Studio VM | **75 / 75 passed** | suites: Uint64 8, Hash64 6, Seed 12, Rng 12, RngStreams 9, CanonicalEncode 11, Contracts 6, InMemoryRepository 3, MigrationHarness 3, Lifecycle 5 |
| Reference anchored to published vectors | 6 / 6 passed | `npm run test:tools` (FNV-1a-64 "", "a", "foobar"; SplitMix64 from 0) |
| Golden vectors up to date | pass | `npm run check:vectors` (5 sets) |
| Selene 0.32.0 | 0 errors, 0 warnings, 0 parse errors | `tools/bin/selene.exe src tests` |
| Policy lint | clean (23 luau files, 57 error codes) | `npm run lint:policy` |
| Rojo 7.7.1 | project resolves, 46 instances (28 scripts) | `tools/bin/rojo.exe sourcemap default.project.json` |
| Format (StyLua) | **pending** | tool not installed (needs approval) |
| Type check (`--!strict`) | **pending** | no analyzer installed; Studio has no diagnostics API |

Defects found by the tests during this slice, both fixed: `Rng.nextInt` accepted a 2^53 range (rounding in `hi - lo + 1`);
`Versions` contained a chained cast that does not parse.

## Measurements

Full spec run 0.136 s in Studio's VM (includes 6 x 10,000-draw RNG digests, a 2,000-sibling seed corpus and 3,000-case decoder
fuzz). No performance claims are made; budgets arrive with the first hot path.

## Studio MCP evidence

Server discovered; studio `8978c8bc-b110-47f2-b72f-0f2f2c13605e`, place `Genesis` (placeId 121145903454904), Studio
0.741.19.7411056, Edit mode, no pre-existing scripts. Capability record: `generated/manifests/studio-mcp-capabilities.json`.
Sync installs 39 instances (28 scripts), all tagged `UCSync`, and tests run from `ServerStorage.Tests`. Play-mode server/client
smoke test: not yet run.

## Horus (read-only inspection, not modified)

`C:\Users\Luc\Desktop\DEV\Horus-main` is not a git repository (no commit hash); license CC0 1.0. It will be pinned by a
content-hash manifest. Static review findings so far (all unverified dynamically, to be re-tested in the compatibility spike):

1. One session key and one base nonce are derived per session and used for **both directions** with independent counters
   starting at 0, so the same (key, nonce) pair protects a client->server and a server->client message with equal sequence ids.
2. No ciphertext size cap before decrypt/deserialize; the 60/s and 20/s per-remote limits therefore still allow large payloads.
3. Every rejection path calls `warn`, which is log amplification under spam (11-SECURITY.md: sample repeated rejects).
4. `RemoteFunctions` handlers run inline without a concurrency cap.
5. The client-set `ClientLoaded` attribute is not a trust signal.
6. `Remotes` folder creation is inconsistent (`ReplicatedStorage.Remotes` vs `Packages.Horus.Remotes`); the adapter must ensure it exists.

## Security / data notes

No DataStore, MemoryStore, Teleport, commerce or publishing code exists yet. Root-seed entropy will be confined to one
server infrastructure module. Studio edits are confined to attribute-marked instances and are reversible; nothing is saved
to the place.

## Known risks

R19 (AI invents APIs): partially mitigated by Studio execution of every module; type verification still pending. R26 (Studio
MCP unavailable or wrong session): mitigated by recording `studio_id`/place and failing closed. R05/R06 (Horus): see findings.

## Next task

Contracts (`UniverseAddressV1`, `PlayerProfileV1`, `UniverseManifestV1`, `CommandEnvelopeV1`) with the bounded schema
validator and fuzz corpus; then persistence + migration harness, lifecycle host, Horus adapter and vendor pin, Studio
bootstrap playtest, and the custom skills.
