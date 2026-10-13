# Bundled 14-day measured dataset: five sets, 1 control + 3 treatment plates/set.
# This uses bundled measured data; original photographs need not be downloaded.
# Folder-derived treatment labels remain provisional, not confirmed biology.
library(FunMel)
metadata <- read.csv(system.file('extdata','14_day_example','metadata.csv',package='FunMel'),stringsAsFactors=FALSE)
colonies <- read.csv(system.file('extdata','14_day_example','colonies.csv',package='FunMel'),stringsAsFactors=FALSE)
plates <- read.csv(system.file('extdata','14_day_example','plates.csv',package='FunMel'),stringsAsFactors=FALSE)
validate_metadata(metadata)
print(with(metadata,table(set_id,treatment)))
plate_means <- aggregate(MI_mean ~ plate_id + set_id + treatment,data=colonies,FUN=mean)
print(plate_means)
example_output <- tempfile('FunMel_14_day_case_study_')
dir.create(example_output)
write.csv(metadata,file.path(example_output,'metadata_for_review.csv'),row.names=FALSE)
write.csv(plate_means,file.path(example_output,'plate_means.csv'),row.names=FALSE)
plot_treatment_comparison(list(colonies=colonies,failed=data.frame()),preview=TRUE,
                         file=file.path(example_output,'case_study_comparison_PREVIEW'))
# Automatic final coefficients deliberately remain blocked while assignments
# and imaging quality are unconfirmed. Never change flags just to obtain output.
message('Design: 1 control + 3 treatment plates per set; 4 target colonies per plate.')
message('Metadata identities and calibration/masks need review before finalization.')
message('Original-image analysis: scripts/analyse_14_day_archive.R.')
message('After review: scripts/finalize_14_day_review.R, or finalize_analysis() on your saved batch.')
message('The current model requires replicated control cells for inferential comparisons; this example is descriptive.')
message('Real-data preview and review metadata saved in: ',example_output)
