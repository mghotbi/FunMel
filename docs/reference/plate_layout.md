# Describe the inoculation layout of a plate

FunMel uses the *known* inoculation geometry as a spatial prior. This is
what makes it possible to separate several cultures that share one dish,
including colonies that touch each other or contact the central fungal
mycelium.

## Usage

``` r
plate_layout(
  n_colonies = 4L,
  radius_frac = 0.45,
  radius_mm = NULL,
  start_deg = -135,
  rotation_deg = 0,
  centre = c("fungus", "none", "bacteria"),
  ids = NULL,
  positions = NULL,
  search_frac = 0.4
)
```

## Arguments

- n_colonies:

  Number of fungal inoculation points placed evenly on a circle (ignored
  if `positions` is given).

- radius_frac:

  Distance of the inoculation points from the dish centre, as a fraction
  of the outer dish radius.

- radius_mm:

  Alternatively, the distance in mm (overrides `radius_frac` once the
  dish scale is known).

- start_deg:

  Angle of the first colony, degrees clockwise from 3 o'clock. The
  default -135 puts the first colony at top-left.

- rotation_deg:

  Extra clockwise rotation of the whole layout.

- centre:

  What is inoculated at the centre: `"bacteria"`, `"none"` or
  `"fungus"`. The fungal path fits separate peripheral-target, central-
  partner and surrounding-zone components; it never adds the central
  partner to the four target colonies. Hyphal masks are image-based
  tissue candidates, not inhibition zones.

- ids:

  Colony identifiers.

- positions:

  Optional data frame with columns `id`, `x_rel`, `y_rel` for arbitrary
  designs.

- search_frac:

  Radius (fraction of the dish radius) around each expected position
  within which the colony core is searched. Colonies are matched to
  expected positions closest-first, one colony per position, so search
  areas may overlap; inoculation points only need to be approximately
  where the layout says.

## Value

An object of class `funmel_layout`.

## Details

Positions are given relative to the dish centre in units of the dish
outer radius, with x increasing to the right and **y increasing
downwards** (image convention). The default reproduces the standard
four-quadrant design: four fungal colonies on the diagonals at 45 % of
the radius (TL = top-left, TR, BR, BL) and, for confrontations, another
fungus in the centre.

Always photograph plates in the same orientation (e.g. a mark on the
dish rim at 12 o'clock) so that colony IDs are reproducible; otherwise
use `rotation_deg`.

## Examples

``` r
plate_layout()                      # 4 Zymoseptoria + central fungus
#> <funmel_layout> 4 fungal colonies; centre: fungus
#>  id  x_rel  y_rel
#>  TL -0.318 -0.318
#>  TR  0.318 -0.318
#>  BR  0.318  0.318
#>  BL -0.318  0.318
plate_layout(centre = "none")       # control plate
#> <funmel_layout> 4 fungal colonies; centre: none
#>  id  x_rel  y_rel
#>  TL -0.318 -0.318
#>  TR  0.318 -0.318
#>  BR  0.318  0.318
#>  BL -0.318  0.318
plate_layout(n_colonies = 3, ids = c("A", "B", "C"))
#> <funmel_layout> 3 fungal colonies; centre: fungus
#>  id  x_rel  y_rel
#>   A -0.318 -0.318
#>   B  0.435 -0.116
#>   C -0.116  0.435
```
