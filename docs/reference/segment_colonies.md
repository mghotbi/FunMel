# Separate Zymoseptoria targets and the central fungal colony

Uses known inoculation positions and seeded watershed segmentation to
separate peripheral target colonies from the central partner. The
central fungus includes a dense core and connected peripheral hyphal
growth. These masks are image-based tissue candidates, not inhibition
boundaries. Morphological clean-up removes small fragments; ambiguous
contact between organisms requires review. Target outlines are not
forced into circles.

## Usage

``` r
segment_colonies(
  plate,
  layout = plate_layout(),
  min_area_mm2 = 0.5,
  min_core_mm = 0.4,
  morph_mm = 0.08,
  hyphae_link_mm = 1,
  edge_criterion = 0.5,
  bridge_mm = 0.5
)
```

## Arguments

- plate:

  A plate processed by
  [`classify_pixels()`](https://mghotbi.github.io/FunMel/reference/classify_pixels.md).

- layout:

  The
  [`plate_layout()`](https://mghotbi.github.io/FunMel/reference/plate_layout.md)
  used for classification.

- min_area_mm2:

  Minimum area of a fungal fragment (mm^2).

- min_core_mm:

  Minimum distance from core to colony edge (mm).

- morph_mm:

  Radius of morphological clean-up (mm).

- hyphae_link_mm:

  Maximum connected gap between central core and peripheral growth (mm).

- edge_criterion:

  Sub-pixel-consistent edge placement: within a 3-pixel band inside each
  colony outline, pixels are kept only if their colour difference from
  agar is at least this fraction of the colony's interior median
  ("half-maximum" criterion, unbiased for a blurred step edge). Set 0 to
  disable.

- bridge_mm:

  Opening radius (mm) separating central tissue from narrow connections.

## Value

The plate with element `objects`: a list containing the colony label
matrix (`labels`, values = row index of `colony_table`), `satellites`,
`bacteria`, `central_fungus`, `central_object` and `hyphae` masks,
partner_type and colony_table. hyphae is connected peripheral central
growth candidate; its biological identity and boundary need QC.

## Examples

``` r
sim <- simulate_plate(width = 300, height = 400, seed = 6)
p <- read_plate(sim$image) |> detect_plate() |> model_background() |>
  classify_pixels(plate_layout()) |> segment_colonies(plate_layout())
p$objects$colony_table
#>   id expected_x expected_y core_x core_y core_depth_mm detected
#> 1 TL   90.66136   140.6882     91    139      6.803420     TRUE
#> 2 TR  210.31293   140.6882    211    140      6.510846     TRUE
#> 3 BR  210.31293   260.3398    211    260      6.537189     TRUE
#> 4 BL   90.66136   260.3398     90    260      6.769656     TRUE
#>   segmentation_trim_fraction
#> 1                          0
#> 2                          0
#> 3                          0
#> 4                          0
```
