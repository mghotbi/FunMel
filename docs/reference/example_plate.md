# Paths to the example plate photographs shipped with FunMel

Two representative original photographs from the bundled eight-image
14-day dataset (four target colonies per dish):

- `"confrontation"`:

  four colonies around a central interacting fungus with spreading
  hyphal growth (2026_10_02_99_38.JPG).

- `"control"`:

  four colonies without an interacting partner (2026_10_02_99_41.JPG).

## Usage

``` r
example_plate(type = c("confrontation", "control", "all"))
```

## Arguments

- type:

  `"confrontation"`, `"control"` or `"all"`.

## Value

File path(s).

## Examples

``` r
example_plate("control")
#>                                                                                                                                                  control 
#> "/private/var/folders/f1/f8pqw4_n4y90tlykbbhy3ztm0000gn/T/RtmpVEPw2F/temp_libpath4334741d4bfc/FunMel/extdata/14-days/A60_2_14_days/2026_10_02_99_41.JPG" 
# \donttest{
res <- analyze_plate(example_plate("control"), layout = plate_layout(centre = "none"))
#> ℹ Reading image
#> ℹ Detecting dish
#> ℹ Dish r = 650 px, 0.0692 mm/px
#> ℹ Modelling agar background and illumination
#> ℹ Classifying target colonies, central core and hyphal growth
#> ℹ Separating colonies
#> ℹ Measuring
#> Warning: Fitted pre-correction illumination range 139 % (not residual error); inspect
#> correction diagnostics and QC.
#> Warning: Flat-field gains reached correction limits for > 1 % of dish pixels; inspect
#> masks and calibration.
#> Warning: Remaining fitted-agar spatial variation exceeds 30 %; review illumination
#> correction.
# }
```
