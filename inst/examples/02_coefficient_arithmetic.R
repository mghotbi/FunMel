# Exact worked example: 3 treatment plates / 1 independent control plate.
library(FunMel)
d <- data.frame(plate_id=rep(c('control_1','treatment_1','treatment_2','treatment_3'),each=4),
                set_id='batch_1',treatment=rep(c('control','fungus_A','fungus_A','fungus_A'),each=4),
                colony_id=rep(c('TL','TR','BR','BL'),4),
                MI_mean=rep(c(40,48,52,56),each=4))
mc <- melanization_coefficient(d)
print(mc$plate_means)                      # 40, 48, 52, 56
print(mc$per_plate_coefficients)           # 1.2, 1.3, 1.4
print(mc$coefficients)                     # mean(48,52,56)/40 = 1.3
stopifnot(abs(mc$coefficients$melanization_coefficient-1.3)<1e-12)
# The four control colonies are one control dish, not four control plates.
a <- suppressWarnings(assess_experiment(d))
print(a$status)                           # insufficient_plate_replication
# If that control's MI were 80 in another batch, that batch would use 80,
# never this batch's 40. MI ratios describe image darkness, not melanin content.
