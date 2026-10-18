test_that('the real example has one control and three treatments in each of two sets', {
  m<-read.csv(system.file('extdata','14_day_example','metadata.csv',package='FunMel'))
  d<-read.csv(system.file('extdata','14_day_example','colonies.csv',package='FunMel'))
  expect_equal(nrow(m),8L);expect_equal(length(unique(m$set_id)),2L)
  for(s in unique(m$set_id)) {
    z<-m[m$set_id==s,]
    expect_equal(sum(z$treatment=='control'),1L)
    expect_equal(sum(z$treatment!='control'),3L)
    expect_equal(z$replicate[z$treatment=='control'],1L)
    expect_setequal(z$replicate[z$treatment!='control'],1:3)
  }
  expect_equal(nrow(d),32L);expect_true(all(table(d$plate_id)==4L))
  expect_setequal(m$plate_id,d$plate_id)
  expect_false("metadata_confirmed" %in% names(m));expect_false("metadata_confirmed" %in% names(d))
  expect_warning(mc <- melanization_coefficient(d),'Image QC')
  expect_equal(nrow(mc$coefficients),2L)
  expect_warning(p <- plot_treatment_comparison(d,preview=TRUE),'Image QC')
  expect_s3_class(p,'ggplot')
  expect_match(attr(p,'FunMel_caption'),'QC UNCONFIRMED')
})
