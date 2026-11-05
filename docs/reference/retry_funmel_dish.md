# Recover a plate by reviewing its dish or tissue boundaries

`retry_funmel_dish()` uses three outer-rim clicks to correct the dish
circle and reruns automatic tissue segmentation.
`recover_funmel_plate()` additionally defaults to guided recovery: click
one centre per peripheral target after the three dish-rim clicks. It
proposes target boundaries and central fungal extent without freehand
outlines. All proposed boundaries require visual review. mode='manual'
retains freehand outlines finished with right-click/Esc. These are
optional recovery tools for photographs whose automatic masks fail
visual review.

## Usage

``` r
retry_funmel_dish(
  path,
  dish_diameter_mm,
  centre = c("fungus", "none"),
  dish = NULL,
  output_dir = NULL,
  max_dim = 1200,
  n_spots = 5,
  spot_radius_mm = 0.4,
  n_boot = 200,
  flat_field = TRUE,
  edge_exclude_mm = 0.1
)

recover_funmel_plate(
  path,
  dish_diameter_mm,
  centre = c("fungus", "none"),
  output_dir = NULL,
  max_dim = 1200,
  dish = NULL,
  polygons = NULL,
  n_spots = 5,
  spot_radius_mm = 0.4,
  n_boot = 200,
  flat_field = TRUE,
  edge_exclude_mm = 0.1,
  mode = c("guided", "manual"),
  seeds = NULL
)
```

## Arguments

- path:

  One original photograph, not a ZIP or QC figure.

- dish_diameter_mm:

  Verified outer dish diameter in millimetres.

- centre:

  `"fungus"` for a confrontation, `"none"` for its control.

- dish:

  Optional `c(x,y,r)` in working-image pixels; otherwise click three rim
  points.

- output_dir:

  New output directory; default creates a new folder in the home
  directory.

- max_dim:

  Working image resolution, used again when applying the annotation.

- n_spots, spot_radius_mm:

  Optional spot sampling settings.

- n_boot:

  Number of spatial bootstrap replicates.

- flat_field:

  Whether to request illumination correction.

- edge_exclude_mm:

  Margin excluded from colour measurements in mm.

- polygons:

  Named list of x/y vertex matrices. NULL collects interactive outlines.

- mode:

  guided (default) proposes boundaries from four target-centre clicks;
  manual requests freehand boundaries. Supplied polygons take
  precedence.

- seeds:

  Optional four-row x/y matrix named TL, TR, BR, BL for guided recovery
  without clicks, in working-image pixels.

## Value

A `funmel_result` with `annotation` and `recovery_dir`. New measurement
CSVs, annotation RDS, result RDS, QC PNG and session information are
saved. Guided failures return a boundary proposal with
recovery_status=awaiting_boundaries and saved diagnostics/QC, without
measurements. Successful recovery returns
recovery_status=measured_requires_review; no review flags are approved.
Closing the graphics window during guided selection returns
recovery_status=cancelled with an informative message and no new
measurements.

## Details

Whole central fungal extent includes visible connected hyphal growth.
Dense core and peripheral growth are not separated by manual polygons;
corresponding hyphal-subregion summaries remain unavailable. Invisible
or overlapping tissue cannot be recovered by inventing boundaries.
Corrected diameters depend on a verified physical dish diameter and the
selected outer rim.

The returned `annotation` can be saved and passed to
`analyze_plate(annotation=)` or to
`run_experiment(corrections=list(plate_id=annotation))`. Use the actual
metadata plate ID as the list name. File checksum, resolution, diameter
and centre model must match. Rerunning replaces the saved image-analysis
run; copy the project folder first if the original run must be retained.

## Examples

``` r
if (FALSE) { # \dontrun{
photo <- file.choose() # Select an original JPG.
fixed <- retry_funmel_dish(photo, dish_diameter_mm = 90, centre = "fungus")
# Use 90 only for a measured 90-mm outer rim. If tissue masks remain wrong:
fixed <- recover_funmel_plate(photo, dish_diameter_mm = 90, centre = "fungus")
} # }
```
