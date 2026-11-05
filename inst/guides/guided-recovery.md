# Optional recovery for difficult FunMel photographs

This development version adds centre-guided boundary proposals. Existing
`analyze_plate()` and `run_experiment()` defaults are unchanged.

## Interactive use in RStudio

```r
library(FunMel)
photo <- file.choose()  # original photograph
# Replace this with the measured OUTER dish diameter, in millimetres.
diameter <- 90

proposal <- suggest_funmel_polygons(
  photo, dish_diameter_mm = diameter, centre = "fungus",
  polarity = "auto", max_dim = 1200
)
plot(proposal)
proposal$guidance$diagnostics
```

Click three widely separated outer-rim points, then one point inside each
peripheral target (TL, TR, BR, BL). Trace the central fungal boundary separately,
including its visible fringe, then finish with Esc/right-click.

Cyan lines are **proposed**, not accepted biological boundaries. Orange is the
central outline. A failed target will be absent from the overlay; inspect the
diagnostic message. If any proposal is wrong, use the existing manual recovery:

```r
fixed <- recover_funmel_plate(
  photo, dish_diameter_mm = diameter, centre = "fungus",
  dish = proposal$dish, max_dim = proposal$max_dim,
  output_dir = "FunMel_manual_recovery"
)
```

If **all** proposed outlines match visible tissue, accept them explicitly:

```r
fixed <- recover_funmel_plate(
  photo, dish_diameter_mm = diameter, centre = proposal$centre,
  dish = proposal$dish, max_dim = proposal$max_dim,
  polygons = proposal$polygons,
  output_dir = "FunMel_guided_recovery"
)
```

Both output folders must be new. Inspect `recovered_QC.png` before using results.
If comparison requires uncorrected colour, pass `flat_field = FALSE` explicitly,
using the same calibration policy across the experiment. This feature does not
change the package's existing flat-field default.

## Per-colony settings and manual exceptions

`polarity` may be `"bright"`, `"dark"`, or `"auto"`, or a vector such as:

```r
c(TL = "bright", TR = "dark", BR = "auto", BL = "auto")
```

`radius_px` is one number or a named vector in **working-image pixels**. Its
outer 20% must contain representative agar; the target must fit in the inner
80%. The radius is a search region, not an assigned colony size. Boundary
contact, inadequate contrast and excluded artifacts cause diagnostic failures.
Adjust it only when the visible tissue and local agar support that choice.

For scripted runs, supply `dish`, a four-row `seeds` matrix with row names
TL/TR/BR/BL and x/y columns, and `polygons$central_fungus` for a confrontation.
Coordinates use the resized, oriented image returned by `read_plate()` with the
same `max_dim`; x goes right and y goes down. `polygons` can also contain manual
peripheral outlines. `exclusions` accepts a list of artifact polygons.
Exclusions do not reconstruct tissue hidden by glare or writing.

To replace a failed proposal using known reviewed vertices:

```r
proposal$polygons$TL <- cbind(x = c(...), y = c(...))  # actual vertices required
```

This example is a template, not executable coordinates. Changed target polygons
are recorded as manual overrides on recovery. Do not invent outlines for tissue
that cannot be resolved. For images where brightness is uninformative, manual
outlines remain the appropriate fallback; no automatic colour-polarity rule
can establish organism identity.

## Reproduce and reintegrate

Recovery saves the original image checksum, resolution, dish geometry, polygon
vertices, seeds, thresholds, exclusions and detection diagnostics in
`annotation.rds`. It also exports proposal method/polarity in `colonies.csv`.
The photograph is not recoloured by proposal generation. Existing measurement
calibration and quality checks run when the reviewed geometry is measured.

Use `fixed$annotation` in `analyze_plate(annotation = ...)` or the existing
project `corrections` list keyed by the **exact metadata plate ID**. Keep the
same image, `max_dim`, dish diameter and centre model. Replace the previous
measurement for that biological plate; do not add a recovery as a replicate.

The central whole-extent polygon does not separate plug, dense core and hyphae;
subregion measurements remain unavailable. These settings are explicit image
analysis exceptions, not exemptions from experimental replication or QC.
