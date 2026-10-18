# Finalize a prepared experiment after plate review

Loads saved measurements and metadata without a manual approval gate,
and applies the requested image-QC policy (warning by default), then
computes whole-colony matched coefficients and plate-level assessment,
and exports the comparison figure and tables. Spot summaries stay
separate; use melanization_coefficient(..., response="MI_spot_mean")
explicitly for a prespecified, consistently applied spot-based analysis.

## Usage

``` r
finish_experiment(project, ..., require_qc = FALSE)
```

## Arguments

- project:

  A funmel_project, its current folder, project.rds, or a saved analysis
  beside project.rds. Use load_experiment() after moving a project.

- ...:

  Additional assess_experiment() settings.

- require_qc:

  Default FALSE warns and continues if image QC is unconfirmed. Set TRUE
  to require qc_pass=TRUE before finalization and plotting.

## Value

Reviewed result saved as reviewed_analysis.rds.
