test_that("landscape panels draw and replay on compact graphics devices", {
  skip_if_not_installed("ragg")
  skip_if_not_installed("png")
  sim <- simulate_plate(width=300,height=400,seed=42)
  x <- suppressWarnings(analyze_plate(sim$image,n_boot=20,verbose=FALSE))
  original <- x$colonies
  for(type in c("3d","2d","both")) for(size in list(c(700,433),c(450,350))) {
    first <- tempfile(fileext=".png");second <- tempfile(fileext=".png")
    ragg::agg_png(first,width=size[1],height=size[2],res=96)
    grDevices::dev.control(displaylist="enable")
    tryCatch({
      expect_warning(plot_melanization_map(x,type=type),NA)
      recorded <- grDevices::recordPlot()
    },finally=grDevices::dev.off())
    ragg::agg_png(second,width=2*size[1],height=2*size[2],res=192)
    tryCatch(expect_warning(grDevices::replayPlot(recorded),NA),finally=grDevices::dev.off())
    expect_gt(file.info(second)$size,1000)
    if(type=="both") {
      pixels <- png::readPNG(second)
      strip <- pixels[seq.int(ceiling(dim(pixels)[1]*0.85),dim(pixels)[1]),,,drop=FALSE]
      opaque <- if(dim(strip)[3]==4L) strip[,,4]>.9 else matrix(TRUE,dim(strip)[1],dim(strip)[2])
      expect_gt(sum(opaque & strip[,,1]-strip[,,3]>.1),100)
    }
    unlink(c(first,second))
  }
  expect_identical(x$colonies,original)
})
