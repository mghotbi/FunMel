#' Summarize optional image-review flags without changing them
#' @keywords internal
#' @noRd
qc_review_summary <- function(data, plate="plate_id") {
  ids <- if(plate %in% names(data)) as.character(data[[plate]]) else as.character(seq_len(nrow(data)))
  recorded <- "qc_pass" %in% names(data)
  approved <- if(recorded && is.logical(data$qc_pass)) !is.na(data$qc_pass) & data$qc_pass else rep(FALSE,nrow(data))
  per_plate <- vapply(split(approved,ids),all,TRUE)
  list(status=if(!recorded) "not_recorded" else if(all(per_plate)) "confirmed" else "unconfirmed",
       n_plates=length(per_plate),n_confirmed_plates=sum(per_plate),
       pending_plate_ids=names(per_plate)[!per_plate])
}

#' Apply the requested image-review policy
#' @keywords internal
#' @noRd
check_qc_review <- function(data, require_qc=FALSE, plate="plate_id", warn_missing=FALSE) {
  if(!is.logical(require_qc) || length(require_qc)!=1L || is.na(require_qc))
    stop("require_qc must be TRUE or FALSE.")
  review <- qc_review_summary(data,plate)
  review$require_qc <- require_qc
  if(review$status!="confirmed") {
    msg <- paste0("Image QC is not confirmed for ",length(review$pending_plate_ids),
      " plate(s). Inspect colony masks, central fungal tissue/hyphae, sampling spots, calibration and warnings before interpreting or publishing results. ",
      "The standard workflow continues without editing review flags; no plates were automatically approved or excluded.")
    if(require_qc) stop("require_qc=TRUE: every included plate requires qc_pass=TRUE after review. ",msg)
    if(review$status!="not_recorded" || warn_missing) warning(msg,call.=FALSE)
  }
  review
}
