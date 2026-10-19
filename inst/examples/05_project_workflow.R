# Prepare once, measure now, add matching labels when comparisons are needed.
library(FunMel)
project <- prepare_experiment() # Choose a photo ZIP or an original photograph.
result <- run_experiment(project,default_centre="fungus",
                         dish_diameter_mm=90,n_spots=5,spot_radius_mm=0.4)
# Replace 90 with the verified outer dish diameter before running.
# Use default_centre="none" for unlabeled control-only collections.
# Explicit per-image centre_model values and known controls take precedence.
# Mixed collections require correct per-image layouts. Inspect all saved QC images.
result$failed
reviewed <- finish_experiment(project)
# Missing matching labels preserve measurements; comparison_status is awaiting_design.
reviewed$comparison_status
# To obtain comparisons later, add treatment/set_id in project$metadata_file,
# save the CSV and finish again. Changing the segmentation layout needs remeasurement.
# Optional annotations and approval flags may remain blank. All columns are retained.
