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
