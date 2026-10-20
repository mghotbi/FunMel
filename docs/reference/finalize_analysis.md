# Finalize saved measurements after reviewing metadata and image masks

Reuses saved measurements without reprocessing photographs. Valid
experimental metadata proceeds automatically; no metadata approval flags
are required. A reminder asks users to review assignments, masks and
calibration before interpreting results. Computation does not establish
biological validation.

## Usage

``` r
finalize_analysis(result, metadata, ..., require_qc = FALSE)
```

## Arguments

- result:

  Batch result returned by analyze_plates(), possibly read from RDS.

- metadata:

  Metadata with one row per independent plate. User-defined columns are
  retained; review flags do not gate the standard workflow.

- ...:

  Arguments forwarded to assess_experiment().

- require_qc:

  Default FALSE warns and continues with unconfirmed QC. TRUE requires
  every qc_pass flag to be logical TRUE. Review flags are never
  automatically changed to TRUE; calculated results retain their QC
  status.

## Value

Updated batch result. A valid matching design adds coefficients and
assessment. Missing design assignments give comparison_status
awaiting_design; missing target MI gives awaiting_measurement_review.
Measurements remain available with metadata_issues, measurement_issues,
layout_assignments and run_summary diagnostics. No missing MI is imputed
or silently excluded.
