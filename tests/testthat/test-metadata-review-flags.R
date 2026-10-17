test_that("metadata templates include pending logical review flags in memory and CSV", {
  d <- tempfile("metadata-review-")
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  file.create(file.path(d, "plate1.JPG"), file.path(d, "plate2.png"))
  m <- suppressMessages(make_metadata(d))
  saved <- read.csv(file.path(d, "plate_metadata.csv"))
  for (x in list(m, saved)) {
    expect_type(x$qc_pass, "logical")
    expect_type(x$metadata_confirmed, "logical")
    expect_identical(x$qc_pass, c(FALSE, FALSE))
    expect_identical(x$metadata_confirmed, c(FALSE, FALSE))
  }
  expect_error(make_metadata(d), "exists")
})
test_that("standard optional fields and custom columns remain in templates", {
  d <- withr::local_tempdir();file.create(file.path(d,"one.JPG"))
  m <- suppressMessages(make_metadata(d,extra=list(operator="A",`free text`="note")))
  expect_true(all(c("set_id","centre_model","partner_type","fungus","zymo_strain","medium",
    "day","replicate","photo_date","notes","metadata_confirmed","qc_pass") %in% names(m)))
  saved <- read.csv(file.path(d,"plate_metadata.csv"),check.names=FALSE)
  expect_identical(saved[["free text"]],"note");expect_identical(saved$operator,"A")
  expect_true(all(is.na(m$day)));expect_false(m$qc_pass)
})
test_that("unrecorded optional contexts are retained without inventing context values", {
  m <- example_experiment()$metadata
  m$zymo_strain <- NA_character_;m$medium <- NA_character_;m$day <- NA_real_
  expect_silent(validate_metadata(m))
  m$day[1] <- 8
  expect_error(validate_metadata(m),"day must be complete")
})
test_that("metadata collisions cannot replace measured MI or colony identifiers", {
  d <- example_experiment()$colonies
  meta <- unique(d[setdiff(names(d),c("colony_id","MI_mean","detected","is_target"))])
  meta$operator <- "A";meta[["free text"]] <- "note";meta$MI_mean <- 999
  meta$colony_id <- "metadata entry";meta$metadata_confirmed <- FALSE;meta$qc_pass <- FALSE
  x <- list(colonies=d[,c("plate_id","colony_id","MI_mean","detected","is_target")],
            plates=meta[c("plate_id","file")],profiles=data.frame(),spots=data.frame(),failed=data.frame())
  a <- FunMel:::attach_result_metadata(x,meta,initial=TRUE)
  expect_identical(a$metadata,meta)
  expect_equal(a$colonies$MI_mean,d$MI_mean)
  expect_true(all(a$colonies$metadata_MI_mean==999))
  expect_identical(a$colonies$colony_id,d$colony_id)
  meta$metadata_confirmed <- TRUE;meta$qc_pass <- TRUE;meta$operator <- "B"
  z <- finalize_analysis(a,meta,method="plate_means")
  expect_equal(z$colonies$MI_mean,d$MI_mean)
  expect_true(all(z$colonies$operator=="B"))
  expect_identical(z$metadata[["free text"]],meta[["free text"]])
  home <- withr::local_tempdir();FunMel:::write_experiment_tables(z,home)
  saved <- read.csv(file.path(home,"metadata_used.csv"),check.names=FALSE)
  expect_setequal(names(saved),names(meta));expect_equal(saved$MI_mean,meta$MI_mean)
})
