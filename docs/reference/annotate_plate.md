# Interactively annotate training regions

Displays the plate and lets you click region centres for each class with
[`graphics::locator()`](https://rdrr.io/r/graphics/locator.html) (finish
each class with Esc / right-click). Works in RStudio's plot pane and in
regular graphics devices.

## Usage

``` r
annotate_plate(
  plate,
  classes = c("zymo", "central_partner", "hyphae"),
  r_mm = 0.5
)
```

## Arguments

- plate:

  A plate processed by
  [`model_background()`](https://mghotbi.github.io/FunMel/reference/model_background.md).

- classes:

  Classes to annotate, in order.

- r_mm:

  Radius of each clicked region (mm).

## Value

Data frame of regions suitable for
[`extract_training_pixels()`](https://mghotbi.github.io/FunMel/reference/extract_training_pixels.md).

## Examples

``` r
if (FALSE) { # \dontrun{
reg <- annotate_plate(p)
clf <- train_classifier(extract_training_pixels(p, reg))
} # }
```
