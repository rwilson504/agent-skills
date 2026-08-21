# `print-bambu-3mf` companion scripts

Reference scripts that live alongside the [`print-bambu-3mf`](../SKILL.md)
skill. These implement the patterns documented there as runnable CLIs.

## Why scripts live in the skill folder

Per the workflow agreed in this conversation, these are *reference
implementations* that belong with the format documentation, not with any
one project. They're tracked by the lint script and the agent picks them
up automatically when the skill loads.

If a future project (e.g. an automated test-print harness) starts using
them every day, promote them to a top-level `tools/` folder.

## Scripts

### `make_template.py`

Generates a baseline `.3mf` from scratch using `build123d` (so you don't
need `trimesh` or any other optional dependency). Outputs a 20 mm
calibration cube as `templates/calibration_cube_20mm.3mf`.

```sh
python make_template.py                 # default 20mm cube to default path
python make_template.py --size 30 --out templates/cube30.3mf
```

**Important caveat:** the resulting `.3mf` is a **bare** 3MF — geometry
only, no Bambu Studio profile metadata. Bambu Studio opens it but treats
it as a fresh import. For real print work, you want a "profile-bearing"
template:

1. Open Bambu Studio
2. Load any model (drag in a STL or use this script's output)
3. Tune the slicer settings to your preferred defaults
4. **Save Project** as `templates/<your-name>.3mf`
5. Use THAT file as the input to `apply_test_profile.py`

This script exists for bootstrapping and for round-trip-validation use.

### `apply_test_profile.py`

The actual workhorse. Takes a Bambu-Studio-saved `.3mf` and mutates
`Metadata/project_settings.config` to switch print modes:

```sh
# Apply the prototype profile (1 wall, lightning infill, no supports)
python apply_test_profile.py path/to/my_part.3mf --profile prototype
# -> writes my_part-prototype.3mf next to the input

# Custom profile via JSON overrides
python apply_test_profile.py path/to/my_part.3mf --json overrides.json

# Custom output path
python apply_test_profile.py path/to/my_part.3mf --profile draft -o test.3mf
```

Built-in profiles:

| Profile | Use case | Source |
|---|---|---|
| `prototype` | Fit-checking, fast iteration. ~45% time / ~75% filament savings vs production. | [How-To Geek slicer tricks](https://www.howtogeek.com/slicer-tricks-i-use-to-speed-up-3d-printing-prototypes/) |
| `draft` | "Going in the bin after I look at it" speed. Not fit-check accurate. | More aggressive than `prototype` |
| `production` | Reset back to sturdy defaults. Use to undo a previous `--apply`. | Bambu Studio defaults |

The script always **drops sliced G-code** from the output (`plate_*.gcode`
and `plate_*.gcode.md5`) so Bambu Studio re-slices on open with the new
settings. Use `--keep-gcode` to override (you almost never want this — the
checksum will mismatch and the printer will reject the file).

### Custom override JSON format

A `{key: value}` dict where keys are `project_settings.config` setting
names and values are strings (Bambu Studio stores everything as strings,
including booleans `"0"/"1"` and percentages `"15%"`).

```json
{
  "wall_loops":            "2",
  "sparse_infill_pattern": "lightning",
  "sparse_infill_density": "5%",
  "enable_support":        "0",
  "support_threshold_angle": "45"
}
```

See the SKILL.md "`project_settings.config` — the important keys" section
for what's available.

## Common workflow

```sh
# 1. One-time: save a "production-baseline" .3mf from Bambu Studio with
#    your preferred quality profile. Drop it under templates/.

# 2. Per print iteration:
python apply_test_profile.py templates/my_baseline.3mf --profile prototype \
    -o cad/harbor-freight-bins/exports/hf_bin-prototype.3mf

# 3. Open the output .3mf in Bambu Studio. It re-slices automatically.
#    Hit Print. Iterate.

# 4. When the design is final, run with --profile production to get the
#    reset baseline back, or just open the original templates file.
```
