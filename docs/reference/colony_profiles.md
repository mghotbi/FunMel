# Edge-to-centre melanization profiles

Melanization of a *Z. tritici* colony is not uniform: the growing margin
consists of young, often lighter hyphae, while older central tissue is
darker. Profiles as a function of distance from the colony **edge** (not
from the centroid) follow this age gradient for irregular, lobed
colonies too.

## Usage

``` r
colony_profiles(
  result,
  ring_width_mm = 0.5,
  mode = c("absolute", "relative"),
  n_rings = 10L,
  n_boot = 200L,
  block_mm = 0.5,
  seed = 1L
)
```

## Arguments

- result:

  A `funmel_result` from
  [`analyze_plate()`](https://mghotbi.github.io/FunMel/reference/analyze_plate.md),
  or a plate processed by
  [`segment_colonies()`](https://mghotbi.github.io/FunMel/reference/segment_colonies.md).

- ring_width_mm:

  Ring width in absolute mode (mm).

- mode:

  `"absolute"` or `"relative"`.

- n_rings:

  Number of rings in relative mode.

- n_boot, block_mm, seed:

  Block-bootstrap settings.

## Value

Data frame with one row per colony x ring.

## Details

The Euclidean distance transform of each colony gives every pixel its
distance to the nearest colony edge. Pixels are grouped into rings of
width `ring_width_mm` (absolute mode, comparable between colonies of
different size) or into `n_rings` rings of equal relative depth
(relative mode, comparable in developmental stage).

**Confidence intervals.** Neighbouring pixels are strongly correlated
(same hypha, JPEG blocks, smoothing in the camera), so a naive pixel
bootstrap grossly overstates precision. FunMel uses a *spatial block
bootstrap* (Künsch 1989; Lahiri 2003): the colony is divided into square
blocks of `block_mm`, and whole blocks are resampled with replacement.
Choose `block_mm` at least as large as the wrinkle / texture scale
(default 0.5 mm).

## Examples

``` r
sim <- simulate_plate(width = 300, height = 400, seed = 8, edge_lightening = 8)
res <- analyze_plate(sim$image, verbose = FALSE)
head(res$profiles)
#>   plate_id colony_id ring from_edge_mm to_edge_mm mid_mm  rel_depth n_pixels
#> 1    plate        TL    1          0.0        0.5   0.25 0.03966576      417
#> 2    plate        TL    2          0.5        1.0   0.75 0.11899727      385
#> 3    plate        TL    3          1.0        1.5   1.25 0.19832878      354
#> 4    plate        TL    4          1.5        2.0   1.75 0.27766029      284
#> 5    plate        TL    5          2.0        2.5   2.25 0.35699180      284
#> 6    plate        TL    6          2.5        3.0   2.75 0.43632331      256
#>   n_blocks   L_mean     L_sd  MI_mean    MI_lo    MI_hi
#> 1      151 57.77047 8.906653 42.22953 41.39722 43.17539
#> 2      139 56.53281 4.026146 43.46719 42.91741 44.11771
#> 3      132 53.02993 3.342428 46.97007 46.32998 47.43156
#> 4      104 51.81034 3.691442 48.18966 47.39821 48.83253
#> 5      108 51.14082 4.359298 48.85918 48.03981 49.76930
#> 6       96 49.91173 4.864773 50.08827 49.12574 51.09368
```
