# Sample a chosen number of circular spots within each target colony

Whole-colony MI uses all eligible interior pixels. This optional
measurement instead samples non-overlapping circular ROIs distributed by
a deterministic farthest-point algorithm. The first centre is nearest
the eligible-region centroid; later centres maximize separation. This is
a reproducible spatial sample, not random sampling or a claim that it
represents the entire colony. Placement is greedy, with at most 20,000
candidate centres; a shortage does not prove that an alternative
geometric packing is impossible. ROIs lie entirely within the
edge-excluded, non-specular target mask. Min/max are observed pixel
extremes, not confidence limits. All spots are subsamples of the colony
and plate, never independent biological replicates.

## Usage

``` r
sample_colony_spots(
  result,
  n_spots = 5L,
  spot_radius_mm = 0.5,
  edge_exclude_mm = 0.1
)
```

## Arguments

- result:

  A funmel_result with images kept, or a segmented funmel_plate.

- n_spots:

  Positive integer number of spots requested per target colony.

- spot_radius_mm:

  Radius of each circular ROI, in mm.

- edge_exclude_mm:

  Excluded target-colony rim, in mm.

## Value

A list with spots (one row per achieved ROI) and summary (one row per
expected colony). If the requested ROIs cannot fit, status is
insufficient_space and summary MI_spot_mean/min/max are NA. Achieved
ROIs remain available for inspection. No rim fallback or overlapping ROI
is used.

## Examples

``` r
sim <- simulate_plate(width = 300, height = 400, seed = 7)
res <- analyze_plate(sim$image, n_spots = 3, spot_radius_mm = 0.3,
                     n_boot = 20, verbose = FALSE)
res$spots
#>    plate_id colony_id spot_id x_px y_px spot_radius_mm n_pixels  MI_mean
#> 1     plate        TL       1   91  141            0.3        5 55.07720
#> 2     plate        TL       2  117  160            0.3        5 44.45097
#> 3     plate        TL       3  110  116            0.3        5 44.48034
#> 4     plate        TR       1  210  141            0.3        5 55.74824
#> 5     plate        TR       2  237  158            0.3        5 47.61745
#> 6     plate        TR       3  199  112            0.3        5 53.12037
#> 7     plate        BR       1  210  261            0.3        5 56.53820
#> 8     plate        BR       2  236  240            0.3        5 62.23673
#> 9     plate        BR       3  180  269            0.3        5 49.44015
#> 10    plate        BL       1   91  260            0.3        5 38.74392
#> 11    plate        BL       2   81  229            0.3        5 29.56856
#> 12    plate        BL       3   62  268            0.3        5 37.24147
#>      MI_min   MI_max   L_mean
#> 1  54.10186 56.42071 44.92280
#> 2  42.31956 45.65051 55.54903
#> 3  43.92984 45.22782 55.51966
#> 4  53.54989 57.77523 44.25176
#> 5  46.58615 48.54422 52.38255
#> 6  46.14684 76.55789 46.87963
#> 7  54.02943 59.24222 43.46180
#> 8  58.64282 64.35958 37.76327
#> 9  46.48781 50.70574 50.55985
#> 10 36.83110 40.51480 61.25608
#> 11 27.48947 30.80291 70.43144
#> 12 36.10255 38.75537 62.75853
```
