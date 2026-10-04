# Toolchain

Recorded after inspecting the actual machine (2026-10-04, Windows 11 23H2 x86_64, PowerShell 5.1). Nothing here is
assumed: every row says whether it was **installed**, **verified**, or is **pending**. Bootstrapped binaries are
hash-pinned in `tools/bootstrap/tools.lock.json` and installed by `tools/bootstrap/install-tools.ps1` into
`tools/bin/` (git-ignored).

## Active toolchain

| Tool | Version | Source | Purpose | Status |
|---|---|---|---|---|
| **Rojo** | 7.7.1 | GitHub release `rojo-7.7.1-windows-x86_64.zip`, SHA-256 `d4dfa349...ba0b82` | project layout validation, `sourcemap`, place build | **Installed** (user-approved 2026-10-04). Used by `tools/studio-sync` |
| **Selene** | 0.32.0 | GitHub release `selene-0.32.0-windows.zip`, SHA-256 `c8b693de...416109` | Luau lint, also a full Luau **parse** of every file | **Installed** (user-approved 2026-10-04). 0 errors / 0 warnings / 0 parse errors |
| Node.js | v22.16.0 | pre-installed | repo tooling (zero npm dependencies), BigInt reference model, policy lint | verified |
| Git | 2.54.0.windows.1 | pre-installed | source control, `origin` = `https://github.com/WannabeCoderLuc/GENESIS.git` | verified. Owner has authorised agents to commit and push freely (see `AGENTS.md`) |
| Roblox Studio | 0.741.19.7411056 | pre-installed, via `Roblox_Studio` MCP | the **only Luau runtime on this machine**: runs the test-suite and the server/client smoke test | verified, `studio_id 8978c8bc-b110-47f2-b72f-0f2f2c13605e`, place `Genesis` (`placeId 121145903454904`) |
| Python | 3.13.3 | pre-installed | not used by the project | n/a |

## Not installed (pending owner approval, because each is a download)

| Tool | Why we want it | Impact while missing |
|---|---|---|
| **Luau analyzer** (`luau-analyze` or `luau-lsp analyze`) | the only way to type-check `--!strict` code. Studio exposes no API for its diagnostics | **Type-check gate is PENDING.** Strict annotations are written carefully and parsed by Selene, but types are not machine-verified |
| **StyLua** | formatter; `stylua.toml` is already committed | **Format gate is PENDING** |
| **Lune** | run Luau tests from a terminal without Studio (CI-friendly) | tests run only through Studio MCP |
| **Rokit** | pins every tool in one `rokit.toml` | replaced for now by `tools.lock.json` + `install-tools.ps1` |

Adding a tool: add a pinned entry (URL, size, SHA-256) to `tools.lock.json`, record the approval, update this file.

## Commands

```bash
# install / verify the pinned binaries (Rojo, Selene)
powershell -NoProfile -ExecutionPolicy Bypass -File tools/bootstrap/install-tools.ps1

# Rojo: validate the project and build a place file
tools/bin/rojo.exe build default.project.json -o build/genesis.rbxl
tools/bin/rojo.exe sourcemap default.project.json --include-non-scripts -o build/sourcemap.json

# Selene lint (config: selene.toml)
tools/bin/selene.exe src tests

# repo policy lint (strict header, no-random, layering, error codes, ad-hoc remotes, ...)
npm run lint:policy

# reference model + golden vectors
npm run test:tools           # node --test (reference anchored to published FNV-1a / SplitMix64 vectors)
npm run gen:vectors          # regenerate generated/source/GoldenVectors/*.luau + manifest
npm run check:vectors        # fail on drift

# Horus pin verification (after tools/horus-pin.mjs lands, see vendor/Horus/UPSTREAM.md)
npm run horus:verify

# everything that runs without Studio
npm run check
```

## Running the Luau test-suite (Studio MCP)

Studio is the Luau VM. The workflow, exactly as used for the evidence in `docs/tasks/`:

1. `npm run studio:serve` (loopback-only manifest server, `127.0.0.1:8765`, three read-only routes).
2. Through the MCP `execute_luau` tool (`datamodel_type = "Edit"`), run the stub in
   `.agents/skills/universe-studio-test-run/SKILL.md`: it fetches `StudioSync.luau`, calls `install()` (materialises the
   Rojo-mapped tree; every created instance carries attribute `UCSync = true`) and `runTests()`.
3. Read the returned report (counts, per-suite results, failures with stack traces).
4. `teardown()` removes only `UCSync` instances. Nothing is saved or published.

## Gate status

| Gate | Status |
|---|---|
| Format (StyLua) | **pending** (not installed) |
| Lint (Selene) | pass |
| Policy lint (`tools/lint-policy.mjs`) | pass |
| Type check (`--!strict`) | **pending** (no analyzer installed; Studio exposes none) |
| Unit + deterministic tests (Studio VM) | see `docs/tasks/2026-10-04-phase0-foundation.md` for the latest counts |
| Golden-vector drift (`check:vectors`) | pass |
| Node reference tests | pass |
| Studio server/client smoke | see task note |

## Studio MCP capability record

Discovered, not assumed (`generated/manifests/studio-mcp-capabilities.json`): tools include `execute_luau`,
`start_stop_play`, `get_console_output`, `search_game_tree`, `inspect_instance`, `script_read/grep/search`,
`multi_edit`, `http_get`, `screen_capture`, `skill`. Skills confirmed by invocation: `rbx-docs-search`,
`rbx-create-skill`, `rbx-unit-test`, `rbx-luau-heap-profiling`. Listed by the server but not yet invoked: `rbx-debug`,
`rbx-perf-profiling`, `rbx-scene-analysis`, `rbx-device-simulator-lua`, `rbx-configs-experimentation`,
`rbx-convert-to-streaming`. `create_skill` / `edit_skill` tools are **not** exposed here, so custom skills are created
through the normal reviewed file workflow under `.agents/skills/`.
