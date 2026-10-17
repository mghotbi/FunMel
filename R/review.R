#' Finalize saved measurements after reviewing metadata and image masks
#'
#' Reuses measurements; no photograph needs to be processed again. This function
#' records user review, not automatic biological validation. All included plates
#' must have metadata_confirmed explicitly TRUE. Unconfirmed image QC warns by
#' default; require_qc=TRUE requires qc_pass=TRUE for every included plate.
#' @param result Batch result returned by analyze_plates(), possibly read from RDS.
#' @param metadata Reviewed metadata with one row per plate, metadata_confirmed
#'   and optional qc_pass logical columns. Use FALSE for unconfirmed image QC;
#'   do not mark it TRUE merely to obtain a coefficient.
#' @param ... Arguments forwarded to assess_experiment().
#' @param require_qc Default FALSE warns and continues with unconfirmed QC.
#'   TRUE requires every qc_pass flag to be logical TRUE. Review flags are never
#'   automatically changed to TRUE; calculated results retain their QC status.
#' @return Updated batch result, including matched coefficients and assessment.
#' @export
finalize_analysis <- function(result, metadata, ..., require_qc=FALSE) {
  if(!is.list(result) || is.null(result$colonies) || !nrow(result$colonies)) stop("Supply a completed batch result.")
  if(!is.null(result$failed) && nrow(result$failed)) stop("Resolve failed plates before finalizing.")
  validate_metadata(metadata)
  for(nm in "metadata_confirmed")
    if(!nm %in% names(metadata) || !is.logical(metadata[[nm]]) || anyNA(metadata[[nm]]) || any(!metadata[[nm]]))
      stop("Every included plate requires ",nm,"=TRUE after review.")
  if(!"qc_pass" %in% names(metadata)) metadata$qc_pass <- FALSE
  ids <- unique(as.character(result$colonies$plate_id))
  if(!setequal(ids,as.character(metadata$plate_id))) stop("Reviewed metadata must match the analyzed plate IDs exactly.")
  layout_fields <- c("rotation_deg","radius_frac","radius_mm","search_frac","start_deg","n_colonies")
  immutable <- intersect(c("file","relative_file","centre_model","partner_type",layout_fields),names(metadata))
  old <- result$plates
  for(nm in setdiff(intersect(layout_fields,names(metadata)),names(old)))
    if(any(!is.na(metadata[[nm]]))) stop("Adding ",nm," requires image reanalysis; saved masks used another layout.")
  for(nm in intersect(immutable,names(old))) {
    a <- as.character(old[[nm]]); b <- as.character(metadata[[nm]][match(old$plate_id,metadata$plate_id)])
    if(nm=="file") {a<-basename(a);b<-basename(b)}
    if(!identical(a,b)) stop("Changing ",nm," requires image reanalysis, because it affects file identity or segmentation.")
  }
  result <- attach_result_metadata(result,metadata)
  result$assessment <- assess_experiment(result,...,require_qc=require_qc)
  result$melanization_coefficient <- result$assessment$coefficients
  result$coefficient_plate_means <- result$assessment$plate_means
  result$per_plate_coefficients <- result$assessment$per_plate_coefficients
  result$qc_review <- result$assessment$qc_review
  result$coefficient_error <- NULL
  result
}
