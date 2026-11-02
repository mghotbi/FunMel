# Classify target colonies and central fungal growth

Fits a layout-initialized mixture to colour and texture features
relative to agar. Expected target positions seed one component; the
centre seeds the dense partner core and an adjacent region seeds
peripheral central growth. For a fungal partner this peripheral growth
represents candidate hyphal tissue, not inhibition or a diffusible
pigment boundary. All image classes require visual review; the
photograph does not identify species or resolve individual microscopic
hyphae. Similar colours or overlapping cultures may remain ambiguous.
Seeded segmentation separates the target colonies later.

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
target-like tissue, 2 central core, 3 peripheral central growth, 4
other) and the fitted model.

## Details

The internal labels fungus and bacteria denote target-like and
central-core components; the biological partner identity comes from the
layout.

## Examples

``` r
sim <- simulate_plate(width = 300, height = 400, seed = 4)
p <- read_plate(sim$image) |> detect_plate() |> model_background()
p <- classify_pixels(p, plate_layout())
table(p$classes$map)
#> 
#>     0     1     2     3     4 
#> 91861 12415  1749 13869   106 
```
