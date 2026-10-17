# A flat-field correction that saturates its own gain limits over much of the
# dish is not an illumination gradient; applying it rescales colonies by a
# position-dependent factor and biases MI. It must be withheld, not clipped
# and applied silently.

real_plate <- function(name = "A60_2_14_days/2026_10_02_99_38.JPG") {
  f <- file.path(system.file("extdata/14-days", package = "FunMel"), name)
  if (!nzchar(f) || !file.exists(f)) skip("bundled example photographs not installed")
  f
}

test_that("a usable illumination fit is still applied", {
  sim <- simulate_plate(width = 400, height = 500, seed = 11, vignetting = 0.3)
  p <- model_background(detect_plate(read_plate(sim$image)))
  expect_true(p$bg$flat_field)
  expect_identical(p$bg$flat_field_status, "applied")
  expect_lte(p$bg$flat_field_clipped_fraction, 0.02)
})

test_that("flat_field = FALSE is reported as not requested", {
  sim <- simulate_plate(width = 400, height = 500, seed = 11)
  p <- model_background(detect_plate(read_plate(sim$image)), flat_field = FALSE)
  expect_false(p$bg$flat_field)
  expect_identical(p$bg$flat_field_status, "not_requested")
  expect_false(p$bg$flat_field_requested)
  expect_true(is.na(p$bg$flat_field_clipped_fraction))
})

test_that("a degenerate fit is withheld and reported", {
  p <- detect_plate(read_plate(real_plate(), max_dim = 900))
  g <- model_background(p)
  expect_false(g$bg$flat_field)
  expect_identical(g$bg$flat_field_status, "withheld_degenerate_fit")
  expect_gt(g$bg$flat_field_clipped_fraction, 0.02)
  # the diagnostic that justified withholding is still recorded
  expect_true(is.finite(g$bg$illumination_range_pct))
})

test_that("withholding leaves the pixels untouched", {
  p <- detect_plate(read_plate(real_plate(), max_dim = 900))
  withheld <- model_background(p)
  never <- model_background(p, flat_field = FALSE)
  expect_equal(withheld$lab[, , 1], never$lab[, , 1])
  expect_equal(withheld$bg$agar_lab, never$bg$agar_lab)
})

test_that("max_clipped_fraction = Inf restores unconditional correction", {
  p <- detect_plate(read_plate(real_plate(), max_dim = 900))
  forced <- model_background(p, max_clipped_fraction = Inf)
  never <- model_background(p, flat_field = FALSE)
  expect_true(forced$bg$flat_field)
  expect_identical(forced$bg$flat_field_status, "applied")
  # and it really does move the measured lightness, which is why it is guarded
  expect_gt(max(abs(forced$bg$agar_lab - never$bg$agar_lab)), 1)
})

test_that("max_clipped_fraction is validated", {
  sim <- simulate_plate(width = 300, height = 400, seed = 12)
  p <- detect_plate(read_plate(sim$image))
  expect_error(model_background(p, max_clipped_fraction = -1), "max_clipped_fraction")
  expect_error(model_background(p, max_clipped_fraction = c(0.1, 0.2)), "max_clipped_fraction")
  expect_error(model_background(p, max_clipped_fraction = NA_real_), "max_clipped_fraction")
})

test_that("the plate summary carries the flat-field outcome", {
  res <- suppressWarnings(analyze_plate(real_plate(), layout = plate_layout(centre = "fungus"),
                                        max_dim = 900, n_boot = 20, verbose = FALSE))
  expect_false(res$plate_summary$flat_field_applied)
  expect_identical(res$plate_summary$flat_field_status, "withheld_degenerate_fit")
  # one clear warning about the withheld correction, not the old trio of
  # downstream complaints about a correction that was never usable
  expect_true(any(grepl("withheld", res$warnings)))
  expect_false(any(grepl("pre-correction illumination range", res$warnings)))
})

test_that("combined result tables carry no rbind row-name artefacts", {
  sim <- simulate_plate(width = 400, height = 500, seed = 13)
  res <- analyze_plate(sim$image, n_boot = 20, verbose = FALSE)
  expect_identical(rownames(res$colonies), as.character(seq_len(nrow(res$colonies))))
})
