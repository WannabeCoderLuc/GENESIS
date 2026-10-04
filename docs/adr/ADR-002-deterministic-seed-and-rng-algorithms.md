# ADR-002: Deterministic seed, hash and RNG algorithms

Status: Accepted, 2026-10-04

## Context

`08-PROCEDURAL-GENERATION.md` requires a 64-bit-equivalent seed, a stable child-seed hash
`Hash(generatorFamilyVersion, parentSeed, namespace, stableId)`, named streams, and independence from iteration order,
time, locale and client state. Luau numbers are doubles, so naive 64-bit integer math is imprecise above 2^53.

## Decision

- **Seed** = immutable `(hi, lo)` uint32 lanes; canonical persisted form = 16 lowercase hex digits.
- **Hash (UC-HASH64-V1)** = FNV-1a 64 byte absorption + MurmurHash3 `fmix64` finaliser. The FNV prime
  `2^40 + 435` makes absorption exact with two 32-bit lanes and a single small multiply. 64x64 multiplication in
  `fmix64` and SplitMix64 uses 16-bit limbs so every partial product stays below 2^53.
- **Derivation (UC-SEED-V1)** hashes domain tag, generator version, parent lanes and *length-prefixed* namespace and
  stable ID, so field boundaries cannot collide. Inputs are validated against explicit byte grammars.
- **Generator (UC-RNG-V1)** = xoshiro128** (pure 32-bit state, exact and fast in Luau), seeded through SplitMix64.
  Integer draws use rejection sampling (no modulo bias).
- **Streams**: one derived seed per registered stream name; canonical vs cosmetic accessors make cross-class access
  impossible by construction. Adding a stream is a registry edit.
- **Canonical encoding (UC-CANON-V1)**: one byte encoding per value, strict bounded decoder; used for checksums and
  the command wire body so Lua table iteration order cannot leak into any output.

## Alternatives considered

- PCG32/xoroshiro128+: need 64-bit multiplies per draw, slower in Luau.
- Seeds as Luau numbers: lose precision above 2^53 (rejected by the doc itself).
- `Random.new(seed)`: engine-defined sequence, no cross-version guarantee, not independently reproducible.
- Concatenating fields without length prefixes: ambiguous.
- SHA-256 from Horus: cryptographic strength is unnecessary here and would couple `Domain` to vendor code.

## Consequences

- Output is fixed by `docs/specs/DETERMINISM.md`; any change is a generator-version event with new vectors.
- Not cryptographic: seeds are not secrets; hiding values from clients is a server-authority concern, not a hash one.
- The only entropy in the system is the server's one-time choice of a new universe's root seed (infrastructure).

## Verification

Luau output equals the BigInt reference for all vectors (uint64 ops, hash, seeds, 10,000-draw RNG digests, canonical
encodings); published FNV/SplitMix64 vectors pass in Node; fuzz tests for the decoder; see spec verification matrix.
