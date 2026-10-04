# Coding Standards

## Luau

- `--!strict` for production modules; use `--!native`/optimization directives only after benchmark and compatibility review.
- Explicit exported types, narrow interfaces, and constructor dependency injection.
- Descriptive PascalCase types/classes/modules, camelCase locals/functions, UPPER_SNAKE_CASE constants.
- One module has one clear responsibility. Avoid god services and mutable global registries.
- Prefer early returns, typed result objects, and exhaustive state handling.
- Never ignore `pcall` failure; convert it to a typed/logged boundary result.
- Validate all external/cloud/client data before domain use.
- Disconnect events, cancel tasks, release leases, and destroy owned Instances in lifecycle teardown.

## Determinism

- Canonical calculations use project unit types and explicit rounding/quantization.
- No `math.random()` or time-derived randomness in generation/gameplay.
- Sort keys before deterministic iteration; never rely on hash table order.
- Separate simulation RNG from cosmetic RNG.
- Include schema/generator/ruleset versions in serialized outputs.

## Numeric safety

Check `value == value` and magnitude bounds to reject NaN/infinity-like invalids. Use integer/fixed-point durable resources. Clamp only when clamping is a documented gameplay rule; reject malicious/out-of-domain input rather than hiding it. Avoid representing astronomical magnitudes as Workspace positions.

## Server/client boundaries

Remote contracts live in `Shared/Contracts`; registration lives in the transport composition root. Client sends intent, never final values. Server handlers are thin: validate, call domain command, commit, publish. UI does not import server modules. Replicated modules contain no secrets.

## Async and cloud calls

Every async operation has timeout/cancellation strategy and typed failure. Retries are bounded, jittered, and only for idempotent/recoverable operations. Do not yield while holding mutable locks. DataStore calls are centralized and budget-aware.

## Parallel code

Document thread-safety and ownership. Require dependencies before desynchronizing. Parallel phase performs pure/read-safe calculations; synchronize for DataModel mutations. Messages carry version/address and bounded plain data. Test different worker counts for identical output.

## Errors and logging

Use stable codes (`SAVE_LEASE_CONFLICT`, `CMD_PERMISSION_DENIED`) plus context fields. Player messages are friendly and non-sensitive. Logs omit session keys, raw tokens, private text, receipt details beyond safe IDs, and large payloads. Sample repetitive rejects.

## Comments and documentation

Comments explain invariants, units, reasoning, and non-obvious constraints—not syntax. Public interfaces include purpose, inputs, output/failure, authority side, and performance notes. Update ADRs for consequential decisions.

## Tests and commits

Tests accompany behavior. Golden changes require explanation. Do not weaken/remove a failing test just to pass. Keep changes focused; never mix broad formatting with logic. Generated files are marked and changed through their generator, not hand-edited.

## Roblox Studio MCP and custom-skill standard

For Studio-dependent changes, use the `Roblox_Studio` MCP server to inspect the real DataModel, run Luau/playtests, debug runtime state, and gather profiling evidence. Select the correct Studio session/`studio_id` and verify the server's exposed tools and skills at task start; never assume that a name in [roblox_skills_guide.md](./roblox_skills_guide.md) is available. Use `rbx-docs-search`, `rbx-debug`, profiling, scene-analysis, or heap-profiling skills only after that check. Repository source remains authoritative: reconcile intentional Studio-side edits into reviewed files and do not leave important logic only in an unsaved Studio session.

Create a project-specific custom skill only when a bounded workflow recurs, has stable inputs/outputs, and benefits from enforced checks. Put it in `.agents/skills/<skill-name>/SKILL.md`, use YAML `name` and an exact trigger-oriented `description`, avoid the reserved `rbx-` prefix, and move bulky details or reliable helpers into `references/` and `scripts/` as the guide specifies. Skills are code-reviewable automation: pin assumptions, validate arguments, provide a dry-run where mutations are possible, expose failures, and update or retire the skill when architecture or MCP capabilities change.

## Example module contract

```luau
--!strict
export type StabilizeStarCommand = {
    commandId: string,
    target: UniverseAddress,
    influenceMilli: number,
}

export type StabilizeStarResult =
    { ok: true, revision: number, stabilityDeltaMilli: number }
    | { ok: false, code: string }
```

Names include units (`massMilliSolar`, `timeSeconds`) where ambiguity is possible.
