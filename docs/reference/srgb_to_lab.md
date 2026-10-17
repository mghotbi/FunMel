# Convert sRGB values to CIE 1976 L*a*b\*

Converts gamma-encoded sRGB (IEC 61966-2-1) values in \[0, 1\] to CIELAB
under the D65 reference white (CIE 15:2004).

## Usage

``` r
srgb_to_lab(rgb)
```

## Arguments

- rgb:

  Numeric matrix with three columns (R, G, B) in \[0, 1\], or a H x W x
  3 array.

## Value

Same shape as the input, with channels L, a, b.

## Details

Steps: (1) inverse sRGB companding to linear light, (2) linear RGB -\>
CIE XYZ with the sRGB/D65 primaries matrix, (3) XYZ -\> \\L^\*a^\*b^\*\\
with the CIE cube-root function and its linear segment below
\\(6/29)^3\\.

\\L^\*\\ (0 = black, 100 = diffuse white) is the perceptual lightness
used by FunMel as the primary melanization readout; \\a^\*\\ (green-red)
and \\b^\*\\ (blue-yellow) carry the chromatic information that
separates achromatic melanized hyphae from warm-coloured bacteria, other
fungal tissue.

## Examples

``` r
srgb_to_lab(rbind(c(1, 1, 1), c(0.5, 0.5, 0.5), c(0, 0, 0)))
#>              L             a            b
#> [1,] 100.00000 -1.666667e-05 6.666666e-06
#> [2,]  53.38897 -9.969678e-06 3.987871e-06
#> [3,]   0.00000  0.000000e+00 0.000000e+00
```
