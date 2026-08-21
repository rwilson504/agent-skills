"""cad_print_3mf.py — mode-aware .3mf export for build123d projects.

Companion to `cad-build123d-general`'s `export_with_reference()` STL helper.
Mirrors the design / test / production EXPORT_MODE workflow into Bambu-ready
.3mf output.

Usage in a project script:

    from cad_print_3mf import export_3mf_for_mode

    # After (or instead of) export_with_reference(part, stl_path, ...)
    export_3mf_for_mode(
        part,
        stl_path=stl_path,
        export_mode=EXPORT_MODE,
        bed_face=BED_FACE,
        axis_ref_block=ref_block_or_None,
    )

The .3mf is written next to the STL with the same stem and `.3mf` extension.
Behaviour by mode:

  - design:     part + axis_ref_block (if provided) added as separate
                objects in the .3mf so a slicer preview shows both.
  - test:       part only (the on-part wall labels from cad-build123d-general
                §8a survive in the mesh; no cube clutter).
  - production: part only.

All modes embed `cad_print_3mf_mode` and related metadata so a human
inspecting the file (or a future tool) can see which export mode produced
it.

This is a v1 BARE 3MF helper — the output has no slicer profile. To get
a profile-bearing print-ready file, drag the bare .3mf onto a template
.3mf in Bambu Studio. (The `print-bambu-3mf` skill, if installed, covers
how to save that template and how to mutate profiles programmatically.)
"""
from __future__ import annotations

from pathlib import Path
from typing import Iterable

from build123d import Mesher


def export_3mf_for_mode(
    part,
    *,
    stl_path: Path,
    export_mode: str,
    bed_face: str | None = None,
    axis_ref_block=None,
    part_number: str | None = None,
    metadata: dict[str, str] | None = None,
) -> Path:
    """Write a mode-aware .3mf next to the STL.

    Args:
        part: build123d Part / Compound / Solid (the printable geometry).
        stl_path: Path to the STL the project is exporting; the .3mf is
            written next to it with the same stem and `.3mf` extension.
        export_mode: "design" / "test" / "production". Controls whether
            the axis ref block is included.
        bed_face: e.g. "-Z". Stored as metadata for downstream consumers.
        axis_ref_block: Optional second Part. Included in design mode;
            ignored otherwise. Pass None outside of design mode.
        part_number: Override for the part_number stored on the main shape.
            Defaults to the STL filename stem.
        metadata: Additional {key: value} pairs to embed. All values are
            stringified.

    Returns:
        Path to the .3mf file written.
    """
    if export_mode not in ("design", "test", "production"):
        raise ValueError(
            f"Unknown export_mode={export_mode!r}; "
            "expected 'design' / 'test' / 'production'."
        )

    out_path = Path(stl_path).with_suffix(".3mf")
    out_path.parent.mkdir(parents=True, exist_ok=True)

    pn = part_number or out_path.stem

    mesher = Mesher()

    # Always add the main part. In design mode, also add the axis ref
    # block as a SEPARATE shape (not a Compound) so Bambu Studio shows
    # them as two distinct objects.
    if export_mode == "design" and axis_ref_block is not None:
        shapes: Iterable = [part, axis_ref_block]
        # Distinct part numbers so they're identifiable in the slicer.
        mesher.add_shape(part, part_number=pn)
        mesher.add_shape(axis_ref_block, part_number=f"{pn}_axis_ref")
    else:
        mesher.add_shape(part, part_number=pn)
        shapes = [part]

    # Embed metadata. All values must be strings.
    base_meta: dict[str, str] = {
        "cad_print_3mf_mode": export_mode,
        "cad_print_3mf_part_number": str(pn),
    }
    if bed_face is not None:
        base_meta["cad_print_3mf_bed_face"] = str(bed_face)
    if metadata:
        for k, v in metadata.items():
            base_meta[str(k)] = str(v)

    for key, value in base_meta.items():
        # Mesher signature: (name_space, name, value, metadata_type, must_preserve)
        # Use a custom namespace and "xs:string" type so any 3MF reader
        # round-trips the values.
        mesher.add_meta_data(
            name_space="cad_print_3mf",
            name=key,
            value=value,
            metadata_type="xs:string",
            must_preserve=True,
        )

    mesher.write(str(out_path))
    return out_path
