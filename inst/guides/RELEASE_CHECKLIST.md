# FunMel 0.3.8 release checklist and scope

## Experimental agreement

Retain independent dishes through inference. Target colonies within a dish are
subsamples; normalize descriptive responses using the appropriate set's control.
Summarize for display without replacing independent observations by treatment
means in the statistical model. Multiple treatments may share one batch control
group, listed once. Multiple control plates contribute to that set's mean.

The built-in raw-MI model has fixed set-treatment cell means and a plate random
intercept. It conditions on observed sets. It is not a random-batch additive
model and is not a universal choice for every design. The two-plate-per-cell guard
is a conservative implementation policy; it does not prove that all single-control
designs are statistically impossible. Growth inhibition, MI ratios and radial
asymmetry are different responses. A factorial design needs explicit factor terms.

## Nine-point audit

| Requirement | Included resource / validation |
|---|---|
| Tests | Unit/integration tests for image geometry, colour/calibration, masks, metadata, matched arithmetic, inference guards, shared controls, ZIP paths, saved review and figure export |
| Complete beginner vignette | Executed synthetic images/arithmetic/models/plots; real-folder/ZIP recipes marked as user-data steps |
| Complete README | Installation, version checks, no-data quickstarts, metadata, real images, review, inference, export, troubleshooting and developer setup |
| General use | Arbitrary image names, explicit metadata, nested folders/ZIPs, configurable/per-image layouts; independent synthetic arrangements tested |
| Efficient explanation | Function/output maps and action-oriented warning tables |
| Later pkgdown/GitHub | Source project and ignore files supplied; no external publication performed |
| Separate overview | guides/FunMel_overview.md: benefits alongside ImageJ, functions, algorithm and limits |
| Ignore files | .gitignore and .Rbuildignore in the project ZIP; private/generated/compiled files excluded |
| Beginner examples | One real-data and three synthetic no-download scripts; actual 20-photo metadata replaces the fictional 10-photo CSV |

## Running validation in the source project

Install the declared dependencies plus testthat, knitr, rmarkdown, png and withr.
Run `testthat::test_local()`, then `R CMD build .` and
`R CMD check --no-manual FunMel_0.3.8.tar.gz`. The vignette is executed and rebuilt
as part of package checks. The beginner scripts can be rerun from system.file()
after installation. If re-generating help, install roxygen2 and run
`roxygen2::roxygenise()` before rebuilding.

Tests establish computational behaviour for specified fixtures and schematic
truth, not universal biological accuracy. The supplied photographs were inspected
in earlier release validation; their unverified experimental metadata and lighting
limitations remain. New layout/provenance helpers do not silently confirm those
images. A successful detected count is not annotated ground truth.

## Before publishing your own package/site

Record the platform and R/dependency versions used for checks. Review warnings,
examples and image assumptions. Add the real repository/site URLs and pkgdown
configuration when ready. Decide whether generated docs/ should be committed for
your hosting setup. Keep user/private photographs out of the repository; inspect
.gitignore before the first commit. Do not publish credentials or .Renviron.

For biological validation, use blinded annotated images beyond the development
set, assess boundary and measurement agreement, include negative/positive controls,
and quantify robustness to imaging conditions. No superiority to ImageJ in accuracy
or speed is established by the current tests. External benchmarking remains a
separate task; it is not claimed complete.

## Figure update (0.3.8)

Controls use outlined squares; treatments use contrasting filled circles.
Independent plate dots have separate lanes to remain visible when MI overlaps.
Means and descriptive SDs, sample sizes and conditional matched-ratio SDs
are exported in an accompanying CSV. Single-control SD is unavailable.
Image segmentation and colony measurements are unchanged.
