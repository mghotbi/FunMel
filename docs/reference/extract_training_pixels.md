# Extract annotated training pixels

Collects classification features of pixels inside circular regions you
marked on a processed plate (see
[`annotate_plate()`](https://mghotbi.github.io/FunMel/reference/annotate_plate.md)
for interactive annotation).

## Usage

``` r
extract_training_pixels(plate, regions)
```

## Arguments

- plate:

  A plate processed by
  [`model_background()`](https://mghotbi.github.io/FunMel/reference/model_background.md).

- regions:

  Data frame with columns `class` (`"fungus"`, `"bacteria"`, `"hyphae"`
  or aliases `"zymo"`, `"central_partner"`), `x`, `y`, `r` in
  working-image pixels.

## Value

Data frame of features with a `class` column.

## Examples

``` r
sim <- simulate_plate(width = 300, height = 400, seed = 5)
p <- read_plate(sim$image) |> detect_plate() |> model_background()
reg <- data.frame(class = c("fungus", "bacteria"),
                  x = c(sim$truth$colonies$x[1], p$dish$x),
                  y = c(sim$truth$colonies$y[1], p$dish$y), r = 8)
head(extract_training_pixels(p, reg))
#>    class     logE        uL         ua         ub       tex           d2
#> 1 fungus 3.403551 0.9920527 0.04370497 0.11798902 0.7694698 0.0002257734
#> 2 fungus 3.390650 0.9920790 0.04736283 0.11634421 0.6904813 0.0002316745
#> 3 fungus 3.374690 0.9924038 0.05702655 0.10900739 0.8514019 0.0002391888
#> 4 fungus 3.361014 0.9921505 0.07022144 0.10347144 0.6647527 0.0002458217
#> 5 fungus 3.473414 0.9931236 0.06378968 0.09816493 1.0880917 0.0001963320
#> 6 fungus 3.466551 0.9930447 0.04843720 0.10731251 1.1054296 0.0001990453
```
