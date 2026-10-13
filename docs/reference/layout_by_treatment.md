# Choose a segmentation layout from one metadata row

The four approximately round target colonies occupy the standard
diagonal inoculation positions. Their measured boundaries are not forced
into circles. centre_model is a computational recipe, not organism
identification. For fungal confrontations, use centre_model=fungus so
the central fungus is returned separately from the four target colonies
and from bacterial outputs.

## Usage

``` r
layout_by_treatment(row, ...)
```

## Arguments

- row:

  One metadata row with treatment and optional centre_model. Optional
  numeric rotation_deg, radius_frac, radius_mm, search_frac, start_deg
  and n_colonies columns customize the layout per image. Explicit ...
  takes priority.

- ...:

  Other
  [`plate_layout()`](https://mghotbi.github.io/FunMel/reference/plate_layout.md)
  arguments, e.g. radius_mm or positions.

## Value

A layout. Controls use centre=none. Explicit centre_model is respected.
