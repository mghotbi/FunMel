# Propose boundaries for difficult bright or dark colonies

Click-guided, local lightness segmentation for the four peripheral
targets. This creates a proposal for visual review, not measurements or
an automatic exception to quality control. Use manual overrides when an
edge is ambiguous.

## Usage

``` r
suggest_funmel_polygons(
  path,
  dish_diameter_mm,
  centre = c("fungus", "none"),
  dish = NULL,
  seeds = NULL,
  radius_px = NULL,
  polarity = "auto",
  min_contrast = 3,
  fraction = 0.35,
  polygons = list(),
  exclusions = list(),
  max_dim = 1200,
  boundary = c("outer_extent", "seed_component")
)

# S3 method for class 'funmel_boundary_proposal'
plot(x, ...)
```

## Arguments

- path:

  Original photograph.

- dish_diameter_mm:

  Verified outer dish diameter in millimetres.

- centre:

  Central partner model, fungus or none.

- dish:

  Outer rim circle c(x,y,r) in working pixels; NULL requests three
  clicks.

- seeds:

  Four-row x/y matrix with row names TL, TR, BR, BL. NULL requests one
  click per target. Seeds are in the resized working image, not original
  pixels.

- radius_px:

  Search radius, one number or a named vector for all four targets. The
  outer 20 percent estimates local agar lightness. Default is 0.20 times
  the dish radius. Keep other colonies, rim and writing outside this
  region.

- polarity:

  One of auto, bright, dark, or a named vector for all targets.

- min_contrast:

  Minimum lightness difference from local agar, default 3.

- fraction:

  Fraction of seed contrast used as the threshold, between 0 and 1.

- polygons:

  Optional named manual overrides. A central_fungus outline is required
  for confrontations; if absent it is collected interactively.

- exclusions:

  List of x/y polygons marking artifacts. They are excluded from
  seed/background estimation and detection. This does not reconstruct
  hidden tissue or modify the photograph.

- max_dim:

  Maximum working-image dimension.

- boundary:

  outer_extent (default) proposes the outermost closed candidate
  enclosing the target seed, including its interior. seed_component uses
  only the connected candidate containing the seed. Both require visual
  review; use a manual outline for open rims, mixed organisms or
  uncertain boundaries.

- x:

  Boundary proposal to display.

- ...:

  Reserved for plotting extensions.

## Value

A funmel_boundary_proposal containing polygons, image geometry and
per-target detection diagnostics. Failed targets have no polygon and
must be supplied manually. plot() displays outlines for review. No
measurements are calculated. Use recover_funmel_plate() with the
reviewed polygons.

## Details

Local brightness is used only to propose geometry. The original
photograph is retained for measurement; existing explicit calibration
settings still apply when running recovery. Automatic mode chooses
bright/dark from the seed and surrounding agar; it does not establish
biological identity. The central fungus is outlined independently,
including its visible fringe, and is not inferred from the bright plug.
Mask contact with the search limit is rejected. A radius is a search
window, never a forced circular boundary.
