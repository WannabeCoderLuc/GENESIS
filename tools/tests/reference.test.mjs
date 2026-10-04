// Anchors the reference implementation to PUBLISHED vectors, so the golden data is not merely self-consistent.
// Run: npm run test:tools
import test from "node:test";
import assert from "node:assert/strict";
import * as ref from "../reference/uc-reference.mjs";

test("FNV-1a 64 matches the published test vectors", () => {
  assert.equal(ref.toHex64(ref.fnvAbsorbString(ref.FNV_OFFSET, "")), "cbf29ce484222325");
  assert.equal(ref.toHex64(ref.fnvAbsorbString(ref.FNV_OFFSET, "a")), "af63dc4c8601ec8c");
  assert.equal(ref.toHex64(ref.fnvAbsorbString(ref.FNV_OFFSET, "foobar")), "85944171f73967e8");
});

test("SplitMix64 from state 0 matches the published sequence", () => {
  let state = 0n;
  const outputs = [];
  for (let i = 0; i < 3; i++) {
    let out;
    [state, out] = ref.splitmix64Next(state);
    outputs.push(ref.toHex64(out));
  }
  assert.deepEqual(outputs, ["e220a8397b1dcdaf", "6e789e6aa1b965f4", "06c45d188009454f"]);
});

test("fmix64 fixed points and avalanche basics", () => {
  assert.equal(ref.fmix64(0n), 0n);
  assert.notEqual(ref.fmix64(1n), ref.fmix64(2n));
});

test("seed derivation is sensitive to every input field and unambiguous across field boundaries", () => {
  const base = ref.seedDerive("0123456789abcdef", "sector", "S-1", 1);
  assert.notEqual(base, ref.seedDerive("0123456789abcdee", "sector", "S-1", 1));
  assert.notEqual(base, ref.seedDerive("0123456789abcdef", "system", "S-1", 1));
  assert.notEqual(base, ref.seedDerive("0123456789abcdef", "sector", "S-2", 1));
  assert.notEqual(base, ref.seedDerive("0123456789abcdef", "sector", "S-1", 2));
  // ("ab","c") vs ("a","bc"): length-prefixed fields cannot collide
  assert.notEqual(ref.seedDerive("0123456789abcdef", "ab", "c", 1), ref.seedDerive("0123456789abcdef", "a", "bc", 1));
});

test("canonical encoding: shapes, normalization, ordering", () => {
  assert.equal(ref.canonicalEncode(0), "i0;");
  assert.equal(ref.canonicalEncode(-0), "i0;");
  assert.equal(ref.canonicalEncode(12), "i12;");
  assert.equal(ref.canonicalEncode(-7), "i-7;");
  assert.equal(ref.canonicalEncode(0.5), "d3fe0000000000000");
  assert.equal(ref.canonicalEncode(9007199254740992), "d4340000000000000");
  assert.equal(ref.canonicalEncode("ab"), "s2:ab");
  assert.equal(ref.canonicalEncode([]), "a0:");
  assert.equal(ref.canonicalEncode({}), "a0:");
  assert.equal(ref.canonicalEncode([true, false]), "a2:TF");
  assert.equal(ref.canonicalEncode({ b: 1, a: 2 }), ref.canonicalEncode({ a: 2, b: 1 }));
  assert.equal(ref.canonicalEncode({ b: 1, a: 2 }), "m2:s1:ai2;s1:bi1;");
  // byte order, not locale: uppercase sorts before lowercase, high bytes after ASCII
  assert.equal(ref.canonicalEncode({ a: 1, B: 2, "\xe9": 3 }), "m3:s1:Bi2;s1:ai1;s1:\xe9i3;");
  assert.throws(() => ref.canonicalEncode(NaN));
  assert.throws(() => ref.canonicalEncode(Infinity));
});

test("xoshiro128** reference is deterministic and range draws stay in bounds", () => {
  const a = new ref.Xoshiro128ss("deadbeefcafef00d");
  const b = new ref.Xoshiro128ss("deadbeefcafef00d");
  for (let i = 0; i < 1000; i++) assert.equal(a.next32(), b.next32());
  const r = new ref.Xoshiro128ss("0123456789abcdef");
  for (let i = 0; i < 5000; i++) {
    const v = r.nextInt(-5, 5);
    assert.ok(v >= -5 && v <= 5 && Number.isInteger(v));
  }
});
