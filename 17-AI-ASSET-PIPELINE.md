# AI Asset Pipeline

## Scope and rule

All production visual/audio assets are created by the user’s AI models, Roblox Studio/native tools, or code in this project. Do not source production models, textures, images, UI kits, music, or sounds from external libraries or creator marketplaces. Roblox engine primitives and built-in materials are allowed. Generated assets must be owned/uploaded by the experience owner or authorized group.

## Asset classes

- Roblox-native procedural assemblies: Parts, beams, particles, trails, UI, terrain/material configurations.
- AI-generated project meshes and LOD variants.
- AI-generated textures, masks, icons, sky layers, UI illustrations.
- AI-generated audio stems and effects.
- Runtime EditableMesh/EditableImage outputs when eligible and budgeted.
- Code-generated data: gradients, curves, palettes, density maps, naming tables.

## Manifest

Every asset has a stable ID and record:

```json
{
  "assetKey": "star/corona/v1",
  "kind": "texture",
  "generator": "model/tool and version",
  "promptHash": "...",
  "seed": "...",
  "createdAt": "ISO-8601",
  "sourceFiles": ["generated/source/..."],
  "transformations": ["crop", "channel-pack", "compression"],
  "licenseOwner": "experience owner/group",
  "robloxAssetId": null,
  "budgets": {"dimensions": "1024x1024"},
  "review": {"provenance": "pass", "visual": "pending", "performance": "pending"}
}
```

Store full prompts where appropriate or a hash plus protected prompt record if it contains private material. Never include secrets.

## Production flow

1. Brief defines function, visual language, scale views, palette, technical budget, and prohibited references.
2. Generate several seeded candidates using only authorized inputs.
3. Automated provenance/safety inspection rejects logos, recognizable third-party IP, signatures, unsafe text, hidden content, or suspicious metadata.
4. Select and normalize scale, pivots, UVs, naming, channels, loudness, and format.
5. Generate LODs/fallbacks and collision proxies; minimize material slots.
6. Import under owner/group and record resulting ID/permissions.
7. Validate in Studio with actual lighting, scale, streaming, and target tier.
8. Profile memory, render, Instances, and audio concurrency.
9. Approve manifest; unused/rejected candidates stay outside release packaging.

## Roblox Studio MCP validation and asset skills

Use the `Roblox_Studio` MCP server to validate generated assets inside the intended Studio place: inspect ownership and references, place candidates in controlled test scenes, exercise lighting/streaming/LOD fallbacks, and gather runtime scene, frame-time, and memory evidence. Confirm the connected MCP server's current tool and built-in-skill inventory before use; [roblox_skills_guide.md](./roblox_skills_guide.md) describes candidates such as `rbx-scene-analysis`, `rbx-perf-profiling`, and `rbx-luau-heap-profiling`, but an agent must not infer that they are present or that the server can upload a given asset type. Imports and uploads still require the manifest, correct owner/group, moderation readiness, and the project's approval gates.

Create a workspace skill only for a stable, repeated asset workflow—for example, `universe-asset-intake` to validate manifests, pivots, budgets, LODs, fallbacks, and Studio evidence, or `universe-cosmic-ui-review` for the fixed resolution/accessibility capture set. Follow the custom-skill structure and reserved-name rules in the guide, reference project scripts instead of duplicating long commands, and keep model prompts, credentials, and unreleased asset IDs out of skill files unless explicitly safe to commit.

## Mesh requirements

Correct normals/winding, clean UVs, bounded triangle/vertex count by use, pivot/origin standard, no unnecessary bones, minimal transparent overlap, simple/no collision unless required, LOD variants, and a primitive/static fallback. Hero assets receive close-up and silhouette review; repeated assets prioritize instancing/reuse.

## Texture/image requirements

Power-appropriate dimensions, transparent edges checked, channels documented, no baked copyrighted imagery/text, compression reviewed, grayscale/readability fallback, and atlasing where it reduces overhead without harming streaming. Procedural scientific surfaces remain stylistically coherent, not false promises of exact simulation.

## UI requirements

Prefer code-native Frames, gradients, strokes, text, and icons built from authorized generated sources. Components include normal/hover/pressed/focus/disabled/loading/error states. Validate at 1080p, ultrawide, UI scales, reduced motion, and color-accessibility palettes.

## Audio requirements

No sampled external recordings unless created/owned within this project. Check clipping, loudness, loops, phase, spectral fatigue, and simultaneous voice count. Keep original stems and generation metadata; create short/compressed runtime variants. Gameplay cues remain distinguishable without music.

## Runtime generation

Runtime outputs are deterministic from cosmetic seed, constrained by memory and time, and never required for gameplay correctness. Editable APIs are feature-flagged and fall back cleanly when unavailable. Do not accept player-supplied arbitrary asset IDs or prompts in the launch scope.
