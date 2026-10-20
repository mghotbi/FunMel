diagnostic_fixture <- function() {
  m <- data.frame(file=c("C.jpg","T.jpg"),plate_id=c("C","T"),set_id="batch",
    treatment=c("control","fungus_A"),centre_model=c("none","fungus"),qc_pass=FALSE,
    `User note`=c("keep control","keep treatment"),check.names=FALSE)
  d <- m[rep(1:2,each=4),];rownames(d)<-NULL
  d$colony_id <- rep(c("TL","TR","BR","BL"),2)
  d$MI_mean <- rep(c(40,60),each=4);d$detected<-TRUE;d$is_target<-TRUE
  d$n_spots_requested<-5;d$n_spots_measured<-5
  list(meta=m,result=list(colonies=d,plates=m,profiles=data.frame(),spots=data.frame(),
    failed=data.frame(file=character(),error=character()),analysis_status="complete",
    analysis_layout=m[c("plate_id","centre_model")]))
}

test_that("design diagnostics name affected rows and preserve experimental values", {
  f<-diagnostic_fixture();m<-f$meta;m$treatment<-NA_character_
  x<-FunMel:::metadata_design_issues(m)
  expect_equal(x$plate_id,c("C","T"));expect_true(all(x$field=="treatment"))
  expect_true(all(x$issue=="missing_treatment"));expect_true(all(is.na(m$treatment)))
  m$treatment<-c("Control ","fungus_A")
  x<-FunMel:::metadata_design_issues(m)
  expect_true(any(x$issue=="control_label_not_exact"))
  expect_identical(m$treatment[1],"Control ")
  m$treatment<-c("control","fungus_A");m$day<-c(14,NA)
  x<-FunMel:::metadata_design_issues(m)
  expect_true(any(x$field=="day" & x$plate_id=="T"))
})

test_that("missing MI and incomplete spots remain distinct from image failures", {
  f<-diagnostic_fixture();r<-f$result
  r$colonies$MI_mean[8]<-NA;r$colonies$detected[8]<-FALSE
  r$colonies$n_spots_measured[c(5,6,8)]<-c(1,1,0)
  z<-FunMel:::add_workflow_diagnostics(r,f$meta)
  expect_equal(z$run_summary$image_failures,0)
  expect_equal(z$run_summary$finite_detected_colony_MI,7)
  expect_equal(z$run_summary$missing_colony_MI,1)
  expect_equal(z$run_summary$colonies_with_incomplete_spots,2)
  expect_identical(z$measurement_qc_status,"needs_review")
  expect_equal(z$colonies,r$colonies)
  z<-suppressWarnings(finalize_analysis(r,f$meta))
  expect_identical(z$comparison_status,"awaiting_measurement_review")
  expect_identical(z$assessment$status,"awaiting_measurement_review")
  expect_match(z$coefficient_error,"T/BL")
  expect_equal(nrow(z$melanization_coefficient),0)
  expect_message(expect_null(plot_treatment_comparison(z)),"T/BL")
  expect_message(expect_null(plot_treatment_comparison(r)),"T/BL")
})

test_that("incomplete spots do not invalidate otherwise complete whole-colony MI", {
  f<-diagnostic_fixture();r<-f$result;r$colonies$n_spots_measured[5]<-1
  z<-suppressWarnings(finalize_analysis(r,f$meta))
  expect_identical(z$comparison_status,"complete")
  expect_identical(z$measurement_qc_status,"needs_review")
  expect_equal(z$melanization_coefficient$melanization_coefficient,1.5)
  expect_equal(z$metadata[["User note"]],f$meta[["User note"]])
  expect_s3_class(suppressWarnings(plot_treatment_comparison(z)),"ggplot")
})

test_that("fallback layout reporting never assigns biological roles", {
  f<-diagnostic_fixture();m<-f$meta;m$treatment<-NA_character_;m$centre_model<-NA_character_
  r<-f$result;r$analysis_layout$centre_model<-"fungus"
  z<-FunMel:::add_workflow_diagnostics(r,m)
  expect_true(all(z$layout_assignments$layout_source=="default_fallback"))
  expect_true(all(is.na(z$metadata$treatment)))
  m$treatment<-c("control","fungus_A");m$centre_model<-c("none","fungus")
  expect_error(finalize_analysis(r,m),"requires image reanalysis for plate\\(s\\): C")
})

test_that("diagnostic exports are explicit and comparison messages expose the cause", {
  f<-diagnostic_fixture();m<-f$meta;m$treatment<-NA_character_
  z<-suppressWarnings(finalize_analysis(f$result,m))
  expect_message(expect_null(plot_treatment_comparison(z)),"Missing/empty metadata in treatment")
  home<-withr::local_tempdir();FunMel:::write_experiment_tables(z,home)
  for(name in c("metadata_issues","measurement_issues","layout_assignments","run_summary"))
    expect_true(file.exists(file.path(home,paste0(name,".csv"))))
  x<-read.csv(file.path(home,"metadata_issues.csv"))
  expect_equal(x$plate_id,c("C","T"))
  expect_equal(read.csv(file.path(home,"run_summary.csv"))$comparison_status,"awaiting_design")
})
