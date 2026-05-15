#!/usr/bin/env node
// Bump version for a single skill across all files that track it.
//
// Usage:
//   node scripts/bump-skill-version.mjs <skill-folder> <patch|minor|major|X.Y.Z>
//
// Updates atomically:
//   1. <skill>/SKILL.md    — top-level `version:` AND `metadata.version`
//   2. <skill>/.github/plugin/plugin.json — `version`
//   3. .github/plugin/marketplace.json — plugins[<skill>].version
//
// Prints the new version to stdout (last line) so the caller can capture it.
// Exits non-zero on any inconsistency or missing file.

import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { resolve, join } from "node:path";

const [, , skill, bumpArg] = process.argv;

if (!skill || !bumpArg) {
  console.error("Usage: node scripts/bump-skill-version.mjs <skill-folder> <patch|minor|major|X.Y.Z>");
  process.exit(2);
}

const repoRoot = resolve(process.cwd());
const skillDir = join(repoRoot, skill);
const skillMdPath = join(skillDir, "SKILL.md");
const pluginJsonPath = join(skillDir, ".github", "plugin", "plugin.json");
const marketplacePath = join(repoRoot, ".github", "plugin", "marketplace.json");

for (const p of [skillDir, skillMdPath, pluginJsonPath, marketplacePath]) {
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

// --- 2. Rewrite per-skill plugin.json --------------------------------------

const pluginJson = JSON.parse(readFileSync(pluginJsonPath, "utf8"));
pluginJson.version = newVersion;
writeFileSync(pluginJsonPath, JSON.stringify(pluginJson, null, 2) + "\n");

// --- 3. Rewrite marketplace.json entry -------------------------------------

const marketplace = JSON.parse(readFileSync(marketplacePath, "utf8"));
const entry = marketplace.plugins.find((p) => p.name === skill);
if (!entry) {
  console.error(`No plugins[].name == '${skill}' in ${marketplacePath}`);
  process.exit(1);
}
entry.version = newVersion;
writeFileSync(marketplacePath, JSON.stringify(marketplace, null, 2) + "\n");

// Last line of stdout = new version, for shell capture.
process.stdout.write(newVersion + "\n");
