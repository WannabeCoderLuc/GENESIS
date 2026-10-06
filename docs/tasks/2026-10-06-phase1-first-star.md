# Task: Phase 1 First Star playable vertical slice

Date: 2026-10-06. Status: **not started**. Owner instruction: build the First Star slice end-to-end. Spec sources: `06-IMPLEMENTATION-PLAN.md` (tasks 10-20), `07-PHASES-AND-MILESTONES.md` (Phase 1).

## Narrow deliverable

A complete playable 15-minute loop where a player can spawn, see a guided visual condensation of a star, trigger an authoritative ignition command, save/reconnect without state loss, and observe one anomaly event.

## Acceptance criteria

1. First-run "black space" opening and condensation visual sequence is functional.
2. Server handles `IgnitionCommand`, deterministically resolving the new star properties.
3. Player can leave and rejoin the session without losing their star's state.
4. Scale indicator, basic settings, and photo mode UI present.
5. Basic Observatory prototype allowing a second player to visit.

## Status

| # | Item | State |
|---|---|---|
| 10 | Define First Star commands, results, and validators | done |
| 11 | Implement pure stellar model and property tests | done |
| 12 | Implement authoritative First Star aggregate | done |
| 13 | Implement save coordinator with session lease and retry queue | next |
| 14 | Build input/camera/focus controllers | pending |
| 15 | Build procedural star visual with tier fallbacks | pending |
| 16 | Build minimal HUD/tutorial and accessibility settings | pending |
| 17 | Add ignition sequence, audio, and telemetry | pending |
| 18 | Add join/leave/reconnect and two-client tests | pending |
| 19 | Profile three graphics tiers and enforce budgets | pending |
| 20 | Stage a complete 15-minute first-session playthrough and repair defects | pending |

## Known risks

- UI and Rendering implementations may exceed frame budgets on lower-tier hardware.
- The procedural star visual requires careful usage of standard parts (or EditableMesh if toggled and safe) to remain performant.
- Multi-client routing logic via MemoryStore/Teleport needs rigorous testing for race conditions.

## Next task

Implement the save coordinator with session lease and retry queue. This service should coordinate with the persistence repository to guarantee safe authoritative saving of the Universe and First Star state, avoiding concurrent modifications.
