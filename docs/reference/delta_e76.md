# Colour difference CIE76 (Euclidean distance in L*a*b\*)

Colour difference CIE76 (Euclidean distance in L*a*b\*)

## Usage

``` r
delta_e76(lab1, lab2)
```

## Arguments

- lab1, lab2:

  n x 3 matrices (or vectors of length 3, recycled).

## Value

Numeric vector of \\\Delta E^\*\_{ab}\\; ~2.3 is a just-noticeable
difference (Sharma 2003).

## Examples

``` r
delta_e76(c(50, 0, 0), c(52, 1, -1))
#> [1] 2.44949
```
