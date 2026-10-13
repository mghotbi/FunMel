test_that('the real example has one control and three treatments in each of five sets', {
  m<-read.csv(system.file('extdata','14_day_example','metadata.csv',package='FunMel'))
  d<-read.csv(system.file('extdata','14_day_example','colonies.csv',package='FunMel'))
  expect_equal(nrow(m),20L);expect_equal(length(unique(m$set_id)),5L)
  for(s in unique(m$set_id)) {
    z<-m[m$set_id==s,]
    expect_equal(sum(z$treatment=='control'),1L)
    expect_equal(sum(z$treatment!='control'),3L)
    expect_equal(z$replicate[z$treatment=='control'],1L)
    expect_setequal(z$replicate[z$treatment!='control'],1:3)
  }
  expect_equal(nrow(d),80L);expect_true(all(table(d$plate_id)==4L))
  expect_setequal(m$plate_id,d$plate_id)
  expect_true(all(!m$metadata_confirmed));expect_true(all(!d$metadata_confirmed))
  expect_error(melanization_coefficient(d),'Confirm')
  expect_s3_class(plot_treatment_comparison(d,preview=TRUE),'ggplot')
})
