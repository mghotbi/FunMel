# Create a metadata template for matched treatment-control sets

Writes one row per image. Fill set_id, treatment and centre_model before
analysis. All controls use the treatment label control; set_id decides
which controls belong to which treatments. The same treatment label
across sets must represent the same intervention. See
[`validate_metadata()`](https://mghotbi.github.io/FunMel/reference/validate_metadata.md).
Review flags metadata_confirmed and qc_pass start at FALSE. Set them to
TRUE only after verifying experimental assignments and inspecting plate
QC plots. Metadata confirmation is required for finalization. Image QC
warns by default; require_qc=TRUE can enforce explicit QC approval.
Standard optional fields (fungus, zymo_strain, medium, day, replicate,
photo_date and notes) are included even when unrecorded. Custom columns
supplied through extra are retained.

## Usage

``` r
make_metadata(
  dir,
  file = file.path(dir, "plate_metadata.csv"),
  treatment = NA_character_,
  set_id = NA_character_,
  patterns = NULL,
  extra = list(),
  overwrite = FALSE,
  recursive = FALSE
)
```

## Arguments

- dir:

  Folder with photographs.

- file:

  Output CSV path.

- treatment:

  Optional default treatment label.

- set_id:

  Optional default set ID; leave missing for multiple sets.

- patterns:

  Optional named regular expressions for treatment labels.

- extra:

  Named list of additional metadata columns.

- overwrite:

  Whether to replace an existing template.

- recursive:

  Search nested image folders. Relative paths distinguish repeated
  basenames.

## Value

Metadata invisibly, also written as CSV. Missing fields must be filled.
