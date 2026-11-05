# FunMel

**From fungal confrontation photographs to matched-control results.**

FunMel measures the colour, shape and image-darkness profiles of
approximately round *Zymoseptoria tritici* colonies around another
fungus. It separates target colonies from central fungal tissue and
connected hyphal growth, preserves image provenance and custom metadata,
and compares treatments with their own set controls.

**[Get started](https://mghotbi.github.io/FunMel/articles/FunMel.html) ·
[Real 14-day
tutorial](https://mghotbi.github.io/FunMel/articles/Real-14-day.html) ·
[All function
examples](https://mghotbi.github.io/FunMel/articles/Function-examples.html)**

## Install

``` r

install.packages("remotes")
remotes::install_github("mghotbi/FunMel")
```

Restart R before loading an updated package. R \>= 4.1 and
source-compilation tools are required: Xcode Command Line Tools on
macOS, matching Rtools on Windows, or R development tools and
ImageMagick development libraries on Linux. For installed tutorials, use
`build_vignettes=TRUE` during installation.

## Quick start with your photographs

The ZIP is an input file; the project is a separate output folder.
Replace these paths with your own. This block reopens a recognized
project and reads saved measurements; otherwise it prepares and measures
a new project.

``` r

library(FunMel)
photo_zip <- path.expand("~/Desktop/photos_14_days.zip")
project_dir <- path.expand("~/Desktop/My_FunMel_project")

if (file.exists(file.path(project_dir, "project.rds"))) {
  project <- load_experiment(project_dir)
} else {
  project <- prepare_experiment(input=photo_zip, project_dir=project_dir)
}

if (file.exists(project$result_file) || file.exists(project$reviewed_file)) {
  result <- read_experiment(project)
} else {
  result <- run_experiment(
    project, dish_diameter_mm=90, # Replace with the verified outer dish diameter.
    n_spots=5, spot_radius_mm=0.4
  )
}
result$failed
head(result$colonies)
project$qc_dir # Inspect the saved QC images and resolve failures first.

reviewed <- finish_experiment(project)
comparison <- plot_treatment_comparison(reviewed)
if (!is.null(comparison)) print(comparison)
project$project_dir # Saved tables and any eligible comparison figures.
```

A new project needs a new or empty output folder. Reopening retains that
project’s photographs; choose another folder for a different archive. To
change analysis settings, rerun
[`run_experiment()`](https://mghotbi.github.io/FunMel/reference/run_experiment.md)
explicitly. The default layout is four target colonies around a central
fungus. Control-only images need `default_centre="none"`; mixed
collections need correct per-image layouts.

Measurement needs no treatment names or approval-flag edits. A treatment
comparison still requires real treatment/control assignments within each
`set_id`. Otherwise FunMel saves measurements, reports `awaiting_design`
and explains why no comparison figure is produced. The real-data
tutorial also shows a descriptive set plot that needs no treatment
names.

The output folder also contains `run_summary.csv`,
`metadata_issues.csv`, `measurement_issues.csv` and
`layout_assignments.csv`. These distinguish missing experimental
assignments from incomplete colony/spot measurements. See the [real-data
troubleshooting
guide](https://mghotbi.github.io/FunMel/articles/Real-14-day.html#when-coefficient-tables-are-empty).

## Tutorials

| Task | Guide |
|----|----|
| Own photographs, layouts, metadata and saved work | [Get started](https://mghotbi.github.io/FunMel/articles/FunMel.html) |
| Eight original photographs, complete walkthrough and set-only summaries | [Real 14-day data](https://mghotbi.github.io/FunMel/articles/Real-14-day.html) |
| Every exported function, including specialist tools | [Function examples](https://mghotbi.github.io/FunMel/articles/Function-examples.html) |
| Algorithms and use alongside ImageJ/Fiji | [Package overview](https://github.com/mghotbi/FunMel/blob/HEAD/inst/guides/FunMel_overview.md) |

## Interpretation

Melanization index is `MI = 100 - CIELAB L*`: an image-darkness proxy,
not a direct measurement of melanin concentration. Central hyphal growth
is not an inhibition zone. Inspect masks, calibration and lighting
before interpreting results.

Independent plates are the experimental units; colonies and spots are
subsamples. Matched coefficients divide the mean target-colony MI under
treatment by the mean target-colony MI in the same set’s controls. One
control per set supports descriptive ratios, not replicated-control
significance tests. The tutorials explain statistical requirements,
figure contents and limitations in detail.

## Recovering an incorrect mask

Inspect the QC image before using a measurement.
[`retry_funmel_dish()`](https://mghotbi.github.io/FunMel/reference/retry_funmel_dish.md)
corrects an outer dish circle with three clicks;
[`recover_funmel_plate()`](https://mghotbi.github.io/FunMel/reference/retry_funmel_dish.md)
additionally collects reviewed target and central-fungus outlines. Both
save a new recovery folder. Reapply saved annotations by exact plate ID
when rerunning a project; see [the real-data recovery
guide](https://mghotbi.github.io/FunMel/articles/Real-14-day.html#recovering-a-failed-dish-fit-or-tissue-mask).
No external recovery script is required.

Target diameter is `eq_diameter_mm` in `colonies.csv`. Central fungal
diameter is `central_diameter_mm` in `plates.csv`. Both are diameters of
circles with the same segmented area, not maximum caliper/Feret
diameters. Physical units require verified calibration and reviewed
boundaries.

## Concentric or differently coloured target colonies

Use one outer tissue boundary for each *Z. tritici* colony and include
its interior. A pale margin and darker centre are parts of the same
target, not separate colonies. If the QC shows only a ring or the inner
core, use the [real-data recovery
procedure](https://mghotbi.github.io/FunMel/articles/Real-14-day.html#concentric-target-colonies).
Keep agar, reflections and central fungal tissue outside the target
outline.

The default melanization coefficient is **mean treatment target-colony
MI / mean own-set control target-colony MI**. Each colony has equal
weight; pixel counts and sampled spots do not determine its weight. With
four valid colonies per plate this equals averaging plate means first.
Plates remain independent replicates for statistical inference. Missing
targets require review.
