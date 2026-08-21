"""make_template.py — generate a baseline Bambu Studio .3mf from scratch.

Produces a "minimal valid 3mf" containing a 20 mm calibration cube. Use it
as the baseline input to apply_test_profile.py when you don't already have
a Bambu-Studio-saved .3mf to mutate.

CAVEAT (read this before printing): a build123d-exported .3mf does NOT
contain Bambu Studio's slicer profile (Metadata/project_settings.config,
plate_*.json, thumbnails). Bambu Studio will open it but treat it as a
fresh import — you'll get default settings, not your tuned profile.

For real prints, save a .3mf from Bambu Studio once with your preferred
profile and use THAT as the template. This script exists so you can:

- Validate the apply_test_profile.py round-trip against a known mesh
- Bootstrap a new template when you don't have one yet
- Smoke-test the entire pipeline without touching Bambu Studio

Usage:
    python make_template.py [--size 20] [--out template.3mf]
"""
from __future__ import annotations

import argparse
from pathlib import Path

from build123d import Box, BuildPart, Mesher


def build_calibration_cube(size_mm: float):
    """Returns a build123d Part of a centered cube of `size_mm`."""
    with BuildPart() as cube:
        Box(size_mm, size_mm, size_mm)
    return cube.part


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--size", type=float, default=20.0,
                        help="Cube edge length in mm (default: 20)")
    parser.add_argument("--out", type=Path,
                        default=Path(__file__).parent / "templates"
                                / "calibration_cube_20mm.3mf",
                        help="Output .3mf path")
    args = parser.parse_args()

    args.out.parent.mkdir(parents=True, exist_ok=True)
    part = build_calibration_cube(args.size)

    # build123d's Mesher writes a minimal valid 3MF (mesh-only, no slicer
    # metadata). Bambu Studio opens it but treats it as a fresh import.
    mesher = Mesher()
    mesher.add_shape(part, part_number="calibration_cube")
    mesher.write(str(args.out))

    bbox = part.bounding_box()
    print(f"Wrote {args.out}")
    print(f"  bbox: {bbox.size.X:.2f} \u00d7 {bbox.size.Y:.2f} \u00d7 {bbox.size.Z:.2f} mm")
    print(f"  size: {args.out.stat().st_size / 1024:.1f} KB")
    print()
    print("NOTE: This is a bare 3MF (no Bambu profile metadata). For real")
    print("print workflows, re-save through Bambu Studio with your tuned")
    print("profile and use THAT file as the template.")


if __name__ == "__main__":
    main()
