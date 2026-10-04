# Project state audit — start of Phase 0 (2026-10-04)

Method: recursive directory listing of the project root and of `Horus-main`, full read of `AGENTS.md`, `README.md`,
`roblox_skills_guide.md` and documents 00, 02-12, 16, 18-20 (01, 13-15, 17 consulted when relevant), toolchain probe, live Studio MCP
discovery. Nothing was modified before this audit was taken.

## Project root (before any change)

- 25 Markdown specifications (`00`-`20`, `AGENTS.md`, `README.md`, `roblox_skills_guide.md`): the whole project was documentation.
- `src/`, `tests/`, `tools/`, `vendor/`, `generated/{manifests,source}/`, `artifacts/audits/`, `.agents/skills/`: each contained only a
  `.gitkeep`. **No Luau, no tests, no tooling, no project file, no git repository.**
- Not a git repository (`fatal: not a git repository`). The owner then supplied the remote
  `https://github.com/WannabeCoderLuc/GENESIS.git` (verified empty and reachable); a local repo was initialised on `main`.

## Horus-main (read-only reference)

- 102 files: `LICENSE` (CC0 1.0), `README.md`, `selene.toml` (`std = "roblox"`), `src/ReplicatedStorage/Packages/{Horus,Cryptography}`,
  `src/ServerScriptService/Horus`. Not a git repository (no commit to pin).
- Uses string requires (`@game/...`, `@self/...`) and Studio's file-sync layout (`Foo.luau` beside `Foo/`). Provides loader,
  Sera schema serialization, X25519 session handshake, ChaCha20-Poly1305 packets, per-remote rate limits, Actor loading.

## Toolchain found

Git 2.54, Node 22.16, Python 3.13, Chocolatey, winget, PowerShell 5.1. **Not found:** Rojo, Selene, StyLua, Luau CLI, Lune,
Rokit, Wally, Cargo. Studio MCP: one studio (`Genesis`, placeId 121145903454904, Studio 0.741.19.7411056), Edit mode, empty place
with default baseplate, `HttpService.HttpEnabled = true`, no scripts.

## Gaps against the documentation

| Requirement | State at start |
|---|---|
| Source tree, tests, tools, ADRs | absent |
| Pinned toolchain and commands | absent |
| Deterministic seed/RNG and golden tests | absent |
| Contracts, persistence harness, lifecycle | absent |
| Horus adapter and compatibility plan | absent |
| Studio verification path | available (MCP), unused |

Follow-up state is tracked in `docs/tasks/2026-10-04-phase0-foundation.md`.
