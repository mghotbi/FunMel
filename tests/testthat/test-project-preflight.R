test_that("invalid scales stop before any image is opened", {
  for(x in list(NA_real_,NaN,Inf,0,-1,numeric(),c(80,90),"90")) {
    expect_error(analyze_plate("not-an-image",dish_diameter_mm=x),"finite positive")
    expect_error(analyze_plates("not-an-image",dish_diameter_mm=x),"finite positive")
  }
  expect_error(detect_plate(NULL,dish_diameter_mm=NA_real_),"finite positive")
  expect_error(analyze_plates("not-an-image",n_spots=1.5),"positive integer")
  expect_error(analyze_plates("not-an-image",spot_radius_mm=NA_real_),"finite positive")
  expect_silent(FunMel:::validate_image_settings(list(max_dim=Inf)))
})
test_that("invalid project inputs leave saved metadata and review flags unchanged", {
  home <- withr::local_tempdir()
  p <- structure(list(metadata_file=file.path(home,"plate_metadata.csv")),class="funmel_project")
  writeLines("qc_pass\nTRUE",p$metadata_file)
  original <- readBin(p$metadata_file,"raw",n=file.info(p$metadata_file)$size)
  for(settings in list(list(dish_diameter_mm=NA_real_),list(n_spots=0),
                       list(spot_radius_mm=NA_real_),list(max_clipped_fraction=NA_real_)))
    expect_error(do.call(run_experiment,c(list(p),settings)),"Analysis has not started")
  expect_identical(readBin(p$metadata_file,"raw",n=file.info(p$metadata_file)$size),original)
})
test_that("missing metadata gives recovery instructions without reconstruction", {
  home <- withr::local_tempdir()
  p <- structure(list(metadata_file=file.path(home,"plate_metadata.csv")),class="funmel_project")
  expect_error(run_experiment(p),"Project metadata CSV is missing")
  expect_false(file.exists(p$metadata_file))
  restored <- data.frame(plate_id="plate1",check.names=FALSE)
  restored[["Custom notes"]] <- "keep this value"
  p$metadata_file <- file.path(home,"edited.csv")
  write.csv(restored,p$metadata_file,row.names=FALSE)
  expect_identical(FunMel:::read_project_metadata(p),restored)
})
test_that("all-failed runs save failures and never report measurement success", {
  root <- withr::local_tempdir();dest <- tempfile()
  on.exit(unlink(dest,recursive=TRUE),add=TRUE)
  for(tr in c("control","fungus_A")) {
    d <- file.path(root,"batch",tr);dir.create(d,recursive=TRUE)
    writeLines("invalid image bytes",file.path(d,"plate.JPG"))
  }
  p <- prepare_experiment(root,dest)
  messages <- capture.output(expect_warning(r <- run_experiment(p,verbose=FALSE),
    "No photographs were successfully analyzed"),type="message")
  expect_false(any(grepl("Measurements saved|Successfully analyzed",messages)))
  expect_identical(r$analysis_status,"failed")
  expect_equal(nrow(r$failed),2L)
  expect_true(file.exists(file.path(dest,"failed.csv")))
  expect_error(finish_experiment(p),"Resolve all failed")
})
test_that("partial failures remain explicit and prevent finalization", {
  root <- withr::local_tempdir();dest <- tempfile()
  on.exit(unlink(dest,recursive=TRUE),add=TRUE)
  for(tr in c("control","fungus_A")) {
    d <- file.path(root,"batch",tr);dir.create(d,recursive=TRUE)
    if(tr=="control") {
      sim <- simulate_plate(width=300,height=300,seed=71,layout=plate_layout(centre="none"))
      png::writePNG(sim$image,file.path(d,"plate.png"))
    } else writeLines("invalid image bytes",file.path(d,"plate.JPG"))
  }
  p <- prepare_experiment(root,dest)
  expect_warning(r <- run_experiment(p,n_boot=20,verbose=FALSE),"1 of 2 photographs analyzed; 1 failed")
  expect_identical(r$analysis_status,"partial")
  expect_equal(nrow(r$failed),1L)
  expect_equal(nrow(r$plates),1L)
  expect_error(finish_experiment(p),"Resolve all failed")
})
