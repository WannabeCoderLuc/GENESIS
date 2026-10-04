// Generates the golden determinism vectors consumed by the Luau test-suite.
//
//   node tools/gen-golden-vectors.mjs           write generated/source/GoldenVectors/*.luau + the manifest
//   node tools/gen-golden-vectors.mjs --check   fail (exit 1) if the files on disk differ from a fresh generation
//
// All expected values come from tools/reference/uc-reference.mjs (BigInt reference), never from the Luau code under
// test. Golden changes require an explanation in the commit/ADR (18-CODING-STANDARDS.md): a diff here means the
// determinism spec or the reference changed, which is a generator-version event for canonical output.

import { createHash } from "node:crypto";
import { mkdirSync, readFileSync, writeFileSync, existsSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";
import * as ref from "./reference/uc-reference.mjs";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const OUT_DIR = join(ROOT, "generated", "source", "GoldenVectors");
const MANIFEST_PATH = join(ROOT, "generated", "manifests", "golden-vectors.manifest.json");
const VECTOR_SET_VERSION = 1;

// ---------------------------------------------------------------------------------------------------------------
// Luau literal emission (deterministic: object keys sorted)
// ---------------------------------------------------------------------------------------------------------------

function luauString(text) {
  let out = '"';
  for (let i = 0; i < text.length; i++) {
    const code = text.charCodeAt(i);
    if (code === 0x5c) out += "\\\\";
    else if (code === 0x22) out += '\\"';
    else if (code >= 0x20 && code <= 0x7e) out += text[i];
    else out += `\\x${code.toString(16).padStart(2, "0")}`;
  }
  return `${out}"`;
}

function isIdentifier(key) {
  return /^[A-Za-z_][A-Za-z0-9_]*$/.test(key) && !LUAU_KEYWORDS.has(key);
}

const LUAU_KEYWORDS = new Set([
  "and", "break", "do", "else", "elseif", "end", "false", "for", "function", "if", "in", "local", "nil", "not", "or",
  "repeat", "return", "then", "true", "until", "while", "continue", "export", "type",
]);

function luau(value, depth = 0) {
  const pad = "\t".repeat(depth + 1);
  const closePad = "\t".repeat(depth);
  if (typeof value === "boolean") return value ? "true" : "false";
  if (typeof value === "number") {
    if (!Number.isFinite(value)) throw new Error("non-finite in vector");
    return String(value);
  }
  if (typeof value === "string") return luauString(value);
  if (Array.isArray(value)) {
    if (value.length === 0) return "{}";
    const simple = value.every((item) => typeof item !== "object");
    if (simple && value.length <= 8) return `{ ${value.map((item) => luau(item, depth + 1)).join(", ")} }`;
    return `{\n${value.map((item) => `${pad}${luau(item, depth + 1)},`).join("\n")}\n${closePad}}`;
  }
  const keys = Object.keys(value).sort();
  if (keys.length === 0) return "{}";
  const body = keys
    .map((key) => `${pad}${isIdentifier(key) ? key : `[${luauString(key)}]`} = ${luau(value[key], depth + 1)},`)
    .join("\n");
  return `{\n${body}\n${closePad}}`;
}

function moduleText(name, description, data) {
  return `--!strict
--[[
	GENERATED FILE - DO NOT EDIT.
	Vector set: ${name} (v${VECTOR_SET_VERSION}) - ${description}
	Source:     tools/gen-golden-vectors.mjs, reference tools/reference/uc-reference.mjs (independent BigInt model)
	Regenerate: npm run gen:vectors      Verify: npm run check:vectors
]]

return table.freeze(${luau(data)} :: any)
`;
}

// ---------------------------------------------------------------------------------------------------------------
// Deterministic operand source for the generator itself (independent of the Luau RNG under test)
// ---------------------------------------------------------------------------------------------------------------

function* operandStream(seed) {
  let state = seed;
  for (;;) {
    let out;
    [state, out] = ref.splitmix64Next(state);
    yield out;
  }
}

const M32 = 0xffffffff;
const EDGE_U32 = [0, 1, 2, 0xffff, 0x10000, 0x7fffffff, 0x80000000, 0xffffffff, 0x1b3, 0x01000000];

// ---------------------------------------------------------------------------------------------------------------
// Vector sets
// ---------------------------------------------------------------------------------------------------------------

function uint64Vectors() {
  const stream = operandStream(0x5eedc0den);
  const u64 = () => stream.next().value;
  const u32 = () => Number(u64() & 0xffffffffn);

  const mul32 = [];
  const mulWide32 = [];
  for (const a of EDGE_U32) {
    for (const b of EDGE_U32) {
      mul32.push({ a, b, result: Number(ref.uint64Ops.mul32(a, b)) });
      const [hi, lo] = ref.splitLanes(ref.uint64Ops.mulWide32(a, b));
      mulWide32.push({ a, b, hi, lo });
    }
  }
  for (let i = 0; i < 64; i++) {
    const a = u32();
    const b = u32();
    mul32.push({ a, b, result: Number(ref.uint64Ops.mul32(a, b)) });
    const [hi, lo] = ref.splitLanes(ref.uint64Ops.mulWide32(a, b));
    mulWide32.push({ a, b, hi, lo });
  }

  const edge64 = [0n, 1n, 0xffffffffffffffffn, 0x8000000000000000n, 0x00000000ffffffffn, 0xffffffff00000000n, 0x100000001b3n];
  const operands = [...edge64];
  for (let i = 0; i < 56; i++) operands.push(u64());

  const binary = (op) => {
    const rows = [];
    for (let i = 0; i < operands.length; i++) {
      const a = operands[i];
      const b = operands[(i * 7 + 3) % operands.length];
      const [aHi, aLo] = ref.splitLanes(a);
      const [bHi, bLo] = ref.splitLanes(b);
      const [hi, lo] = ref.splitLanes(ref.uint64Ops[op](a, b));
      rows.push({ aHi, aLo, bHi, bLo, hi, lo });
    }
    return rows;
  };

  const shr = [];
  for (const a of operands) {
    for (const n of [0, 1, 5, 17, 30, 31, 32, 33, 47, 63]) {
      const [hi, lo] = ref.splitLanes(a);
      const [rHi, rLo] = ref.splitLanes(ref.uint64Ops.shr(a, n));
      shr.push({ hi, lo, n, outHi: rHi, outLo: rLo });
    }
  }

  return { mul32, mulWide32, mul: binary("mul"), add: binary("add"), xor: binary("xor"), shr };
}

function hashVectors() {
  const longText = "universe-creator-".repeat(60);
  let everyByte = "";
  for (let i = 0; i < 256; i++) everyByte += String.fromCharCode(i);
  const texts = ["", "a", "foobar", "hello", "UCSEEDV1", "epoch", longText, everyByte, "\x00", "\xff\xfe"];

  const fnv = texts.map((text) => ({
    input: text,
    hex: ref.toHex64(ref.fnvAbsorbString(ref.FNV_OFFSET, text)),
  }));
  const hashString = texts.map((text) => ({ input: text, hex: ref.toHex64(ref.hashString(text)) }));

  const fmixInputs = [0n, 1n, 0xffffffffffffffffn, 0x0123456789abcdefn, 0x8000000000000000n, 0xdeadbeefcafef00dn];
  const stream = operandStream(0xf1f1n);
  for (let i = 0; i < 24; i++) fmixInputs.push(stream.next().value);
  const fmix = fmixInputs.map((value) => ({ inputHex: ref.toHex64(value), outputHex: ref.toHex64(ref.fmix64(value)) }));

  const splitmix = [0n, 1n, 0xdeadbeefcafef00dn, 0xffffffffffffffffn, 0x0123456789abcdefn].map((start) => {
    let state = start;
    const outputs = [];
    for (let i = 0; i < 8; i++) {
      let out;
      [state, out] = ref.splitmix64Next(state);
      outputs.push({ stateHex: ref.toHex64(state), outHex: ref.toHex64(out) });
    }
    return { seedHex: ref.toHex64(start), outputs };
  });

  return { fnv1a64: fnv, hashString, fmix64: fmix, splitmix64: splitmix };
}

const SEED_HEXES = [
  "0000000000000000",
  "0000000000000001",
  "ffffffffffffffff",
  "0123456789abcdef",
  "deadbeefcafef00d",
  "8000000080000000",
];

const LEVEL_NAMES = ["epoch", "cluster", "galaxy", "sector", "system", "body", "subobject"];
const ID_SAMPLES = ["E1", "C-07", "G.alpha", "S_00042", "sys-9", "a", "Z9z9-_.", "x".repeat(64), "0", "UC-001b"];
const GEN_VERSIONS = [1, 2, 7, 65535, 2147483647];

function seedVectors() {
  const derive = [];
  for (const parentHex of SEED_HEXES) {
    for (let i = 0; i < 6; i++) {
      const namespace = LEVEL_NAMES[(i + parentHex.charCodeAt(3)) % LEVEL_NAMES.length];
      const stableId = ID_SAMPLES[(i * 3 + parentHex.charCodeAt(5)) % ID_SAMPLES.length];
      const generatorVersion = GEN_VERSIONS[(i + parentHex.charCodeAt(7)) % GEN_VERSIONS.length];
      derive.push({
        parentHex,
        namespace,
        stableId,
        generatorVersion,
        childHex: ref.seedDerive(parentHex, namespace, stableId, generatorVersion),
      });
    }
  }
  for (const namespace of ["stream", "epoch", "a", "a.b-c_9"]) {
    derive.push({
      parentHex: SEED_HEXES[3],
      namespace,
      stableId: "morphology",
      generatorVersion: 1,
      childHex: ref.seedDerive(SEED_HEXES[3], namespace, "morphology", 1),
    });
  }

  const fromText = [
    ["challenge", "stellar-forge-2026w40"],
    ["challenge", ""],
    ["fixture", "root"],
    ["a", "\x00\xffbytes"],
    ["universe", "x".repeat(300)],
  ].map(([purpose, text]) => ({ purpose, text, hex: ref.seedFromText(purpose, text) }));

  const paths = [];
  for (const rootHex of [SEED_HEXES[3], SEED_HEXES[4]]) {
    for (const generatorVersion of [1, 3]) {
      const ids = ["E1", "C-07", "G.alpha", "S_00042", "sys-9", "UC-001b", "moon.2"];
      const path = ids.map((id, i) => [LEVEL_NAMES[i], id]);
      const steps = [];
      let current = rootHex;
      for (const [namespace, stableId] of path) {
        current = ref.seedDerive(current, namespace, stableId, generatorVersion);
        steps.push({ namespace, stableId, hex: current });
      }
      paths.push({ rootHex, generatorVersion, steps });
    }
  }

  // Sibling stress corpus: derive N children of one parent and publish the digest of all of them in id order.
  const stressParent = SEED_HEXES[4];
  const stressCount = 2000;
  let digest = ref.FNV_OFFSET;
  const seen = new Set();
  for (let i = 0; i < stressCount; i++) {
    const child = ref.seedDerive(stressParent, "sector", `S-${i}`, 1);
    if (seen.has(child)) throw new Error("reference collision in stress corpus");
    seen.add(child);
    digest = ref.fnvAbsorbString(digest, child);
  }

  return {
    derive,
    fromText,
    paths,
    stress: { parentHex: stressParent, namespace: "sector", idPrefix: "S-", count: stressCount, generatorVersion: 1, digestHex: ref.toHex64(ref.fmix64(digest)) },
  };
}

function rngVectors() {
  const first32 = [];
  const u53 = [];
  const ints = [];
  const digests = [];
  const shuffles = [];
  const chances = [];
  const resumes = [];

  const ranges = [
    [0, 0],
    [1, 6],
    [-5, 5],
    [0, 99],
    [0, 4294967295],
    [0, 4294967296],
    [1, 1099511627776],
    [-4503599627370496, 4503599627370495],
    [7, 8],
    [0, 2],
  ];

  for (const seedHex of SEED_HEXES) {
    const rng = new ref.Xoshiro128ss(seedHex);
    first32.push({ seedHex, values: Array.from({ length: 12 }, () => rng.next32()) });

    const rng2 = new ref.Xoshiro128ss(seedHex);
    u53.push({ seedHex, values: Array.from({ length: 6 }, () => rng2.nextU53()) });

    for (const [lo, hi] of ranges) {
      const r = new ref.Xoshiro128ss(seedHex);
      ints.push({ seedHex, lo, hi, values: Array.from({ length: 10 }, () => r.nextInt(lo, hi)) });
    }

    const rng3 = new ref.Xoshiro128ss(seedHex);
    let digest = ref.FNV_OFFSET;
    for (let i = 0; i < 10000; i++) digest = ref.absorbU32(digest, rng3.next32());
    digests.push({ seedHex, count: 10000, digestHex: ref.toHex64(ref.fmix64(digest)) });

    const rng4 = new ref.Xoshiro128ss(seedHex);
    shuffles.push({ seedHex, input: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], output: rng4.shuffle([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]) });

    const rng5 = new ref.Xoshiro128ss(seedHex);
    chances.push({ seedHex, chancePermille: 250, values: Array.from({ length: 24 }, () => rng5.chancePermille(250)) });

    const rng6 = new ref.Xoshiro128ss(seedHex);
    for (let i = 0; i < 100; i++) rng6.next32();
    resumes.push({ seedHex, skip: 100, next: Array.from({ length: 4 }, () => rng6.next32()) });
  }

  const streamNames = ["morphology", "positions", "composition", "anomalies", "names", "visual"];
  const streams = [];
  for (const baseHex of [SEED_HEXES[3], SEED_HEXES[4]]) {
    for (const generatorVersion of [1, 2]) {
      for (const name of streamNames) {
        const seedHex = ref.streamSeed(baseHex, generatorVersion, name);
        const r = new ref.Xoshiro128ss(seedHex);
        streams.push({ baseHex, generatorVersion, name, seedHex, first: Array.from({ length: 4 }, () => r.next32()) });
      }
    }
  }

  return { first32, u53, ints, digests, shuffles, chances, resumes, streams };
}

function canonicalVectors() {
  const cases = [
    ["true", true],
    ["false", false],
    ["zero", 0],
    ["one", 1],
    ["negative", -42],
    ["maxSafe", 9007199254740991],
    ["minSafe", -9007199254740991],
    ["beyondSafe", 9007199254740992],
    ["half", 0.5],
    ["tenth", 0.1],
    ["negativeSmall", -1.25e-7],
    ["large", 1e300],
    ["denormal", 5e-324],
    ["maxDouble", 1.7976931348623157e308],
    ["emptyString", ""],
    ["ascii", "abc"],
    ["bytes", "\x00\xff\xc3\xa9"],
    ["emptyTable", []],
    ["array", [1, "two", true, 0.5]],
    ["nestedArray", [[1, 2], [], [[3]]]],
    ["map", { zeta: 1, alpha: 2, Beta: 3, "": 4, _under: 5, "é": 6 }],
    ["nestedMap", { a: { b: { c: [1, { d: false }] } }, list: ["x", "y"] }],
    [
      "profileLike",
      { profileVersion: 1, userId: 123456789, settings: { uiScalePermille: 1000, reducedMotion: false }, owned: ["u1", "u2"] },
    ],
  ];
  const valid = cases.map(([name, value]) => ({
    name,
    value,
    encoded: ref.canonicalEncode(value),
    checksumHex: ref.canonicalChecksum(value),
  }));
  return { valid };
}

const SETS = [
  ["UintVectorsV1", "uint64 lane/limb arithmetic vs BigInt", uint64Vectors],
  ["HashVectorsV1", "FNV-1a 64, fmix64, hashString, SplitMix64", hashVectors],
  ["SeedVectorsV1", "seed derivation, fromText, address paths, sibling stress digest", seedVectors],
  ["RngVectorsV1", "xoshiro128** streams, ranges, shuffles, 10k-draw digests, named stream seeds", rngVectors],
  ["CanonicalVectorsV1", "canonical encoding and checksums", canonicalVectors],
];

// ---------------------------------------------------------------------------------------------------------------

function sha256(text) {
  return createHash("sha256").update(text).digest("hex");
}

const check = process.argv.includes("--check");
const files = SETS.map(([name, description, build]) => {
  const text = moduleText(name, description, build());
  return { name, path: join(OUT_DIR, `${name}.luau`), text, sha256: sha256(text) };
});

const manifest = {
  manifestVersion: 1,
  vectorSetVersion: VECTOR_SET_VERSION,
  referenceAlgorithms: ["UC-HASH64-V1", "UC-SEED-V1", "UC-RNG-V1", "UC-CANON-V1"],
  generator: "tools/gen-golden-vectors.mjs",
  referenceImplementation: "tools/reference/uc-reference.mjs",
  files: files.map((f) => ({ path: relative(ROOT, f.path).replaceAll("\\", "/"), sha256: f.sha256 })),
};
const manifestText = `${JSON.stringify(manifest, null, 2)}\n`;

if (check) {
  const drift = [];
  for (const file of files) {
    if (!existsSync(file.path) || readFileSync(file.path, "utf8") !== file.text) drift.push(relative(ROOT, file.path));
  }
  if (!existsSync(MANIFEST_PATH) || readFileSync(MANIFEST_PATH, "utf8") !== manifestText) drift.push(relative(ROOT, MANIFEST_PATH));
  if (drift.length > 0) {
    console.error(`golden vectors are out of date:\n  ${drift.join("\n  ")}\nrun: npm run gen:vectors`);
    process.exit(1);
  }
  console.log(`golden vectors up to date (${files.length} sets)`);
} else {
  mkdirSync(OUT_DIR, { recursive: true });
  mkdirSync(dirname(MANIFEST_PATH), { recursive: true });
  for (const file of files) writeFileSync(file.path, file.text);
  writeFileSync(MANIFEST_PATH, manifestText);
  console.log(`wrote ${files.length} vector sets + manifest`);
}
