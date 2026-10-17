# Validation

Run tests from the source project with testthat::test_local(). The tests cover
image kernels, simulated geometry and colour, central fungal separation, spot
ROI containment and arithmetic, archive matching and reviewed project export.
Synthetic tests are computational checks, not validation of organism identity
or guaranteed segmentation accuracy on arbitrary photographs. Inspect every
new photograph and establish imaging/biological validation for each assay.
The bundled measured 14-day table is provisional and must not be treated as
validated ground truth. Reanalyze original photographs before adopting changed
segmentation settings in an experiment.
