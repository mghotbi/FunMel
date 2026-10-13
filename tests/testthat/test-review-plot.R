review_fixture <- function() {
  d<-example_experiment(seed=42)$colonies
  d$file<-paste0(d$plate_id,'.JPG');d$metadata_confirmed<-FALSE
  list(colonies=d,plates=unique(d[c('plate_id','file','set_id','treatment','metadata_confirmed')]),
       profiles=data.frame(),failed=data.frame())
}
test_that('preview cannot silently confirm metadata or bypass failed QC', {
  x<-review_fixture()
  expect_error(plot_treatment_comparison(x),'Confirm')
  p<-plot_treatment_comparison(x,preview=TRUE)
  expect_s3_class(p,'ggplot');expect_match(p$labels$caption,'PROVISIONAL')
  expect_true(all(!x$colonies$metadata_confirmed))
  x$colonies$qc_pass<-FALSE
  expect_error(plot_treatment_comparison(x,preview=TRUE),'qc_pass')
})
test_that('review reuses measurements and applies exactly matched metadata', {
  x<-review_fixture();m<-x$plates
  expect_error(finalize_analysis(x,m),'metadata_confirmed')
  m$metadata_confirmed<-TRUE
  expect_error(finalize_analysis(x,m),'qc_pass')
  m$qc_pass<-TRUE
  y<-finalize_analysis(x,m)
  expect_equal(y$colonies$MI_mean,x$colonies$MI_mean)
  expect_null(y$coefficient_error);expect_equal(y$assessment$status,'ok')
  expect_true(all(y$colonies$metadata_confirmed & y$colonies$qc_pass))
  expect_error(finalize_analysis(x,m[-1,]),'match')
})
test_that('plotted means are exact matched ratios and exports work', {
  x<-example_experiment(seed=42);p<-plot_treatment_comparison(x)
  mc<-melanization_coefficient(x)
  a<-p$layers[[3]]$data
  expect_equal(sort(a$x[a$panel=='B  Matched melanization coefficient']),sort(mc$coefficients$melanization_coefficient))
  d<-withr::local_tempdir();prefix<-file.path(d,'comparison')
  plot_treatment_comparison(x,file=prefix)
  expect_true(all(file.exists(paste0(prefix,c('.pdf','.svg','.png')))))
})


test_that('figure statistics use independent plates and own set controls', {
  d<-data.frame(plate_id=rep(c("C","T1","T2","T3"),each=4),
                set_id="S",treatment=rep(c("control",rep("fungus",3)),each=4),
                colony_id=rep(c("TL","TR","BR","BL"),4),
                MI_mean=rep(c(40,48,52,56),each=4))
  p<-plot_treatment_comparison(d)
  s<-attr(p,"FunMel_statistics")
  expect_equal(s$MI_control_mean,40)
  expect_true(is.na(s$MI_control_sd))
  expect_equal(s$MI_treatment_mean,52)
  expect_equal(s$MI_treatment_sd,4)
  expect_equal(s$melanization_coefficient,1.3)
  expect_equal(s$coefficient_sd,0.1)
  expect_equal(s$delta_MI,12)
  expect_equal(s$n_control_plates,1L)
  expect_equal(s$n_treatment_plates,3L)
  expect_match(p$labels$caption,'not a confidence interval',fixed=TRUE)
  shapes<-ggplot2::ggplot_build(p)$plot$scales$get_scales('shape')$map(c('Control plates','Treatment plates'))
  expect_equal(unname(shapes),c(0,21))
  expect_error(plot_treatment_comparison(d,palette=c(other='red')),'every treatment')
  prefix<-file.path(withr::local_tempdir(),'stats')
  plot_treatment_comparison(d,file=prefix)
  saved<-read.csv(paste0(prefix,'_statistics.csv'))
  expect_equal(saved$MI_treatment_sd,4)
  expect_true(is.na(saved$MI_control_sd))
})

test_that('replicated controls receive their own between-plate SD', {
  d<-example_experiment(seed=42)$colonies
  p<-plot_treatment_comparison(d)
  s<-attr(p,'FunMel_statistics')
  pm<-melanization_coefficient(d)$plate_means
  for(i in seq_len(nrow(s))) {
    z<-pm[pm$set_id==s$set_id[i],]
    expect_equal(s$MI_control_sd[i],sd(z$MI_plate[z$treatment=='control']))
    expect_equal(s$coefficient_sd[i],sd(z$MI_plate[z$treatment==s$treatment[i]])/s$MI_control_mean[i])
  }
})
