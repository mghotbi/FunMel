#' Exclude or reinstate individual colonies after image review
#'
#' Save a review decision by exact plate and colony ID. The next
#' [finish_experiment()] applies it automatically. Original image measurements,
#' detection flags and plate-level qc_pass values are not changed.
#' @param project A saved FunMel project or its current folder.
#' @param plate_id,colony_id Character vectors identifying the rejected targets.
#'   A single plate ID may be used with several colony IDs.
#' @param reason Nonempty review reason, one per decision or one shared reason.
#' @param exclude TRUE excludes the colony; FALSE reinstates it. One logical
#'   value or one per decision.
#' @return Invisibly, the saved decision table. Decisions are written to
#'   colony_exclusions.csv beside project.rds. Repeating an ID pair updates its
#'   decision. Raw measurements are retained. Exclusions belong to the current
#'   saved image-analysis run; re-review and record them again after reanalysis.
#' @details Use guided recovery first when a boundary can be corrected.
#'   A finite MI from a bad mask cannot be identified automatically.
#'   Exclusions apply to target-colony comparisons, including spot-based
#'   coefficients. With na_action="omit", remaining valid targets are used.
#'   A plate without usable targets still requires review. Review flags do not
#'   filter data. Measurements from excluded masks remain in output tables for
#'   audit and must not be interpreted as valid size, colour or spot values.
#' @examples
#' \dontrun{
#' exclude_colonies(project, plate_id="plate_1", colony_id="TR",
#'                  reason="Mask includes agar")
#' reviewed <- finish_experiment(project)
#' # Reinstate after reviewing the decision:
#' exclude_colonies(project, "plate_1", "TR",
#'                  reason="Rechecked; boundary is acceptable", exclude=FALSE)
#' }
#' @export
exclude_colonies <- function(project, plate_id, colony_id, reason, exclude=TRUE) {
  project <- as_funmel_project(project)
  result <- read_experiment(project)
  if(!file.exists(project$result_file))
    stop("The original image_analysis.rds is required to bind exclusions to this run.",call.=FALSE)
  n <- max(length(plate_id), length(colony_id), length(reason), length(exclude))
  expand <- function(x, nm) {
    if (!length(x) || !length(x) %in% c(1L, n))
      stop(nm, " must have length one or the number of decisions.", call.=FALSE)
    rep(x, length.out=n)
  }
  text <- function(x, nm) {
    if (!is.character(x) || anyNA(x) || any(!nzchar(trimws(x))))
      stop(nm, " must contain nonempty text.", call.=FALSE)
    x
  }
  plate_id <- expand(text(plate_id,"plate_id"),"plate_id")
  colony_id <- expand(text(colony_id,"colony_id"),"colony_id")
  reason <- expand(text(reason,"reason"),"reason")
  if (!is.logical(exclude) || anyNA(exclude))
    stop("exclude must be TRUE or FALSE.", call.=FALSE)
  exclude <- expand(exclude,"exclude")
  decisions <- data.frame(plate_id=plate_id, colony_id=colony_id,
    exclude=exclude, reason=reason,
    analysis_md5=unname(as.character(tools::md5sum(project$result_file))),
    updated_utc=format(Sys.time(),tz="UTC",format="%Y-%m-%dT%H:%M:%SZ"),
    stringsAsFactors=FALSE)
  validate_colony_exclusions(decisions, result)
  path <- file.path(project$project_dir,"colony_exclusions.csv")
  old <- if(file.exists(path)) read_colony_exclusions(path) else decisions[FALSE,]
  validate_colony_exclusions(old, result)
  old_key <- colony_exclusion_keys(old)
  new_key <- colony_exclusion_keys(decisions)
  decisions <- rbind(old[!old_key %in% new_key,,drop=FALSE],decisions)
  utils::write.csv(decisions,path,row.names=FALSE,na="")
  message("Saved colony review decisions in ",path,
          ". Original measurements are unchanged. Run finish_experiment(project); ",
          "qc_pass flags do not exclude colonies.")
  invisible(decisions)
}

colony_exclusion_keys <- function(x) paste(x$plate_id,x$colony_id,sep="\r")

read_colony_exclusions <- function(path) {
  x <- utils::read.csv(path,colClasses="character",check.names=FALSE)
  if(!"exclude" %in% names(x) || anyNA(x$exclude) ||
     any(!x$exclude %in% c("TRUE","FALSE")))
    stop("Exclusion decisions need logical TRUE/FALSE exclude values.",call.=FALSE)
  x$exclude <- x$exclude=="TRUE"
  x
}

validate_colony_exclusions <- function(x, result) {
  required <- c("plate_id","colony_id","exclude","reason","analysis_md5","updated_utc")
  if(!is.data.frame(x) || !setequal(names(x),required))
    stop("Invalid colony_exclusions.csv. Use exclude_colonies() to record review decisions.",call.=FALSE)
  if(!nrow(x)) return(invisible(NULL))
  for(nm in setdiff(required,"exclude"))
    if(!is.character(x[[nm]]) || anyNA(x[[nm]]) ||
       any(!nzchar(trimws(x[[nm]]))) || any(grepl("\r",x[[nm]],fixed=TRUE)))
      stop("Invalid exclusion field: ",nm,call.=FALSE)
  if(!is.logical(x$exclude) || anyNA(x$exclude) || anyDuplicated(colony_exclusion_keys(x)))
    stop("Exclusion decisions need unique plate/colony IDs and logical exclude values.",call.=FALSE)
  co <- result$colonies
  target <- !as.character(co$colony_id) %in% c("centre","center")
  if("is_target" %in% names(co)) target <- target & !is.na(co$is_target) & co$is_target
  keys <- colony_exclusion_keys(co[target,,drop=FALSE])
  if(any(!colony_exclusion_keys(x) %in% keys))
    stop("Exclusion IDs must match target colonies in the saved project exactly.",call.=FALSE)
  invisible(NULL)
}

apply_project_exclusions <- function(result, project) {
  path <- file.path(project$project_dir,"colony_exclusions.csv")
  if(!file.exists(path)) return(result)
  x <- read_colony_exclusions(path)
  validate_colony_exclusions(x,result)
  hash <- unname(as.character(tools::md5sum(project$result_file)))
  if(any(x$exclude & x$analysis_md5 != hash))
    stop("Colony exclusions refer to an earlier image-analysis run. Review the new masks and ",
         "use exclude_colonies() to re-record or reinstate those colonies before finalizing.",call.=FALSE)
  for(nm in c("colonies","spots","profiles")) {
    df <- result[[nm]]
    if(is.data.frame(df) && all(c("plate_id","colony_id") %in% names(df))) {
      j <- match(colony_exclusion_keys(df),colony_exclusion_keys(x))
      flagged <- !is.na(j) & x$exclude[j]
      df$.funmel_excluded <- flagged
      df$.funmel_exclusion_reason <- ifelse(flagged,x$reason[j],"")
      result[[nm]] <- df
    }
  }
  result$colony_exclusions <- x
  result
}

colony_review_valid <- function(df) {
  if(!".funmel_excluded" %in% names(df)) return(rep(TRUE,nrow(df)))
  if(!is.logical(df$.funmel_excluded) || anyNA(df$.funmel_excluded))
    stop("Invalid saved colony exclusion flags.",call.=FALSE)
  !df$.funmel_excluded
}
