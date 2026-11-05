test_that("guided proposals detect irregular bright and dark targets without recolouring", {
  H <- 100L; W <- 100L
  xx <- matrix(rep(1:W,each=H),H,W); yy <- matrix(rep(1:H,W),H,W)
  tissue <- ((xx-50)/12)^2+((yy-50)/8)^2<=1
  for(delta in c(-25,25)) {
    L <- matrix(50,H,W); L[tissue] <- 50+delta; original <- L
    z <- FunMel:::.fm_seed_outline(L,c(50,50),30,"auto",3,.35)
    expect_equal(z$polarity,if(delta>0) "bright" else "dark")
    recovered <- FunMel:::.fm_polygon_mask(z$polygon,H,W)
    expect_equal(recovered,tissue)
    expect_identical(L,original)
  }
})

test_that("ambiguous, clipped and excluded targets do not get forced boundaries", {
  L <- matrix(50,100,100)
  expect_error(FunMel:::.fm_seed_outline(L,c(50,50),30,"auto",3,.35),"Insufficient")
  L[40:60,20:80] <- 80
  expect_error(FunMel:::.fm_seed_outline(L,c(50,50),30,"bright",3,.35),"search boundary")
  L <- matrix(50,100,100); L[40:60,40:60] <- 80
  ex <- matrix(FALSE,100,100);ex[45:46,45:46] <- TRUE
  expect_error(FunMel:::.fm_seed_outline(L,c(50,50),30,"bright",3,.35,ex),"excluded region")
  expect_error(FunMel:::.fm_seed_outline(L,c(50,50),30,"dark",3,.35),"Insufficient")
})

test_that("proposals retain failed diagnostics and manual alternatives", {
  x <- recovery_fixture('none');on.exit(unlink(x$path))
  seeds <- matrix(1,4,2,dimnames=list(c('TL','TR','BR','BL'),c('x','y')))
  q <- suggest_funmel_polygons(x$path,90,centre='none',dish=x$dish,max_dim=300,
    seeds=seeds,polygons=x$polygons)
  expect_s3_class(q,'funmel_boundary_proposal')
  expect_true(all(q$guidance$diagnostics$method=='manual_override'))
  expect_identical(q$polygons$TL,x$polygons$TL)
  expect_null(q$colonies)
  output <- tempfile();on.exit(unlink(output,recursive=TRUE),add=TRUE)
  r <- suppressWarnings(recover_funmel_plate(x$path,90,centre='none',dish=x$dish,
    max_dim=300,polygons=q$polygons,n_boot=0,n_spots=2,output_dir=output))
  expect_identical(r$annotation$guidance,q$guidance)
  expect_true(all(r$colonies$boundary_proposal_method=='manual_override'))
  replay <- suppressWarnings(analyze_plate(x$path,layout=plate_layout(centre='none'),
    max_dim=300,annotation=r$annotation,n_boot=0,verbose=FALSE))
  expect_equal(replay$colonies$MI_mean,r$colonies$MI_mean)
  expect_error(recover_funmel_plate(x$path,85,centre='none',dish=x$dish,
    max_dim=300,polygons=q$polygons,output_dir=tempfile()),'diameter differs')
  broken <- suggest_funmel_polygons(x$path,90,centre='none',dish=x$dish,max_dim=300,
    seeds=seeds,min_contrast=1000)
  expect_length(broken$polygons,0)
  expect_true(all(broken$guidance$diagnostics$status!='review_required'))
})

test_that("outer extent includes concentric interior without altering lightness", {
  H <- 100L; W <- 100L
  x <- matrix(rep(1:W,each=H),H,W); y <- matrix(rep(1:H,W),H,W)
  r <- sqrt((x-50)^2+(y-50)^2)
  L <- matrix(20,H,W); L[r<=7] <- 40; L[r>=10 & r<=13] <- 75
  original <- L
  outer <- FunMel:::.fm_seed_outline(L,c(50,50),30,"bright",3,.35)
  core <- FunMel:::.fm_seed_outline(L,c(50,50),30,"bright",3,.35,boundary="seed_component")
  om <- FunMel:::.fm_polygon_mask(outer$polygon,H,W)
  cm <- FunMel:::.fm_polygon_mask(core$polygon,H,W)
  expect_equal(om,r<=13)
  expect_equal(cm,r<=7)
  expect_true(all(om[r<10]))
  expect_identical(L,original)
  ex <- matrix(FALSE,H,W); ex[50,58] <- TRUE
  expect_error(FunMel:::.fm_seed_outline(L,c(50,50),30,"bright",3,.35,ex),"excluded")
})
