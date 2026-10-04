# Autonomous Agent Instructions

These instructions apply to every AI agent working in this repository.

## Mission

Build **Universe Creator: Genesis** as a production-quality, PC-only Roblox experience using AI-produced code and project-owned, Roblox-compatible generated assets. Preserve the core fantasy: start with one star; progressively operate at system, galactic, cluster, cosmic-web, and cosmic-epoch scale. Multiplayer, visual beauty, endless meaningful progression, safety of persistent creations, and minor ethical monetization are mandatory.

This folder is the live project root and primary development environment. Place implementation, tests, tools, manifests, audit artifacts, and project-scoped skills here. Do not treat it as a documentation-only or disposable concept directory. Read `roblox_skills_guide.md` before Roblox Studio automation, debugging, performance, scene, heap, documentation lookup, or custom-skill work; verify the named MCP skills are available in the active environment before relying on them.

## Decision order

1. Player data integrity and safety.
2. Server authority and exploit resistance.
3. Stable frame time, memory use, and network budget.
4. Determinism and reproducibility.
5. Comprehensible, satisfying play.
6. Visual richness.
7. Feature breadth.

When requirements conflict, protect the higher item. Record consequential choices in `docs/adr/ADR-NNN-title.md` (create the folder when first needed).

## Required reading before work

- Always: `README.md`, this file, `18-CODING-STANDARDS.md`, and the assigned phase section.
- Gameplay: `00-CONCEPT.md`, `01-GAME-DESIGN.md`, `13-UI-UX-AND-VISUAL-DIRECTION.md`.
- Runtime systems: `02-TECHNOLOGY.md`, `03-ARCHITECTURE.md`, `12-PERFORMANCE-AND-OPTIMIZATION.md`.
- Generation: `08-PROCEDURAL-GENERATION.md`.
- Networking/data/security: `09-MULTIPLAYER-AND-NETWORKING.md`, `10-DATA-PERSISTENCE.md`, `11-SECURITY.md`, `05-HORUS-INTEGRATION.md`.
- Assets: `17-AI-ASSET-PIPELINE.md`.
- Release work: `16-TESTING-AND-QA.md`, `19-RISK-REGISTER.md`.

## Autonomous work protocol

1. Restate the narrow deliverable in a task note.
2. Inspect existing code, tests, dirty changes, schemas, and ADRs. Never overwrite unrelated work.
3. Define acceptance criteria and measurable budgets before implementation.
4. Implement the smallest vertical change that is fully testable.
5. Add or update tests with the code.
6. Run formatting, linting, type checks, unit tests, integration tests, and relevant Studio tests.
7. Profile any hot path or rendering change. Never claim optimization without before/after evidence.
8. Run the Horus compatibility/security checklist when loaders, remotes, sessions, Actors, or serialization change.
9. Update documentation, schema versions, changelog/task note, and asset manifest.
10. Report files changed, tests run, measurements, risks, and the next unblocked task.

## Roblox Studio MCP and custom-skill policy

- Before Studio work, inspect the active Roblox Studio MCP server and load only the relevant built-in skill described in `roblox_skills_guide.md` (for example debugging, performance profiling, scene analysis, heap profiling, or current API lookup). If the capability is missing, state that limitation and use the documented fallback rather than inventing results.
- Use MCP Studio operations for evidence: inspect the live DataModel before editing, run the smallest appropriate playtest, collect server and client output, and retain measurements or screenshots required by the work packet.
- Create a workspace skill in `.agents/skills/<name>/SKILL.md` when the same project-specific sequence has occurred or is planned at least twice, crosses a high-risk boundary, or needs an exact checklist to remain reproducible. A skill must have valid YAML `name`/`description`, a concise `SKILL.md`, optional reusable scripts/references, explicit triggers, inputs, outputs, failure behavior, and verification steps.
- Never use the reserved `rbx-` prefix for project skills, duplicate a built-in Studio skill, or encode secrets, machine-specific credentials, unverified API claims, or irreversible publishing actions in a skill.
- Changes to a custom skill are reviewed like code. Test its trigger wording and procedure on a non-production case, then update all documents that rely on it.

## Stop conditions

Stop and request human direction only when a decision changes the product promise, monetization ethics, live data, irreversible publishing state, credentials, ownership, legal/provenance posture, or would require modifying upstream `Horus-main`. Normal implementation choices should be resolved using these documents and an ADR.

## Hard engineering rules

- Use `--!strict` in production Luau modules; exported interfaces use explicit types.
- The server owns economy, progression, unlocks, generation decisions, permissions, rankings, challenge outcomes, and save commits.
- Treat every client message as fabricated. Validate type/schema, finiteness, bounds, permissions, state transition, ownership, distance where relevant, rate, and replay/order.
- Encryption or obfuscation never establishes client trust.
- Clients render, predict reversible presentation, collect input, and request intent. They do not award value.
- Use integer/fixed-point units for durable economy and canonical simulation values where floating drift matters.
- Never save Roblox Instances, full generated geometry, or cosmetic particle state. Save schemas, seeds, decisions, sparse deltas, and summaries.
- No `math.random()` in deterministic generation. Use named RNG streams derived from canonical seeds.
- No frame loop that scans an unbounded collection. All work uses budgets, queues, spatial partitions, or event-driven updates.
- Parallel workers compute immutable/plain-data results; serial code validates and commits DataModel mutations.
- Remote names and schemas are declared centrally. No ad hoc RemoteEvent creation in feature modules.
- DataStore writes use `UpdateAsync`, retries with jittered backoff, session ownership, idempotency, and shutdown flushing with a deadline.
- Teleport data is routing metadata only, never trusted progression/currency.
- Feature flags protect risky rollouts. Every migration is forward-compatible and idempotent.
- Avoid externally sourced production assets. Every generated asset needs a manifest entry with prompt/tool/model/version, authoring date, transformations, ownership, and approval state.
- Do not modify `C:\Users\Luc\Desktop\DEV\Horus-main` by default. Integrate through a pinned copy or adapter in this project.

## Definition of done

A task is done only when behavior works in server/client context; failure paths are handled; tests pass; no new high-severity security issue is known; target budgets are met or a documented exception exists; relevant docs and manifests are current; and another agent can reproduce the result from the repository.

## Required handoff format

```text
Outcome:
Changed:
Verified:
Measurements:
Security/data notes:
Known risks:
Next task:
```

## Repository operations and installed tooling (owner instructions, 2026-10-04)

These notes record explicit owner instructions given in chat. They add to, and do not relax, the rules above.

### Git

- This directory is a git repository on branch `main`; `origin` is `https://github.com/WannabeCoderLuc/GENESIS.git`.
- **The owner has authorised agents to commit and push freely to `origin`.** Commit at coherent checkpoints (a verified
  slice, an ADR, a toolchain change) rather than waiting for a phase to end, and push after committing.
- The authorisation covers ordinary commits and pushes to this remote. It does **not** cover force-pushes, history
  rewrites, tags or releases, other remotes, publishing the Roblox experience, spending Robux, or modifying
  `C:\Users\Luc\Desktop\DEV\Horus-main`; each of those still needs explicit instruction.
- Commit only reviewed, verified content: no secrets, no generated binaries (`build/`, `tools/bin/` are ignored), no
  unreviewed third-party code. Never commit a state where `npm run lint:policy` or `npm run check:vectors` fails.
- Golden-vector changes need an explanation in the commit message (see `18-CODING-STANDARDS.md`).

### Installed tooling

- **Rojo 7.7.1** and **Selene 0.32.0** are installed in `tools/bin/` (git-ignored), hash-pinned in
  `tools/bootstrap/tools.lock.json` and installed/verified by `tools/bootstrap/install-tools.ps1`. The owner approved
  exactly these two downloads; installing any other binary (StyLua, a Luau analyzer, Lune, Rokit, ...) still needs
  explicit approval, a pinned hash and an entry in `docs/TOOLCHAIN.md`.
- Run before committing: `tools/bin/selene.exe src tests`, `npm run lint:policy`, `npm run check:vectors`,
  `npm run test:tools`, and the Studio test run (`.agents/skills/universe-studio-test-run`). Report gates that cannot
  run (format and type-check are **pending** until their tools are approved) as pending, never as passed.
- Full command list, gate status and the Studio MCP capability record: `docs/TOOLCHAIN.md`.
