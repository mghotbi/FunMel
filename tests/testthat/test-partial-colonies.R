partial_fixture <- function() {
  m <- data.frame(file=c('C.jpg','T.jpg'),relative_file=c('C.jpg','T.jpg'),
    plate_id=c('C','T'),set_id='S1',treatment=c('control','fungus_A'),
    centre_model=c('none','fungus'),qc_pass=TRUE,custom=c('retain C','retain T'))
  d <- m[rep(1:2,each=4),];rownames(d)<-NULL
  d$colony_id<-rep(c('TL','TR','BR','BL'),2)
  d$MI_mean<-rep(c(40,60),each=4);d$MI_mean[8]<-NA_real_
  d$detected<-TRUE;d$detected[8]<-FALSE
  list(meta=m,result=list(colonies=d,plates=m,profiles=data.frame(),spots=data.frame(),
    failed=data.frame(file=character(),error=character()),analysis_status='complete',
    analysis_layout=m[c('plate_id','centre_model')]))
}

test_that('default partial targets warn, retain original rows and use actual counts', {
  f<-partial_fixture()
  expect_warning(mc<-melanization_coefficient(f$result),'T/BL.*3/4 usable targets')
  expect_equal(mc$coefficients$melanization_coefficient,1.5)
  expect_equal(mc$coefficients$n_treatment_colonies,3)
  expect_equal(mc$coefficients$n_control_colonies,4)
  expect_equal(mc$coefficients$n_excluded_target_colonies,1)
  expect_equal(mc$excluded_colonies$colony_id,'BL')
  z<-suppressWarnings(finalize_analysis(f$result,f$meta))
  expect_identical(z$comparison_status,'complete')
  expect_equal(nrow(z$colonies),8)
  expect_true(is.na(z$colonies$MI_mean[8]))
  expect_equal(z$excluded_colonies$plate_id,'T')
  expect_equal(z$excluded_colonies$colony_id,'BL')
  expect_equal(z$metadata$custom,f$meta$custom)
  plot<-suppressWarnings(plot_treatment_comparison(z))
  expect_s3_class(plot,'ggplot')
  expect_equal(attr(plot,'FunMel_statistics')$n_treatment_colonies,3)
  home<-withr::local_tempdir();FunMel:::write_experiment_tables(z,home)
  expect_equal(read.csv(file.path(home,'excluded_colonies.csv'))$colony_id,'BL')
  expect_equal(nrow(read.csv(file.path(home,'colonies.csv'))),8)
})

test_that('strict mode and zero usable target plates remain unavailable', {
  f<-partial_fixture()
  strict<-suppressWarnings(finalize_analysis(f$result,f$meta,na_action='error'))
  expect_equal(strict$comparison_status,'awaiting_measurement_review')
  expect_equal(nrow(strict$excluded_colonies),0)
  expect_error(melanization_coefficient(f$result,na_action='error'),'Undetected')
  f$result$colonies$MI_mean[5:8]<-NA_real_
  none<-suppressWarnings(finalize_analysis(f$result,f$meta))
  expect_equal(none$comparison_status,'awaiting_measurement_review')
  expect_match(none$coefficient_error,'No usable target MI.*T')
  expect_equal(nrow(none$melanization_coefficient),0)
  expect_message(expect_null(plot_treatment_comparison(none)),'No usable target MI')
})

test_that('partial controls retain own-set matching and are never replaced by zero', {
  f<-partial_fixture();a<-f$result$colonies
  a$MI_mean[1]<-NA_real_;a$detected[1]<-FALSE
  b<-a;b$set_id<-'S2';b$plate_id<-paste0('S2_',b$plate_id)
  b$MI_mean[b$treatment=='control' & b$detected]<-20
  mc<-suppressWarnings(melanization_coefficient(rbind(a,b)))
  expect_equal(mc$coefficients$melanization_coefficient,c(1.5,3))
  expect_equal(mc$coefficients$n_control_colonies,c(3,3))
  expect_equal(mc$coefficients$n_excluded_target_colonies,c(2,2))
  expect_true(all(mc$coefficients$MI_control_mean>0))
})

test_that('public finalization saves partial-colony coefficients, diagnostics and figure', {
  f<-partial_fixture();home<-withr::local_tempdir()
  p<-list(project_dir=home,image_root=file.path(home,'photos'),
    metadata_file=file.path(home,'plate_metadata.csv'),qc_dir=file.path(home,'qc'),
    result_file=file.path(home,'image_analysis.rds'),reviewed_file=file.path(home,'reviewed_analysis.rds'))
  class(p)<-'funmel_project'
  dir.create(p$image_root);dir.create(p$qc_dir)
  write.csv(f$meta,p$metadata_file,row.names=FALSE)
  saveRDS(p,file.path(home,'project.rds'));saveRDS(f$result,p$result_file)
  z<-suppressWarnings(finish_experiment(p))
  expect_equal(z$comparison_status,'complete')
  expect_equal(z$melanization_coefficient$melanization_coefficient,1.5)
  expect_equal(z$coefficient_plate_means$n_colonies_used,c(4,3))
  for(name in c('excluded_colonies.csv','measurement_issues.csv','treatment_comparison.pdf',
               'treatment_comparison.svg','treatment_comparison.png','reviewed_analysis.rds'))
    expect_true(file.exists(file.path(home,name)))
  expect_equal(read.csv(file.path(home,'excluded_colonies.csv'))$colony_id,'BL')
})
