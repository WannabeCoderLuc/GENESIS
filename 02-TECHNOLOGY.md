# Technology Specification

## Platform baseline

- Roblox Studio and Luau, PC input only.
- Experience uses multiple places when scale or isolation warrants it, while all places share the same universe-level data stores.
- `StreamingEnabled` for navigable 3D places; generation and rendering remain explicitly budgeted because streaming is not a substitute for LOD.
- Future Lighting/modern lighting features selected after target-hardware profiling; visual settings degrade by tier.
- Source-controlled filesystem workflow with a deterministic Studio synchronization method where available. Pin every tool and library version.

Roblox APIs evolve. Before implementing a milestone, the assigned agent must confirm current Creator Hub behavior for APIs marked beta, gated, deprecated, or permission-dependent.

## Luau/runtime choices

- Strict typed Luau and small ModuleScripts with dependency injection.
- `buffer` for compact deterministic serialization where it proves valuable.
- `Random.new(seed)` only behind project RNG abstractions; never global randomness in canonical generation.
- `Actor`, `task.desynchronize()`, `task.synchronize()`, `Actor:SendMessage()`, and parallel-safe APIs for pure generation/scoring workloads.
- `SharedTable` only after measurement demonstrates that copying is material and ownership is clearly documented.
- `debug.profilebegin/end`, MicroProfiler labels, Script Performance, Developer Console, Stats, and controlled telemetry for profiling.
- Attributes and CollectionService tags for lightweight authored metadata, never as the sole durable source of truth.

## Roblox services

| Service/API | Use |
|---|---|
| DataStoreService | durable player profiles, universe manifests, versioned journals |
| OrderedDataStore | durable numeric leaderboard projections only |
| MemoryStoreService | visit routing, server registry, locks/leases, challenge queues, ephemeral rankings |
| MessagingService | low-volume invalidation and cross-server announcements; never durable truth |
| TeleportService | Observatory, universe instances, challenges, Void, retry-aware party travel |
| MemoryStoreQueue/SortedMap/HashMap | matchmaking, time-bounded registry and distributed coordination |
| AssetService EditableMesh/EditableImage | optional runtime/project-owned procedural visual layers after gates |
| RunService | fixed-step simulation scheduling and client render orchestration |
| CollectionService | discovery of tagged components and tooling metadata |
| ContentProvider | bounded preload of critical first-session assets |
| ContextActionService/UserInputService | PC controls and rebinding |
| TextService/TextChatService | safe user-entered names and social surfaces where applicable |
| MarketplaceService | receipt-validated minor purchases |
| PolicyService | regional/player policy compliance where required |
| AnalyticsService | funnel, performance, economy, and error telemetry without sensitive payloads |

## EditableMesh and EditableImage policy

These are enhancement paths, not foundation dependencies. Published experiences require eligible ownership/verification and the mesh/image API toggle; editable assets have strict client memory constraints, and displayed EditableImages update under engine limits. Therefore:

- Provide a Parts/MeshPart/Beam/Particle/UI fallback for every use.
- Prefer fixed-size EditableMeshes and multi-reference one mesh where possible.
- Generate or mutate only near-field hero objects, bounded by a memory pool.
- Never create one editable asset per distant celestial object.
- EditableImage is suitable for low-frequency procedural maps, masks, and thumbnails—not per-frame full-screen rendering.
- Feature flag all use and test on published staging.

## Rendering toolkit

Roblox-native primitives, project-owned meshes, SurfaceAppearance, MaterialService, ParticleEmitter, Beam, Trail, Highlight, Atmosphere, Bloom, ColorCorrection, DepthOfField used sparingly, sky layers, UI gradients, ViewportFrames, and client-generated impostors. Use camera-space math and logarithmic scale transitions rather than physically co-locating astronomical distances.

## Audio toolkit

Project-owned AI-generated sound stems imported through Roblox asset ownership, plus runtime layering through Sound objects and audio effects. Space remains physically silent unless sound is clearly presented as observer telemetry, interface sonification, or cinematic interpretation.

## Tooling gates

Recommended local gates: formatter, Selene configured for Roblox, Luau analysis/type checks supported by the chosen toolchain, unit/spec runner, project build validation, asset-manifest validation, schema compatibility tests, deterministic golden tests, and Studio multi-client smoke tests. Agents must not invent a command that does not exist; document and pin the actual command when bootstrapping.

## Roblox Studio MCP and custom skills

Treat the `Roblox_Studio` MCP server as the automation bridge to a live Studio session, not as a production dependency. Use it for DataModel inspection and bounded edits, Luau execution, play-mode and multi-client checks where supported, debugger capture, scene/heap/performance profiling, and final in-engine verification. At the beginning of each Studio-dependent work packet, enumerate the exposed MCP tools, confirm the correct `studio_id` and place/build, and request only skills the server actually exposes. The built-in capabilities described in `roblox_skills_guide.md`—including `rbx-docs-search`, `rbx-debug`, `rbx-perf-profiling`, `rbx-scene-analysis`, and `rbx-luau-heap-profiling`—must not be reported as run unless the server returned evidence.

Promote a workflow to `.agents/skills/<skill-name>/SKILL.md` only when it is project-specific, repeated, and benefits from a fixed checklist or helper scripts. Good candidates are deterministic seed regression, three-tier cosmic render profiling, Studio smoke-test setup, and publish preflight. Follow `roblox_skills_guide.md`, use an explicit trigger description, move large material to `references/`, reuse checked-in scripts, and never assign a custom skill the reserved `rbx-` prefix. If `rbx-create-skill` or an equivalent creation tool is absent, create/review the files through the normal repository workflow and mark tool-specific validation pending.

## Horus role

Horus-main currently supplies lifecycle loading, client/server bootstrap state, schema serialization, session establishment, encrypted/authenticated packets, per-remote basic rate limits, and Actor-backed module loading. It is a dependency candidate, not an unquestioned security boundary. Adopt via the adapter described in `05-HORUS-INTEGRATION.md` after compatibility tests.
