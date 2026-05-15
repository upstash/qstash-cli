#!/usr/bin/env node
const { spawnSync } = require("node:child_process");
const path = require("node:path");

const platformMap = { darwin: "darwin", linux: "linux", win32: "win32" };
const archMap = { arm64: "arm64", x64: "x64" };

const platform = platformMap[process.platform];
const arch = archMap[process.arch];

if (!platform || !arch) {
  console.error(
    `@upstash/qstash-cli: unsupported platform/arch: ${process.platform}/${process.arch}`
  );
  process.exit(1);
}

const pkg = `@upstash/qstash-cli-${platform}-${arch}`;
const binName = process.platform === "win32" ? "qstash.exe" : "qstash";

let binaryPath = process.env.QSTASH_CLI_BIN;

if (!binaryPath) {
  try {
    const pkgJsonPath = require.resolve(`${pkg}/package.json`);
    binaryPath = path.join(path.dirname(pkgJsonPath), "bin", binName);
  } catch {
    console.error(
      `@upstash/qstash-cli: could not locate ${pkg}.\n` +
        `Reinstall @upstash/qstash-cli with optional dependencies enabled, ` +
        `or open an issue if your platform is not supported.`
    );
    process.exit(1);
  }
}

const result = spawnSync(binaryPath, process.argv.slice(2), {
  stdio: "inherit",
  windowsHide: true,
});

if (result.error) {
  console.error(`@upstash/qstash-cli: failed to spawn ${binaryPath}: ${result.error.message}`);
  process.exit(1);
}

process.exit(result.status ?? 1);
