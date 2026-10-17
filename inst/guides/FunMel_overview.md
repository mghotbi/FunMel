# FunMel: purpose, measurements and algorithms

FunMel connects fungal confrontation photographs to reproducible measurements,
explicit matched controls and plate-aware statistical assessment. Its standard
layout has four Zymoseptoria tritici targets around another fungus. Central
mycelium, including the dense core and connected peripheral hyphal growth,
is separated from target measurements. These are image-based tissue masks,
not inhibition boundaries, species identification or microscopic hyphal counts.

## Practical benefit alongside ImageJ/Fiji

ImageJ/Fiji already supports ROI measurements, manual segmentation and macro
automation. FunMel integrates those assay tasks with batch provenance, per-set
control matching, review flags, statistical status and figure/table exports in R.
It can reduce bookkeeping and help users reproduce a batch analysis. Difficult
boundaries may still require manual review or ImageJ. No head-to-head accuracy
or speed superiority is claimed. RGB brightness and CIELAB MI are different
quantities; comparisons require aligned masks, calibration and colour conversion.

## Measurements

Whole-colony MI is 100 minus CIELAB L*, measured over eligible interior pixels.
Minimum/mean/maximum are observed pixel summaries, not melanin concentrations
or confidence limits. Optional n_spots and spot_radius_mm specify circular,
non-overlapping ROIs placed by a deterministic farthest-point algorithm. Their
centres, radius and measurements are exported and plotted for review. Spot
summaries remain distinct from whole-colony MI and do not increase replication.

## Main functions

| Function | Role |
|---|---|
| prepare_experiment | Unpack a ZIP or index folders and prepare editable metadata |
| run_experiment | Analyze all listed plates and export QC and measurements |
| finish_experiment | Apply recorded review, calculate own-set coefficients and export figures |
| analyze_plate / analyze_plates | Advanced single/batch image analysis |
| sample_colony_spots | Reproducible circular sampling within usable target masks |
| melanization_coefficient | Ratios of equally weighted plate MI means within each control set |
| assess_experiment | Plate-aware models, matched contrasts and explicit diagnostic status |
| plot_treatment_comparison | Descriptive plate-level publication exports |

## Behind the scenes

Dish fitting establishes image scale and geometry. Agar-colour estimation
supports illumination correction. Layout-initialized colour/texture mixtures
provide candidate target and central-growth classes. Distance-transform cores
seed watershed separation; morphological clean-up and edge refinement reduce
specks and mixed boundary pixels. Broad fungal regions may still be ambiguous
when organisms touch or have similar appearance. Spatial spot placement uses
only complete usable circles, with no rim fallback or artificial duplication.

Colonies are equally weighted within plates and plates within their matching
sets. Controls are never pooled across set IDs. The default mixed assessment
uses lme4/lmerTest on raw MI with independent plate structure and matched
contrasts. It retains shared-control covariance. Sparse designs and problematic
fits are explicitly limited to descriptive results. Repeated images of the same
plate across time require a study-specific repeated-measures model. The default
workflow reports different recorded days, strains and media separately.
