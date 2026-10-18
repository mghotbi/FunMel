# Plot plate-level darkness and matched melanization coefficients

A two-panel descriptive figure. Panel A shows independent plate MI means
and control means within each matching set. Panel B shows treatment
plate ratios and the set-specific ratio of means. Bars show descriptive
between-plate SD, never confidence intervals. Single-plate SD is
unavailable. Ratio SD conditions on the shared control mean and does not
quantify its uncertainty. Controls shown on multiple rows within a set
are shared, not new replicates.

## Usage

``` r
plot_treatment_comparison(
  colonies,
  control = "control",
  by = NULL,
  preview = FALSE,
  labels = NULL,
  file = NULL,
  width = 7.2,
  height = NULL,
  palette = NULL,
  require_qc = FALSE,
  caption = c("none", "brief", "full")
)
```

## Arguments

- colonies:

  Colony table, batch result, project object, current project folder,
  project.rds or saved analysis RDS. Projects use current metadata;
  directly selected analysis files use their stored metadata snapshot.

- control:

  Control treatment label.

- by:

  Additional matching columns passed to melanization_coefficient().

- preview:

  TRUE labels the figure as a provisional preview. No metadata approval
  flags are required in either mode. Unconfirmed image QC warns by
  default and is labelled in the caption.

- labels:

  Optional named character vector of treatment display names.

- file:

  Optional output prefix. Writes vector PDF and SVG and 600-dpi PNG.

- width, height:

  Export dimensions in inches. Height defaults to row count.

- palette:

  Optional named vector of treatment colours. Controls always use dark
  outlined squares; treatments use filled circles.

- require_qc:

  Default FALSE warns on unconfirmed recorded QC. TRUE requires every
  included plate to have qc_pass=TRUE.

- caption:

  Text beneath the figure: none (default), brief, or full. The full
  explanation remains in the FunMel_caption attribute and is exported
  separately as \_caption.txt. QC warnings and statistical safeguards
  remain.

## Value

A ggplot object, invisibly when exported. Colours and typography can be
edited using standard ggplot2 methods. Match the target journal's size
and caption requirements before submission. The attribute
`FunMel_statistics` contains the plotted means, SDs, counts and
descriptive differences. Export also writes a `_statistics.csv`
companion table.
