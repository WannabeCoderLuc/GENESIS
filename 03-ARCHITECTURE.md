# Architecture

## System shape

```text
PC client
  input + camera + UI + local visual generation + reversible prediction
        │ typed intent / snapshots / deltas
        ▼
authoritative place server
  sessions → command validation → domain services → simulation scheduler
                              │              │
                              │              ├─ replicated view models
                              │              └─ telemetry/audit
                              ▼
  repository + save coordinator + versioned codecs
        │
        ├─ DataStore: durable truth
        ├─ MemoryStore: leases, queues, routing, temporary state
        ├─ OrderedDataStore: numeric leaderboard projections
        └─ MessagingService: invalidation/announcements
```

## Place topology

Start with the fewest places that prove the product, then split only at measured boundaries.

| Place | Responsibility | Typical capacity |
|---|---|---|
| Cosmic Observatory | arrival, social discovery, visit routing, showcases | 20–40 after profiling |
| Universe Instance | authoritative host universe plus invited visitors | 8–16 |
| Challenge Arena | equal-seed timed contests | 4–16 |
| Interstitial Void | optional risk expeditions | 8–24 |
| Staging/Test | migrations, telemetry, teleport, API validation | private |

A universe instance may be a public server for early development. Reserved server routing becomes valuable for privacy, collaboration, and resuming a host universe. Never make a reserved access code the sole authorization mechanism; validate the arriving player and signed/nonce-based routing record server-side.

## Domain layers

### Shared pure domain

Types, IDs, units, deterministic RNG, hashing, seed derivation, celestial formulas, progression rules, schemas, codecs, and command/result definitions. It has no DataModel writes and can be unit tested outside a live place where tooling permits.

### Server application

- `SessionService`: lifecycle, load gate, ownership lease, disconnect.
- `CommandService`: remote endpoints, validation pipeline, idempotency.
- `UniverseService`: aggregate root, commands, sparse deltas, addresses.
- `SimulationService`: fixed-budget clocks, event scheduling, offline summaries.
- `GenerationService`: jobs and deterministic chunk/sector results.
- `ProgressionService`: unlocks, automation, epochs.
- `VisitService`: permissions, tickets, host/visitor roles.
- `ChallengeService`: equal seeds, scoring, results.
- `PersistenceService`: repositories, migrations, journals, write coalescing.
- `LeaderboardService`: projection writer, never canonical reward authority.
- `CommerceService`: receipt processing and entitlements.
- `TelemetryService`: structured, sampled events.

### Client application

- `InputController`, `CameraController`, `ScaleController`.
- `UniverseViewStore`: immutable-ish replicated presentation state.
- `RenderOrchestrator`: representation selection and pools.
- `SelectionController`, `InteractionController`, `NavigationController`.
- `HUD`, map, Archivarium, challenge, visit, settings, accessibility.
- `EffectsController`, `AudioController`, photo mode.

## Aggregate and address model

The universe is a hierarchy, not an Instance tree:

```text
UniverseAddress = epoch/cluster/galaxy/sector/system/body/subobject
```

Every segment uses a stable generated ID. The authoritative aggregate stores high-level entities, player-authored decisions, important discoveries, active events, and sparse overrides. Any untouched child is regenerated from its parent seed and generator version. A materialized region has a lease and bounded cache; eviction discards derived state after durable deltas are committed.

## Command flow

1. Client sends `CommandEnvelope {commandId, clientSequence, kind, targetAddress, payload}` through a declared Horus/project remote.
2. Transport validates packet/authentication/schema/rate.
3. Command gateway validates session, finite/bounded values, permissions, target existence, current phase, costs, cooldowns, distance if relevant, and idempotency.
4. Domain handler computes a result against the authoritative aggregate.
5. Commit atomically mutates server state and appends an audit/journal record.
6. Server sends a minimal result to the requester and interest-filtered deltas to observers.
7. Persistence coalesces dirty state; critical purchases/epoch transitions force a durable checkpoint.

The client may animate an anticipated result, but reconciles to the server response.

## Simulation timing

Use explicit clocks:

- render clock: client frame, presentation only;
- interaction clock: 10–20 Hz for responsive local systems;
- authoritative near simulation: typically 2–10 Hz, budgeted;
- strategic simulation: 0.1–1 Hz or event-driven;
- offline simulation: analytical event jumps capped by policy.

No astronomical orbit is simulated with unconstrained physics. Kepler-inspired positions are evaluated from parameters and time. Important collisions/events are scheduled results, not emergent high-cost Part physics.

## Dependency and startup rules

Composition roots explicitly construct services. Horus may load modules, but feature dependencies are declared in constructors/interfaces, not obtained through arbitrary globals. Lifecycle is `Load/Init/Start/Stop` with timeouts and readiness health. Loader priority is reserved for unavoidable bootstrap ordering; dependency graphs should determine most order.

## Repository boundaries

- `Shared/Domain`: pure and deterministic.
- `Shared/Contracts`: remote/data schemas, versioned.
- `Server/Application`: orchestration.
- `Server/Infrastructure`: stores, Horus adapters, telemetry.
- `Client/Presentation`: view and effects.
- `Client/Application`: input and navigation.
- `Generated`: manifests and source artifacts, not hand-edited runtime output.

Circular dependencies are forbidden. Domain does not import infrastructure or presentation.

## Studio automation boundary

The `Roblox_Studio` MCP server is a development and verification adapter outside the shipped architecture. Agents may use a verified Studio session to inspect the composed DataModel, exercise client/server startup, place-role boundaries, remotes, streaming, Actors, and telemetry, and gather debugger/profile evidence. MCP actions must not become an undeclared runtime service or bypass source-controlled schemas and composition roots. Before any action, verify the exposed tools, intended `studio_id`, open place/build, and built-in skill availability; if Studio automation is unavailable, record the gate as pending and use the documented local/manual path.

Recurring architecture conformance checks may become project-scoped skills, such as `universe-boundary-audit` or `universe-place-smoke-test`. A skill should orchestrate existing tests and evidence collection, not hide dependencies or mutate architecture opportunistically. Define its trigger, inputs, allowed Studio mutations, rollback, and outputs under `.agents/skills/` according to `roblox_skills_guide.md`, without using the reserved `rbx-` prefix.

## Observability

Every server has build ID, schema version, generator version, place role, and feature-flag snapshot. Structured events carry correlation ID and non-sensitive universe/player surrogate IDs. Track command rejects by reason, save latency/failures, generation queue depth, active materialized nodes, remote bytes/rate, teleport outcomes, frame time, memory, and long task labels.
