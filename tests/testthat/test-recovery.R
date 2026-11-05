test_that("recovery geometry measures finite target and central diameters", {
  x <- recovery_fixture();on.exit(unlink(x$path))
  r <- suppressWarnings(analyze_plate(x$path,max_dim=300,annotation=x$annotation,n_boot=0,verbose=FALSE))
  expect_equal(nrow(r$colonies),4L)
  expect_true(all(is.finite(r$colonies$MI_mean)))
  expect_true(all(r$colonies$boundary_source=="manual_polygon"))
  expect_equal(r$colonies$eq_diameter_mm,2*sqrt(r$colonies$area_mm2/pi))
  expect_equal(r$plate_summary$central_diameter_mm,2*r$plate_summary$central_radius_mm)
  expect_gt(r$plate_summary$central_diameter_mm,0)
  expect_true(is.na(r$plate_summary$hyphae_area_mm2))
  expect_equal(r$plate_summary$hyphae_status,"whole_extent_only_core_not_separated")
  expect_identical(r$annotation,x$annotation)
})

test_that("annotations reject changed images, scale, layout and resolution", {
  x <- recovery_fixture();on.exit(unlink(x$path))
  expect_error(analyze_plate(x$path,max_dim=200,annotation=x$annotation,verbose=FALSE),"resolution differs")
  expect_error(analyze_plate(x$path,max_dim=300,dish_diameter_mm=85,annotation=x$annotation,verbose=FALSE),"diameter differs")
  expect_error(analyze_plate(x$path,max_dim=300,layout=plate_layout(centre='none'),annotation=x$annotation,verbose=FALSE),"centre model differs")
  a <- x$annotation;a$working_dim <- c(200L,300L)
  expect_error(analyze_plate(x$path,max_dim=300,annotation=a,verbose=FALSE),"dimensions/orientation differ")
  a <- x$annotation;a$image_md5 <- 'different' 
  expect_error(analyze_plate(x$path,max_dim=300,annotation=a,verbose=FALSE),"different or changed photograph")
})

test_that("reviewed tissue masks cannot overlap or extend outside analysed agar", {
  x <- recovery_fixture();on.exit(unlink(x$path))
  a <- x$annotation;a$polygons$TR <- a$polygons$TL
  expect_error(suppressWarnings(analyze_plate(x$path,max_dim=300,annotation=a,n_boot=0,verbose=FALSE)),"outlines overlap")
  a <- x$annotation;a$polygons$TL <- rbind(c(1,1),c(30,1),c(30,30),c(1,30))
  expect_error(suppressWarnings(analyze_plate(x$path,max_dim=300,annotation=a,n_boot=0,verbose=FALSE)),"outside the analysed agar")
})

test_that("batch corrections retain exact plate IDs and additional metadata", {
  x <- recovery_fixture();on.exit(unlink(x$path))
  meta <- data.frame(file=basename(x$path),plate_id='actual_plate_id',set_id='S1',
    treatment='fungus_A',centre_model='fungus',extra_note='retained value')
  r <- suppressWarnings(analyze_plates(x$path,metadata=meta,max_dim=300,n_boot=0,
    corrections=list(actual_plate_id=x$annotation),coefficient_control=NULL,verbose=FALSE))
  expect_equal(nrow(r$failed),0L)
  expect_true(all(r$colonies$plate_id=='actual_plate_id'))
  expect_true(all(r$colonies$extra_note=='retained value'))
  expect_identical(r$annotations$actual_plate_id,x$annotation)
  expect_error(analyze_plates(x$path,metadata=meta,corrections=list(wrong_id=x$annotation),verbose=FALSE),"exact plate IDs")
})

test_that("recovery tools save annotations without overwriting existing work", {
  x <- recovery_fixture('none');on.exit(unlink(x$path))
  output <- tempfile();on.exit(unlink(output,recursive=TRUE),add=TRUE)
  r <- suppressWarnings(recover_funmel_plate(x$path,90,centre='none',max_dim=300,
    dish=x$dish,polygons=x$polygons,n_spots=2,spot_radius_mm=.4,n_boot=0,output_dir=output))
  expect_true(file.exists(file.path(output,'annotation.rds')))
  expect_true(file.exists(file.path(output,'recovered_QC.png')))
  expect_true(all(r$colonies$detected))
  expect_true(is.na(r$plate_summary$central_diameter_mm))
  expect_equal(r$plate_summary$hyphae_status,'not_applicable')
  expect_error(recover_funmel_plate(x$path,90,centre='none',output_dir=output),"NEW output directory")
  expect_error(retry_funmel_dish(x$path,NA_real_),"finite positive")
})

test_that("rim-point geometry rejects collinear points", {
  expect_equal(FunMel:::.fm_circle3(rbind(c(15,20),c(10,25),c(5,20))),c(10,20,5))
  expect_error(FunMel:::.fm_circle3(rbind(c(1,1),c(2,2),c(3,3))),"collinear")
})
