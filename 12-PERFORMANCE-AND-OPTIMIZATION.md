# Performance and Optimization

## Performance philosophy

The experience sells impossible scale through representation, not brute force. Optimize measured bottlenecks after correctness, while designing every system with bounded work from the beginning.

## Initial budgets

Final budgets must be calibrated on named reference PCs in Phase 0. Starting gates:

- target 60 FPS presentation; provide a stable 30 FPS fallback tier;
- avoid sustained client script or render spikes above frame budget;
- authoritative server steps use explicit millisecond budgets and defer excess work;
- bounded active Instances per representation tier; no count grows with total universe size;
- no per-frame network messages; ordinary network traffic stays event-driven/coarsely sampled;
- save size and write cadence tracked continuously;
- generation jobs sliced/cancelled so scale changes remain responsive.

Every budget report includes hardware, graphics setting, player count, build ID, scene/seed, duration, and percentile—not only averages.

## Representation optimization

- Calculate analytic orbits rather than simulate physics.
- Render only representative samples and important pinned objects.
- Pool stars, body icons, beams, labels, particles, selection rings, and ViewportFrames.
- Batch visual state changes and reuse materials/textures.
- Disable shadows/collisions/touch/query on objects that do not need them.
- Use screen-size LOD, hysteresis, and crossfade.
- Cull labels aggressively and cluster map markers.
- Generate effects locally from semantic cues.
- Reserve expensive post-processing for high tiers and cinematic moments.

## StreamingEnabled

Enable it for Observatory/interior/near-field geometry after streaming-aware tests. Scripts must tolerate Instances not being present, use stable logical IDs, and avoid `WaitForChild` without timeouts on streamed content. Persistent streaming should be rare. Adjust min/target radii against actual memory and pop-in behavior. Cosmic map layers remain custom-rendered and budgeted.

## Parallel Luau and Actors

Good candidates: independent procedural chunks, scoring batches, density samples, spatial queries over immutable snapshots, and offline summary partitions. Poor candidates: tiny tasks, frequent shared mutation, DataStore operations, UI, or logic requiring repeated synchronization.

Pre-require modules serially, respect API thread-safety, compute plain results in parallel, synchronize once to commit. Measure worker count and granularity. Horus `Parallel` modules are reviewed under the same rules; loading beneath Actors alone is not evidence of parallel speedup.

## Scheduling

Maintain priority queues: interaction/focus, near visual, navigation context, background prefetch, and archival. Each heartbeat consumes a bounded budget. Jobs carry cancellation tokens and expected revisions. Work for abandoned camera targets is dropped. Strategic simulation is event-driven and processes due events in capped batches.

## Memory

Track Instances, Lua heap, textures/meshes, editable assets, cached generated data, UI screens, and audio. Caches use size/count limits and LRU/importance eviction. Destroy/disconnect pooled objects correctly. Weak tables are not a substitute for lifecycle ownership. EditableMesh/Image pools have hard device-tier caps and static fallbacks.

## Profiling workflow

1. Reproduce with a fixed seed and scripted camera path.
2. Capture baseline MicroProfiler/Script Performance/memory/network statistics.
3. Label suspected code and identify the limiting subsystem.
4. Make one focused change.
5. Repeat identical workload and compare percentiles plus visual correctness.
6. Retain artifact and decision; revert regressions.

Profile single player, target server occupancy, rapid zoom, dense galaxy, join burst, visitor arrival, generation cancellation, offline catch-up, save storm, and low graphics tier.

## Roblox Studio MCP profiling

At the start of a profiling run, discover the connected `Roblox_Studio` MCP session and `studio_id` and enumerate the available tools/skills; names in [roblox_skills_guide.md](./roblox_skills_guide.md) must be verified, not assumed. Prefer `rbx-perf-profiling` for scripted MicroProfiler captures, `rbx-scene-analysis` for triangle/draw-call/Instance and scene-health evidence, and `rbx-luau-heap-profiling` for before/after retention analysis when those skills are exposed. Use available Studio playtest/Luau tools to replay the fixed seed, camera path, player count, device tier, and duration. Save raw captures plus build ID and scenario metadata; an unavailable profiler produces an explicit incomplete result, never a guessed pass.

Create a workspace custom skill such as `universe-performance-baseline` only after the scenario runner, capture format, comparison thresholds, and degradation checks are stable. Put large baseline tables in `references/` and deterministic capture/comparison helpers in `scripts/`, store the skill under `.agents/skills/` (or the supported `.agent/skills/` path), and never use the reserved `rbx-` prefix. Invoke `rbx-create-skill` only after MCP discovery confirms it exists. A baseline or threshold change requires an ADR and a clean replay; the skill must report visual/correctness regressions alongside timing improvements.

## Degradation ladder

Under pressure: reduce particle density → lower representative samples → slow far-state cadence → disable editable hero variants → simplify atmospheres/post effects → reduce label density → defer background generation. Never degrade command validation, save safety, or authoritative simulation correctness.

## Anti-patterns

Unbounded `GetDescendants()` in runtime loops, per-object Heartbeat connections, clone/destroy churn, giant replicated tables, recursive deep copies, frequent DataStore calls, polling when events suffice, client-server transform streaming for deterministic objects, thousands of physics assemblies, and assuming `--!native` automatically improves every module.
