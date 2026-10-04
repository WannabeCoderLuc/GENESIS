# Data Persistence

## Storage principles

Save compact intent and history: seeds, versions, player choices, important entities, sparse deltas, progression, permissions, and summaries. Never save generated geometry, all representative stars, particles, or Instances.

Data stores are server-only durable truth across places. Memory stores are temporary coordination/caches with expiry. Ordered data stores accept numeric ranking projections only and are not canonical profiles.

## Top-level records

### Player profile

```text
profileVersion, userId, createdAt, lastSeenAt
activeUniverseId, ownedUniverseIds
settings, accessibility, tutorialState
entitlements, cosmetics, discoveryAccountSummary
receiptsProcessedWindow/checkpoints
```

### Universe manifest

```text
schemaVersion, generatorVersion, universeId, ownerUserId
rootSeed, activeEpochId, revision, createdAt, updatedAt
progression, resources, unlocks, automation
epochSummaries, importantEntityIndex, sparseOverrides
discoveries, eventSchedule, permissions, challengeHistorySummary
auditCheckpoint, checksum/validation metadata
```

Large collections are sharded by stable key: `Universe/<id>/Manifest`, `/Epoch/<id>`, `/Entities/<shard>`, `/Discoveries/<page>`, `/Journal/<segment>`. Keep manifest size bounded and avoid hot single keys for frequently changing append-only details.

## Write model

- Load with protected calls and explicit corruption/unavailable states.
- Acquire a time-bounded session lease through atomic `UpdateAsync`; renew periodically.
- Mutate in server memory via domain commands and mark named dirty sections.
- Coalesce normal writes; force checkpoint for purchase grant, epoch creation, risky expedition deployment/return, and orderly server transfer.
- Use `UpdateAsync` with expected revision/lease token. Never blind `SetAsync` for live mutable profiles.
- Retry transient errors with exponential backoff plus jitter and a deadline.
- On `BindToClose`, stop new risky commands, flush a bounded queue, and report failures; do not hang forever.

## Idempotency and journals

Commands with durable value use unique IDs. Persist a bounded dedupe structure or journal checkpoint so retries cannot double-award. Commerce receipt IDs require durable idempotent processing. Cross-place transfers use a state machine (`Prepared → Departed → Arrived/Recovered`) rather than deleting from source before destination confirmation.

## Migrations

Each schema has a pure stepwise migration `Vn → Vn+1`; never skip undocumented behavior. Migrations are deterministic, idempotent where feasible, covered by sanitized fixtures, and preserve unknown forward-compatible fields only when safe. Back up/log the prior version metadata and stage on copied test data. A generator upgrade is not automatically a data schema migration.

## Offline progress

Store last authoritative simulation time and scheduled strategic events. On load:

1. clamp elapsed time to an explicit maximum;
2. apply analytical/event-jump simulation, not frame replay;
3. prevent offline irreversible disasters;
4. cap rewards and resource containers;
5. produce a deterministic digest with input/output checksum;
6. commit once after the player acknowledges/enters.

Use server time and guard against clock anomalies.

## Leaderboards

Canonical metric is derived server-side from saved universe state. Update OrderedDataStore asynchronously with numeric values and a stable user/universe key. Display metadata comes from a safe cached profile lookup. A leaderboard entry never grants rewards by itself; reward service verifies canonical challenge/result records.

## Failure modes

- Store unavailable: allow safe read-only/sandbox session or fail closed with a clear retry; never create a fresh profile over an uncertain load.
- Lease conflict: prevent simultaneous writers; offer reconnect/transfer recovery.
- Partial shard load: quarantine affected feature and recover from checkpoint/journal; do not overwrite.
- Oversized record: alert before hard limit, compact/archive bounded history, never truncate silently.
- Migration error: retain source, disable write, emit support correlation ID.

## Backup and support

Keep periodic checkpoint generations and an administrative recovery design using authorized server/Open Cloud processes when later built. Support tools require least privilege, immutable audit entries, reason codes, preview/dry-run, and no client exposure.

## Test matrix

Fresh profile, legacy versions, missing optional shard, malformed/corrupt field, concurrent servers, throttling, timeout, crash during commit, duplicate command, duplicate receipt, teleport interruption, server shutdown, oversized collections, offline cap, and rollback to previous build.

## Roblox Studio MCP and persistence rehearsals

Before using Studio automation, discover the active `Roblox_Studio` MCP session and `studio_id` and enumerate its real tools/skills; [roblox_skills_guide.md](./roblox_skills_guide.md) is guidance, not an availability guarantee. Use `rbx-docs-search` when available to confirm current DataStore, MemoryStore, OrderedDataStore, and shutdown semantics. Use exposed Studio playtest/Luau/debug tools only against an isolated test universe and namespaced test keys to exercise fixtures, lease conflicts, throttling mocks, duplicate commands, offline catch-up, and stepwise migrations. Never put production credentials or raw player records in MCP prompts, logs, fixtures, or custom-skill resources, and never let a Studio probe write production data.

Create a workspace custom skill such as `universe-save-rehearsal` when migration, rollback, and failure-injection steps become stable enough to automate. Put sanitized schema fixtures and expected revisions in `references/`, deterministic check/rehearsal scripts in `scripts/`, and require dry-run output before any fixture mutation. Store the skill under `.agents/skills/` (or the supported `.agent/skills/` path), do not use the reserved `rbx-` prefix, and call `rbx-create-skill` only if the connected MCP server reports it. Treat updates to the skill, fixtures, or migration runner as persistence changes requiring review and replay of the full failure matrix.
