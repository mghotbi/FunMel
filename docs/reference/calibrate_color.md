# Colour / exposure calibration against a reference patch

Rescales the image in *linear* RGB so that a neutral reference patch
photographed in every image (grey card, white standard, colour-checker
neutral patch) takes its known CIELAB value. This is a diagonal (von
Kries-type) correction: it removes differences in exposure and white
balance between photographs, which is essential for comparing absolute
\\L^\*\\ (melanization) across plates, days and cameras.

## Usage

``` r
calibrate_color(plate, region, ref_lab = c(50, 0, 0))
```

## Arguments

- plate:

  A `funmel_plate`.

- region:

  Reference patch as `c(x, y, r)` in **relative** image coordinates
  (fractions of width, height and of the shorter side), e.g.
  `c(0.08, 0.92, 0.03)` for a card in the bottom-left corner.

- ref_lab:

  Known CIELAB of the patch (default neutral `c(50, 0, 0)`).

## Value

The calibrated `funmel_plate` (with `$calibration` gains).

## Details

A photographic 18 % grey card has \\L^\* \approx 50\\; the neutral 5
patch of an X-Rite ColorChecker Classic has \\L^\* \approx 51\\. The
patch must be evenly lit and not clipped.

## Examples

``` r
sim <- simulate_plate(width = 300, height = 400, seed = 2, exposure = 0.8, grey_card = TRUE)
plate <- read_plate(sim$image)
plate <- calibrate_color(plate, region = sim$truth$grey_card)
#> Warning: 0.44 % of channel values exceed 1 after calibration and were clipped.
```
