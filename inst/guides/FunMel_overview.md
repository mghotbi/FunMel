# Why FunMel? A README-ready overview

FunMel connects confrontation-plate photographs to reproducible measurements,
explicit treatment–control matching and statistical assessment in R. Its main
benefit is a consistent workflow: image processing, colony summaries, quality
review, matched melanization coefficients and exportable figures stay linked to
the same biological plate and experimental metadata.

It was developed for four approximately round *Zymoseptoria tritici* colonies
surrounding a fungal or bacterial partner. The inoculation layout, dish diameter
and analysis settings are configurable. Detected boundaries remain irregular
where the tissue is irregular; the software does not identify species from an
image. Mean MI is `100 - CIELAB L*`, a darkness proxy rather than a measurement of
melanin concentration. The central partner is excluded from target MI, and halo
regions are reported as colour-zone candidates requiring interpretation.

## How users benefit alongside ImageJ/Fiji

ImageJ already provides intensity/area measurements, ROI management, threshold
particle analysis and macro automation. FunMel does not claim inherently greater
accuracy or guaranteed speed. Its assay-specific contribution is integrating
these measurement tasks with known inoculation layouts, per-set control metadata,
plate-aware models, diagnostic statuses and scripted result/figure export. This
can reduce manual bookkeeping and make a batch analysis easier to rerun and audit.
ImageJ remains useful for inspecting or manually analysing difficult images.
ImageJ RGB brightness and FunMel CIELAB MI are different numerical quantities;
validation must align masks, colour conversion, calibration and excluded pixels.

## Main functions

| Function | Purpose |
|---|---|
| `plate_layout()` | Define expected target positions and the central recipe |
| `analyze_plate()` | Process one image; retain masks for QC |
| `analyze_plates()` | Process arbitrary image paths using explicit metadata |
| `make_metadata()`, `validate_metadata()` | Record provenance and check control matching |
| `prepare_photo_archive()` | Resolve metadata-listed photos in an arbitrary ZIP |
| `melanization_coefficient()` | Calculate plate means and own-set treatment/control ratios |
| `assess_experiment()` | Model raw MI with plate structure and matched contrasts |
| `finalize_analysis()` | Apply verified metadata and review decisions to saved measurements |
| `plot_treatment_comparison()` | Export descriptive PDF/SVG/600-dpi PNG comparisons |

## Behind the scenes

The workflow orients/resizes an image and fits its approximately circular dish
to establish geometry and scale. Robust agar-colour estimation supports a trimmed
polynomial illumination model in linear RGB. Layout-initialized colour/texture
mixtures, or a supplied trained classifier, assign candidate tissue classes.
Distance-transform cores seed watershed separation; morphology and edge refinement
reduce specks and blurred boundaries. Narrow connections to central fungal margins
are separated where appropriate and reported for review. Colony interiors provide
CIELAB, MI, geometry and edge-to-centre profiles. C++ kernels implement image operations.

Descriptive coefficients give colonies equal weight within a plate and plates
equal weight within a set. Statistical assessment retains raw colony observations
with a plate random intercept and fixed set-treatment means (`lme4`/`lmerTest`).
Shared-control covariance is retained in MI contrasts; ratios themselves are not
treated as independent observations. Sparse or problematic fits report explicit
status instead of manufacturing significance. Comparable imaging, verified metadata,
adequate biological replication and mask review remain essential.

Sources for the ImageJ and model capabilities:
[ImageJ measurements and ROI Manager](https://imagej.net/ij/docs/guide/146-30.html),
[ImageJ macros](https://imagej.net/ij/developer/macro/macros.html), and
[lme4 model specification](https://lme4.github.io/lme4/reference/lmer.html).
