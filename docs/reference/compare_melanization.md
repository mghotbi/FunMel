# Compare colony measurements while accounting for plates

Preserves the MycoHalo argument names. For MI with set_id metadata this
delegates to
[`assess_experiment()`](https://mghotbi.github.io/FunMel/reference/assess_experiment.md)
so each treatment uses its own control. For other outcomes, or a legacy
single-set table, it fits the original plate-aware comparison with
lmerTest Satterthwaite inference instead of the old ad hoc degrees of
freedom. Multi-set assessment of MI should use assess_experiment()
directly. Never compare shared-denominator MC rows as independent
observations.

## Usage

``` r
compare_melanization(
  colonies,
  response = "MI_mean",
  group = "treatment",
  plate = "plate_id",
  reference = NULL,
  method = c("auto", "mixed", "plate_means"),
  by = NULL,
  control = NULL,
  require_qc = FALSE
)
```

## Arguments

- colonies:

  Colony table.

- response:

  Numeric response column, default MI_mean.

- group:

  Treatment column.

- plate:

  Plate ID column.

- reference:

  Reference treatment; defaults to control if available.

- method:

  auto, mixed, or plate_means. auto chooses mixed with at least three
  plates per group, otherwise an explicit plate-mean model.

- by:

  Extra control-matching columns for matched MI assessment.

- control:

  Optional control label, alias of reference for matched MI.

- require_qc:

  Require explicit image QC approval for matched MI analysis. Default
  FALSE warns on unconfirmed recorded QC.

## Value

A list with model, coefficients, descriptives and status; matched MI
results also contain the complete assessment and matched_coefficients.
