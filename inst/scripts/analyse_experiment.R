# Run this script to prepare a new project from a photograph ZIP.
# Then run the printed commands one at a time, completing each review first.
library(FunMel)
project <- prepare_experiment(file.choose(), "FunMel_project")
message("Step 1: open ",project$metadata_file,
        "; verify treatment, set_id and centre_model. Save the CSV.")
message("Step 2: run the following command AFTER editing metadata:")
message("result <- run_experiment(project, dish_diameter_mm=90, n_spots=5, spot_radius_mm=0.4)")
message("Use the actual dish diameter. Choose n_spots and radius consistently.")
message("Inspect every image in ",project$qc_dir,
        ", then save per-plate metadata_confirmed and qc_pass decisions in the CSV.")
message("Step 3: after confirming metadata and inspecting QC (unconfirmed QC warns by default), run finish_experiment(project).")
