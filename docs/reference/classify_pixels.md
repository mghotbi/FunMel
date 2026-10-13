# Classify pixels into peripheral targets, central partner and surrounding zone

This step solves the core problem of confrontation plates: grey fungal
colonies, the whitish bacterial colony and the yellowish halo overlap in
brightness but not in *colour and texture*.

## Usage

``` r
classify_pixels(
  plate,
  layout = plate_layout(),
  classifier = NULL,
  posterior_smooth_mm = 0.15,
  context_mm = 0.5,
  max_em_pixels = 60000L
)
```

## Arguments

- plate:

  A plate processed by
  [`model_background()`](https://mghotbi.github.io/FunMel/reference/model_background.md).

- layout:

  A
  [`plate_layout()`](https://mghotbi.github.io/FunMel/reference/plate_layout.md).

- classifier:

  Optional `funmel_classifier` from
  [`train_classifier()`](https://mghotbi.github.io/FunMel/reference/train_classifier.md).

- posterior_smooth_mm:

  Smoothing of class posteriors for confident pixels (mm).

- context_mm:

  Neighbourhood (mm) from which low-confidence (faint) pixels borrow
  their class.

- max_em_pixels:

  Maximum number of pixels used to fit the mixture.

## Value

The plate with element `classes`: an integer matrix (0 agar/outside, 1
fungus, 2 bacteria, 3 halo, 4 other) and the fitted model.

## Details

**Features** (per object pixel, after flat-field correction and light
Gaussian smoothing). The colour difference to the agar of the *same*
plate, \\(\Delta L^\*, \Delta a^\*, \Delta b^\*)\\, is split into its
magnitude \\\log \Delta E\\ and its direction (unit vector). A
diffusible pigment at decreasing concentration moves the colour along a
fixed direction from the agar towards the pigment colour, so the faint
fringe of a halo shares the direction of its core, while grey fungal
tissue points along the achromatic \\L^\*\\ axis at every melanization
level. The fifth feature is texture, the log local standard deviation of
\\L^\*\\ in a 0.4 mm window (wrinkled hyphal colonies vs. smooth
bacterial growth). Referencing colour to the agar of the same plate also
cancels most white-balance differences between photographs.

**Class model.** Each class has a bivariate Gaussian for (\\\log \Delta
E\\, texture) and a mean colour *direction* with an isotropic spread.
The direction likelihood of every pixel is widened by its own
noise-induced uncertainty \\(\sigma\_{noise} / \Delta E)^2\\, so faint
pixels (colony margins, halo fringe) are not forced into a class by
noise (a heteroscedastic, measurement-error-aware mixture).

The halo is a *diffusion zone*: pigment concentration, and hence colour
magnitude, decays continuously with distance from the bacterium. Its
magnitude likelihood is therefore uniform in \\\log \Delta E\\ up to its
core level (with a Gaussian fall-off above), so the faint outer fringe
is as plausible a halo pixel as the saturated core.

**Unsupervised model (default).** A mixture with one component per class
is fitted by EM (Dempster, Laird & Rubin 1977). The EM is *initialised
from the plate layout*: pixels near the expected fungal inoculation
points seed the fungus class, pixels at the centre seed the bacterium,
and pixels in the annulus between them seed the halo. The components
therefore keep their biological meaning, and the halo class is dropped
automatically when the bacterium produces no halo (its colour direction
must differ from that of the fungus by \> 12 degrees).

**Supervised model (optional).** Pass a classifier from
[`train_classifier()`](https://mghotbi.github.io/FunMel/reference/train_classifier.md)
(Gaussian / quadratic discriminant model built from pixels you
annotated), which is recommended when a new bacterium-fungus pair has
unusual colours.

**Spatial regularisation.** Class posteriors are smoothed before the
maximum-a-posteriori decision (a fast approximation of a Markov random
field prior). Each pixel gets a confidence \\c = 1 / (1 + d^2 / 0.01)\\
from its direction uncertainty \\d^2\\; its final posterior is \\c\\ x
(posterior smoothed at `posterior_smooth_mm`) + \\(1 - c)\\ x
(confidence-weighted posterior of its neighbourhood at `context_mm`).
Faint pixels such as the fading fringe of a halo thus take the class of
the confident tissue they belong to, instead of being mistaken for pale
fungal margin. Pixels far from every class (Mahalanobis distance above
the \\1 - 10^{-6}\\ quantile of \\\chi^2_4\\) are labelled `"other"`
(dust, bubbles, contaminants) and never measured.

## Examples

``` r
sim <- simulate_plate(width = 300, height = 400, seed = 4)
p <- read_plate(sim$image) |> detect_plate() |> model_background()
p <- classify_pixels(p, plate_layout())
table(p$classes$map)
#> 
#>     0     1     2     3 
#> 91861 12795  1722 13622 
```
