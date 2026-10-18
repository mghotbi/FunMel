# FunMel 0.4.9 maintenance and validation checklist

Use independent plates as the biological units. Four target colonies and any
sampling spots within a plate are subsamples. Each treatment is compared with
controls in its own reviewed set_id. Keep different days, strains and media
separate unless a study-specific model explicitly supports joint analysis.

Before release, regenerate help, build vignettes, run the test suite and run
R CMD check on the source archive. Rebuild pkgdown from the authored sources
and commit docs/ for branch-based GitHub Pages. Check local links, figures,
metadata examples and exported statistics. Keep credentials and private images
out of the repository.

Review central fungal core and hyphal-growth masks independently of target
colony masks. The algorithm does not identify species or infer inhibition.
Spot ROI location, radius, containment and missing-placement status must be
traceable. Do not interpret pixel extrema as confidence limits or substitute
spot measurements for whole-colony MI without labeling the response.

The default mixed model uses set-treatment cell means and plate structure.
Its replicated-cell guard does not establish universal sample-size adequacy.
Inspect convergence, singularity, residual assumptions and the actual design.
A descriptive ratio from a single control is not a significance test.

Synthetic fixtures test computation, not universal biological accuracy. Real
photographs need blinded annotated validation, consistent imaging and appropriate
positive/negative controls. The bundled provisional measured table is not ground
truth. No accuracy/speed superiority to ImageJ/Fiji is claimed.

Check that no metadata approval gate or required approval-flag editing appears
in public guides, examples, help or the rendered site. The standard workflow
uses reminders; structural metadata checks and failed-image checks remain.

For 0.4.9, run both installed scripts `examples/06_all_functions.R` and
`examples/walkthrough_14_days.R`. Check catalog coverage against namespace
exports. Interactive tissue annotation requires a separate human click session.
Test moved projects, direct saved-result reading, missing metadata errors and
project-input comparison plotting. Reconnection must preserve measurements and
experimental assignments and must not invent missing metadata.
