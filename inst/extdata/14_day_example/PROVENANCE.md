# Precomputed teaching tables

These tables were recomputed with FunMel 0.4.6 from all eight unchanged photographs
in extdata/14-days, with dish_diameter_mm=90, max_dim=1200, n_spots=5,
spot_radius_mm=0.4 and n_boot=20. The 90-mm scale is illustrative and has not been
experimentally verified. The illumination safeguard was active; all eight fits
were withheld as degenerate. Every plate yielded four detected target colonies,
finite MI means and five placed spots per target.

Experimental labels, masks and calibration remain unverified; image QC is not confirmed. These are operational teaching results, not biological
ground truth or a substitute for reviewing the original experiment. Each set has
one independent control and three confrontation plates, so its ratios are
descriptive. Four colonies and any spots within a plate are subsamples.

Rerun the documented workflow with the actual dish diameter and accurate
experimental metadata for scientific use. Bootstrap limits use n_boot=20 here
for a quick demonstration; they are not high-precision uncertainty estimates.
