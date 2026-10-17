test_that("fungal centre is separate from targets and bacterial measurements", {
  lay<-plate_layout(centre='fungus')
  # Use the original simulator's central bright body and coloured annulus,
  # then declare its biological partner type fungal for the classification test.
  sim<-simulate_plate(width=600,height=800,seed=2,layout=lay)
  r<-suppressWarnings(analyze_plate(sim$image,layout=lay,n_boot=20,verbose=FALSE))
  expect_true(any(sim$truth$central_fungus))
  expect_false(any(sim$truth$bacteria))
  expect_equal(nrow(r$colonies),4L)
  expect_true(all(r$colonies$is_target))
  expect_true(all(r$colonies$detected))
  expect_true(any(r$plate$objects$central_fungus))
  expect_false(any(r$plate$objects$bacteria))
  expect_false(any(r$plate$objects$central_fungus & r$plate$objects$labels>0))
  expect_false(any(r$plate$objects$hyphae & r$plate$objects$labels>0))
  expect_equal(r$plate_summary$central_partner_type,'fungus')
  expect_true(r$plate_summary$central_fungus_area_mm2>0)
  expect_true(all(r$colonies$interaction_target=='fungus'))
  expect_true(all(is.na(r$colonies$gap_bacteria_mm)))
  expect_true(all(is.finite(r$colonies$gap_partner_mm)))
})
test_that("legacy MycoHalo exported function names are retained", {
  expect_true(is.function(is_mycohalo_plate))
  expect_true(all(c('response','group','plate','reference','method') %in% names(formals(compare_melanization))))
  d<-example_experiment()$colonies
  r<-compare_melanization(d,reference='control',method='plate_means')
  expect_equal(r$status,'ok')
  expect_true(all(c('model','coefficients','descriptives','matched_coefficients') %in% names(r)))
})
test_that("supplied review records do not gate matched coefficients", {
  d<-example_experiment()$colonies;d$metadata_confirmed<-FALSE
  expect_equal(nrow(melanization_coefficient(d)$coefficients),6L)
  d$metadata_confirmed<-TRUE
  expect_equal(nrow(melanization_coefficient(d)$coefficients),6L)
  z<-melanization_coefficient(d)
  expect_equal(nrow(z$per_plate_coefficients),18L)
  for(i in seq_len(nrow(z$coefficients))) {
    x<-z$coefficients[i,]
    pp<-subset(z$per_plate_coefficients,set_id==x$set_id & treatment==x$treatment)
    expect_equal(mean(pp$melanization_coefficient),x$melanization_coefficient)
  }
})
test_that("coefficient is a ratio of means rather than a mean of position ratios", {
  d<-data.frame(plate_id=rep(c('C1','T1'),each=2),set_id='S1',treatment=rep(c('control','A'),each=2),
                colony_id=rep(c('TL','TR'),2),MI_mean=c(20,80,40,80))
  expect_equal(melanization_coefficient(d)$coefficients$melanization_coefficient,1.2)
})
test_that("facing correction uses controls in the same set", {
  d<-data.frame(set_id=c('S1','S1','S2','S2'),treatment=c('control','A','control','B'),
                colony_id='TL',delta_MI_facing=c(1,3,10,12))
  z<-correct_facing_bias(d)
  expect_equal(z$delta_MI_facing_corrected,c(0,2,0,2))
})
test_that("all original MycoHalo export names remain callable", {
  old<-c('analyze_plate','analyze_plates','annotate_plate','calibrate_color','classify_pixels',
         'colony_profiles','compare_melanization','correct_facing_bias','delta_e76','detect_plate',
         'example_plate','extract_training_pixels','is_mycohalo_plate','lab_chroma_hue','lab_to_srgb',
         'layout_by_treatment','make_metadata','measure_colonies','model_background','plate_layout',
         'plot_melanization_map','plot_profiles','plot_qc','read_plate','segment_colonies',
         'simulate_plate','srgb_to_lab','train_classifier')
  expect_true(all(vapply(old,function(n) is.function(getExportedValue('FunMel',n)),TRUE)))
})
test_that('a narrow central-margin bridge cannot shift a target into the partner', {
  lay<-plate_layout(centre='fungus')
  sim<-simulate_plate(width=400,height=400,seed=8,layout=lay)
  p<-read_plate(sim$image) |> detect_plate() |> model_background() |> classify_pixels(lay)
  m<-FunMel:::dish_masks(p);d<-p$dish;mm<-d$mm_per_px
  ep<-FunMel:::layout_pixels(lay,d)
  map<-matrix(0L,nrow(m$x),ncol(m$x))
  for(i in 1:4) map[(m$x-ep$x[i])^2+(m$y-ep$y[i])^2 <= (5/mm)^2]<-1L
  r<-sqrt((m$x-d$x)^2+(m$y-d$y)^2)*mm
  ring<-r>8 & r<9
  map[ring]<-1L;map[r<=8]<-2L
  # Thin connector along the radial direction toward BL; classification
  # uncertainty at the contact links the two biological objects.
  vx<-ep$x[4]-d$x;vy<-ep$y[4]-d$y;nv<-sqrt(vx^2+vy^2)
  along<-((m$x-d$x)*vx+(m$y-d$y)*vy)/nv*mm
  across<-abs((m$x-d$x)*vy-(m$y-d$y)*vx)/nv*mm
  map[along>8 & along<nv*mm & across<0.25 & r>8]<-1L
  p$classes$map<-map
  z<-segment_colonies(p,lay,edge_criterion=0,bridge_mm=0.5)
  expect_true(all(z$objects$colony_table$detected))
  expect_gt(z$objects$colony_table$segmentation_trim_fraction[4],0)
  expect_lt(sum(z$objects$labels==4 & ring),0.1*sum(ring))
  w<-which(z$objects$labels==4)
  expect_lt(sqrt((mean(m$x[w])-ep$x[4])^2+(mean(m$y[w])-ep$y[4])^2)*mm,2)
})
