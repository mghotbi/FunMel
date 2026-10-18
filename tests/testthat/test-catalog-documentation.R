test_that("the function catalog is self-contained and matches its runnable script", {
  vignette <- testthat::test_path("..", "..", "vignettes", "Function-examples.Rmd")
  script <- testthat::test_path("..", "..", "inst", "examples", "06_all_functions.R")
  skip_if_not(file.exists(vignette) && file.exists(script), "Authored source files are checked in source tests")
  text <- paste(readLines(vignette, warn=FALSE), collapse="\n")
  expected <- paste(readLines(script, warn=FALSE), collapse="\n")
  expect_true(grepl("```{r catalog-source, eval=FALSE}",text,fixed=TRUE))
  expect_true(grepl(expected,text,fixed=TRUE))
  setup <- strsplit(text,"```",fixed=TRUE)[[1]][2]
  expect_false(grepl("library(FunMel)",setup,fixed=TRUE))
  expect_false(grepl("system.file(",text,fixed=TRUE))
})
