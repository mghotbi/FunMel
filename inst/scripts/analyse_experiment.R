# GENERIC WORKFLOW. Copy this script and edit only these input settings.
# No filenames, treatment identities or replicate counts are inferred.
library(FunMel)
meta_file <- file.choose()                 # Select YOUR completed metadata CSV.
photo_root <- dirname(meta_file)           # Or set your photograph root folder.
photo_zip <- NULL                         # Or set an arbitrary original photo ZIP.
output_dir <- 'FunMel_results'
meta <- read.csv(meta_file,stringsAsFactors=FALSE,check.names=FALSE)
if(!'metadata_confirmed' %in% names(meta)) meta$metadata_confirmed <- FALSE
files <- if(is.null(photo_zip)) {
  file.path(photo_root,if('relative_file' %in% names(meta)) meta$relative_file else meta$file)
} else prepare_photo_archive(photo_zip,meta,file.path(output_dir,'photos'))
validate_metadata(meta,files)
dir.create(output_dir,recursive=TRUE,showWarnings=FALSE)
out <- analyze_plates(files,metadata=meta,
  layout=function(row) layout_by_treatment(row),qc_dir=file.path(output_dir,'qc'))
saveRDS(out,file.path(output_dir,'image_analysis.rds'))
write.csv(meta,file.path(output_dir,'metadata_for_review.csv'),row.names=FALSE)
for(nm in c('colonies','profiles','plates','failed','melanization_coefficient',
           'coefficient_plate_means','per_plate_coefficients'))
  write.csv(out[[nm]],file.path(output_dir,paste0(nm,'.csv')),row.names=FALSE)
writeLines(capture.output(sessionInfo()),file.path(output_dir,'sessionInfo.txt'))
if(nrow(out$failed)) {
  print(out$failed)
  message('Resolve failed images before final assessment. Completed results were saved.')
} else {
  confirmed <- all(c('metadata_confirmed','qc_pass') %in% names(meta)) &&
    is.logical(meta$metadata_confirmed) && is.logical(meta$qc_pass) &&
    !anyNA(meta$metadata_confirmed) && !anyNA(meta$qc_pass) &&
    all(meta$metadata_confirmed & meta$qc_pass)
  if(confirmed) {
    reviewed <- finalize_analysis(out,meta)
    saveRDS(reviewed,file.path(output_dir,'reviewed_analysis.rds'))
    for(nm in c('coefficients','overall_coefficients','within_sets','overall_effects','treatment_comparisons'))
      write.csv(reviewed$assessment[[nm]],file.path(output_dir,paste0(nm,'.csv')),row.names=FALSE)
    writeLines(c(paste('Status:',reviewed$assessment$status),capture.output(str(reviewed$assessment$diagnostics))),
      file.path(output_dir,'model_diagnostics.txt'))
    plot_treatment_comparison(reviewed,file=file.path(output_dir,'treatment_comparison'))
    print(reviewed$assessment$status)
  } else {
    write.csv(data.frame(status='pending_review',reason=if(is.null(out$coefficient_error))
      'Confirm metadata AND mask/calibration review before finalization.' else out$coefficient_error),
      file.path(output_dir,'coefficient_status.csv'),row.names=FALSE)
    tryCatch(plot_treatment_comparison(out,preview=TRUE,file=file.path(output_dir,'treatment_comparison_PREVIEW')),
      error=function(e) message('Preview withheld: ',conditionMessage(e)))
    message('Review qc/ and metadata_for_review.csv. Then add qc_pass=TRUE only for acceptable plates and confirm verified metadata.')
    message('Reuse saved measurements with finalize_analysis(out, reviewed_metadata); do not repeat image processing just for label changes.')
  }
}
