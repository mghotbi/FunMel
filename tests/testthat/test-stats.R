test_that("mixed model uses matched set contrasts and plate random effects", {
  d<-example_experiment()$colonies
  a<-assess_experiment(d)
  expect_equal(a$status,"ok")
  expect_s4_class(a$model,"lmerModLmerTest")
  expect_equal(nrow(a$within_sets),6L)
  expect_equal(nrow(a$overall_effects),2L)
  expect_equal(nrow(a$treatment_comparisons),1L)
  expect_true(all(is.finite(a$overall_effects$p_adjusted)))
  expect_true(all(a$overall_effects$p_adjusted>=a$overall_effects$p_value))
  expect_equal(a$treatment_comparisons$n_common_sets,3L)
})
