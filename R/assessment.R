#' Assess matched treatment effects within and across control sets
#'
#' First computes each set-specific arithmetic MI ratio using
#' [melanization_coefficient()]. Final descriptive coefficients average these
#' ratios equally across sets for each treatment. They are not ratios against
#' a pooled control. Inferential contrasts use raw colony MI, not ratios sharing
#' a control denominator.
#'
#' The mixed model is MI ~ 0 + set-treatment cell + (1 | plate). It estimates a
#' separate mean for every observed set-treatment cell and a random intercept
#' for each plate. Within-set contrasts subtract the matching control cell.
#' Overall contrasts average those differences equally over available sets.
#' Pairwise treatment comparisons subtract the average matched effects of each
#' treatment. Optionally restrict both treatments to their common sets.
#' These effects refer to the observed sets, not a population of unobserved sets.
#'
#' @param colonies Target colony table or batch result, with plate_id, set_id,
#'   treatment, colony_id and MI_mean. Raw pipeline results may include the
#'   central partner, which is excluded. Missing target values are errors.
#' @param control Label identifying control plates.
#' @param by Optional extra control-matching columns. A set cannot span different
#'   matching values. To pool multiple strains/days, explicitly justify that
#'   estimand; otherwise assess each biological context separately.
#' @param comparison_scope matched_effects compares each treatment's own matched
#'   effects across its observed sets; common_sets restricts both to shared sets.
#'   Different set coverage is flagged and needs a comparability justification.
#' @param pool_contexts Allow final pooling across different recorded strains,
#'   days or media. Default FALSE; subset to a context or explicitly justify pooling.
#' @param method mixed (lme4/lmerTest) or plate_means (ordinary linear model on
#'   one arithmetic MI per plate). The latter is an explicit alternative, not
#'   a silent fallback after a problematic mixed fit.
#' @param level Confidence level for unadjusted, contrast-wise intervals.
#' @param p_adjust Multiplicity method passed to p.adjust; default Holm.
#'   Applied separately to within_sets, overall_effects and treatment_comparisons.
#' @param require_qc Require recorded QC approval for every plate. Default FALSE
#'   warns on unconfirmed QC and retains its status in qc_review.
#' @return List with coefficients, overall_coefficients, plate_means,
#'   within_sets, overall_effects, treatment_comparisons, model, diagnostics,
#'   and status. Mixed-model contrasts use Satterthwaite degrees of freedom.
#'   Sparse designs, singular fits and convergence problems return descriptive
#'   coefficients with no inferential tables. At least two independent plates
#'   per cell are required as a computational guard, not a sufficiency guarantee.
#' @details Assumes independent plates, approximately normal residuals and common
#'   residual variance. Inspect model residuals and the actual design. Pixels,
#'   radial rings and repeat photographs are not biological replicates. The
#'   model does not handle repeated observations of a plate over time. Shared
#'   control uncertainty is retained through the model contrast covariance;
#'   do not test exported ratios as if they were independent observations.
#' @export
assess_experiment <- function(colonies, control="control", by=NULL,
                              method=c("mixed","plate_means"),level=.95,
                              p_adjust="holm",pool_contexts=FALSE,
                              comparison_scope=c("matched_effects","common_sets"),require_qc=FALSE) {
  method <- match.arg(method)
  comparison_scope <- match.arg(comparison_scope)
  if(length(level)!=1L || !is.finite(level) || level<=0 || level>=1) stop("level must be between 0 and 1.")
  if(!p_adjust %in% stats::p.adjust.methods) stop("Unknown p_adjust method.")
  if(is.list(colonies) && !is.data.frame(colonies) && !is.null(colonies$failed) && nrow(colonies$failed))
    stop("Some plates failed. Resolve failures before final assessment.")
  mc <- melanization_coefficient(colonies,control=control,by=by,require_qc=require_qc)
  if(any(mc$coefficients$status!="ok")) stop("Resolve unavailable within-set coefficients before final assessment.")
  df <- mc$target_data; pm <- mc$plate_means
  if(!is.logical(pool_contexts) || length(pool_contexts)!=1L || is.na(pool_contexts)) stop("pool_contexts must be TRUE or FALSE.")
  if(!pool_contexts) for(nm in recorded_context_columns(df))
    if(length(unique(df[[nm]]))>1L) stop("Multiple ",nm," contexts: assess separately or explicitly set pool_contexts=TRUE.")
  for(id in unique(pm$set_id)) for(nm in by)
    if(length(unique(pm[[nm]][pm$set_id==id]))!=1L) stop("Each set_id must have one ",nm," value.")
  overall <- do.call(rbind,lapply(split(mc$coefficients,mc$coefficients$treatment),function(z)
    data.frame(treatment=z$treatment[1],n_sets=nrow(z),
               mean_matched_coefficient=mean(z$melanization_coefficient),
               sd_across_sets=stats::sd(z$melanization_coefficient),
               sets=paste(as.character(z$set_id),collapse=";"),stringsAsFactors=FALSE)))
  rownames(overall)<-NULL
  ans <- list(qc_review=mc$qc_review,coefficients=mc$coefficients,overall_coefficients=overall,plate_means=pm,per_plate_coefficients=mc$per_plate_coefficients,
              within_sets=data.frame(),overall_effects=data.frame(),treatment_comparisons=data.frame(),
              model=NULL,diagnostics=list(method=method,level=level,p_adjust=p_adjust),status="descriptive_only")
  cells <- unique(pm[c("set_id","treatment")]);cells$cell<-sprintf("C%04d",seq_len(nrow(cells)))
  cell_for <- function(s,t) cells$cell[match(paste(s,t,sep="\r"),paste(cells$set_id,cells$treatment,sep="\r"))]
  # Labels may contain punctuation but not the internal key separator.
  if(any(grepl("\r",c(as.character(pm$set_id),as.character(pm$treatment)),fixed=TRUE))) stop("Metadata labels cannot contain carriage returns.")
  pm$.cell <- cell_for(pm$set_id,pm$treatment)
  counts <- table(factor(pm$.cell,levels=cells$cell))
  ans$diagnostics$plates_per_cell <- data.frame(cells,n_plates=as.integer(counts))
  if(any(counts<2L)) {
    ans$status <- "insufficient_plate_replication"
    warning("Fewer than two independent plates in a set-treatment cell: descriptive matched coefficients only.")
    return(ans)
  }
  warnings_seen <- character()
  if(method=="mixed") {
    df$.cell <- factor(cell_for(df$set_id,df$treatment),levels=cells$cell)
    df$.plate <- factor(df$plate_id);df$.y<-df$MI_mean
    if(nrow(df)<=nlevels(df$.plate)) {
      ans$status<-"no_within_plate_replication"
      warning("Mixed model needs within-plate replication. Explicitly choose method='plate_means' for one mean per plate.")
      return(ans)
    }
    fit <- withCallingHandlers(lmerTest::lmer(.y ~ 0 + .cell + (1 | .plate),data=df,REML=TRUE),
      warning=function(w){warnings_seen<<-c(warnings_seen,conditionMessage(w));invokeRestart("muffleWarning")})
    ans$model<-fit
    singular<-lme4::isSingular(fit,tol=1e-4)
    conv<-fit@optinfo$conv$lme4$messages
    optcode<-fit@optinfo$conv$opt
    ans$diagnostics$singular<-singular
    ans$diagnostics$convergence_messages<-conv
    ans$diagnostics$warnings<-warnings_seen
    ans$diagnostics$variance_components<-as.data.frame(lme4::VarCorr(fit))
    if(singular || length(conv) || any(optcode!=0) || length(warnings_seen)) {
      ans$status<-if(singular) "singular_fit" else "model_diagnostic_failure"
      warning("Mixed-model diagnostics need review; inferential tables withheld. Descriptive coefficients remain available.")
      return(ans)
    }
    beta<-lme4::fixef(fit)
    test <- function(L) {
      z<-lmerTest::contest1D(fit,L,confint=TRUE,level=level,ddf="Satterthwaite")
      data.frame(estimate=z[["Estimate"]],se=z[["Std. Error"]],df=z[["df"]],
        lower=z[["lower"]],upper=z[["upper"]],p_value=z[["Pr(>|t|)"]])
    }
  } else {
    pm$.cell<-factor(pm$.cell,levels=cells$cell);pm$.y<-pm$MI_plate
    fit<-stats::lm(.y~0+.cell,data=pm);ans$model<-fit;beta<-stats::coef(fit)
    if(anyNA(beta) || stats::df.residual(fit)<1L || !is.finite(summary(fit)$sigma) || summary(fit)$sigma<=0) {
      ans$status<-"degenerate_plate_mean_model";warning("Cannot estimate residual uncertainty.");return(ans)
    }
    test <- function(L) {
      est<-sum(L*beta);se<-sqrt(drop(t(L)%*%stats::vcov(fit)%*%L));dfree<-stats::df.residual(fit)
      q<-stats::qt((1+level)/2,dfree)
      data.frame(estimate=est,se=se,df=dfree,lower=est-q*se,upper=est+q*se,
                 p_value=2*stats::pt(-abs(est/se),dfree))
    }
  }
  vec <- function(s,t) {
    v<-stats::setNames(rep(0,length(beta)),names(beta))
    v[paste0(".cell",cell_for(s,t))]<-1
    v[paste0(".cell",cell_for(s,control))]<- -1
    unname(v)
  }
  contrasts<-mc$coefficients
  within<-lapply(seq_len(nrow(contrasts)),function(i)
    cbind(contrasts[i,c("set_id","treatment"),drop=FALSE],test(vec(contrasts$set_id[i],contrasts$treatment[i]))))
  treatments<-unique(as.character(contrasts$treatment))
  over<-lapply(treatments,function(trt){
    ss<-as.character(contrasts$set_id[contrasts$treatment==trt]);L<-Reduce(`+`,lapply(ss,vec,t=trt))/length(ss)
    cbind(data.frame(treatment=trt,n_sets=length(ss),sets=paste(ss,collapse=";")),test(L))
  })
  pairs<-list()
  if(length(treatments)>1L) for(pair in utils::combn(treatments,2,simplify=FALSE)) {
    s1<-as.character(contrasts$set_id[contrasts$treatment==pair[1]])
    s2<-as.character(contrasts$set_id[contrasts$treatment==pair[2]])
    common<-intersect(s1,s2)
    same<-setequal(s1,s2)
    if(comparison_scope=="common_sets") { s1<-common;s2<-common }
    base<-data.frame(treatment_1=pair[1],treatment_2=pair[2],n_common_sets=length(common),
                     sets_1=paste(s1,collapse=";"),sets_2=paste(s2,collapse=";"),
                     comparison_scope=comparison_scope,same_set_coverage=same)
    if(!length(s1) || !length(s2)) row<-cbind(base,status="no_common_sets",estimate=NA_real_,se=NA_real_,df=NA_real_,lower=NA_real_,upper=NA_real_,p_value=NA_real_) else {
      L1<-Reduce(`+`,lapply(s1,vec,t=pair[1]))/length(s1)
      L2<-Reduce(`+`,lapply(s2,vec,t=pair[2]))/length(s2)
      row<-cbind(base,status=if(same || comparison_scope=="common_sets") "ok" else "different_set_coverage",test(L1-L2))
    }
    pairs[[length(pairs)+1L]]<-row
  }
  finish<-function(rows){
    if(!length(rows)) return(data.frame())
    x<-do.call(rbind,rows);rownames(x)<-NULL;x$p_adjusted<-stats::p.adjust(x$p_value,method=p_adjust);x
  }
  ans$within_sets<-finish(within);ans$overall_effects<-finish(over);ans$treatment_comparisons<-finish(pairs)
  ans$diagnostics$estimand<-"MI difference from own control; equal weighting of observed sets; pairwise differences of matched effects; inspect set coverage"
  ans$status<-"ok"
  ans
}
