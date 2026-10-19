# Create a metadata template for matched treatment-control sets

Writes one row per image. Treatment, set and optional annotations may
remain blank for image measurement. For comparisons, controls use the
treatment label control; set_id decides which controls belong to which
treatments. The same treatment label across sets must represent the same
intervention. See
[`validate_metadata()`](https://mghotbi.github.io/FunMel/reference/validate_metadata.md).
Review experimental assignments and image masks before interpretation.
No metadata approval flag is generated or required. Image QC warns by
default; no review-flag edits are needed for the standard workflow.
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

Metadata invisibly, also written as CSV. Experimental assignments are
needed only for matched comparisons; optional annotations may remain
blank.
