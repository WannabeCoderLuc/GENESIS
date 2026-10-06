import fs from "fs";
import path from "path";
import crypto from "crypto";

const UPSTREAM_DIR = "C:/Users/Luc/Desktop/DEV/Horus-main";
const VENDOR_DIR = "vendor/Horus";

// We want to pin the exact state of the Horus upstream directory to ensure no drift.
function hashDirectory(dir) {
	const files = fs.readdirSync(dir, { withFileTypes: true });
	files.sort((a, b) => a.name.localeCompare(b.name));
	const hash = crypto.createHash("sha256");
	for (const file of files) {
		const fullPath = path.join(dir, file.name);
		if (file.isDirectory()) {
			if (file.name === ".git") continue;
			hash.update(file.name + "/");
			hash.update(hashDirectory(fullPath));
		} else {
			if (file.name === "UPSTREAM.md") continue;
			hash.update(file.name);
			hash.update(fs.readFileSync(fullPath));
		}
	}
	return hash.digest("hex");
}

function copyDirectory(src, dest) {
	if (!fs.existsSync(dest)) fs.mkdirSync(dest, { recursive: true });
	const files = fs.readdirSync(src, { withFileTypes: true });
	for (const file of files) {
		if (file.name === ".git") continue;
		const srcPath = path.join(src, file.name);
		const destPath = path.join(dest, file.name);
		if (file.isDirectory()) {
			copyDirectory(srcPath, destPath);
		} else {
			fs.copyFileSync(srcPath, destPath);
		}
	}
}

const command = process.argv[2];

if (command === "verify") {
	if (!fs.existsSync(VENDOR_DIR)) {
		console.error("Horus is not vendored. Run 'npm run horus:pin'.");
		process.exit(1);
	}
	
	const upstreamHash = hashDirectory(UPSTREAM_DIR);
	const vendorHash = hashDirectory(VENDOR_DIR);
	
	if (upstreamHash !== vendorHash) {
		console.error(`Hash mismatch! Upstream: ${upstreamHash}, Vendored: ${vendorHash}`);
		process.exit(1);
	}
	console.log("Horus pin verified.");
} else {
	// Pin
	console.log("Pinning Horus...");
	if (fs.existsSync(VENDOR_DIR)) {
		fs.rmSync(VENDOR_DIR, { recursive: true });
	}
	copyDirectory(UPSTREAM_DIR, VENDOR_DIR);
	
	const vendorHash = hashDirectory(VENDOR_DIR);
	fs.writeFileSync(path.join(VENDOR_DIR, "UPSTREAM.md"), `# Horus Upstream\n\nPinned from ${UPSTREAM_DIR}.\nContent Hash: ${vendorHash}\n\nDo not modify these files directly.\n`);
	console.log(`Horus pinned. Hash: ${vendorHash}`);
}
