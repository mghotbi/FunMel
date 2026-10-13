#' Extract and locate the photographs required by metadata
#'
#' Checks a selected ZIP before extraction, ignores Mac resource-fork files,
#' resolves extra enclosing folders and requires exactly one path per expected
#' photograph. Existing extraction folders are not used as evidence that this
#' ZIP contains an image. Missing/ambiguous files stop before image analysis.
#' @param photo_zip Path to the original ZIP of plate photographs.
#' @param metadata Data frame containing file and optionally relative_file.
#'   relative_file helps distinguish duplicate basenames in nested folders.
#' @param photo_root Parent directory for a fresh extraction subfolder.
#' @return Character vector of existing absolute image paths, in metadata order.
#' @export
prepare_photo_archive <- function(photo_zip, metadata, photo_root) {
  if(!is.character(photo_zip) || length(photo_zip)!=1L || is.na(photo_zip) || !file.exists(photo_zip)) stop("Choose an existing photo ZIP.")
  if(!is.data.frame(metadata) || !nrow(metadata) || !"file" %in% names(metadata) || anyNA(metadata$file) || any(!nzchar(metadata$file))) stop("metadata must contain nonempty expected filenames.")
  listing <- tryCatch(utils::unzip(photo_zip,list=TRUE),error=function(e) NULL)
  if(is.null(listing) || !nrow(listing)) stop("Cannot read the selected ZIP.")
  entries <- listing$Name[grepl("\\.(jpe?g|png|tiff?)$",listing$Name,ignore.case=TRUE) &
                           !grepl("(^|/)__MACOSX/|(^|/)\\._",listing$Name)]
  if(!length(entries)) stop("The selected ZIP contains no plate photographs. Choose the original photograph ZIP, not a package or QC review ZIP.")
  expected <- as.character(metadata$file)
  missing <- expected[!tolower(expected) %in% tolower(basename(entries))]
  if(length(missing)) stop("The selected ZIP is missing expected photographs:\n",paste(missing,collapse="\n"),"\nChoose the original photo archive. Analysis has not started.")
  if(any(grepl("(^|/)\\.\\.(/|$)|^/|^[A-Za-z]:",entries))) stop("ZIP contains invalid extraction paths.")
  dir.create(photo_root,recursive=TRUE,showWarnings=FALSE)
  dest <- tempfile("selected_archive_",tmpdir=normalizePath(photo_root))
  dir.create(dest)
  utils::unzip(photo_zip,files=entries,exdir=dest)
  available <- list.files(dest,recursive=TRUE,full.names=TRUE,pattern="\\.(jpe?g|png|tiff?)$",ignore.case=TRUE)
  resolved <- vapply(seq_along(expected),function(i) {
    matches <- available[tolower(basename(available))==tolower(expected[i])]
    if(length(matches)>1L && "relative_file" %in% names(metadata) &&
       !is.na(metadata$relative_file[i]) && nzchar(metadata$relative_file[i])) {
      wanted <- gsub("\\\\","/",metadata$relative_file[i])
      matches <- matches[endsWith(tolower(gsub("\\\\","/",matches)),tolower(paste0("/",wanted)))]
    }
    if(length(matches)!=1L) stop("Expected exactly one extracted photograph for ",expected[i],"; found ",length(matches),". Analysis has not started.")
    normalizePath(matches,mustWork=TRUE)
  },character(1))
  if(!all(file.exists(resolved))) stop("Some extracted images are missing; analysis has not started.")
  resolved
}

