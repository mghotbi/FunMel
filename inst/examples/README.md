# FunMel examples

Start with `walkthrough_14_days.R`: eight real photographs, metadata, five spots per colony, QC reminders, matched coefficients, exported figures and reopening saved results.

Run `06_all_functions.R` for the complete synthetic API catalog. Run numbered sections in order. Outputs go to a temporary folder printed at the end. Its 20 bootstrap replicates are for quick teaching runs, not precise uncertainty estimates.

Interactive annotation alone needs user clicks; enable `options(FunMel.annotate=TRUE)` before sourcing if desired. Synthetic training regions demonstrate calls, not a validated model for photographs.

| Function | Catalog section |
|---|---|
| `analyze_plate()` | 4. Complete single-plate workflow and visual checks. |
| `analyze_plates()` | 7. Metadata, batch analysis and a complete saved project from synthetic images. |
| `annotate_plate()` | 5. Supervised classification. Coordinates below come from simulated truth. |
| `assess_experiment()` | 6. Repeated independent plates and matched-set statistics (synthetic values). |
| `calibrate_color()` | 2. Colour conversions and reference calibration. |
| `classify_pixels()` | 3. The individual image-processing steps (normally analyze_plate does these). |
| `colony_profiles()` | 3. The individual image-processing steps (normally analyze_plate does these). |
| `compare_melanization()` | 6. Repeated independent plates and matched-set statistics (synthetic values). |
| `correct_facing_bias()` | 6. Repeated independent plates and matched-set statistics (synthetic values). |
| `delta_e76()` | 2. Colour conversions and reference calibration. |
| `detect_plate()` | 3. The individual image-processing steps (normally analyze_plate does these). |
| `example_experiment()` | 6. Repeated independent plates and matched-set statistics (synthetic values). |
| `example_plate()` | 1. Layout, simulation and import. |
| `extract_training_pixels()` | 5. Supervised classification. Coordinates below come from simulated truth. |
| `finalize_analysis()` | 7. Metadata, batch analysis and a complete saved project from synthetic images. |
| `finish_experiment()` | 7. Metadata, batch analysis and a complete saved project from synthetic images. |
| `is_funmel_plate()` | 1. Layout, simulation and import. |
| `is_mycohalo_plate()` | 1. Layout, simulation and import. |
| `lab_chroma_hue()` | 2. Colour conversions and reference calibration. |
| `lab_to_srgb()` | 2. Colour conversions and reference calibration. |
| `layout_by_treatment()` | 7. Metadata, batch analysis and a complete saved project from synthetic images. |
| `load_experiment()` | 7. Metadata, batch analysis and a complete saved project from synthetic images. |
| `make_metadata()` | 7. Metadata, batch analysis and a complete saved project from synthetic images. |
| `measure_colonies()` | 3. The individual image-processing steps (normally analyze_plate does these). |
| `melanization_coefficient()` | 6. Repeated independent plates and matched-set statistics (synthetic values). |
| `model_background()` | 3. The individual image-processing steps (normally analyze_plate does these). |
| `plate_layout()` | 1. Layout, simulation and import. |
| `plot_melanization_map()` | 4. Complete single-plate workflow and visual checks. |
| `plot_profiles()` | 4. Complete single-plate workflow and visual checks. |
| `plot_qc()` | 4. Complete single-plate workflow and visual checks. |
| `plot_treatment_comparison()` | 6. Repeated independent plates and matched-set statistics (synthetic values). |
| `prepare_experiment()` | 7. Metadata, batch analysis and a complete saved project from synthetic images. |
| `prepare_photo_archive()` | 8. ZIP input (a nested archive may contain many sets with their own controls). |
| `read_experiment()` | 7. Metadata, batch analysis and a complete saved project from synthetic images. |
| `read_plate()` | 1. Layout, simulation and import. |
| `run_experiment()` | 7. Metadata, batch analysis and a complete saved project from synthetic images. |
| `sample_colony_spots()` | 3. The individual image-processing steps (normally analyze_plate does these). |
| `segment_colonies()` | 3. The individual image-processing steps (normally analyze_plate does these). |
| `simulate_plate()` | 1. Layout, simulation and import. |
| `srgb_to_lab()` | 2. Colour conversions and reference calibration. |
| `train_classifier()` | 5. Supervised classification. Coordinates below come from simulated truth. |
| `validate_metadata()` | 6. Repeated independent plates and matched-set statistics (synthetic values). |
