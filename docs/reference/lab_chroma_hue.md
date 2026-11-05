# Chroma and hue angle from a\* and b\*

\\C^\*\_{ab} = \sqrt{a^{\*2} + b^{\*2}}\\, \\h\_{ab} = atan2(b^\*,
a^\*)\\ in degrees \[0, 360). Melanized hyphae have low chroma;
yellow/cream bacterial growth and diffusible pigments have hue angles
near 70-100 deg.

## Usage

``` r
lab_chroma_hue(a, b)
```

## Arguments

- a, b:

  Numeric vectors.

## Value

A list with elements `chroma` and `hue` (degrees).

## Examples

``` r
lab_chroma_hue(a = c(0, 5), b = c(0, 20))
#> $chroma
#> [1]  0.00000 20.61553
#> 
#> $hue
#> [1]  0.00000 75.96376
#> 
```
