#' Calculate the treatment-to-control melanization coefficient
#'
#' Computes MC = mean treatment plate MI / mean control plate MI. Each plate
#' MI is the arithmetic mean of its target colony MI_mean values. Plates are
#' equally weighted, irrespective of pixel counts or numbers of colonies.
#' This is a ratio of descriptive image-darkness indices, not a ratio of
#' melanin concentrations. MC > 1 indicates a darker treatment mean; MC < 1
#' indicates a lighter treatment mean. No significance test or CI is implied.
#'
#' @param colonies Colony data frame returned by [analyze_plates()], or such
#'   a batch result. Must contain group, plate, colony_id and response columns.
#'   Only target Zymoseptoria rows should be supplied. The standard central
#'   partner ID is excluded automatically; specify other partner IDs below.
#' @param control Exact group label for the no-interaction control.
#' @param group Treatment column. Every non-control level is compared separately.
#' @param plate Column identifying an independent plate uniquely.
#' @param response Colony-level index column, default MI_mean (range 0 to 100).
#' @param by Optional matching columns, e.g. c("zymo_strain", "day", "medium").
#'   A control must exist within each combination. Do not include partner
#'   identity when controls do not share it. Missing matching values are errors.
#' @param set Matching-set column, required. Controls are never pooled across sets.
#' @param exclude_ids Colony identifiers excluded before calculation. Default
#'   excludes centre and center, used for the central interacting fungus.
#' @param na_action Either error (default) for undetected/nonfinite target
#'   colonies or omit, which warns and reports excluded counts. A plate with
#'   no eligible target measurements remains unavailable, not silently dropped.
#' @return List with coefficients (one row per contrast and matching stratum),
#'   plate_means, and settings. Undefined ratios have NA and an explicit status.
#'   Counts distinguish measured target colonies, excluded target rows and plates.
#'   One plate per group permits a descriptive ratio, not biological inference.
#' @examples
#' d <- data.frame(plate_id = rep(c("C1", "T1"), each = 4),
#'                 set_id = "set1",
#'                 treatment = rep(c("control", "fungus"), each = 4),
#'                 colony_id = rep(c("TL", "TR", "BR", "BL"), 2),
#'                 MI_mean = c(40, 42, 38, 40, 60, 62, 58, 60))
#' melanization_coefficient(d)$coefficients  # 60 / 40 = 1.5
#' @export
melanization_coefficient <- function(colonies, control="control",
                                    group="treatment", plate="plate_id",
                                    response="MI_mean", by=NULL,
                                    exclude_ids=c("centre", "center"),
                                    na_action=c("error", "omit"), set="set_id") {
  na_action <- match.arg(na_action)
  if(length(set)!=1L || is.na(set) || !nzchar(set)) stop("Specify a matching-set column.")
  by <- unique(c(set,by))
  if (is.list(colonies) && !is.data.frame(colonies) && !is.null(colonies$colonies))
    colonies <- colonies$colonies
  needed <- unique(c(group,plate,response,"colony_id",by))
  if (!is.data.frame(colonies) || !all(needed %in% names(colonies)))
    stop("colonies must contain: ",paste(needed,collapse=", "))
  if (length(control)!=1L || is.na(control) || !nzchar(control)) stop("control must be one nonempty label.")
  if (anyDuplicated(by) || any(by %in% c(group,plate,response,"colony_id"))) stop("by must contain distinct matching columns.")
  keep <- !as.character(colonies$colony_id) %in% exclude_ids
  if ("is_target" %in% names(colonies)) {
    if(anyNA(colonies$is_target) || !is.logical(colonies$is_target)) stop("is_target must be a complete logical column.")
    keep <- keep & colonies$is_target
  }
  df <- colonies[keep,,drop=FALSE]
  if("metadata_confirmed" %in% names(df) && (!is.logical(df$metadata_confirmed) || anyNA(df$metadata_confirmed) || any(!df$metadata_confirmed)))
    stop("Confirm the proposed plate-to-treatment/control metadata before calculating coefficients (metadata_confirmed=TRUE).")
  if ("qc_pass" %in% names(df) && (!is.logical(df$qc_pass) || anyNA(df$qc_pass) || any(!df$qc_pass)))
    stop("All included plates need qc_pass=TRUE after mask review; do not silently discard failed plates.")
  if (!nrow(df)) stop("No target colonies remain after excluding partner IDs.")
  for (nm in c(group,plate,"colony_id",by)) {
    if (anyNA(df[[nm]]) || any(!nzchar(trimws(as.character(df[[nm]])))))
      stop("Missing or empty values in ",nm,"; complete metadata before comparing plates.")
  }
  for(id in unique(df[[set]])) for(nm in intersect(c("zymo_strain","medium","day"),names(df))) {
    v <- df[[nm]][df[[set]]==id]
    if(anyNA(v) || any(!nzchar(trimws(as.character(v)))) || length(unique(v))!=1L)
      stop("Within each matched set, ",nm," must be complete and constant.")
  }
  if (!is.numeric(df[[response]])) stop(response," must be numeric.")
  if (any(is.finite(df[[response]]) & (df[[response]] < -1e-6 | df[[response]] > 100+1e-6)))
    stop(response," must be on the MI scale from 0 to 100.")
  if (anyDuplicated(df[c(plate,"colony_id")])) stop("Duplicate plate/colony rows; use colony summaries, not radial profile rows.")
  groups <- split(seq_len(nrow(df)),as.character(df[[plate]]))
  for (idx in groups) for (nm in c(group,by))
    if (length(unique(df[[nm]][idx]))!=1L) stop("Each plate must have one value of ",nm,"; use globally unique plate IDs.")
  valid <- is.finite(df[[response]])
  if ("detected" %in% names(df)) valid <- valid & !is.na(df$detected) & df$detected==TRUE
  if (any(!valid)) {
    if (na_action=="error") stop("Undetected or nonfinite target MI values. Inspect QC; use na_action='omit' only with a documented exclusion decision.")
    warning(sum(!valid)," target colony rows excluded; inspect plate_means for incomplete plates.")
  }
  rows <- lapply(groups,function(idx) {
    z <- df[idx[valid[idx]],response]
    data.frame(df[idx[1],c(plate,group,by),drop=FALSE],
               MI_plate=if(length(z)) mean(z) else NA_real_,
               n_target_colonies=length(idx),n_colonies_used=length(z),
               n_colonies_excluded=sum(!valid[idx]),row.names=NULL)
  })
  pm <- do.call(rbind,rows); rownames(pm) <- NULL
  strata <- if(length(by)) unique(pm[by]) else data.frame(.all=1L)
  contrasts <- list(); per_plate <- list()
  for (s in seq_len(nrow(strata))) {
    sel <- rep(TRUE,nrow(pm))
    for(nm in by) sel <- sel & pm[[nm]]==strata[[nm]][s]
    sub <- pm[sel,,drop=FALSE]
    ctr <- sub[as.character(sub[[group]])==control,,drop=FALSE]
    for(trt in setdiff(unique(as.character(sub[[group]])),control)) {
      tx <- sub[as.character(sub[[group]])==trt,,drop=FALSE]
      cmean <- if(nrow(ctr) && all(is.finite(ctr$MI_plate))) mean(ctr$MI_plate) else NA_real_
      tmean <- if(all(is.finite(tx$MI_plate))) mean(tx$MI_plate) else NA_real_
      status <- if(!nrow(ctr)) "missing_control" else if(!is.finite(cmean) || !is.finite(tmean))
        "plate_without_usable_MI" else if(cmean<=0) "nonpositive_control_MI" else "ok"
      mc <- if(status=="ok") tmean/cmean else NA_real_
      for(j in seq_len(nrow(tx))) {
        pr<-data.frame(tx[j,c(plate,group,by),drop=FALSE],MI_treatment_plate=tx$MI_plate[j],
                       MI_matching_control=cmean,melanization_coefficient=if(status=="ok") tx$MI_plate[j]/cmean else NA_real_,
                       n_control_plates=nrow(ctr),status=status,row.names=NULL)
        per_plate[[length(per_plate)+1L]]<-pr
      }
      row <- data.frame(treatment=trt,control=control,MI_treatment_mean=tmean,MI_control_mean=cmean,
                        melanization_coefficient=mc,delta_MI=tmean-cmean,
                        n_treatment_plates=nrow(tx),n_control_plates=nrow(ctr),
                        control_replication=if(nrow(ctr)==1L) "single_control_plate" else "replicated_controls",
                        n_treatment_colonies=sum(tx$n_colonies_used),n_control_colonies=sum(ctr$n_colonies_used),
                        n_excluded_target_colonies=sum(tx$n_colonies_excluded)+sum(ctr$n_colonies_excluded),
                        status=status,interpretation=if(status!="ok") "Ratio unavailable; inspect status." else
                          if(mc>1) "Higher treatment image-darkness index." else if(mc<1)
                            "Lower treatment image-darkness index." else "Equal mean image-darkness index.",
                        stringsAsFactors=FALSE)
      if(length(by)) row <- cbind(strata[s,,drop=FALSE],row)
      contrasts[[length(contrasts)+1L]] <- row
    }
  }
  if(!length(contrasts)) stop("No non-control treatment available for comparison.")
  out <- do.call(rbind,contrasts); rownames(out) <- NULL
  if(any(out$status!="ok")) warning("Some coefficients are unavailable; inspect the status column.")
  list(coefficients=out,per_plate_coefficients=if(length(per_plate)) do.call(rbind,per_plate) else data.frame(),plate_means=pm,target_data=df[valid,,drop=FALSE],
       settings=list(control=control,group=group,plate=plate,response=response,by=by,set=set,
                     exclude_ids=exclude_ids,na_action=na_action,
                     weighting="equal colonies within plate; equal plates within group",
                     inference="descriptive ratio; no biological confidence interval or p-value"))
}
