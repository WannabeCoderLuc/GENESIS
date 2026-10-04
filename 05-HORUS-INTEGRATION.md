# Horus-main Integration

## Observed upstream capabilities

Inspected path: `C:\Users\Luc\Desktop\DEV\Horus-main`.

The current repository describes Horus as an all-in-one Roblox framework. Its source includes:

- server/client module loading with `Init`/`Start` lifecycles;
- CollectionService discovery (`Horus_Load`) and module attributes including `LoaderPriority`, `Parallel`, `ClientOnly`, `IgnoreLoader`, and relocation behavior;
- Actor-backed parallel module loading;
- schema encoding and serialization through Sera;
- RemoteEvent and request/response wrappers;
- per-player session setup using X25519-derived material and authenticated encryption;
- monotonic receive sequence rejection;
- basic per-remote per-player limits (observed defaults: events 60/s, function-like requests 20/s);
- readiness/session helpers.

The upstream README warns that the project was a portfolio framework and was not originally intended for other games. Treat integration as a reviewed fork/vendor dependency, not a turnkey guarantee.

## Non-modification policy

Do not modify `Horus-main` in place. Choose one reproducible approach:

1. preferred: pin a Git commit/submodule under `vendor/Horus`;
2. acceptable: copy the required source into `vendor/Horus` with `UPSTREAM.md` recording source path, commit/hash, date, license, and local patches;
3. temporary prototype: filesystem mapping to upstream, never for CI/release.

Any required change is first implemented as a project adapter. Upstream modification requires explicit user approval, a dedicated fork/branch, tests, and a patch ledger.

## Adapter boundary

Create `Server/Infrastructure/Networking/HorusTransport.luau` and a matching client adapter. Game code depends on project interfaces:

```luau
export type EventEndpoint<T> = {
    sendTo: (self: EventEndpoint<T>, player: Player, payload: T) -> (),
    onRequest: (self: EventEndpoint<T>, handler: (Player, T) -> ()) -> Connection,
}
```

The adapter maps central contract schemas to Horus. Feature modules never call raw Horus remotes or know cryptographic/session details. This permits replacement, testing, instrumentation, and per-command limits.

## Required compatibility spike

Before adoption, produce a minimal published staging place and verify:

- server and two clients complete startup/session handshakes;
- malformed types, invalid buffers, repeated/out-of-order sequences, and authentication failures are rejected without server failure;
- reconnect, rapid leave, timeout, and session cleanup work;
- event and request/response schemas round-trip all planned primitive/container types;
- payload-size boundaries fail safely;
- Actor modules initialize and report errors without deadlock;
- Studio and published clients behave consistently;
- loader discovers only intended modules and ordering is deterministic enough for project rules;
- bandwidth and CPU costs are measured at expected command rates.

Record the pinned commit and results in `vendor/Horus/COMPATIBILITY.md`.

## Security position

Horus packet encryption/authentication can deter casual packet inspection and provides integrity/replay checks within its session model. It does **not** make a compromised client trustworthy: exploiters can call client code before encryption with fabricated values. Every command still passes project validation, authorization, rate, state, and economy checks.

Additional controls required outside Horus:

- command-specific token buckets and global abuse budgets;
- maximum serialized payload size before expensive processing where possible;
- finite-number and domain-bound checks after deserialization;
- capability/role verification;
- command ID idempotency and state-machine validation;
- suspicious-action scoring and structured audit logs;
- server-owned outcome computation;
- safe disconnect cleanup and load shedding.

Review the handshake for resource-exhaustion paths, key lifecycle, nonce/sequence rollover, reconnect semantics, pending-key cleanup, and behavior after sequence gaps. Cryptography must never be custom-modified casually.

## Performance position

Encrypted serialization costs CPU and allocations. Benchmark realistic payload distributions, not empty packets. Use compact event-specific schemas and low-frequency authoritative deltas. Do not stream visual particles, orbital transforms, or whole universe trees through remotes. Clients derive visuals from seeds and occasional state corrections.

Use Horus `Parallel` loading only for modules whose runtime work is explicitly parallel-safe. A module being loaded under an Actor does not automatically make arbitrary DataModel writes safe or improve performance.

## Studio MCP-assisted audit

When available, use a verified `Roblox_Studio` MCP server session to exercise Horus in the actual place: inspect bootstrap state, run server/client reconnect and malformed-command cases, observe remotes and Actors, attach runtime debugging, and capture performance/heap evidence. Confirm the target `studio_id`, place/build, tool inventory, and requested built-in skills before the audit. `rbx-debug`, `rbx-perf-profiling`, and `rbx-luau-heap-profiling` are useful capabilities described in `roblox_skills_guide.md`, but their presence must be discovered; an unavailable capability leaves that audit item pending rather than implicitly passed.

After the Horus review procedure stabilizes, package its orchestration as a project skill such as `universe-horus-audit` under `.agents/skills/`, following `roblox_skills_guide.md` and avoiding the reserved `rbx-` prefix. The skill may call pinned tests and collect evidence, but it must not modify `Horus-main`, weaken findings, expose secrets, or replace an independent review. Keep vendor changes separately authorized and reviewable.

## Workflow invocation

“Run Horus review” means:

1. diff all changes touching transport contracts, Sera schemas, sessions, remotes, loaders, Actors, or vendor files;
2. run the compatibility suite and remote fuzz corpus;
3. run a multi-client startup/reconnect test;
4. capture packet rate/bytes, handler time, rejection counts, and memory;
5. inspect every handler for server authority and command-specific validation;
6. compare vendor hash with the approved pin and list any patch;
7. produce `artifacts/audits/horus-YYYYMMDD-<build>.md` with pass/fail evidence.

Run it at bootstrap, every Horus/vendor update, every schema or remote change, every security milestone, and before each release candidate.

## Adoption decision gate

Adopt only if the spike demonstrates stable startup, bounded overhead, schema coverage, clean failure behavior, maintainable licensing/provenance, and no unresolved critical finding. Otherwise retain Horus as a reference and implement the project transport interface with Roblox remotes directly. The rest of the architecture must remain unchanged either way.
