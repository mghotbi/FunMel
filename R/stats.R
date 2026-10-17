#' Compare colony measurements while accounting for plates
#'
#' Preserves the MycoHalo argument names. For MI with set_id metadata this
#' delegates to [assess_experiment()] so each treatment uses its own control.
#' For other outcomes, or a legacy single-set table, it fits the original
#' plate-aware comparison with lmerTest Satterthwaite inference instead of
#' the old ad hoc degrees of freedom. Multi-set assessment of MI should use
#' assess_experiment() directly. Never compare shared-denominator MC rows as
#' independent observations.
#' @param colonies Colony table.
#' @param response Numeric response column, default MI_mean.
#' @param group Treatment column.
#' @param plate Plate ID column.
#' @param reference Reference treatment; defaults to control if available.
#' @param method auto, mixed, or plate_means. auto chooses mixed with at least
#'   three plates per group, otherwise an explicit plate-mean model.
#' @param by Extra control-matching columns for matched MI assessment.
#' @param control Optional control label, alias of reference for matched MI.
#' @param require_qc Require explicit image QC approval for matched MI analysis.
#'   Default FALSE warns on unconfirmed recorded QC.
#' @return A list with model, coefficients, descriptives and status; matched
#'   MI results also contain the complete assessment and matched_coefficients.
#' @export
compare_melanization <- function(colonies,response="MI_mean",group="treatment",
                                 plate="plate_id",reference=NULL,
                                 method=c("auto","mixed","plate_means"),by=NULL,control=NULL,require_qc=FALSE) {
  method<-match.arg(method)
  if(!is.data.frame(colonies) || !all(c(response,group,plate) %in% names(colonies))) stop("Required comparison columns missing.")
  if(is.null(reference)) reference<-if(!is.null(control)) control else if("control" %in% colonies[[group]]) "control" else sort(unique(as.character(colonies[[group]])))[1]
  if(response=="MI_mean" && "set_id" %in% names(colonies)) {
    d<-colonies;d$treatment<-as.character(d[[group]]);d$plate_id<-as.character(d[[plate]])
    a<-assess_experiment(d,control=reference,by=by,require_qc=require_qc,method=if(method=="plate_means") "plate_means" else "mixed")
    tab<-a$overall_effects
    if(nrow(tab)) tab$term<-tab$treatment
    return(list(method=if(method=="plate_means") "matched plate means" else "matched mixed model",
                coefficients=tab,matched_coefficients=a$coefficients,model=a$model,
                descriptives=a$plate_means,assessment=a,status=a$status,icc=NA_real_))
  }
  if("set_id" %in% names(colonies) && length(unique(colonies$set_id))>1L)
    stop("For multi-set non-MI outcomes, specify a model for that outcome; do not pool the control sets.")
  d<-colonies[is.finite(colonies[[response]]),,drop=FALSE]
  if("is_target" %in% names(d)) d<-d[!is.na(d$is_target) & d$is_target,,drop=FALSE]
  if("detected" %in% names(d)) d<-d[!is.na(d$detected) & d$detected,,drop=FALSE]
  if(anyNA(d[c(group,plate)])) stop("Complete treatment and plate metadata.")
  d$.y<-d[[response]];d$.g<-stats::relevel(factor(d[[group]]),reference);d$.p<-factor(d[[plate]])
  if(any(vapply(split(d$.g,d$.p),function(z) length(unique(z))>1L,TRUE))) stop("A plate must belong to one treatment.")
  pm<-stats::aggregate(.y~.p+.g,data=d,FUN=mean)
  desc<-do.call(rbind,lapply(split(pm,pm$.g),function(z)
    data.frame(group=as.character(z$.g[1]),n_plates=nrow(z),mean=mean(z$.y),sd_between_plates=stats::sd(z$.y))))
  n<-table(pm$.g)
  if(length(n)<2L || any(n<2L)) {
    warning("Too few independent plates; descriptive results only.")
    return(list(method="descriptive",coefficients=data.frame(),descriptives=desc,model=NULL,status="insufficient_plate_replication",icc=NA_real_))
  }
  mixed<-method=="mixed" || (method=="auto" && min(n)>=3L && nrow(d)>nrow(pm))
  if(mixed) {
    fit<-lmerTest::lmer(.y~.g+(1|.p),data=d,REML=TRUE)
    if(lme4::isSingular(fit) || length(fit@optinfo$conv$lme4$messages)) {
      warning("Mixed fit needs diagnostic review; inferential table withheld.")
      return(list(method="mixed",coefficients=data.frame(),descriptives=desc,model=fit,status="model_diagnostic_failure",icc=NA_real_))
    }
    co<-summary(fit)$coefficients
    q<-stats::qt(.975,co[,"df"])
    tab<-data.frame(term=sub('^\\.g','',rownames(co)),estimate=co[,"Estimate"],se=co[,"Std. Error"],
                    df=co[,"df"],t=co[,"t value"],lower=co[,"Estimate"]-q*co[,"Std. Error"],
                    upper=co[,"Estimate"]+q*co[,"Std. Error"],p_value=co[,"Pr(>|t|)"],row.names=NULL)
    vc<-as.data.frame(lme4::VarCorr(fit));icc<-vc$vcov[vc$grp=='.p']/sum(vc$vcov)
  } else if(nlevels(pm$.g)==2L) {
    tt<-stats::t.test(.y~.g,data=pm);fit<-NULL;icc<-NA_real_
    tab<-data.frame(term=levels(pm$.g)[2],estimate=unname(tt$estimate[2]-tt$estimate[1]),
                    lower=-tt$conf.int[2],upper=-tt$conf.int[1],t=-unname(tt$statistic),
                    df=unname(tt$parameter),p_value=tt$p.value)
  } else {fit<-stats::lm(.y~.g,data=pm);tab<-as.data.frame(stats::anova(fit));icc<-NA_real_}
  list(method=if(mixed) "lmerTest mixed model" else "plate means",coefficients=tab,
       descriptives=desc,model=fit,status="ok",icc=icc)
}
