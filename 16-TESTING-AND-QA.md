# Testing and QA

## Test pyramid

### Pure unit/property tests

Seed derivation, RNG streams, stellar/orbital formulas, resource invariants, command validation, state machines, scoring, migrations, codecs, permission rules, offline summaries, and LOD decisions. Property tests emphasize finiteness, bounds, conservation/caps, monotonic requirements, idempotency, and deterministic output.

### Integration tests

Service lifecycle, command-to-domain-to-delta flow, Horus adapter schemas, persistence repositories, lease conflicts, receipts, MemoryStore ticket consumption, rankings, and feature flags. Use fakes for repeatable failure injection, then staging for actual cloud behavior.

### Studio/server-client tests

Use Test/Test Here for server-client separation and Server & Clients for 1–8 clients. Automate with StudioTestService where the project tooling supports it. Verify join, late join, leave, reconnect, host/visitor permissions, collaborative actions, challenge synchronization, streaming behavior, and server shutdown.

### Published staging tests

TeleportService and real cross-place/reserved-server behavior must be tested in a published private staging experience. Also validate DataStore/MemoryStore budgets, EditableMesh/Image eligibility, Marketplace receipts using supported test flows, and policy-dependent behavior.

### Visual/performance tests

Fixed seeds, cameras, paths, device tiers, graphics levels, player counts, and durations. Capture screenshots/video, MicroProfiler artifacts, memory, network, and long-frame percentiles.

## Roblox Studio MCP test execution

Studio-specific suites should be driven through the `Roblox_Studio` MCP server when it is available: bind to the intended `studio_id`, start the required play mode/server-client topology, execute test harness Luau, inspect runtime state, and collect reproducible artifacts. Before invoking a named skill, query or confirm the connected server's current skill/tool inventory. The built-ins described in [roblox_skills_guide.md](./roblox_skills_guide.md)—including `rbx-debug`, `rbx-perf-profiling`, `rbx-scene-analysis`, `rbx-luau-heap-profiling`, and `rbx-docs-search`—may support the suite, but documentation alone is not availability evidence. Record unavailable capabilities as test gaps and use the documented local or manual fallback rather than fabricating results.

Create a project-specific custom skill when it makes a recurring test matrix safer and more consistent, such as `universe-release-gate`, `universe-multiplayer-matrix`, or `universe-determinism-capture`. Store it under `.agents/skills/`, give its frontmatter a precise trigger, keep the main instructions concise, and place reusable scripts/fixtures in its `scripts/` or `references/` directories as described by the guide. The skill must emit the same exit evidence required below and must never weaken assertions, silently skip unavailable MCP steps, or turn a failed test into a pass.

## Required suites

- `determinism`: golden vectors across versions and worker ordering.
- `simulation`: stars, orbits, life, events, epochs, offline catch-up.
- `commands`: valid and invalid transitions, permissions, rates, idempotency.
- `fuzz-remotes`: malformed buffers/types, extremes, NaN/inf, huge/deep collections, replay/order.
- `persistence`: throttling, crash, partial data, migration, conflict, duplicate receipt.
- `multiplayer`: 2/4/8 clients, visits, host loss, late join, challenge.
- `teleport-staging`: tickets, stale/replay, partial party failure, retry.
- `performance`: first star, dense system, rapid zoom, galaxy, visit burst.
- `accessibility`: rebinding, UI scale, reduced motion, color independence, captions.

## AI-generated-code review

Scan for fabricated APIs, deprecated members, unsafe yields, hidden globals, circular imports, unbounded loops, per-frame allocations, insecure remotes, dynamic requires/assets, missing cleanup, silent protected-call failures, non-deterministic iteration, and comments that claim guarantees not enforced in code.

## Release matrix

At minimum: clean profile, mature profile, latest two migratable versions, slow/failing stores, fresh/returning player, host/visitor/collaborator, graphics low/high, 1080p and ultrawide, keyboard/mouse rebinding, low and high latency simulation where feasible, full server, rolling deployment between compatible builds, and rollback.

## Bug severity

- P0: data/security/commerce/privacy loss, server-wide crash—release blocked, feature disabled.
- P1: progression blocked, major exploit, sustained budget failure—release blocked.
- P2: significant feature/visual/accessibility fault with workaround—triage before milestone.
- P3: minor polish/content issue—backlog with evidence.

## Exit evidence

Agents publish a machine-readable test summary plus a concise human report containing build, environment, seed, cases, failures, flaky status, performance percentile, screenshots/profile links, known gaps, and release recommendation. “Works in Studio once” is never sufficient.
