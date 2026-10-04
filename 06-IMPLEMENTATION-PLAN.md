# Implementation Plan

## Build strategy

Develop vertical slices in increasing scale. Every slice must contain a player action, authoritative result, save/load, visual response, telemetry, automated tests, and a performance measurement. Do not build galaxy breadth atop an unproven star loop.

## Workstreams

### Foundation

- repository/tool pins, CI/local gates, environment config;
- verified `Roblox_Studio` MCP connection procedure, `studio_id`/place checks, and documented non-MCP fallbacks;
- project-skill policy and `.agents/skills/` scaffold following `roblox_skills_guide.md`;
- strict shared types, units, identifiers, Result/Error types;
- deterministic seed/RNG library and golden fixtures;
- command envelope and central schemas;
- service composition and Horus compatibility spike;
- feature flags, structured logging, basic test harness.

### First Star vertical slice

- first-run black-space opening and guided condensation;
- server-authoritative stellar state and ignition command;
- client star renderer, camera, input, scale indicator, audio layers;
- autosave/profile load, reconnect, and starter Archivarium entries;
- one anomaly and one repair event;
- Observatory prototype with two-player visit permission.

### Planetary system

- deterministic accretion candidates and six body archetypes;
- orbit visualization, placement preview, resonance and collision checks;
- material/influence economy; bounded offline progress;
- system LOD and object pooling; first equal-seed challenge.

### Living worlds and automation

- atmosphere/habitability model and simple biosphere progression;
- scanning/discovery and Archivarium expansion;
- templates/governors that automate mastered star/planet actions;
- notification digest and return-to-session objectives.

### Interstellar and civilization layer

- sector addressing and streaming/materialization;
- statistical civilizations, specialization, projects, trade graph;
- multi-system resource routing and agent policies;
- cooperative event contract and expanded visit tools.

### Galaxy layer

- galaxy morphology parameters and deterministic density field;
- representative-star sampling, impostors, galactic map UI;
- sculpting decisions, central black hole, satellites, merger timeline;
- rankings by category and beauty showcase moderation safeguards.

### Cluster, cosmic web, epochs

- galaxy-as-unit simulation, cluster policies, filaments/voids;
- archive/revisit and epoch-law modifiers;
- scalable summaries, long-horizon events, cross-epoch Archivarium;
- ensure each new epoch changes mechanics, not only multipliers.

### Optional risk/live systems

- Interstitial Void place, explicit deployment and bounded loss;
- seasonal equalized challenges, event rotation, operations dashboards;
- cosmetic catalog and receipts only after core retention is healthy.

## Cross-cutting backlog order

1. Data correctness/security blockers.
2. Determinism and save compatibility.
3. Frame time/memory/network budgets.
4. Onboarding and first-session completion.
5. Content diversity.
6. Cosmetics and live cadence.

## Detailed first 20 tasks

1. Bootstrap repository layout, documented tool commands, Studio MCP discovery, and custom-skill conventions.
2. Define units, branded IDs, `UniverseAddress`, schema/generator/build versions.
3. Implement hash-based `deriveSeed(parentSeed, namespace, stableId)`.
4. Implement named RNG streams and golden vectors.
5. Define `PlayerProfileV1`, `UniverseManifestV1`, codecs, and migration harness.
6. Build in-memory repository/test doubles.
7. Implement service composition and lifecycle health.
8. Vendor/pin Horus without altering upstream.
9. Complete Horus compatibility and abuse spike.
10. Define First Star commands, results, and validators.
11. Implement pure stellar model and property tests.
12. Implement authoritative First Star aggregate.
13. Implement save coordinator with session lease and retry queue.
14. Build input/camera/focus controllers.
15. Build procedural star visual with tier fallbacks.
16. Build minimal HUD/tutorial and accessibility settings.
17. Add ignition sequence, audio, and telemetry.
18. Add join/leave/reconnect and two-client tests.
19. Profile three graphics tiers and enforce budgets.
20. Stage a complete 15-minute first-session playthrough and repair defects.

## Per-feature acceptance checklist

- traceable requirement and owner;
- deterministic/server-authoritative domain behavior;
- typed contract and failure result;
- save/migration impact assessed;
- exploit cases and command limits specified;
- unit/integration/multi-client tests;
- render/network/CPU/memory cost measured;
- telemetry and feature flag;
- UI states for loading, empty, success, rejection, retry, offline;
- Studio MCP evidence where the feature depends on live engine behavior, including verified target session/tool/skill names or an explicit unverified fallback note;
- reusable project skill added or updated when the workflow meets the repeatability/risk threshold in `roblox_skills_guide.md`;
- documentation and generated-asset manifest updated.

## MCP and skill checkpoints

At the start of each vertical slice, verify rather than assume that the `Roblox_Studio` MCP server is connected, that the intended `studio_id` and place/build are selected, and that any requested `rbx-*` capability exists. Use the server for live DataModel inspection, bounded Studio edits, playtests, debugging, multi-client checks, visual review, and profiling. Preserve repository-based tests and a documented fallback so an unavailable connection cannot produce a false pass.

At each slice retrospective, identify repeated Studio or audit procedures with stable inputs, steps, and outputs. Create a project-scoped custom skill only for those procedures; follow `roblox_skills_guide.md`, use `.agents/skills/<skill-name>/`, avoid the reserved `rbx-` prefix, and dry-run it in a non-production place. Likely candidates are first-session validation, deterministic generator regression, three-tier rendering profiles, Horus audits, and release preflight.

## Explicit exclusions until validated

No physical billions-of-stars model, unrestricted user mesh uploads, open player economy, destructive home-universe PvP, blockchain/external entitlement, dynamic execution from remote-supplied asset IDs, unbounded generative AI calls at runtime, or monetized power multipliers.
