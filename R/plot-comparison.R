#' Plot plate-level darkness and matched melanization coefficients
#'
#' A two-panel descriptive figure. Panel A shows independent plate MI means and
#' control means within each matching set. Panel B shows treatment plate ratios
#' and the set-specific ratio of means. Bars show descriptive between-plate SD,
#' never confidence intervals. Single-plate SD is unavailable. Ratio SD conditions
#' on the shared control mean and does not quantify its uncertainty.
#' Controls shown on multiple rows within a set are shared, not new replicates.
#' @param colonies Colony table or an analyze_plates() batch result.
#' @param control Control treatment label.
#' @param by Additional matching columns passed to melanization_coefficient().
#' @param preview TRUE labels the figure as a provisional preview. No metadata
#'   approval flags are required in either mode. Unconfirmed image QC warns by
#'   default and is labelled in the caption.
#' @param labels Optional named character vector of treatment display names.
#' @param file Optional output prefix. Writes vector PDF and SVG and 600-dpi PNG.
#' @param palette Optional named vector of treatment colours. Controls always
#'   use dark outlined squares; treatments use filled circles.
#' @param require_qc Default FALSE warns on unconfirmed recorded QC. TRUE requires
#'   every included plate to have qc_pass=TRUE.
#' @param width,height Export dimensions in inches. Height defaults to row count.
#' @return A ggplot object, invisibly when exported. Colours and typography can
#'   be edited using standard ggplot2 methods. Match the target journal's size
#'   and caption requirements before submission. The attribute
#'   `FunMel_statistics` contains the plotted means, SDs, counts and descriptive
#'   differences. Export also writes a `_statistics.csv` companion table.
#' @importFrom rlang .data
#' @export
plot_treatment_comparison <- function(colonies, control="control", by=NULL,
                                     preview=FALSE, labels=NULL, file=NULL,
                                     width=7.2, height=NULL, palette=NULL,require_qc=FALSE) {
  if(!is.logical(preview) || length(preview)!=1L || is.na(preview)) stop("preview must be TRUE or FALSE.")
  if(is.list(colonies) && !is.data.frame(colonies)) {
    if(!is.null(colonies$failed) && nrow(colonies$failed)) stop("Resolve failed images before plotting.")
    colonies<-colonies$colonies
  }
  if(!is.data.frame(colonies)) stop("Supply a colony table or batch result.")
  mc<-melanization_coefficient(colonies,control=control,by=by,require_qc=require_qc)
  cf<-mc$coefficients
  if(any(cf$status!="ok")) stop("Resolve unavailable coefficients before plotting.")
  cf<-cf[order(as.character(cf$treatment),as.character(cf$set_id)),,drop=FALSE]
  display<-as.character(cf$treatment)
  if(!is.null(labels)) {
    if(!is.character(labels) || is.null(names(labels)) || anyDuplicated(names(labels))) stop("labels must be a uniquely named character vector.")
    j<-match(display,names(labels));display[!is.na(j)]<-labels[j[!is.na(j)]]
  }
  # Each row is one matching stratum, never an implicit pooled denominator.
  rowlabel<-if(anyDuplicated(display)) paste0(display," [",cf$set_id,"]") else display
  if(anyDuplicated(rowlabel)) rowlabel<-paste0(rowlabel," \u00b7 ",seq_along(rowlabel))
  treatments<-unique(as.character(cf$treatment))
  default_colours<-c("#0072B2","#D55E00","#009E73","#CC79A7","#E69F00","#56B4E9")
  colours<-stats::setNames(rep(default_colours,length.out=length(treatments)),treatments)
  if(length(treatments)>length(default_colours)) colours<-stats::setNames(grDevices::hcl.colors(length(treatments),"Dark 3"),treatments)
  if(!is.null(palette)) {
    if(!is.character(palette) || is.null(names(palette)) || anyDuplicated(names(palette)) || !all(treatments %in% names(palette)))
      stop("palette must supply one named colour for every treatment.")
    colours<-palette[treatments]
  }
  colours<-c(colours,".control"="#303840")
  dots<-means<-bars<-annotations<-list()
  summary<-cf
  summary$MI_control_sd<-summary$MI_treatment_sd<-summary$coefficient_sd<-NA_real_
  summary$statistical_scope<-"descriptive; coefficient SD conditional on matching control mean"
  summary$metadata_status<-"not independently verified"
  sd_text<-function(x,digits=2) if(is.finite(x)) formatC(x,format="f",digits=digits) else "unavailable"
  panel_a<-"A  Plate melanization index"
  panel_b<-"B  Matched melanization coefficient"
  for(i in seq_len(nrow(cf))) {
    pm<-mc$plate_means
    sel<-rep(TRUE,nrow(pm))
    for(nm in mc$settings$by) sel<-sel & pm[[nm]]==cf[[nm]][i]
    p<-pm[sel & pm$treatment %in% c(control,cf$treatment[i]),,drop=FALSE]
    # Deterministic vertical separation keeps independent plate points visible.
    for(gr in unique(as.character(p$treatment))) {
      z<-p[p$treatment==gr,,drop=FALSE];z<-z[order(z$plate_id),,drop=FALSE]
      offset<-if(gr==control) {
        if(nrow(z)>1) seq(-0.18,-0.06,length.out=nrow(z)) else -0.12
      } else {
        if(nrow(z)>1) seq(0,0.16,length.out=nrow(z)) else 0.08
      }
      series<-if(gr==control) "Control plates" else "Treatment plates"
      dots[[length(dots)+1L]]<-data.frame(row=i,y=i+offset,x=z$MI_plate,panel=panel_a,series=series,key=if(gr==control) ".control" else gr)
      if(gr!=control) dots[[length(dots)+1L]]<-data.frame(row=i,y=i+offset,x=z$MI_plate/cf$MI_control_mean[i],panel=panel_b,series="Treatment plates",key=gr)
    }
    cs<-stats::sd(p$MI_plate[p$treatment==control])
    ts<-stats::sd(p$MI_plate[p$treatment==cf$treatment[i]])
    rs<-ts/cf$MI_control_mean[i]
    summary$MI_control_sd[i]<-cs;summary$MI_treatment_sd[i]<-ts;summary$coefficient_sd[i]<-rs
    # Summary diamonds sit beneath raw plates, preserving their distinct shapes.
    means[[i]]<-data.frame(row=i,y=i-0.28,x=c(cf$MI_treatment_mean[i],cf$melanization_coefficient[i]),
      panel=c(panel_a,panel_b),series="Treatment plates",key=as.character(cf$treatment[i]))
    bars[[i]]<-data.frame(y=c(i-0.28,i-0.28,i-0.12),x=c(cf$MI_treatment_mean[i],cf$melanization_coefficient[i],cf$MI_control_mean[i]),
      sd=c(ts,rs,cs),panel=c(panel_a,panel_b,panel_a),key=c(rep(as.character(cf$treatment[i]),2),".control"))
    annotations[[i]]<-data.frame(y=i+0.32,panel=c(panel_a,panel_b),
      text=c(paste0("C ",sd_text(cf$MI_control_mean[i])," (SD ",sd_text(cs),") | T ",
                    sd_text(cf$MI_treatment_mean[i])," \u00b1 ",sd_text(ts)),
             paste0("MC ",sd_text(cf$melanization_coefficient[i],3)," \u00b1 ",sd_text(rs,3))))
  }
  d<-do.call(rbind,dots);a<-do.call(rbind,means)
  d$series<-factor(d$series,levels=c("Control plates","Treatment plates"));a$series<-factor(a$series,levels=levels(d$series))
  intervals<-do.call(rbind,bars);intervals<-intervals[is.finite(intervals$sd),,drop=FALSE]
  ann<-do.call(rbind,annotations)
  for(panel in c(panel_a,panel_b)) ann$x[ann$panel==panel]<-mean(range(d$x[d$panel==panel]))
  refs<-data.frame(panel=panel_b,x=1)
  note<-if(preview) "PROVISIONAL: verify metadata, masks and calibration." else "Descriptive matched plate comparison."
  if(mc$qc_review$status!="confirmed") note<-paste0(note," QC UNCONFIRMED: inspect masks and calibration before interpretation.")
  caption<-paste0(note,"\nSquares: control plates; circles: treatment plates; lower diamonds: treatment means.",
    "\nBars and \u00b1 values: one between-plate SD, not a confidence interval. C = control; T = treatment; MC = T/C.",
    "\nMC SD describes treatment spread conditional on its own set's control mean; shared-control uncertainty is not included.",
    if(any(cf$n_control_plates<2)) "\nSingle-control SD is unavailable. No p-values or significance tests are shown." else
      "\nDescriptive summaries only; no p-values or significance tests are shown.")
  caption<-paste(vapply(strsplit(caption,"\n",fixed=TRUE)[[1]],function(z) paste(strwrap(z,width=112),collapse="\n"),character(1)),collapse="\n")
  countlabels<-paste0(rowlabel,"\n",cf$n_treatment_plates," treatment / ",cf$n_control_plates," control plates")
  plt<-ggplot2::ggplot(d,ggplot2::aes(x=.data$x,y=.data$y,colour=.data$key,shape=.data$series,fill=.data$key))+
    ggplot2::geom_vline(data=refs,ggplot2::aes(xintercept=.data$x),colour="#8B9399",linewidth=0.4,linetype="dashed")+
    ggplot2::geom_point(size=2.6,stroke=0.8,alpha=1)+
    ggplot2::geom_point(data=a,shape=18,size=2.7,show.legend=FALSE)+
    ggplot2::geom_segment(data=intervals,ggplot2::aes(x=.data$x-.data$sd,xend=.data$x+.data$sd,y=.data$y,yend=.data$y,colour=.data$key),inherit.aes=FALSE,linewidth=0.65)+
    ggplot2::geom_text(data=ann,ggplot2::aes(x=.data$x,y=.data$y,label=.data$text),inherit.aes=FALSE,size=2.25,colour="#303840")+
    ggplot2::facet_wrap(~panel,scales="free_x",nrow=1,
      labeller=ggplot2::labeller(panel=function(x) vapply(x,function(z)
        paste(strwrap(z,width=26),collapse="\n"),character(1))))+
    ggplot2::scale_y_continuous(breaks=seq_len(nrow(cf)),labels=countlabels,limits=c(0.5,nrow(cf)+0.5))+
    ggplot2::scale_colour_manual(values=colours,guide="none")+
    ggplot2::scale_fill_manual(values=colours,guide="none")+
    ggplot2::scale_shape_manual(values=c("Control plates"=0,"Treatment plates"=21))+
    ggplot2::guides(shape=ggplot2::guide_legend(override.aes=list(colour=c("#303840","#0072B2"),fill=c("white","#0072B2"))))+
    ggplot2::labs(x=NULL,y=NULL,colour=NULL,shape=NULL,caption=caption)+
    ggplot2::theme_classic(base_size=9,base_family="sans")+
    ggplot2::theme(strip.background=ggplot2::element_blank(),strip.text=ggplot2::element_text(face="bold",hjust=0,size=10),
      axis.line.y=ggplot2::element_blank(),axis.ticks.y=ggplot2::element_blank(),
      axis.text=ggplot2::element_text(colour="#263238"),axis.text.y=ggplot2::element_text(size=8),
      panel.grid.major.y=ggplot2::element_line(colour="#E8ECEE",linewidth=0.3),
      legend.position="top",legend.justification="left",plot.caption.position="plot",plot.caption=ggplot2::element_text(hjust=0,size=7,colour="#47535D"),
      plot.margin=ggplot2::margin(10,12,10,10),panel.spacing=grid::unit(14,"pt"))
  attr(plt,"FunMel_statistics")<-summary
  if(!is.null(file)) {
    if(length(file)!=1L || is.na(file) || !nzchar(file)) stop("file must be an output prefix.")
    if(is.null(height)) height<-max(5,3.2+0.65*nrow(cf))
    utils::write.csv(summary,paste0(file,"_statistics.csv"),row.names=FALSE)
    for(ext in c("pdf","svg","png")) ggplot2::ggsave(paste0(file,".",ext),plt,width=width,height=height,dpi=600,
      device=if(ext=="svg") grDevices::svg else if(ext=="pdf") grDevices::cairo_pdf else "png",bg="white")
    return(invisible(plt))
  }
  plt
}
