# Train a supervised pixel classifier

Fits one multivariate Gaussian per class (quadratic discriminant
analysis) to annotated pixels from one or several plates.

## Usage

``` r
train_classifier(training, equal_priors = TRUE)
```

## Arguments

- training:

  Data frame from
  [`extract_training_pixels()`](https://mghotbi.github.io/FunMel/reference/extract_training_pixels.md)
  (or a list of them, which are row-bound).

- equal_priors:

  Use equal class priors (recommended, because annotation effort rather
  than biology determines class frequencies).

## Value

An object of class `funmel_classifier`.

## Examples

``` r
sim <- simulate_plate(width = 300, height = 400, seed = 5)
p <- read_plate(sim$image) |> detect_plate() |> model_background()
reg <- data.frame(class = c("fungus", "bacteria"),
                  x = c(sim$truth$colonies$x[1], p$dish$x),
                  y = c(sim$truth$colonies$y[1], p$dish$y), r = 8)
clf <- train_classifier(extract_training_pixels(p, reg))
clf
#> <funmel_classifier> Gaussian (QDA) pixel classifier
#> • fungus: n = 201; median |dE| = 33.4, colour direction (L,a,b) = (0.99, 0.05,
#>   0.089)
#> • bacteria: n = 208; median |dE| = 66.7, colour direction (L,a,b) = (0.98,
#>   0.015, 0.21)
```
