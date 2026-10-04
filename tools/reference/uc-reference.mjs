// Independent reference implementation of the Universe Creator determinism spec (docs/specs/DETERMINISM.md).
//
// Purpose: golden vectors for the Luau implementation come from THIS file, which shares no code and uses a
// different arithmetic strategy (BigInt for 64-bit math, Math.imul for 32-bit) than the Luau lane/limb version.
// Disagreement between the two is a bug in one of them. The primitives are anchored to published vectors in
// tools/tests/reference.test.mjs (FNV-1a 64, SplitMix64), so the reference is not merely self-consistent.
//
// Strings are "binary strings": each UTF-16 code unit 0-255 is one byte. Callers must not pass code units > 255.

const M64 = (1n << 64n) - 1n;
const M32 = 0xffffffffn;

export const FNV_OFFSET = 0xcbf29ce484222325n;
export const FNV_PRIME = 0x100000001b3n;

export const MAX_SAFE_INTEGER = 9007199254740991;

export function toHex64(value) {
  return value.toString(16).padStart(16, "0");
}

export function fromHex64(text) {
  if (!/^[0-9a-f]{16}$/.test(text)) throw new Error(`bad hex64: ${text}`);
  return BigInt(`0x${text}`);
}

function bytesOf(text) {
  const out = [];
  for (let i = 0; i < text.length; i++) {
    const code = text.charCodeAt(i);
    if (code > 255) throw new Error("binary string required (code unit > 255)");
    out.push(code);
  }
  return out;
}

// --- hashing ------------------------------------------------------------------------------------------------

export function fnvAbsorbByte(h, byte) {
  return ((h ^ BigInt(byte)) * FNV_PRIME) & M64;
}

export function fnvAbsorbString(h, text) {
  for (const byte of bytesOf(text)) h = fnvAbsorbByte(h, byte);
  return h;
}

export function absorbU32(h, value) {
  const v = BigInt(value) & M32;
  for (let i = 0n; i < 4n; i++) h = fnvAbsorbByte(h, Number((v >> (8n * i)) & 0xffn));
  return h;
}

export function absorbField(h, text) {
  h = absorbU32(h, text.length);
  return fnvAbsorbString(h, text);
}

export function fmix64(k) {
  k ^= k >> 33n;
  k = (k * 0xff51afd7ed558ccdn) & M64;
  k ^= k >> 33n;
  k = (k * 0xc4ceb9fe1a85ec53n) & M64;
  k ^= k >> 33n;
  return k;
}

export function hashString(text) {
  return fmix64(fnvAbsorbString(FNV_OFFSET, text));
}

// --- SplitMix64 ---------------------------------------------------------------------------------------------

export function splitmix64Next(state) {
  const next = (state + 0x9e3779b97f4a7c15n) & M64;
  let z = next;
  z = ((z ^ (z >> 30n)) * 0xbf58476d1ce4e5b9n) & M64;
  z = ((z ^ (z >> 27n)) * 0x94d049bb133111ebn) & M64;
  z ^= z >> 31n;
  return [next, z];
}

// --- seeds --------------------------------------------------------------------------------------------------

const DOMAIN_TAG = "UCSEEDV1";
const ROOT_TAG = "UCROOTV1";

export function seedDerive(parentHex, namespace, stableId, generatorVersion) {
  const parent = fromHex64(parentHex);
  let h = fnvAbsorbString(FNV_OFFSET, DOMAIN_TAG);
  h = absorbU32(h, generatorVersion);
  h = absorbU32(h, Number(parent >> 32n));
  h = absorbU32(h, Number(parent & M32));
  h = absorbField(h, namespace);
  h = absorbField(h, stableId);
  return toHex64(fmix64(h));
}

export function seedFromText(purpose, text) {
  let h = fnvAbsorbString(FNV_OFFSET, ROOT_TAG);
  h = absorbField(h, purpose);
  h = absorbField(h, text);
  return toHex64(fmix64(h));
}

export function seedDeriveAlongPath(rootHex, path, generatorVersion) {
  let current = rootHex;
  for (const [namespace, stableId] of path) current = seedDerive(current, namespace, stableId, generatorVersion);
  return current;
}

// --- xoshiro128** -------------------------------------------------------------------------------------------

function rotl32(x, k) {
  return ((x << k) | (x >>> (32 - k))) >>> 0;
}

export class Xoshiro128ss {
  constructor(seedHex) {
    let state = fromHex64(seedHex);
    let out1;
    let out2;
    [state, out1] = splitmix64Next(state);
    [state, out2] = splitmix64Next(state);
    this.s = [Number(out1 & M32), Number(out1 >> 32n), Number(out2 & M32), Number(out2 >> 32n)];
    if (this.s.every((word) => word === 0)) this.s[0] = 1;
  }

  next32() {
    const s = this.s;
    const result = Math.imul(rotl32(Math.imul(s[1], 5) >>> 0, 7), 9) >>> 0;
    const t = (s[1] << 9) >>> 0;
    s[2] = (s[2] ^ s[0]) >>> 0;
    s[3] = (s[3] ^ s[1]) >>> 0;
    s[1] = (s[1] ^ s[2]) >>> 0;
    s[0] = (s[0] ^ s[3]) >>> 0;
    s[2] = (s[2] ^ t) >>> 0;
    s[3] = rotl32(s[3], 11);
    return result;
  }

  nextU53() {
    const high = this.next32() >>> 5;
    const low = this.next32() >>> 6;
    return high * 67108864 + low;
  }

  nextInt(lo, hi) {
    const range = hi - lo + 1;
    if (range === 1) return lo;
    if (range <= 4294967296) {
      const limit = 4294967296 - (4294967296 % range);
      let draw = this.next32();
      while (draw >= limit) draw = this.next32();
      return lo + (draw % range);
    }
    const two53 = 9007199254740992n;
    const bigRange = BigInt(range);
    const limit = two53 - (two53 % bigRange);
    let draw = BigInt(this.nextU53());
    while (draw >= limit) draw = BigInt(this.nextU53());
    return lo + Number(draw % bigRange);
  }

  chancePermille(chance) {
    if (chance === 0) return false;
    if (chance === 1000) return true;
    return this.nextInt(0, 999) < chance;
  }

  shuffle(list) {
    for (let i = list.length; i >= 2; i--) {
      const j = this.nextInt(1, i);
      [list[i - 1], list[j - 1]] = [list[j - 1], list[i - 1]];
    }
    return list;
  }
}

export function streamSeed(baseHex, generatorVersion, name) {
  return seedDerive(baseHex, "stream", name, generatorVersion);
}

// --- canonical encoding ---------------------------------------------------------------------------------------

function compareBytes(a, b) {
  const ba = bytesOf(a);
  const bb = bytesOf(b);
  const n = Math.min(ba.length, bb.length);
  for (let i = 0; i < n; i++) if (ba[i] !== bb[i]) return ba[i] < bb[i] ? -1 : 1;
  return ba.length === bb.length ? 0 : ba.length < bb.length ? -1 : 1;
}

function floatHex(value) {
  const buffer = Buffer.alloc(8);
  buffer.writeDoubleBE(value);
  return buffer.toString("hex");
}

// Value model: boolean | number | string(binary) | Array | plain object (string keys). An EMPTY plain object and an
// EMPTY array both encode as "a0:" (Lua has a single empty table).
export function canonicalEncode(value) {
  if (typeof value === "boolean") return value ? "T" : "F";
  if (typeof value === "number") {
    if (!Number.isFinite(value)) throw new Error("non-finite number");
    if (value === 0) return "i0;";
    if (Number.isInteger(value) && Math.abs(value) <= MAX_SAFE_INTEGER) return `i${value};`;
    return `d${floatHex(value)}`;
  }
  if (typeof value === "string") {
    bytesOf(value);
    return `s${value.length}:${value}`;
  }
  if (Array.isArray(value)) {
    if (value.length === 0) return "a0:";
    return `a${value.length}:${value.map(canonicalEncode).join("")}`;
  }
  if (value !== null && typeof value === "object") {
    const keys = Object.keys(value).sort(compareBytes);
    if (keys.length === 0) return "a0:";
    return `m${keys.length}:${keys.map((key) => `s${key.length}:${key}${canonicalEncode(value[key])}`).join("")}`;
  }
  throw new Error(`unsupported value: ${String(value)}`);
}

export function canonicalChecksum(value) {
  return toHex64(hashString(canonicalEncode(value)));
}

// --- uint64 operation oracle (for the lane/limb implementation) ------------------------------------------------

export function splitLanes(value) {
  return [Number(value >> 32n), Number(value & M32)];
}

export function joinLanes(hi, lo) {
  return (BigInt(hi) << 32n) | BigInt(lo);
}

export const uint64Ops = {
  mul: (a, b) => (a * b) & M64,
  add: (a, b) => (a + b) & M64,
  xor: (a, b) => a ^ b,
  shr: (a, n) => a >> BigInt(n),
  mulWide32: (a, b) => BigInt(a) * BigInt(b),
  mul32: (a, b) => (BigInt(a) * BigInt(b)) & M32,
};
