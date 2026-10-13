# FunMel 0.3.6

- Focus primary documentation on four target Zymoseptoria colonies around
  a central fungal colony and halo candidate; use two fungal treatment labels
  in the matched statistical teaching example.

- Rewrite README and vignette for general users, with the measured dataset
  presented as a bundled case study and neutral example entry points.
- Display small vignette p-values with an explicit threshold; qualify
  stats::setNames to resolve the namespace check note.

- Distinguish controls with outlined squares and treatment plates with filled
  circles; use contrasting treatment colours and separate summary diamonds.
- Add plate means, between-plate SD, sample counts and matched coefficient SD
  to comparison figures, plus an inspectable statistics CSV/plot attribute.
- Mark single-control SD unavailable; ratio SD explicitly conditions on the
  matching control mean. No inferential p-values or intervals are implied.
- Update real-data figure, guidance and tests; preserve image measurements.

# FunMel 0.3.5

* Make the supplied five-set, one-control/three-treatment design the first
  real-data example in README and vignette instead of the fictional 10-photo design.
* Bundle actual filenames, provisional metadata and corrected image measurements.
* Add a no-download real-data preview script and the actual 20-row metadata CSV.
* Label control replicate 1 explicitly and clarify shared-denominator matching.
* Keep biological confirmation flags FALSE; no extra controls are invented.

# FunMel 0.3.4

* Rewrite the README and vignette as a general beginner-to-review workflow;
  distinguish matched ratios, plate-aware MI inference and growth inhibition.
* Add three executable beginner scripts and a fictional 10-photo metadata CSV.
* Make the generic batch script stop at review unless both flags are confirmed.
* Add recursive metadata templates and per-image layout settings; validate
  layout parameters and prohibit layout changes during saved-result review.
* Add radial_asymmetry_pct as the clear alias of legacy growth_inhibition_pct.
* Remove dataset-specific wording from the general archive helper.
* Add .gitignore, .Rbuildignore, README-ready overview and release guidance.
* Test independent synthetic arrangements, resolutions and illumination settings.

# FunMel 0.3.3

* Add finalize_analysis() to apply verified metadata and explicit mask-review
  flags to saved measurements without reprocessing photographs.
* Add plot_treatment_comparison(): matched plate MI and coefficient panels,
  vector PDF/SVG and 600-dpi PNG exports; explicit provisional previews.
* Separate narrow target-to-central fungal bridges by assigned core, retain
  irregular outlines and report segmentation_trim_fraction for review.
* Distinguish fitted pre-correction illumination range from remaining fitted
  agar variation and report gain-limit clipping. Preserve existing MI definition.
* Add a saved-results finalization script, coefficient-status output, renewed
  guidance and tests for metadata review, exact plotted ratios and export.

# FunMel 0.3.2

* Put the ZIP workflow repair inside the package: export prepare_photo_archive()
  and use it in the shipped analyse_14_day_archive.R script.
* Resolve nested parent folders; reject wrong ZIPs and missing/ambiguous images
  before processing; use fresh extraction folders to avoid stale-file matches.
* Add preflight file checks to analyze_plates(). Return readable empty schemas
  and an explicit assessment error when all existing images fail analysis.
* Update the README/vignette and test archive paths and empty batch results.

# FunMel 0.3.1

* Retain all original exported MycoHalo function names and the original
  compare_melanization() argument names, with lmerTest mixed inference.
* Add a dedicated fungal central-partner path using separate peripheral,
  central and surrounding-zone image components. Exclude central fungus from MI.
* Return central_fungus, central_object and halo masks; add neutral central
  measurements and halo_status. Preserve the bacterial and control pathways.
* Draw resolved masks in QC instead of unlinked preliminary halo-class pixels.
* Add zymo and central_partner training aliases for fungal confrontations.
* Add per-treatment-plate coefficients and single-control replication labels.
* Match facing-bias corrections to controls from the same set.
* Block coefficients when proposed metadata is unconfirmed.
* Include technical review of all 20 supplied 14-day images and explicit limits
  from metadata errors, single control plates and unresolved halo boundaries.

# FunMel 0.3.0

* Rename the working MycoHalo package, native library and result classes to FunMel.
* Preserve the image kernels and segmentation; retain the four expected target
  positions and actual detected colony boundaries rather than circular masks.
* Require matching-set metadata in coefficient calculations. Never borrow
  controls from other sets; validate independent plate IDs and metadata mappings.
* Add assess_experiment(): raw-MI mixed model with set-treatment cell means and
  a plate random intercept, fitted with lme4/lmerTest and Satterthwaite contrasts.
* Return matched-set coefficients, equal-set descriptive averages, within-set
  contrasts, overall effects and final differences between matched effects.
* Flag differing set coverage and support common-set-only comparisons. Preserve
  shared-control covariance and report Holm-adjusted p-values separately by table.
* Withhold model inference for sparse cells, singular fits or convergence problems;
  keep descriptive coefficients. Add an explicit plate-means model alternative.
* Require explicit permission to pool recorded biological contexts in assessment.
* Replace the unblocked legacy compare_melanization() with the matched assessment.
* Rebuild README, vignette, help pages, metadata template and runnable examples.
