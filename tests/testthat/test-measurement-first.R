test_that("measurement validation accepts incomplete designs but preserves identity checks", {
  m <- data.frame(file=c("a.JPG","b.JPG"),plate_id=c("A","B"),
    set_id=NA_character_,treatment=NA_character_,centre_model=NA_character_,day=c(14,NA))
  expect_silent(validate_metadata(m,stage="measurement"))
  expect_error(validate_metadata(m),"set_id")
  m$plate_id <- c("A","A")
  expect_error(validate_metadata(m,stage="measurement"),"globally unique")
  m$plate_id <- c("A","B");m$centre_model <- c("oops",NA)
  expect_error(validate_metadata(m,stage="measurement"),"centre_model")
})

test_that("layout fallback is computational and explicit per-image settings win", {
  m <- data.frame(treatment=NA_character_,centre_model=NA_character_)
  expect_identical(layout_by_treatment(m)$centre,"fungus")
  expect_identical(layout_by_treatment(m,default_centre="none")$centre,"none")
  m$treatment <- "control"
  expect_identical(layout_by_treatment(m)$centre,"none")
  m$centre_model <- "fungus"
  expect_error(layout_by_treatment(m),"Control")
  m$treatment <- NA_character_;m$centre_model <- "none"
  expect_identical(layout_by_treatment(m,default_centre="fungus")$centre,"none")
  expect_true(is.na(m$treatment))
})

measurement_first_project <- function() {
  root <- withr::local_tempdir(.local_envir=parent.frame())
  for(i in 1:2) {
    sim <- simulate_plate(width=400,height=400,seed=70+i,
      layout=plate_layout(centre=if(i==1) "none" else "fungus"))
    png::writePNG(sim$image,file.path(root,paste0("photo_",i,".png")))
  }
  dest <- tempfile();withr::defer(unlink(dest,recursive=TRUE),envir=parent.frame())
  p <- prepare_experiment(root,dest)
  m <- read.csv(p$metadata_file,check.names=FALSE,stringsAsFactors=FALSE)
  m$centre_model <- c("none",NA_character_)
  m[["Observer notes"]] <- c("keep control note","keep fungus note")
  m$day <- c(14,NA_real_) # A partial optional context must not block measurement.
  utils::write.csv(m,p$metadata_file,row.names=FALSE,na="")
  p
}

test_that("unlabeled projects measure, save, resume and later match without remeasurement", {
  p <- measurement_first_project()
  m <- read.csv(p$metadata_file,check.names=FALSE,stringsAsFactors=FALSE)
  r <- suppressWarnings(run_experiment(p,n_spots=2,n_boot=0,max_dim=400,verbose=FALSE))
  expect_equal(nrow(r$failed),0L)
  expect_identical(r$analysis_status,"complete")
  expect_equal(nrow(r$colonies),8L)
  expect_equal(nrow(r$spots),16L)
  expect_identical(r$analysis_layout$centre_model,c("none","fungus"))
  expect_true(all(is.na(r$metadata$treatment)))
  expect_equal(r$metadata[["Observer notes"]],m[["Observer notes"]])
  expect_equal(r$metadata$day,m$day)
  expect_equal(nrow(read_experiment(load_experiment(p$project_dir))$colonies),8L)
  before <- unname(tools::md5sum(p$result_file))
  z <- suppressWarnings(finish_experiment(p))
  expect_identical(z$comparison_status,"awaiting_design")
  expect_equal(z$colonies$MI_mean,r$colonies$MI_mean)
  expect_equal(nrow(z$melanization_coefficient),0L)
  expect_false(file.exists(file.path(p$project_dir,"treatment_comparison.pdf")))
  expect_null(plot_treatment_comparison(z))
  expect_null(plot_treatment_comparison(p))
  status <- read.csv(file.path(p$project_dir,"comparison_status.csv"))
  expect_identical(status$status,"awaiting_design")
  expect_true(file.exists(file.path(p$project_dir,"spots.csv")))
  # Complete only the true matching design. Entire optional contexts may remain blank.
  m$treatment <- c("control","fungus_A");m$set_id <- "own_set";m$day <- NA_real_
  utils::write.csv(m,p$metadata_file,row.names=FALSE,na="")
  z <- suppressWarnings(finish_experiment(p))
  expect_identical(z$comparison_status,"complete")
  expect_equal(nrow(z$melanization_coefficient),1L)
  expect_equal(z$melanization_coefficient$melanization_coefficient,
    z$melanization_coefficient$MI_treatment_mean/z$melanization_coefficient$MI_control_mean)
  expect_identical(unname(tools::md5sum(p$result_file)),before)
  expect_true(file.exists(file.path(p$project_dir,"treatment_comparison.pdf")))
  expect_equal(z$metadata[["Observer notes"]],m[["Observer notes"]])
  # Invalidating the matching design archives old figures rather than keeping stale ones.
  m$treatment <- NA_character_;utils::write.csv(m,p$metadata_file,row.names=FALSE,na="")
  pending <- suppressWarnings(finish_experiment(p))
  expect_identical(pending$comparison_status,"awaiting_design")
  expect_false(file.exists(file.path(p$project_dir,"treatment_comparison.pdf")))
  old <- list.dirs(p$project_dir,recursive=FALSE,full.names=TRUE)
  old <- old[grepl("previous_comparisons_",basename(old))]
  expect_equal(length(old),1L)
  expect_true(file.exists(file.path(old,"treatment_comparison.pdf")))
  # Declaring a previously fungal layout to be a control requires remeasurement.
  m$treatment <- c("fungus_A","control");utils::write.csv(m,p$metadata_file,row.names=FALSE,na="")
  expect_error(finish_experiment(p),"requires image reanalysis")
})

test_that("low-level batch measurement accepts labels missing and generates IDs", {
  root <- withr::local_tempdir()
  sim <- simulate_plate(width=400,height=400,seed=123)
  f <- file.path(root,"unlabeled.png");png::writePNG(sim$image,f)
  m <- data.frame(file=basename(f),`User field`="retain",check.names=FALSE)
  r <- suppressWarnings(analyze_plates(f,metadata=m,n_boot=0,verbose=FALSE))
  expect_equal(nrow(r$failed),0L)
  expect_identical(r$metadata$plate_id,"unlabeled")
  expect_identical(r$metadata[["User field"]],"retain")
  expect_equal(nrow(r$melanization_coefficient),0L)
  expect_true(nzchar(r$coefficient_error))
})
