# FunMel: run the numbered sections in order. No approval flags need editing.
library(FunMel)

# 1. Prepare the original eight photographs with supplied combined metadata.
photos14 <- system.file("extdata", "14-days", package="FunMel")
stopifnot(nzchar(photos14))
project14 <- prepare_experiment(photos14, "FunMel_14_day_project")
project14$metadata_file
# Check treatment, control, set_id, centre_model, day and replicate assignments
# against laboratory records. Only correct missing or inaccurate information.

# 2. Measure: set the actual outer dish diameter directly.
dish_mm <- 90 # Illustrative; replace with the verified diameter (mm).
result14 <- run_experiment(project14,dish_diameter_mm=dish_mm,max_dim=1200,
                           n_spots=5,spot_radius_mm=0.4)
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
# project14 <- readRDS(file.choose()) # Select this project's project.rds.
# reviewed14 <- finish_experiment(project14)
