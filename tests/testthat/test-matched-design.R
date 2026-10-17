test_that("control matching cannot silently pool independent sets", {
  d<-data.frame(plate_id=c('c1','t1','c2','t2'),set_id=c('S1','S1','S2','S2'),
                treatment=c('control','A','control','A'),colony_id='TL',MI_mean=c(20,40,80,80))
  z<-melanization_coefficient(d)$coefficients
  expect_equal(z$melanization_coefficient,c(2,1))
  expect_warning(a<-assess_experiment(d),'independent plates')
  expect_equal(a$overall_coefficients$mean_matched_coefficient,1.5)
  expect_false(a$overall_coefficients$mean_matched_coefficient==1.2)
  expect_warning(z<-melanization_coefficient(d[-3,]),'unavailable')
  expect_equal(z$coefficients$status,c('ok','missing_control'))
  expect_true(is.na(z$coefficients$melanization_coefficient[2]))
  expect_error(melanization_coefficient(d[,names(d)!='set_id']),'set_id')
})
test_that("metadata demands explicit, consistent plate to set mappings", {
  m<-example_experiment()$metadata
  expect_silent(validate_metadata(m))
  bad<-m;bad$plate_id[2]<-bad$plate_id[1]
  expect_error(validate_metadata(bad),'globally unique')
  bad<-m[m$treatment!='control' | m$set_id!='S2',]
  expect_error(validate_metadata(bad),'no matching control')
  bad<-m;bad$day[1]<-9
  expect_error(validate_metadata(bad),'constant')
  expect_error(validate_metadata(m,files='unmatched.jpg'),'one-to-one')
})
test_that("QC decisions and biological contexts are not silently ignored", {
  d<-example_experiment()$colonies
  d$qc_pass<-TRUE;d$qc_pass[1]<-FALSE
  expect_warning(pending <- melanization_coefficient(d),'Image QC')
  expect_identical(pending$qc_review$status,'unconfirmed')
  expect_error(melanization_coefficient(d,require_qc=TRUE),'qc_pass')
  d$qc_pass<-NULL;d$day[d$set_id=='S2']<-8
  expect_error(assess_experiment(d),'Multiple day')
  expect_equal(assess_experiment(d,pool_contexts=TRUE)$status,'ok')
})
test_that("the central partner is excluded using target metadata", {
  d<-example_experiment()$colonies
  partner<-d[1,];partner$colony_id<-'arbitrary_partner';partner$is_target<-FALSE;partner$MI_mean<-1
  expect_equal(melanization_coefficient(rbind(d,partner))$coefficients,
               melanization_coefficient(d)$coefficients)
})
test_that("pairwise contrasts use common sets and share control covariance", {
  d<-example_experiment()$colonies
  z<-assess_experiment(d)
  p<-z$treatment_comparisons[1,]
  a<-subset(z$within_sets,treatment==p$treatment_1)
  b<-subset(z$within_sets,treatment==p$treatment_2)
  expect_equal(p$estimate,mean(a$estimate)-mean(b$estimate),tolerance=1e-8)
  # Disjoint treatments must not be compared across unrelated sets.
  d<-d[d$treatment=='control' | (d$treatment=='fungus_A' & d$set_id!='S3') |
         (d$treatment=='fungus_B' & d$set_id=='S3'),]
  z<-assess_experiment(d,method='plate_means',comparison_scope='common_sets')
  expect_equal(z$treatment_comparisons$status,'no_common_sets')
  expect_true(is.na(z$treatment_comparisons$p_value))
  z<-assess_experiment(d,method='plate_means',comparison_scope='matched_effects')
  expect_equal(z$treatment_comparisons$status,'different_set_coverage')
  expect_true(is.finite(z$treatment_comparisons$p_value))
})
test_that("singular mixed fits withhold inferential tables", {
  d<-example_experiment()$colonies
  d$MI_mean<-40+8*(d$treatment=='fungus_A')+15*(d$treatment=='fungus_B')+
    rep(c(-1,-.3,.3,1),nrow(d)/4)
  expect_warning(z<-suppressMessages(assess_experiment(d)),'diagnostics')
  expect_equal(z$status,'singular_fit')
  expect_equal(nrow(z$within_sets),0L)
  expect_true(nrow(z$coefficients)>0L)
})
