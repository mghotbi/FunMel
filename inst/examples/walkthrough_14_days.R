# FunMel: run the numbered sections in order. No approval flags need editing.
library(FunMel)

# 1. Prepare the original eight photographs with supplied combined metadata.
photos14 <- system.file("extdata", "14-days", package="FunMel")
stopifnot(nzchar(photos14))
project_dir14 <- tempfile("FunMel_14_day_project_") # New temporary practice folder.
# For durable work, set a new folder path instead, before preparing.
project14 <- prepare_experiment(photos14,project_dir14)
project14$metadata_file
# Check treatment, control, set_id, centre_model, day and replicate assignments
# against laboratory records. Only correct missing or inaccurate information.

# 2. Measure: set the actual outer dish diameter directly.
dish_mm <- 90 # Illustrative; replace with the verified diameter (mm).
result14 <- run_experiment(project14,dish_diameter_mm=dish_mm,max_dim=1200,
                           n_spots=5,spot_radius_mm=0.4,n_boot=20)
result14$analysis_status
result14$failed
stopifnot(nrow(result14$failed)==0L)

# 3. Inspect every QC image before interpreting results.
project14$qc_dir
# Check boundaries, separation of fungal tissue/hyphae, spots, calibration,
# illumination and warnings. There is no approval column to change.

# 4. Calculate and export from saved measurements.
reviewed14 <- finish_experiment(project14)
reviewed14$melanization_coefficient
reviewed14$assessment$status
list.files(project14$project_dir)
# One control per set permits descriptive coefficients, not replicated-control
# significance tests. Colonies/spots are within-plate subsamples.

# 5. Resume later without preparing or measuring again:
# project14 <- load_experiment() # Select project.rds in its current folder.
# reviewed14 <- finish_experiment(project14)

# 6. Inspect measurements and draw the comparison directly from the project.
result14 <- read_experiment(project14)
head(result14$spots[, c("plate_id", "colony_id", "spot_id", "MI_mean", "MI_min", "MI_max")])
head(result14$colonies)
head(result14$plates)
head(result14$profiles)
plot_treatment_comparison(project14)
# Or use finalized results already in memory:
plot_treatment_comparison(reviewed14)
# project14$result_file is a filename; it has no $spots table.

# 7. Optional detailed views of one real photograph (keeps image arrays).
# The batch workflow saves QC PNGs but drops image arrays to save memory.
# Reprocess just this one photograph when interactive image-level plots are needed.
metadata14 <- utils::read.csv(project14$metadata_file,check.names=FALSE)
row14 <- metadata14[metadata14$plate_id==result14$plates$plate_id[1],,drop=FALSE]
image14 <- file.path(project14$image_root,row14$relative_file)
plate14 <- analyze_plate(image14,id=row14$plate_id,
  layout=layout_by_treatment(row14),dish_diameter_mm=dish_mm,max_dim=1200,
  n_spots=5,spot_radius_mm=.4,n_boot=20,keep_images=TRUE,verbose=FALSE)
plot_qc(plate14)
print(plot_profiles(plate14))
plot_melanization_map(plate14,type="2d")
# The map shows image darkness. It does not measure melanin concentration.
# For all specialist utilities see examples/06_all_functions.R and its index.
