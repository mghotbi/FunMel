# Remove position-specific lighting bias from side-specific metrics

Under directional light every raised colony is brighter on the side that
faces the lamp, whatever the treatment. On a fixed copy stand this bias
depends on the colony's position in the frame (TL, TR, BR, BL), so it is
estimated from controls at the same position within each set_id, when
that column is present. Without set_id the supplied table is one legacy
set.

## Usage

``` r
correct_facing_bias(
  colonies,
  control = "control",
  group = "treatment",
  vars = c("delta_MI_facing", "growth_inhibition_pct")
)
```

## Arguments

- colonies:

  Colony table from
  [`analyze_plates()`](https://mghotbi.github.io/FunMel/reference/analyze_plates.md).

- control:

  Value of `group` that marks control plates.

- group:

  Column holding the treatment.

- vars:

  Side-specific columns to correct.

## Value

`colonies` with extra columns `<var>_corrected`.

## Examples

``` r
d <- data.frame(colony_id = rep(c("TL", "TR"), 4),
                treatment = rep(c("control", "bacteria"), each = 4),
                delta_MI_facing = c(4, -8, 5, -7, 9, -2, 10, -3))
correct_facing_bias(d)
#>   colony_id treatment delta_MI_facing delta_MI_facing_corrected
#> 1        TL   control               4                      -0.5
#> 2        TR   control              -8                      -0.5
#> 3        TL   control               5                       0.5
#> 4        TR   control              -7                       0.5
#> 5        TL  bacteria               9                       4.5
#> 6        TR  bacteria              -2                       5.5
#> 7        TL  bacteria              10                       5.5
#> 8        TR  bacteria              -3                       4.5
```
