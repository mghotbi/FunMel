# FunMel: run each numbered section separately in RStudio.
# Do not source this whole file. Stop for metadata and image QC review.

# 1. Load the original eight photographs included with the package.
library(FunMel)
photos14 <- system.file("extdata", "14-days", package="FunMel")
stopifnot(nzchar(photos14))

# 2. Prepare the project ONCE; choose a new folder to start over.
project14 <- prepare_experiment(photos14, "FunMel_14_day_project")
project14$metadata_file
# Open this CSV. Verify file/set_id/treatment/centre_model and day.
# Verify the biological meaning of the A60_2 and B20_2 labels against records.
# One control + three independent treatment plates per set; do not copy controls.
# Set metadata_confirmed=TRUE per verified row, leave qc_pass=FALSE; save CSV.

# 3. Measure. Enter the actual outer dish diameter, not an assumed value.
dish_mm <- as.numeric(readline("Actual outer dish diameter in mm: "))
stopifnot(length(dish_mm)==1L, is.finite(dish_mm), dish_mm>0)
result14 <- run_experiment(project14, dish_diameter_mm=dish_mm, max_dim=1200,
                           n_spots=5, spot_radius_mm=0.4)
result14$failed
project14$qc_dir
# Omit n_spots/spot_radius_mm for whole-colony MI alone.

# 4. STOP. Open EVERY QC PNG in the printed folder.
# Check target boundaries, exclusion of central tissue/hyphae, shadows and agar,
# sampling circles, spot_status, calibration and warnings.
# Optional: reopen project14$metadata_file and record qc_pass=TRUE per acceptable reviewed plate.
# Keep unresolved rows FALSE. Default finalization warns and continues.
# Save as CSV if edited. Do not rerun analysis merely to update flags.
# metadata_confirmed must be TRUE. QC warns by default; require_qc=TRUE enforces it.

# 5. Finish using SAVED measurements and the edited CSV.
reviewed14 <- finish_experiment(project14)
reviewed14$melanization_coefficient
reviewed14$qc_review
reviewed14$assessment$status
list.files(project14$project_dir)
# Figures: treatment_comparison.pdf/.svg/.png.
# Complete metadata: metadata_used.csv. Data: colonies.csv and spots.csv.
# Optional strict mode after explicit QC approval:
# reviewed14 <- finish_experiment(project14, require_qc=TRUE)
# One control per set limits biological uncertainty estimation.
# Between-treatment differences can remain confounded with batch.

# 6. Resume after restarting R (do not recreate the project).
# library(FunMel)
# project14 <- readRDS("FunMel_14_day_project/project.rds")
# result14 <- readRDS(project14$result_file)
# reviewed14 <- finish_experiment(project14) # after completing reviews
