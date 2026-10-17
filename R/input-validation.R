# Shared preflight validation for public image-analysis entry points.
validate_image_settings <- function(settings) {
  scalar <- function(x) is.numeric(x) && length(x)==1L && is.finite(x)
  for(nm in intersect(c("dish_diameter_mm","mm_per_px","spot_radius_mm"),names(settings))) {
    x <- settings[[nm]]
    if(nm=="mm_per_px" && is.null(x)) next
    if(!scalar(x) || x<=0)
      stop(nm," must be one finite positive number. Set the numeric value directly; for example, dish_diameter_mm=90 only for a verified 90-mm dish. Analysis has not started.",call.=FALSE)
  }
  if("max_dim" %in% names(settings)) {
    x <- settings$max_dim
    if(!is.numeric(x) || length(x)!=1L || is.na(x) || x<=0)
      stop("max_dim must be a positive number (Inf keeps native resolution). Analysis has not started.",call.=FALSE)
  }
  if("n_spots" %in% names(settings) && !is.null(settings$n_spots)) {
    x <- settings$n_spots
    if(!scalar(x) || x<1 || x!=floor(x)) stop("n_spots must be a positive integer or NULL. Analysis has not started.",call.=FALSE)
  }
  if("max_clipped_fraction" %in% names(settings)) {
    x <- settings$max_clipped_fraction
    if(!is.numeric(x) || length(x)!=1L || is.na(x) || x<0)
      stop("max_clipped_fraction must be a single non-negative number (Inf never withholds the correction). Analysis has not started.",call.=FALSE)
  }
  invisible(NULL)
}
