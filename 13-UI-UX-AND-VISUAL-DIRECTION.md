# UI, UX, and Visual Direction

## Target feeling

SpaceEngine-like serenity and scale meet EVE-like precision, industry, and tactical information—without copying either product’s protected assets or interface. The result is dark, restrained, luminous, and legible: the universe is the hero, while UI behaves like an observatory instrument.

## Visual grammar

- Near-black blue-violet space, subtle gradients, restrained bloom.
- Stars use physically inspired color families with artistic exposure control.
- Warm amber for creation/energy, cyan for navigation/science, violet for exotic phenomena, green only for safe/valid states, red reserved for consequential danger.
- Fine lines, quiet grids, sparse typography, generous negative space.
- Scale transitions use parallax collapse, label aggregation, exposure shift, and audio filtering.
- Never fill the screen with shop buttons, reward confetti, or floating currencies.

## PC controls

| Input | Default |
|---|---|
| WASD | translate/pan |
| Mouse | look/orbit/select |
| Q/E | roll where vessel mode applies |
| Shift/Ctrl | accelerate/decelerate or scale speed |
| Mouse wheel | contextual zoom/scale transition |
| F | focus selection |
| Tab | tactical/management overlay |
| M | cosmic map |
| Space | pause/inspect strategic simulation where allowed |
| Esc | back/settings |

Support rebinding, invert axes, sensitivity, hold/toggle choices, UI scale, reduced motion, photosensitivity-safe effects, color-independent state indicators, subtitles/captions, and screen-shake reduction.

## Navigation model

Selection always exposes name/address, scale, status, next useful action, and breadcrumbs back to Home Star. A scale ruler communicates representation changes. Focus transitions can be interrupted. “Return Home” is persistent and safe. Use a two-stage input for destructive/expensive actions: preview consequences, then commit.

## Information layers

1. **Cinematic:** almost no UI; observation/photo mode.
2. **Context:** selection card, objectives, alerts, scale.
3. **Tactical:** orbits, routes, hazards, resource flows.
4. **Management:** tables, automation policies, comparisons.
5. **Cosmic map:** hierarchy, search, bookmarks, visits.

The user toggles layers; the game never displays all at once. Tooltips state consequence in plain language first, scientific detail second.

## First-session flow

Open in darkness with one disturbance and three prompts: Condense matter. Ignite fusion. Create your first star. Each input visibly changes the cloud. Ignition temporarily suppresses UI, then reveals a calm star status panel. The camera pullback establishes scale and exposes one next goal. No store prompt appears during this emotional sequence.

## UI states

Every screen handles loading, empty, partial, unavailable/offline, retry, success, validation error, permission denial, and stale revision. Long cloud operations show cancellable progress or clear background status. Errors use a support correlation code without exposing secrets.

## Celestial rendering

- Star: layered emissive sphere/project mesh, noise-driven surface motion, corona beams/particles, lens effects kept subtle.
- Planet: project-owned base geometry, layered material/atmosphere/cloud cues; nearby terrain is selective, not full planets at real scale.
- Galaxy: density layers, dust masks, representative stars, core glow, arm structure, low-cost impostor at distance.
- Cosmic web: spline/beam filaments, fog/density fields, nodes, restrained labels.

All systems have low-tier fallbacks. AI-generated art must be adapted into project-owned Roblox assets and recorded in the manifest.

## Audio

Use deep, slow, non-fatiguing ambience; UI sonification with strong hierarchy; formation events built from layered project-owned AI-generated stems; adaptive intensity from scale and event state. Avoid constant sub-bass, overcompression, or noisy reward sounds. Provide independent master/music/effects/UI sliders and captions for gameplay-significant audio.

## Younger and older audiences

The surface layer uses direct verbs, visible cause/effect, collections, and short goals. Depth comes from tradeoffs, optimization, statistics, history, and automation. Do not infantilize copy or require astrophysics knowledge. Optional “Explain” panels teach why without blocking play.

## Visual QA shots

Maintain fixed seeds/cameras for: first void, ignition, first planet, habitable world, tactical system, Observatory window, spiral galaxy, merger, cluster, cosmic web, low-tier mode, accessibility palette, and four aspect/UI scales. Compare captures per release for clipping, overexposure, pop, label collisions, and hierarchy.

## Roblox Studio MCP visual workflow

Before an automated UI/visual pass, discover the active `Roblox_Studio` MCP session, record its `studio_id`, and enumerate the server's current tools and skills; [roblox_skills_guide.md](./roblox_skills_guide.md) describes possible capabilities but does not prove they are installed. Use `rbx-docs-search` when available before relying on unfamiliar UI, lighting, camera, EditableImage, or accessibility APIs. Use exposed Studio inspection/playtest/Luau tools to load the fixed seed/camera matrix, exercise every UI state and input scale, and collect reproducible observations; use scene/performance skills when available to ensure beauty passes do not violate frame, memory, draw-call, or Instance budgets. Automated checks supplement, rather than replace, human review of legibility, motion comfort, hierarchy, and emotional timing.

Create a workspace custom skill such as `universe-visual-regression` only when the capture matrix, naming scheme, tolerances, and accessibility checklist are stable and recurring. Keep baseline metadata/checklists in `references/` and repeatable scene setup or comparison helpers in `scripts/`; store it under `.agents/skills/` (or the supported `.agent/skills/` path), avoid the reserved `rbx-` prefix, and use `rbx-create-skill` only if the active MCP inventory confirms it. Require deterministic seed/camera/build metadata and route changed images for review instead of allowing the skill to auto-approve aesthetic differences.
