// Repository policy linter: enforces the hard engineering rules from AGENTS.md / 18-CODING-STANDARDS.md that a
// generic linter cannot know. Zero dependencies.
//
//   node tools/lint-policy.mjs            lint the repository, exit 1 on any violation
//
// Rules (each violation prints file:line and the rule id):
//   strict-header     production .luau under src/ and tests/ must start with --!strict
//   no-random         math.random / Random.new / os.time / os.date / tick() / DateTime banned in pure layers
//   pure-layer        Core/Domain/Contracts/Lifecycle may not touch the engine (game, workspace, Instance, task)
//   layering          Core/Domain may not require Contracts/Server/Client/Runtime; Shared may not require Server/Client
//   chained-cast      `x :: A :: B` is a syntax error in Luau; parenthesise
//   error-code        every ErrorCodes.NAME must exist in Core/ErrorCodes.luau
//   no-adhoc-remote   Instance.new("RemoteEvent"...) only inside Infrastructure/Networking or Runtime
//   no-dynamic-code   loadstring / getfenv / setfenv / require(<number>) banned everywhere
//   no-http           HttpService use banned in src/ (tools use loopback HTTP, game code does not)
import { readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");

const PURE_DIRS = ["src/ReplicatedStorage/Shared/Core", "src/ReplicatedStorage/Shared/Domain", "src/ReplicatedStorage/Shared/Contracts", "src/ReplicatedStorage/Shared/Lifecycle"];
const NO_RANDOM_DIRS = [...PURE_DIRS, "src/ServerScriptService/Server/Application"];
const REMOTE_ALLOWED = ["Infrastructure/Networking", "Shared/Runtime", "Client/Networking"];

function walk(dir, files = []) {
  for (const name of readdirSync(dir)) {
    if (name === "node_modules" || name === ".git" || name === "build" || name === "vendor") continue;
    const full = join(dir, name);
    if (statSync(full).isDirectory()) walk(full, files);
    else if (name.endsWith(".luau") || name.endsWith(".lua")) files.push(full);
  }
  return files;
}

const posix = (path) => relative(ROOT, path).split(sep).join("/");
const under = (file, dirs) => dirs.some((dir) => file === dir || file.startsWith(`${dir}/`));

// Strips comments and string literals so rules do not fire on prose or data. Preserves line structure.
export function stripNoise(source) {
  let out = "";
  let i = 0;
  const n = source.length;
  while (i < n) {
    const two = source.slice(i, i + 2);
    if (two === "--") {
      const long = /^--\[(=*)\[/.exec(source.slice(i));
      if (long) {
        const close = `]${long[1]}]`;
        const end = source.indexOf(close, i + long[0].length);
        const stop = end === -1 ? n : end + close.length;
        out += source.slice(i, stop).replace(/[^\n]/g, " ");
        i = stop;
      } else {
        const end = source.indexOf("\n", i);
        const stop = end === -1 ? n : end;
        out += " ".repeat(stop - i);
        i = stop;
      }
    } else if (source[i] === '"' || source[i] === "'") {
      const quote = source[i];
      let j = i + 1;
      while (j < n && source[j] !== quote && source[j] !== "\n") j += source[j] === "\\" ? 2 : 1;
      out += quote + " ".repeat(Math.max(0, j - i - 1)) + (source[j] === quote ? quote : "");
      i = j + 1;
    } else if (source[i] === "[" && /^\[(=*)\[/.test(source.slice(i))) {
      const m = /^\[(=*)\[/.exec(source.slice(i));
      const close = `]${m[1]}]`;
      const end = source.indexOf(close, i + m[0].length);
      const stop = end === -1 ? n : end + close.length;
      out += source.slice(i, stop).replace(/[^\n]/g, " ");
      i = stop;
    } else {
      out += source[i];
      i += 1;
    }
  }
  return out;
}

function loadErrorCodes() {
  const text = readFileSync(join(ROOT, "src/ReplicatedStorage/Shared/Core/ErrorCodes.luau"), "utf8");
  const codes = new Set();
  for (const match of text.matchAll(/^\s*([A-Z][A-Z0-9_]+)\s*=\s*"\1"/gm)) codes.add(match[1]);
  return codes;
}

export function lintFile(file, source, errorCodes) {
  const violations = [];
  const add = (line, rule, message) => violations.push({ file, line, rule, message });
  const lines = source.split("\n");
  const clean = stripNoise(source).split("\n");
  const isProduction = file.startsWith("src/");
  const isTest = file.startsWith("tests/");

  if ((isProduction || isTest) && !/^--!strict\b/m.test(lines.slice(0, 3).join("\n"))) {
    add(1, "strict-header", "production and test modules must begin with --!strict");
  }

  clean.forEach((text, index) => {
    const line = index + 1;
    if (under(file, NO_RANDOM_DIRS) && /\b(math\.random|math\.randomseed|Random\.new|os\.time|os\.date|os\.clock|tick|time|DateTime)\b\s*[(.]/.test(text)) {
      add(line, "no-random", "randomness/time sources are banned in pure and application layers (inject a clock or derive from a Seed)");
    }
    if (under(file, PURE_DIRS) && /\b(game\s*[:.]|workspace\b|Instance\.new|task\.|script\.Parent\.Parent\.Parent\.Parent)/.test(text)) {
      add(line, "pure-layer", "pure layers must not touch the engine; inject a scheduler/clock instead");
    }
    if (under(file, ["src/ReplicatedStorage/Shared/Core", "src/ReplicatedStorage/Shared/Domain"]) && /require\([^)]*(Contracts|Server|Client|Runtime|Lifecycle)/.test(text)) {
      add(line, "layering", "Core/Domain may not depend on higher layers");
    }
    if (file.startsWith("src/ReplicatedStorage/") && /require\([^)]*\b(ServerScriptService|ServerStorage|StarterPlayer)\b/.test(text)) {
      add(line, "layering", "replicated modules must not require server or client-only modules");
    }
    if (/::\s*[A-Za-z_][\w.<>]*(\?)?\s*::/.test(text)) {
      add(line, "chained-cast", "chained `::` casts do not parse in Luau; write (x :: A) :: B");
    }
    for (const match of text.matchAll(/\bErrorCodes\.([A-Z][A-Z0-9_]*)\b/g)) {
      if (!errorCodes.has(match[1])) add(line, "error-code", `ErrorCodes.${match[1]} is not defined in Core/ErrorCodes.luau`);
    }
    if (isProduction && /Instance\.new\(\s*"(RemoteEvent|RemoteFunction|UnreliableRemoteEvent)"/.test(source.split("\n")[index]) && !REMOTE_ALLOWED.some((part) => file.includes(part))) {
      add(line, "no-adhoc-remote", "remotes are created only by the central transport (Infrastructure/Networking, Runtime)");
    }
    if (/\b(loadstring|getfenv|setfenv)\b/.test(text) || /\brequire\(\s*-?\d/.test(text)) {
      add(line, "no-dynamic-code", "dynamic code loading and numeric-id require are banned");
    }
    if (isProduction && /\bHttpService\b/.test(text)) {
      add(line, "no-http", "game code must not use HttpService");
    }
  });
  return violations;
}

function main() {
  const errorCodes = loadErrorCodes();
  const files = [];
  for (const dir of ["src", "tests"]) {
    try {
      walk(join(ROOT, dir), files);
    } catch {
      /* directory not present yet */
    }
  }
  const violations = [];
  for (const full of files) {
    const file = posix(full);
    violations.push(...lintFile(file, readFileSync(full, "utf8"), errorCodes));
  }
  if (violations.length > 0) {
    for (const v of violations) console.error(`${v.file}:${v.line} [${v.rule}] ${v.message}`);
    console.error(`\n${violations.length} policy violation(s) in ${files.length} file(s)`);
    process.exit(1);
  }
  console.log(`policy lint clean (${files.length} luau files, ${errorCodes.size} error codes)`);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) main();
