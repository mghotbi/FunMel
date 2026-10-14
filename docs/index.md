# FunMel

**From confrontation-plate photographs to reviewed colony measurements,
matched melanization coefficients and plate-aware treatment
comparisons.**

FunMel analyzes confrontation-plate photographs, measures target-colony
image darkness and geometry, and links each treatment to the controls
specified in experimental metadata. The default layout supports four
approximately round *Zymoseptoria tritici* colonies surrounding a
central fungal colony and its surrounding halo candidate. Melanization
is measured on the four target *Z. tritici* colonies; the central fungus
and halo are segmented separately and excluded from target-colony MI
summaries. Layouts, dish diameter and segmentation settings can be
adjusted for other supported arrangements. Colony outlines follow
detected regions. Organism identities must be supplied by the
experimenter.

FunMel retains the original MycoHalo function names for compatibility.

## 1. Install and start

Use R \>= 4.1. Source installation requires a compiler: on macOS install
Xcode Command Line Tools; on Windows use the Rtools version matching
your R release; on Linux install an R development toolchain and the
system libraries required by `magick`. Consult [magick
installation](https://docs.ropensci.org/magick/#installing-magick). CRAN
dependencies can normally be installed as binaries on macOS/Windows.

**Restart R before installing over an existing loaded version.**

### Install from GitHub

Install the package from GitHub with `remotes`:

``` r

install.packages("remotes")
remotes::install_github("mghotbi/FunMel")
```

The source repository is
[mghotbi/FunMel](https://github.com/mghotbi/FunMel). The default
installation uses its default branch.

To build and install the vignette locally:

``` r

install.packages(c("remotes", "knitr", "rmarkdown"))
remotes::install_github("mghotbi/FunMel",
                        build_vignettes=TRUE, dependencies=TRUE)
library(FunMel)
vignette("FunMel", package="FunMel")
```

Building vignettes also requires Pandoc, normally provided with RStudio.
GitHub installation requires the source-compilation tools described
above. Private repositories additionally require GitHub authentication.
An optional `ref="TAG_OR_BRANCH"` selects a specific version or
development branch.

### Install from a source archive

``` r

install.packages(c("cli", "magick", "Rcpp", "lme4", "lmerTest", "ggplot2"))
install.packages(file.choose(), repos=NULL, type="source")
# Choose FunMel_0.3.8.tar.gz. Restart R again after installation.
```

``` r

library(FunMel)
packageVersion("FunMel")                 # installed version: 0.3.8
getNamespaceVersion("FunMel")            # loaded version: also 0.3.8
vignette("FunMel", package="FunMel")
help(package="FunMel")
```

With a custom library, pass the same `lib` to installation and `lib.loc`
to [`library()`](https://rdrr.io/r/base/library.html). If the installed
and loaded versions differ, restart R; loading again does not replace an
already loaded namespace.

## 2. Explore the bundled 14-day case study

The bundled case study contains measured data from **20 photographs in
five matched sets**. Each set has **one control plate and three
treatment plates**; each plate contains four target *Z. tritici*
colonies. Metadata therefore has 20 plate rows, while the measurement
table has 80 colony rows. This example illustrates one experimental
design; users should record the actual numbers of independent plates and
matching controls in their own experiments.

| Matching set / source folder | Control image suffix | Three treatment image suffixes |
|----|----|----|
| `A33_1_14_days` | `28` | `29`, `31`, `32` |
| `A60_2_14_days` | `41` | `38`, `39`, `40` |
| `B20_2_14_days` | `45` | `42`, `43`, `44` |
| `B22_2_14_days` | `47` | `48`, `49`, `50` |
| `B37_1_14_days` | `33` | `34`, `36`, `37` |

Case-study filenames follow `2026_10_02_99_<suffix>.JPG`. The generic
analysis functions accept arbitrary image names. The bundled treatment
codes and assignments are provisional; folder names record provenance
rather than confirmed biological identity. The control’s replicate label
is 1; the three treatment plates are labelled 1–3. This does not pair
treatment replicate 1 only to control replicate 1: all three use that
set’s single control as their denominator.

``` r

# Run the bundled measured-data example without downloading photographs:
source(system.file("examples", "04_14_day_case_study.R", package="FunMel"))

# Copy the case-study metadata to inspect its plate-level structure:
file.copy(system.file("examples", "metadata_14_day_case_study.csv",
                      package="FunMel"), "case_study_metadata.csv", overwrite=FALSE)
```

The example prints plate means and exports a **provisional real-data
comparison**. Measurements were obtained from plate-image analysis.
Experimental assignments, segmentation masks and calibration remain
subject to review. The example demonstrates the workflow without marking
these review decisions complete. The archive case-study script can also
process the original photographs.

The coefficient is `mean(MI_T1, MI_T2, MI_T3) / MI_control` within each
set. A single control supports this descriptive calculation. Inferential
assessment has additional replication requirements, described below.
Each independent control plate should be recorded once in the metadata.

### Additional beginner examples

``` r

source(system.file("examples", "01_image_quickstart.R", package="FunMel"))
source(system.file("examples", "02_coefficient_arithmetic.R", package="FunMel"))
source(system.file("examples", "03_fungal_matched_experiment.R", package="FunMel"))
```

These additional examples use synthetic data to explain masks, exact
arithmetic and a replicated-control model. Scripts write to temporary
output directories and print their locations. These simulated outputs
demonstrate methods and are not experimental results.

## 3. Analyze one real photograph and inspect its mask

``` r

img <- file.choose()
r <- analyze_plate(img, layout=plate_layout(centre="fungus"),
                   dish_diameter_mm=90, keep_images=TRUE)
plot_qc(r)
r$colonies[, c("colony_id", "detected", "MI_mean", "area_mm2")]
r$warnings
```

Use `centre="fungus"` for fungal confrontation plates and
`centre="none"` for control plates containing only the four target
colonies. Enter the actual **outer dish diameter**, not an assumed 90
mm. MI is mean `100 - L*` on the retained colony interior: greater MI
means a darker image, not a measured melanin concentration.
`keep_images=TRUE` enables later QC plotting; batch runs save QC files
and omit large image arrays from their returned object.

Photograph plates using comparable exposure, illumination and geometry.
Include a suitable colour reference where possible. Inspect dish
fit/scale, each target mask, central-partner assignment and candidate
halo. Flat-field correction does not prove that different photographs
are biologically comparable. Halo candidates are colour zones, not
independently validated inhibition boundaries.

## 4. Prepare metadata: one row per independent plate

``` r

make_metadata("photos", recursive=TRUE)
# Edit photos/plate_metadata.csv before analysis.
```

### Review metadata before finalization

1.  **Load the completed metadata table.** Each row represents one
    independent plate. The template includes logical
    `metadata_confirmed` and `qc_pass` columns, both initially `FALSE`.

    ``` r

    metadata <- read.csv("photos/plate_metadata.csv", stringsAsFactors = FALSE)
    ```

2.  **Review the image analysis and experimental assignments.** Inspect
    each plate’s target-colony masks, central fungus and halo candidate,
    calibration and warnings. Verify the treatment label and `set_id`
    linking the plate to its matching controls. Mark only plates whose
    QC has passed, and separately confirm their experimental metadata.
    Replace the example IDs below with the actual plate IDs:

    ``` r

    reviewed_ids <- c("plate_1", "plate_2")
    metadata$qc_pass[metadata$plate_id %in% reviewed_ids] <- TRUE

    confirmed_ids <- c("plate_1", "plate_2")
    metadata$metadata_confirmed[metadata$plate_id %in% confirmed_ids] <- TRUE
    ```

3.  **Save the reviewed metadata and finalize.** Both flags must be
    logical `TRUE` for every included plate, with no missing values. The
    metadata must match the analyzed plate IDs exactly. Resolve failed
    images and unacceptable QC before finalizing. Use `TRUE` and `FALSE`
    without quotation marks.

    ``` r

    write.csv(metadata, "plate_metadata_reviewed.csv", row.names = FALSE)
    reviewed <- finalize_analysis(result, metadata)
    ```

Here `result` is the batch result returned by
[`analyze_plates()`](https://mghotbi.github.io/FunMel/reference/analyze_plates.md);
use the actual object name from the analysis. The flags record completed
user review. Changing segmentation settings or the central-partner
recipe requires reanalysis.

The template keeps relative source paths but leaves experimental fields
for you to fill. Folder names are provenance, not sufficient evidence of
treatment or control identity. A ZIP needs your metadata too: the
package cannot infer the experimental design just by unzipping it. Image
basenames must be unique.

| Column | What to enter |
|----|----|
| `file` | Unique image basename, including extension |
| `relative_file` | Relative path from the image root; useful for nested folders |
| `plate_id` | Globally unique independent biological plate ID |
| `set_id` | Matching control set; often an experimental batch |
| `treatment` | Exact `control` label, or consistent treatment name |
| `centre_model` | Primary assay recipes: `none` for controls; `fungus` for fungal confrontation |
| `partner_type` | Biological partner type, consistent with the recipe |
| `zymo_strain`, `day`, `medium` | Recommended context; if included, complete and constant within a set |
| `metadata_confirmed` | Logical TRUE only after checking experimental assignments |
| `qc_pass` | Logical TRUE only after acceptable mask/calibration review; required by finalization |
| `replicate` | Optional plate replicate label; not the colony number |
| `rotation_deg`, `radius_frac`, `radius_mm`, `search_frac` | Optional numeric, per-image layout settings |

All treatment replicates in set S use only controls in S. Several
treatments may share S’s controls: list each control plate **once**. The
same treatment label in several sets must represent the same
intervention. Give different strains, days or media separate set IDs.
Four colonies on one dish are subsamples, not four independent plates.
Multiple photos of one dish do not create biological replication.

The bundled `inst/examples/metadata_14_day_case_study.csv` illustrates
this structure. For a new experiment, generate and complete a metadata
template using the actual plate IDs, treatments and control assignments.

## 5. Analyze a folder or a ZIP

``` r

meta <- read.csv("photos/plate_metadata.csv", stringsAsFactors=FALSE)
files <- file.path("photos", meta$relative_file)
# Alternatively, with an arbitrary original photo ZIP:
# files <- prepare_photo_archive("my_photos.zip", meta, "extracted_photos")
validate_metadata(meta, files)
out <- analyze_plates(files, metadata=meta,
                      layout=function(row) layout_by_treatment(row),
                      qc_dir="FunMel_results/qc")
saveRDS(out, "FunMel_results/image_analysis.rds")
out$failed
out$coefficient_error
```

For a complete generic workflow, copy and configure
`scripts/analyse_experiment.R`. It takes any valid metadata and image
paths; it does not assume particular filenames, treatment codes or
replicate counts. It stops at the review stage unless both confirmation
flags are TRUE. The 14-day archive script is a separately named **case
study**, not the general entry point.

After inspecting and, where necessary, correcting the photographs/masks,
update your metadata CSV. Do not set flags TRUE merely to obtain a
coefficient.

``` r

reviewed_meta <- read.csv("photos/plate_metadata.csv", stringsAsFactors=FALSE)
reviewed <- finalize_analysis(out, reviewed_meta)
reviewed$melanization_coefficient
reviewed$assessment$status
reviewed$assessment$treatment_comparisons
```

Finalization reuses saved measurements. Changing the central
segmentation recipe or an image’s layout settings requires image
reanalysis; reassigning verified matching-set/treatment labels can be
applied to saved measurements. Resolve failed images explicitly; do not
silently drop a failed replicate.

## 6. Understand the coefficient and statistical assessment

For each plate, average its target colonies’ `MI_mean`. The matched
coefficient is the treatment’s mean **plate MI** divided by its own
set’s control mean plate MI. Plates get equal descriptive weight. MC \>
1 means darker treatment images; MC \< 1 means lighter images. Each
treatment replicate’s ratio is also exported. Across several sets, the
final descriptive coefficient averages matched set ratios equally; it
does not divide by pooled unrelated controls.

[`assess_experiment()`](https://mghotbi.github.io/FunMel/reference/assess_experiment.md)
retains raw colony MI and fits a fixed mean for each observed
set-treatment cell plus a plate random intercept:
`MI ~ 0 + set_treatment_cell + (1 | plate_id)`. `lme4` fits the model
and `lmerTest` supplies Satterthwaite contrast inference. Within-set
effects are `treatment - own control`; treatment comparisons subtract
these matched effects. Shared-control covariance is preserved. An
explicit `method="plate_means"` alternative retains one row per
independent plate and the same matched contrasts. Neither method tests
treatment averages as if they were replicates.

This cell-specific model conditions on observed sets. It differs from an
additive `treatment + batch` model or a random-batch population model.
Different set coverage can confound a treatment-only interpretation;
prefer `comparison_scope="common_sets"` where the design supports common
batches. Do not feed ratios sharing one denominator to an ordinary
independent-sample test.

The current implementation requires at least two independent plates in
every set-treatment cell before inference; this is a conservative
computational guard, not a universal assay rule or an assurance of
sufficient power. A single control can support a descriptive ratio. Some
sparse designs can support inference under other justified models; those
must be specified separately. Singular fits or convergence issues
withhold inferential tables. Inspect status, residuals and replication.
Holm-adjusted p values are separate from unadjusted contrast-wise CIs.

## 7. Save results and a comparison figure

``` r

write.csv(reviewed$colonies, "FunMel_results/colonies.csv", row.names=FALSE)
write.csv(reviewed$melanization_coefficient,
          "FunMel_results/matched_coefficients.csv", row.names=FALSE)
saveRDS(reviewed, "FunMel_results/reviewed_analysis.rds")
plot_treatment_comparison(reviewed,
                         file="FunMel_results/treatment_comparison")
```

PDF/SVG are vector exports; PNG is 600 dpi. Panel A shows plate MI and
matching controls; panel B shows matched plate ratios and group ratios
of means. The Outlined squares distinguish controls from filled
treatment circles. Treatments use contrasting colours. Lower diamonds
and bars show treatment means ± one between-plate SD; row annotations
give means, SDs and plate counts. Control SD is unavailable when n=1.
Ratio SD measures treatment spread conditional on its shared control,
without accounting for denominator uncertainty. A companion
`_statistics.csv` records all plotted summaries and descriptive ΔMI.
Access this table without exporting using
`attr(p, "FunMel_statistics")`, where `p` is the returned plot. No
p-values or confidence intervals are implied. Customize labels with
`labels=c(fungus_A="Fungal partner A")`. `preview=TRUE` labels an
unconfirmed mapping as provisional; it does not confirm metadata or
override a failed QC review. Save
[`sessionInfo()`](https://rdrr.io/r/utils/sessionInfo.html) alongside
your analysis.

| Output | Interpretation |
|----|----|
| `colonies` | One row per target colony; MI, shape, geometry and detection status |
| `profiles` | Within-colony edge-to-centre rings, not biological replicates |
| `plates` | Dish scale, central partner, halo candidate and image diagnostics |
| `failed` | Image errors that require action |
| `melanization_coefficient` | Set-specific descriptive ratios and plate counts |
| `per_plate_coefficients` | Replicate ratios using the matching control mean |
| `assessment` | Model, contrasts, replication and diagnostic status |

`radial_asymmetry_pct` is the clear alias of legacy
`growth_inhibition_pct`: both measure toward/away radial asymmetry,
**not** `(control growth - treatment growth) / control growth * 100`.
Image-derived growth inhibition requires a consistent growth measurement
and its own control comparison. Spatial bootstrap intervals describe
uncertainty within an image, not independent-plate variation.

## 8. Adapt layouts and resolve common problems

``` r

lay <- plate_layout(centre="fungus", rotation_deg=15, radius_frac=0.5)
# For a different inoculation pattern, supply positions explicitly:
pos <- data.frame(id=c("N", "E", "S", "W"),
                  x_rel=c(0,0.5,0,-0.5), y_rel=c(-0.5,0,0.5,0))
lay <- plate_layout(centre="fungus", positions=pos)
```

| Problem | Action |
|----|----|
| Function missing / unused argument | Check the loaded version and [`args()`](https://rdrr.io/r/base/args.html); restart after upgrades |
| Missing image | Check filenames/relative paths; use the original ZIP, not the review ZIP |
| Four regions, wrong boundaries | Inspect QC; adjust layout, imaging or supervised training |
| Undetected target / missing MI | Correct segmentation; documented `na_action="omit"` is explicit, not automatic |
| Empty coefficient table | Read `coefficient_error` / status; verify metadata and QC |
| Brightness warnings | Inspect correction limits and residual agar variation; consider a colour reference or rephotography |
| Unresolved halo | Do not replace an unresolved biological boundary with zero inhibition |
| Inference withheld | Check independent plate counts and model diagnostics; never duplicate controls |

The supported use case is a roughly circular dish with a known
inoculation layout. A crowded plate, merged organisms, unknown layouts
or severe reflections can require training or manual analysis. Changing
layouts is supported; accuracy for every photograph is not guaranteed.
The simulator tests computation under known schematic conditions, not
unrestricted biological generalization.

## 9. Why use FunMel alongside ImageJ?

FunMel connects assay-specific image processing to explicit control
metadata, repeatable batch measurements, plate-aware statistics and
figure exports in one R workflow. ImageJ/Fiji already supports
measurements, ROI management and macro batch processing; FunMel is not
claimed to be inherently more accurate or always faster. ImageJ can
remain useful for manual mask review and difficult images. See the
separate, README-ready [overview and
algorithms](https://github.com/mghotbi/FunMel/blob/HEAD/inst/guides/FunMel_overview.md).
