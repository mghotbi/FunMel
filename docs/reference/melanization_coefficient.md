# Calculate the treatment-to-control melanization coefficient

Computes MC = mean treatment plate MI / mean control plate MI. Each
plate MI is the arithmetic mean of its target colony MI_mean values.
Plates are equally weighted, irrespective of pixel counts or numbers of
colonies. This is a ratio of descriptive image-darkness indices, not a
ratio of melanin concentrations. MC \> 1 indicates a darker treatment
mean; MC \< 1 indicates a lighter treatment mean. No significance test
or CI is implied.

## Usage

``` r
melanization_coefficient(
  colonies,
  control = "control",
  group = "treatment",
  plate = "plate_id",
  response = "MI_mean",
  by = NULL,
  exclude_ids = c("centre", "center"),
  na_action = c("error", "omit"),
  set = "set_id",
  require_qc = FALSE
)
```

## Arguments

- colonies:

  Colony data frame returned by
  [`analyze_plates()`](https://mghotbi.github.io/FunMel/reference/analyze_plates.md),
  or such a batch result. Must contain group, plate, colony_id and
  response columns. Only target Zymoseptoria rows should be supplied.
  The standard central partner ID is excluded automatically; specify
  other partner IDs below.

- control:

  Exact group label for the no-interaction control.

- group:

  Treatment column. Every non-control level is compared separately.

- plate:

  Column identifying an independent plate uniquely.

- response:

  Colony-level index column, default MI_mean (range 0 to 100).

- by:

  Optional matching columns, e.g. c("zymo_strain", "day", "medium"). A
  control must exist within each combination. Do not include partner
  identity when controls do not share it. Missing matching values are
  errors.

- exclude_ids:

  Colony identifiers excluded before calculation. Default excludes
  centre and center, used for the central interacting fungus.

- na_action:

  Either error (default) for undetected/nonfinite target colonies or
  omit, which warns and reports excluded counts. A plate with no
  eligible target measurements remains unavailable, not silently
  dropped.

- set:

  Matching-set column, required. Controls are never pooled across sets.

- require_qc:

  Require every included plate to have logical qc_pass=TRUE. Default
  FALSE warns for unconfirmed recorded QC and continues without
  approving or excluding plates. Plain tables without review flags are
  reported as not_recorded. Finalization warns if review is unrecorded.

## Value

List with coefficients (one row per contrast and matching stratum),
plate_means, and settings. Undefined ratios have NA and an explicit
status. Counts distinguish measured target colonies, excluded target
rows and plates. One plate per group permits a descriptive ratio, not
biological inference.

## Examples

``` r
d <- data.frame(plate_id = rep(c("C1", "T1"), each = 4),
                set_id = "set1",
                treatment = rep(c("control", "fungus"), each = 4),
                colony_id = rep(c("TL", "TR", "BR", "BL"), 2),
                MI_mean = c(40, 42, 38, 40, 60, 62, 58, 60))
melanization_coefficient(d)$coefficients  # 60 / 40 = 1.5
#>   set_id treatment control MI_treatment_mean MI_control_mean
#> 1   set1    fungus control                60              40
#>   melanization_coefficient delta_MI n_treatment_plates n_control_plates
#> 1                      1.5       20                  1                1
#>   qc_review_status  control_replication n_treatment_colonies n_control_colonies
#> 1      unconfirmed single_control_plate                    4                  4
#>   n_excluded_target_colonies status                         interpretation
#> 1                          0     ok Higher treatment image-darkness index.
```
