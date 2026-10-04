# Security

## Trust model

The client is fully hostile. It can inspect replicated code, alter local state, fabricate and spam remote calls, manipulate its character/owned physics, and replay any public interaction. Horus encryption does not change this. Roblox services, stores, and teleport calls may fail or throttle. AI-generated code is untrusted until reviewed and tested.

## Protected assets

Persistent universes, currency/resources, discoveries, entitlements, competitive integrity, visit privacy, challenge rewards, personal settings, service availability, and the reputation/safety of social surfaces.

## Command validation pipeline

For every client-triggered action:

1. transport/session packet validity;
2. declared schema and payload-size limit;
3. primitive type and finite-number checks (`NaN`/infinities rejected);
4. string/table count, depth, and length bounds;
5. global and command-specific token bucket;
6. authenticated player/session and capability;
7. target class/address/ownership and current loaded revision;
8. legal state-machine transition and cooldown;
9. server-computed distance/line-of-sight when relevant;
10. server-owned cost/inventory/economy check;
11. command ID idempotency/replay/order;
12. bounded execution and safe typed error.

Do not accept arbitrary Instance paths, asset IDs, module IDs, DataStore keys, place IDs, destination server IDs, or code-like strings from clients.

## Rate and resource controls

Horus default remote limits are only an outer layer. Add per-command costs, per-player/global buckets, concurrent-job caps, generation queue limits, cancellation, payload limits, and progressive responses (drop → warn/telemetry → temporary command quarantine → kick only with strong evidence). Avoid expensive logging of every spam packet.

## Economy and competition

- All values calculated server-side from canonical state.
- Fixed-point/integer durable balances; checked non-negative transitions and maxima.
- Receipt processing is server-only and idempotent.
- Equal-seed challenges reject late/illegal commands and compute score on server.
- Leaderboards are projections; never trust them for rewards.
- Host/visitor farming is capped, diversity-weighted, and suspicious patterns flagged.
- Void deployment/return uses a durable transfer state machine.

## Network ownership and physics

Keep critical interaction targets anchored or server-owned. Never infer cosmic authority from client CFrames. Validate vessel action against logical navigation state. Cosmetic local physics cannot cause rewards. Server reconstructs proximity or ray conditions using authoritative/logically bounded inputs.

## Visits and teleports

Use short-lived one-time MemoryStore tickets bound to players, universe, capability, destination, expiry, and nonce. TeleportData is visible to clients and therefore untrusted. Destination loads durable permission state and consumes the ticket atomically. Deny by default on service uncertainty.

## Social/content safety

Universe/body names pass Roblox text filtering and length/character rules before replication. Photography/showcase metadata never permits arbitrary external URLs or asset IDs. Provide report/block integration where applicable. Public listings use safe thumbnails and moderation-aware text.

## Secrets and supply chain

- No credentials, Open Cloud keys, private tokens, or personal data in source, prompts, logs, replicated storage, or generated manifests.
- Pin tool/dependency versions and record licenses/provenance.
- Treat vendor updates—including Horus and cryptography—as high-risk reviewed changes.
- Never dynamically `require` an ID supplied by a player or runtime message.
- Scan generated code for obfuscated payloads, network calls, dynamic loading, and hidden asset references.

## Detection and response

Log structured rejection categories, impossible progression velocity, repeated invalid targets, replay/auth failures, abnormal command rate, and leaderboard discontinuities. Use server-side detection as evidence; never trust client anti-cheat reports alone. Prefer nullifying impact and preserving evidence over revealing exact thresholds.

Have feature kill switches for commerce, trading/visit rewards, challenges, risky expeditions, and new migrations. A severity-1 response freezes affected writes/rewards, preserves logs, disables the feature, assesses impacted records, performs idempotent repair, and communicates clearly.

## Security review checklist

- What client input reaches this path?
- Can it award, delete, transfer, publish, teleport, or affect another player?
- Are all bounds and permissions server-derived?
- Can retries, concurrency, disconnects, or reordering duplicate value?
- Can a payload force excessive CPU/memory/Instances/logging?
- Does failure default safe without overwriting known data?
- Is sensitive state replicated or logged?
- Is the action covered by fuzz and abuse tests?

## Roblox Studio MCP security audit

Security reviews must begin by discovering the connected `Roblox_Studio` MCP session, recording its `studio_id`, and enumerating the tools and skills it actually provides. Do not treat the `rbx-*` list in [roblox_skills_guide.md](./roblox_skills_guide.md) as installed capabilities. When available, use Studio inspection/playtest/Luau tools to inventory remotes and replicated secrets, replay bounded malformed-payload fixtures, verify server-side rejection paths, and check that exploit attempts cannot create durable value. Use `rbx-debug` to inspect authoritative validation state, `rbx-docs-search` to verify uncertain platform security semantics, and the profiling/heap skills to identify denial-of-service amplification or retained attacker data. Never send credentials, private tokens, production records, exploit thresholds, or sensitive logs through MCP calls.

Create a custom skill such as `universe-security-gate` only after the threat checklist, remote corpus, Horus audit, and evidence format are stable and recurring. Keep it workspace-scoped under `.agents/skills/` (or the supported `.agent/skills/` path); keep exact attack fixtures and redaction rules in controlled `references/`/`scripts/`; avoid the reserved `rbx-` prefix; and use `rbx-create-skill` only when discovered on the active server. The skill may orchestrate checks but may not waive human/independent review, broaden MCP permissions, modify Horus, or declare a pass when a required capability was unavailable. Version and review it as security-sensitive code.
