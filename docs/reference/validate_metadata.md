# Validate the plate-to-set metadata used for matched controls

One row must represent one independent plate photographed once. set_id
defines which treatment and control plates are biologically comparable;
controls are never borrowed from a different set. Use globally unique
plate IDs and unambiguous relative file paths. Repeated photographs of
the same plate are not new replicates.

## Usage

``` r
validate_metadata(
  metadata,
  files = NULL,
  control = "control",
  stage = c("comparison", "measurement")
)
```

## Arguments

- metadata:

  Data frame containing file, plate_id, set_id and treatment. treatment
  must equal control for controls. Other labels identify treatments
  consistently across sets. Optional zymo_strain, medium and day must be
  complete and constant within each set once any value is recorded;
  entirely unrecorded optional columns may remain blank.

- files:

  Optional vector of image paths. Exactly these images must appear once
  in metadata; no unmatched or unused rows are accepted.

- control:

  Exact label used for control plates, default control.

- stage:

  comparison (default) checks the matched experimental design.
  measurement checks image identities only; experimental labels and
  optional context fields may remain blank. Explicit invalid layouts are
  still errors.

## Value

The validated metadata, invisibly. Errors explain invalid mappings.
