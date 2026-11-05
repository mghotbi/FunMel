recovery_fixture <- function(centre="fungus") {
  sim <- simulate_plate(width=300,height=300,seed=71,layout=plate_layout(centre=centre))
  path <- tempfile(fileext=".png"); png::writePNG(sim$image,path)
  # Explicit vertex outlines exercise geometry, not automated classification.
  d <- sim$truth$dish
  if(is.list(d)) d <- unlist(d[c("x","y","r")])
  # Simulator records the actual dish as x, y, r_outer in some versions.
  p <- read_plate(path,max_dim=300)
  p <- detect_plate(p,dish_diameter_mm=90)
  dc <- c(p$dish$x,p$dish$y,p$dish$r_outer)
  xy <- FunMel:::layout_pixels(plate_layout(centre=centre),p$dish)
  th <- seq(0,2*pi,length.out=33)[-33]
  polygons <- lapply(seq_len(nrow(xy)),function(i)
    cbind(x=xy$x[i]+10*cos(th),y=xy$y[i]+10*sin(th)))
  names(polygons) <- as.character(xy$id)
  if(centre=="fungus") polygons$central_fungus <- cbind(x=dc[1]+12*cos(th),y=dc[2]+12*sin(th))
  a <- list(image_md5=unname(as.character(tools::md5sum(path))),source_file=basename(path),
    max_dim=300,working_dim=c(300L,300L),dish_diameter_mm=90,centre=centre,
    dish=unname(dc),polygons=polygons)
  list(path=path,annotation=a,polygons=polygons,dish=dc)
}
