# Read a plate photograph

Imports a plate image (JPEG, PNG, TIFF, HEIC ... anything ImageMagick
reads), applies the EXIF orientation, optionally down-samples it to a
working resolution and converts it to CIELAB.

## Usage

``` r
read_plate(path, max_dim = 2000, id = NULL)
```

## Arguments

- path:

  Path to an image file, **or** a numeric H x W x 3 array with sRGB
  values in \[0, 1\] (e.g. from
  [`simulate_plate()`](https://mghotbi.github.io/FunMel/reference/simulate_plate.md)).

- max_dim:

  Maximum size (px) of the longest image side used for analysis. Default
  2000.

- id:

  Optional plate identifier; defaults to the file name without
  extension.

## Value

An object of class `funmel_plate`: a list with

- rgb:

  H x W x 3 array of sRGB values in \[0, 1\].

- lab:

  H x W x 3 array of CIELAB values.

- id, path:

  Identifier and source path.

- original_dim:

  Width and height of the file (px).

- resize_factor:

  Working px per original px.

- clipped_fraction:

  Fraction of pixels with a channel at 255.

## Details

**Working resolution.** Segmentation and colour statistics are computed
on an image whose longest side is at most `max_dim` pixels. For a 90 mm
dish photographed so that it fills the frame, `max_dim = 2000` gives
roughly 0.05 mm per pixel. Resolution affects segmentation, boundaries
and colour summaries; evaluate stability across resolutions for the
actual images. Down-sampling can reduce fine texture and JPEG artefacts,
but does not guarantee unbiased colony means or a particular measurement
precision. Use `max_dim = Inf` to keep the native resolution.

**Clipping.** Pixels with a channel at 255 may be clipped in the encoded
image; this does not by itself establish sensor saturation. Their
fraction is stored and
[`analyze_plate()`](https://mghotbi.github.io/FunMel/reference/analyze_plate.md)
warns if colonies contain clipped pixels. Photograph with manual
exposure so that the brightest bacterial growth stays below ~ 245.

## See also

[`analyze_plate()`](https://mghotbi.github.io/FunMel/reference/analyze_plate.md),
[`calibrate_color()`](https://mghotbi.github.io/FunMel/reference/calibrate_color.md)

## Examples

``` r
sim <- simulate_plate(width = 300, height = 400, seed = 1)
plate <- read_plate(sim$image, id = "sim1")
plate
#> <funmel_plate> "sim1"
#> • Working size: 300 x 400 px (resize factor 1)
#> • Source: NA
#> • Over-exposed pixels: 0 %
#> • Colour calibration: none
```
