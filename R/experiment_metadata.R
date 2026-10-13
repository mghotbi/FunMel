#' Validate the plate-to-set metadata used for matched controls
#'
#' One row must represent one independent plate photographed once. set_id defines
#' which treatment and control plates are biologically comparable; controls are
#' never borrowed from a different set. Use globally unique plate IDs and file
#' basenames. Repeated photographs of the same plate are not new replicates.
#' @param metadata Data frame containing file, plate_id, set_id and treatment.
#'   treatment must equal control for controls. Other labels identify treatments
#'   consistently across sets. Optional zymo_strain, medium and day must be
#'   complete and constant within each set if present.
#' @param files Optional vector of image paths. Exactly these images must appear
#'   once in metadata; no unmatched or unused rows are accepted.
#' @param control Exact label used for control plates, default control.
#' @return The validated metadata, invisibly. Errors explain invalid mappings.
#' @export
validate_metadata <- function(metadata, files=NULL, control="control") {
  req <- c("file","plate_id","set_id","treatment")
  if(!is.data.frame(metadata) || !nrow(metadata) || !all(req %in% names(metadata)))
    stop("Metadata needs one row per plate and columns: ",paste(req,collapse=", "))
  for(nm in req) if(anyNA(metadata[[nm]]) || any(!nzchar(trimws(as.character(metadata[[nm]])))))
    stop("Missing/empty metadata in ",nm,". Complete it before analysis.")
  if(any(grepl("[/\\\\]",metadata$plate_id)) || any(metadata$plate_id %in% c(".","..")))
    stop("plate_id must be a filename-safe label without path separators.")
  if(anyDuplicated(metadata$plate_id)) stop("plate_id must be globally unique: one photograph per independent plate.")
  if(anyDuplicated(basename(metadata$file))) stop("Image basenames in metadata must be unique.")
  if(!is.null(files) && (anyDuplicated(basename(files)) ||
                          !setequal(basename(files),basename(metadata$file))))
    stop("Files and metadata must match one-to-one, with no unused rows or duplicate basenames.")
  for(id in unique(metadata$set_id)) {
    m <- metadata[metadata$set_id==id,,drop=FALSE]
    if(!any(m$treatment==control)) stop("Set '",id,"' has no matching control. Controls from other sets cannot be used.")
    if(!any(m$treatment!=control)) stop("Set '",id,"' has no treatment plate.")
    for(nm in intersect(c("zymo_strain","medium","day"),names(m)))
      if(anyNA(m[[nm]]) || any(!nzchar(trimws(as.character(m[[nm]])))) || length(unique(m[[nm]]))!=1L)
        stop("Within set '",id,"', ",nm," must be complete and constant. Define distinct sets for different contexts.")
  }
  if("centre_model" %in% names(metadata)) {
    if(anyNA(metadata$centre_model) || any(!metadata$centre_model %in% c("none","bacteria","fungus")))
      stop("centre_model must be none, bacteria or fungus (legacy segmentation model names).")
    if(any(metadata$treatment==control & metadata$centre_model!="none"))
      stop("Control plates must use centre_model='none'.")
  }
  invisible(metadata)
}
