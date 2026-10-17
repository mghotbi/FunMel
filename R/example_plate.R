#' Paths to the example plate photographs shipped with FunMel
#'
#' Two representative original photographs from the bundled eight-image
#' 14-day dataset (four target colonies per dish):
#' \describe{
#'   \item{`"confrontation"`}{four colonies around a central interacting fungus with
#'     spreading hyphal growth (2026_10_02_99_38.JPG).}
#'   \item{`"control"`}{four colonies without an interacting partner
#'     (2026_10_02_99_41.JPG).}
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
  f <- c(confrontation = "14-days/A60_2_14_days/2026_10_02_99_38.JPG",
         control = "14-days/A60_2_14_days/2026_10_02_99_41.JPG")
  if (type != "all") f <- f[type]
  p <- vapply(f, function(x) system.file("extdata", x, package = "FunMel"), "")
  if (any(!nzchar(p))) cli::cli_abort("Example image not found; reinstall FunMel.")
  p
}
