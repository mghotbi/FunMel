load_tutorial_display <- function() {
  p <- testthat::test_path("..","..","vignettes","Real-14-day.Rmd")
  if (!file.exists(p)) p <- system.file("doc","Real-14-day.Rmd",package="FunMel")
  skip_if_not(nzchar(p) && file.exists(p),"Source or installed vignette is required")
  lines <- readLines(p)
  a <- match("# BEGIN tutorial_table14",lines);b <- match("# END tutorial_table14",lines)
  e <- new.env(parent=globalenv())
  eval(parse(text=lines[(a+1L):(b-1L)]),e)
  list(env=e,code=lines[(a+1L):(b-1L)],source=lines)
}
test_that("missing optional QC fields are visible and never inferred", {
  h <- load_tutorial_display();d <- data.frame(plate_id=c("C","T"),MI_mean=c(40,60))
  fields <- c("plate_id","n_colonies_detected","central_detected","flat_field_status")
  out <- h$env$tutorial_table14(d,fields,required="plate_id",label="QC")
  expect_identical(names(out),fields)
  expect_identical(out$plate_id,d$plate_id)
  expect_true(all(is.na(out$n_colonies_detected)))
  expect_true(all(is.na(out$central_detected)))
  expect_true(all(is.na(out$flat_field_status)))
  expect_identical(names(d),c("plate_id","MI_mean"))
  report <- capture.output(h$env$report_missing14(out,"plate QC"))
  expect_match(paste(report,collapse=" "),"Not reported")
  expect_match(paste(report,collapse=" "),"flat_field_status")
  expect_match(paste(report,collapse=" "),as.character(getNamespaceVersion("FunMel")),fixed=TRUE)
})
test_that("essential measurements cannot be replaced by optional placeholders", {
  h <- load_tutorial_display()
  expect_error(h$env$tutorial_table14(data.frame(plate_id="P"),c("plate_id","MI_mean"),
    required=c("plate_id","MI_mean"),label="colony measurements"),"lacks required fields: MI_mean")
  d <- data.frame(plate_id="P",MI_mean=42,flat_field_status="withheld_degenerate_fit")
  out <- h$env$tutorial_table14(d,names(d),required="MI_mean")
  expect_identical(out$MI_mean,d$MI_mean)
  expect_identical(out$flat_field_status,d$flat_field_status)
  expect_length(attr(out,"missing_fields"),0L)
})
test_that("the exact illumination chunk knits with QC fields deliberately absent", {
  h <- load_tutorial_display();lines <- h$source
  a <- grep("^```\\{r illumination14",lines);b <- a+which(lines[(a+1):length(lines)]=="```")[1]
  text <- c("```{r, echo=FALSE}",h$code,
    'result14 <- list(plates=data.frame(plate_id=c("C","T")))',"```",lines[a:b])
  out <- knitr::knit(text=paste(text,collapse="\n"),quiet=TRUE,envir=new.env(parent=globalenv()))
  expect_match(out,"Not reported")
  expect_match(out,"central_detected")
  expect_match(out,"flat_field_status")
  expect_match(out,"no values were inferred")
})
