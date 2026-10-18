#' Open an existing experiment in its current folder
#'
#' Reconnects internal paths after a complete project folder is moved. External
#' photograph locations are retained. Loading never edits metadata or measurements.
#' @param path Project folder, project.rds, or saved analysis beside project.rds.
#'   NULL opens a chooser; select project.rds.
#' @return A funmel_project with paths relative to its current folder resolved.
#' @examples
#' \dontrun{
#' project <- load_experiment() # Select project.rds in its current folder.
#' result <- read_experiment(project)
#' head(result$spots)
#' plot_treatment_comparison(project)
#' }
#' @export
load_experiment <- function(path=NULL) {
  if(is.null(path)) path <- tryCatch(file.choose(),error=function(e)
    stop("No project selected. Select project.rds in its current folder. Nothing was changed.",call.=FALSE))
  if(!is.character(path) || length(path)!=1L || is.na(path) || !nzchar(path))
    stop("Supply the current project folder or project.rds path.",call.=FALSE)
  if(!file.exists(path)) stop("Project path does not exist: ",path,
    ". Use load_experiment() to select project.rds in its current folder.",call.=FALSE)
  path <- normalizePath(path,mustWork=TRUE)
  home <- if(dir.exists(path)) path else dirname(path)
  value <- read_funmel_rds(if(dir.exists(path)) file.path(home,"project.rds") else path)
  if(!inherits(value,"funmel_project")) {
    if(!is_saved_analysis(value)) stop("Selected file is neither a FunMel project nor an analysis. Select project.rds.",call.=FALSE)
    value <- read_funmel_rds(file.path(home,"project.rds"))
  }
  if(!inherits(value,"funmel_project")) stop("project.rds does not contain a FunMel project.",call.=FALSE)
  old <- value$project_dir
  if(is.character(old) && length(old)==1L && !is.na(old) && nzchar(old)) {
    old <- sub("/+$","",gsub("\\\\","/",old))
    for(nm in c("image_root","metadata_file","qc_dir","result_file","reviewed_file")) {
      x <- value[[nm]]
      if(!is.character(x) || length(x)!=1L || is.na(x)) next
      x <- gsub("\\\\","/",x)
      if(identical(x,old)) value[[nm]] <- home else if(startsWith(x,paste0(old,"/")))
        value[[nm]] <- file.path(home,substring(x,nchar(old)+2L))
    }
  }
  value$project_dir <- home
  if(identical(basename(value$result_file),"reviewed_analysis.rds") &&
     file.exists(file.path(home,"image_analysis.rds"))) value$result_file <- file.path(home,"image_analysis.rds")
  value
}

#' Read saved experiment tables
#'
#' Projects store filenames, whereas saved analysis objects contain measurement
#' tables such as result$spots. No images are processed and no metadata is edited.
#' @param project Project object, current project folder, project.rds, or analysis RDS.
#' @param finalized TRUE reads finalized results from a project. FALSE prefers
#'   original measurements and falls back to finalized measurements if needed.
#'   An explicitly selected analysis RDS is read as supplied in either mode.
#' @return Saved batch result with colonies, plates, spots and metadata.
#' @examples
#' \dontrun{
#' project <- load_experiment()
#' result <- read_experiment(project)
#' head(result$spots)
#' }
#' @export
read_experiment <- function(project,finalized=FALSE) {
  if(!is.logical(finalized) || length(finalized)!=1L || is.na(finalized)) stop("finalized must be TRUE or FALSE.",call.=FALSE)
  if(is.character(project) && length(project)==1L && !is.na(project) && file.exists(project) && !dir.exists(project)) {
    x <- read_funmel_rds(project)
    if(is_saved_analysis(x)) return(x)
  }
  project <- as_funmel_project(project)
  paths <- if(finalized) project$reviewed_file else unique(c(project$result_file,project$reviewed_file))
  paths <- paths[!is.na(paths) & nzchar(paths) & file.exists(paths) & !dir.exists(paths)]
  if(!length(paths)) stop(if(finalized) "No finalized analysis found. Run finish_experiment(project)." else
    "No saved image measurements found. Run run_experiment(project), or use load_experiment() to open the completed project folder.",call.=FALSE)
  x <- read_funmel_rds(paths[1L])
  if(!is_saved_analysis(x)) stop("Saved file does not contain FunMel measurement tables: ",paths[1L],call.=FALSE)
  x
}
read_funmel_rds <- function(path) {
  if(!is.character(path) || length(path)!=1L || is.na(path) || !file.exists(path) || dir.exists(path))
    stop("Saved file is missing: ",paste(path,collapse="; "),". Open the current complete project folder with load_experiment(); do not recreate experimental assignments.",call.=FALSE)
  tryCatch(readRDS(path),error=function(e) stop("Cannot read saved file ",path,": ",conditionMessage(e),call.=FALSE))
}
is_saved_analysis <- function(x) is.list(x) && !inherits(x,"funmel_project") && is.data.frame(x$colonies) && is.data.frame(x$plates)
