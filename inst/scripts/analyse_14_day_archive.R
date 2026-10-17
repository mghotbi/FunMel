# FunMel 0.4.3: choose the original ZIP containing the plate photographs.

library(FunMel)
if(package_version(as.character(getNamespaceVersion('FunMel'))) < '0.4.3')
  stop('Restart R and load FunMel 0.4.3 before running this script.')
output_dir <- 'FunMel_14_day_review'
dir.create(output_dir,recursive=TRUE,showWarnings=FALSE)
meta_file <- file.path(output_dir,'proposed_metadata.csv')
if(!file.exists(meta_file)) {
  template <- system.file('validation','proposed_photo_metadata.csv',package='FunMel')
  if(!nzchar(template) || !file.copy(template,meta_file)) stop('Could not obtain the metadata template.')
}
meta <- read.csv(meta_file,stringsAsFactors=FALSE,check.names=FALSE)
message('Choose the original photograph ZIP containing the eight A60_2/B20_2 example photographs. Other images are not analysed by this script.')
photo_zip <- file.choose()
files <- FunMel::prepare_photo_archive(photo_zip,meta,file.path(output_dir,'photos'))
FunMel::validate_metadata(meta,files)
message('Found all ',length(files),' expected photographs. Starting image analysis.')
out <- FunMel::analyze_plates(files,metadata=meta,
 layout=function(row) FunMel::layout_by_treatment(row),
 qc_dir=file.path(output_dir,'qc'),max_dim=1200)
saveRDS(out,file.path(output_dir,'image_analysis.rds'))
for(nm in c('colonies','profiles','plates','failed','melanization_coefficient','per_plate_coefficients','coefficient_plate_means'))
 utils::write.csv(out[[nm]],file.path(output_dir,paste0(nm,'.csv')),row.names=FALSE)
if(!nrow(out$plates)) {
  print(out$failed)
  stop('No plates completed. Failures were saved in failed.csv; no assessment attempted.')
}
show <- intersect(c('plate_id','n_colonies_detected','central_detected','hyphae_status'),names(out$plates))
print(out$plates[,show,drop=FALSE])
if(nrow(out$failed)) {
  print(out$failed)
  warning('Some plates failed; final assessment has not been attempted.')
} else if(!is.null(out$coefficient_error)) {
  message('Coefficient assessment pending: ',out$coefficient_error)
  message('Review metadata and every QC image before interpreting the results.')
  utils::write.csv(data.frame(status='pending_review',reason=out$coefficient_error),
    file.path(output_dir,'coefficient_status.csv'),row.names=FALSE)
  tryCatch(FunMel::plot_treatment_comparison(out,preview=TRUE,
    file=file.path(output_dir,'treatment_comparison_PREVIEW')),
    error=function(e) message('Preview unavailable: ',conditionMessage(e)))
  message('After review, use scripts/finalize_14_day_review.R; saved measurements will be reused.')
} else {
  assessment <- FunMel::assess_experiment(out)
  print(assessment$status);print(assessment$overall_coefficients)
  saveRDS(assessment,file.path(output_dir,'assessment.rds'))
  FunMel::plot_treatment_comparison(out,file=file.path(output_dir,'treatment_comparison'))
}
