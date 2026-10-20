# FunMel 0.4.19

* Distinguish image-processing completion from missing target-colony MI and
  incomplete sampling spots. Export per-colony issues and a run summary.
* Export affected design fields and plate IDs, plus actual segmentation layouts
  and their source. Unlabeled defaults never establish control identity.
* Preserve measurements while withholding comparisons with explicit reasons.
  Missing target MI now records awaiting_measurement_review; no values are
  imputed and incomplete target rows are not silently excluded.
* Name affected plates when a changed layout requires reanalysis. Explain the
  difference between label-only corrections and control-layout corrections.
* Add regression coverage and real-data guidance. The image-analysis algorithms,
  coefficient formula, mixed-model assessment and final figure styling are unchanged.
* Exclude generated vignette intermediates and retain portable release dates.

# FunMel 0.4.18

* Measure images without completing treatment, set or optional context labels.
  Comparison validation remains strict; unmatched designs produce measurement-only
  outputs and a clear comparison status instead of blocking image measurement.
* Record the actual central segmentation model independently of biological labels.
  Unlabeled images use the documented fungal layout by default; control-only runs
  can use default_centre="none". Explicit row layouts take precedence.
* Complete matching assignments later without repeating measurement when the
  segmentation layout is unchanged. All metadata columns are retained.
* Update the README, tutorials, examples and help for the measurement-first workflow.

# FunMel 0.4.17

* Correct Windows image-path validation by normalizing both photographs and
  their image root to the same separator before comparison. Valid nested paths
  work across platforms; paths outside the root, including symlink escapes,
  remain rejected.
* Add path-boundary, Windows drive/UNC, and real-file regression tests.

# FunMel 0.4.16

* Function examples are embedded directly in the vignette. Rendering the catalog
  no longer looks up a script inside an installed FunMel package or loads FunMel.

# FunMel 0.4.15

* The real-data tutorial checks the functions and automatic finalization it
  needs instead of requiring identical source and installed patch versions.
* Tutorials use consistent file graphics, formatting and canonical filenames.
* All three tutorials and their original shared styling are included.
* Exclude the local `tc` backup folder from Git and source builds.

# FunMel 0.4.14

* Website builds install an isolated runtime copy without vignette sources or
  stale vignette indices, so a fresh GitHub checkout does not require generated
  `inst/doc` files. Articles are rendered from the original vignette sources.

# FunMel 0.4.13

* Ensure documentation builds use the current local package and verify automatic finalization before rendering.
* Preserve coloured console progress and isolate rendering from the active R session.
* Make the landscape colour bar adapt to the graphics device so two-panel maps can be resized and replayed.

# FunMel 0.4.12

* Streamline the user guides for installation, metadata preparation, image analysis and interpretation.
* Retain the styled standalone vignettes and complete real-data tutorial.

# FunMel 0.4.11

- Style all three standalone vignettes with embedded cream-and-gold presentation, readable code, responsive tables and tutorial panels.
- Add a styled introduction and contents navigation to the function catalog. Measurement and statistical algorithms are unchanged.

# FunMel 0.4.10

* The real-data tutorial reports absent optional table fields as not reported, identifies the missing fields and loaded package version, and still rejects missing essential measurements. It never invents QC values or treats unavailable illumination status as success.
* Update documentation links and icons.

# FunMel 0.4.9

* Comparison figures omit the embedded caption by default; export full interpretation to a separate caption text file, with optional brief/full caption modes.

* Preparation now accepts a photograph selected in a file chooser and clearly identifies its containing image folder. Existing project RDS selections reopen saved work.
* Separate Get started, detailed real 14-day walkthrough and complete function catalog into three navigable articles.
* Synchronize README, examples, input guidance and website navigation; retain independent-plate and matched-control safeguards.

# FunMel 0.4.8

* Open complete moved projects with load_experiment(), and read saved tables with read_experiment().
* Plot treatment comparisons directly from projects, folders or saved analyses.
* Extend the eight-photo walkthrough with table inspection, figure export and reopening saved results.
* Add an indexed example catalog for every exported function.

# FunMel 0.4.7

- Remove mandatory metadata approval throughout coefficient calculation, finalization and plotting. Valid inputs proceed without changing FALSE to TRUE.
- Replace approval prompts with informative review reminders; new metadata templates do not generate a metadata_confirmed column.
- Preserve supplied metadata columns and values, including any supplied review records, without treating them as a metadata approval gate.
- Retain checks for missing experimental labels, own-set controls, file identity, layout changes and failed images.
- Rewrite the beginner guidance and real-data walkthrough around prepare, run and finish without approval-column editing.

# FunMel 0.4.6

- Retain the 0.4.5 illumination safeguard and its diagnostic outputs.
- Reject invalid diameter, pixel scale and spot inputs before processing or resetting project QC flags.
- Explain missing project metadata and photograph paths with recovery instructions; never replace experimental assignments silently.
- Report complete and partial batch failures accurately, retaining error reports and withholding finalization.
- Replace the interactive diameter prompt with a directly editable numeric value throughout the beginner walkthrough.
- Align README, vignette, generated help and examples; explain illumination status and its implications for matched coefficients.
- Keep long comparison-panel titles and captions within the default export canvas.
- Add regression tests covering invalid inputs, file recovery, preserved metadata and batch failures.

# FunMel 0.4.5

- Withhold the flat-field illumination correction when fitted gains saturate
  over more than `max_clipped_fraction` of the dish (default 2 %) instead of
  clipping and applying it. Saturated gains can introduce position-dependent
  shifts in image lightness. This is a quality safeguard, not validation of
  the photograph or proof of a particular lighting artifact. MI values and
  matched treatment-to-control ratios may change; reanalyze matched plates
  consistently and review the new QC. `max_clipped_fraction = Inf` applies
  the correction unconditionally.
- Report `flat_field_applied` and `flat_field_status` in the plate summary, and
  replace the three downstream warnings about an unusable correction with one
  statement that it was withheld and why.
- Remove a duplicated internal `reassign_pixels()` definition and an
  unreachable branch in the `hyphae_status` summary.
- Drop `rbind()` row-name artefacts (`.x`, `.x1`, ...) from combined colony,
  profile, spot and plate tables.

# FunMel 0.4.4

- Qualify utils::capture.output when exporting session information, resolving the namespace NOTE reported by R CMD check --as-cran.

# FunMel 0.4.3

- Keep eight original example photographs: complete A60_2 and B20_2 sets, each with one control and three treatment plates.
- Warn on unconfirmed image QC by default; optional require_qc=TRUE enforces approval. Experimental metadata confirmation remains required for finalization.
- Retain review flags and report QC status in coefficient tables, saved assessments and comparison captions; never silently mark a plate as passed.
- Handle empty per-colony spot tables without failing to combine the measured spots.
- Update the vignette, README, scripts and fixture tests for the eight-photo workflow and compact website display assets.

# FunMel 0.4.2

- Bundle the original 20 photographs in extdata/14-days with a combined, pending-review metadata template.
- Add a numbered real-data vignette walkthrough and a companion R script, including explicit QC approval and saved-project recovery.
- Document the two source metadata inconsistencies and the limits of comparing treatments represented in separate sets with one control each.

# FunMel 0.4.1

- Include standard optional metadata columns in every generated template.
- Preserve complete supplied metadata in saved results and metadata_used.csv.
- Protect measurements from same-named metadata columns and retain both values.
- Treat entirely unrecorded optional context columns as unrecorded; partially filled contexts still require completion.

# FunMel 0.4.0

- Central fungal growth is represented as dense core plus peripheral hyphae, excluded from Zymoseptoria MI. The default centre is fungus. Output fields and class labels use hyphae terminology.
- Add optional non-overlapping circular spot sampling (n_spots and spot_radius_mm), exported ROI locations and separate spot summaries. Add whole-colony MI_min/MI_max.
- Add prepare_experiment(), run_experiment() and finish_experiment() for folders or ZIPs, editable metadata, saved QC and reviewed outputs.
- Support repeated photograph basenames across batch folders through exact relative-path matching; controls stay within their reviewed set_id.
- Separate different recorded days, strains and media in project finalization. Image processing never silently approves metadata or masks.
- Rewrite the user guide and examples around the current three-stage workflow.

# FunMel 0.3.8

- Metadata templates now include qc_pass = FALSE alongside metadata_confirmed.
- Clarify review flags and migration of existing metadata in the README, vignette and help.
- Add regression coverage for review flags in returned metadata and written CSV files.

# FunMel 0.3.7

- Fit QC legends to the graphics device, omit absent classes and use a neutral non-target-material label.

- Add the FunMel-branded logo and a coordinated pkgdown theme with Menlo code typography.
- Polish the user guide with a workflow overview, concise headings and a collapsible plate-measurement table.
- Move maintenance instructions to CONTRIBUTING.md; retain user-focused documentation and exact GitHub installation instructions.
- Include the documentation site for branch-based GitHub Pages hosting.
- Retain image-analysis and matched-control statistical methods; qualify stats::setNames to resolve the namespace check note.

# FunMel 0.3.6

- Focus primary documentation on four target Zymoseptoria colonies around
  a central fungal colony and hyphae candidate; use two fungal treatment labels
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
* Return central_fungus, central_object and hyphae masks; add neutral central
  measurements and hyphae_status. Preserve the bacterial and control pathways.
* Draw resolved masks in QC instead of unlinked preliminary hyphae-class pixels.
* Add zymo and central_partner training aliases for fungal confrontations.
* Add per-treatment-plate coefficients and single-control replication labels.
* Match facing-bias corrections to controls from the same set.
* Block coefficients when proposed metadata is unconfirmed.
* Include technical review of all 20 supplied 14-day images and explicit limits
  from metadata errors, single control plates and unresolved hyphae boundaries.

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
