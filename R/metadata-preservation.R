#' Standard metadata columns and lossless result annotation
#' @keywords internal
#' @noRd
complete_metadata_columns <- function(metadata) {
  if(!is.data.frame(metadata) || anyDuplicated(names(metadata))) stop("Metadata must be a data frame with unique column names.")
  defaults <- list(fungus=NA_character_,zymo_strain=NA_character_,medium=NA_character_,
    day=NA_real_,replicate=NA_integer_,photo_date=NA_character_,notes=NA_character_,
    qc_pass=FALSE)
  for(nm in setdiff(names(defaults),names(metadata))) metadata[[nm]] <- rep(defaults[[nm]],nrow(metadata))
  standard <- c("file","relative_file","plate_id","set_id","treatment","centre_model",
    "partner_type","fungus","zymo_strain","medium","day","replicate","photo_date",
    "notes","qc_pass")
  metadata[c(intersect(standard,names(metadata)),setdiff(names(metadata),standard))]
}

#' Context columns containing any recorded information
#' @keywords internal
#' @noRd
recorded_context_columns <- function(metadata) {
  cols <- intersect(c("zymo_strain","medium","day"),names(metadata))
  cols[vapply(metadata[cols],function(x) any(!is.na(x) & nzchar(trimws(as.character(x)))),TRUE)]
}

#' Attach metadata without overwriting measured image values
#' @keywords internal
#' @noRd
attach_result_metadata <- function(result, metadata, initial=FALSE) {
  if(anyDuplicated(names(metadata))) stop("Metadata column names must be unique.")
  maps <- result$metadata_column_maps
  if(is.null(maps)) maps <- list()
  for(table in c("colonies","profiles","plates","spots")) {
    df <- result[[table]]
    if(is.null(df) || !"plate_id" %in% names(df)) next
    idx <- match(df$plate_id,metadata$plate_id)
    if(anyNA(idx)) stop("A result plate has no metadata row.")
    map <- maps[[table]]
    if(is.null(map)) map <- stats::setNames(character(),character())
    for(nm in setdiff(names(metadata),"plate_id")) {
      target <- unname(map[nm])
      if(!length(target) || is.na(target)) {
        target <- nm
        # Saved results without maps may already contain experimental fields.
        # Preserve those names while protecting technical measurement columns.
        legacy_metadata <- !initial && is.null(result$metadata_column_maps) &&
          !grepl("^(MI_|L_|a_mean$|b_mean$|chroma_|hue_|area_|centroid_|n_pixels$|detected$|is_target$|colony_id$|ring$|file$)",nm)
        if(target %in% names(df) && !legacy_metadata) {
          target <- paste0("metadata_",nm)
          while(target %in% c(names(df),names(metadata),unname(map))) target <- paste0("metadata_",target)
        }
        map[nm] <- target
      }
      df[[target]] <- metadata[[nm]][idx]
    }
    result[[table]] <- df
    maps[[table]] <- map
  }
  result$metadata <- metadata
  result$metadata_column_maps <- maps
  result
}
