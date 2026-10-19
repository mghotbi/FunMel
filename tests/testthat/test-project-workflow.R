project_folders <- function() {
  root <- withr::local_tempdir(.local_envir=parent.frame())
  for(b in c("day8/batch1","day10/batch1")) for(tr in c("control","fungus_A")) {
    d <- file.path(root,b,tr);dir.create(d,recursive=TRUE)
    writeLines("template only",file.path(d,"plate.JPG"))
  }
  root
}
test_that("folder preparation distinguishes batches, days and repeated basenames", {
  root <- project_folders();dest <- tempfile()
  on.exit(unlink(dest,recursive=TRUE),add=TRUE)
  project <- prepare_experiment(root,dest)
  m <- read.csv(project$metadata_file)
  expect_equal(nrow(m),4L);expect_equal(length(unique(m$set_id)),2L)
  expect_equal(length(unique(m$plate_id)),4L)
  expect_true(all(!m$qc_pass));expect_false("metadata_confirmed" %in% names(m))
  expect_true(all(c("fungus","zymo_strain","medium","day","replicate","photo_date","notes") %in% names(m)))
  expect_true(all(m$centre_model[m$treatment=="control"]=="none"))
  expect_true(all(m$centre_model[m$treatment!="control"]=="fungus"))
  expect_silent(validate_metadata(m,file.path(root,m$relative_file)))
  ix <- FunMel:::match_image_rows(rev(file.path(root,m$relative_file)),m)
  expect_equal(ix,4:1)
  expect_error(prepare_experiment(root,dest),"new or empty")
})
test_that("nested ZIP preparation preserves source paths and proposed control matching", {
  root <- project_folders();dest <- tempfile();z <- tempfile(fileext=".zip")
  on.exit(unlink(c(dest,z),recursive=TRUE),add=TRUE)
  withr::with_dir(root,utils::zip(z,list.files(".",recursive=TRUE),flags="-q"))
  project <- prepare_experiment(z,dest)
  m <- read.csv(project$metadata_file)
  expect_equal(nrow(m),4L);expect_equal(length(unique(m$set_id)),2L)
  expect_true(all(file.exists(file.path(project$image_root,m$relative_file))))
})
test_that("ambiguous flat image folders are not automatically assigned controls", {
  root <- withr::local_tempdir();writeLines("template",file.path(root,"c1.JPG"))
  dest <- tempfile();on.exit(unlink(dest,recursive=TRUE),add=TRUE)
  p <- prepare_experiment(root,dest);m <- read.csv(p$metadata_file)
  expect_true(all(is.na(m$treatment)))
  expect_error(validate_metadata(read.csv(p$metadata_file)),"treatment")
  expect_silent(validate_metadata(read.csv(p$metadata_file),stage="measurement"))
})
test_that("duplicate basenames are analyzed with exact metadata row mapping", {
  root <- project_folders();dest <- tempfile();on.exit(unlink(dest,recursive=TRUE),add=TRUE)
  p <- prepare_experiment(root,dest);m <- read.csv(p$metadata_file)
  # Invalid image bytes exercise batch mapping without expensive image processing.
  z <- analyze_plates(file.path(root,m$relative_file),metadata=m,
    layout=layout_by_treatment,coefficient_control=NULL,verbose=FALSE)
  expect_equal(nrow(z$failed),4L)
})
test_that("prepare-run-review-finish works on unseen image names and a shared control", {
  root <- withr::local_tempdir();dest <- tempfile()
  on.exit(unlink(dest,recursive=TRUE),add=TRUE)
  for(tr in c("control","fungus_A")) {
    d <- file.path(root,"new_batch",tr);dir.create(d,recursive=TRUE)
    sim <- simulate_plate(width=400,height=400,seed=71,
      layout=plate_layout(centre=if(tr=="control") "none" else "fungus"))
    png::writePNG(sim$image,file.path(d,"same_name.png"))
  }
  p <- prepare_experiment(root,dest)
  r <- suppressWarnings(run_experiment(p,n_spots=2,spot_radius_mm=0.3,n_boot=20,verbose=FALSE))
  expect_equal(nrow(r$failed),0L)
  expect_equal(nrow(r$colonies),8L);expect_true(nrow(r$spots)>0)
  expect_true(file.exists(p$result_file));expect_equal(length(list.files(p$qc_dir)),2L)
  auto <- suppressWarnings(finish_experiment(p))
  expect_equal(nrow(auto$melanization_coefficient),1L)
  expect_false("metadata_confirmed" %in% names(auto$metadata))
  expect_true(all(c("fungus","notes","replicate") %in% names(r$metadata)))
  expect_true(file.exists(file.path(dest,"metadata_used.csv")))
  m <- read.csv(p$metadata_file);m$metadata_confirmed <- TRUE;m$qc_pass <- TRUE
  write.csv(m,p$metadata_file,row.names=FALSE)
  expect_warning(z <- finish_experiment(p),"Fewer than two")
  expect_equal(nrow(z$melanization_coefficient),1L)
  expect_equal(z$melanization_coefficient$n_control_plates,1L)
  expect_true(all(z$spots$qc_pass))
  expect_true(file.exists(file.path(dest,"treatment_comparison.pdf")))
})
test_that("final project assessment keeps different recorded days separate", {
  home <- withr::local_tempdir()
  d <- example_experiment(seed=41)$colonies
  d$day <- ifelse(d$set_id=="S1",8L,10L)
  d$metadata_confirmed <- FALSE; d$qc_pass <- FALSE
  m <- unique(d[setdiff(names(d),c("colony_id","MI_mean","detected","is_target"))])
  r <- list(colonies=d,profiles=data.frame(),spots=data.frame(),plates=m,failed=data.frame())
  p <- structure(list(project_dir=home,metadata_file=file.path(home,"plate_metadata.csv"),
    result_file=file.path(home,"image_analysis.rds"),reviewed_file=file.path(home,"reviewed.rds")),class="funmel_project")
  saveRDS(r,p$result_file);m$metadata_confirmed <- TRUE;m$qc_pass <- TRUE
  write.csv(m,p$metadata_file,row.names=FALSE)
  z <- suppressWarnings(finish_experiment(p,method="plate_means"))
  expect_equal(length(z$context_results),2L)
  expect_true(file.exists(file.path(home,"context_index.csv")))
  for(a in z$context_results) expect_length(unique(a$colonies$day),1L)
  expect_null(z$assessment)
})
