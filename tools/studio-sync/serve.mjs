// Loopback-only manifest server for Studio sync.
//
//   node tools/studio-sync/serve.mjs [--port 8765]
//
// Serves exactly three read-only GET routes on 127.0.0.1: /health, /manifest.json (rebuilt from disk on every
// request, so Studio always receives the current working tree) and /StudioSync.luau (the Studio-side sync module).
// It never serves arbitrary files and refuses any non-loopback peer. Stop it with Ctrl+C or by killing the PID printed at startup.
import { createServer } from "node:http";
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { buildManifest } from "./build-manifest.mjs";

const HERE = dirname(fileURLToPath(import.meta.url));

const portIndex = process.argv.indexOf("--port");
const PORT = portIndex >= 0 ? Number(process.argv[portIndex + 1]) : 8765;
const HOST = "127.0.0.1";

const server = createServer((request, response) => {
  const peer = request.socket.remoteAddress ?? "";
  if (peer !== "127.0.0.1" && peer !== "::1" && peer !== "::ffff:127.0.0.1") {
    response.writeHead(403).end("loopback only");
    return;
  }
  if (request.method !== "GET") {
    response.writeHead(405).end("GET only");
    return;
  }
  const route = (request.url ?? "").split("?")[0];
  if (route === "/health") {
    response.writeHead(200, { "content-type": "text/plain" }).end("ok");
    return;
  }
  if (route === "/StudioSync.luau") {
    response.writeHead(200, { "content-type": "text/plain", "cache-control": "no-store" });
    response.end(readFileSync(join(HERE, "StudioSync.luau"), "utf8"));
    return;
  }
  if (route === "/manifest.json") {
    try {
      const manifest = buildManifest();
      response.writeHead(200, { "content-type": "application/json", "cache-control": "no-store" });
      response.end(JSON.stringify(manifest));
      console.log(`served manifest ${manifest.sha256.slice(0, 12)} (${manifest.entryCount} instances)`);
    } catch (error) {
      console.error(`manifest build failed: ${error.message}`);
      response.writeHead(500, { "content-type": "text/plain" }).end(`manifest build failed: ${error.message}`);
    }
    return;
  }
  response.writeHead(404).end("not found");
});

server.listen(PORT, HOST, () => {
  console.log(`studio-sync manifest server on http://${HOST}:${PORT}  (pid ${process.pid})`);
});
