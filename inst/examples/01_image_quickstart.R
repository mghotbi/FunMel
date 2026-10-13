# Run with source(system.file('examples','01_image_quickstart.R',package='FunMel')).
# These schematic images have known simulated truth, not biological results.
library(FunMel)
example_output <- tempfile('FunMel_images_')
dir.create(example_output)
example_results <- list()
for (partner in c('none', 'fungus', 'bacteria')) {
  lay <- plate_layout(centre=partner)
  sim <- simulate_plate(width=400,height=500,layout=lay,seed=101+match(partner,c('none','fungus','bacteria')))
  res <- analyze_plate(sim$image,layout=lay,id=paste0('example_',partner),
                       n_boot=20,verbose=FALSE,
                       qc_file=file.path(example_output,paste0(partner,'_qc.png')))
  example_results[[partner]] <- res
  print(res$colonies[,c('colony_id','detected','MI_mean','area_mm2')])
}
# Keep the image arrays for interactive QC; the PNGs also remain available.
if(interactive()) plot_qc(example_results$fungus)
message('Synthetic QC examples saved in: ',example_output)
