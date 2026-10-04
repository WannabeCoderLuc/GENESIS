# Multiplayer and Networking

## Authority matrix

| Concern | Server | Client |
|---|---|---|
| progression/economy/unlocks | canonical | display/predict only |
| seeds and important generated state | canonical | derive allowed views |
| challenge scoring | computes/verifies | submits intents, shows feedback |
| permissions/visits | validates/issues routes | requests and presents |
| navigation camera | verifies only consequential actions | authoritative presentation |
| particles, impostors, audio | sends semantic cues | generates locally |
| saves/leaderboards/receipts | exclusive access | no access |

## Protocol

Use centrally registered, versioned contracts over the Horus adapter. Prefer semantic commands and coarse deltas:

- `RequestCondenseMatter(amount, target)` not `SetStarMass(newMass)`;
- `RequestOrbitCommit(candidateId)` not arbitrary CFrames;
- `SubscribeRegion(address, detailTier)` with server-approved interest;
- `UniverseDelta(sequence, baseRevision, changes)` for state;
- `EffectCue(kind, seed, address, serverTime)` for client spectacle.

Each client command includes command ID and monotonically increasing sequence. The server responds with accepted revision or typed rejection. Maximum payload, element count, string length, and nesting are contract-level limits.

## Interest management

The server tracks each player’s place role, focus address, scale tier, party/visit membership, and subscriptions. Replicate only:

- the focused region at required detail;
- nearby collaborative actors;
- summaries for navigation context;
- global event/score state relevant to the session.

Never broadcast the entire universe. Seed-derived visual fields stay client-side. Update cadence lowers with distance/scale and state stability.

## Visits

Privacy modes: private, friends, public, collaborative. A visit request creates a short-lived MemoryStore ticket containing random nonce, host universe ID, visitor IDs/party, capabilities, target place/server, expiry, and issuance revision. TeleportData carries only the ticket ID/nonce and cosmetic routing hints. Destination consumes/validates the ticket, reloads authoritative profile/permissions, and grants capability-scoped access.

Default visitor capabilities: navigate, scan allowed targets, photograph, participate in public anomalies, and use host-approved tour points. Mutations are prohibited unless a collaboration capability and server-side command rule allow them. Host rewards are time/action capped and ignore idle/bot-like activity.

## Multi-place and teleport reliability

- Server calls `TeleportAsync`; clients never choose arbitrary destinations.
- Retry only retryable failures with jitter and clear UI; never loop indefinitely.
- Persist critical state before departure and include a save revision in the ticket.
- Keep players together by party where possible; support partial failure/rejoin.
- Teleport APIs require published-client testing; Studio alone is insufficient.
- Reserved server codes are secrets from UI but not authorization truth.
- On arrival, reject stale/used/wrong-player tickets and return safely to Observatory.

## Challenges

Challenge server receives immutable ruleset and seed. Entrants start from normalized state. Server schedules start/end using server time, records accepted commands, computes score, and writes a signed-by-system result record. Durable rewards are idempotently granted after validation. OrderedDataStore receives numeric projection only; canonical result stays in standard DataStore.

## Cross-server services

- MemoryStore queue: matchmaking/challenge entries.
- Sorted map: active server/visit registry and ephemeral rankings.
- Hash map: ticket and short lease records where appropriate.
- MessagingService: invalidation and event notice; missed messages are expected.
- DataStore: durable universe, results, entitlements.

All cloud calls can fail. Use timeouts, retries, circuit breakers/load shedding, expiry, and idempotency.

## Network budgets

Establish budgets during Phase 0 and measure on realistic scenes. Initial design targets: ordinary gameplay command rates below 10/s/player, high-cost commands below 1–2/s, deltas event-driven or ≤10 Hz for near state and far lower strategically, bounded packet schemas, and no per-frame remote traffic. These are starting hypotheses, not promises; profile and revise through ADRs.

## Disconnect/reconnect

Server retains no assumed client state. On reconnect, load durable revision, reconcile an active lease, then send a snapshot followed by sequenced deltas. Client discards prediction from the old session. Collaborative sessions tolerate participant loss; host ownership is data ownership, not reliance on the host client.

## Roblox Studio MCP validation

For each protocol change, first discover the connected `Roblox_Studio` MCP session, capture its `studio_id`, and enumerate available tools/skills; do not assume an `rbx-*` capability from [roblox_skills_guide.md](./roblox_skills_guide.md) is installed. Use available Studio playtest/Luau tools to run at least two clients, inspect the registered remotes, replay valid and malformed command fixtures, force reordering/duplication/disconnect cases, and confirm that observers converge on the same revision. Use `rbx-debug` when available to stop at rejection and reconciliation paths, and `rbx-docs-search` when a networking or service API contract is uncertain. MCP playtests do not replace published-client teleport tests or production-like service-failure tests.

Once the command-fuzz and convergence procedure is stable and repeatedly used, create a workspace custom skill such as `universe-network-abuse-audit`. It should consume versioned protocol fixtures, state exact rate/payload/revision assertions, redact player data, and emit a machine-readable report. Store it under `.agents/skills/` (or the supported `.agent/skills/` path), avoid the reserved `rbx-` prefix, and use `rbx-create-skill` only if capability discovery confirms it. Until the custom skill itself passes a disposable-place test, agents must continue using the documented manual test matrix.
