test_that('layout input validation rejects ambiguous and impossible designs', {
  expect_error(plate_layout(n_colonies=0),'positive integer')
  expect_error(plate_layout(ids=c('A','B')),'one value')
  expect_error(plate_layout(radius_frac=1.5),'between')
  expect_error(plate_layout(rotation_deg=NA_real_),'Angles')
  expect_error(plate_layout(positions=data.frame(id=c('A','A'),x_rel=c(.1,.2),y_rel=c(.1,.2))),'unique')
  expect_error(plate_layout(positions=data.frame(id='A',x_rel=2,y_rel=0)),'within')
  expect_error(plate_layout(positions=data.frame(id=c('A','B'),x_rel=c(.1,.1),y_rel=c(.1,.1))),'distinct')
})
test_that('metadata layout overrides adapt new image arrangements', {
  row<-data.frame(treatment='new_species',centre_model='fungus',rotation_deg=25,radius_frac=.52)
  a<-layout_by_treatment(row);b<-plate_layout(centre='fungus',rotation_deg=25,radius_frac=.52)
  expect_equal(a,b)
  expect_equal(layout_by_treatment(row,rotation_deg=0),plate_layout(centre='fungus',radius_frac=.52))
})
test_that('new synthetic layouts and illumination settings need no known filenames', {
  specs<-list(
    list(width=540,height=420,seed=137,layout=plate_layout(centre='none',rotation_deg=22,radius_frac=.52),vignetting=.1),
    list(width=420,height=540,seed=138,layout=plate_layout(centre='fungus',rotation_deg=-18,radius_frac=.49),vignetting=.35),
    list(width=600,height=450,seed=139,layout=plate_layout(n_colonies=3,ids=c('A','B','C'),centre='bacteria',rotation_deg=25,radius_frac=.5),vignetting=.2))
  for(i in seq_along(specs)) {
    sim<-do.call(simulate_plate,specs[[i]])
    r<-suppressWarnings(analyze_plate(sim$image,layout=specs[[i]]$layout,id=paste0('unseen_',i),n_boot=0,verbose=FALSE))
    z<-merge(sim$truth$colonies,r$colonies,by='colony_id',suffixes=c('_true',''))
    expect_equal(nrow(z),nrow(specs[[i]]$layout$positions))
    expect_true(all(z$detected))
    expect_true(all(is.finite(z$MI_mean)))
    expect_lt(max(abs(z$MI_mean-z$MI_mean_true)),2)
    expect_lt(abs(r$plate_summary$mm_per_px/sim$truth$mm_per_px-1),.01)
    expect_equal(z$radial_asymmetry_pct,z$growth_inhibition_pct)
  }
})
test_that('nested metadata templates record provenance without guessing identity', {
  d<-withr::local_tempdir();dir.create(file.path(d,'first'));dir.create(file.path(d,'second'))
  writeLines('template only',file.path(d,'first','arbitrary_control.JPG'))
  writeLines('template only',file.path(d,'second','unseen_photo.png'))
  x<-suppressMessages(make_metadata(d,recursive=TRUE))
  expect_setequal(x$file,c('arbitrary_control.JPG','unseen_photo.png'))
  expect_true(all(file.exists(file.path(d,x$relative_file))))
  expect_true(all(is.na(x$set_id)));expect_true(all(is.na(x$treatment)))
  expect_false("metadata_confirmed" %in% names(x))
  writeLines('duplicate',file.path(d,'second','arbitrary_control.JPG'))
  y <- suppressMessages(make_metadata(d,recursive=TRUE,overwrite=TRUE))
  expect_equal(nrow(y),3L); expect_equal(length(unique(y$plate_id)),3L)
  expect_equal(length(unique(y$relative_file)),3L)
})
test_that('saved review cannot change image-layout settings without reanalysis', {
  d<-example_experiment()$colonies;d$metadata_confirmed<-FALSE
  x<-list(colonies=d,plates=unique(d[c("plate_id","file","set_id","treatment","metadata_confirmed")]),failed=data.frame())
  m<-x$plates;m$metadata_confirmed<-TRUE;m$qc_pass<-TRUE
  m$rotation_deg<-15
  expect_error(finalize_analysis(x,m),'requires image reanalysis')
})
