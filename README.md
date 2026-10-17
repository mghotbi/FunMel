# FunMel <img src="man/figures/logo.png" align="right" height="139" alt="FunMel hex logo" />

**From fungal confrontation photographs to matched-control results.**

FunMel measures the colour, shape and melanization index of approximately round
*Zymoseptoria tritici* colonies surrounding another fungus. It separates central
fungal tissue and hyphal growth from the target colonies. The outlines can be
irregular; photographs do not establish species identity.

Melanization index (MI) is `100 - CIELAB L*`. Larger values mean darker tissue.
This is an image-darkness proxy, not a direct measurement of melanin concentration.

## Install

```r
install.packages("remotes")
remotes::install_github("mghotbi/FunMel")
library(FunMel)
```

Restart R before updating a loaded package. R >= 4.1 and a compilation toolchain
are required: Xcode Command Line Tools on macOS, matching Rtools on Windows,
or R development tools and ImageMagick development libraries on Linux.
To install the local vignette:

```r
remotes::install_github("mghotbi/FunMel", build_vignettes = TRUE,
                        dependencies = TRUE)
vignette("FunMel", package = "FunMel")
```

## Start here: prepare, run, finish

**No approval columns need to be edited.** FunMel prints review reminders and
proceeds automatically with valid metadata. Check experimental assignments
before processing and inspect image QC before interpreting results. Missing
labels, unmatched controls and failed images still need correction.

### 1. Prepare a photograph folder or ZIP

```r
project <- prepare_experiment(file.choose(), "FunMel_project")
# Select a ZIP, or replace file.choose() with a photograph-folder path.
project$metadata_file
```

Use a new project folder. The ZIP may contain nested batches and repeated image
basenames; relative paths distinguish files. With folders such as
`batch_1/control/`, `batch_1/fungus_A/`, `batch_2/control/` and
`batch_2/fungus_B/`, the package proposes matching sets and treatment labels.
Only explicit `control` or `controls` folders denote controls by default.
Use `control_folders="C"` only if that label really means control.
A unique `plate_metadata.csv` inside the input is read automatically; alternatively
supply one combined table through `metadata=`. Ambiguous file names do not
establish biological assignments.

Review the printed metadata file. **Only correct missing or inaccurate information;
there is no confirmation switch.** One row represents one independent plate.

| Column | Meaning |
|---|---|
| `file`, `relative_file`, `plate_id` | Photograph provenance and unique plate identity; preserve these |
| `set_id` | Treatment plates and their own relevant control plates |
| `treatment` | `control` or the actual treatment name |
| `centre_model` | `none` for a control; `fungus` for a central fungus |
| `partner_type` | Biological partner, normally `none` or `fungus` |
| `day`, `medium`, `zymo_strain` | Recorded context; complete and constant within each matching set |
| `replicate`, `fungus`, `photo_date`, `notes` | Experimental annotations |

For one control and three treatment plates, use four rows sharing a `set_id`.
Enter the control once. Four colonies and any sampling spots on a plate are
subsamples, not independent biological replicates. Repeated photographs of the
same plate are repeated observations, not additional independent plates.

### 2. Run image analysis

```r
dish_mm <- 90  # Replace with the verified outer dish diameter (mm).
result <- run_experiment(project, dish_diameter_mm = dish_mm,
                         n_spots = 5, spot_radius_mm = 0.4)
result$analysis_status
result$failed
```

The diameter is a numeric value, not an interactive prompt. Omit `n_spots` and
`spot_radius_mm` for whole-colony measurements alone. Spots are additional,
deterministically distributed, non-overlapping circular ROIs inside eligible
colony tissue. Five spots are requested per colony in this example; they are
not five independent replicates. Choose settings consistently across plates.
If spots cannot fit, `spot_status="insufficient_space"`; achieved ROIs remain
available, but the requested spot summary is unavailable.

Inspect the QC PNGs in `project$qc_dir`: target masks, central fungal tissue and
hyphae, spot outlines, scale, shadows, illumination and warnings. Correct
measurement problems before interpretation. Informative reminders do not require
approval-flag edits. Any failed photographs must be resolved before finalization.

### 3. Finish and export

```r
reviewed <- finish_experiment(project)
reviewed$melanization_coefficient
```

This reads the saved measurements and metadata and exports tables, an assessment
RDS and a comparison figure in PDF, SVG and 600-dpi PNG. It does not reprocess
photographs or require manual approval. Unconfirmed image QC warns and remains
recorded; it does not block the default workflow or automatically approve plates.
Different recorded days, strains and media are reported separately in context
folders; consult `context_index.csv` when present.

## Understand the outputs

The coefficient is `mean(treatment plate MI) / mean(matching control plate MI)`.
A plate's MI is the equally weighted mean of its target-colony `MI_mean` values.
Each treatment uses only controls in its own set. Values above 1 indicate a
darker treatment mean, not a fold increase in melanin concentration.

`colonies.csv` contains whole-colony `MI_min`, `MI_mean` and `MI_max` for eligible
interior pixels. `spots.csv` contains individual ROI measurements.
`MI_spot_mean/min/max` summarize the individual **spot means**, not pixel extrema
or confidence limits. Default coefficients use whole-colony MI. A prespecified
spot-based descriptive analysis can use:

```r
spot_coefficients <- melanization_coefficient(reviewed, response = "MI_spot_mean")
```

Keep spot and whole-colony results labelled separately. Independent plates are
the biological units. One control per set permits descriptive ratios but does
not meet the built-in replicated-cell inference guard. Supported mixed-model
assessment uses `lme4`/`lmerTest`, plate-level random effects and matched-set
contrasts. Check design, residuals, convergence and singularity before using
p-values. The comparison figure shows between-plate SD, not confidence intervals;
ratio SD does not include uncertainty in a shared control mean.

## Follow eight real photographs

The vignette and `examples/walkthrough_14_days.R` use eight original photographs:
A60_2 and B20_2, each with one control and three confrontation plates.
No separate download is required. The combined metadata is supplied, so the
example runs without approval-column editing. Verify labels against laboratory
records and use the actual dish diameter for scientific interpretation.

```r
vignette("FunMel", package = "FunMel")
```

The original JPEGs are unchanged. Precomputed tables are illustrative results
with a 90-mm scale, `max_dim=1200`, five 0.4-mm-radius spots and `n_boot=20`;
see `extdata/14_day_example/PROVENANCE.md`. They are not biological ground truth.

## Try one simulated image

```r
sim <- simulate_plate(width = 400, height = 400, seed = 1)
x <- analyze_plate(sim$image, n_spots = 3, spot_radius_mm = 0.4,
                   n_boot = 20, verbose = FALSE)
plot_qc(x)
x$colonies[, c("colony_id", "MI_min", "MI_mean", "MI_max", "MI_spot_mean")]
```

For a control, use `layout=plate_layout(centre="none")`. Advanced functions
`analyze_plate()`, `analyze_plates()`, `make_metadata()`, `prepare_photo_archive()`
and `finalize_analysis()` remain available.

## Metadata, calibration and recovery

Additional metadata columns retain their names and values. The complete table
is exported as `metadata_used.csv`. A collision with a measured column receives
a `metadata_` prefix in measurement tables; original names remain in the full
metadata. An optional recorded `qc_pass` field starts FALSE and is reset for a
new image run, but never needs editing for default calculations.

Entirely unrecorded day/strain/medium columns may remain blank. Once recorded,
complete them for all plates and keep each context constant within a set.
Do not hide differing experimental contexts to pool incompatible plates.

`flat_field=TRUE` requests spatial illumination correction. It can be withheld
when fitted gains saturate: inspect `flat_field_applied`, `flat_field_status`
and warnings in `plates.csv`. Withholding does not establish adequate lighting;
matched ratios do not guarantee cancellation of illumination bias.

Resume an existing project without recreating it:

```r
project <- readRDS(file.choose()) # Select the existing project.rds.
reviewed <- finish_experiment(project)
```

Printing a stored path does not prove that the file exists. Restore missing
metadata from the saved edited CSV, or point `project$metadata_file` to that
existing file and save the updated project object. Download cloud files locally.
Use `result$failed` to resolve image errors. The package never invents missing
experimental assignments. Reanalysis is necessary if image-layout settings change.

The separate [algorithm overview](https://github.com/mghotbi/FunMel/blob/HEAD/inst/guides/FunMel_overview.md)
describes the methods and comparison with ImageJ/Fiji. Manual ROI tools remain
useful for difficult boundaries; no universal accuracy or speed superiority is claimed.
