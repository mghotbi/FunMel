# Model the agar background and correct uneven illumination

Estimates the colour of the agar, removes the spatial illumination
gradient (vignetting, oblique light) by flat-field correction, and flags
every dish pixel that differs significantly from agar.

## Usage

``` r
model_background(
  plate,
  flat_field = TRUE,
  degree = 2L,
  max_clipped_fraction = 0.02,
  min_delta_e = 3,
  texture_z = 4,
  shadow_texture_z = 2.5,
  smooth_mm = 0.08,
  feature_smooth_mm = 0.25,
  reference = NULL,
  reference_lab = c(50, 0, 0)
)
```

## Arguments

- plate:

  A `funmel_plate` with a detected dish.

- flat_field:

  Logical; request the illumination correction. The fitted correction is
  applied only if it passes the `max_clipped_fraction` check below;
  `plate$bg$flat_field` records whether it was actually applied.

- degree:

  Polynomial degree of the illumination surface (1 or 2).

- max_clipped_fraction:

  Largest fraction of dish pixels whose fitted gain may reach the
  correction limits (0.5x-2x) before the whole correction is judged
  degenerate and withheld. A correction that saturates over a
  substantial part of the dish is not a mild illumination gradient: it
  rescales colonies by a position-dependent factor and shifts MI by
  several units, which would be read as a melanization difference. This
  can occur with reflections or strongly nonuniform backgrounds. Gain
  saturation alone does not identify the cause of the failed fit. Use
  `Inf` to apply the correction unconditionally, and inspect
  `flat_field_status` in the plate summary either way.

- min_delta_e:

  Minimum CIE76 colour difference from agar for a pixel to be considered
  object.

- texture_z:

  Robust z-score of log local texture (relative to agar) above which a
  pixel is an object even if its colour matches the agar.

- shadow_texture_z:

  Pixels darker than agar, with agar-like chromaticity and texture z
  below this value are cast shadows of raised colonies and are excluded
  (set `-Inf` to disable).

- smooth_mm:

  Gaussian smoothing (mm) of colour used for object detection
  (measurements always use unsmoothed pixels).

- feature_smooth_mm:

  Gaussian smoothing (mm) of colour used as classification feature;
  averages over hyphal ridges and valleys so a wrinkled colony is
  described by its mean colour.

- reference:

  Optional exposure / white-balance reference applied after flat-field
  correction: a grey-card region `c(x, y, r)` in relative image
  coordinates (see
  [`calibrate_color()`](https://mghotbi.github.io/FunMel/reference/calibrate_color.md)),
  or `"agar"` to scale the image so that the agar takes the colour
  `reference_lab` (only valid when all plates use the same medium batch
  and the agar is not tinted).

- reference_lab:

  Known CIELAB of the reference.

## Value

The plate with corrected `rgb`/`lab` and an element `bg`.

## Details

**1. Agar colour by mode seeking.** The agar is the most frequent colour
inside the dish even on crowded confrontation plates, because agar
pixels are concentrated in colour space while colonies, bacteria and
hyphae are spread along gradients. The mode of the (smoothed)
\\L^\*a^\*b^\*\\ distribution of low-texture pixels is found with a
coarse 3-D histogram followed by mean-shift refinement (Comaniciu & Meer
2002). It works on dark and on light agar.

**2. Flat-field correction.** Illumination acts multiplicatively on
*linear* light. For each linear RGB channel c a quadratic surface \\\log
I_c(x, y) = \beta_0 + \beta_1 x + \beta_2 y + \beta_3 x^2 + \beta_4 xy +
\beta_5 y^2\\ is fitted to agar pixels with iterative 3-MAD trimming,
and every pixel is multiplied by \\\exp(\hat\ell_c(x_0, y_0) -
\hat\ell_c(x, y))\\, i.e. normalised to the illumination at the dish
centre. Because the correction is estimated from agar *around* the
colonies and applied to the colonies, colony lightness is adjusted for
the fitted spatial surface. This does not prove that remaining lighting
or exposure differences have been removed.

**3. Object detection.** After correction the agar has a spatially
constant colour \\\mu\\ with per-channel robust SD \\\sigma\\ (MAD). A
pixel is *object* (non-agar) if its standardised distance \\D^2 = \sum_c
((x_c - \mu_c)/\sigma_c)^2\\ exceeds the 0.999 quantile of \\\chi^2_3\\
**and** its colour difference exceeds `min_delta_e` (default 3, just
above the ~2.3 just-noticeable difference), so that neither sensor noise
nor imperceptible tints are called objects. In addition, a pixel is
object when its local texture (SD of \\L^\*\\ in a ~0.2 mm window, log
scale) exceeds the agar texture by more than `texture_z` robust standard
deviations: strongly melanized, wrinkled colonies can have almost the
*mean* colour of a dark agar but are far rougher. Cast shadows of raised
colonies (darker than agar, agar-like chromaticity, smooth) are removed
from the objects: under directional light they would otherwise be
counted as melanized tissue on one side of every colony.

## Examples

``` r
sim <- simulate_plate(width = 300, height = 400, seed = 3, vignetting = 0.3)
p <- detect_plate(read_plate(sim$image))
p <- model_background(p)
p$bg$agar_lab
#>          L          a          b 
#> 22.2716888 -0.9644315 -3.8346218 
p$bg$illumination_range_pct
#> [1] 28.25772
```
