test_that("approval records never gate coefficients or plotting", {
  d <- example_experiment(seed=42)$colonies
  base <- melanization_coefficient(d)$coefficients
  for(flag in list(FALSE,NA, "unreviewed")) {
    d$metadata_confirmed <- flag
    z <- melanization_coefficient(d)
    expect_equal(z$coefficients$melanization_coefficient,base$melanization_coefficient)
    expect_identical(z$target_data$metadata_confirmed,d$metadata_confirmed)
    p <- plot_treatment_comparison(d)
    expect_s3_class(p,"ggplot")
    expect_false(grepl("confirmed or",attr(p,"FunMel_statistics")$metadata_status[1]))
  }
})
test_that("finalization requires valid design but not metadata approval", {
  d <- example_experiment(seed=42)$colonies
  m <- unique(d[setdiff(names(d),c("colony_id","MI_mean","detected","is_target"))])
  m$metadata_confirmed <- FALSE
  m[["User notes"]] <- "retain exactly"
  r <- list(colonies=d,plates=m,profiles=data.frame(),spots=data.frame(),failed=data.frame())
  z <- suppressWarnings(finalize_analysis(r,m))
  expect_equal(nrow(z$melanization_coefficient),6L)
  expect_true(all(!z$metadata$metadata_confirmed))
  expect_identical(z$metadata[["User notes"]],m[["User notes"]])
  expect_equal(z$colonies$MI_mean,d$MI_mean)
  bad <- m;bad$treatment[1] <- NA
  z_bad <- suppressWarnings(finalize_analysis(r,bad))
  expect_identical(z_bad$comparison_status,"awaiting_design")
  expect_equal(nrow(z_bad$melanization_coefficient),0L)
  r$failed <- data.frame(file="missing.JPG",error="missing")
  expect_error(finalize_analysis(r,m),"failed plates")
})
