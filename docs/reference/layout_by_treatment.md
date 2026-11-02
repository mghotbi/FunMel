# Choose a segmentation layout from one metadata row

The four approximately round target colonies occupy the standard
diagonal inoculation positions. Their measured boundaries are not forced
into circles. centre_model is a computational recipe, not organism
identification. For fungal confrontations, use centre_model=fungus so
the central fungus is returned separately from the four target colonies
and from bacterial outputs.

## Usage

``` r
layout_by_treatment(row, ..., default_centre = "fungus")
```

## Arguments

- row:

  One metadata row with optional treatment and centre_model. Optional
  numeric rotation_deg, radius_frac, radius_mm, search_frac, start_deg
  and n_colonies columns customize the layout per image. Explicit ...
  takes priority.

- ...:

  Other
  [`plate_layout()`](https://mghotbi.github.io/FunMel/reference/plate_layout.md)
  arguments, e.g. radius_mm or positions.

- default_centre:

  Layout for an unlabeled row without a centre_model. Default fungus;
  use none for control-only images. Explicit per-row layouts and
  identified controls take precedence. This never assigns a treatment
  label.

## Value

A layout. Controls use centre=none. Explicit centre_model is respected.
