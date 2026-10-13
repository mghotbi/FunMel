# Analyse many plates

Batch wrapper around
[`analyze_plate()`](https://mghotbi.github.io/FunMel/reference/analyze_plate.md)
that never stops on a single bad image: failures are recorded and
reported. A QC figure is written for every plate — inspect them before
using the numbers.

## Usage

``` r
analyze_plates(
  files,
  metadata = NULL,
  layout = plate_layout(),
  qc_dir = NULL,
  ...,
  verbose = TRUE,
  coefficient_control = "control",
  coefficient_by = NULL
)
```

## Arguments

- files:

  Character vector of image paths, or a directory (all JPEG/PNG/TIFF
  files are used).

- metadata:

  Optional design data frame. When supplied, file, plate_id, set_id and
  treatment are required and validated by
  [`validate_metadata()`](https://mghotbi.github.io/FunMel/reference/validate_metadata.md).
  Extra design columns are merged into the output tables.

- layout:

  A single
  [`plate_layout()`](https://mghotbi.github.io/FunMel/reference/plate_layout.md),
  or a function `function(metadata_row)` returning the layout for each
  plate (e.g. `centre = "none"` for controls).

- qc_dir:

  Directory for QC PNGs (created if needed). The default `NULL` writes
  nothing; give a folder, e.g. `qc_dir = "qc"`, to save one QC figure
  per plate.

- ...:

  Further arguments passed to
  [`analyze_plate()`](https://mghotbi.github.io/FunMel/reference/analyze_plate.md).

- verbose:

  Print progress.

- coefficient_control:

  Control treatment label for automatic coefficient calculation; NULL
  disables it. Calculated when treatment metadata exists.

- coefficient_by:

  Matching columns for controls, e.g. strain and day.

## Value

A list of three data frames (`colonies`, `profiles`, `plates`) and a
`failed` data frame. Also contains `melanization_coefficient`
(coefficient table), `coefficient_plate_means` and `coefficient_error`.
Coefficient errors preserve image results but must be resolved before
use.

## Examples

``` r
if (FALSE) { # \dontrun{
meta <- data.frame(file = c("2026_05_26_20.JPG", "2026_05_26_37.JPG"),
                   plate_id = c("t1", "c1"), set_id = "set1",
                   treatment = c("bacteria", "control"))
lay <- function(row) plate_layout(centre = if (row$treatment == "control") "none" else "bacteria")
out <- analyze_plates("plates/", metadata = meta, layout = lay, qc_dir = "qc/")
write.csv(out$colonies, "colonies.csv", row.names = FALSE)
} # }
```
