#' Create a metadata template for matched treatment-control sets
#'
#' Writes one row per image. Fill set_id, treatment and centre_model before
#' analysis. All controls use the treatment label control; set_id decides which
#' controls belong to which treatments. The same treatment label across sets
#' must represent the same intervention. See [validate_metadata()].
#' Review flags metadata_confirmed and qc_pass start at FALSE. Set them to TRUE
#' only after verifying experimental assignments and inspecting plate QC plots.
#' @param dir Folder with photographs.
#' @param file Output CSV path.
#' @param treatment Optional default treatment label.
#' @param set_id Optional default set ID; leave missing for multiple sets.
#' @param patterns Optional named regular expressions for treatment labels.
#' @param extra Named list of additional metadata columns.
#' @param recursive Search nested image folders. Duplicate basenames require renaming.
#' @param overwrite Whether to replace an existing template.
#' @return Metadata invisibly, also written as CSV. Missing fields must be filled.
#' @export
make_metadata <- function(dir,file=file.path(dir,"plate_metadata.csv"),
                          treatment=NA_character_,set_id=NA_character_,patterns=NULL,
                          extra=list(),overwrite=FALSE,recursive=FALSE) {
  if(!dir.exists(dir)) stop("Image directory does not exist.")
  files<-list.files(dir,pattern="\\.(jpe?g|png|tiff?|heic)$",ignore.case=TRUE,recursive=recursive)
  if(anyDuplicated(basename(files))) stop("Image basenames must be unique across folders; rename duplicates before analysis.")
  if(!length(files)) stop("No supported images found.")
  trt<-rep(treatment,length(files))
  if(!is.null(patterns)) for(k in names(patterns)) trt[grepl(patterns[[k]],files,ignore.case=TRUE)]<-k
  meta<-data.frame(file=basename(files),plate_id=tools::file_path_sans_ext(basename(files)),
                   set_id=rep(set_id,length(files)),treatment=trt,
                   centre_model=ifelse(!is.na(trt) & trt=="control","none",NA_character_),
                   partner_type=ifelse(!is.na(trt) & trt=="control","none",NA_character_),
                   metadata_confirmed=FALSE,qc_pass=FALSE,relative_file=files,
                   stringsAsFactors=FALSE)
  for(nm in names(extra)) meta[[nm]]<-extra[[nm]]
  if(file.exists(file) && !overwrite) stop("Metadata file exists; use overwrite=TRUE only if intended.")
  utils::write.csv(meta,file,row.names=FALSE,na="")
  message("Metadata template saved. Fill set_id, treatment and centre_model; record biological partner_type separately. Review flags metadata_confirmed and qc_pass start FALSE; confirm each plate after metadata and QC review.")
  invisible(meta)
}

#' Choose a segmentation layout from one metadata row
#'
#' The four approximately round target colonies occupy the standard diagonal
#' inoculation positions. Their measured boundaries are not forced into circles.
#' centre_model is a computational recipe, not organism identification. For
#' fungal confrontations, use centre_model=fungus so the central fungus is
#' returned separately from the four target colonies and from bacterial outputs.
#' @param row One metadata row with treatment and optional centre_model. Optional
#'   numeric rotation_deg, radius_frac, radius_mm, search_frac, start_deg and
#'   n_colonies columns customize the layout per image. Explicit ... takes priority.
#' @param ... Other [plate_layout()] arguments, e.g. radius_mm or positions.
#' @return A layout. Controls use centre=none. Explicit centre_model is respected.
#' @export
layout_by_treatment <- function(row,...) {
  if(is.null(row) || nrow(row)!=1L || !"treatment" %in% names(row) || is.na(row$treatment))
    stop("Provide one metadata row with a treatment label.")
  ctrl<-as.character(row$treatment)=="control"
  model<-if("centre_model" %in% names(row)) as.character(row$centre_model) else if("partner_type" %in% names(row)) as.character(row$partner_type) else if(ctrl) "none" else "bacteria"
  if(is.na(model) || !model %in% c("none","bacteria","fungus")) stop("Fill centre_model with none, bacteria or fungus.")
  if(ctrl && model!="none") stop("Control plates require centre_model='none'.")
  args<-list(centre=model,...)
  for(nm in c("rotation_deg","radius_frac","radius_mm","search_frac","start_deg","n_colonies"))
    if(nm %in% names(row) && !is.na(row[[nm]][1]) && !nm %in% names(args)) args[[nm]]<-row[[nm]][1]
  do.call(plate_layout,args)
}

#' Remove position-specific lighting bias from side-specific metrics
#'
#' Under directional light every raised colony is brighter on the side that
#' faces the lamp, whatever the treatment. On a fixed copy stand this bias
#' depends on the colony's position in the frame (TL, TR, BR, BL), so it is
#' estimated from controls at the same position within each set_id, when
#' that column is present. Without set_id the supplied table is one legacy set.
#'
#' @param colonies Colony table from [analyze_plates()].
#' @param control Value of `group` that marks control plates.
#' @param group Column holding the treatment.
#' @param vars Side-specific columns to correct.
#' @return `colonies` with extra columns `<var>_corrected`.
#' @examples
#' d <- data.frame(colony_id = rep(c("TL", "TR"), 4),
#'                 treatment = rep(c("control", "bacteria"), each = 4),
#'                 delta_MI_facing = c(4, -8, 5, -7, 9, -2, 10, -3))
#' correct_facing_bias(d)
#' @export
correct_facing_bias <- function(colonies, control = "control", group = "treatment",
                                vars = c("delta_MI_facing", "growth_inhibition_pct")) {
  vars <- intersect(vars,names(colonies))
  if(!all(c(group,"colony_id") %in% names(colonies))) stop("Treatment and colony_id columns required.")
  # Keep the original single-set API, but never pool controls when set_id exists.
  sets<-if("set_id" %in% names(colonies)) as.character(colonies$set_id) else rep("single_set",nrow(colonies))
  if(anyNA(sets) || any(!nzchar(sets))) stop("Complete set_id before bias correction.")
  for(v in vars) {
    colonies[[paste0(v,"_corrected")]]<-NA_real_
    for(s in unique(sets)) {
      ix<-which(sets==s);ctrl<-ix[!is.na(colonies[[group]][ix]) & colonies[[group]][ix]==control]
      if(!length(ctrl)) {warning("No matching control for bias correction in set ",s);next}
      bias<-tapply(colonies[[v]][ctrl],colonies$colony_id[ctrl],mean,na.rm=TRUE)
      colonies[[paste0(v,"_corrected")]][ix]<-colonies[[v]][ix]-unname(bias[colonies$colony_id[ix]])
    }
  }
  colonies
}
