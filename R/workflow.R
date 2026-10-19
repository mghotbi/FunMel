#' Prepare photographs as an experiment project
#'
#' Finds photographs recursively, preserving their relative paths. With a
#' batch/control and batch/treatment folder structure, each batch path proposes
#' a separate set_id and the leaf folder proposes the treatment. Only explicit
#' control folder names are recognized. Other structures produce blank labels
#' that may remain blank for measurement; matching labels are needed for comparisons. Folder suggestions never confirm experimental
#' identity or QC. One photograph must represent one independent plate; repeated
#' time points of a plate are not independent replicates.
#'
#' @param input Photograph folder, ZIP, or a photograph inside the intended
#'   folder. Selecting a photograph includes all supported images in its containing
#'   folder and subfolders, not only that image. For multiple batches, supply the
#'   root folder or ZIP. NULL opens a file chooser. Selecting an existing project
#'   or analysis RDS beside project.rds reopens it with load_experiment().
#' @param project_dir New output folder; must be empty or not yet exist.
#' @param metadata Optional metadata data frame or CSV path. Otherwise a unique
#'   plate_metadata.csv in the input is used, or a template is proposed.
#' @param control_folders Exact folder labels denoting controls (case-insensitive).
#' @param max_uncompressed_mb Maximum total selected ZIP entry size in MB.
#' @return A funmel_project with paths to metadata, images, QC and result files.
#' @examples
#' \dontrun{
#' project <- prepare_experiment() # Choose a photo ZIP or one photo in its folder.
#' # Matching labels can be supplied later; use the correct segmentation layout.
#' result <- run_experiment(project, n_spots = 5, spot_radius_mm = 0.4)
#' # Inspect project$qc_dir; review reminders do not require approval-flag edits.
#' reviewed <- finish_experiment(project)
#' }
#' @export
prepare_experiment <- function(input = NULL, project_dir = "FunMel_project",
                               metadata = NULL, control_folders = c("control", "controls"),
                               max_uncompressed_mb = 2048) {
  if(is.null(input)) {
    message("Select a photograph ZIP, one photograph inside its folder, or project.rds to reopen saved work.")
    input <- tryCatch(file.choose(),error=function(e)
      stop("No input selected. Nothing was prepared. Run prepare_experiment() again, or supply a photograph-folder path.",call.=FALSE))
  }
  if(!is.character(input) || length(input)!=1L || is.na(input) || !file.exists(input))
    stop("Choose an existing photograph folder, ZIP or photograph. To reopen saved work, use load_experiment().",call.=FALSE)
  image_pattern <- "\\.(jpe?g|png|tiff?|heic)$"
  if(!dir.exists(input) && grepl("\\.rds$",input,ignore.case=TRUE)) {
    if(!is.null(metadata)) stop("To change an existing project, load it and edit its metadata CSV; metadata= is for new projects.",call.=FALSE)
    project <- load_experiment(input)
    message("Opened existing project in ",project$project_dir,". No new project was created; read saved tables with read_experiment(project), or finalize with finish_experiment(project).")
    return(project)
  }
  if(!dir.exists(input) && grepl(image_pattern,input,ignore.case=TRUE)) {
    input <- dirname(normalizePath(input,mustWork=TRUE))
    message("Using selected photograph's containing folder: ",input,
      ". All supported photographs there and in subfolders will be included. For multiple batches, supply their common root folder or ZIP. Check the segmentation layout before interpretation; matching labels can be supplied later.")
  }
  if(!dir.exists(input) && !grepl("\\.zip$",input,ignore.case=TRUE))
    stop("Selected file is not a photograph or photo ZIP. Select a JPG/PNG/TIFF/HEIC, a ZIP, or project.rds; a metadata CSV, QC PDF or SVG is not a photograph input.",call.=FALSE)
  if(!is.numeric(max_uncompressed_mb) || length(max_uncompressed_mb)!=1L ||
     !is.finite(max_uncompressed_mb) || max_uncompressed_mb<=0) stop("max_uncompressed_mb must be positive.")
  if(!is.character(control_folders) || !length(control_folders) || anyNA(control_folders) ||
     any(!nzchar(control_folders))) stop("control_folders must be explicit nonempty labels.")
  if(dir.exists(project_dir) && length(list.files(project_dir,all.files=TRUE,no..=TRUE)))
    stop("project_dir must be new or empty; existing metadata and results will not be overwritten.")
  if(!dir.exists(input)) {
    listing <- tryCatch(utils::unzip(input,list=TRUE),error=function(e) stop("Cannot read the selected photo ZIP: ",conditionMessage(e),call.=FALSE))
    entries <- gsub("\\\\","/",listing$Name)
    unsafe <- grepl("(^|/)\\.\\.(/|$)|^/|^[A-Za-z]:",entries)
    if(any(unsafe)) stop("ZIP contains unsafe extraction paths.")
    good <- !grepl("(^|/)__MACOSX/|(^|/)\\._",entries)
    selected <- good & (grepl(image_pattern,entries,ignore.case=TRUE) |
                        tolower(basename(entries))=="plate_metadata.csv")
    if(!any(grepl(image_pattern,entries[selected],ignore.case=TRUE))) stop("ZIP contains no supported photographs.")
    if(anyDuplicated(tolower(entries[selected]))) stop("ZIP contains duplicate entry paths.")
    if(sum(listing$Length[selected])/1024^2>max_uncompressed_mb) stop("ZIP exceeds max_uncompressed_mb.")
    dir.create(project_dir,recursive=TRUE,showWarnings=FALSE)
    root <- file.path(project_dir,"photos");dir.create(root)
    utils::unzip(input,files=listing$Name[selected],exdir=root)
  } else root <- normalizePath(input,mustWork=TRUE)
  rel <- list.files(root,recursive=TRUE,pattern=image_pattern,ignore.case=TRUE)
  rel <- rel[!grepl("(^|/)__MACOSX/|(^|/)\\._",rel)]
  if(!length(rel)) stop("No supported photographs found.")
  if(anyDuplicated(tolower(rel))) stop("Photograph paths differ only by case; rename them before analysis.")
  if(is.null(metadata)) {
    csv <- list.files(root,recursive=TRUE,full.names=TRUE,pattern="^plate_metadata\\.csv$",ignore.case=TRUE)
    if(length(csv)>1L) stop("Multiple plate_metadata.csv files found. Supply one combined metadata table explicitly.")
    if(length(csv)==1L) metadata <- utils::read.csv(csv,stringsAsFactors=FALSE,check.names=FALSE)
  }
  if(is.character(metadata) && length(metadata)==1L) metadata <- utils::read.csv(metadata,stringsAsFactors=FALSE,check.names=FALSE)
  if(is.null(metadata)) {
    parent <- dirname(rel);leaf <- basename(parent);batch <- dirname(parent)
    ctrl <- tolower(leaf) %in% tolower(control_folders)
    structured <- batch %in% batch[ctrl]
    trt <- ifelse(structured,ifelse(ctrl,"control",leaf),NA_character_)
    sets <- ifelse(structured,batch,parent)
    sets[sets=="."] <- "set1"
    ids <- make.unique(gsub("[^A-Za-z0-9._-]","_",tools::file_path_sans_ext(rel)),sep="_")
    metadata <- data.frame(file=basename(rel),relative_file=rel,plate_id=ids,
      set_id=sets,treatment=trt,centre_model=ifelse(is.na(trt),NA_character_,ifelse(ctrl,"none","fungus")),
      partner_type=ifelse(is.na(trt),NA_character_,ifelse(ctrl,"none","fungus")),
      qc_pass=FALSE,stringsAsFactors=FALSE,check.names=FALSE)
  } else {
    if(!is.data.frame(metadata) || !nrow(metadata)) stop("metadata must be a nonempty table.")
    # A new analysis requires a fresh image review, even if the supplied design was confirmed.
    metadata$qc_pass <- FALSE
    ix <- match_image_rows(file.path(root,rel),metadata)
    metadata <- metadata[ix,,drop=FALSE]
    metadata$relative_file <- rel
  }
  metadata <- complete_metadata_columns(metadata)
  dir.create(project_dir,recursive=TRUE,showWarnings=FALSE)
  home <- normalizePath(project_dir,mustWork=TRUE)
  project <- structure(list(project_dir=home,image_root=normalizePath(root,mustWork=TRUE),
    metadata_file=file.path(home,"plate_metadata.csv"),qc_dir=file.path(home,"qc"),
    result_file=file.path(home,"image_analysis.rds"),reviewed_file=file.path(home,"reviewed_analysis.rds")),class="funmel_project")
  utils::write.csv(metadata,project$metadata_file,row.names=FALSE,na="")
  saveRDS(project,file.path(home,"project.rds"))
  message("Prepared ",nrow(metadata)," photographs. Edit ",project$metadata_file,
    " to review labels when comparisons are needed. Image measurement can start now; unlabeled images use the fungal layout by default. For control-only images use default_centre='none'. No approval-flag edits are required. Then run run_experiment(project).")
  project
}

#' Analyze all photographs in a prepared experiment
#'
#' Reads the editable project metadata, applies the fungal or control layout
#' per row, writes QC images and saves measurements. Review flags are reset
#' for this new analysis; coefficients are withheld until finish_experiment().
#' @param project A funmel_project, its current folder, project.rds, or a saved
#'   analysis beside project.rds. Use load_experiment() after moving a project.
#' @param n_spots Optional number of circular spots per target colony; NULL uses
#'   whole-colony pixels only. Spot and whole-colony results are kept separate.
#' @param spot_radius_mm Radius of each optional circular ROI (mm).
#' @param default_centre Segmentation fallback for unlabeled images, default
#'   fungus. Use none for control-only images. Per-image centre_model and known
#'   control labels take precedence. No treatment or control identity is guessed.
#' @param ... Other analyze_plate() settings, such as dish_diameter_mm and max_dim.
#' @return Batch result saved to image_analysis.rds and CSV tables.
#' @details Dish diameter and any supplied pixel scale must be finite positive numeric scalars. Invalid settings stop before image processing or changes to project QC flags.
#' Missing project metadata must be restored or its recorded path corrected.
#' A batch with failed images saves error reports and warns; it does not report success.
#' Inspect result$failed and resolve every failed image before finalization.
#' @export
run_experiment <- function(project, n_spots = NULL, spot_radius_mm = 0.5,
                           ..., default_centre="fungus") {
  default_centre <- match.arg(default_centre,c("fungus","none","bacteria"))
  project <- as_funmel_project(project)
  dots <- list(...)
  validate_image_settings(dots)
  validate_image_settings(list(n_spots=n_spots, spot_radius_mm=spot_radius_mm))
  meta <- read_project_metadata(project)
  validate_metadata(meta,stage="measurement")
  if(!"relative_file" %in% names(meta)) stop("Project metadata requires relative_file; preserve the prepared image paths.")
  files <- file.path(project$image_root,meta$relative_file)
  missing <- files[!file.exists(files) | dir.exists(files)]
  if(length(missing)) stop("Photographs are missing or unavailable locally: ",
    paste(utils::head(missing,5L),collapse="; "),
    ". Restore the files or correct the recorded image paths before rerunning.",call.=FALSE)
  if(any(!image_paths_within_root(files,project$image_root)))
    stop("Image paths must remain within the project image root.",call.=FALSE)
  # Preflight settings and file checks precede any changes to review flags.
  if(any(names(dots) %in% c("files","metadata","layout","qc_dir","coefficient_control","keep_images")))
    stop("Project files, metadata, layouts and QC are managed by run_experiment; pass only image settings.")
  unresolved <- vapply(seq_len(nrow(meta)),function(i)
    is.na(resolve_centre_model(meta[i,,drop=FALSE],NA_character_)),TRUE)
  if(any(unresolved)) message("Using default_centre='",default_centre,"' for ",sum(unresolved),
    " unlabeled photograph(s). This is a segmentation setting, not a treatment assignment. ",
    "For control-only images use default_centre='none'; mixed plates need the correct per-image centre_model or control label. Inspect QC before interpretation.")
  message("Review reminder: check plate identities, treatment/control assignments, matching sets and dish calibration before analysis. Processing does not require approval flags.")
  meta$qc_pass <- FALSE
  utils::write.csv(meta,project$metadata_file,row.names=FALSE,na="")
  result <- analyze_plates(files,metadata=meta,layout=function(row) layout_by_treatment(row,default_centre=default_centre),
    qc_dir=project$qc_dir,n_spots=n_spots,spot_radius_mm=spot_radius_mm,
    coefficient_control=NULL,...)
  result$qc_review <- qc_review_summary(meta)
  result$qc_review$require_qc <- FALSE
  n_failed <- nrow(result$failed)
  result$analysis_status <- if(n_failed==length(files)) "failed" else if(n_failed>0L) "partial" else "complete"
  design_issue <- comparison_metadata_issue(meta)
  result$comparison_status <- if(is.null(design_issue)) "not_finalized" else "awaiting_design"
  result$coefficient_error <- if(n_failed) "Resolve failed photographs and rerun before finalization." else
    if(!is.null(design_issue)) paste0("Comparisons withheld: ",design_issue) else
    "Awaiting finalization; inspect image QC and use finish_experiment(project)."
  saveRDS(result,project$result_file)
  write_experiment_tables(result,project$project_dir)
  if(n_failed==length(files)) {
    warning("No photographs were successfully analyzed. Failure details saved in result$failed and failed.csv. ",
      "Correct the errors and rerun run_experiment(project); do not finalize this run.",call.=FALSE)
  } else if(n_failed>0L) {
    warning(length(files)-n_failed," of ",length(files)," photographs analyzed; ",n_failed,
      " failed. Inspect result$failed or failed.csv, correct the errors and rerun before finalization.",call.=FALSE)
  } else {
    message("Successfully analyzed ",length(files)," photographs. Inspect ",project$qc_dir,
      "; check masks, calibration and experimental labels before interpreting results. ",
      "No approval-flag edits are required. Run finish_experiment(project) to export tables and, when matching labels are complete, comparison figures.")
  }
  result
}

#' Finalize a prepared experiment after plate review
#'
#' Loads saved measurements and metadata without a manual approval gate, and
#' applies the requested image-QC policy (warning by default), then
#' computes whole-colony matched coefficients and plate-level assessment, and
#' exports the comparison figure and tables. Spot summaries stay separate;
#' use melanization_coefficient(..., response="MI_spot_mean") explicitly for
#' a prespecified, consistently applied spot-based analysis.
#' @param project A funmel_project, its current folder, project.rds, or a saved
#'   analysis beside project.rds. Use load_experiment() after moving a project.
#' @param ... Additional assess_experiment() settings.
#' @param require_qc Default FALSE warns and continues if image QC is unconfirmed.
#'   Set TRUE to require qc_pass=TRUE before finalization and plotting.
#' @return Result saved as reviewed_analysis.rds. If the matching design is
#'   incomplete, saves measurement-only outputs and comparison_status.csv;
#'   no comparison figure is generated. Complete the matching labels and finish
#'   again without remeasuring, provided the recorded layouts remain correct.
#' @export
finish_experiment <- function(project, ..., require_qc=FALSE) {
  project <- as_funmel_project(project)
  result <- read_experiment(project)
  meta <- read_project_metadata(project)
  if(nrow(result$failed)) stop("Resolve all failed photographs before finalization.")
  design_issue <- comparison_metadata_issue(meta)
  if(!is.null(design_issue)) {
    reviewed <- finalize_analysis(result,meta,...,require_qc=require_qc)
    archive_comparison_exports(project$project_dir)
    saveRDS(reviewed,project$reviewed_file)
    write_experiment_tables(reviewed,project$project_dir)
    message("Measurements saved in ",project$project_dir,
      ". Comparisons are awaiting experimental assignments; see comparison_status.csv. No photographs need remeasurement unless their layout changes.")
    return(reviewed)
  }
  context <- recorded_context_columns(meta)
  contexts <- if(length(context)) unique(meta[context]) else data.frame(.context="all")
  if(nrow(contexts)==1L) {
    reviewed <- finalize_analysis(result,meta,...,require_qc=require_qc)
    saveRDS(reviewed,project$reviewed_file)
    write_experiment_tables(reviewed,project$project_dir)
    plot_treatment_comparison(reviewed,require_qc=require_qc,file=file.path(project$project_dir,"treatment_comparison"))
  } else {
    # Different days/strains/media are separate analyses, never silently pooled.
    reviewed <- result; reviewed$context_results <- list()
    contexts$output_folder <- sprintf("context_%03d",seq_len(nrow(contexts)))
    for(k in seq_len(nrow(contexts))) {
      sel <- rep(TRUE,nrow(meta))
      for(nm in context) sel <- sel & !is.na(meta[[nm]]) & meta[[nm]]==contexts[[nm]][k]
      submeta <- meta[sel,,drop=FALSE]
      sub <- result
      for(nm in c("colonies","profiles","plates","spots")) if(nrow(sub[[nm]]))
        sub[[nm]] <- sub[[nm]][sub[[nm]]$plate_id %in% submeta$plate_id,,drop=FALSE]
      ans <- finalize_analysis(sub,submeta,...,require_qc=require_qc)
      path <- file.path(project$project_dir,contexts$output_folder[k]);dir.create(path,showWarnings=FALSE)
      write_experiment_tables(ans,path);saveRDS(ans,file.path(path,"reviewed_analysis.rds"))
      plot_treatment_comparison(ans,require_qc=require_qc,file=file.path(path,"treatment_comparison"))
      reviewed$context_results[[contexts$output_folder[k]]] <- ans
    }
    for(nm in c("colonies","profiles","plates","spots","melanization_coefficient",
                "coefficient_plate_means","per_plate_coefficients"))
      reviewed[[nm]] <- bind_rows_fill(lapply(reviewed$context_results,`[[`,nm))
    reviewed$metadata <- meta
    reviewed$metadata_column_maps <- reviewed$context_results[[1L]]$metadata_column_maps
    reviewed$qc_review <- qc_review_summary(meta)
    reviewed$qc_review$require_qc <- require_qc
    reviewed$assessment <- NULL;reviewed$coefficient_error <- NULL
    reviewed$comparison_status <- "complete"
    saveRDS(reviewed,project$reviewed_file)
    write_experiment_tables(reviewed,project$project_dir)
    utils::write.csv(contexts,file.path(project$project_dir,"context_index.csv"),row.names=FALSE)
  }
  message("Final outputs saved in ",project$project_dir,
          "; different recorded day/strain/medium contexts are reported separately.")
  reviewed
}

#' @keywords internal
#' @noRd
as_funmel_project <- function(project) {
  if(is.character(project)) return(load_experiment(project))
  if(!inherits(project,"funmel_project")) stop("Supply a FunMel project or use load_experiment().",call.=FALSE)
  home <- project$project_dir
  if(is.character(home) && length(home)==1L && !is.na(home) &&
     (!dir.exists(home) || (!any(file.exists(project$metadata_file)) && !any(file.exists(project$result_file))))) {
    anchors <- c(project$result_file,project$reviewed_file,project$metadata_file)
    anchors <- anchors[!is.na(anchors) & nzchar(anchors) & file.exists(anchors)]
    candidates <- character()
    for(d in unique(c(dirname(anchors),getwd()))) {
      f <- file.path(d,"project.rds")
      p <- if(file.exists(f)) tryCatch(readRDS(f),error=function(e) NULL) else NULL
      if(inherits(p,"funmel_project") && identical(p$project_dir,home)) candidates <- c(candidates,d)
    }
    if(length(candidates)==1L) {
      message("Reconnected moved project in ",candidates)
      return(load_experiment(candidates))
    }
  }
  if(is.character(home) && length(home)==1L && !is.na(home) &&
     identical(basename(project$result_file),"reviewed_analysis.rds") && file.exists(file.path(home,"image_analysis.rds")))
    project$result_file <- file.path(home,"image_analysis.rds")
  project
}

#' @keywords internal
#' @noRd
write_experiment_tables <- function(result, path) {
  if(!is.null(result$comparison_status)) utils::write.csv(data.frame(
    status=result$comparison_status,reason=if(is.null(result$coefficient_error)) "" else result$coefficient_error),
    file.path(path,"comparison_status.csv"),row.names=FALSE)
  if(!is.null(result$qc_review)) {
    qr <- result$qc_review
    utils::write.csv(data.frame(status=qr$status,n_plates=qr$n_plates,n_confirmed_plates=qr$n_confirmed_plates,
      require_qc=isTRUE(qr$require_qc),pending_plate_ids=paste(qr$pending_plate_ids,collapse=";")),
      file.path(path,"qc_review_status.csv"),row.names=FALSE)
  }
  if(!is.null(result$metadata)) utils::write.csv(result$metadata,file.path(path,"metadata_used.csv"),row.names=FALSE)
  for(nm in intersect(c("colonies","profiles","spots","plates","failed","melanization_coefficient",
    "coefficient_plate_means","per_plate_coefficients"),names(result)))
    utils::write.csv(result[[nm]],file.path(path,paste0(nm,".csv")),row.names=FALSE)
  if(!is.null(result$assessment)) saveRDS(result$assessment,file.path(path,"assessment.rds"))
  writeLines(utils::capture.output(utils::sessionInfo()),file.path(path,"sessionInfo.txt"))
}

#' Match actual image paths to exactly one metadata row
#' @keywords internal
#' @noRd
match_image_rows <- function(files, metadata) {
  if(!is.data.frame(metadata) || !"file" %in% names(metadata) || nrow(metadata)!=length(files))
    stop("Files and metadata must match one-to-one, with no unused rows.")
  norm <- function(x) gsub("\\\\","/",as.character(x))
  paths <- norm(files)
  refs <- if("relative_file" %in% names(metadata)) norm(metadata$relative_file) else norm(metadata$file)
  if(anyNA(refs) || any(!nzchar(refs)) || anyDuplicated(refs)) stop("Image references must be nonempty and unique; use relative_file for repeated basenames.")
  ix <- vapply(paths,function(f) {
    hit <- which(f==refs | endsWith(f,paste0("/",refs)))
    if(!length(hit)) hit <- which(basename(metadata$file)==basename(f))
    if(length(hit)!=1L) stop("Files and metadata must match one-to-one: ambiguous or missing image ",f,". Use relative_file including batch folders.")
    hit
  },integer(1))
  if(anyDuplicated(ix) || !setequal(ix,seq_len(nrow(metadata)))) stop("Files and metadata must match one-to-one, without unused rows or duplicate image paths.")
  unname(ix)
}

# Read the edited design, never silently reconstruct missing assignments.
read_project_metadata <- function(project) {
  p <- project$metadata_file
  if(!is.character(p) || length(p)!=1L || is.na(p) || !file.exists(p) || dir.exists(p))
    stop("Project metadata CSV is missing: ",paste(p,collapse="; "),
      ". Restore your edited plate_metadata.csv, or use load_experiment() to open its current complete project folder. ",
      "Do not recreate the project or guess treatment-control assignments.",call.=FALSE)
  tryCatch(utils::read.csv(p,stringsAsFactors=FALSE,check.names=FALSE),
    error=function(e) stop("Cannot read project metadata CSV at ",p,": ",conditionMessage(e),
      ". Check permissions and download cloud files locally.",call.=FALSE))
}

# Canonicalize both sides before comparing: Windows normalizePath() otherwise
# returns backslashes while .Platform$file.sep and file.path() use forward slashes.
image_paths_within_root <- function(paths, root) {
  paths <- normalizePath(paths, winslash="/", mustWork=TRUE)
  root <- normalizePath(root, winslash="/", mustWork=TRUE)
  canonical_paths_within_root(paths, root)
}

# Component boundary prevents e.g. photos_backup from matching photos.
# Inputs are canonical absolute paths; symlinks have already been resolved.
canonical_paths_within_root <- function(paths, root,
                                        windows=.Platform$OS.type=="windows") {
  if(windows) {
    paths <- tolower(chartr("\\", "/", paths))
    root <- tolower(chartr("\\", "/", root))
  }
  prefix <- paste0(sub("/+$", "", root), "/")
  startsWith(paths, prefix)
}

# Keep previously generated comparisons without presenting them as current results.
archive_comparison_exports <- function(path) {
  files <- file.path(path,paste0("treatment_comparison",c(".pdf",".svg",".png","_statistics.csv","_caption.txt")))
  files <- files[file.exists(files)]
  if(!length(files)) return(invisible(NULL))
  dest <- tempfile("previous_comparisons_",tmpdir=path)
  dir.create(dest)
  if(!all(file.copy(files,dest))) stop("Could not preserve previous comparison figures.",call.=FALSE)
  unlink(files)
  message("Previous comparison exports retained in ",dest,"; they are not results for the current metadata.")
  invisible(dest)
}
