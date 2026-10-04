# Procedural Generation

## Goals

Generation must be deterministic, hierarchical, explorable at arbitrary scale, cheap to reproduce, stable across traversal order, versioned across releases, and visually varied without saving derived bulk data.

## Canonical seed tree

Store a 64-bit-equivalent seed representation supported safely by Luau implementation (for example two 32-bit lanes or a canonical string), never relying on imprecise large integer arithmetic. Derive children by a stable project hash:

```text
rootSeed
└─ epoch:<id>
   └─ cluster:<id>
      └─ galaxy:<id>
         └─ sector:<morton-or-grid-id>
            └─ system:<id>
               └─ body:<id>
```

`childSeed = Hash(generatorFamilyVersion, parentSeed, namespace, stableId)`.

Use named streams (`morphology`, `positions`, `composition`, `anomalies`, `names`, `visual`) so adding a cosmetic draw does not alter physics. Never derive results from iteration order, dictionary order, current time, frame count, or client locale.

## Generator versioning

Every materialized address records the generator family/version that created its canonical important state. A new generator does not silently rewrite old universes. Policies:

- cosmetic-only version may regenerate visuals if identity remains stable;
- balance version uses migration/compatibility mapping;
- topology version applies only to new epochs unless an explicit opt-in migration exists;
- discoveries reference stable addresses and archived metadata.

Golden fixtures record inputs and normalized outputs for critical versions.

## Hierarchical generation

### Star/system

Sample scientifically inspired distributions constrained for playability. Generate star parameters, then disk mass/composition, stable orbit candidates, bodies, moons, rings, anomalies, and visual traits. Validate energy/orbit constraints after sampling; deterministic repair resolves invalid configurations.

### Galaxy

Store morphology, scale, arm count/pitch, bar/core/halo parameters, metallicity gradient, gas/dust fields, black-hole state, and population summaries. A density function plus seeded stratified sampling yields representative stars. Important player systems are pinned samples; nearby details materialize by sector.

### Cluster/cosmic web

Use graph nodes/edges and density fields, not physical bodies. Generate cluster masses, satellite relationships, filament splines, voids, lensing/lighting cues, and representative galaxy impostors. Strategic simulation updates aggregates and selected events.

## Coordinates and floating origin

Never express real astronomical distances directly as Workspace studs. Maintain canonical coordinates in scale-domain structures and render a local camera-relative projection.

- Each scale has logical units and an origin anchor address.
- Convert selected/nearby canonical coordinates into bounded local studs.
- Rebase when the observer exceeds a threshold (for example 2,000–8,000 studs, tuned by tests).
- Move a client-local render root and camera-relative effects, not authoritative identity.
- Physics-enabled local interiors/vessels use a separate bounded zone.
- Transitions blend two representations around a hysteresis band to avoid popping.

Server gameplay uses logical positions/addresses. Client-reported Workspace positions never determine ownership or cosmic distance without server reconstruction.

## LOD and impostors

| Apparent scale | Representation |
|---|---|
| local/interior | Parts/project meshes, limited physics, detailed effects |
| body | sphere/project mesh, atmosphere shells, surface patches |
| system | icon/sprite/beam or low-poly body, analytic orbit lines |
| sector | batched representative points and density volumes |
| galaxy | layered impostor, particles/beams, sparse hero clusters |
| cluster | galaxy sprites/impostors and graph overlays |
| cosmic web | luminous nodes/filaments, density texture/mesh |

LOD selection uses projected screen size, importance, focus, motion, device tier, and budget—not distance alone. Use enter/exit hysteresis, crossfades, stable dithering, and object pools. The focus target and Home Star receive a detail reserve.

## Work scheduling and Parallel Luau

Generation jobs are small immutable requests with deadline, priority, address, version, and cancellation token. Actor workers compute pure numeric/table/buffer outputs in parallel. The serial coordinator validates the result is still wanted, checks version/address, and commits bounded Instances. Jobs yield across frames and are cancelled on scale/travel changes.

Do not call unsafe DataModel APIs in parallel. Do not assume one Actor improves throughput; distribute independent chunks across a measured worker pool.

## Editable assets

Use EditableMesh for a small number of near-field asteroids, surface patches, or hero structures if enabled and within memory. Prefer fixed-size topology. Use EditableImage for low-frequency procedural masks/maps/thumbnails, updating a bounded number. Fall back to project-owned static meshes, Parts, particles, and UI images.

## Roblox Studio MCP workflow

Before an agent performs generation work in Studio, it discovers the active `Roblox_Studio` MCP session and its `studio_id`, then inventories the exposed tools and skills. Entries in [roblox_skills_guide.md](./roblox_skills_guide.md) are candidates, not proof of availability. When present, use `rbx-docs-search` before adopting unfamiliar APIs; use the server's exposed Luau execution/playtest tools to replay golden seeds, compare normalized hashes, exercise cancellation/rebasing, and inspect materialized Instance counts; and use the available performance, scene-analysis, or heap-profiling skills on worst-case seeds. MCP-generated observations must be saved with build ID, seed, generator version, worker count, and device/test context so results are reproducible.

Create a project custom skill such as `universe-generation-audit` only when the golden-seed replay and evidence-capture sequence has stabilized and is recurring. Its `SKILL.md` should define trigger conditions and pass/fail outputs; reusable seed corpora and expected schemas belong in `references/`, while deterministic replay/check scripts belong in `scripts/`. Keep it workspace-scoped under `.agents/skills/` (or the supported `.agent/skills/` path), never use the reserved `rbx-` prefix, and invoke `rbx-create-skill` only after confirming that skill exists on the connected MCP server. Review and fixture-test every skill change like production code.

## Validation and tests

- same input/version → byte-equivalent normalized output;
- generation order and worker count do not alter output;
- all numbers finite and within declared ranges;
- stable IDs have no collision in stress corpus;
- constraints repair deterministically;
- materialization and eviction leave the same durable state;
- camera rebasing preserves apparent position/selection;
- worst-case chunk time, memory, and Instance count stay under budget.
