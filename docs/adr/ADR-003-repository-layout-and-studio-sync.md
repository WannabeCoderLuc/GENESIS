# ADR-003: Repository layout, require style and Studio sync

Status: Accepted, 2026-10-04

## Context

`README.md` fixes the top-level layout; `03-ARCHITECTURE.md` fixes layer boundaries (Domain pure, Contracts versioned,
Server/Client application and infrastructure). The Studio place `Genesis` is the only runtime available.

## Decision

- **Layout** (Rojo `default.project.json`): `src/ReplicatedFirst`, `src/ReplicatedStorage/Shared/{Core,Domain,Contracts,Lifecycle,Runtime}`,
  `src/ServerScriptService/Server/{Application,Infrastructure}`, `src/StarterPlayer/StarterPlayerScripts/Client`,
  `src/ServerStorage/ServerAssets`; tests and generated vectors live under `ServerStorage.Tests` (never replicated to
  clients). `vendor/` is **not** mapped into the tree until the Horus adoption gate passes.
- **Layering enforced by tooling** (`tools/lint-policy.mjs`): Core/Domain/Contracts/Lifecycle cannot touch the engine,
  randomness or time; Core/Domain cannot depend on higher layers; replicated code cannot require server code; remotes
  may be created only by the central transport.
- **Instance-relative requires** (`require(script.Parent.X)`), not string/alias requires. They work identically under
  Rojo, Studio sync and the built-in test harness, and keep the dependency graph visible to static checks.
- **Studio sync**: `tools/studio-sync` serves the Rojo `sourcemap`-derived manifest over loopback; `StudioSync.luau`
  materialises it inside Studio. Created instances carry `UCSync = true`; teardown removes only those.
- **Contracts**: persisted/wire shapes are suffix-versioned (`PlayerProfileV1`, ...), validated by a bounded schema
  validator that returns fresh, normalised tables.

## Alternatives considered

- Rojo `serve` + Studio plugin: needs plugin installation and a human click to connect; not drivable through MCP.
- `rojo build` to `.rbxm` then `SerializationService`: the API documents third-party `.rbxm` as unsupported and
  service containers as non-deserialisable.
- String requires (`@game/...`) as used by Horus: couples modules to Studio's require-by-string feature and path aliases.

## Consequences

- A layout change touches `default.project.json` and `tests/Support/Paths.luau` only.
- Lint rules must be updated when a new layer is introduced.

## Verification

`rojo build` and `rojo sourcemap` succeed; policy lint clean; Studio sync creates the expected instance counts and
`teardown` leaves zero marked instances.
