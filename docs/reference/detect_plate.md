# Detect the Petri dish and set the spatial scale

Locates the dish as a circle and derives the pixel-to-millimetre scale
from its known physical diameter.

## Usage

``` r
detect_plate(
  plate,
  dish = NULL,
  dish_diameter_mm = 90,
  agar_fraction = 0.88,
  background = c("auto", "dark", "light"),
  mm_per_px = NULL,
  seed = 1L
)
```

## Arguments

- plate:

  A `funmel_plate` from
  [`read_plate()`](https://mghotbi.github.io/FunMel/reference/read_plate.md).

- dish:

  Optional manual circle `c(x, y, r)` in working-image pixels; skips
  detection.

- dish_diameter_mm:

  Physical outer diameter of the dish (mm).

- agar_fraction:

  Fraction of the outer radius analysed (0-1).

- background:

  `"auto"`, `"dark"` or `"light"` photographic background.

- mm_per_px:

  Optional scale (mm per *working-image* pixel), e.g. from a ruler
  photographed with the plates; overrides `dish_diameter_mm`. Note: if
  you measured the scale on the original file, multiply by
  `1 / plate$resize_factor`.

- seed:

  RNG seed for RANSAC (results are deterministic by default).

## Value

The plate with element `dish`: a list with `x`, `y`, `r_outer`, `r_agar`
(px), `mm_per_px`, `fit_rmse_px`, `arc_coverage` and `method`.

## Details

**Algorithm.**

1.  The background (e.g. black paper) lightness is estimated from the
    four image corners, which lie outside a round dish, as the median
    \\L^\*\\ with a robust (MAD) noise estimate \\\sigma\\.

2.  Pixels brighter than `median + max(6 sigma, 3)` (dark background) or
    darker than `median - max(6 sigma, 3)` (light background) form the
    foreground; it is cleaned by a morphological opening, the largest
    connected component is kept and its holes filled.

3.  Boundary pixels of that region, excluding those on the image border
    (dishes are often cropped at the sides), are fitted with a circle by
    RANSAC (Fischler & Bolles 1981) followed by an algebraic
    least-squares refinement (Kasa 1976) on the inliers. Partial arcs
    are therefore handled correctly.

The analysed agar disk has radius `agar_fraction * r_outer`, which
excludes the dish wall, its reflections and the agar meniscus.

**Scale.** `mm_per_px = dish_diameter_mm / (2 * r_outer)`, where
`r_outer` is the radius of the edge that was *detected*. Depending on
lighting this is the outer rim of the dish or the inner wall / agar
edge, so check the dashed circle in
[`plot_qc()`](https://mghotbi.github.io/FunMel/reference/plot_qc.md)
once for your photo set-up and measure *that* diameter with calipers
(standard "90 mm" dishes are ~88-90 mm outside and ~85-86 mm inside).
Alternatively photograph a ruler and pass `mm_per_px`.

## Examples

``` r
sim <- simulate_plate(width = 300, height = 400, seed = 1)
plate <- detect_plate(read_plate(sim$image))
str(plate$dish)
#> List of 11
#>  $ x               : Named num 150
#>   ..- attr(*, "names")= chr "x"
#>  $ y               : Named num 200
#>   ..- attr(*, "names")= chr "y"
#>  $ r_outer         : num 188
#>  $ r_agar          : num 165
#>  $ mm_per_px       : num 0.239
#>  $ scale_source    : chr "dish diameter"
#>  $ dish_diameter_mm: num 90
#>  $ agar_fraction   : num 0.88
#>  $ fit_rmse_px     : num 0.29
#>  $ arc_coverage    : num 0.611
#>  $ method          : chr "auto"
sim$truth$dish
#>     x     y     r 
#> 150.5 200.5 188.0 
```
