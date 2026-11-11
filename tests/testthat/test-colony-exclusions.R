exclusion_project <- function() {
  home <- tempfile();dir.create(home)
  p <- structure(list(project_dir=home, metadata_file=file.path(home,"plate_metadata.csv"),
    result_file=file.path(home,"image_analysis.rds"), reviewed_file=file.path(home,"reviewed_analysis.rds")),
    class="funmel_project")
  meta <- data.frame(file=c("C.jpg","T.jpg"),plate_id=c("C","T"),set_id="set1",
    treatment=c("control","fungus_A"),centre_model=c("none","fungus"),qc_pass=FALSE)
  co <- meta[rep(1:2,each=4),];rownames(co)<-NULL
  co$colony_id<-rep(c("TL","TR","BR","BL"),2)
  co$MI_mean<-c(40,40,40,40,60,90,60,60)
  co$MI_spot_mean<-co$MI_mean
  co$detected<-co$is_target<-TRUE
  r <- list(colonies=co,plates=meta,profiles=data.frame(),spots=co,
    analysis_layout=meta[c("plate_id","centre_model")],failed=data.frame())
  saveRDS(r,p$result_file);utils::write.csv(meta,p$metadata_file,row.names=FALSE)
  list(project=p,raw=r,meta=meta)
}

test_that("saved decisions exclude finite MI without changing raw measurements", {
  f<-exclusion_project();p<-f$project
  hash<-tools::md5sum(p$result_file)
  expect_message(exclude_colonies(p,"T","TR","Mask includes agar"),"Saved colony review")
  z<-suppressWarnings(finish_experiment(p))
  expect_equal(z$melanization_coefficient$melanization_coefficient,1.5)
  expect_equal(z$coefficient_plate_means$n_colonies_used,c(4L,3L))
  expect_equal(z$colonies$MI_mean,f$raw$colonies$MI_mean)
  expect_equal(z$colonies$detected,f$raw$colonies$detected)
  expect_equal(tools::md5sum(p$result_file),hash)
  expect_equal(read_experiment(p),f$raw)
  expect_true(all(!z$metadata$qc_pass))
  expect_equal(z$excluded_colonies$issue,"manual_colony_exclusion")
  expect_match(z$excluded_colonies$action,"Mask includes agar")
  expect_equal(sum(z$spots$.funmel_excluded),1)
  expect_equal(suppressWarnings(melanization_coefficient(z,response="MI_spot_mean"))$coefficients$melanization_coefficient,1.5)
  expect_s3_class(suppressWarnings(plot_treatment_comparison(p)),"ggplot")
  expect_true(file.exists(file.path(p$project_dir,"treatment_comparison.pdf")))
  expect_true(file.exists(file.path(p$project_dir,"colony_exclusions.csv")))
  expect_equal(suppressWarnings(finish_experiment(p))$melanization_coefficient$melanization_coefficient,1.5)
  expect_error(finish_experiment(p,require_qc=TRUE),"qc_pass")
})

test_that("decisions can be reinstated and invalid IDs do not alter the file", {
  f<-exclusion_project();p<-f$project
  exclude_colonies(p,"T","TR","Mask includes agar")
  path<-file.path(p$project_dir,"colony_exclusions.csv");before<-tools::md5sum(path)
  expect_error(exclude_colonies(p,"not_a_plate","TR","bad"),"match target")
  expect_error(exclude_colonies(p,"T","TR",""),"nonempty")
  expect_error(exclude_colonies(p,"T",c("TR","TR"),"duplicate"),"unique")
  expect_equal(tools::md5sum(path),before)
  exclude_colonies(p,"T","TR","Boundary rechecked",exclude=FALSE)
  z<-suppressWarnings(finish_experiment(p))
  expect_equal(z$melanization_coefficient$melanization_coefficient,1.6875)
  expect_equal(nrow(z$excluded_colonies),0)
  expect_equal(nrow(z$colony_exclusions),1)
  expect_false(z$colony_exclusions$exclude)
})

test_that("new runs require a fresh review and whole-plate loss is not silent", {
  f<-exclusion_project();p<-f$project
  exclude_colonies(p,"T","TR","Bad mask")
  r<-f$raw;r$new_run<-TRUE;saveRDS(r,p$result_file)
  expect_error(finish_experiment(p),"earlier image-analysis")
  exclude_colonies(p,"T","TR","Reviewed new run")
  expect_equal(suppressWarnings(finish_experiment(p))$melanization_coefficient$melanization_coefficient,1.5)
  exclude_colonies(p,"T",c("TL","TR","BR","BL"),"All masks invalid")
  z<-suppressWarnings(finish_experiment(p))
  expect_identical(z$comparison_status,"awaiting_measurement_review")
  expect_equal(nrow(z$melanization_coefficient),0)
  expect_equal(nrow(z$excluded_colonies),4)
})

test_that("exclusions stay with their own context", {
  f<-exclusion_project();p<-f$project
  r<-f$raw;m<-f$meta
  r2<-r
  for(nm in c("colonies","plates","spots","analysis_layout"))
    r2[[nm]]$plate_id<-paste0(r2[[nm]]$plate_id,"2")
  r2$plates$file<-paste0("2",r2$plates$file)
  r2$colonies$file<-paste0("2",r2$colonies$file)
  r2$spots$file<-paste0("2",r2$spots$file)
  for(nm in c("colonies","plates","spots")) {r[[nm]]$day<-14;r2[[nm]]$day<-8}
  r2$plates$set_id<-r2$colonies$set_id<-r2$spots$set_id<-"set2"
  for(nm in c("colonies","plates","spots","analysis_layout")) r[[nm]]<-rbind(r[[nm]],r2[[nm]])
  m<-r$plates;saveRDS(r,p$result_file);utils::write.csv(m,p$metadata_file,row.names=FALSE)
  exclude_colonies(p,"T","TR","Bad mask")
  z<-suppressWarnings(finish_experiment(p))
  expect_equal(sort(z$melanization_coefficient$melanization_coefficient),c(1.5,1.6875))
  expect_equal(sum(z$colonies$.funmel_excluded),1)
  expect_equal(vapply(z$context_results,function(x) nrow(x$colony_exclusions),integer(1)),c(context_001=1L,context_002=0L))
})

test_that("reviewing a missing colony does not inflate available MI counts", {
  f<-exclusion_project();p<-f$project;r<-f$raw
  r$colonies$MI_mean[6]<-NA_real_;r$colonies$detected[6]<-FALSE
  saveRDS(r,p$result_file)
  exclude_colonies(p,"T","TR","No reliable tissue detected")
  z<-suppressWarnings(finish_experiment(p))
  expect_equal(z$run_summary$finite_detected_colony_MI,7)
  expect_equal(z$run_summary$missing_colony_MI,1)
  expect_equal(z$run_summary$manually_excluded_colonies,1)
  expect_equal(z$run_summary$usable_colony_MI,7)
  expect_equal(z$melanization_coefficient$melanization_coefficient,1.5)
})

test_that("custom metadata cannot overwrite review exclusion flags", {
  f<-exclusion_project();p<-f$project;m<-f$meta
  m$.funmel_excluded<-FALSE;m$.funmel_exclusion_reason<-"custom user note"
  r<-FunMel:::attach_result_metadata(f$raw,m,initial=TRUE)
  expect_true("metadata_.funmel_excluded" %in% names(r$colonies))
  saveRDS(r,p$result_file);utils::write.csv(m,p$metadata_file,row.names=FALSE)
  exclude_colonies(p,"T","TR","Mask includes agar")
  z<-suppressWarnings(finish_experiment(p))
  expect_equal(z$melanization_coefficient$melanization_coefficient,1.5)
  expect_equal(sum(z$colonies$.funmel_excluded),1)
  expect_true(all(!z$colonies$metadata_.funmel_excluded))
  expect_true(all(z$colonies$metadata_.funmel_exclusion_reason=="custom user note"))
  expect_identical(z$metadata$.funmel_excluded,m$.funmel_excluded)
  expect_identical(z$metadata$.funmel_exclusion_reason,m$.funmel_exclusion_reason)
})
