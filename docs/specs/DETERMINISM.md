# Determinism Specification (v1)

Normative definition of the deterministic primitives. Code, tests and the independent reference
(`tools/reference/uc-reference.mjs`) all implement THIS document. If they disagree, stop and reconcile (see
`README.md` "Source-of-truth rule").

All integers below are unsigned and arithmetic is modulo the stated width. `u32` = 32 bits, `u64` = 64 bits.
Strings are byte strings. Text that feeds a hash must already satisfy the grammar of its field.

## Algorithm identifiers

| Id | Where | Purpose |
|---|---|---|
| `UC-HASH64-V1` | `Domain/Hash64.luau` | non-cryptographic 64-bit hash |
| `UC-SEED-V1` | `Domain/Seed.luau` | hierarchical seed derivation |
| `UC-RNG-V1` | `Domain/Rng.luau`, `RngStreams.luau` | xoshiro128\*\* generator and named streams |
| `UC-CANON-V1` | `Domain/CanonicalEncode.luau` | canonical byte encoding, checksums, wire body |

Changing the observable output of any identifier is a **generator-version event** for canonical data: bump the
algorithm id (`-V2`), keep `-V1` readable for existing universes, and regenerate golden vectors with an explanation
(`18-CODING-STANDARDS.md`).

## UC-HASH64-V1

```
FNV_OFFSET = 0xCBF29CE484222325        FNV_PRIME = 0x100000001B3
absorbByte(h, b)  = ((h xor b) * FNV_PRIME) mod 2^64            -- FNV-1a
absorbU32(h, v)   = absorbByte x4 over v's bytes, little endian
absorbField(h, s) = absorbU32(h, len(s)) then absorbByte over s  -- length-prefixed, unambiguous
fmix64(k):  k ^= k >> 33; k *= 0xFF51AFD7ED558CCD; k ^= k >> 33; k *= 0xC4CEB9FE1A85EC53; k ^= k >> 33
hashString(s) = fmix64(absorb every byte of s into FNV_OFFSET)
```

Anchors: FNV-1a 64 of `""`, `"a"`, `"foobar"` = `cbf29ce484222325`, `af63dc4c8601ec8c`, `85944171f73967e8`
(published vectors, asserted in `tools/tests/reference.test.mjs`). `fmix64(1) = b456bcfc34c2cb2c`.

Not a security boundary: never use it to authenticate or to hide values from the client.

## UC-SEED-V1

A `Seed` is an immutable 64-bit value, held as `(hi, lo)` uint32 lanes and persisted as **exactly 16 lowercase hex
digits** (`hi` first).

```
derive(parent, namespace, stableId, generatorVersion) =
  h = FNV_OFFSET
  h = absorb bytes "UCSEEDV1"
  h = absorbU32(h, generatorVersion)
  h = absorbU32(h, parent.hi); h = absorbU32(h, parent.lo)
  h = absorbField(h, namespace); h = absorbField(h, stableId)
  return fmix64(h)

fromText(purpose, text) = fmix64( absorbField(absorbField(absorb "UCROOTV1", purpose), text) )
```

Field grammars (enforced; violations are typed errors, never silently normalised):

- `namespace`: `[a-z][a-z0-9_.-]{0,31}`.
- `stableId`: 1-64 bytes of `[A-Za-z0-9_.-]` (ASCII only; `:` and `/` are excluded so canonical address text is
  unambiguous).
- `generatorVersion`: integer in `[1, 2147483647]`.

Only these inputs may influence a derived seed. Never time, frame count, traversal order, dictionary order, locale,
or client state. The seed tree is `root -> epoch -> cluster -> galaxy -> sector -> system -> body -> subobject`
(namespace = level name, stableId = that level's ID), walked by `Seed.deriveAlongPath`.

A new universe's **root seed** is the only legitimate entropy: it is chosen once by the server in infrastructure
code, persisted, and thereafter treated as data. `Domain` never creates entropy.

## UC-RNG-V1

xoshiro128\*\* (Blackman & Vigna) over four u32 words.

```
seed expansion:   (s1', o1) = splitmix64(seed); (_, o2) = splitmix64(s1')
                  s0 = o1.lo, s1 = o1.hi, s2 = o2.lo, s3 = o2.hi        (all-zero state -> s0 = 1)
splitmix64(x):    x += 0x9E3779B97F4A7C15; z = x
                  z = (z xor z>>30) * 0xBF58476D1CE4E5B9
                  z = (z xor z>>27) * 0x94D049BB133111EB; out = z xor z>>31
next32():         result = rotl(s1*5, 7) * 9
                  t = s1 << 9; s2 ^= s0; s3 ^= s1; s1 ^= s2; s0 ^= s3; s2 ^= t; s3 = rotl(s3, 11)
nextU53():        (next32() >> 5) * 2^26 + (next32() >> 6)
nextUnit():       nextU53() / 2^53                     in [0, 1), exact
nextInt(lo, hi):  inclusive; range = hi-lo+1; range==1 consumes no draw;
                  range <= 2^32: reject next32() >= 2^32 - (2^32 mod range), result lo + draw mod range
                  else same with nextU53 and 2^53;  requires hi - lo <= 2^53 - 1
shuffle(list):    for i = n down to 2: j = nextInt(1, i); swap(list[i], list[j])      (Fisher-Yates)
chancePermille(p): p==0 false, p==1000 true, else nextInt(0, 999) < p
```

### Named streams

`streamSeed(base, version, name) = derive(base, "stream", name, version)`. Registry (`RngStreams.REGISTRY`):

| Stream | Class |
|---|---|
| `morphology`, `positions`, `composition`, `anomalies` | canonical |
| `names`, `visual` | cosmetic |

Streams share no state. `set.canonical:get(n)` and `set.cosmetic:get(n)` each refuse the other class and unregistered
names. Presentation code is handed only `set.cosmetic`, so cosmetic draws cannot reach, and therefore cannot perturb,
canonical simulation. Saved designations are IDs, never RNG output.

## UC-CANON-V1

A single canonical byte encoding for plain data (used for checksums, the command wire body, determinism oracles).

```
value := 'T' | 'F'
       | 'i' <decimal> ';'              integer, |n| <= 2^53-1, no leading zeros, never "-0"
       | 'd' <16 lowercase hex>         IEEE-754 binary64, big endian; ONLY non-integers or |n| > 2^53-1
       | 's' <len> ':' <len bytes>
       | 'a' <count> ':' value*         keys exactly 1..count; the empty table is "a0:"
       | 'm' <count> ':' (key value)*   count >= 1; key := 's' <len> ':' bytes; keys strictly ascending by BYTE order
```

Rejected on encode: `nil`, NaN, +-inf, functions, userdata, Instances, tables with metatables, mixed/sparse tables,
non-string map keys. Rejected on decode: every non-canonical form (`m0:`, `i01;`, `i-0;`, integers written as `d`,
unsorted/duplicate keys, uppercase hex, trailing bytes) so `encode(decode(x)) == x` for all accepted `x`. Decoding is
bounded by `Limits {maxBytes, maxDepth, maxNodes, maxStringBytes, maxContainerEntries}` and never raises.

`checksum(value) = hex16(hashString(encode(value)))`.

## Verification matrix

| Property | Evidence |
|---|---|
| Luau uint64 lane math equals BigInt | `tests/Domain/Uint64.spec.luau` vs `UintVectorsV1` |
| Hash, SplitMix64 equal reference and published vectors | `Hash64.spec`, `tools/tests/reference.test.mjs` |
| Seed derivation equals reference; no collisions in 2000-sibling corpus | `Seed.spec` |
| Identical input -> identical output | `Seed.spec`, `Rng.spec`, `RngStreams.spec` |
| Iteration/insertion/access order cannot change results | `Seed.spec` (300 siblings x 3 orders), `CanonicalEncode.spec`, `RngStreams.spec` |
| Unrelated streams do not affect each other | `RngStreams.spec` |
| Finite and within declared bounds | `Rng.spec` (10,000 bounded draws across 40 seeds) |
| 10,000-draw digests match the reference | `Rng.spec` vs `RngVectorsV1` |
| Hostile bytes never raise; accepted input is canonical | `CanonicalEncode.spec` fuzz |

Regenerate vectors: `npm run gen:vectors`. Drift check: `npm run check:vectors`.
