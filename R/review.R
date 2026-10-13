#' Finalize saved measurements after reviewing metadata and image masks
#'
#' Reuses measurements; no photograph needs to be processed again. This function
#' records user review, not automatic biological validation. All included plates
#' must have metadata_confirmed and qc_pass explicitly TRUE in the metadata.
#' @param result Batch result returned by analyze_plates(), possibly read from RDS.
#' @param metadata Reviewed metadata with one row per plate, metadata_confirmed
#'   and qc_pass logical columns. Use FALSE for a plate that requires correction;
#'   do not mark it TRUE merely to obtain a coefficient.
#' @param ... Arguments forwarded to assess_experiment().
#' @return Updated batch result, including matched coefficients and assessment.
#' @export
finalize_analysis <- function(result, metadata, ...) {
  if(!is.list(result) || is.null(result$colonies) || !nrow(result$colonies)) stop("Supply a completed batch result.")
  if(!is.null(result$failed) && nrow(result$failed)) stop("Resolve failed plates before finalizing.")
  validate_metadata(metadata)
  for(nm in c("metadata_confirmed","qc_pass"))
    if(!nm %in% names(metadata) || !is.logical(metadata[[nm]]) || anyNA(metadata[[nm]]) || any(!metadata[[nm]]))
      stop("Every included plate requires ",nm,"=TRUE after review.")
  ids <- unique(as.character(result$colonies$plate_id))
  if(!setequal(ids,as.character(metadata$plate_id))) stop("Reviewed metadata must match the analyzed plate IDs exactly.")
  layout_fields <- c("rotation_deg","radius_frac","radius_mm","search_frac","start_deg","n_colonies")
  immutable <- intersect(c("file","centre_model","partner_type",layout_fields),names(metadata))
  old <- result$plates
  for(nm in setdiff(intersect(layout_fields,names(metadata)),names(old)))
    if(any(!is.na(metadata[[nm]]))) stop("Adding ",nm," requires image reanalysis; saved masks used another layout.")
  for(nm in intersect(immutable,names(old))) {
    a <- as.character(old[[nm]]); b <- as.character(metadata[[nm]][match(old$plate_id,metadata$plate_id)])
    if(nm=="file") {a<-basename(a);b<-basename(b)}
    if(!identical(a,b)) stop("Changing ",nm," requires image reanalysis, because it affects file identity or segmentation.")
  }
  for(table in c("colonies","profiles","plates")) {
    z<-result[[table]]
    if(is.null(z) || !nrow(z)) next
    idx<-match(z$plate_id,metadata$plate_id)
    for(nm in setdiff(names(metadata),c("plate_id","file"))) z[[nm]]<-metadata[[nm]][idx]
    result[[table]]<-z
  }
  mc<-melanization_coefficient(result$colonies)
  result$melanization_coefficient<-mc$coefficients
  result$coefficient_plate_means<-mc$plate_means
  result$per_plate_coefficients<-mc$per_plate_coefficients
  result$coefficient_error<-NULL
  result$assessment<-assess_experiment(result,...)
  result
}
