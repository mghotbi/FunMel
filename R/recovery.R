.fm_show <- function(p, title) {
  rgb <- p$rgb; H <- dim(rgb)[1]; W <- dim(rgb)[2]
  graphics::plot.new()
  graphics::plot.window(xlim=c(0.5,W+0.5), ylim=c(H+0.5,0.5),
                        asp=1, xaxs="i", yaxs="i")
  graphics::rasterImage(grDevices::as.raster(rgb),0.5,H+0.5,W+0.5,0.5,
                         interpolate=FALSE)
  graphics::title(main=title, cex.main=0.85)
}
.fm_circle3 <- function(xy) {
  xy <- as.matrix(xy)
  if (!identical(dim(xy),c(3L,2L)) || any(!is.finite(xy)))
    stop("Supply three finite rim points with columns x and y.")
  a <- 2*sweep(xy[2:3,,drop=FALSE],2,xy[1,],"-")
  b <- rowSums(xy[2:3,,drop=FALSE]^2)-sum(xy[1,]^2)
  if (abs(det(a))<1e-8) stop("Rim points are collinear; select points farther apart.")
  centre <- as.vector(solve(a,b))
  c(centre,sqrt(sum((xy[1,]-centre)^2)))
}
.fm_polygon_mask <- function(xy,H,W) {
  xy <- as.matrix(xy)
  if (ncol(xy)!=2L || nrow(xy)<3L || any(!is.finite(xy)))
    stop("Each outline needs at least three finite x/y vertices.")
  if(any(xy[,1]<0.5|xy[,1]>W+0.5|xy[,2]<0.5|xy[,2]>H+0.5))
    stop("Outline vertices must lie inside the working image.")
  area <- abs(sum(xy[,1]*xy[c(2:nrow(xy),1),2]-
                    xy[c(2:nrow(xy),1),1]*xy[,2]))/2
  if(area<1) stop("Outline encloses too little area.")
  # Even-odd point-in-polygon rule, evaluated at pixel centres.
  x <- rep(seq_len(W),each=H); y <- rep(seq_len(H),W)
  inside <- rep(FALSE,length(x)); j <- nrow(xy)
  for(i in seq_len(nrow(xy))) {
    if (xy[i,2]!=xy[j,2]) {
      cross <- ((xy[i,2]>y)!=(xy[j,2]>y)) &
        x < (xy[j,1]-xy[i,1])*(y-xy[i,2])/(xy[j,2]-xy[i,2])+xy[i,1]
      inside <- xor(inside,cross)
    }
    j <- i
  }
  matrix(inside,H,W)
}
.fm_click_polygon <- function(p,title) {
  if(!interactive()) stop("Interactive outlines need an RStudio or desktop graphics device.")
  .fm_show(p,title)
  message(title,". Click boundary points in order, then finish with Esc/right-click.")
  q <- graphics::locator(type="l",col="#00B8D4",lwd=2)
  if(is.null(q)||length(q$x)<3L) stop("Outline cancelled; no recovery result was saved.")
  cbind(x=q$x,y=q$y)
}
.fm_save_qc <- function(result,output) {
  p <- result$plate; ob <- p$objects; cl <- result$colonies
  cols <- c("#1FB5E0","#D6336C","#3FA34D","#7B5CD6")
  grDevices::png(output,width=2000,height=1250,res=150)
  on.exit(grDevices::dev.off())
  graphics::par(mar=c(1,1,3,1))
  .fm_show(p,if(identical(ob$boundary_source,"guided_polygon"))
    "PROPOSED boundaries: inspect all target interiors and the whole central fungal extent" else
    "Reviewed boundaries: Zymoseptoria targets; orange = whole central fungal extent")
  th <- seq(0,2*pi,length.out=361)
  d <- p$dish
  graphics::lines(d$x+d$r_outer*cos(th),d$y+d$r_outer*sin(th),
                  col="#00B8D4",lty=2,lwd=2)
  bound <- function(mask,col) {
    b <- mask_boundary(mask)
    w <- which(b,arr.ind=TRUE)
    if(nrow(w)) graphics::points(w[,2],w[,1],pch=".",col=col)
  }
  for(i in seq_len(nrow(cl))) {
    bound(ob$labels==i,cols[i])
    graphics::text(cl$centroid_x_px[i],cl$centroid_y_px[i],
      sprintf("%s: MI %.1f; d %.2f mm",cl$colony_id[i],cl$MI_mean[i],cl$eq_diameter_mm[i]),
      col="white",cex=.75)
  }
  if(any(ob$central_fungus)) bound(ob$central_fungus,"#FF9900")
  if(nrow(result$spots)) for(i in seq_len(nrow(result$spots))) {
    s <- result$spots[i,]
    graphics::lines(s$x_px+s$spot_radius_mm/d$mm_per_px*cos(th),
                    s$y_px+s$spot_radius_mm/d$mm_per_px*sin(th),col="white")
  }
}

# Reviewed polygons bypass uncertain automatic tissue classification.
.fm_apply_polygons <- function(p, layout, polygons) {
  H <- dim(p$rgb)[1]; W <- dim(p$rgb)[2]
  ids <- as.character(layout$positions$id)
  needed <- c(ids,if(layout$centre=="fungus") "central_fungus")
  if(!is.list(polygons)||!all(needed %in% names(polygons)))
    stop("Reviewed polygons require every target ID and central_fungus for fungal confrontations.")
  masks <- lapply(polygons[needed],.fm_polygon_mask,H=H,W=W)
  m <- dish_masks(p)
  if(any(vapply(masks,function(z) any(z & !m$agar),logical(1))))
    stop("A reviewed outline extends outside the analysed agar disk; check dish and outlines.")
  if(any(Reduce(`+`,lapply(masks,as.integer))>1L))
    stop("Reviewed tissue outlines overlap; do not assign the same pixels to different organisms.")
  if(any(vapply(masks,sum,numeric(1))<30)) stop("A reviewed outline contains fewer than 30 pixels.")
  labels <- matrix(0L,H,W)
  for(i in seq_along(ids)) labels[masks[[ids[i]]]] <- i
  central <- if(layout$centre=="fungus") masks$central_fungus else matrix(FALSE,H,W)
  empty <- matrix(FALSE,H,W)
  xy <- t(vapply(masks[ids],function(z) c(mean(m$x[z]),mean(m$y[z])),numeric(2)))
  ct <- data.frame(id=ids,expected_x=xy[,1],expected_y=xy[,2],core_x=xy[,1],core_y=xy[,2],
      core_depth_mm=NA_real_,detected=TRUE,segmentation_trim_fraction=0,row.names=NULL)
  p$classes <- list(map=matrix(0L,H,W),map_final=matrix(0L,H,W),source="reviewed manual polygons")
  p$objects <- list(labels=labels,satellites=empty,bacteria=empty,
    central_fungus=central,central_core=empty,central_object=central,
    partner_type=layout$centre,hyphae=empty,fungus=labels>0,colony_table=ct,
    boundary_source="manual_polygon")
  p
}

.fm_validate_annotation <- function(annotation,path,max_dim,diameter,centre) {
  if(!is.list(annotation)||!all(c("image_md5","max_dim","working_dim","dish_diameter_mm","centre","dish") %in% names(annotation)))
    stop("Invalid recovery annotation; use retry_funmel_dish() or recover_funmel_plate().")
  if(!is.character(path)||length(path)!=1L||!file.exists(path))
    stop("Recovery annotations require their original photograph file.")
  if(!identical(as.character(annotation$image_md5),unname(as.character(tools::md5sum(path)))))
    stop("Recovery annotation belongs to a different or changed photograph; do not reuse it.")
  if(!identical(as.character(annotation$centre),as.character(centre)))
    stop("Recovery annotation centre model differs from metadata/layout; correct the experimental role.")
  if(!isTRUE(all.equal(annotation$max_dim,max_dim,check.attributes=FALSE)))
    stop("Recovery annotation working resolution differs: rerun with max_dim=",annotation$max_dim,".")
  if(!isTRUE(all.equal(annotation$dish_diameter_mm,diameter,check.attributes=FALSE)))
    stop("Recovery annotation dish diameter differs; supply the measured diameter used for annotation.")
  d <- annotation$dish
  if(!is.numeric(d)||length(d)!=3L||any(!is.finite(d))||d[3]<=0)
    stop("Invalid reviewed dish circle.")
  invisible(TRUE)
}

.fm_collect_circle <- function(p,dish) {
  if(!is.null(dish)) return(dish)
  if(!interactive()) stop("Supply dish=c(x,y,r) for a noninteractive recovery run.")
  .fm_show(p,"Click THREE widely separated points on the OUTER dish rim")
  message("Click exactly three outer-rim points, widely separated around the dish.")
  q <- graphics::locator(n=3,type="p",col="#00B8D4",pch=3)
  if(is.null(q)||length(q$x)!=3L) stop("Dish selection cancelled; no measurements were changed.")
  .fm_circle3(cbind(q$x,q$y))
}

.fm_recovery <- function(path,dish_diameter_mm,centre,output_dir,max_dim,dish,polygons,
                         n_spots,spot_radius_mm,n_boot,flat_field,edge_exclude_mm,manual) {
  validate_image_settings(list(dish_diameter_mm=dish_diameter_mm,max_dim=max_dim,
       n_spots=n_spots,spot_radius_mm=spot_radius_mm))
  if(!is.character(path)||length(path)!=1L||!file.exists(path)||dir.exists(path))
    stop("Select one original image file, not a ZIP or folder.")
  if(!grepl("\\.(jpe?g|png|tiff?|heic)$",path,ignore.case=TRUE))
    stop("Select an original JPG/PNG/TIFF/HEIC photograph, not a ZIP or R script.")
  if(is.null(output_dir)) output_dir <- tempfile("FunMel_recovered_",tmpdir=path.expand("~"))
  if(file.exists(output_dir)) stop("Use a NEW output directory; original results will not be overwritten.")
  p <- read_plate(path,max_dim=max_dim)
  dish <- .fm_collect_circle(p,dish)
  p <- detect_plate(p,dish=dish,dish_diameter_mm=dish_diameter_mm)
  if(manual && is.null(polygons)) {
    ids <- c("TL","TR","BR","BL",if(centre=="fungus") "central_fungus")
    polygons <- stats::setNames(lapply(ids,function(id)
      .fm_click_polygon(p,paste("Outline",id,"tissue; exclude agar and other colonies"))),ids)
  }
  guidance <- attr(polygons,"guidance")
  if(!is.null(guidance)) {
    .fm_validate_annotation(guidance,path,max_dim,dish_diameter_mm,centre)
    if(!isTRUE(all.equal(unname(dish),guidance$dish,check.attributes=FALSE)))
      stop("Proposal dish differs; regenerate proposals with the reviewed circle.")
    for(i in seq_len(nrow(guidance$diagnostics))) {
      id <- guidance$diagnostics$colony_id[i]
      if(!identical(polygons[[id]],guidance$proposed_polygons[[id]])) {
        guidance$diagnostics$method[i] <- "manual_override"
        guidance$diagnostics$polarity[i] <- NA_character_
      }
    }
  }
  annotation <- list(image_md5=unname(as.character(tools::md5sum(path))),
    source_file=basename(path),max_dim=max_dim,working_dim=dim(p$rgb)[1:2],
    dish_diameter_mm=dish_diameter_mm,centre=centre,dish=unname(dish),polygons=polygons,
    guidance=guidance)
  res <- analyze_plate(path,layout=plate_layout(centre=centre),
     dish_diameter_mm=dish_diameter_mm,max_dim=max_dim,annotation=annotation,
     n_spots=n_spots,spot_radius_mm=spot_radius_mm,n_boot=n_boot,
     flat_field=flat_field,edge_exclude_mm=edge_exclude_mm,keep_images=TRUE)
  if(manual && any(!is.finite(res$colonies$MI_mean)))
    stop("A target has no usable MI; inspect exposure, outlines and edge exclusion.")
  dir.create(output_dir,recursive=TRUE)
  if(!dir.exists(output_dir)) stop("Could not create recovery output directory.")
  res$recovery_dir <- normalizePath(output_dir)
  res$recovery_status <- "measured_requires_review"
  for(nm in c("colonies","spots","profiles"))
    utils::write.csv(res[[nm]],file.path(output_dir,paste0(nm,".csv")),row.names=FALSE,na="")
  utils::write.csv(res$plate_summary,file.path(output_dir,"plates.csv"),row.names=FALSE,na="")
  saveRDS(res,file.path(output_dir,"recovered_analysis.rds"))
  saveRDS(annotation,file.path(output_dir,"annotation.rds"))
  if(manual) .fm_save_qc(res,file.path(output_dir,"recovered_QC.png")) else {
    grDevices::png(file.path(output_dir,"recovered_QC.png"),width=2400,height=1250,res=150)
    tryCatch(plot_qc(res),finally=grDevices::dev.off())
  }
  writeLines(utils::capture.output(utils::sessionInfo()),file.path(output_dir,"sessionInfo.txt"))
  res$recovery_dir <- normalizePath(output_dir)
  message("Recovery saved in: ",res$recovery_dir,". Inspect recovered_QC.png before interpretation.")
  invisible(res)
}

#' Recover a plate by reviewing its dish or tissue boundaries
#'
#' `retry_funmel_dish()` uses three outer-rim clicks to correct the dish circle
#' and reruns automatic tissue segmentation. `recover_funmel_plate()` additionally
#' defaults to guided recovery: click one centre per peripheral target after the
#' three dish-rim clicks. It proposes target boundaries and central fungal extent
#' without freehand outlines. All proposed boundaries require visual review.
#' mode='manual' retains freehand outlines finished with right-click/Esc. These are optional
#' recovery tools for photographs whose automatic masks fail visual review.
#'
#' @details
#' Whole central fungal extent includes visible connected hyphal growth. Dense
#' core and peripheral growth are not separated by manual polygons; corresponding
#' hyphal-subregion summaries remain unavailable. Invisible or overlapping tissue
#' cannot be recovered by inventing boundaries. Corrected diameters depend on a
#' verified physical dish diameter and the selected outer rim.
#'
#' The returned `annotation` can be saved and passed to `analyze_plate(annotation=)`
#' or to `run_experiment(corrections=list(plate_id=annotation))`. Use the actual
#' metadata plate ID as the list name. File checksum, resolution, diameter and
#' centre model must match. Rerunning replaces the saved image-analysis run;
#' copy the project folder first if the original run must be retained.
#'
#' @param path One original photograph, not a ZIP or QC figure.
#' @param dish_diameter_mm Verified outer dish diameter in millimetres.
#' @param centre `"fungus"` for a confrontation, `"none"` for its control.
#' @param output_dir New output directory; default creates a new folder in the home directory.
#' @param max_dim Working image resolution, used again when applying the annotation.
#' @param dish Optional `c(x,y,r)` in working-image pixels; otherwise click three rim points.
#' @param polygons Named list of x/y vertex matrices. NULL collects interactive outlines.
#' @param n_spots,spot_radius_mm Optional spot sampling settings.
#' @param n_boot Number of spatial bootstrap replicates.
#' @param flat_field Whether to request illumination correction.
#' @param edge_exclude_mm Margin excluded from colour measurements in mm.
#' @param mode guided (default) proposes boundaries from four target-centre
#'   clicks; manual requests freehand boundaries. Supplied polygons take precedence.
#' @param seeds Optional four-row x/y matrix named TL, TR, BR, BL for guided
#'   recovery without clicks, in working-image pixels.
#' @return A `funmel_result` with `annotation` and `recovery_dir`. New measurement
#' CSVs, annotation RDS, result RDS, QC PNG and session information are saved.
#' Guided failures return a boundary proposal with recovery_status=awaiting_boundaries
#' and saved diagnostics/QC, without measurements. Successful recovery returns
#' recovery_status=measured_requires_review; no review flags are approved.
#' Closing the graphics window during guided selection returns recovery_status=cancelled
#' with an informative message and no new measurements.
#' @examples
#' \dontrun{
#' photo <- file.choose() # Select an original JPG.
#' fixed <- retry_funmel_dish(photo, dish_diameter_mm = 90, centre = "fungus")
#' # Use 90 only for a measured 90-mm outer rim. If tissue masks remain wrong:
#' fixed <- recover_funmel_plate(photo, dish_diameter_mm = 90, centre = "fungus")
#' }
#' @export
retry_funmel_dish <- function(path,dish_diameter_mm,centre=c("fungus","none"),
                              dish=NULL,output_dir=NULL,max_dim=1200,
                              n_spots=5,spot_radius_mm=0.4,n_boot=200,
                              flat_field=TRUE,edge_exclude_mm=0.1) {
  centre <- match.arg(centre)
  .fm_recovery(path,dish_diameter_mm,centre,output_dir,max_dim,dish,NULL,
    n_spots,spot_radius_mm,n_boot,flat_field,edge_exclude_mm,FALSE)
}

#' @rdname retry_funmel_dish
#' @export
recover_funmel_plate <- function(path,dish_diameter_mm,centre=c("fungus","none"),
                                 output_dir=NULL,max_dim=1200,dish=NULL,polygons=NULL,
                                 n_spots=5,spot_radius_mm=0.4,n_boot=200,
                                 flat_field=TRUE,edge_exclude_mm=0.1,
                                 mode=c("guided","manual"),seeds=NULL) {
  if(!is.null(output_dir) && file.exists(output_dir))
    stop("Use a NEW output directory; original results will not be overwritten.")
  centre <- match.arg(centre)
  mode <- match.arg(mode)
  if(is.null(polygons) && mode=="guided") {
    proposal <- tryCatch(suggest_funmel_polygons(path,dish_diameter_mm,centre=centre,dish=dish,
      seeds=seeds,max_dim=max_dim,central_auto=TRUE),error=function(e) {
        if(grepl("graphics device closed|selection cancelled",conditionMessage(e),ignore.case=TRUE)) {
          message("Recovery cancelled because the graphics selection was interrupted. Rerun the call, keep the photograph window open, and click each requested point. No new measurements were saved.")
          return(structure(list(recovery_status="cancelled",recovery_dir=NULL),class="funmel_recovery_cancelled"))
        }
        stop(e)
      })
    if(inherits(proposal,"funmel_recovery_cancelled")) return(invisible(proposal))
    needed <- c("TL","TR","BR","BL",if(centre=="fungus") "central_fungus")
    if(!all(needed %in% names(proposal$polygons))) {
      if(is.null(output_dir)) output_dir <- tempfile("FunMel_proposal_",tmpdir=path.expand("~"))
      if(file.exists(output_dir)) stop("Use a NEW output directory; original results will not be overwritten.")
      dir.create(output_dir,recursive=TRUE)
      if(!dir.exists(output_dir)) stop("Could not create proposal directory.")
      proposal$recovery_dir <- normalizePath(output_dir)
      proposal$recovery_status <- "awaiting_boundaries"
      saveRDS(proposal,file.path(output_dir,"boundary_proposal.rds"))
      utils::write.csv(proposal$guidance$diagnostics,file.path(output_dir,"boundary_diagnostics.csv"),row.names=FALSE)
      grDevices::png(file.path(output_dir,"proposed_QC.png"),width=2000,height=1400,res=150)
      tryCatch(plot(proposal),finally=grDevices::dev.off())
      message("Boundary proposals saved in ",proposal$recovery_dir,
        ". No measurements were calculated: unresolved boundaries are listed in boundary_diagnostics.csv. Use a reviewed manual override for unresolved tissue.")
      return(invisible(proposal))
    }
    dish <- proposal$dish
    polygons <- proposal$polygons
    message("Boundaries proposed from target centres and local contrast. Measurements are provisional: inspect every target interior and the central fungal fringe in recovered_QC.png.")
  }
  .fm_recovery(path,dish_diameter_mm,centre,output_dir,max_dim,dish,polygons,
    n_spots,spot_radius_mm,n_boot,flat_field,edge_exclude_mm,TRUE)
}
