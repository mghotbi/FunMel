test_that("QC warnings retain every plate, flags and measured coefficients", {
  d <- example_experiment(seed=42)$colonies
  baseline <- melanization_coefficient(d)
  d$qc_pass <- TRUE;d$qc_pass[d$plate_id==d$plate_id[1]] <- FALSE
  expect_warning(mc <- melanization_coefficient(d),"Image QC")
  expect_equal(mc$coefficients$melanization_coefficient,baseline$coefficients$melanization_coefficient)
  expect_equal(nrow(mc$target_data),nrow(d))
  expect_identical(mc$target_data$qc_pass,d$qc_pass)
  expect_true(any(mc$coefficients$qc_review_status=="unconfirmed"))
  expect_equal(mc$qc_review$n_confirmed_plates,length(unique(d$plate_id))-1L)
  expect_error(melanization_coefficient(d,require_qc=TRUE),"qc_pass")
  expect_error(melanization_coefficient(d,require_qc=NA),"TRUE or FALSE")
  d$qc_pass <- NA
  expect_warning(melanization_coefficient(d),"Image QC")
  d$qc_pass <- NULL
  expect_error(melanization_coefficient(d,require_qc=TRUE),"qc_pass")
})

test_that("project finalization warns by default and strict QC remains optional", {
  home <- withr::local_tempdir()
  d <- example_experiment(seed=42)$colonies
  m <- unique(d[setdiff(names(d),c("colony_id","MI_mean","detected","is_target"))])
  m$metadata_confirmed <- TRUE;m$qc_pass <- FALSE
  r <- list(colonies=d,plates=m,profiles=data.frame(),spots=data.frame(),failed=data.frame())
  p <- structure(list(project_dir=home,metadata_file=file.path(home,"plate_metadata.csv"),
    result_file=file.path(home,"image_analysis.rds"),reviewed_file=file.path(home,"reviewed.rds")),class="funmel_project")
  write.csv(m,p$metadata_file,row.names=FALSE);saveRDS(r,p$result_file)
  expect_error(finish_experiment(p,require_qc=TRUE),"qc_pass")
  # finish_experiment warns at calculation and export; both retain unconfirmed status.
  seen <- character()
  z <- withCallingHandlers(finish_experiment(p),warning=function(w) {
    seen <<- c(seen,conditionMessage(w));invokeRestart("muffleWarning")
  })
  expect_true(any(grepl("Image QC",seen)))
  expect_identical(z$qc_review$status,"unconfirmed")
  expect_false(any(z$metadata$qc_pass))
  expect_true(file.exists(file.path(home,"treatment_comparison.pdf")))
  status <- read.csv(file.path(home,"qc_review_status.csv"))
  expect_identical(status$status,"unconfirmed")
  expect_false(status$require_qc)
  expect_equal(status$n_confirmed_plates,0L)
  m$qc_pass <- TRUE;write.csv(m,p$metadata_file,row.names=FALSE)
  expect_silent(strict <- finalize_analysis(r,m,require_qc=TRUE))
  expect_identical(strict$qc_review$status,"confirmed")
  expect_true(all(strict$metadata$qc_pass))
})
