#' FunMel: plate-image measurements and matched-control assessment
#'
#' FunMel retains the layout-based image workflow originally developed as
#' MycoHalo. It measures four expected Zymoseptoria colonies using their detected
#' boundaries, CIELAB colour, shape and edge-to-centre profiles. It does not
#' identify organisms from photographs. Central-model class labels require
#' biological interpretation and quality-control review.
#'
#' Metadata links each independent plate to its own control set. Use
#' [validate_metadata()], [analyze_plates()], [melanization_coefficient()] and
#' [assess_experiment()] in sequence. The mixed model uses lme4 with lmerTest
#' Satterthwaite contrasts; descriptions remain available when inference is
#' unsupported. See vignette('FunMel') and [example_experiment()].
#'
#' @keywords internal
#' @useDynLib FunMel, .registration = TRUE
#' @importFrom Rcpp sourceCpp
"_PACKAGE"
