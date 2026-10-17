# Quality-control figure

Always look at the QC figure before trusting numbers. The left panel
shows the (flat-field corrected) photograph with the detected dish, the
analysed agar disk, expected inoculation points and search radii, colony
outlines, the central fungal core and hyphal growth; the right panel
shows the pixel classification, with each separated colony filled in its
own colour (same colours as the outlines on the left). Optional sampling
spots are shown as white numbered circles on the photograph.

## Usage

``` r
plot_qc(
  x,
  panels = c("overlay", "classes"),
  colony_cols = c("#1FB5E0", "#D6336C", "#3FA34D", "#7B5CD6", "#00897B", "#F48FB1",
    "#8D6E63", "#5C6BC0")
)
```

## Arguments

- x:

  A `funmel_result` (computed with `keep_images = TRUE`).

- panels:

  Which panels to draw.

- colony_cols:

  Colours for the colonies.

## Value

Invisibly `x`.

## Examples

``` r
sim <- simulate_plate(width = 300, height = 400, seed = 11)
res <- analyze_plate(sim$image, verbose = FALSE)
plot_qc(res)
```
