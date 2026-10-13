# Fully crossed synthetic design: three sets, three groups, 3 plates per group.
# No photographs, downloads or path edits required.
library(FunMel)
demo <- example_experiment(seed=42)
validate_metadata(demo$metadata)
print(with(demo$metadata,table(set_id,treatment)))
mc <- melanization_coefficient(demo$colonies)
assessment <- assess_experiment(demo$colonies,comparison_scope='common_sets')
print(mc$per_plate_coefficients)
print(assessment$overall_coefficients)
print(assessment$treatment_comparisons)
print(assessment$status)
example_output <- tempfile('FunMel_experiment_')
dir.create(example_output)
plot_treatment_comparison(demo,
  labels=c(fungus_A='Fungal partner A',bacterium_B='Bacterial partner B'),
  file=file.path(example_output,'matched_comparison'))
write.csv(mc$coefficients,file.path(example_output,'coefficients.csv'),row.names=FALSE)
saveRDS(assessment,file.path(example_output,'assessment.rds'))
writeLines(capture.output(sessionInfo()),file.path(example_output,'sessionInfo.txt'))
# Raw MI points, not coefficient ratios, are used in this model's contrasts.
# Review residuals and random-effect diagnostics whenever an inferential fit exists.
if(!is.null(assessment$model)) {
  grDevices::pdf(file.path(example_output,'residual_diagnostics.pdf'),width=7,height=3.5)
  op <- graphics::par(mfrow=c(1,2))
  plot(fitted(assessment$model),residuals(assessment$model),xlab='Fitted MI',ylab='Residual')
  abline(h=0,lty=2)
  qqnorm(residuals(assessment$model));qqline(residuals(assessment$model))
  graphics::par(op);grDevices::dev.off()
}
message('Synthetic comparison exports saved in: ',example_output)
