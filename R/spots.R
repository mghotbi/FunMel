#' Sample a chosen number of circular spots within each target colony
#'
#' Whole-colony MI uses all eligible interior pixels. This optional measurement
#' instead samples non-overlapping circular ROIs distributed by a deterministic
#' farthest-point algorithm. The first centre is nearest the eligible-region
#' centroid; later centres maximize separation. This is a reproducible spatial
#' sample, not random sampling or a claim that it represents the entire colony.
#' Placement is greedy, with at most 20,000 candidate centres; a shortage
#' does not prove that an alternative geometric packing is impossible.
#' ROIs lie entirely within the edge-excluded, non-specular target mask.
#' Min/max are observed pixel extremes, not confidence limits. All spots are
#' subsamples of the colony and plate, never independent biological replicates.
#'
#' @param result A funmel_result with images kept, or a segmented funmel_plate.
#' @param n_spots Positive integer number of spots requested per target colony.
#' @param spot_radius_mm Radius of each circular ROI, in mm.
#' @param edge_exclude_mm Excluded target-colony rim, in mm.
#' @return A list with spots (one row per achieved ROI) and summary (one row
#'   per expected colony). If the requested ROIs cannot fit, status is
#'   insufficient_space and summary MI_spot_mean/min/max are NA. Achieved ROIs
#'   remain available for inspection. No rim fallback or overlapping ROI is used.
#' @examples
#' sim <- simulate_plate(width = 300, height = 400, seed = 7)
#' res <- analyze_plate(sim$image, n_spots = 3, spot_radius_mm = 0.3,
#'                      n_boot = 20, verbose = FALSE)
#' res$spots
#' @export
sample_colony_spots <- function(result, n_spots = 5L, spot_radius_mm = 0.5,
                                edge_exclude_mm = 0.1) {
  if (!is.numeric(n_spots) || length(n_spots)!=1L || !is.finite(n_spots) ||
      n_spots < 1 || n_spots != floor(n_spots)) stop("n_spots must be a positive integer.")
  scalar <- function(x) is.numeric(x) && length(x)==1L && is.finite(x)
  if (!scalar(spot_radius_mm) || spot_radius_mm<=0) stop("spot_radius_mm must be positive.")
  if (!scalar(edge_exclude_mm) || edge_exclude_mm<0) stop("edge_exclude_mm must be nonnegative.")
  p <- if(inherits(result,"funmel_result")) result$plate else result
  if(is.null(p) || !is_funmel_plate(p) || is.null(p$objects))
    stop("Keep images (keep_images=TRUE) or supply a segmented plate.")
  mm <- p$dish$mm_per_px; rp <- spot_radius_mm/mm
  if(rp < 1) stop("spot_radius_mm must span at least one working-image pixel; increase max_dim or spot radius.")
  L <- p$lab[,,1]; rgb <- p$rgb
  spec <- L>97 | rgb[,,1]>=254.5/255 | rgb[,,2]>=254.5/255 | rgb[,,3]>=254.5/255
  ct <- p$objects$colony_table; xy <- dish_masks(p)
  spot_rows <- list(); summaries <- list()
  for(i in seq_len(nrow(ct))) {
    cm <- p$objects$labels==i
    eligible <- cm & edt_local(cm)*mm>edge_exclude_mm & !spec
    # Distance to any excluded pixel protects the full circular ROI.
    candidates <- which(eligible & edt_local(eligible)>rp)
    achieved <- list(); chosen <- integer()
    if(isTRUE(ct$detected[i]) && length(candidates)) {
      # A fixed maximum bounds memory and runtime without RNG side effects.
      if(length(candidates)>20000L) candidates <- candidates[unique(round(seq(1,length(candidates),length.out=20000L)))]
      cx <- xy$x[candidates]; cy <- xy$y[candidates]
      score <- -((cx-mean(cx))^2+(cy-mean(cy))^2)
      available <- rep(TRUE,length(candidates)); nearest <- rep(Inf,length(candidates))
      for(k in seq_len(n_spots)) {
        if(!any(available)) break
        score[!available] <- -Inf; j <- which.max(score)
        ix <- candidates[j]; chosen <- c(chosen,ix)
        x0 <- xy$x[ix]; y0 <- xy$y[ix]
        # Bound the disk locally instead of allocating a whole-image ROI.
        xr <- seq.int(max(1,ceiling(x0-rp)),min(ncol(L),floor(x0+rp)))
        yr <- seq.int(max(1,ceiling(y0-rp)),min(nrow(L),floor(y0+rp)))
        g <- expand.grid(y=yr,x=xr)
        g <- g[(g$x-x0)^2+(g$y-y0)^2<=rp^2,,drop=FALSE]
        ind <- g$y+(g$x-1L)*nrow(L)
        if(!length(ind) || !all(eligible[ind])) stop("Internal ROI eligibility check failed.")
        mi <- 100-L[ind]
        achieved[[k]] <- data.frame(plate_id=p$id,colony_id=ct$id[i],spot_id=k,
          x_px=x0,y_px=y0,spot_radius_mm=spot_radius_mm,n_pixels=length(ind),
          MI_mean=mean(mi),MI_min=min(mi),MI_max=max(mi),L_mean=mean(L[ind]),
          stringsAsFactors=FALSE)
        dsq <- (cx-x0)^2+(cy-y0)^2
        nearest <- pmin(nearest,dsq)
        available <- available & dsq>(2*rp)^2
        score <- nearest
      }
    }
    status <- if(!isTRUE(ct$detected[i])) "not_detected" else if(length(achieved)<n_spots) "insufficient_space" else "ok"
    z <- bind_rows_fill(achieved)
    summaries[[i]] <- data.frame(colony_id=ct$id[i],n_spots_requested=as.integer(n_spots),
      n_spots_measured=nrow(z),spot_radius_mm=spot_radius_mm,spot_status=status,
      MI_spot_mean=if(status=="ok") mean(z$MI_mean) else NA_real_,
      MI_spot_min=if(status=="ok") min(z$MI_mean) else NA_real_,
      MI_spot_max=if(status=="ok") max(z$MI_mean) else NA_real_,stringsAsFactors=FALSE)
    spot_rows[[i]] <- z
  }
  spots <- bind_rows_fill(spot_rows)
  if(!nrow(spots)) spots <- data.frame(plate_id=character(),colony_id=character(),spot_id=integer(),
    x_px=double(),y_px=double(),spot_radius_mm=double(),n_pixels=integer(),
    MI_mean=double(),MI_min=double(),MI_max=double(),L_mean=double())
  list(spots=spots,summary=bind_rows_fill(summaries),
       settings=list(method="spatial_farthest_point",n_spots=n_spots,
                     spot_radius_mm=spot_radius_mm,edge_exclude_mm=edge_exclude_mm))
}
