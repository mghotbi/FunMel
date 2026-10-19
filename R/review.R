#' Finalize saved measurements after reviewing metadata and image masks
#'
#' Reuses saved measurements without reprocessing photographs. Valid experimental
#' metadata proceeds automatically; no metadata approval flags are required.
#' A reminder asks users to review assignments, masks and calibration before
#' interpreting results. Computation does not establish biological validation.
#' @param result Batch result returned by analyze_plates(), possibly read from RDS.
#' @param metadata Metadata with one row per independent plate. User-defined
#'   columns are retained; review flags do not gate the standard workflow.
#' @param ... Arguments forwarded to assess_experiment().
#' @param require_qc Default FALSE warns and continues with unconfirmed QC.
#'   TRUE requires every qc_pass flag to be logical TRUE. Review flags are never
#'   automatically changed to TRUE; calculated results retain their QC status.
#' @return Updated batch result. A valid matching design adds coefficients and
#'   assessment. Otherwise comparison_status is awaiting_design, measurements
#'   remain available, and the reason is recorded without inventing comparisons.
#' @export
finalize_analysis <- function(result, metadata, ..., require_qc=FALSE) {
  if(!is.list(result) || is.null(result$colonies) || !nrow(result$colonies)) stop("Supply a completed batch result.")
  if(!is.null(result$failed) && nrow(result$failed)) stop("Resolve failed plates before finalizing.")
  validate_metadata(metadata,stage="measurement")
  message("Review reminder: verify treatment/control assignments, matching sets, image masks and calibration before interpreting results. No metadata approval-flag edits are required.")
  if(!"qc_pass" %in% names(metadata)) metadata$qc_pass <- FALSE
  check_saved_metadata(result,metadata)
  result <- attach_result_metadata(result,metadata)
  issue <- comparison_metadata_issue(metadata)
  if(!is.null(issue)) {
    result$comparison_status <- "awaiting_design"
    result$coefficient_error <- paste0("Comparisons withheld: ",issue)
    result$qc_review <- check_qc_review(metadata,require_qc=require_qc)
    result$assessment <- list(status="awaiting_design",reason=issue)
    for(nm in c("melanization_coefficient","coefficient_plate_means","per_plate_coefficients"))
      result[[nm]] <- if(is.data.frame(result[[nm]])) result[[nm]][FALSE,,drop=FALSE] else data.frame()
    message("Image measurements are available. ",result$coefficient_error,
      " Optional strain, medium, date and notes may remain blank. Complete only the matching design when comparisons are needed; no approval flags are required.")
    return(result)
  }
  result$comparison_status <- "complete"
  result$assessment <- assess_experiment(result,...,require_qc=require_qc)
  result$melanization_coefficient <- result$assessment$coefficients
  result$coefficient_plate_means <- result$assessment$plate_means
  result$per_plate_coefficients <- result$assessment$per_plate_coefficients
  result$qc_review <- result$assessment$qc_review
  result$coefficient_error <- NULL
  result
}

check_saved_metadata <- function(result,metadata) {
  validate_metadata(metadata,stage="measurement")
  ids <- unique(as.character(result$colonies$plate_id))
  if(!setequal(ids,as.character(metadata$plate_id))) stop("Metadata must match the analyzed plate IDs exactly.")
  layout_fields <- c("rotation_deg","radius_frac","radius_mm","search_frac","start_deg","n_colonies")
  immutable <- intersect(c("file","relative_file","centre_model","partner_type",layout_fields),names(metadata))
  old <- result$plates
  if(is.data.frame(result$analysis_layout) && nrow(result$analysis_layout)) {
    recorded <- result$analysis_layout
    idx <- match(metadata$plate_id,recorded$plate_id)
    if(anyNA(idx)) stop("Saved segmentation layouts do not match plate IDs.")
    requested <- vapply(seq_len(nrow(metadata)),function(i)
      resolve_centre_model(metadata[i,,drop=FALSE],NA_character_),character(1))
    if(any(!is.na(requested) & requested!=recorded$centre_model[idx]))
      stop("Changing centre_model requires image reanalysis; saved masks used another layout.")
    immutable <- setdiff(immutable,c("centre_model","partner_type"))
  }
  for(nm in setdiff(intersect(layout_fields,names(metadata)),names(old)))
    if(any(!is.na(metadata[[nm]]))) stop("Adding ",nm," requires image reanalysis; saved masks used another layout.")
  for(nm in intersect(immutable,names(old))) {
    a <- as.character(old[[nm]]); b <- as.character(metadata[[nm]][match(old$plate_id,metadata$plate_id)])
    if(nm=="file") {a<-basename(a);b<-basename(b)}
    if(!identical(a,b)) stop("Changing ",nm," requires image reanalysis, because it affects file identity or segmentation.")
  }
  invisible(NULL)
}

comparison_metadata_issue <- function(metadata) {
  tryCatch({validate_metadata(metadata);NULL},error=function(e) conditionMessage(e))
}
