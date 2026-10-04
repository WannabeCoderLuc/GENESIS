# Retention and Live Operations

## Ethical retention model

Players return because their universe changes meaningfully, long projects complete, discoveries remain, social visits matter, and new cosmic rules create fresh decisions. Avoid obligation loops, punishing streaks, excessive timers, and noisy daily chores.

## Retention layers

- **Session:** clear next objective, satisfying transformation, safe stopping point.
- **Return:** bounded offline digest, completed projects, new anomalies, visitor activity.
- **Week:** mastery objective, collaborative construction, equal-seed challenge rotation.
- **Season:** cosmetic theme, new anomaly family or rule variant, curated showcase, archived rankings.
- **Long-term:** Archivarium completion, specialization, historical universes, cosmic epochs.

## Dynamic events

Events are deterministic from schedule seed and current state, telegraphed, and deduplicated. Live operations may select event families and parameters but cannot inject arbitrary code or unvalidated assets. Offline event resolution is safe and summarized. Rare events use pity/eligibility logic where pure randomness would create unreasonable droughts.

## Daily/weekly design

Offer a small set of optional observations rather than mandatory chores: inspect a phenomenon, improve stability, host/help a visit, or attempt a normalized challenge. Missed objectives do not break streaks or remove earned value. Rewards emphasize cosmetics, knowledge, and discovery routes rather than power.

## Seasons

A season introduces one coherent cosmic theme and ruleset. Persistent home universes remain compatible. Competitive seasonal activities use equalized seeds/divisions. At season end, results and exhibits archive; core content remains or returns predictably. No destructive reset.

## Content operations pipeline

1. Define event/ruleset as data under a versioned schema.
2. Simulate distribution, economy, difficulty, and exploit cases.
3. Generate/validate owned visual/audio assets and manifests.
4. Stage behind a flag; run published multi-place tests.
5. Canary to a small cohort, watch errors/performance/economy.
6. Expand gradually; preserve one-click kill switch.
7. Archive outcomes and conduct retrospective.

## Roblox Studio MCP and project skills

Use the `Roblox_Studio` MCP server against a named staging Studio session to load an event configuration, run deterministic schedule seeds, exercise feature flags and kill switches, and capture playtest/debug/performance evidence before canary expansion. First verify which MCP tools and built-in skills the connected server actually exposes; [roblox_skills_guide.md](./roblox_skills_guide.md) documents likely capabilities such as debugging, performance profiling, scene analysis, heap profiling, and documentation lookup, but agents must not assume any capability is installed or available. Versioned repository data remains the source of truth, and MCP access does not authorize production publication or irreversible live-state changes.

When the same season or incident procedure has been executed successfully more than once, create a narrowly scoped custom skill for the workspace, such as `universe-liveops-canary` or `universe-incident-triage`. The skill should encode staging prerequisites, simulation commands, evidence fields, stop conditions, rollback checks, and required human gates; place it under `.agents/skills/` and follow the naming and progressive-disclosure rules in the guide. Do not create a skill for a one-off event or embed mutable season content inside the workflow instructions.

## Telemetry

Measure tutorial steps, time-to-ignition, first planet, scale promotion, return after offline digest, session length distribution, activity diversity, automation use, visits hosted/completed, challenge completion, performance tier, error/retry, and churn points. Use cohorts and funnels; do not optimize for raw minutes at the cost of wellbeing.

## Live incident levels

- SEV-1: data loss/duplication, receipt issue, broad exploit, privacy bypass—disable affected writes/features immediately.
- SEV-2: major teleport failure, challenge integrity, severe performance—stop rotation/canary and rollback.
- SEV-3: visual/content defect—flag off or hotfix in normal cycle.

Every incident records timeline, affected builds/data, containment, repair, validation, and prevention. Automated agents may enact pre-approved feature flags but may not publish irreversible data repair without reviewed dry-run evidence.
