# Reproducible synthetic matched-set experiment for learning the workflow

Three sets, each with control, fungus_A and fungus_B; three independent
plates per cell and four target colonies per plate. This is synthetic
data, not an experimental result. True treatment MI differences are 8
and 15.

## Usage

``` r
example_experiment(seed = 42L)
```

## Arguments

- seed:

  Reproducible RNG seed.

## Value

List containing metadata and colonies. No image files are created.
