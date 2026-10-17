# Measure colonies: size, shape, melanization and interaction metrics

Measure colonies: size, shape, melanization and interaction metrics

## Usage

``` r
measure_colonies(
  plate,
  edge_exclude_mm = 0.1,
  dark_L = NULL,
  n_boot = 200L,
  block_mm = 0.5,
  seed = 1L
)
```

## Arguments

- plate:

  A plate processed by
  [`segment_colonies()`](https://mghotbi.github.io/FunMel/reference/segment_colonies.md).

- edge_exclude_mm:

  Width of the colony margin excluded from colour statistics (mm).

- dark_L:

  Optional \\L^\*\\ threshold for `dark_fraction`.

- n_boot:

  Bootstrap replicates for confidence intervals.

- block_mm:

  Side of the square spatial blocks for the bootstrap (mm).

- seed:

  RNG seed for the bootstrap.

  The clearer alias `radial_asymmetry_pct` equals the legacy
  `growth_inhibition_pct`. Both describe toward/away radial asymmetry,
  not inhibition referenced to a separate control plate.

## Value

Data frame with one row per expected colony.

## Details

### Melanization readouts

All colour statistics use unsmoothed, flat-field-corrected pixels of the
colony *interior*: a rim of `edge_exclude_mm` is removed (mixed
colony/agar pixels, "partial-volume" effect) and specular highlights
(\\L^\* \> 97\\ or a saturated channel) are excluded.

- `L_mean`, `L_median`, `L_sd`, `L_q05`...`L_q95`:

  CIE lightness \\L^\*\\ (0 black - 100 white). An approximately
  perceptual lightness coordinate; it is not a direct pigment
  concentration.

- `MI_mean`, `MI_median`:

  Melanization index \\MI = 100 - L^\*\\. Higher = darker; attribution
  to melanin requires validation. Linear in \\L^\*\\, so MI differences
  are comparable across the whole range.

- `MI_min`, `MI_max`:

  Observed minimum and maximum eligible-pixel MI; these are
  noise-sensitive extrema, not confidence limits.

- `MI_lo`, `MI_hi`:

  Nominal 95 % spatial block-bootstrap interval of `MI_mean`,
  conditional on image and segmentation; this does not represent
  variation between biological replicate plates.

- `gray_imagej`:

  Mean of (R + G + B) / 3 on the 0-255 scale, an unweighted RGB channel
  average (ImageJ conversion depends on its weighting settings), for
  comparison with earlier *Z. tritici* melanization studies that report
  mean grey values.

- `a_mean`, `b_mean`, `chroma_mean`, `hue_deg`:

  Chromatic components; DHN-melanin is dark brown-black, so strongly
  melanized colonies drift towards low \\L^\*\\ with slightly positive
  \\a^\*, b^\*\\ (brown), whereas "grey" colonies are nearly neutral.

- `dark_fraction`:

  Fraction of interior pixels with \\L^\* \<\\ `dark_L` (only if
  `dark_L` is given). Choose `dark_L` from control plates, e.g. the 10th
  percentile of control colonies.

### Interaction readouts

The *interaction direction* of a colony is the vector from its centroid
to the centroid of the central partner (confrontations), or to the dish
centre (controls, so that the same metrics give the null expectation).

- `MI_facing`, `MI_away`, `delta_MI_facing`:

  MI of the colony half facing the central partner (angle \< 90 deg to
  the interaction direction) and of the opposite half, and their
  difference. A localized melanization response towards the central
  partner gives `delta_MI_facing > 0`.

- `R_toward_mm`, `R_away_mm`, `growth_inhibition_pct`:

  Colony radius from the centroid towards / away from the central
  partner (maximum radius in a +/- 20 deg sector), and the percent
  inhibition of radial growth 100 (R_away - R_toward) / R_away, a
  within-colony radial asymmetry index. Despite the legacy column name,
  this is not control-referenced percent inhibition of radial growth.

- `gap_bacteria_mm`, `gap_hyphae_mm`:

  Shortest edge-to-edge distance from the colony to the central partner
  and its peripheral hyphal extent (0 = contact).

## Examples

``` r
sim <- simulate_plate(width = 300, height = 400, seed = 7)
res <- analyze_plate(sim$image, verbose = FALSE)
res$colonies[, c("colony_id", "area_mm2", "L_mean", "MI_mean")]
#>    colony_id area_mm2   L_mean  MI_mean
#> x         TL 154.4311 52.30603 47.69397
#> x1        TR 154.9466 46.53839 53.46161
#> x2        BR 154.5456 41.47310 58.52690
#> x3        BL 154.8893 58.45871 41.54129
```
