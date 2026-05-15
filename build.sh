#!/bin/bash
# Build script for agent-skills distribution packages.
#
# Regenerates plugins/ (so zips always reflect src/ + plugins.yml), then
# packages each plugin folder under plugins/<name>/ as its own zip and
# bundles all plugins + root docs into a single zip.
#
# Per-plugin zip name: <plugin>-v<version>.zip (version from plugin.json).
# Bundle zip name:     agent-skills-v<VERSION>.zip (from arg / env / git tag).
#
# Requires `pwsh` on PATH for the regenerate step (skip with --skip-build).
#
# Usage:
#   ./build.sh                  # Uses version from git tag or 0.0.0-dev
#   ./build.sh 1.0.0            # Explicit bundle version
#   VERSION=1.0.0 ./build.sh    # Via env var
#   ./build.sh --skip-build     # Use existing plugins/ as-is

set -e

SKIP_BUILD=0
ARG_VERSION=""
for arg in "$@"; do
    case "$arg" in
        --skip-build) SKIP_BUILD=1 ;;
        *) ARG_VERSION="$arg" ;;
    esac
done

if [ -n "$ARG_VERSION" ]; then
    VERSION="$ARG_VERSION"
elif [ -z "$VERSION" ]; then
    VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.0.0-dev")
fi

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="$REPO_ROOT/dist"
PLUGINS_DIR="$REPO_ROOT/plugins"
BUILD_PS1="$REPO_ROOT/scripts/build-plugins.ps1"
REPO_NAME="agent-skills"

# --- Step 1: regenerate plugins/ from src/ + plugins.yml ---
if [ "$SKIP_BUILD" -eq 0 ]; then
    if ! command -v pwsh >/dev/null 2>&1; then
        echo "ERROR: pwsh is required to regenerate plugins/. Install PowerShell or run with --skip-build." >&2
        exit 1
    fi
    echo "Regenerating plugins/ from src/ + plugins.yml..."
    pwsh -NoProfile -File "$BUILD_PS1"
    echo ""
fi

if [ ! -d "$PLUGINS_DIR" ]; then
    echo "ERROR: plugins/ does not exist. Run scripts/build-plugins.ps1 first or omit --skip-build." >&2
    exit 1
fi

echo "Building ${REPO_NAME} distribution packages (bundle v${VERSION})..."
echo ""

mkdir -p "$DIST_DIR"
echo "Removing old zip files..."
rm -f "$DIST_DIR"/*.zip

# --- Discover plugins ---
PLUGINS=()
for plugin_json in "$PLUGINS_DIR"/*/plugin.json; do
    [ -f "$plugin_json" ] || continue
    PLUGINS+=("$(basename "$(dirname "$plugin_json")")")
done

if [ ${#PLUGINS[@]} -eq 0 ]; then
    echo "ERROR: No plugin folders found under plugins/ (each must contain plugin.json)" >&2
    exit 1
fi

echo "Found ${#PLUGINS[@]} plugin(s):"
for p in "${PLUGINS[@]}"; do echo "  - $p"; done
echo ""

# Extract a plugin's version from its plugin.json (no jq dependency).
get_plugin_version() {
    local manifest="$1"
    local v
    v=$(grep -E '^[[:space:]]*"version"[[:space:]]*:' "$manifest" | head -n 1 | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')
    if [ -z "$v" ]; then
        echo "ERROR: Could not extract version from $manifest" >&2
        exit 1
    fi
    echo "$v"
}

# --- Build per-plugin zips ---
echo "Building individual plugin packages..."
cd "$PLUGINS_DIR"
for plugin in "${PLUGINS[@]}"; do
    plugin_ver=$(get_plugin_version "$PLUGINS_DIR/$plugin/plugin.json")
    zip_name="${plugin}-v${plugin_ver}.zip"
    echo "  Packaging: ${zip_name}"
    # Zip the plugin folder relative to plugins/ so it extracts to <plugin>/.
    zip -rq "$DIST_DIR/${zip_name}" "${plugin}/" -x "*/.DS_Store" "*/evaluations/*"
done
cd "$REPO_ROOT"

# --- Build complete bundle ---
echo ""
echo "Building complete bundle..."
BUNDLE_NAME="${REPO_NAME}-v${VERSION}.zip"

# Bundle layout: plugins/<each>/, README.md, LICENSE.
ZIP_ARGS=("plugins/")
[ -f "README.md" ] && ZIP_ARGS+=("README.md")
[ -f "LICENSE" ] && ZIP_ARGS+=("LICENSE")

zip -rq "$DIST_DIR/${BUNDLE_NAME}" "${ZIP_ARGS[@]}" -x "*/.DS_Store" "*/evaluations/*"
echo "  Packaged: ${BUNDLE_NAME}"

# --- Report ---
echo ""
echo "Build complete! Files in ${DIST_DIR}/:"
echo ""
ls -lh "$DIST_DIR"/*.zip
echo ""
echo "Package sizes:"
du -h "$DIST_DIR"/*.zip
