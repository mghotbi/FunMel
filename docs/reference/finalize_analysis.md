# Finalize saved measurements after reviewing metadata and image masks

Reuses measurements; no photograph needs to be processed again. This
function records user review, not automatic biological validation. All
included plates must have metadata_confirmed explicitly TRUE.
Unconfirmed image QC warns by default; require_qc=TRUE requires
qc_pass=TRUE for every included plate.

## Usage

``` r
finalize_analysis(result, metadata, ..., require_qc = FALSE)
```

## Arguments

- result:

  Batch result returned by analyze_plates(), possibly read from RDS.

- metadata:

  Reviewed metadata with one row per plate, metadata_confirmed and
  optional qc_pass logical columns. Use FALSE for unconfirmed image QC;
  do not mark it TRUE merely to obtain a coefficient.

- ...:

  Arguments forwarded to assess_experiment().

- require_qc:

  Default FALSE warns and continues with unconfirmed QC. TRUE requires
  every qc_pass flag to be logical TRUE. Review flags are never
  automatically changed to TRUE; calculated results retain their QC
  status.

## Value

Updated batch result, including matched coefficients and assessment.
