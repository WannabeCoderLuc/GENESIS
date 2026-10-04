# AI-Only Development Workflow

## Principle

AI agents perform design elaboration, coding, test creation, asset generation, documentation, profiling analysis, and defect repair. Human involvement is limited to product approvals, account/ownership actions, publishing credentials, age/identity-gated API enablement, policy decisions, and subjective acceptance where automation cannot responsibly decide.

“AI-only” does not mean unreviewed. Every output must be traceable, reproducible where possible, tested, and accepted by an independent automated or agent review gate.

## Roles

- **Planner:** converts a milestone into vertical tasks, dependencies, budgets, and acceptance tests.
- **Implementer:** changes code/assets narrowly and supplies evidence.
- **Reviewer:** checks architecture, correctness, exploit paths, data compatibility, and scope.
- **Performance auditor:** captures comparable profiles and budget reports.
- **Security auditor:** threat-models each new boundary and fuzzes commands.
- **Visual QA agent:** renders screenshots/video at specified viewpoints and compares composition/readability.
- **Release agent:** verifies manifests, migrations, flags, rollback, and staging telemetry.

One agent may perform multiple roles, but a high-risk change requires a separate review pass with fresh context.

## Work packet template

```markdown
# Task: <single outcome>
Context: linked requirement/ADR
Inputs: exact files, schemas, assets
Acceptance:
- observable behavior
- tests
- performance budget
- security/data condition
Out of scope:
Risks:
Evidence required:
```

Tasks should fit one coherent review. Avoid “build the entire galaxy system.” Prefer “produce deterministic spiral-arm density samples from a versioned galaxy seed and golden-test them.”

## Execution loop

1. **Discover:** read instructions and inspect code, current tests, dependency versions, and uncommitted work.
2. **Specify:** write/update contracts and acceptance checks first.
3. **Prototype:** prove the riskiest unknown in isolation; discard spikes unless promoted deliberately.
4. **Implement:** domain first, adapter second, presentation last.
5. **Verify:** format, lint, type, unit, property, integration, multi-client, security, performance, and visual tests as applicable.
6. **Review:** independent pass against threat model, budgets, and product pillars.
7. **Record:** ADR, changelog/task note, schemas, generator version, asset manifest, and measurements.
8. **Promote:** merge behind a flag; staging soak; progressively enable.

## Prompting rules for agents

Give agents bounded context and source-of-truth files. Prompts state desired behavior and invariants, not merely filenames. Require agents to cite local evidence for API assumptions and to flag any current Roblox API that must be rechecked. Never ask an agent to “optimize everything”; name a metric and workload.

## Roblox Studio MCP operating procedure

For every task that needs Studio state, the agent must:

1. discover whether a `Roblox_Studio` MCP server is connected and enumerate its current tools/skills;
2. confirm the intended `studio_id`, place role, build ID, and whether edit or play mode is required;
3. request the smallest applicable built-in skill described in `roblox_skills_guide.md`, such as `rbx-docs-search`, `rbx-debug`, `rbx-perf-profiling`, `rbx-scene-analysis`, or `rbx-luau-heap-profiling`;
4. perform bounded, source-traceable changes and run the relevant Studio playtest/profile;
5. record exact observations, outputs, and limitations in the work packet; and
6. stop and mark the Studio gate unverified if the server, tool, skill, or target session is unavailable—never simulate a successful MCP result.

MCP is preferred for live DataModel inspection, in-engine scripts/instances, runtime debugging, multi-client behavior, visual QA, and performance evidence. Repository edits, deterministic unit tests, schemas, and generated source assets remain source-controlled and must not exist only inside an unsaved Studio session.

## Custom-skill creation rule

Create a project-specific skill when the same multi-step workflow has recurred or is scheduled to recur, has stable inputs and acceptance criteria, and would materially reduce drift or risk between autonomous agents. Candidates include universe-generation determinism audits, Horus remote reviews, first-session playtests, scene-budget captures, and release preflight. Do not create a skill merely to preserve a one-time prompt.

Follow `roblox_skills_guide.md`: prefer `.agents/skills/<skill-name>/SKILL.md`, provide precise YAML `name` and trigger-focused `description`, avoid the reserved `rbx-` prefix, keep `SKILL.md` concise, place large guidance in `references/`, and place repeatable commands in `scripts/`. Verify `rbx-create-skill` or equivalent MCP support before invoking it; when absent, use the normal reviewed file workflow. Every new or changed skill receives a dry run on a non-production Studio session and is reviewed like code.

## Asset workflow

Concept prompts become project-owned source artifacts. Generated mesh, texture, sound, image, or UI output receives a manifest entry, validation, optimization, and in-Studio render review. Reject outputs with unclear provenance, third-party logos/characters, embedded signatures, excessive geometry, unreadable UI, or mismatched visual language. See `17-AI-ASSET-PIPELINE.md`.

## Quality gates by change type

| Change | Minimum gates |
|---|---|
| Pure domain | type/lint, unit, property/golden determinism |
| Remote/command | schema tests, malformed/fuzz inputs, rate/permission tests, Horus review |
| Persistence | migration fixtures, retry/idempotency, concurrent ownership, failure injection |
| Generation | seed reproducibility, order independence, bounds, performance, visual samples |
| Rendering | frame/memory budget, LOD transitions, low-tier view, screenshot review |
| Economy | invariant simulation, receipt idempotency, abuse review |
| Teleport/multi-place | published staging test, retry/failure UI, authorization |

## Context and artifact hygiene

- Generated code must not fabricate test results or API availability.
- Store prompts and metadata, not secrets or private user content.
- Never place API keys in the repository or Roblox replicated containers.
- Avoid broad mechanical rewrites during feature work.
- Preserve a human-readable changelog of generator/schema changes.
- If output is nondeterministic, save the chosen seed and selection rationale.

## Failure handling

An agent that cannot reproduce a test or profile marks the result unverified. On three failed repair attempts, isolate the smallest failing case, document evidence, disable the feature behind a flag, and escalate. Never bypass a gate by deleting a test, loosening validation, or increasing a budget without a documented decision.

## Completion report

Every work packet ends with outcome, changed files, exact checks, measured budgets, security/data impact, manifest changes, known risks, rollback/flag, and next task. Autonomous agents may proceed to the next scheduled packet only when the current phase exit criteria remain satisfied.
