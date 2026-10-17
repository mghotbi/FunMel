# FunMel

**From fungal confrontation photographs to reviewed, matched-control
results.**

FunMel measures the darkness and shape of four approximately round
*Zymoseptoria tritici* colonies growing around another fungus. It
separates the central fungal core and peripheral hyphal growth from the
target colonies. The measured outlines may be irregular. Image masks
require visual review; the software does not identify organisms from a
photograph.

Melanization index (MI) is `100 - CIELAB L*`: larger values mean darker
tissue. It is an image-darkness proxy, not a direct measurement of
melanin concentration.

## Install

``` r

install.packages("remotes")
remotes::install_github("mghotbi/FunMel")
library(FunMel)
```

R \>= 4.1 and a source compilation toolchain are required: Xcode Command
Line Tools on macOS, the matching Rtools on Windows, or R development
tools and ImageMagick development libraries on Linux. Restart R before
updating a loaded package. To install the local vignette as well:

``` r

remotes::install_github("mghotbi/FunMel",
                        build_vignettes = TRUE, dependencies = TRUE)
vignette("FunMel", package = "FunMel")
```

## Start here: three functions, two review steps

Use a ZIP or a photograph folder. A convenient folder layout is:

| Relative folder     | Meaning                                      |
|---------------------|----------------------------------------------|
| `batch_1/control/`  | Controls for batch 1                         |
| `batch_1/fungus_A/` | Treatment plates matched to batch 1 controls |
| `batch_2/control/`  | Controls for batch 2                         |
| `batch_2/fungus_B/` | Treatment plates matched to batch 2 controls |

Put the plate photographs inside those folders. The ZIP may contain an
additional enclosing folder. Repeated photograph basenames in different
folders are supported; relative paths distinguish them.

### 1. Prepare and verify the metadata

``` r

# Select a photograph ZIP; use a new output folder for each project.
project <- prepare_experiment(file.choose(), "FunMel_project")
# Alternatively: prepare_experiment("path/to/photos", "FunMel_project")
project$metadata_file
```

Open `FunMel_project/plate_metadata.csv` in a spreadsheet editor. There
is one row per independent plate. Folder names propose labels but never
establish biological identity. Check each row before analysis:

| Column | What to record |
|----|----|
| `file`, `relative_file` | Photograph provenance; preserve these paths |
| `plate_id` | Unique plate identifier; preserve it through review |
| `set_id` | Matching group: treatment plates and only their relevant controls |
| `treatment` | `control` for controls; a consistent name for each treatment |
| `centre_model` | `none` for controls; `fungus` for a central fungus |
| `partner_type` | `none` or `fungus` for this assay |
| `day`, `zymo_strain`, `medium` | Add these context columns when relevant; complete and constant within each set |
| `metadata_confirmed` | Logical `TRUE` after verifying experimental assignments |
| `qc_pass` | Leave `FALSE` until reviewing the image-analysis QC |

Each set must contain at least one control and one treatment. If folder
names are ambiguous, treatment labels remain blank until completed. Only
explicit `control` or `controls` folders are recognized by default. Use
`control_folders="C"` only when that folder label actually denotes
controls. An explicit `metadata=` table can also be supplied at
preparation.

**One control plus three treatment plates:** enter four rows with the
same `set_id`. The control appears once and is shared by all three
treatment plates. Four Zymo colonies on one plate are subsamples, not
four independent replicates.

Analyze different days or strains as distinct matching sets and record
their values explicitly in the `day` or `zymo_strain` columns. Folder
paths alone are not context variables for statistical assessment.
Repeated photographs of the same plate are repeated observations, not
new independent plates.

### 2. Analyze and review the images

``` r

result <- run_experiment(project, dish_diameter_mm = 90)
```

Whole-colony MI uses every eligible interior pixel after excluding the
colony rim and specular/saturated pixels. No fixed number of spots is
needed for this measurement. `MI_min`, `MI_mean` and `MI_max` describe
those eligible pixels.

To request circular sampling spots as **additional** measurements:

``` r

result <- run_experiment(project, dish_diameter_mm = 90,
                         n_spots = 5, spot_radius_mm = 0.4)
```

Choose one of the two calls above. The spot call still retains
whole-colony MI. Each target receives up to the chosen number of
non-overlapping circular ROIs, placed by a deterministic spatial-spread
algorithm. Inspect their outlines in the QC figures. Use the same count,
radius and image settings across compared plates. If the placement
algorithm cannot fit the spots, `spot_status="insufficient_space"` and
the colony spot summary is unavailable; partial ROIs remain in
`spots.csv` for review. Do not shrink spots on selected colonies simply
to obtain a preferred result.

Inspect every PNG in `FunMel_project/qc/`. Check target outlines,
central fungal core and hyphal tissue, illumination/calibration and
warnings. Correct problems before interpretation. Set
`metadata_confirmed=TRUE` only after verifying the experimental
assignments. You may record `qc_pass=TRUE` for acceptable reviewed
plates, but this is optional by default. Unconfirmed image QC warns and
continues without changing flags or dropping plates. A new analysis
resets `qc_pass=FALSE` so the new masks can be reviewed. Use logical
TRUE/FALSE without quotation marks.

### 3. Finish and export

``` r

reviewed <- finish_experiment(project) # warns and continues if QC is unconfirmed
# Optional strict mode, after recording QC approval:
# reviewed <- finish_experiment(project, require_qc = TRUE)
```

Finalization requires confirmed experimental metadata, exact plate-ID
matching and no unresolved image failures. QC approval is optional by
default: unconfirmed QC warns, remains recorded and is labelled in
figure captions. Use `require_qc=TRUE` to enforce QC approval.
Finalization reuses saved measurements. Different recorded days, strains
and media are assessed separately in indexed context folders; consult
`context_index.csv` when present.

The project contains colony, spot, profile and plate tables, matched
coefficients, an assessment RDS, session information and a
treatment-comparison figure in PDF, SVG and 600-dpi PNG. The figure’s
bars describe plate SD, not confidence intervals. Model estimates and
inferential status are separate outputs.

The default coefficient is:

`mean(treatment plate MI) / mean(matching control plate MI)`

A plate’s MI is the equally weighted mean of its target-colony `MI_mean`
values. Each treatment uses only controls in its own `set_id`. Values
above 1 indicate a darker treatment mean; values below 1 indicate a
lighter mean. Shared controls remain shared. One control plate permits a
descriptive ratio but does not meet the built-in replicated-cell
inference guard. Supported mixed-model inference uses independent plates
with `lme4`/`lmerTest`; spots and pixels do not increase biological
replication. Review diagnostics and the design before interpreting p
values.

### Understand the spot outputs

`spots.csv` contains each ROI’s location, radius, pixel count and MI
minimum, mean and maximum. `colonies.csv` includes `n_spots_requested`,
`n_spots_measured`, `spot_status` and `MI_spot_mean/min/max`. The latter
are the mean, minimum and maximum **of the individual spot means**. They
differ from pixel extrema and from whole-colony `MI_mean`. Neither
minimum/maximum is a CI.

Default coefficients and figures continue to use whole-colony MI. If a
study prespecifies spot-based measurements, calculate its descriptive
coefficients explicitly from the reviewed results:

``` r

spot_coefficients <- melanization_coefficient(
  reviewed, response = "MI_spot_mean"
)
```

Keep spot and whole-colony analyses labeled separately. Do not test spot
ratios as independent replicates; the built-in default assessment uses
whole-colony MI.

## Try a single image without preparing a project

``` r

sim <- simulate_plate(width = 400, height = 400, seed = 1)
x <- analyze_plate(sim$image, n_spots = 3, spot_radius_mm = 0.4,
                   n_boot = 20, verbose = FALSE)
plot_qc(x)
x$colonies[, c("colony_id", "MI_min", "MI_mean", "MI_max", "MI_spot_mean")]
x$spots
```

For an actual control photograph, use
`layout=plate_layout(centre="none")`. The default confrontation layout
has a central fungus. Advanced functions
[`analyze_plate()`](https://mghotbi.github.io/FunMel/reference/analyze_plate.md),
[`analyze_plates()`](https://mghotbi.github.io/FunMel/reference/analyze_plates.md),
[`make_metadata()`](https://mghotbi.github.io/FunMel/reference/make_metadata.md),
[`prepare_photo_archive()`](https://mghotbi.github.io/FunMel/reference/prepare_photo_archive.md)
and
[`finalize_analysis()`](https://mghotbi.github.io/FunMel/reference/finalize_analysis.md)
remain available.

### Metadata columns are preserved

Templates include `file`, `relative_file`, `plate_id`, `set_id`,
`treatment`, `centre_model`, `partner_type`, `fungus`, `zymo_strain`,
`medium`, `day`, `replicate`, `photo_date`, `notes`,
`metadata_confirmed` and `qc_pass`. Experimental values are left blank
when unknown; both review flags start as `FALSE`. Additional
user-defined columns are retained, including their names and values. A
new image-analysis run resets `qc_pass=FALSE`. Finalization warns and
continues with unconfirmed QC by default; `require_qc=TRUE` enforces
approval.

A context column (`day`, `medium` or `zymo_strain`) may be entirely
blank when not recorded. Once any value is entered, complete that column
for all plates and keep it constant within each matching set. Do not
leave a varying context unrecorded to combine incompatible experiments.

The full table is stored in `result$metadata` and exported as
`metadata_used.csv`. Additional fields are also attached to measurement
tables by `plate_id`. If a metadata name conflicts with a measured
column, the measurement is protected and the metadata copy receives a
`metadata_` prefix in that output table. The original names remain
unchanged in the full metadata table.

QC flags remain unchanged unless edited by the user.
`qc_review_status.csv`, coefficient-table QC status and figure captions
identify unconfirmed review. Metadata confirmation and valid matching
controls remain required.

## Follow the included real photographs

The vignette has a numbered walkthrough using eight original photographs
in `extdata/14-days`: prepare the project, verify the combined metadata,
analyse, review every QC image, approve individual plates and export
results. It shows two complete sets (A60_2 and B20_2), with one control
and three treatment plates per set. Verify assignments against
laboratory records before finalization.

``` r

vignette("FunMel", package="FunMel")
# Website: Get started > Follow the real 14-day photographs: step by step
```

The eight original photographs are included without resizing or
recompression. The companion script is at
`system.file("examples", "walkthrough_14_days.R", package="FunMel")`.

## Common questions

- **Where is the metadata?** `project$metadata_file` points to the
  editable CSV.
- **No control or missing labels?** Complete `set_id`, `treatment` and
  `centre_model`; the package does not infer biological identity from
  image colour.
- **Not enough spots?** Review `spot_status`; reduce the requested
  radius/count consistently for the study, then rerun and inspect the
  new QC images.
- **Central hyphae contact Zymo?** Inspect the separation; a photograph
  may not support an unambiguous boundary. Do not approve an unresolved
  mask.
- **QC flags still FALSE?** Review images and metadata, then save the
  CSV before calling
  [`finish_experiment()`](https://mghotbi.github.io/FunMel/reference/finish_experiment.md).
  Do not mark flags TRUE just to suppress an error.
- **Only descriptive statistics?** Insufficient control replication or
  model diagnostics can prevent inference while allowing matched
  descriptive ratios.

## Why use FunMel alongside ImageJ/Fiji?

FunMel links layout-based measurements, batch provenance, own-set
controls, plate-aware assessment and reproducible exports in one R
workflow. ImageJ/Fiji remains useful for manual ROI work and difficult
segmentation. No head-to-head accuracy or speed advantage is claimed.
See [the algorithm
overview](https://github.com/mghotbi/FunMel/blob/HEAD/inst/guides/FunMel_overview.md)
and the **Get started** vignette for details and runnable examples.
