testthat::test_that('whole reviewed colony interior contributes to MI, not only its ring', {
  f <- recovery_fixture('none');on.exit(unlink(f$path))
  p <- read_plate(f$path,max_dim=300)
  p <- detect_plate(p,dish=f$dish,dish_diameter_mm=90)
  p <- FunMel:::.fm_apply_polygons(p,plate_layout(centre='none'),f$polygons)
  masks <- p$objects$labels
  for(i in 1:4) {
    wh <- which(masks==i,arr.ind=TRUE)
    cx <- mean(wh[,2]);cy<-mean(wh[,1])
    rr <- (wh[,2]-cx)^2+(wh[,1]-cy)^2
    L <- p$lab[,,1];L[masks==i] <- ifelse(rr<25,70,30);p$lab[,,1]<-L
  }
  p$rgb[] <- .5
  d <- measure_colonies(p,edge_exclude_mm=0,n_boot=0)
  for(i in 1:4) {
    testthat::expect_equal(d$MI_mean[i],100-mean(p$lab[,,1][masks==i]))
    testthat::expect_lt(d$MI_mean[i],70)
    testthat::expect_equal(d$n_pixels[i],sum(masks==i))
  }
})
