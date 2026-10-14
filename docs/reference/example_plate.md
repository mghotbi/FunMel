# Paths to the example plate photographs shipped with FunMel

Two real photographs of *Zymoseptoria tritici* (four colonies per dish),
reduced to 1000 px for size:

- `"confrontation"`:

  four colonies around a central interacting fungus with spreading
  growth (original: 2026_05_26_20.JPG).

- `"control"`:

  four colonies without an interacting partner (original:
  2026_05_26_37.JPG).

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
#>                                                                                                                        control 
#> "/private/var/folders/f1/f8pqw4_n4y90tlykbbhy3ztm0000gn/T/RtmpVEPw2F/temp_libpath4334518c5e78/FunMel/extdata/zymo_control.jpg" 
# \donttest{
res <- analyze_plate(example_plate("control"), layout = plate_layout(centre = "none"))
#> ℹ Reading image
#> ℹ Detecting dish
#> ℹ Dish r = 475 px, 0.0947 mm/px
#> ℹ Modelling agar background and illumination
#> ℹ Classifying pixels (fungus / bacteria / halo)
#> ℹ Separating colonies
#> ℹ Measuring
#> Warning: Fitted pre-correction illumination range 72 % (not residual error); inspect
#> correction diagnostics and QC.
# }
```
