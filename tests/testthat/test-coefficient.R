mc_data <- function() data.frame(plate_id=rep(c("C1","C2","T1","T2"),each=2),
  set_id="S1",treatment=rep(c("control","control","fungus","fungus"),each=2),
  colony_id=rep(c("TL","TR"),4),MI_mean=c(30,50,40,40,50,70,60,60),detected=TRUE)
test_that("coefficient equals ratio of equally weighted plate means", {
  d <- mc_data(); r <- melanization_coefficient(d)
  expect_equal(r$coefficients$melanization_coefficient,1.5)
  expect_equal(r$coefficients$n_control_plates,2)
  d <- d[-1,] # C1=50, C2=40; pooled colony mean is 43.33, plate mean is 45
  expect_equal(melanization_coefficient(d)$coefficients$melanization_coefficient,60/45)
})
test_that("central partner excluded and strata matched", {
  d <- mc_data(); extra <- d[1,,drop=FALSE]; extra$plate_id <- "T1";extra$treatment <- "fungus"
  extra$colony_id <- "centre";extra$MI_mean <- 0
  expect_equal(melanization_coefficient(rbind(d,extra))$coefficients$melanization_coefficient,1.5)
  d$day <- 1; d2 <- d;d2$day <- 2;d2$set_id <- "S2";d2$plate_id <- paste0(d2$plate_id,"b");d2$MI_mean <- d2$MI_mean/2
  expect_equal(melanization_coefficient(rbind(d,d2),by="day")$coefficients$melanization_coefficient,c(1.5,1.5))
})
test_that("undefined ratios and missing targets are explicit", {
  d<-mc_data();d$MI_mean[d$treatment=="control"]<-0
  expect_warning(r<-melanization_coefficient(d),"unavailable")
  expect_true(is.na(r$coefficients$melanization_coefficient))
  expect_equal(r$coefficients$status,"nonpositive_control_MI")
  expect_warning(r<-melanization_coefficient(subset(mc_data(),treatment=="fungus")),"unavailable")
  expect_equal(r$coefficients$status,"missing_control")
  d<-mc_data();d$detected[1]<-FALSE
  expect_error(melanization_coefficient(d),"Undetected")
  expect_warning(r<-melanization_coefficient(d,na_action="omit"),"excluded")
  expect_equal(r$coefficients$n_excluded_target_colonies,1)
  expect_equal(r$coefficients$MI_control_mean,45)
  d$MI_mean[3:4]<-NA
  expect_warning(r<-suppressWarnings(melanization_coefficient(d,na_action="omit")),NA)
  expect_equal(r$coefficients$status,"plate_without_usable_MI")
})
test_that("repeated rows and incompatible metadata are rejected", {
  d<-mc_data();expect_error(melanization_coefficient(rbind(d,d[1,])),"Duplicate")
  d$treatment[1]<-"wrong";expect_error(melanization_coefficient(d),"one value")
  d<-mc_data();d$day<-NA;expect_error(melanization_coefficient(d,by="day"),"Missing")
})
test_that("one plate per group gives a descriptive ratio", {
  d<-subset(mc_data(),plate_id %in% c("C1","T1"))
  expect_equal(melanization_coefficient(d)$coefficients$melanization_coefficient,1.5)
  expect_warning(r<-compare_melanization(d),"independent plates")
  expect_equal(r$status,"insufficient_plate_replication")
})
