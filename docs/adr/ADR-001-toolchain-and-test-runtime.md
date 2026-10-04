# ADR-001: Toolchain and Luau test runtime

Status: Accepted, 2026-10-04

## Context

`02-TECHNOLOGY.md` requires pinned tools and says agents must not invent commands. Inspection of the machine found
Git, Node 22, Python 3.13, Chocolatey and Roblox Studio (with the `Roblox_Studio` MCP server) but **no** Rojo, Selene,
StyLua, Luau CLI, Lune or Rokit. Phase 0 needs a real Luau runtime to execute deterministic tests.

## Decision

1. **Test runtime = Roblox Studio's Luau VM, driven through the Studio MCP server.** It is the production VM, so tests
   exercise the exact `bit32`, `buffer`, `string.pack` and number semantics the game will run.
2. **Independent oracle.** Expected values for all determinism tests come from `tools/reference/uc-reference.mjs`, a
   BigInt/`Math.imul` model that shares no code with the Luau implementation and is itself anchored to published
   FNV-1a-64 and SplitMix64 vectors. Golden vectors are generated, committed and drift-checked.
3. **Install only what the owner approves, hash-pinned.** Rojo 7.7.1 and Selene 0.32.0 are installed from their GitHub
   release assets by `tools/bootstrap/install-tools.ps1`, which rejects any archive whose SHA-256 differs from
   `tools.lock.json`. Approvals so far: Rojo and Selene (owner, in chat, 2026-10-04).
4. **Rojo is the authority on file -> Instance mapping.** `rojo sourcemap` feeds the Studio sync; we do not
   re-implement mapping rules.
5. **Zero npm dependencies.** Repository tooling uses only Node built-ins, removing a supply-chain surface.
6. **Spec-compatible tests.** Spec modules return `function(t) t.test(name, fn) end`, the same contract as Studio's
   built-in `rbx-unit-test` harness, so either runner can execute them.

## Alternatives considered

- Install Lune/Luau CLI/Rokit now: faster and CI-friendly but unapproved downloads; deferred, still desirable.
- Re-implement Rojo's mapping in Node: rejected, drift risk against the real tool.
- Test in plain Node by transliterating Luau: rejected, would not test the real VM semantics.

## Consequences

- Tests need an open Studio session; CI without Studio cannot run Luau tests until Lune (or equivalent) is approved.
- The type-check and format gates remain **pending** until an analyzer and StyLua are approved (docs/TOOLCHAIN.md).
- Studio writes are confined to attribute-marked instances and are reversible (`teardown`).

## Verification

`docs/TOOLCHAIN.md` gate table; `tools/bootstrap/install-tools.ps1` hash check; Rojo build and sourcemap succeed;
Studio test report in `docs/tasks/2026-10-04-phase0-foundation.md`.
