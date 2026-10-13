# Analyse one plate photograph

Runs the complete FunMel pipeline: import, dish detection and scale,
optional colour calibration, flat-field correction, colour/texture pixel
classification, seeded colony separation, measurement and QC.

## Usage

``` r
analyze_plate(
  path,
  layout = plate_layout(),
  id = NULL,
  dish_diameter_mm = 90,
  agar_fraction = 0.88,
  dish = NULL,
  mm_per_px = NULL,
  reference = NULL,
  reference_lab = c(50, 0, 0),
  max_dim = 2000,
  flat_field = TRUE,
  classifier = NULL,
  min_delta_e = 3,
  min_area_mm2 = 0.5,
  min_core_mm = 0.4,
  morph_mm = 0.08,
  edge_criterion = 0.5,
  edge_exclude_mm = 0.1,
  dark_L = NULL,
  n_boot = 200L,
  block_mm = 0.5,
  ring_width_mm = 0.5,
  profile_mode = c("absolute", "relative"),
  n_rings = 10L,
  qc_file = NULL,
  keep_images = TRUE,
  verbose = TRUE
)
```

## Arguments

- path:

  Image file or H x W x 3 sRGB array.

- layout:

  A
  [`plate_layout()`](https://mghotbi.github.io/FunMel/reference/plate_layout.md).
  Use `plate_layout(centre = "none")` for control plates without
  bacteria.

- id:

  Plate identifier (default: file name).

- dish_diameter_mm:

  Outer diameter of the dish (mm); sets the scale.

- agar_fraction:

  Fraction of the dish radius that is analysed.

- dish:

  Optional manual dish circle `c(x, y, r)` in working pixels.

- mm_per_px:

  Optional known scale (mm per working-image pixel); overrides
  `dish_diameter_mm`.

- reference:

  Optional exposure / white-balance reference: a grey-card region
  `c(x, y, r)` in relative image coordinates, or `"agar"`; see
  [`model_background()`](https://mghotbi.github.io/FunMel/reference/model_background.md).

- reference_lab:

  Known CIELAB of the reference.

- max_dim:

  Working resolution (longest side, px).

- flat_field:

  Apply illumination correction (recommended).

- classifier:

  Optional supervised classifier
  ([`train_classifier()`](https://mghotbi.github.io/FunMel/reference/train_classifier.md)).

- min_delta_e:

  Minimum colour difference from agar for objects.

- min_area_mm2, min_core_mm, morph_mm, edge_criterion:

  Segmentation settings, see
  [`segment_colonies()`](https://mghotbi.github.io/FunMel/reference/segment_colonies.md).

- edge_exclude_mm, dark_L, n_boot, block_mm:

  Measurement settings, see
  [`measure_colonies()`](https://mghotbi.github.io/FunMel/reference/measure_colonies.md).

- ring_width_mm, profile_mode, n_rings:

  Profile settings, see
  [`colony_profiles()`](https://mghotbi.github.io/FunMel/reference/colony_profiles.md).

- qc_file:

  Optional path of a PNG quality-control figure.

- keep_images:

  Keep image arrays in the result (needed for
  [`plot_qc()`](https://mghotbi.github.io/FunMel/reference/plot_qc.md)
  later; set `FALSE` in large batches to save memory).

- verbose:

  Print progress.

## Value

An object of class `funmel_result`, a list with

- colonies:

  One row per expected colony
  ([`measure_colonies()`](https://mghotbi.github.io/FunMel/reference/measure_colonies.md)).

- profiles:

  Edge-to-centre profiles
  ([`colony_profiles()`](https://mghotbi.github.io/FunMel/reference/colony_profiles.md)).

- plate_summary:

  One row of plate-level measures and QC.

- plate:

  The processed plate (images and masks) if `keep_images = TRUE`.

- params, warnings:

  Settings used and QC warnings.

## Examples

``` r
sim <- simulate_plate(width = 300, height = 400, seed = 10)
res <- analyze_plate(sim$image, id = "sim10", verbose = FALSE)
res
#> <funmel_result> plate "sim10"
#> • Scale: 0.2393 mm/px; agar L* = 22.2
#> • Colonies detected: 4 / 4; satellites: 1
#> • Central object r = 6.36 mm; surrounding zone outer r = 17.01 mm
#>  colony_id area_mm2 L_mean MI_mean MI_lo MI_hi delta_MI_facing
#>         TL      155   51.2    48.8  48.4  49.1            2.29
#>         TR      156   46.9    53.1  52.7  53.4            2.51
#>         BR      155   40.0    60.0  59.6  60.4            2.73
#>         BL      156   57.7    42.3  42.0  42.6           -2.54
#>  growth_inhibition_pct
#>                  2.450
#>                  0.270
#>                 -0.152
#>                 -7.634
res$colonies[, c("colony_id", "MI_mean", "delta_MI_facing")]
#>    colony_id  MI_mean delta_MI_facing
#> x         TL 48.75743        2.293812
#> x1        TR 53.05115        2.514062
#> x2        BR 59.99747        2.729403
#> x3        BL 42.27137       -2.539792
if (FALSE) { # \dontrun{
res <- analyze_plate("plates/2026_05_26_20.JPG", layout = plate_layout())
plot_qc(res)
ctrl <- analyze_plate("plates/2026_05_26_37.JPG",
                      layout = plate_layout(centre = "none"))
} # }
```
