# Convert CIE L*a*b\* to sRGB

Inverse of
[`srgb_to_lab()`](https://mghotbi.github.io/FunMel/reference/srgb_to_lab.md);
out-of-gamut values are clipped to \[0, 1\].

## Usage

``` r
lab_to_srgb(lab)
```

## Arguments

- lab:

  Numeric n x 3 matrix (L, a, b) or H x W x 3 array.

## Value

sRGB values in \[0, 1\], same shape as input.

## Examples

``` r
lab_to_srgb(cbind(L = 50, a = 0, b = 0))
#>           [,1]      [,2]      [,3]
#> [1,] 0.4663266 0.4663266 0.4663266
```
