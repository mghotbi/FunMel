#' Describe the inoculation layout of a plate
#'
#' FunMel uses the *known* inoculation geometry as a spatial prior. This
#' is what makes it possible to separate several cultures that share one
#' dish, including colonies that touch each other or grow into the halo of
#' the central bacterium.
#'
#' @details
#' Positions are given relative to the dish centre in units of the dish
#' outer radius, with x increasing to the right and **y increasing
#' downwards** (image convention). The default reproduces the standard
#' four-quadrant design: four fungal colonies on the diagonals at 45 % of the
#' radius (TL = top-left, TR, BR, BL) and, for confrontations, a bacterium
#' in the centre.
#'
#' Always photograph plates in the same orientation (e.g. a mark on the dish
#' rim at 12 o'clock) so that colony IDs are reproducible; otherwise use
#' `rotation_deg`.
#'
#' @param n_colonies Number of fungal inoculation points placed evenly on a
#'   circle (ignored if `positions` is given).
#' @param radius_frac Distance of the inoculation points from the dish
#'   centre, as a fraction of the outer dish radius.
#' @param radius_mm Alternatively, the distance in mm (overrides
#'   `radius_frac` once the dish scale is known).
#' @param start_deg Angle of the first colony, degrees clockwise from
#'   3 o'clock. The default -135 puts the first colony at top-left.
#' @param rotation_deg Extra clockwise rotation of the whole layout.
#' @param centre What is inoculated at the centre: `"bacteria"`, `"none"`
#'   or `"fungus"`. The fungal path fits separate peripheral-target, central-
#'   partner and surrounding-zone components; it never adds the central
#'   partner to the four target colonies. Halo masks are image candidates.
#' @param ids Colony identifiers.
#' @param positions Optional data frame with columns `id`, `x_rel`, `y_rel`
#'   for arbitrary designs.
#' @param search_frac Radius (fraction of the dish radius) around each
#'   expected position within which the colony core is searched. Colonies
#'   are matched to expected positions closest-first, one colony per
#'   position, so search areas may overlap; inoculation points only need to
#'   be approximately where the layout says.
#'
#' @return An object of class `funmel_layout`.
#'
#' @examples
#' plate_layout()                      # 4 Zymoseptoria + central bacterium
#' plate_layout(centre = "none")       # control plate
#' plate_layout(n_colonies = 3, ids = c("A", "B", "C"))
#' @export
plate_layout <- function(n_colonies = 4L, radius_frac = 0.45, radius_mm = NULL,
                         start_deg = -135, rotation_deg = 0,
                         centre = c("bacteria", "none", "fungus"),
                         ids = NULL, positions = NULL, search_frac = 0.4) {
  centre <- match.arg(centre)
  scalar <- function(x) is.numeric(x) && length(x)==1L && is.finite(x)
  if(!scalar(n_colonies) || n_colonies<1 || n_colonies!=as.integer(n_colonies)) stop("n_colonies must be a positive integer.")
  if(!scalar(radius_frac) || radius_frac<0 || radius_frac>1) stop("radius_frac must be between 0 and 1.")
  if(!is.null(radius_mm) && (!scalar(radius_mm) || radius_mm<=0)) stop("radius_mm must be positive.")
  if(!scalar(start_deg) || !scalar(rotation_deg)) stop("Angles must be finite numeric scalars.")
  if(!scalar(search_frac) || search_frac<=0) stop("search_frac must be positive.")
  if(is.null(positions) && !is.null(ids) && length(ids)!=n_colonies) stop("ids must have one value per colony.")
  if (is.null(positions)) {
    ang <- (start_deg + rotation_deg + (seq_len(n_colonies) - 1) * 360 / n_colonies) * pi / 180
    if (is.null(ids)) {
      ids <- if (n_colonies == 4L && start_deg == -135) c("TL", "TR", "BR", "BL")
             else sprintf("C%d", seq_len(n_colonies))
    }
    positions <- data.frame(id = ids, x_rel = radius_frac * cos(ang),
                            y_rel = radius_frac * sin(ang), stringsAsFactors = FALSE)
  } else {
    stopifnot(all(c("id", "x_rel", "y_rel") %in% names(positions)))
    positions <- as.data.frame(positions)
    if (rotation_deg != 0) {
      a <- rotation_deg * pi / 180
      xr <- positions$x_rel * cos(a) - positions$y_rel * sin(a)
      yr <- positions$x_rel * sin(a) + positions$y_rel * cos(a)
      positions$x_rel <- xr; positions$y_rel <- yr
    }
  }
  if(!nrow(positions) || anyNA(positions$id) || any(!nzchar(trimws(as.character(positions$id)))) ||
     anyDuplicated(as.character(positions$id))) stop("Position IDs must be nonempty and unique.")
  if(!is.numeric(positions$x_rel) || !is.numeric(positions$y_rel) ||
     any(!is.finite(positions$x_rel)) || any(!is.finite(positions$y_rel)) ||
     any(positions$x_rel^2+positions$y_rel^2>1+1e-8)) stop("Expected positions must be finite numeric coordinates within the dish radius.")
  if(anyDuplicated(positions[c("x_rel","y_rel")])) stop("Expected inoculation positions must be distinct.")
  structure(list(positions = positions, centre = centre, radius_mm = radius_mm,
                 search_frac = search_frac),
            class = "funmel_layout")
}

#' @rdname print_funmel
#' @method print funmel_layout
#' @export
print.funmel_layout <- function(x, ...) {
  cli::cli_text("{.strong <funmel_layout>} {nrow(x$positions)} fungal colonies; centre: {x$centre}")
  print(x$positions, row.names = FALSE, digits = 3)
  invisible(x)
}

#' Expected colony positions in working-image pixels
#' @keywords internal
#' @noRd
layout_pixels <- function(layout, dish) {
  pos <- layout$positions
  scale <- rep(1, nrow(pos))
  if (!is.null(layout$radius_mm)) {
    rf <- sqrt(pos$x_rel^2 + pos$y_rel^2)
    target <- (layout$radius_mm / dish$mm_per_px) / dish$r_outer
    scale <- ifelse(rf > 0, target / rf, 1)
  }
  data.frame(id = pos$id,
             x = dish$x + pos$x_rel * scale * dish$r_outer,
             y = dish$y + pos$y_rel * scale * dish$r_outer,
             stringsAsFactors = FALSE)
}
