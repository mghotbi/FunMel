#' Separate Zymoseptoria targets and the central fungal colony
#'
#' Uses known inoculation positions and seeded watershed segmentation to
#' separate peripheral target colonies from the central partner. The central
#' fungus includes a dense core and connected peripheral hyphal growth.
#' These masks are image-based tissue candidates, not inhibition boundaries.
#' Morphological clean-up removes small fragments; ambiguous contact between
#' organisms requires review. Target outlines are not forced into circles.
#'
#' @param plate A plate processed by [classify_pixels()].
#' @param layout The [plate_layout()] used for classification.
#' @param min_area_mm2 Minimum area of a fungal fragment (mm^2).
#' @param min_core_mm Minimum distance from core to colony edge (mm).
#' @param morph_mm Radius of morphological clean-up (mm).
#' @param hyphae_link_mm Maximum connected gap between central core and peripheral growth (mm).
#' @param bridge_mm Opening radius (mm) separating central tissue from narrow connections.
#' @param edge_criterion Sub-pixel-consistent edge placement: within a
#'   3-pixel band inside each colony outline, pixels are kept only if their
#'   colour difference from agar is at least this fraction of the colony's
#'   interior median ("half-maximum" criterion, unbiased for a blurred step
#'   edge). Set 0 to disable.
#'
#' @return The plate with element `objects`: a list containing the colony
#'   label matrix (`labels`, values = row index of `colony_table`),
#'   `satellites`, `bacteria`, `central_fungus`, `central_object` and `hyphae`
#'   masks, partner_type and colony_table. hyphae is connected peripheral central growth
#'   candidate; its biological identity and boundary need QC.
#' @examples
#' sim <- simulate_plate(width = 300, height = 400, seed = 6)
#' p <- read_plate(sim$image) |> detect_plate() |> model_background() |>
#'   classify_pixels(plate_layout()) |> segment_colonies(plate_layout())
#' p$objects$colony_table
#' @export
segment_colonies <- function(plate, layout = plate_layout(), min_area_mm2 = 0.5,
                             min_core_mm = 0.4, morph_mm = 0.08, hyphae_link_mm = 1,
                             edge_criterion = 0.5, bridge_mm = 0.5) {
  stopifnot(is_funmel_plate(plate), !is.null(plate$classes))
  d <- plate$dish
  mmpp <- d$mm_per_px
  map <- plate$classes$map
  m <- dish_masks(plate)
  rpx <- morph_mm / mmpp

  # ---- bacterium first: one compact colony nearest the dish centre.
  # Bacteria-class pixels elsewhere (e.g. light colony margins, faint hyphae
  # fringe) are re-assigned to the most probable remaining class.
  bact <- matrix(FALSE, nrow(map), ncol(map))
  if (layout$centre %in% c("bacteria", "fungus") && any(map == 2L)) {
    b <- map == 2L
    if (rpx >= 1) b <- close_disk(b, rpx)
    # cut thin bridges (e.g. along a hyphae into a light colony) so that only
    # the compact central colony is kept
    b <- open_disk(b, max(1, bridge_mm / mmpp))
    b <- remove_small(b, min_area_mm2 / mmpp^2)
    if (any(b)) {
      lb <- label_components(b)
      ids <- seq_len(max(lb))
      dc <- vapply(ids, function(k) {
        w <- which(lb == k)
        min(sqrt((m$x[w] - d$x)^2 + (m$y[w] - d$y)^2))
      }, 1)
      if (min(dc) <= 0.25 * d$r_outer) bact <- fill_holes(lb == ids[which.min(dc)])
    }
  }
  stray <- map == 2L & !bact
  if (any(stray)) map <- reassign_pixels(plate, map, stray, exclude = "bacteria")
  map[bact] <- 2L

  # ---- fungus
  fung <- map == 1L
  if (rpx >= 1) fung <- open_disk(close_disk(fung, rpx), rpx)
  # fill holes, but never across bacterial or hyphae tissue
  fung <- fill_holes(fung, forbid = map %in% c(2L, 3L)) & m$agar & !bact
  fung <- remove_small(fung, min_area_mm2 / mmpp^2)
  dist <- edt(fung)

  exp_pos <- layout_pixels(layout, d)
  search_r <- layout$search_frac * d$r_outer
  n <- nrow(exp_pos)
  markers <- matrix(0L, nrow(fung), ncol(fung))
  core <- data.frame(id = exp_pos$id, expected_x = exp_pos$x, expected_y = exp_pos$y,
                     core_x = NA_real_, core_y = NA_real_, core_depth_mm = NA_real_,
                     detected = FALSE, stringsAsFactors = FALSE)

  # candidate colony cores: greedy non-maximum suppression on the distance
  # transform (each accepted core suppresses its own inscribed disk)
  cand <- find_cores(dist, fung, min_depth_px = min_core_mm / mmpp,
                     max_n = 4L * nrow(core) + 4L)
  if (nrow(cand)) {
    # match expected positions to cores: closest pairs first, each core used
    # once, cores much shallower than the deepest (satellites) ignored
    cand <- cand[cand$depth >= 0.3 * max(cand$depth), , drop = FALSE]
    dmat <- sqrt(outer(core$expected_x, cand$x, "-")^2 + outer(core$expected_y, cand$y, "-")^2)
    dmat[dmat > search_r] <- Inf
    while (any(is.finite(dmat))) {
      k <- which(dmat == min(dmat), arr.ind = TRUE)[1, ]
      i <- k[1]; j <- k[2]
      core$core_x[i] <- cand$x[j]; core$core_y[i] <- cand$y[j]
      core$core_depth_mm[i] <- cand$depth[j] * mmpp
      core$detected[i] <- TRUE
      dmat[i, ] <- Inf; dmat[, j] <- Inf
    }
  }
  # two expected positions must not share one core
  dup <- duplicated(paste(core$core_x, core$core_y)) & core$detected
  if (any(dup)) {
    cli::cli_warn("Colonies {.val {core$id[dup]}} share a core with another colony and were not detected.")
    core$detected[dup] <- FALSE
  }
  for (i in which(core$detected)) {
    # seed = disk of half the local depth around the core (robust to plateaus)
    rr <- max(1, 0.5 * core$core_depth_mm[i] / mmpp)
    sel <- (m$x - core$core_x[i])^2 + (m$y - core$core_y[i])^2 <= rr^2 & fung
    markers[sel] <- i
  }
  cost <- -gauss_blur(dist, 1)
  # (the centroid check after the watershed rejects "colonies" that are
  # really bands of mis-classified tissue passing through the search area)
  labels <- if (any(markers > 0)) watershed_cpp(cost, markers, fung) else markers
  for (i in which(core$detected)) {
    w <- which(labels == i)
    if (sqrt((mean(m$x[w]) - core$expected_x[i])^2 + (mean(m$y[w]) - core$expected_y[i])^2) > search_r) {
      labels[w] <- 0L
      core$detected[i] <- FALSE
    }
  }
  satellites <- fung & labels == 0L
  # unassigned "fungus" fragments hugging the bacterium are its darker
  # margin (colony edge / swarming front), not fungal satellites
  if (any(bact) && any(satellites)) {
    ls <- label_components(satellites)
    touch <- unique(ls[dilate_disk(bact, 2) & ls > 0])
    if (length(touch)) {
      add <- ls %in% touch
      bact <- fill_holes(bact | add)
      satellites <- satellites & !add
      fung <- fung & !add
    }
  }
  # fragments touching the edge of the analysed disk are dish-wall
  # reflections or meniscus artefacts, not satellite colonies
  if (any(satellites)) {
    ls <- label_components(satellites)
    rim <- m$rr > d$r_agar - 3 & m$agar
    edge_ids <- unique(ls[rim & ls > 0])
    if (length(edge_ids)) satellites <- satellites & !(ls %in% edge_ids)
  }
  if (edge_criterion > 0) labels <- refine_edges(plate, labels, edge_criterion)

  # A thin classified bridge may connect a target colony to the central
  # fungal margin. Keep the opened component containing its assigned core,
  # then restore its edge locally. Never force a circular target outline.
  core$segmentation_trim_fraction <- 0
  if(layout$centre == "fungus") {
    before <- labels
    for(i in which(core$detected)) {
      cm <- labels==i
      separated <- open_disk(cm,max(1,bridge_mm/mmpp))
      lc <- label_components(separated)
      if(max(lc)>1L) {
        w <- which(lc>0)
        nearest <- w[which.min((m$x[w]-core$core_x[i])^2+(m$y[w]-core$core_y[i])^2)]
        anchor <- lc[nearest]
        # Only cut secondary components bordering the central partner;
        # distant lobes of an irregular target colony must remain eligible.
        central_ids <- unique(lc[dilate_disk(bact,max(2,bridge_mm/mmpp)+2) & lc>0])
        central_ids <- setdiff(central_ids,anchor)
        if(!length(central_ids)) next
        central_parts <- matrix(lc %in% central_ids,nrow(lc),ncol(lc))
        retained <- cm & dilate_disk(lc>0 & !central_parts,max(1,bridge_mm/mmpp)+1)
        core$segmentation_trim_fraction[i] <- sum(cm & !retained)/sum(cm)
        labels[cm & !retained] <- 0L
      }
    }
    removed <- before>0 & labels==0
    if(any(removed)) {
      lr <- label_components(removed)
      linked <- unique(lr[dilate_disk(bact,2) & lr>0])
      add <- lr %in% linked & removed
      bact <- fill_holes(bact | add) & !(labels>0)
      satellites <- satellites | (removed & !add)
      fung <- fung & !add
    }
  }

  # ---- hyphae: hyphae-class pixels connected to the bacterium
  hyphae <- matrix(FALSE, nrow(map), ncol(map))
  if (any(bact) && any(map == 3L)) {
    h <- map == 3L & !fung
    if (rpx >= 1) h <- open_disk(close_disk(h, rpx), rpx)
    near_b <- edt(!bact) * mmpp <= hyphae_link_mm
    lh <- label_components(h | bact)
    keep <- unique(lh[bact | (near_b & h)])
    keep <- keep[keep > 0]
    hyphae <- (lh %in% keep) & h
    hyphae <- fill_holes(hyphae | bact) & !bact & !fung
  }
  bact <- bact & !(labels > 0)
  plate$classes$map_final <- map

  central_fungus <- if(layout$centre=="fungus") (bact | hyphae) else matrix(FALSE,nrow(map),ncol(map))
  bacterial_mask <- if(layout$centre=="bacteria") bact else matrix(FALSE,nrow(map),ncol(map))
  plate$objects <- list(labels=labels,satellites=satellites,bacteria=bacterial_mask,
                        central_fungus=central_fungus,central_core=bact,
                        central_object=if(layout$centre=="fungus") central_fungus else bact,
                        partner_type=layout$centre,hyphae=hyphae,fungus=fung,colony_table=core)
  plate
}

#' Re-assign pixels to their most probable class, excluding some classes
#' @keywords internal
#' @noRd
reassign_pixels <- function(plate, map, which_px, exclude) {
  cl <- plate$classes
  keep_k <- which(!cl$post_names %in% exclude)
  if (!length(keep_k)) {
    map[which_px] <- 4L
    return(map)
  }
  pos <- match(which(which_px), cl$obj_idx)
  ok <- !is.na(pos)
  P <- cl$post[pos[ok], keep_k, drop = FALSE]
  code <- c(fungus = 1L, bacteria = 2L, hyphae = 3L)[cl$post_names[keep_k]]
  newlab <- code[max.col(P, ties.method = "first")]
  idx <- which(which_px)
  map[idx[ok]] <- newlab
  map[idx[!ok]] <- 4L
  map
}

#' Re-place colony outlines at half contrast (internal)
#'
#' Local version of the 50 % edge criterion: each pixel in a thin band inside
#' the outline is compared with the *local* colony colour (inside the band)
#' and the *local* surrounding colour (just outside the outline, which may
#' be agar, hyphae or a neighbouring culture), and is kept only if it is
#' closer to the colony. `frac` shifts the threshold (0.5 = half way).
#' @keywords internal
#' @noRd
refine_edges <- function(plate, labels, frac = 0.5, band = 3) {
  S <- plate$bg$smooth
  mmpp <- plate$dish$mm_per_px
  sig <- max(2, 0.25 / mmpp)
  for (i in setdiff(unique(as.vector(labels)), 0L)) {
    cm <- labels == i
    w <- which(cm, arr.ind = TRUE)
    pad <- ceiling(3 * sig + band + 2)
    r1 <- max(1, min(w[, 1]) - pad); r2 <- min(nrow(cm), max(w[, 1]) + pad)
    c1 <- max(1, min(w[, 2]) - pad); c2 <- min(ncol(cm), max(w[, 2]) + pad)
    sub <- cm[r1:r2, c1:c2, drop = FALSE]
    dep_in <- edt(sub)
    dep_out <- edt(!sub)
    inner <- sub & dep_in > band + 1
    outer <- !sub & dep_out > 1 & dep_out <= band + 3
    if (sum(inner) < 50 || sum(outer) < 20) next
    bandm <- sub & dep_in <= band
    d_in <- 0; d_out <- 0
    for (ch in c("L", "a", "b")) {
      x <- S[[ch]][r1:r2, c1:c2, drop = FALSE]
      mi <- gauss_blur(x, sig, w = inner * 1)
      mo <- gauss_blur(x, sig, w = outer * 1)
      d_in <- d_in + (x - mi)^2
      d_out <- d_out + (x - mo)^2
    }
    d_in <- sqrt(d_in); d_out <- sqrt(d_out)
    # keep if the pixel lies on the colony side of the frac point
    drop <- bandm & is.finite(d_in) & is.finite(d_out) &
      d_in / pmax(d_in + d_out, 1e-9) > frac
    keep <- sub & !drop
    keep <- open_disk(keep, 1)
    keep <- largest_component(keep)
    loss <- sub & !keep
    tmp <- labels[r1:r2, c1:c2]
    tmp[loss] <- 0L
    labels[r1:r2, c1:c2] <- tmp
  }
  labels
}

#' Candidate colony cores by non-maximum suppression of the EDT (internal)
#' @keywords internal
#' @noRd
find_cores <- function(dist, mask, min_depth_px, max_n = 20L) {
  idx <- which(mask & dist >= min_depth_px)
  if (!length(idx)) return(data.frame(x = numeric(), y = numeric(), depth = numeric()))
  H <- nrow(dist)
  xs <- (idx - 1) %/% H + 1; ys <- (idx - 1) %% H + 1
  dv <- dist[idx]
  o <- order(dv, decreasing = TRUE)
  xs <- xs[o]; ys <- ys[o]; dv <- dv[o]
  alive <- rep(TRUE, length(dv))
  out <- list()
  while (any(alive) && length(out) < max_n) {
    j <- which(alive)[1]
    out[[length(out) + 1]] <- c(xs[j], ys[j], dv[j])
    r <- max(dv[j], min_depth_px) * 1.5
    alive[alive] <- (xs[alive] - xs[j])^2 + (ys[alive] - ys[j])^2 > r^2
  }
  o <- do.call(rbind, out)
  data.frame(x = o[, 1], y = o[, 2], depth = o[, 3])
}
