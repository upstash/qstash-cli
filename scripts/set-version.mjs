#!/usr/bin/env node
import * as fs from "node:fs";
import * as path from "node:path";
import * as process from "node:process";
import * as util from "node:util";

const { values } = util.parseArgs({
  options: {
    version: { type: "string" },
    manifest: { type: "string", default: "package.json" },
  },
  strict: true,
});

if (!values.version) {
  console.error("Usage: set-version.mjs --version <version> [--manifest <path>]");
  process.exit(1);
}

const manifestPath = path.resolve(values.manifest);
const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));

manifest.version = values.version;

if (manifest.optionalDependencies) {
  for (const name of Object.keys(manifest.optionalDependencies)) {
    manifest.optionalDependencies[name] = values.version;
  }
}

fs.writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
console.log(`Updated ${manifestPath} (version=${values.version})`);
