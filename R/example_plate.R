#' Paths to the example plate photographs shipped with FunMel
#'
#' Two real photographs of *Zymoseptoria tritici* (four colonies per dish),
#' reduced to 1000 px for size:
#' \describe{
#'   \item{`"confrontation"`}{four colonies around a central interacting fungus with
#'     spreading growth (original: 2026_05_26_20.JPG).}
#'   \item{`"control"`}{four colonies without an interacting partner
#'     (original: 2026_05_26_37.JPG).}
#' }
#'
#' @param type `"confrontation"`, `"control"` or `"all"`.
#' @return File path(s).
#' @examples
#' example_plate("control")
#' \donttest{
#' res <- analyze_plate(example_plate("control"), layout = plate_layout(centre = "none"))
#' }
#' @export
example_plate <- function(type = c("confrontation", "control", "all")) {
  type <- match.arg(type)
  f <- c(confrontation = "zymo_confrontation.jpg", control = "zymo_control.jpg")
  if (type != "all") f <- f[type]
  p <- vapply(f, function(x) system.file("extdata", x, package = "FunMel"), "")
  if (any(!nzchar(p))) cli::cli_abort("Example image not found; reinstall FunMel.")
  p
}
