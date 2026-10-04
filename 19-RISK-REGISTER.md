# Risk Register

Scoring: probability (P) and impact (I), 1–5. Review at every milestone.

| ID | Risk | P/I | Early signal | Mitigation / owner response |
|---|---|---:|---|---|
| R01 | Continuous scale cannot feel seamless in Roblox | 4/5 | popping, long stalls, loss of orientation | prototype first; camera-relative projection, dual-representation blends, fixed screenshot paths; cut physical detail before continuity |
| R02 | Scope exceeds AI-agent capacity | 5/5 | many half-built systems, failing docs/tests | vertical slices, hard exits, WIP limits, feature cuts; galaxy work blocked until First Star quality bar |
| R03 | Save corruption/data loss | 3/5 | migration errors, lease conflicts, oversized keys | versioned sharded schemas, UpdateAsync leases, checkpoints, failure injection, read-only fail-safe |
| R04 | Exploit/dupe through remotes or transfers | 4/5 | impossible velocity, duplicate receipts, replay rejects | server authority, idempotency, transfer state machines, fuzzing, kill switches |
| R05 | Horus incompatibility or hidden defect | 3/5 | handshake deadlock, schema gap, high CPU | pinned vendor, adapter, compatibility spike/audits; replacement transport path |
| R06 | Cryptography creates false confidence | 4/4 | handlers trust decrypted values | explicit threat model, validator templates, security review required per command |
| R07 | Client CPU/GPU/memory overload | 4/5 | low FPS, editable asset failures, crashes | strict LOD/pools/budgets, StreamingEnabled, degradation ladder, tier tests |
| R08 | Server simulation grows with universe size | 4/5 | queue backlog, long heartbeat | aggregate/event simulation, materialization caps, analytical offline steps, bounded schedulers |
| R09 | Network bandwidth grows with visual density | 3/5 | packet spikes during zoom/events | semantic cues/seeds, interest management, no transform streaming, schema metrics |
| R10 | EditableMesh/Image unavailable or too costly | 3/3 | permissions/memory errors | optional flagged enhancement; static/native fallbacks; published staging validation |
| R11 | Procedural results change after updates | 4/5 | vanished discoveries/layout drift | versioned generators, named streams, golden fixtures, old-version support/epoch policy |
| R12 | Game becomes shallow clicker | 3/5 | repetitive inputs, passive-only optimal play | mastery gates, tradeoffs, automation graduation, player tests at each tier |
| R13 | Complexity overwhelms new/young players | 4/4 | low ignition/planet completion | three-action onboarding, progressive disclosure, explain panels, objective telemetry |
| R14 | Older players find systems trivial | 3/4 | low optimization/challenge return | deep tradeoffs, category rankings, automation policies, optional risk/equalized modes |
| R15 | Multiplayer still feels lonely | 3/4 | low visits/co-op completion | Observatory visibility, useful co-op, tours, host incentives capped against farming |
| R16 | Griefing damages creations | 2/5 | unauthorized mutation reports | capability permissions, read-only default, home safety invariant, reversible proposals |
| R17 | Monetization damages trust | 2/5 | complaints/non-payer churn | cosmetics only, no early prompts, ethics metrics, easy removal |
| R18 | AI asset provenance/IP concern | 3/5 | logos/style imitation, missing manifests | authorized inputs only, provenance scans, manifests, ownership upload, rejection pipeline |
| R19 | AI code invents/deprecates APIs | 4/4 | runtime/member errors | current official docs checks, staging proofs, lint/type/test gates, dependency pins |
| R20 | Teleport/reserved server instability | 3/4 | failed visits/party splits | retry UX, tickets, durable pre-save, published tests, safe Observatory return |
| R21 | Cloud quotas/throttling | 3/5 | write queues, MemoryStore failures | coalescing, sharding, budgets, backoff, caches, load shedding; never hardcode assumed quotas |
| R22 | Offline progress exploits/catastrophe | 3/4 | clock anomalies, huge awards/loss | server time, caps, analytical deterministic digest, no offline irreversible loss |
| R23 | Generated content repetition | 4/3 | same-looking systems/events | hierarchical parameter diversity, rarity bands, authored rule combinations, repetition telemetry |
| R24 | Visual beauty conflicts with clarity | 3/3 | unreadable labels/overexposure | information layers, restrained effects, accessibility captures, visual budgets |
| R25 | Live migration/rollback incompatibility | 3/5 | old/new server conflicts | additive protocols, compatible windows, flags, rehearsal, kill switches |
| R26 | Roblox Studio MCP is unavailable, stale, or targets the wrong Studio session | 3/4 | missing tools, unexpected DataModel, evidence from another place/build | verify connection, place/build, `studio_id`, and exposed tool/skill inventory per task; fail closed on mutations; retain local/manual test fallback |
| R27 | Project custom skill becomes unsafe or obsolete | 3/4 | outdated paths/API assumptions, over-broad trigger, silent skipped gates | workspace scope, narrow trigger, versioned review/tests, dry-run for mutations, named owner, retire on architecture/MCP change |

## Roblox Studio MCP and skill controls

Treat MCP output as runtime evidence, not authority to publish or bypass gates. Agents must verify the live `Roblox_Studio` MCP tool/skill inventory before relying on any built-in named in [roblox_skills_guide.md](./roblox_skills_guide.md), positively identify the intended Studio session, and record fallbacks when a capability is absent. A failed availability check may reduce test coverage; it may not be reported as a passed test.

Create a custom workspace skill only when it repeatedly mitigates a named risk—for example, `universe-save-failure-injection`, `universe-remote-fuzz`, or `universe-release-gate`. Follow the guide's `.agents/skills/` structure and naming rules, link the skill to its risk IDs and evidence outputs, and reassess it at every milestone. Custom skills must not contain secrets, hide destructive actions, or encode acceptance of a high risk that still requires an ADR or owner review.

## Risk acceptance

No agent may accept a P×I score ≥15 without an ADR and owner review. P×I 10–14 requires a named mitigation task and evidence before the affected milestone. Risks are closed only with evidence, not optimism.
