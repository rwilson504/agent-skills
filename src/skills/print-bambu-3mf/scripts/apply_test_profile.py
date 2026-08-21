"""apply_test_profile.py — mutate a Bambu Studio .3mf for fast prototype prints.

Implements the techniques from
https://www.howtogeek.com/slicer-tricks-i-use-to-speed-up-3d-printing-prototypes/
as a CLI wrapper:

  - 'prototype' profile: 1 wall, 1 top, 1 bottom, lightning infill at 10%,
    no supports. Author measured 45% time / 75% filament savings on a
    real part.

  - 'draft' profile: even more aggressive. 0.28 mm layer height, 0% infill,
    no top, 1 wall. "Going in the bin after I look at it" speed. Don't use
    for fit-checking against another part.

  - 'production' profile: a sane reset. 3 walls, 5 top / 3 bottom, 15%
    gyroid, supports re-enabled. Use to undo a previous --apply or to
    sanity-check what the production defaults look like.

  - Custom: pass --json overrides.json with your own {key: value} dict.

Usage:
    python apply_test_profile.py input.3mf --profile prototype
        -> writes input-prototype.3mf next to input.3mf

    python apply_test_profile.py input.3mf --profile draft -o out.3mf
    python apply_test_profile.py input.3mf --json my_overrides.json

The script preserves [Content_Types].xml, _rels/.rels, all mesh files,
and per-object settings. It DROPS any sliced G-code and checksum files
(plate_*.gcode, plate_*.gcode.md5) so Bambu Studio re-slices on open
with the new settings.

Caveat: a build123d-generated .3mf (from make_template.py) won't have a
project_settings.config to mutate. This script will fail with a clear
error in that case. Save a .3mf through Bambu Studio first to get a
profile-bearing template.
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
import tempfile
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

# ---------------------------------------------------------------------------
# Built-in profiles
# ---------------------------------------------------------------------------
# Each value is the literal STRING that goes into <setting key="...">value</setting>.
# Bambu Studio uses string values for everything, including booleans ("0"/"1")
# and percentages ("15%").

PROFILES: dict[str, dict[str, str]] = {
    # Prototype: How-To Geek's recipe. Fit-check quality, fast iteration.
    "prototype": {
        "wall_loops":            "1",
        "top_shell_layers":      "1",
        "bottom_shell_layers":   "1",
        "sparse_infill_pattern": "lightning",
        "sparse_infill_density": "10%",
        "enable_support":        "0",
    },

    # Draft: cosmetic-only, going-in-the-bin speed. NOT fit-check accurate.
    "draft": {
        "layer_height":          "0.28",
        "wall_loops":            "1",
        "top_shell_layers":      "0",
        "bottom_shell_layers":   "1",
        "sparse_infill_density": "0%",
        "sparse_infill_pattern": "lightning",
        "enable_support":        "0",
    },

    # Production: Bambu Studio defaults for a sturdy mechanical part.
    # Use this to UNDO a previous --apply, or to baseline-compare.
    "production": {
        "wall_loops":            "3",
        "top_shell_layers":      "5",
        "bottom_shell_layers":   "3",
        "sparse_infill_pattern": "gyroid",
        "sparse_infill_density": "15%",
        "enable_support":        "0",
    },
}

PROJECT_SETTINGS_PATH = "Metadata/project_settings.config"


def load_overrides(profile: str | None, json_path: Path | None) -> dict[str, str]:
    if profile and json_path:
        sys.exit("Pick --profile OR --json, not both.")
    if json_path:
        data = json.loads(json_path.read_text(encoding="utf-8"))
        return {str(k): str(v) for k, v in data.items()}
    if profile:
        if profile not in PROFILES:
            sys.exit(f"Unknown profile {profile!r}. "
                     f"Valid: {sorted(PROFILES)} or --json <file>")
        return PROFILES[profile]
    sys.exit("Specify --profile <name> or --json <file>.")


def apply_overrides(in_3mf: Path, out_3mf: Path,
                    overrides: dict[str, str], *,
                    keep_gcode: bool = False) -> dict[str, tuple[str, str]]:
    """Mutate `in_3mf` -> `out_3mf` applying the overrides.

    Returns a dict {key: (before, after)} of the changes actually made,
    so the caller can print a diff for the user.
    """
    if not in_3mf.is_file():
        sys.exit(f"Input file not found: {in_3mf}")

    changes: dict[str, tuple[str, str]] = {}

    with tempfile.TemporaryDirectory() as td:
        ext = Path(td)
        with zipfile.ZipFile(in_3mf) as z:
            z.extractall(ext)

        cfg = ext / PROJECT_SETTINGS_PATH
        if not cfg.is_file():
            sys.exit(
                f"{PROJECT_SETTINGS_PATH} not found inside {in_3mf}.\n"
                "This .3mf doesn't carry a Bambu Studio profile (it was "
                "probably exported by build123d / trimesh / Fusion). Save "
                "the file through Bambu Studio once with your tuned profile "
                "and use THAT as the input."
            )

        # Mutate
        tree = ET.parse(cfg)
        root = tree.getroot()
        for key, new_val in overrides.items():
            el = root.find(f".//setting[@key='{key}']")
            if el is None:
                # Setting absent: append it. Bambu Studio tolerates extras.
                el = ET.SubElement(root, "setting", attrib={"key": key})
                el.text = new_val
                changes[key] = ("(absent)", new_val)
            else:
                old_val = el.text or ""
                if old_val != new_val:
                    changes[key] = (old_val, new_val)
                el.text = new_val
        tree.write(cfg, encoding="utf-8", xml_declaration=True)

        # Drop sliced G-code unless explicitly preserved (their checksums
        # would mismatch the new settings).
        if not keep_gcode:
            for stale in (ext / "Metadata").glob("plate_*.gcode*"):
                stale.unlink()

        # Re-zip preserving structure.
        out_3mf.parent.mkdir(parents=True, exist_ok=True)
        if out_3mf.exists():
            out_3mf.unlink()
        with zipfile.ZipFile(out_3mf, "w", zipfile.ZIP_DEFLATED) as z:
            for path in sorted(ext.rglob("*")):
                if path.is_file():
                    z.write(path, path.relative_to(ext))

    return changes


def derive_output_path(in_3mf: Path, profile: str | None,
                       json_path: Path | None) -> Path:
    if profile:
        suffix = profile
    elif json_path:
        suffix = json_path.stem
    else:
        suffix = "modified"
    return in_3mf.with_name(f"{in_3mf.stem}-{suffix}{in_3mf.suffix}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("input", type=Path, help="Input .3mf file (project save).")
    parser.add_argument("--profile", choices=sorted(PROFILES),
                        help="Built-in profile name.")
    parser.add_argument("--json", type=Path,
                        help="Path to a JSON file with custom {key: value} overrides.")
    parser.add_argument("-o", "--out", type=Path,
                        help="Output path (default: <input>-<profile>.3mf).")
    parser.add_argument("--keep-gcode", action="store_true",
                        help="Preserve sliced G-code in the output. "
                             "Bambu Studio may reject mismatched checksums; "
                             "use only if you know what you're doing.")
    args = parser.parse_args()

    overrides = load_overrides(args.profile, args.json)
    out_path = args.out or derive_output_path(args.input, args.profile, args.json)

    print(f"Input:    {args.input}")
    print(f"Output:   {out_path}")
    if args.profile:
        print(f"Profile:  {args.profile} ({len(overrides)} settings)")
    else:
        print(f"Custom:   {args.json} ({len(overrides)} settings)")
    print()

    changes = apply_overrides(args.input, out_path, overrides,
                              keep_gcode=args.keep_gcode)

    if not changes:
        print("(No settings changed \u2014 the input already matches this profile.)")
    else:
        print("Settings changed:")
        for key, (before, after) in changes.items():
            print(f"  {key:<28}  {before!r:>14}  \u2192  {after!r}")
    if not args.keep_gcode:
        print()
        print("Note: dropped any plate_*.gcode files. Bambu Studio will "
              "re-slice on open with the new settings.")
    print(f"\nDone: {out_path}  ({out_path.stat().st_size / 1024:.1f} KB)")


if __name__ == "__main__":
    main()
