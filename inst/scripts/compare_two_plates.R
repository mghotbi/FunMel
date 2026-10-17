# FunMel: existing automatic image analysis plus treatment/control coefficient.
# Run in a fresh R session after installing FunMel 0.4.3.
library(FunMel)
stopifnot(utils::packageVersion("FunMel") >= "0.4.3")
message("Choose the CONTROL photograph (Zymoseptoria alone)")
control_file <- file.choose()
message("Choose the CONFRONTATION photograph")
treatment_file <- file.choose()
# For the included A60_2 confrontation example the central partner is a fungus.
# The metadata records the actual partner and the segmentation model below.
partner <- "fungus"
# Select the actual central partner type; the fungal path excludes it from target MI.
central_model <- partner
meta <- data.frame(file=basename(c(control_file,treatment_file)),
                   plate_id=c("control_plate","treatment_plate"),set_id="pair1",
                   treatment=c("control",partner),qc_pass=FALSE,
                   centre_model=c("none","fungus"),partner_type=c("none",partner),
                   stringsAsFactors=FALSE,check.names=FALSE)
output_dir <- "FunMel_comparison"
dir.create(output_dir,recursive=TRUE,showWarnings=FALSE)
write.csv(meta,file.path(output_dir,"plate_metadata.csv"),row.names=FALSE)
res <- FunMel::analyze_plates(
  c(control_file,treatment_file),metadata=meta,
  layout=function(row) FunMel::plate_layout(
    centre=if(row$treatment=="control") "none" else central_model),
  qc_dir=file.path(output_dir,"qc"),coefficient_control=NULL
)
write.csv(res$colonies,file.path(output_dir,"colonies.csv"),row.names=FALSE)
write.csv(res$profiles,file.path(output_dir,"profiles.csv"),row.names=FALSE)
write.csv(res$plates,file.path(output_dir,"plates.csv"),row.names=FALSE)
write.csv(res$failed,file.path(output_dir,"failed.csv"),row.names=FALSE)
write.csv(res$melanization_coefficient,file.path(output_dir,"melanization_coefficient.csv"),row.names=FALSE)
write.csv(res$coefficient_plate_means,file.path(output_dir,"coefficient_plate_means.csv"),row.names=FALSE)
saveRDS(res,file.path(output_dir,"analysis.rds"))
message("Review experimental assignments and image QC before interpretation. No approval-flag edits are required.")
message("Then: reviewed <- finalize_analysis(res, read.csv(file.path(output_dir, 'plate_metadata.csv')))")
message("Unconfirmed image QC warns by default; optional require_qc=TRUE enforces approval.")
if(!is.null(res$coefficient_error)) warning(res$coefficient_error)
message("Review every QC image in: ",normalizePath(file.path(output_dir,"qc")))
message("With one plate per condition, the coefficient is descriptive; no treatment significance is established.")

message("Central hyphal-growth masks require review and are excluded from target-colony MI.")
