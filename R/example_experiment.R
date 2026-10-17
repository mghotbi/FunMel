#' Reproducible synthetic matched-set experiment for learning the workflow
#'
#' Three sets, each with control, fungus_A and fungus_B; three independent
#' plates per cell and four target colonies per plate. This is synthetic data,
#' not an experimental result. True treatment MI differences are 8 and 15.
#' @param seed Reproducible RNG seed.
#' @return List containing metadata and colonies. No image files are created.
#' @export
example_experiment <- function(seed=42L) {
  with_seed(seed, {
    meta<-expand.grid(replicate=1:3,treatment=c("control","fungus_A","fungus_B"),
                      set_id=c("S1","S2","S3"),stringsAsFactors=FALSE)
    meta$plate_id<-sprintf("P%03d",seq_len(nrow(meta)))
    meta$file<-paste0(meta$plate_id,".jpg")
    meta$zymo_strain<-"example_strain";meta$day<-7L;meta$medium<-"example_medium"
    meta$centre_model<-ifelse(meta$treatment=="control","none","fungus")
    meta$partner_type<-ifelse(meta$treatment=="control","none","fungus")
    rows<-lapply(seq_len(nrow(meta)),function(i){
      m<-meta[i,,drop=FALSE];base<-40+5*(match(m$set_id,c("S1","S2","S3"))-1)
      effect<-c(control=0,fungus_A=8,fungus_B=15)[m$treatment]
      cbind(m[rep(1,4),,drop=FALSE],colony_id=c("TL","TR","BR","BL"),
            MI_mean=base+effect+stats::rnorm(1,0,3)+stats::rnorm(4,0,1),
            detected=TRUE,is_target=TRUE)
    })
    col<-do.call(rbind,rows);rownames(col)<-NULL
    list(metadata=meta,colonies=col)
  })
}
