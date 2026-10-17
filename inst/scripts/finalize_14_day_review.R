# Reuse existing measurements after verifying experimental metadata AND QC masks.
library(FunMel)
if(package_version(as.character(getNamespaceVersion('FunMel'))) < '0.4.3')
  stop('Restart R and load FunMel 0.4.3.')
output_dir <- 'FunMel_14_day_review'
meta <- read.csv(file.path(output_dir,'proposed_metadata.csv'),stringsAsFactors=FALSE,check.names=FALSE)
out <- readRDS(file.path(output_dir,'image_analysis.rds'))
# Edit the CSV first: metadata_confirmed=TRUE only for verified mappings;
# Optionally record qc_pass=TRUE after acceptable masks and calibration review.
# Default unconfirmed QC warns; use require_qc=TRUE for mandatory approval.
reviewed <- FunMel::finalize_analysis(out,meta)
saveRDS(reviewed,file.path(output_dir,'reviewed_analysis.rds'))
saveRDS(reviewed$assessment,file.path(output_dir,'assessment.rds'))
for(nm in c('melanization_coefficient','per_plate_coefficients','coefficient_plate_means'))
  utils::write.csv(reviewed[[nm]],file.path(output_dir,paste0(nm,'.csv')),row.names=FALSE)
utils::write.csv(data.frame(status=reviewed$assessment$status,reason='See assessment diagnostics'),
  file.path(output_dir,'coefficient_status.csv'),row.names=FALSE)
FunMel::plot_treatment_comparison(reviewed,file=file.path(output_dir,'treatment_comparison'))
print(reviewed$assessment$status)
print(reviewed$assessment$overall_coefficients)
