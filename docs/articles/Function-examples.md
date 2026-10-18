# Examples for every function

THE COMPLETE FUNCTION CATALOG

Explore the tools at your own pace.

Find each exported function, follow a runnable example, and return to
the complete real-photograph workflow whenever you need the wider
context.

Start with [Get started with
FunMel](https://mghotbi.github.io/FunMel/articles/FunMel.md) for
installation and the main workflow. The separate [real 14-day
tutorial](https://mghotbi.github.io/FunMel/articles/Real-14-day.md)
covers every step for the bundled photographs. This catalog covers every
exported function, including specialist utilities that are not needed
for routine photographs. Use the runnable script below to explore the
functions in sequence.

Start with `walkthrough_14_days.R`: eight real photographs, metadata,
five spots per colony, QC reminders, matched coefficients, exported
figures and reopening saved results.

Run `06_all_functions.R` for the complete synthetic API catalog. Run
numbered sections in order. Outputs go to a temporary folder printed at
the end. Its 20 bootstrap replicates are for quick teaching runs, not
precise uncertainty estimates.

Interactive annotation alone needs user clicks; enable
`options(FunMel.annotate=TRUE)` before sourcing if desired. Synthetic
training regions demonstrate calls, not a validated model for
photographs.

| Function | Catalog section |
|----|----|
| [`analyze_plate()`](https://mghotbi.github.io/FunMel/reference/analyze_plate.md) | 4\. Complete single-plate workflow and visual checks. |
| [`analyze_plates()`](https://mghotbi.github.io/FunMel/reference/analyze_plates.md) | 7\. Metadata, batch analysis and a complete saved project from synthetic images. |
| [`annotate_plate()`](https://mghotbi.github.io/FunMel/reference/annotate_plate.md) | 5\. Supervised classification. Coordinates below come from simulated truth. |
| [`assess_experiment()`](https://mghotbi.github.io/FunMel/reference/assess_experiment.md) | 6\. Repeated independent plates and matched-set statistics (synthetic values). |
| [`calibrate_color()`](https://mghotbi.github.io/FunMel/reference/calibrate_color.md) | 2\. Colour conversions and reference calibration. |
| [`classify_pixels()`](https://mghotbi.github.io/FunMel/reference/classify_pixels.md) | 3\. The individual image-processing steps (normally analyze_plate does these). |
| [`colony_profiles()`](https://mghotbi.github.io/FunMel/reference/colony_profiles.md) | 3\. The individual image-processing steps (normally analyze_plate does these). |
| [`compare_melanization()`](https://mghotbi.github.io/FunMel/reference/compare_melanization.md) | 6\. Repeated independent plates and matched-set statistics (synthetic values). |
| [`correct_facing_bias()`](https://mghotbi.github.io/FunMel/reference/correct_facing_bias.md) | 6\. Repeated independent plates and matched-set statistics (synthetic values). |
| [`delta_e76()`](https://mghotbi.github.io/FunMel/reference/delta_e76.md) | 2\. Colour conversions and reference calibration. |
| [`detect_plate()`](https://mghotbi.github.io/FunMel/reference/detect_plate.md) | 3\. The individual image-processing steps (normally analyze_plate does these). |
| [`example_experiment()`](https://mghotbi.github.io/FunMel/reference/example_experiment.md) | 6\. Repeated independent plates and matched-set statistics (synthetic values). |
| [`example_plate()`](https://mghotbi.github.io/FunMel/reference/example_plate.md) | 1\. Layout, simulation and import. |
| [`extract_training_pixels()`](https://mghotbi.github.io/FunMel/reference/extract_training_pixels.md) | 5\. Supervised classification. Coordinates below come from simulated truth. |
| [`finalize_analysis()`](https://mghotbi.github.io/FunMel/reference/finalize_analysis.md) | 7\. Metadata, batch analysis and a complete saved project from synthetic images. |
| [`finish_experiment()`](https://mghotbi.github.io/FunMel/reference/finish_experiment.md) | 7\. Metadata, batch analysis and a complete saved project from synthetic images. |
| [`is_funmel_plate()`](https://mghotbi.github.io/FunMel/reference/is_funmel_plate.md) | 1\. Layout, simulation and import. |
| [`is_mycohalo_plate()`](https://mghotbi.github.io/FunMel/reference/is_mycohalo_plate.md) | 1\. Layout, simulation and import. |
| [`lab_chroma_hue()`](https://mghotbi.github.io/FunMel/reference/lab_chroma_hue.md) | 2\. Colour conversions and reference calibration. |
| [`lab_to_srgb()`](https://mghotbi.github.io/FunMel/reference/lab_to_srgb.md) | 2\. Colour conversions and reference calibration. |
| [`layout_by_treatment()`](https://mghotbi.github.io/FunMel/reference/layout_by_treatment.md) | 7\. Metadata, batch analysis and a complete saved project from synthetic images. |
| [`load_experiment()`](https://mghotbi.github.io/FunMel/reference/load_experiment.md) | 7\. Metadata, batch analysis and a complete saved project from synthetic images. |
| [`make_metadata()`](https://mghotbi.github.io/FunMel/reference/make_metadata.md) | 7\. Metadata, batch analysis and a complete saved project from synthetic images. |
| [`measure_colonies()`](https://mghotbi.github.io/FunMel/reference/measure_colonies.md) | 3\. The individual image-processing steps (normally analyze_plate does these). |
| [`melanization_coefficient()`](https://mghotbi.github.io/FunMel/reference/melanization_coefficient.md) | 6\. Repeated independent plates and matched-set statistics (synthetic values). |
| [`model_background()`](https://mghotbi.github.io/FunMel/reference/model_background.md) | 3\. The individual image-processing steps (normally analyze_plate does these). |
| [`plate_layout()`](https://mghotbi.github.io/FunMel/reference/plate_layout.md) | 1\. Layout, simulation and import. |
| [`plot_melanization_map()`](https://mghotbi.github.io/FunMel/reference/plot_melanization_map.md) | 4\. Complete single-plate workflow and visual checks. |
| [`plot_profiles()`](https://mghotbi.github.io/FunMel/reference/plot_profiles.md) | 4\. Complete single-plate workflow and visual checks. |
| [`plot_qc()`](https://mghotbi.github.io/FunMel/reference/plot_qc.md) | 4\. Complete single-plate workflow and visual checks. |
| [`plot_treatment_comparison()`](https://mghotbi.github.io/FunMel/reference/plot_treatment_comparison.md) | 6\. Repeated independent plates and matched-set statistics (synthetic values). |
| [`prepare_experiment()`](https://mghotbi.github.io/FunMel/reference/prepare_experiment.md) | 7\. Metadata, batch analysis and a complete saved project from synthetic images. |
| [`prepare_photo_archive()`](https://mghotbi.github.io/FunMel/reference/prepare_photo_archive.md) | 8\. ZIP input (a nested archive may contain many sets with their own controls). |
| [`read_experiment()`](https://mghotbi.github.io/FunMel/reference/read_experiment.md) | 7\. Metadata, batch analysis and a complete saved project from synthetic images. |
| [`read_plate()`](https://mghotbi.github.io/FunMel/reference/read_plate.md) | 1\. Layout, simulation and import. |
| [`run_experiment()`](https://mghotbi.github.io/FunMel/reference/run_experiment.md) | 7\. Metadata, batch analysis and a complete saved project from synthetic images. |
| [`sample_colony_spots()`](https://mghotbi.github.io/FunMel/reference/sample_colony_spots.md) | 3\. The individual image-processing steps (normally analyze_plate does these). |
| [`segment_colonies()`](https://mghotbi.github.io/FunMel/reference/segment_colonies.md) | 3\. The individual image-processing steps (normally analyze_plate does these). |
| [`simulate_plate()`](https://mghotbi.github.io/FunMel/reference/simulate_plate.md) | 1\. Layout, simulation and import. |
| [`srgb_to_lab()`](https://mghotbi.github.io/FunMel/reference/srgb_to_lab.md) | 2\. Colour conversions and reference calibration. |
| [`train_classifier()`](https://mghotbi.github.io/FunMel/reference/train_classifier.md) | 5\. Supervised classification. Coordinates below come from simulated truth. |
| [`validate_metadata()`](https://mghotbi.github.io/FunMel/reference/validate_metadata.md) | 6\. Repeated independent plates and matched-set statistics (synthetic values). |

``` r

# FunMel function catalog. Run this whole script in a fresh R session.
# Synthetic examples teach the API; use walkthrough_14_days.R for real photographs.
# Output is written to a new temporary folder, never over an existing project.
library(FunMel)
catalog_dir <- tempfile("FunMel_catalog_")
dir.create(catalog_dir)

# 1. Layout, simulation and import.
layout <- plate_layout(centre="fungus")
sim <- simulate_plate(width=400,height=400,seed=7,layout=layout,grey_card=TRUE)
plate <- read_plate(sim$image,id="teaching")
stopifnot(is_funmel_plate(plate),is_mycohalo_plate(plate))
print(example_plate("all")) # Paths to the real bundled photographs.

# 2. Colour conversions and reference calibration.
colours <- matrix(c(.2,.3,.4,.6,.5,.4),ncol=3,byrow=TRUE)
lab <- srgb_to_lab(colours)
lab_to_srgb(lab)
lab_chroma_hue(lab[,2],lab[,3])
delta_e76(lab[1,],lab[2,])
calibrated <- calibrate_color(plate,region=sim$truth$grey_card)

# 3. The individual image-processing steps (normally analyze_plate does these).
plate <- detect_plate(calibrated,dish_diameter_mm=90)
plate <- model_background(plate)
background_plate <- plate
plate <- classify_pixels(plate,layout=layout)
plate <- segment_colonies(plate,layout=layout)
whole_colonies <- measure_colonies(plate,n_boot=20)
profiles <- colony_profiles(plate,n_boot=20)
spots <- sample_colony_spots(plate,n_spots=5,spot_radius_mm=.4)
head(whole_colonies)
head(profiles)
head(spots$spots)

# 4. Complete single-plate workflow and visual checks.
result <- analyze_plate(sim$image,layout=layout,id="teaching",n_boot=20,
                        n_spots=5,spot_radius_mm=.4,verbose=FALSE)
grDevices::pdf(file.path(catalog_dir,"image_checks.pdf"),width=8,height=7)
plot_qc(result)
print(plot_profiles(result))
plot_melanization_map(result,type="2d")
grDevices::dev.off()

# 5. Supervised classification. Coordinates below come from simulated truth.
# Labels zymo/central_partner are biological roles, even with a fungal partner.
regions <- data.frame(class=c("zymo","central_partner"),
  x=c(sim$truth$colonies$x[1],background_plate$dish$x),
  y=c(sim$truth$colonies$y[1],background_plate$dish$y),r=5)
training <- extract_training_pixels(background_plate,regions)
classifier <- train_classifier(training)
classified <- classify_pixels(background_plate,layout=layout,classifier=classifier)
# Optional interactive alternative: explicitly request it in a plotting session.
# This needs clicks and therefore does not run when sourcing the catalog.
if(interactive() && isTRUE(getOption("FunMel.annotate",FALSE))) {
  regions <- annotate_plate(background_plate,classes=c("zymo","central_partner"),r_mm=.5)
  training <- extract_training_pixels(background_plate,regions)
  classifier <- train_classifier(training)
}

# 6. Repeated independent plates and matched-set statistics (synthetic values).
demo <- example_experiment(seed=42)
validate_metadata(demo$metadata)
coefficient <- melanization_coefficient(demo$colonies)
assessment <- assess_experiment(demo$colonies)
comparison <- compare_melanization(demo$colonies)
corrected <- correct_facing_bias(demo$colonies)
plot_treatment_comparison(demo,file=file.path(catalog_dir,"synthetic_comparison"))
# Diagnostic status must be checked before interpreting inference.
print(assessment$status)

# 7. Metadata, batch analysis and a complete saved project from synthetic images.
photo_dir <- file.path(catalog_dir,"photos");dir.create(photo_dir)
png::writePNG(sim$image,file.path(photo_dir,"fungus_1.png"))
control_sim <- simulate_plate(width=400,height=400,seed=8,layout=plate_layout(centre="none"))
png::writePNG(control_sim$image,file.path(photo_dir,"control_1.png"))
metadata <- make_metadata(photo_dir,set_id="teaching_set",patterns=c(control="control",fungus_A="fungus"))
metadata$centre_model <- ifelse(metadata$treatment=="control","none","fungus")
metadata$partner_type <- metadata$centre_model
metadata$operator <- "Teaching example" # Custom columns are preserved.
validate_metadata(metadata)
layout_by_treatment(metadata[1,,drop=FALSE])
utils::write.csv(metadata,file.path(photo_dir,"plate_metadata.csv"),row.names=FALSE)
files <- file.path(photo_dir,metadata$file)
batch <- analyze_plates(files,metadata=metadata,layout=layout_by_treatment,
                         n_boot=20,n_spots=5,spot_radius_mm=.4,verbose=FALSE)
stopifnot(nrow(batch$failed)==0)
finalized <- finalize_analysis(batch,metadata)
project <- prepare_experiment(photo_dir,file.path(catalog_dir,"project"))
project_result <- run_experiment(project,dish_diameter_mm=90,n_boot=20,
                                 n_spots=5,spot_radius_mm=.4,verbose=FALSE)
stopifnot(nrow(project_result$failed)==0)
project_final <- finish_experiment(project)
reopened <- load_experiment(project$project_dir)
saved <- read_experiment(reopened)
head(saved$spots)
plot_treatment_comparison(reopened)

# 8. ZIP input (a nested archive may contain many sets with their own controls).
zip_file <- file.path(catalog_dir,"photos.zip")
local({
  old <- setwd(photo_dir);on.exit(setwd(old))
  utils::zip(zip_file,files=metadata$file,flags="-q")
})
extracted <- prepare_photo_archive(zip_file,metadata,file.path(catalog_dir,"extracted"))
stopifnot(length(extracted)==nrow(metadata),all(file.exists(extracted)))
# prepare_experiment also accepts ZIPs. Supply verified metadata when absent
# from an archive; folder names alone cannot establish biological assignments.
message("Function catalog completed. Outputs: ",catalog_dir)
```
