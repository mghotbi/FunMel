# Separate individual colonies, the bacterium and its halo

Turns the pixel classes into labelled objects: one region per expected
fungal colony, the central bacterial colony and its halo.

## Usage

``` r
segment_colonies(
  plate,
  layout = plate_layout(),
  min_area_mm2 = 0.5,
  min_core_mm = 0.4,
  morph_mm = 0.08,
  halo_link_mm = 1,
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

- halo_link_mm:

  Maximum gap between bacterium and halo (mm).

- edge_criterion:

  Sub-pixel-consistent edge placement: within a 3-pixel band inside each
  colony outline, pixels are kept only if their colour difference from
  agar is at least this fraction of the colony's interior median
  ("half-maximum" criterion, unbiased for a blurred step edge). Set 0 to
  disable.

- bridge_mm:

  Opening radius (mm) that separates the bacterial colony from
  bacteria-like tissue connected to it by thin bridges.

## Value

The plate with element `objects`: a list containing the colony label
matrix (`labels`, values = row index of `colony_table`), `satellites`,
`bacteria`, `central_fungus`, `central_object` and `halo` masks,
partner_type and colony_table. halo is a connected colour-zone
candidate; its biological identity and boundary need QC.

## Details

**Fungal mask clean-up.** The fungus class is closed and opened with a
disk of radius `morph_mm` (bridging wrinkle shadows, removing hairline
specks), holes are filled (unclassified craters and highlights inside a
colony belong to the colony) and fragments smaller than `min_area_mm2`
are dropped.

**Seeded separation of cultures.** For each expected inoculation point
(from the
[`plate_layout()`](https://mghotbi.github.io/FunMel/reference/plate_layout.md)),
the colony *core* is the fungal pixel with the largest distance to the
colony edge (maximum of the Euclidean distance transform) within
`search_frac` x dish radius of that point. Cores closer than
`min_core_mm` to the colony edge are rejected (the inoculation failed,
or only a satellite is present) and the colony is reported as not
detected. The cores then seed a marker-controlled watershed on the
negated distance transform, restricted to the fungal mask: each fungal
pixel is assigned to the colony from which it can be reached through
fungal tissue with the least "constriction". Colonies that touch are
split along their neck, and a colony can never claim fungal tissue that
is not connected to it.

**Edge placement.** Colour features are lightly smoothed for robust
classification, which blurs colony outlines outwards by about one pixel.
Outlines are therefore re-placed at the half-contrast position (the
classical 50 % edge criterion for a blurred step edge) using the
unsmoothed colour difference from agar.

**Satellites.** Fungal fragments not connected to any core (e.g. spread
inoculum, a secondary micro-colony next to the main one) are labelled
separately and excluded from colony statistics, but their number and
area are reported as a QC measure.

**Bacterium and halo.** The bacterial colony is the bacteria-class
component closest to the dish centre (holes filled). The halo is the set
of halo-class pixels connected to (within `halo_link_mm` of) the
bacterium, excluding bacterial and fungal pixels.

## Examples

``` r
sim <- simulate_plate(width = 300, height = 400, seed = 6)
p <- read_plate(sim$image) |> detect_plate() |> model_background() |>
  classify_pixels(plate_layout()) |> segment_colonies(plate_layout())
p$objects$colony_table
#>   id expected_x expected_y core_x core_y core_depth_mm detected
#> 1 TL   90.66136   140.6882     91    140      6.853754     TRUE
#> 2 TR  210.31293   140.6882    211    140      6.510846     TRUE
#> 3 BR  210.31293   260.3398    210    260      6.637198     TRUE
#> 4 BL   90.66136   260.3398     90    260      6.769656     TRUE
#>   segmentation_trim_fraction
#> 1                          0
#> 2                          0
#> 3                          0
#> 4                          0
```
