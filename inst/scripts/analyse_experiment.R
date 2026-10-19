# Prepare once; correct only missing or inaccurate experimental labels.
library(FunMel)
project <- prepare_experiment() # Choose a photo ZIP or a photo inside its folder.
message("Review ",project$metadata_file," when matched comparisons are needed. Images can be measured now; check layouts and QC. No approval flags need editing.")
message("Then run: result <- run_experiment(project, dish_diameter_mm=90, n_spots=5, spot_radius_mm=0.4)")
message("Replace 90 with the verified outer dish diameter. Inspect result$failed and every QC image in ",project$qc_dir)
message("Finish with: reviewed <- finish_experiment(project). No FALSE-to-TRUE edits are required.")
