#' Analyse one plate photograph
#'
#' Runs the complete FunMel pipeline: import, dish detection and scale,
#' optional colour calibration, flat-field correction, colour/texture pixel
#' classification, seeded colony separation, measurement and QC.
#'
#' @param path Image file or H x W x 3 sRGB array.
#' @param layout A [plate_layout()]. Use `plate_layout(centre = "none")` for
#'   control plates without a central partner.
#' @param id Plate identifier (default: file name).
#' @param dish_diameter_mm Outer diameter of the dish (mm); sets the scale.
#' @param agar_fraction Fraction of the dish radius that is analysed.
#' @param dish Optional manual dish circle `c(x, y, r)` in working pixels.
#' @param mm_per_px Optional known scale (mm per working-image pixel);
#'   overrides `dish_diameter_mm`.
#' @param reference Optional exposure / white-balance reference: a grey-card
#'   region `c(x, y, r)` in relative image coordinates, or `"agar"`; see
#'   [model_background()].
#' @param reference_lab Known CIELAB of the reference.
#' @param max_dim Working resolution (longest side, px).
#' @param flat_field Apply illumination correction (recommended).
#' @param classifier Optional supervised classifier ([train_classifier()]).
#' @param min_delta_e Minimum colour difference from agar for objects.
#' @param min_area_mm2,min_core_mm,morph_mm,edge_criterion Segmentation settings, see
#'   [segment_colonies()].
#' @param edge_exclude_mm,dark_L,n_boot,block_mm Measurement settings, see
#'   [measure_colonies()].
#' @param n_spots Optional spots per target colony; NULL keeps only whole-colony measurements.
#' @param spot_radius_mm Circular spot radius (mm); see [sample_colony_spots()].
#' @param ring_width_mm,profile_mode,n_rings Profile settings, see
#'   [colony_profiles()].
#' @param qc_file Optional path of a PNG quality-control figure.
#' @param keep_images Keep image arrays in the result (needed for
#'   [plot_qc()] later; set `FALSE` in large batches to save memory).
#' @param verbose Print progress.
#'
#' @return An object of class `funmel_result`, a list with
#'   \describe{
#'     \item{colonies}{One row per expected colony ([measure_colonies()]).}
#'     \item{spots}{Optional circular ROI measurements and locations; whole-colony MI stays unchanged.}
#'     \item{profiles}{Edge-to-centre profiles ([colony_profiles()]).}
#'     \item{plate_summary}{One row of plate-level measures and QC.}
#'     \item{plate}{The processed plate (images and masks) if
#'       `keep_images = TRUE`.}
#'     \item{params, warnings}{Settings used and QC warnings.}
#'   }
#'
#' @examples
#' sim <- simulate_plate(width = 300, height = 400, seed = 10)
#' res <- analyze_plate(sim$image, id = "sim10", verbose = FALSE)
#' res
#' res$colonies[, c("colony_id", "MI_mean", "delta_MI_facing")]
#' \dontrun{
#' res <- analyze_plate("plates/2026_05_26_20.JPG", layout = plate_layout())
#' plot_qc(res)
#' ctrl <- analyze_plate("plates/2026_05_26_37.JPG",
#'                       layout = plate_layout(centre = "none"))
#' }
#' @export
analyze_plate <- function(path, layout = plate_layout(), id = NULL,
                          dish_diameter_mm = 90, agar_fraction = 0.88, dish = NULL,
                          mm_per_px = NULL,
                          reference = NULL, reference_lab = c(50, 0, 0),
                          max_dim = 2000, flat_field = TRUE, classifier = NULL,
                          min_delta_e = 3, min_area_mm2 = 0.5, min_core_mm = 0.4,
                          morph_mm = 0.08, edge_criterion = 0.5, edge_exclude_mm = 0.1, dark_L = NULL,
                          n_boot = 200L, block_mm = 0.5, ring_width_mm = 0.5,
                          profile_mode = c("absolute", "relative"), n_rings = 10L,
                          qc_file = NULL, keep_images = TRUE, verbose = TRUE,
                          n_spots = NULL, spot_radius_mm = 0.5) {
  profile_mode <- match.arg(profile_mode)
  stopifnot(inherits(layout, "funmel_layout"))
  params <- as.list(environment())
  params$path <- if (is.character(path)) path else "<array>"
  params$layout <- layout
  step <- function(msg) if (verbose) cli::cli_alert_info(msg)
  warn <- character()

  step("Reading image")
  plate <- read_plate(path, max_dim = max_dim, id = id)
  step("Detecting dish")
  plate <- detect_plate(plate, dish = dish, dish_diameter_mm = dish_diameter_mm,
                        agar_fraction = agar_fraction, mm_per_px = mm_per_px)
  step(sprintf("Dish r = %.0f px, %.4f mm/px", plate$dish$r_outer, plate$dish$mm_per_px))
  step("Modelling agar background and illumination")
  plate <- model_background(plate, flat_field = flat_field, min_delta_e = min_delta_e,
                            reference = reference, reference_lab = reference_lab)
  step("Classifying target colonies, central core and hyphal growth")
  plate <- classify_pixels(plate, layout, classifier = classifier)
  step("Separating colonies")
  plate <- segment_colonies(plate, layout, min_area_mm2 = min_area_mm2,
                            min_core_mm = min_core_mm, morph_mm = morph_mm,
                            edge_criterion = edge_criterion)
  step("Measuring")
  col <- measure_colonies(plate, edge_exclude_mm = edge_exclude_mm, dark_L = dark_L,
                          n_boot = n_boot, block_mm = block_mm)
  prof <- colony_profiles(plate, ring_width_mm = ring_width_mm, mode = profile_mode,
                          n_rings = n_rings, n_boot = n_boot, block_mm = block_mm)
  spot_result <- if(is.null(n_spots)) NULL else sample_colony_spots(plate,
    n_spots=n_spots,spot_radius_mm=spot_radius_mm,edge_exclude_mm=edge_exclude_mm)
  if(!is.null(spot_result)) {
    summary <- spot_result$summary[match(col$colony_id,spot_result$summary$colony_id),,drop=FALSE]
    col <- cbind(col,summary[setdiff(names(summary),"colony_id")])
  }
  ps <- measure_plate(plate)

  # ---- QC warnings
  if (any(!col$detected)) warn <- c(warn, sprintf("Colony not detected: %s", paste(col$colony_id[!col$detected], collapse = ", ")))
  if (!is.na(plate$dish$arc_coverage) && plate$dish$arc_coverage < 0.4)
    warn <- c(warn, "Dish edge visible on < 40 % of its circumference; check the scale.")
  if (isTRUE(ps$illumination_range_pct > 30))
    warn <- c(warn, sprintf("Fitted pre-correction illumination range %.0f %% (not residual error); inspect correction diagnostics and QC.", ps$illumination_range_pct))
  if (isTRUE(ps$flat_field_clipped_fraction > 0.01))
    warn <- c(warn, "Flat-field gains reached correction limits for > 1 % of dish pixels; inspect masks and calibration.")
  if (isTRUE(ps$residual_agar_range_pct > 30))
    warn <- c(warn, "Remaining fitted-agar spatial variation exceeds 30 %; review illumination correction.")
  if(any(col$n_pixels<30 & col$detected,na.rm=TRUE))
    warn <- c(warn,"A target has fewer than 30 usable interior pixels; inspect resolution, mask and colour summary.")
  if (any(col$specular_fraction > 0.02, na.rm = TRUE))
    warn <- c(warn, "Colonies contain > 2 % specular / over-exposed pixels; reduce exposure or use diffuse light.")
  if (any(col$segmentation_trim_fraction > 0.1, na.rm=TRUE))
    warn <- c(warn, "A target-colony bridge to separate tissue was removed (> 10 % of its initial mask); inspect the refined boundary.")
  if (any(col$offset_from_expected_mm > 8, na.rm = TRUE))
    warn <- c(warn, "A colony centroid is > 8 mm from its expected position; check layout / orientation.")
  if (layout$centre %in% c("bacteria","fungus") && !isTRUE(ps$central_detected))
    warn <- c(warn, "No central partner region was resolved; inspect the central-object mask.")
  if(!is.null(spot_result) && any(spot_result$summary$spot_status!="ok"))
    warn <- c(warn,"Requested spots could not fit in every target colony; inspect spot_status. Reduce radius or count consistently across the experiment.")
  for (w in warn) cli::cli_warn(w)

  col$is_target <- col$colony_id %in% as.character(layout$positions$id)
  col <- cbind(plate_id = plate$id, col, stringsAsFactors = FALSE)
  if (nrow(prof)) prof <- cbind(plate_id = plate$id, prof, stringsAsFactors = FALSE)
  ps <- cbind(plate_id = plate$id, n_warnings = length(warn),
              warnings = paste(warn, collapse = " | "), ps, stringsAsFactors = FALSE)

  res <- structure(list(colonies = col, profiles = prof, spots = if(is.null(spot_result)) data.frame() else spot_result$spots, plate_summary = ps,
                        plate = plate, params = params, warnings = warn,
                        version = as.character(utils::packageVersion("FunMel"))),
                   class = "funmel_result")
  if (!is.null(qc_file)) {
    grDevices::png(qc_file, width = 2400, height = 1250, res = 150)
    on.exit(grDevices::dev.off(), add = TRUE)
    plot_qc(res)
  }
  if (!keep_images) res$plate <- NULL
  res
}

#' @rdname print_funmel
#' @method print funmel_result
#' @export
print.funmel_result <- function(x, ...) {
  cli::cli_text("{.strong <funmel_result>} plate {.val {x$plate_summary$plate_id}}")
  ps <- x$plate_summary
  cr <- if(!is.null(ps$central_radius_mm)) ps$central_radius_mm else ps$bacteria_radius_mm
  cli::cli_bullets(c(
    "*" = "Scale: {signif(ps$mm_per_px, 4)} mm/px; agar L* = {round(ps$agar_L, 1)}",
    "*" = "Colonies detected: {ps$n_colonies_detected} / {nrow(x$colonies)}; satellites: {ps$n_satellites}",
    "*" = if (!is.na(cr)) "Central fungal/partner extent: equivalent r = {round(cr, 2)} mm" else "No central object class"
  ))
  cols <- intersect(c("colony_id", "area_mm2", "L_mean", "MI_mean", "MI_lo", "MI_hi",
                      "delta_MI_facing", "growth_inhibition_pct"), names(x$colonies))
  print(format(x$colonies[, cols], digits = 3), row.names = FALSE)
  if (length(x$warnings)) cli::cli_alert_warning("{length(x$warnings)} QC warning{?s}: {x$warnings}")
  invisible(x)
}

#' Analyse many plates
#'
#' Batch wrapper around [analyze_plate()] that never stops on a single bad
#' image: failures are recorded and reported. A QC figure is written for
#' every plate — inspect them before using the numbers.
#'
#' @param files Character vector of image paths, or a directory (all
#'   JPEG/PNG/TIFF files are used).
#' @param metadata Optional design data frame. When supplied, file, plate_id,
#'   set_id and treatment are required and validated by [validate_metadata()].
#'   Extra design columns are merged into the output tables.
#' @param layout A single [plate_layout()], or a function
#'   `function(metadata_row)` returning the layout for each plate (e.g.
#'   `centre = "none"` for controls).
#' @param qc_dir Directory for QC PNGs (created if needed). The default
#'   `NULL` writes nothing; give a folder, e.g. `qc_dir = "qc"`, to save one
#'   QC figure per plate.
#' @param ... Further arguments passed to [analyze_plate()].
#' @param coefficient_control Control treatment label for automatic coefficient
#'   calculation; NULL disables it. Calculated when treatment metadata exists.
#' @param coefficient_by Matching columns for controls, e.g. strain and day.
#' @param verbose Print progress.
#'
#' @return A list of three data frames (`colonies`, `profiles`, `plates`)
#'   and a `failed` data frame. Also contains `melanization_coefficient`
#'   (coefficient table), `coefficient_plate_means` and `coefficient_error`.
#'   Coefficient errors preserve image results but must be resolved before use.
#' @examples
#' \dontrun{
#' meta <- data.frame(file = c("2026_05_26_20.JPG", "2026_05_26_37.JPG"),
#'                    plate_id = c("t1", "c1"), set_id = "set1",
#'                    treatment = c("bacteria", "control"))
#' lay <- function(row) plate_layout(centre = if (row$treatment == "control") "none" else "bacteria")
#' out <- analyze_plates("plates/", metadata = meta, layout = lay, qc_dir = "qc/")
#' write.csv(out$colonies, "colonies.csv", row.names = FALSE)
#' }
#' @export
analyze_plates <- function(files, metadata = NULL, layout = plate_layout(),
                           qc_dir = NULL, ..., verbose = TRUE,
                           coefficient_control = "control", coefficient_by = NULL) {
  if(!is.character(files) || anyNA(files) || any(!nzchar(files))) stop("files must be image paths without missing values.")
  if (length(files) == 1 && dir.exists(files)) {
    files <- list.files(files, pattern = "\\.(jpe?g|png|tiff?|heic)$",
                        ignore.case = TRUE, full.names = TRUE)
  }
  if (!length(files)) cli::cli_abort("No image files found.")
  missing<-files[!file.exists(files) | dir.exists(files)]
  if(length(missing)) stop("Image paths missing or not files (",length(missing),"): ",
    paste(utils::head(missing,5L),collapse="; "),". Analysis has not started. Check extraction and use prepare_photo_archive() for ZIP files.")
  if (is.null(metadata) && anyDuplicated(tools::file_path_sans_ext(basename(files))))
    stop("Image basenames must be unique; duplicate names would overwrite plate results.")
  if (!is.null(metadata)) validate_metadata(metadata,files=files,
    control=if(is.null(coefficient_control)) "control" else coefficient_control)
  metadata_index <- if(is.null(metadata)) NULL else match_image_rows(files,metadata)
  if (!is.null(qc_dir)) dir.create(qc_dir, showWarnings = FALSE, recursive = TRUE)
  out_c <- list(); out_p <- list(); out_s <- list(); out_spots <- list(); failed <- list()
  for (k in seq_along(files)) {
    f <- files[k]
    pid <- tools::file_path_sans_ext(basename(f))
    mrow <- NULL
    if (!is.null(metadata)) mrow <- metadata[metadata_index[k],,drop=FALSE]
    if (!is.null(metadata) && (is.null(mrow) || nrow(mrow)!=1L))
      stop("Exactly one metadata row must match each image: ",basename(f))
    if (!is.null(mrow)) pid <- as.character(mrow$plate_id[1])
    lay <- if (is.function(layout)) layout(mrow) else layout
    if (verbose) cli::cli_alert("[{k}/{length(files)}] {basename(f)}")
    qc <- if (is.null(qc_dir)) NULL else file.path(qc_dir, paste0(pid, "_qc.png"))
    r <- tryCatch(analyze_plate(f, layout = lay, id = pid, qc_file = qc,
                                keep_images = FALSE, verbose = FALSE, ...),
                  error = function(e) e)
    if (inherits(r, "error")) {
      failed[[length(failed) + 1]] <- data.frame(file = f, error = conditionMessage(r))
      if (verbose) cli::cli_alert_danger(conditionMessage(r))
      next
    }
    out_spots[[pid]] <- r$spots
    out_c[[pid]] <- r$colonies
    out_p[[pid]] <- r$profiles
    out_s[[pid]] <- cbind(r$plate_summary, file=f)

  }
  result <- list(colonies = bind_rows_fill(out_c), profiles = bind_rows_fill(out_p),
       spots = bind_rows_fill(out_spots),
       plates = bind_rows_fill(out_s),
       failed = if (length(failed)) do.call(rbind, failed) else data.frame(file = character(), error = character()))
  if(!nrow(result$colonies)) result$colonies<-data.frame(plate_id=character(),colony_id=character(),MI_mean=double(),detected=logical())
  if(!nrow(result$profiles)) result$profiles<-data.frame(plate_id=character(),colony_id=character(),ring=integer(),MI_mean=double())
  if(!nrow(result$plates)) result$plates<-data.frame(plate_id=character(),n_colonies_detected=integer(),central_detected=logical(),hyphae_status=character())
  result$melanization_coefficient <- data.frame(set_id=character(),treatment=character(),control=character(),
    MI_treatment_mean=double(),MI_control_mean=double(),melanization_coefficient=double(),
    n_treatment_plates=integer(),n_control_plates=integer(),status=character())
  result$coefficient_plate_means <- data.frame(plate_id=character(),treatment=character(),set_id=character(),MI_plate=double())
  result$per_plate_coefficients <- data.frame(plate_id=character(),treatment=character(),set_id=character(),
    MI_treatment_plate=double(),MI_matching_control=double(),melanization_coefficient=double(),status=character())
  result$coefficient_error <- if(!nrow(result$plates)) "No plates completed; inspect failed results before assessment." else NULL
  if(!is.null(metadata)) result <- attach_result_metadata(result,metadata,initial=TRUE)
  if (!is.null(coefficient_control) && "treatment" %in% names(result$colonies)) {
    if (nrow(result$failed)) {
      result$coefficient_error <- "Some plates failed analysis; automatic coefficient withheld. Inspect failed plates before choosing a complete subset."
    } else {
      mc <- tryCatch(melanization_coefficient(result$colonies, control=coefficient_control,
                                               by=coefficient_by),error=function(e)e)
      if (inherits(mc,"error")) result$coefficient_error <- conditionMessage(mc) else {
        result$melanization_coefficient <- mc$coefficients
        result$coefficient_plate_means <- mc$plate_means
        result$per_plate_coefficients <- mc$per_plate_coefficients
      }
    }
    if (!is.null(result$coefficient_error)) warning("Coefficient not calculated: ",result$coefficient_error)
  }
  result
}
