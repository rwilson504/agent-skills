#!/usr/bin/env node
// Bump version for a single skill / plugin.
//
// Usage:
//   node scripts/bump-skill-version.mjs <skill-folder> <patch|minor|major|X.Y.Z>
//
// Updates atomically:
//   1. src/skills/<skill>/SKILL.md  — top-level `version:` AND `metadata.version`
//   2. plugins.yml                  — plugins.<skill>.version
//      (assumes plugin name == skill name; this matches the current 1:1
//      layout. If a plugin ever bundles multiple skills with diverging
//      versions, this script will need to grow.)
//
// Then runs `pwsh scripts/build-plugins.ps1` so plugins/ and
// .github/plugin/marketplace.json are regenerated from the bumped sources.
//
// Prints the new version to stdout (last line) so the caller can capture it.
// Exits non-zero on any inconsistency or missing file.

import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { resolve, join } from "node:path";
import { spawnSync } from "node:child_process";

const [, , skill, bumpArg] = process.argv;

if (!skill || !bumpArg) {
  console.error(
    "Usage: node scripts/bump-skill-version.mjs <skill-folder> <patch|minor|major|X.Y.Z>"
  );
  process.exit(2);
}

const repoRoot = resolve(process.cwd());
const skillDir = join(repoRoot, "src", "skills", skill);
const skillMdPath = join(skillDir, "SKILL.md");
const pluginsYmlPath = join(repoRoot, "plugins.yml");
const buildScriptPath = join(repoRoot, "scripts", "build-plugins.ps1");

for (const p of [skillDir, skillMdPath, pluginsYmlPath, buildScriptPath]) {
  if (!existsSync(p)) {
    console.error(`Missing required path: ${p}`);
    process.exit(1);
  }
}

// --- Read current version from SKILL.md frontmatter -------------------------

const skillMd = readFileSync(skillMdPath, "utf8");
const fmMatch = skillMd.match(/^---\r?\n([\s\S]*?)\r?\n---/);
if (!fmMatch) {
  console.error(`No YAML frontmatter found in ${skillMdPath}`);
  process.exit(1);
}
const fm = fmMatch[1];

const topVersionMatch = fm.match(/^version:\s*(\S+)\s*$/m);
if (!topVersionMatch) {
  console.error(`No top-level 'version:' key in ${skillMdPath} frontmatter`);
  process.exit(1);
}
const currentVersion = topVersionMatch[1];

const metaVersionMatch = fm.match(/"version"\s*:\s*"([^"]+)"/);
if (!metaVersionMatch) {
  console.error(`No metadata.version in ${skillMdPath} frontmatter`);
  process.exit(1);
}
if (metaVersionMatch[1] !== currentVersion) {
  console.error(
    `Version mismatch in ${skillMdPath}: top-level '${currentVersion}' != metadata.version '${metaVersionMatch[1]}'. Fix manually before bumping.`
  );
  process.exit(1);
}

// --- Compute new version ----------------------------------------------------

const semverRe = /^(\d+)\.(\d+)\.(\d+)$/;
const cur = currentVersion.match(semverRe);
if (!cur) {
  console.error(`Current version '${currentVersion}' is not plain semver X.Y.Z`);
  process.exit(1);
}
let [maj, min, pat] = cur.slice(1).map(Number);

let newVersion;
if (bumpArg === "patch") {
  newVersion = `${maj}.${min}.${pat + 1}`;
} else if (bumpArg === "minor") {
  newVersion = `${maj}.${min + 1}.0`;
} else if (bumpArg === "major") {
  newVersion = `${maj + 1}.0.0`;
} else if (semverRe.test(bumpArg)) {
  newVersion = bumpArg;
} else {
  console.error(`Bump arg must be patch|minor|major|X.Y.Z, got '${bumpArg}'`);
  process.exit(1);
}

console.error(`[${skill}] ${currentVersion} -> ${newVersion}`);

// --- 1. Rewrite SKILL.md frontmatter ---------------------------------------

let newFm = fm.replace(/^version:\s*\S+\s*$/m, `version: ${newVersion}`);
// Replace ONLY the metadata.version, not any other "version" string in the file.
// The metadata line is single-line JSON, so the first "version":"..." after
// `metadata: {` is the one to update.
newFm = newFm.replace(
  /(metadata:\s*\{[^}]*?"version"\s*:\s*")[^"]+(")/,
  `$1${newVersion}$2`
);
const newSkillMd = skillMd.replace(fm, newFm);
writeFileSync(skillMdPath, newSkillMd);

// --- 2. Rewrite plugins.yml plugin version ---------------------------------
//
// Targeted regex update: find the `<skill>:` map key under `plugins:`, then
// replace the first `version: ...` line under it. We deliberately avoid a
// full YAML round-trip so we don't reflow comments or quoting. Plugin entries
// in plugins.yml use 2-space indent for the key and 4-space indent for fields.

const pluginsYml = readFileSync(pluginsYmlPath, "utf8");
const pluginBlockRe = new RegExp(
  String.raw`(^  ${skill}:\s*\r?\n(?:(?:    [^\r\n]*|\s*)\r?\n)*?    version:\s*)\S+(\s*\r?\n)`,
  "m"
);
if (!pluginBlockRe.test(pluginsYml)) {
  console.error(
    `Could not find 'version:' line under plugin '${skill}' in ${pluginsYmlPath}`
  );
  process.exit(1);
}
const newPluginsYml = pluginsYml.replace(pluginBlockRe, `$1${newVersion}$2`);
if (newPluginsYml === pluginsYml) {
  console.error(`plugins.yml unchanged after replace for plugin '${skill}'`);
  process.exit(1);
}
writeFileSync(pluginsYmlPath, newPluginsYml);

// --- 3. Regenerate plugins/ + marketplace.json -----------------------------

console.error(`[${skill}] running scripts/build-plugins.ps1 to regenerate artifacts...`);
const result = spawnSync("pwsh", ["-NoProfile", "-File", buildScriptPath], {
  cwd: repoRoot,
  stdio: ["ignore", "inherit", "inherit"],
});
if (result.status !== 0) {
  console.error(
    `scripts/build-plugins.ps1 failed (exit ${result.status}). plugins/ may be stale.`
  );
  process.exit(result.status ?? 1);
}

// Last line of stdout = new version, for shell capture.
process.stdout.write(newVersion + "\n");
