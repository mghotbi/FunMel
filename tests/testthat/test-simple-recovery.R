test_that('guided recovery uses centre seeds without any freehand locator', {
  f<-recovery_fixture('none');on.exit(unlink(f$path))
  seeds<-t(vapply(f$polygons,function(x)c(mean(x[,1]),mean(x[,2])),numeric(2)))
  out<-withr::local_tempdir();out<-file.path(out,'guided')
  r<-suppressWarnings(recover_funmel_plate(f$path,90,centre='none',dish=f$dish,
    seeds=seeds,max_dim=300,output_dir=out,n_boot=0,n_spots=2))
  expect_s3_class(r,'funmel_result')
  expect_equal(r$recovery_status,'measured_requires_review')
  expect_true(all(r$colonies$detected))
  expect_true(all(is.finite(r$colonies$MI_mean)))
  expect_true(all(r$colonies$boundary_source=='guided_polygon'))
  expect_equal(r$annotation$guidance$central_auto,TRUE)
  saved<-readRDS(file.path(out,'recovered_analysis.rds'))
  expect_equal(saved$recovery_status,r$recovery_status)
  expect_equal(saved$recovery_dir,r$recovery_dir)
  replay<-suppressWarnings(analyze_plate(f$path,layout=plate_layout(centre='none'),
    max_dim=300,annotation=r$annotation,n_boot=0,verbose=FALSE))
  expect_equal(replay$colonies$MI_mean,r$colonies$MI_mean)
})

test_that('unresolved guided outlines save proposals without invented measurements', {
  file<-tempfile(fileext='.png');on.exit(unlink(file))
  png::writePNG(array(.5,c(300,300,3)),file)
  seeds<-rbind(TL=c(100,100),TR=c(200,100),BR=c(200,200),BL=c(100,200))
  out<-file.path(withr::local_tempdir(),'pending')
  expect_message(r<-recover_funmel_plate(file,90,centre='fungus',dish=c(150,150,130),
    seeds=seeds,max_dim=300,output_dir=out),'No measurements were calculated')
  expect_s3_class(r,'funmel_boundary_proposal')
  expect_equal(r$recovery_status,'awaiting_boundaries')
  expect_null(r$colonies)
  expect_false(file.exists(file.path(out,'colonies.csv')))
  expect_true(file.exists(file.path(out,'boundary_diagnostics.csv')))
  expect_true(file.exists(file.path(out,'proposed_QC.png')))
})

test_that('guided central proposal uses visible contrast and retains extent provenance', {
  H<-300;W<-300;x<-matrix(rep(1:W,each=H),H,W);y<-matrix(rep(1:H,W),H,W)
  central<-((x-150)/45)^2+((y-150)/35)^2<=1
  rgb<-array(.12,c(H,W,3));seeds<-rbind(TL=c(80,80),TR=c(220,80),BR=c(220,220),BL=c(80,220))
  target<-matrix(FALSE,H,W)
  for(i in 1:4)target<-target | ((x-seeds[i,1])^2+(y-seeds[i,2])^2<=15^2)
  for(k in 1:3) {a<-rgb[,,k];a[central]<-.7;a[target]<-.5;rgb[,,k]<-a}
  file<-tempfile(fileext='.png');on.exit(unlink(file));png::writePNG(rgb,file)
  q<-suggest_funmel_polygons(file,90,centre='fungus',dish=c(150,150,140),seeds=seeds,max_dim=300)
  expect_true('central_fungus' %in% names(q$polygons))
  expect_equal(FunMel:::.fm_polygon_mask(q$polygons$central_fungus,H,W),central)
  out<-file.path(withr::local_tempdir(),'central')
  r<-suppressWarnings(recover_funmel_plate(file,90,centre='fungus',dish=q$dish,
    polygons=q$polygons,max_dim=300,n_spots=2,n_boot=0,output_dir=out))
  expect_equal(r$plate_summary$central_boundary_source,'guided_whole_extent')
  expect_equal(r$plate_summary$hyphae_status,'whole_extent_only_core_not_separated')
  expect_true(is.na(r$plate_summary$hyphae_area_mm2))
  expect_true(all(r$colonies$boundary_source=='guided_polygon'))
  expect_true(all(is.finite(r$colonies$MI_mean)))
})

test_that('closing the graphics window cancels guided recovery informatively', {
  testthat::local_mocked_bindings(suggest_funmel_polygons=function(...)
    stop('graphics device closed during call to locator or identify'),.package='FunMel')
  expect_message(r<-recover_funmel_plate('unused.png',90,centre='fungus'),
    'Recovery cancelled.*No new measurements were saved')
  expect_s3_class(r,'funmel_recovery_cancelled')
  expect_equal(r$recovery_status,'cancelled')
  expect_null(r$recovery_dir)
  expect_null(r$annotation)
})
