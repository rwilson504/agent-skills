#!/bin/bash
# Build script for agent-skills distribution packages
# Creates zip files for individual skills and a complete bundle
#
# Usage:
#   ./build.sh                  # Uses version from git tag or defaults to 0.0.0-dev
#   ./build.sh 1.0.0            # Explicit version
#   VERSION=1.0.0 ./build.sh    # Via environment variable

set -e

# Determine version: CLI arg > env var > git tag > fallback
if [ -n "$1" ]; then
    VERSION="$1"
elif [ -z "$VERSION" ]; then
    VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "0.0.0-dev")
fi

DIST_DIR="dist"
REPO_NAME="agent-skills"

echo "Building ${REPO_NAME} distribution packages (v${VERSION})..."
echo ""

# Create dist directory
mkdir -p "$DIST_DIR"

# Remove old zips
echo "Removing old zip files..."
rm -f "$DIST_DIR"/*.zip

# Auto-discover skill folders (any directory containing a SKILL.md)
SKILLS=()
for skill_file in */SKILL.md; do
    if [ -f "$skill_file" ]; then
        SKILLS+=("$(dirname "$skill_file")")
    fi
done

if [ ${#SKILLS[@]} -eq 0 ]; then
    echo "ERROR: No skill folders found (directories containing SKILL.md)"
    exit 1
fi

echo "Found ${#SKILLS[@]} skill(s):"
for skill in "${SKILLS[@]}"; do
    echo "  - $skill"
done
echo ""

# Build individual skill zips
echo "Building individual skill packages..."
for skill in "${SKILLS[@]}"; do
    echo "  Packaging: ${skill}-v${VERSION}.zip"
    zip -rq "$DIST_DIR/${skill}-v${VERSION}.zip" "${skill}/" -x "*/.DS_Store" "*/evaluations/*"
done

# Build complete bundle
echo ""
echo "Building complete bundle..."
BUNDLE_NAME="${REPO_NAME}-v${VERSION}.zip"

# Build zip with all skill folders + root files
ZIP_ARGS=()
for skill in "${SKILLS[@]}"; do
    ZIP_ARGS+=("${skill}/")
done
# Include root-level docs if they exist
[ -f "README.md" ] && ZIP_ARGS+=("README.md")
[ -f "LICENSE" ] && ZIP_ARGS+=("LICENSE")

zip -rq "$DIST_DIR/${BUNDLE_NAME}" "${ZIP_ARGS[@]}" -x "*/.DS_Store" "*/evaluations/*"
echo "  Packaged: ${BUNDLE_NAME}"

# Show results
echo ""
echo "Build complete! Files in ${DIST_DIR}/:"
echo ""
ls -lh "$DIST_DIR"/*.zip
echo ""
echo "Package sizes:"
du -h "$DIST_DIR"/*.zip
