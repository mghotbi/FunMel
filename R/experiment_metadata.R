#' Validate the plate-to-set metadata used for matched controls
#'
#' One row must represent one independent plate photographed once. set_id defines
#' which treatment and control plates are biologically comparable; controls are
#' never borrowed from a different set. Use globally unique plate IDs and unambiguous relative file paths. Repeated photographs of the same plate are not new replicates.
#' @param metadata Data frame containing file, plate_id, set_id and treatment.
#'   treatment must equal control for controls. Other labels identify treatments
#'   consistently across sets. Optional zymo_strain, medium and day must be
#'   complete and constant within each set once any value is recorded; entirely
#'   unrecorded optional columns may remain blank.
#' @param files Optional vector of image paths. Exactly these images must appear
#'   once in metadata; no unmatched or unused rows are accepted.
#' @param control Exact label used for control plates, default control.
#' @param stage comparison (default) checks the matched experimental design.
#'   measurement checks image identities only; experimental labels and optional
#'   context fields may remain blank. Explicit invalid layouts are still errors.
#' @return The validated metadata, invisibly. Errors explain invalid mappings.
#' @export
validate_metadata <- function(metadata, files=NULL, control="control",
                              stage=c("comparison","measurement")) {
  stage <- match.arg(stage)
  if(is.data.frame(metadata) && anyDuplicated(names(metadata))) stop("Metadata column names must be unique.")
  context_columns <- if(is.data.frame(metadata)) recorded_context_columns(metadata) else character()
  req <- if(stage=="measurement") c("file","plate_id") else c("file","plate_id","set_id","treatment")
  if(!is.data.frame(metadata) || !nrow(metadata) || !all(req %in% names(metadata)))
    stop("Metadata needs one row per plate and columns: ",paste(req,collapse=", "))
  for(nm in req) if(anyNA(metadata[[nm]]) || any(!nzchar(trimws(as.character(metadata[[nm]])))))
    stop("Missing/empty metadata in ",nm,". Complete it before ",if(stage=="measurement") "measurement." else "comparison.")
  if(any(grepl("[/\\\\]",metadata$plate_id)) || any(metadata$plate_id %in% c(".","..")))
    stop("plate_id must be a filename-safe label without path separators.")
  if(anyDuplicated(metadata$plate_id)) stop("plate_id must be globally unique: one photograph per independent plate.")
  refs <- if("relative_file" %in% names(metadata)) metadata$relative_file else metadata$file
  if(anyNA(refs) || any(!nzchar(refs)) || anyDuplicated(refs))
    stop("Image references must be unique; supply relative_file for duplicate basenames in separate folders.")
  if(!is.null(files)) match_image_rows(files,metadata)
  if(stage=="measurement") {
    if("centre_model" %in% names(metadata)) {
      supplied <- !is.na(metadata$centre_model) & nzchar(trimws(as.character(metadata$centre_model)))
      if(any(supplied & !metadata$centre_model %in% c("none","bacteria","fungus")))
        stop("centre_model must be none, bacteria or fungus when supplied.")
      if("treatment" %in% names(metadata) && any(supplied & !is.na(metadata$treatment) &
          metadata$treatment==control & metadata$centre_model!="none"))
        stop("Control plates must use centre_model='none'.")
    }
    return(invisible(metadata))
  }
  for(id in unique(metadata$set_id)) {
    m <- metadata[metadata$set_id==id,,drop=FALSE]
    if(!any(m$treatment==control)) stop("Set '",id,"' has no matching control. Controls from other sets cannot be used.")
    if(!any(m$treatment!=control)) stop("Set '",id,"' has no treatment plate.")
    for(nm in context_columns)
      if(anyNA(m[[nm]]) || any(!nzchar(trimws(as.character(m[[nm]])))) || length(unique(m[[nm]]))!=1L)
        stop("Within set '",id,"', ",nm," must be complete and constant. Define distinct sets for different contexts.")
  }
  if("centre_model" %in% names(metadata)) {
    supplied <- !is.na(metadata$centre_model) & nzchar(trimws(as.character(metadata$centre_model)))
    if(any(supplied & !metadata$centre_model %in% c("none","bacteria","fungus")))
      stop("centre_model must be none, bacteria or fungus when supplied.")
    if(any(supplied & metadata$treatment==control & metadata$centre_model!="none"))
      stop("Control plates must use centre_model='none'.")
  }
  invisible(metadata)
}
