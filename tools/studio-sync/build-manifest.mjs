// Builds the Studio sync manifest from the REAL Rojo project mapping.
//
//   node tools/studio-sync/build-manifest.mjs [--out build/studio-manifest.json]
//
// Rojo (tools/bin/rojo.exe, pinned in tools/bootstrap/tools.lock.json) is the authority on how files become
// Instances (script classes, init files, nesting). This tool only reads `rojo sourcemap` and attaches script
// sources, producing a flat parent-first list that tools/studio-sync/studio-install.luau materialises inside Studio
// over loopback HTTP. It adds no mapping rules of its own.
import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import { mkdirSync, readFileSync, writeFileSync, existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..", "..");
const ROJO = join(ROOT, "tools", "bin", process.platform === "win32" ? "rojo.exe" : "rojo");
const SCRIPT_CLASSES = new Set(["Script", "LocalScript", "ModuleScript"]);

export function buildManifest() {
  if (!existsSync(ROJO)) {
    throw new Error("rojo not installed; run: powershell -File tools/bootstrap/install-tools.ps1");
  }
  const scratch = join(ROOT, "build", "studio-sourcemap.json");
  mkdirSync(dirname(scratch), { recursive: true });
  execFileSync(ROJO, ["sourcemap", "default.project.json", "--include-non-scripts", "-o", scratch], {
    cwd: ROOT,
    stdio: ["ignore", "pipe", "pipe"],
  });
  const rojoVersion = execFileSync(ROJO, ["--version"], { cwd: ROOT }).toString().trim();
  const tree = JSON.parse(readFileSync(scratch, "utf8"));

  const entries = [];
  const walk = (node, parentPath) => {
    const path = parentPath ? `${parentPath}/${node.name}` : node.name;
    const entry = { p: path, c: node.className };
    if (SCRIPT_CLASSES.has(node.className)) {
      const file = (node.filePaths ?? []).find((candidate) => candidate.endsWith(".luau") || candidate.endsWith(".lua"));
      if (!file) throw new Error(`script without source file: ${path}`);
      entry.s = readFileSync(join(ROOT, file), "utf8");
      entry.f = file.replaceAll("\\", "/");
    }
    entries.push(entry);
    for (const child of node.children ?? []) walk(child, path);
  };
  for (const service of tree.children ?? []) walk(service, "");

  const digest = createHash("sha256");
  for (const entry of entries) digest.update(`${entry.p}\0${entry.c}\0${entry.s ?? ""}\0`);
  return {
    manifestVersion: 1,
    rojoVersion,
    entryCount: entries.length,
    scriptCount: entries.filter((entry) => entry.s !== undefined).length,
    sha256: digest.digest("hex"),
    entries,
  };
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const outIndex = process.argv.indexOf("--out");
  const out = resolve(ROOT, outIndex >= 0 ? process.argv[outIndex + 1] : "build/studio-manifest.json");
  const manifest = buildManifest();
  mkdirSync(dirname(out), { recursive: true });
  writeFileSync(out, JSON.stringify(manifest));
  console.log(`manifest: ${manifest.entryCount} instances (${manifest.scriptCount} scripts), sha256 ${manifest.sha256.slice(0, 16)}...`);
}
