# Finalize saved measurements after reviewing metadata and image masks

Reuses measurements; no photograph needs to be processed again. This
function records user review, not automatic biological validation. All
included plates must have metadata_confirmed and qc_pass explicitly TRUE
in the metadata.

## Usage

``` r
finalize_analysis(result, metadata, ...)
```

## Arguments

- result:

  Batch result returned by analyze_plates(), possibly read from RDS.

- metadata:

  Reviewed metadata with one row per plate, metadata_confirmed and
  qc_pass logical columns. Use FALSE for a plate that requires
  correction; do not mark it TRUE merely to obtain a coefficient.

- ...:

  Arguments forwarded to assess_experiment().

## Value

Updated batch result, including matched coefficients and assessment.
