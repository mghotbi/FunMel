# Diagnostics describe saved values; they never repair or infer experimental roles.
empty_workflow_issues <- function() data.frame(
  plate_id=character(),set_id=character(),field=character(),issue=character(),
  action=character(),stringsAsFactors=FALSE)

metadata_design_issues <- function(metadata) {
  out <- empty_workflow_issues()
  value <- function(nm) if(nm %in% names(metadata)) as.character(metadata[[nm]]) else rep(NA_character_,nrow(metadata))
  ids <- value("plate_id"); sets <- value("set_id"); trt <- value("treatment")
  missing <- function(x) is.na(x) | !nzchar(trimws(x))
  add <- function(ix,field,issue,action) {
    if(length(ix)) out <<- rbind(out,data.frame(plate_id=ids[ix],set_id=sets[ix],
      field=field,issue=issue,action=action,stringsAsFactors=FALSE))
  }
  add(which(missing(sets)),"set_id","missing_set",
      "Record the actual matching set shared by treatment plates and their own control.")
  add(which(missing(trt)),"treatment","missing_treatment",
      "Record the actual treatment code, or control for an experimentally identified control plate.")
  variants <- !missing(trt) & tolower(trimws(trt))=="control" & trt!="control"
  add(which(variants),"treatment","control_label_not_exact",
      "For confirmed controls use the exact label control, without spaces or capital letters.")
  for(s in unique(sets[!missing(sets)])) {
    ix <- which(!missing(sets) & sets==s)
    if(!any(missing(trt[ix]))) {
      if(!any(trt[ix]=="control")) add(ix,"treatment","missing_matching_control",
        "Identify the actual control within this set; do not borrow a control from another set.")
      if(!any(trt[ix]!="control")) add(ix,"treatment","missing_treatment_plate",
        "Supply the actual treatment plates in this matching set.")
    }
    for(nm in recorded_context_columns(metadata)) {
      v <- value(nm)[ix]
      if(any(missing(v))) add(ix[missing(v)],nm,"incomplete_recorded_context",
        paste0("Complete recorded ",nm," within this set, or leave the entire annotation column unrecorded when unknown."))
      else if(length(unique(v))!=1L) add(ix,nm,"mixed_context_within_set",
        paste0("Define separate matching sets for different ",nm," contexts."))
    }
  }
  out
}

measurement_issue_table <- function(result) {
  out <- data.frame(plate_id=character(),colony_id=character(),field=character(),
                    issue=character(),action=character(),stringsAsFactors=FALSE)
  co <- result$colonies
  if(!is.data.frame(co) || !nrow(co) || !all(c("plate_id","colony_id","MI_mean") %in% names(co))) return(out)
  keep <- !as.character(co$colony_id) %in% c("centre","center")
  if("is_target" %in% names(co)) keep <- keep & !is.na(co$is_target) & co$is_target
  co <- co[keep,,drop=FALSE]
  valid <- is.finite(co$MI_mean)
  if("detected" %in% names(co)) valid <- valid & !is.na(co$detected) & co$detected
  add <- function(ix,field,issue,action) {
    if(length(ix)) out <<- rbind(out,data.frame(plate_id=as.character(co$plate_id[ix]),
      colony_id=as.character(co$colony_id[ix]),field=field,issue=issue,
      action=action,stringsAsFactors=FALSE))
  }
  add(which(!valid),"MI_mean","missing_target_measurement",
      "Inspect this colony in QC; correct its image/layout and rerun. No missing MI is imputed or silently omitted.")
  if(all(c("n_spots_requested","n_spots_measured") %in% names(co))) {
    incomplete <- valid & is.finite(co$n_spots_requested) & co$n_spots_requested>0 &
      (!is.finite(co$n_spots_measured) | co$n_spots_measured<co$n_spots_requested)
    for(i in which(incomplete)) add(i,"MI_spot_mean","incomplete_spot_sampling",
      paste0("Measured ",co$n_spots_measured[i]," of ",co$n_spots_requested[i],
        " requested spots. Inspect masks and spot size; whole-colony MI remains available. Use consistent feasible spot settings if remeasuring."))
  }
  out
}

missing_target_measurement_issue <- function(result) {
  x <- measurement_issue_table(result)
  x <- x[x$issue=="missing_target_measurement",,drop=FALSE]
  if(!nrow(x)) return(NULL)
  examples <- paste(utils::head(paste0(x$plate_id,"/",x$colony_id),5L),collapse=", ")
  paste0(nrow(x)," target colony measurement(s) are missing or undetected: ",examples,
    ". Inspect measurement_issues.csv and QC; correct the image/layout and rerun before matched comparisons. No target values were imputed or silently excluded.")
}

add_workflow_diagnostics <- function(result,metadata) {
  result$metadata_issues <- metadata_design_issues(metadata)
  result$measurement_issues <- measurement_issue_table(result)
  result$measurement_qc_status <- if(nrow(result$measurement_issues)) "needs_review" else "no_missing_measurements"
  if(is.data.frame(result$analysis_layout) && nrow(result$analysis_layout)) {
    x <- result$analysis_layout[result$analysis_layout$plate_id %in% metadata$plate_id,,drop=FALSE]
    ix <- match(x$plate_id,metadata$plate_id)
    supplied <- function(nm) if(nm %in% names(metadata)) {
      v <- as.character(metadata[[nm]][ix]); !is.na(v) & nzchar(trimws(v))
    } else rep(FALSE,nrow(x))
    explicit <- supplied("centre_model")
    control <- if("treatment" %in% names(metadata)) !is.na(metadata$treatment[ix]) & metadata$treatment[ix]=="control" else rep(FALSE,nrow(x))
    partner <- if("partner_type" %in% names(metadata)) !is.na(metadata$partner_type[ix]) & metadata$partner_type[ix] %in% c("none","fungus","bacteria") else rep(FALSE,nrow(x))
    x$layout_source <- ifelse(explicit,"centre_model",ifelse(control,"control_label",ifelse(partner,"partner_type","default_fallback")))
    x$review_message <- ifelse(x$layout_source=="default_fallback",
      "Default layout used; biological role is unknown. Actual controls need centre_model=none and reanalysis if another layout was used.",
      "Recorded layout used; inspect QC and verify against experimental records.")
    result$layout_assignments <- x
  }
  co <- result$colonies
  target <- if(is.data.frame(co) && nrow(co)) !as.character(co$colony_id) %in% c("centre","center") else logical()
  if(length(target) && "is_target" %in% names(co)) target <- target & !is.na(co$is_target) & co$is_target
  n_target <- sum(target)
  if(!n_target) result$measurement_qc_status <- "no_target_measurements"
  n_missing <- sum(result$measurement_issues$issue=="missing_target_measurement")
  n_incomplete <- sum(result$measurement_issues$issue=="incomplete_spot_sampling")
  n_failed <- if(is.data.frame(result$failed)) nrow(result$failed) else 0L
  n_plates <- length(unique(c(if(is.data.frame(result$plates)) as.character(result$plates$plate_id),
                            if(is.data.frame(result$failed) && "file" %in% names(result$failed)) as.character(result$failed$file))))
  result$run_summary <- data.frame(images_processed=n_plates,image_failures=n_failed,
    target_colony_rows=n_target,finite_detected_colony_MI=n_target-n_missing,
    missing_colony_MI=n_missing,colonies_with_incomplete_spots=n_incomplete,
    image_processing_status=if(!is.null(result$analysis_status)) result$analysis_status else "not_recorded",
    measurement_qc_status=result$measurement_qc_status,
    comparison_status=if(!is.null(result$comparison_status)) result$comparison_status else "not_finalized",
    stringsAsFactors=FALSE)
  result
}

report_workflow_diagnostics <- function(result) {
  s <- result$run_summary
  if(!is.data.frame(s) || !nrow(s)) return(invisible(NULL))
  message("Measurement summary: ",s$finite_detected_colony_MI,"/",s$target_colony_rows,
    " target-colony MI values available; ",s$missing_colony_MI," missing; ",
    s$colonies_with_incomplete_spots," detected colonies have incomplete spot sampling. ",
    "Image-processing completion does not imply complete colony measurements or biological validation.")
  if(nrow(result$measurement_issues)) message("Inspect measurement_issues.csv and the named colony QC before interpreting results.")
  if(nrow(result$metadata_issues)) message("Matching-design issues affect ",
    length(unique(result$metadata_issues$plate_id))," plate(s); see metadata_issues.csv for fields, plate IDs and next steps. ",
    "Colony MI values remain in colonies.csv; coefficient tables are unavailable until the matching design is valid.")
  invisible(NULL)
}
