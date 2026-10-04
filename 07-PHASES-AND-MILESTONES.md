# Phases and Milestones

Dates are intentionally not promised before team throughput is measured. Progress is exit-criteria driven.

## Phase 0 — Feasibility and contracts

Deliver deterministic seed prototype, star simulation, logarithmic camera/representation proof, save schema, multi-client command path, Horus spike, and target-device profile.

Exit: same seeds reproduce outputs; reconnect preserves the star; two clients observe consistent state; 60 FPS target on reference PC in the small scene; no unresolved critical security/data risk.

## Phase 1 — First Star playable

Deliver polished 15-minute flow from void to ignition, meaningful tuning, one event, three discoveries, save/load, settings, photo mode, and a basic visitor.

Exit: at least 90% of internal runs ignite without help; no data loss in failure injection; visual/audio sequence meets review bar; remote abuse corpus passes.

## Phase 2 — Planetary alpha

Deliver six planet archetypes, orbital tools, system economy, automation seed, twelve Archivarium entries, and equal-seed challenge.

Exit: 30–60 minute loop remains legible; system reload is deterministic; four-client challenge completes; LOD transition has no blocking spike over budget.

## Phase 3 — Social closed alpha

Deliver Observatory, routing, privacy, visits, collaboration proposals, host rewards with abuse caps, moderation/report touchpoints, and cross-server presence.

Exit: published staging teleports succeed under retries; unauthorized visitors/actions fail; server loss does not corrupt universes; visit performance meets budget.

## Phase 4 — Interstellar beta

Deliver sectors, multi-star automation, life, civilizations, trade graph, co-op events, and broader progression.

Exit: representative 7-day simulated profile remains stable; offline summaries are bounded; content repetition metrics acceptable; no unbounded scheduler queues.

## Phase 5 — Galaxy beta

Deliver galactic formation/sculpting, morphology, representative populations, mergers, specialized Cosmic Index leaderboards, and showcase surfaces.

Exit: galaxy transition is understandable and spectacular; deterministic drill-down works; saves remain compact; low-tier clients maintain memory/frame budgets.

## Phase 6 — Launch candidate

Deliver onboarding polish, accessibility, complete rollback, live dashboards, support tooling, data deletion/export process, minor cosmetic commerce, and release content.

Exit: full release matrix passes; staged migrations and rollback rehearsed; receipts are idempotent; policy/age/rating checks completed by account owner; 72-hour soak has no severity-1 issue.

## Phase 7 — Cosmic expansion

Deliver clusters, cosmic web, epoch archive and mechanically distinct laws, then the optional Interstitial Void.

Exit: each scale introduces new decisions and automation; archived epochs remain revisit-able; Void loss is explicit and cannot affect protected home state.

## Roblox Studio MCP and custom-skill gates

At the start of every phase, the agent must discover the connected `Roblox_Studio` MCP session, record its `studio_id`, and enumerate the tools and skills the server actually exposes. It must not assume that an `rbx-*` skill or a Studio action exists merely because it appears in [roblox_skills_guide.md](./roblox_skills_guide.md). If the MCP server, required skill, or required Studio capability is unavailable, record that limitation in the phase report and use an explicit manual/local test fallback rather than inventing a call.

- Phase 0 uses the MCP server to inspect the live DataModel, verify API assumptions with `rbx-docs-search` when available, and run the first deterministic/runtime probes.
- Phases 1–3 use available Studio playtest and Luau-execution tools plus `rbx-debug` for runtime faults, multi-client command paths, visit permissions, and failure injection.
- Phases 2–5 use `rbx-perf-profiling`, `rbx-scene-analysis`, and `rbx-luau-heap-profiling` when discovered to capture generation, LOD, streaming, and memory evidence from representative seeds.
- Phases 6–7 repeat the MCP-backed security, performance, migration, and visual baselines against the release candidate and each new scale domain.

Create a workspace-scoped custom skill only after a phase exposes a stable, repeatable project workflow that ordinary instructions do not express reliably—for example deterministic seed certification, remote-abuse replay, migration rehearsal, or fixed-camera visual capture. Store it under `.agents/skills/<name>/` (or the supported `.agent/skills/<name>/` form), avoid the reserved `rbx-` prefix, keep `SKILL.md` concise, and place heavy references or repeatable scripts in `references/` and `scripts/`. Use `rbx-create-skill` only if the MCP inventory confirms it is available; otherwise create and review the skill files through the repository workflow. A new or changed skill is itself a milestone artifact and must be tested on a disposable Studio session before agents may rely on it.

## Milestone governance

Every exit review includes product demonstration, automated report, security/data review, performance captures on reference tiers, current risk register, dependency/vendor hash, migration rehearsal, MCP capability record, custom-skill version/hash where used, and a go/no-go decision. Failed mandatory criteria defer the milestone; features are cut before budgets are waived.
