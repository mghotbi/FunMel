# Local segmentation is deliberately separate from measurement/calibration.
.fm_seed_outline <- function(L, seed, radius, polarity, min_contrast, fraction,
                             excluded = matrix(FALSE,nrow(L),ncol(L)),
                             boundary = "outer_extent") {
  H <- nrow(L); W <- ncol(L)
  x <- matrix(rep(seq_len(W),each=H),H,W)
  y <- matrix(rep(seq_len(H),W),H,W)
  distance <- sqrt((x-seed[1])^2+(y-seed[2])^2)
  ring <- distance >= .8*radius & distance <= radius & !excluded
  core <- distance <= max(2,.1*radius) & !excluded
  if(sum(ring)<30 || sum(core)<3) stop("Too little usable seed/background area; revise centre or radius.")
  background <- stats::median(L[ring])
  contrast <- stats::median(L[core])-background
  if(polarity=="auto") polarity <- if(contrast>=0) "bright" else "dark"
  sign <- if(polarity=="bright") 1 else -1
  contrast <- sign*contrast
  if(!is.finite(contrast) || contrast < min_contrast)
    stop("Insufficient seed-to-agar contrast; use a manual outline.")
  # A threshold proposal, not an asserted biological boundary.
  candidate <- sign*(L-background) >= max(min_contrast,fraction*contrast) &
    distance < .8*radius & !excluded
  labels <- label_components(candidate)
  at <- labels[round(seed[2]),round(seed[1])]
  if(boundary=="outer_extent") {
    # A closed peripheral rim can enclose a differently coloured target centre.
    # Geometry is proposed only: the reviewer must exclude agar/foreign tissue.
    candidates <- setdiff(unique(as.vector(labels)),0L)
    mask <- matrix(FALSE,H,W)
    best_area <- 0L
    for(k in candidates) {
      filled <- fill_holes(labels==k)
      if(filled[round(seed[2]),round(seed[1])] && sum(filled)>best_area) {
        mask <- filled; best_area <- sum(filled)
      }
    }
    if(!best_area) stop("No closed candidate encloses the seed; draw the whole target manually.")
  } else {
    if(at==0) stop("Clicked centre is outside the candidate; reclick inside tissue or draw manually.")
    mask <- fill_holes(labels==at)
  }
  if(sum(mask)<30) stop("Candidate contains fewer than 30 pixels; draw manually or increase resolution.")
  if(any(mask & (distance >= .8*radius-2)) ||
     any(mask[c(1,H),]) || any(mask[,c(1,W)]))
    stop("Candidate reaches its search boundary; revise radius or draw manually.")
  if(any(mask & excluded)) stop("Candidate contains an excluded region; use a reviewed manual outline.")
  curves <- grDevices::contourLines(x=seq_len(W),y=seq_len(H),z=t(mask*1),levels=.5)
  if(!length(curves)) stop("Could not form a closed outline.")
  q <- curves[[which.max(vapply(curves,function(z) length(z$x),integer(1)))]]
  list(polygon=cbind(x=q$x,y=q$y),polarity=polarity,
       background_L=background,seed_contrast_L=contrast)
}

#' Propose boundaries for difficult bright or dark colonies
#'
#' Click-guided, local lightness segmentation for the four peripheral targets.
#' This creates a proposal for visual review, not measurements or an automatic
#' exception to quality control. Use manual overrides when an edge is ambiguous.
#'
#' @param path Original photograph.
#' @param dish_diameter_mm Verified outer dish diameter in millimetres.
#' @param centre Central partner model, fungus or none.
#' @param dish Outer rim circle c(x,y,r) in working pixels; NULL requests three clicks.
#' @param seeds Four-row x/y matrix with row names TL, TR, BR, BL. NULL requests
#'   one click per target. Seeds are in the resized working image, not original pixels.
#' @param radius_px Search radius, one number or a named vector for all four targets.
#'   The outer 20 percent estimates local agar lightness. Default is 0.20 times
#'   the dish radius. Keep other colonies, rim and writing outside this region.
#' @param polarity One of auto, bright, dark, or a named vector for all targets.
#' @param min_contrast Minimum lightness difference from local agar, default 3.
#' @param fraction Fraction of seed contrast used as the threshold, between 0 and 1.
#' @param polygons Optional named manual overrides. A central_fungus outline is
#'   required for confrontations; if absent it is collected interactively.
#' @param exclusions List of x/y polygons marking artifacts. They are excluded
#'   from seed/background estimation and detection. This does not reconstruct
#'   hidden tissue or modify the photograph.
#' @param max_dim Maximum working-image dimension.
#' @param boundary outer_extent (default) proposes the outermost closed candidate
#'   enclosing the target seed, including its interior. seed_component uses only
#'   the connected candidate containing the seed. Both require visual review;
#'   use a manual outline for open rims, mixed organisms or uncertain boundaries.
#' @return A funmel_boundary_proposal containing polygons, image geometry and
#'   per-target detection diagnostics. Failed targets have no polygon and must
#'   be supplied manually. plot() displays outlines for review. No measurements
#'   are calculated. Use recover_funmel_plate() with the reviewed polygons.
#' @details
#' Local brightness is used only to propose geometry. The original photograph
#' is retained for measurement; existing explicit calibration settings still
#' apply when running recovery. Automatic mode chooses bright/dark from the
#' seed and surrounding agar; it does not establish biological identity.
#' The central fungus is outlined independently, including its visible fringe,
#' and is not inferred from the bright plug. Mask contact with the search limit
#' is rejected. A radius is a search window, never a forced circular boundary.
#' @export
suggest_funmel_polygons <- function(path,dish_diameter_mm,centre=c("fungus","none"),
    dish=NULL,seeds=NULL,radius_px=NULL,polarity="auto",min_contrast=3,fraction=.35,
    polygons=list(),exclusions=list(),max_dim=1200,
    boundary=c("outer_extent","seed_component")) {
  centre <- match.arg(centre)
  boundary <- match.arg(boundary)
  validate_image_settings(list(dish_diameter_mm=dish_diameter_mm,max_dim=max_dim))
  if(length(min_contrast)!=1L || !is.finite(min_contrast) || min_contrast<=0 ||
     length(fraction)!=1L || !is.finite(fraction) || fraction<=0 || fraction>=1)
    stop("min_contrast must be positive and fraction strictly between zero and one.")
  ids <- c("TL","TR","BR","BL")
  if(!is.list(polygons) || (length(polygons) &&
      (is.null(names(polygons)) || anyDuplicated(names(polygons)) ||
       any(!names(polygons) %in% c(ids,"central_fungus")))))
    stop("polygons must be named manual outlines for TL, TR, BR, BL or central_fungus.")
  p <- read_plate(path,max_dim=max_dim)
  dish <- .fm_collect_circle(p,dish)
  p <- detect_plate(p,dish=dish,dish_diameter_mm=dish_diameter_mm)
  expand <- function(z,name) {
    if(length(z)==1L) return(stats::setNames(rep(z,4),ids))
    if(length(z)!=4L || is.null(names(z)) || !setequal(names(z),ids))
      stop(name," needs one value or four values named TL, TR, BR, BL.")
    z[ids]
  }
  if(is.null(radius_px)) radius_px <- .2*p$dish$r_outer
  radius_px <- expand(radius_px,"radius_px")
  polarity <- expand(polarity,"polarity")
  if(!is.numeric(radius_px) || any(!is.finite(radius_px)|radius_px<8))
    stop("Search radii must be finite and at least eight pixels.")
  if(anyNA(polarity) || any(!polarity %in% c("auto","bright","dark")))
    stop("polarity must be auto, bright or dark.")
  H <- dim(p$rgb)[1]; W <- dim(p$rgb)[2]
  excluded <- !dish_masks(p)$agar
  for(z in exclusions) excluded <- excluded | .fm_polygon_mask(z,H,W)
  if(is.null(seeds)) {
    seeds <- matrix(NA_real_,4,2,dimnames=list(ids,c("x","y")))
    for(id in setdiff(ids,names(polygons))) {
      if(!interactive()) stop("Supply seeds for noninteractive proposals.")
      .fm_show(p,paste("Click inside",id,"colony"))
      q <- graphics::locator(n=1,type="p",pch=3,col="cyan")
      if(is.null(q)) stop("Centre selection cancelled.")
      seeds[id,] <- c(q$x,q$y)
    }
  }
  seeds <- as.matrix(seeds)
  if(!is.numeric(seeds) || !identical(dim(seeds),c(4L,2L)) ||
      is.null(rownames(seeds)) || !setequal(rownames(seeds),ids))
    stop("seeds must be a four-row x/y matrix named TL, TR, BR, BL.")
  seeds <- seeds[ids,,drop=FALSE]
  diagnostics <- list()
  L <- p$lab[,,1]
  for(id in ids) {
    if(id %in% names(polygons)) {
      diagnostics[[id]] <- data.frame(colony_id=id,method="manual_override",
        polarity=NA_character_,background_L=NA_real_,seed_contrast_L=NA_real_,status="review_required")
      next
    }
    seed <- seeds[id,]
    result <- tryCatch({
      if(any(!is.finite(seed)) || seed[1]<1 || seed[1]>W || seed[2]<1 || seed[2]>H)
        stop("Seed must lie inside the working image.")
      if(excluded[round(seed[2]),round(seed[1])]) stop("Seed lies in an excluded region.")
      .fm_seed_outline(L,seed,radius_px[id],polarity[id],min_contrast,fraction,excluded,boundary)
    },error=function(e) e)
    failed <- inherits(result,"error")
    if(!failed) polygons[[id]] <- result$polygon
    diagnostics[[id]] <- data.frame(colony_id=id,method="seeded_lightness",
      polarity=if(failed) polarity[id] else result$polarity,
      background_L=if(failed) NA_real_ else result$background_L,
      seed_contrast_L=if(failed) NA_real_ else result$seed_contrast_L,
      status=if(failed) conditionMessage(result) else "review_required")
  }
  if(centre=="fungus" && is.null(polygons$central_fungus) && interactive())
    polygons$central_fungus <- .fm_click_polygon(p,"Outline whole central fungus including visible fringe")
  guidance <- list(method="seeded_lightness",seeds=seeds,radius_px=radius_px,
    polarity=polarity,boundary=boundary,min_contrast=min_contrast,fraction=fraction,exclusions=exclusions,
    diagnostics=do.call(rbind,diagnostics),proposed_polygons=polygons,
    image_md5=unname(as.character(tools::md5sum(path))),max_dim=max_dim,
    working_dim=dim(p$rgb)[1:2],dish_diameter_mm=dish_diameter_mm,
    centre=centre,dish=unname(dish))
  attr(polygons,"guidance") <- guidance
  structure(list(polygons=polygons,guidance=guidance,path=path,dish=unname(dish),
    dish_diameter_mm=dish_diameter_mm,centre=centre,max_dim=max_dim,
    image_md5=unname(as.character(tools::md5sum(path))),plate=p),class="funmel_boundary_proposal")
}

#' @rdname suggest_funmel_polygons
#' @param x Boundary proposal to display.
#' @param ... Reserved for plotting extensions.
#' @export
plot.funmel_boundary_proposal <- function(x,...) {
  .fm_show(x$plate,"PROPOSED outlines: review each edge before recovery")
  for(id in names(x$polygons)) {
    xy <- x$polygons[[id]]
    graphics::lines(rbind(xy,xy[1,]),col=if(id=="central_fungus") "orange" else "cyan",lwd=2)
    graphics::text(mean(xy[,1]),mean(xy[,2]),id,col="white")
  }
  for(xy in x$guidance$exclusions)
    graphics::lines(rbind(xy,xy[1,]),col="red",lty=2)
  invisible(x)
}
