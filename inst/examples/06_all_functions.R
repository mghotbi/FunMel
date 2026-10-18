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
