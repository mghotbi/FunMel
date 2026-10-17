spot_fixture <- function() {
  p <- read_plate(array(0.5,c(120,120,3)),max_dim=120,id="known")
  p$dish <- list(x=60,y=60,r_outer=55,r_agar=50,mm_per_px=0.1)
  xy <- FunMel:::dish_masks(p)
  p$lab <- array(0,c(120,120,3));p$lab[,,1] <- 20+xy$x/3
  p$objects <- list(labels=matrix(as.integer((xy$x-60)^2+(xy$y-60)^2<35^2),120,120),
    colony_table=data.frame(id="target",detected=TRUE))
  p
}
test_that("requested circular spots are reproducible, nonoverlapping and quantitatively exact", {
  p <- spot_fixture();a <- sample_colony_spots(p,5,0.4)
  expect_equal(a,sample_colony_spots(p,5,0.4));expect_equal(nrow(a$spots),5L)
  expect_equal(a$summary$spot_status,"ok")
  expect_equal(a$summary$MI_spot_mean,mean(a$spots$MI_mean))
  expect_equal(a$summary$MI_spot_min,min(a$spots$MI_mean))
  expect_equal(a$summary$MI_spot_max,max(a$spots$MI_mean))
  dd <- as.matrix(dist(a$spots[c("x_px","y_px")]))
  expect_true(all(dd[upper.tri(dd)]>8))
  xy <- FunMel:::dish_masks(p)
  for(i in seq_len(nrow(a$spots))) {
    z <- a$spots[i,];mask <- (xy$x-z$x_px)^2+(xy$y-z$y_px)^2<=16
    expect_true(all(p$objects$labels[mask]==1))
    expect_equal(z$MI_mean,mean(100-p$lab[,,1][mask]))
    expect_equal(z$MI_min,min(100-p$lab[,,1][mask]))
    expect_equal(z$MI_max,max(100-p$lab[,,1][mask]))
  }
})
test_that("spots never fill shortages with overlapping or outside pixels", {
  p <- spot_fixture();z <- sample_colony_spots(p,50,1)
  expect_equal(z$summary$spot_status,"insufficient_space")
  expect_true(is.na(z$summary$MI_spot_mean));expect_lt(nrow(z$spots),50)
  expect_error(sample_colony_spots(p,0),"positive integer")
  expect_error(sample_colony_spots(p,1.5),"positive integer")
  expect_error(sample_colony_spots(p,2,0.01),"one working-image pixel")
  p$objects$colony_table$detected <- FALSE
  expect_equal(sample_colony_spots(p)$summary$spot_status,"not_detected")
})
test_that("highlights cannot enter a spot ROI", {
  p <- spot_fixture();p$rgb[55:65,55:65,] <- 1
  z <- sample_colony_spots(p,5,0.4)
  for(i in seq_len(nrow(z$spots))) {
    xy <- FunMel:::dish_masks(p);a <- z$spots[i,]
    mask <- (xy$x-a$x_px)^2+(xy$y-a$y_px)^2<=16
    expect_true(all(p$rgb[,,1][mask]<1))
  }
})

test_that("an empty spot table for one colony does not discard other colonies", {
  p <- spot_fixture()
  p$objects$colony_table <- data.frame(id=c("target","empty"),detected=c(TRUE,TRUE))
  z <- sample_colony_spots(p,5,0.4)
  expect_equal(nrow(z$spots),5L)
  expect_identical(z$summary$spot_status,c("ok","insufficient_space"))
  expect_equal(z$summary$n_spots_measured,c(5L,0L))
  expect_true(is.na(z$summary$MI_spot_mean[2]))
  expect_equal(unique(z$spots$colony_id),"target")
})
