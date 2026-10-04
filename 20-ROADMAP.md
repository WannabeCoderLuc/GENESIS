# Roadmap

## Now — prove the impossible parts

- Repository/tool bootstrap and deterministic core.
- Horus compatibility/security/performance spike.
- Continuous-scale camera and floating-origin proof.
- First Star simulation, renderer, command, save/load.
- Two-client consistent view and basic visit.
- Reference hardware budgets and visual target captures.

Decision: proceed only if the star is satisfying, scale transition is convincing, and saves/remotes are safe.

## Next — complete the first hour

- Planet formation and orbital tools.
- Six planet archetypes, first anomalies, Archivarium.
- Automation as graduation.
- Equal-seed challenge and Observatory loop.
- Offline digest, accessibility, photo mode.

Decision: proceed if players understand tradeoffs without a lecture and choose diverse activities.

## Then — make it social and persistent

- Robust visits, permissions, collaborative projects.
- Published multi-place routing and reserved servers.
- Sector streaming, multiple stars, life/civilizations.
- Category rankings and safe showcase surfaces.
- Operations telemetry and support/recovery tooling.

Decision: proceed if social sessions add value without threatening ownership or budgets.

## Expansion — earn galactic scale

- Galaxy morphology/sculpting, representative populations.
- Mergers and long-horizon projects.
- Cluster and cosmic-web strategic layers.
- Epoch archives and altered physical-law rules.
- Optional Interstitial Void after protected systems are mature.

## Post-launch cadence

- Small monthly anomaly/challenge/rule additions.
- Larger seasonal theme with one new mechanical combination.
- Continuous performance, exploit, data, and onboarding work.
- New cosmetic sets only when core content ships alongside them.

## Roblox Studio MCP and skill milestones

- **Now:** connect the intended Studio place to the `Roblox_Studio` MCP server, record the `studio_id`/place identity, and inventory the tools and built-in skills actually exposed. Use verified documentation lookup, debugging, profiling, scene-analysis, and heap-profiling capabilities for the first-star and scale proofs; the names in [roblox_skills_guide.md](./roblox_skills_guide.md) are guidance, not an availability guarantee.
- **Next:** after repeated first-hour and accessibility runs, create a focused workspace skill such as `universe-first-hour-validation` to reproduce seeds, captures, assertions, and evidence. Do not create it before the workflow is stable.
- **Then:** consider `universe-multiplayer-matrix` and `universe-liveops-canary` skills for published staging, teleport, permissions, rollback, and incident gates. Keep production publication and irreversible data actions behind explicit authorization regardless of MCP access.
- **Expansion/post-launch:** add or revise skills only when generator compatibility, asset budgets, or release operations have repeatable contracts. Review every skill at milestone gates and retire stale ones.

All project-specific custom skills live under `.agents/skills/`, follow the guide's frontmatter and progressive-disclosure structure, avoid the reserved `rbx-` prefix, and are reviewed/tested like source code. Every roadmap decision gate must cite MCP-derived evidence where Studio behavior matters, plus a documented fallback or gap when the required capability is unavailable.

## Feature priority rubric

Score 0–3 each: reinforces scale fantasy, adds a new decision, reuses architecture, supports multiple personas, improves social value, has bounded performance/data risk, and is testable. Subtract 0–3 each for security/data risk, asset burden, tutorial cost, and ongoing operations burden. High scores enter planning; low scores remain ideas regardless of spectacle.

## Launch content target

Launch quality matters more than reaching the literal cosmic web. A credible launch may end at early galaxy scale if First Star, systems, visits, automation, Archivarium, challenges, and galactic formation are polished. Cluster/web/epochs can be visible as the long-term roadmap rather than shallow at launch.

## Definition of project success

- A new player creates a memorable first star within 90 seconds.
- The same player can later locate and revisit it from galactic scale.
- Progress introduces new verbs and automates mastered chores.
- Players can admire/help/compete without risking protected creations.
- A mature universe remains compact, deterministic, recoverable, and performant.
- Spending is unnecessary for power or completion.
- Autonomous agents can extend content without breaking old universes because contracts, versions, tests, budgets, and review gates are explicit.
