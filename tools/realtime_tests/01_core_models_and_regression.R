## LET'S TEST METAPROPUL IN REAL TIME
## Script 1: core models, subgroups, object structure and meta-regression
## Open this file in RStudio and run one section at a time.

## Install once if required:
# install.packages(c("devtools", "dplyr", "meta", "metafor"))

## During development this loads the current source without reinstalling.
devtools::load_all()
library(dplyr)

## If testing the GitHub release instead:
# devtools::install_github("drrubesh/propulmeta", force = TRUE)
# library(metapropul)

###############################################################################
## 1. LOAD AND EXPLORE THE BUNDLED DATA
###############################################################################

data("Olkin95", package = "metapropul")
names(Olkin95)
head(Olkin95)
summary(Olkin95)

## Create a meaningful teaching subgroup.
Olkin95 <- Olkin95 |>
  mutate(year_cat = if_else(year < 1975, "Before 1975", "1975 onwards"))
table(Olkin95$year_cat, useNA = "ifany")

data("dat_bcg", package = "metapropul")
names(dat_bcg)
head(dat_bcg)
table(dat_bcg$alloc, useNA = "ifany")
table(dat_bcg$region, useNA = "ifany")

## The BCG dataset stores control cases and non-cases separately.
dat_bcg$n_control <- dat_bcg$cpos + dat_bcg$cneg

data("dat_normand1999", package = "metapropul")
names(dat_normand1999)
head(dat_normand1999)

## Construct a two-level subgroup for teaching purposes.
dat_normand1999 <- dat_normand1999 |>
  mutate(region = case_when(
    grepl("Montreal|Umea|Uppsala", source) ~ "Non-UK",
    TRUE ~ "UK"
  ))
table(dat_normand1999$region)

###############################################################################
## 2. META_RATIO(): ODDS RATIOS, RISK RATIOS AND OBJECT CONTENTS
###############################################################################

## Primary random-effects odds-ratio analysis using 70 studies.
ratio_or <- meta_ratio(
  data = Olkin95,
  event.e = "event.e", n.e = "n.e",
  event.c = "event.c", n.c = "n.c",
  studylab = "author",
  measure = "OR",
  model = "random",
  duplicate_action = "make_unique"
)

summary(ratio_or)
ratio_or

## Explore the returned object. These components support later plots/tables.
names(ratio_or)
ratio_or$meta
head(ratio_or$table)
head(ratio_or$influence.analysis)
ratio_or$model
ratio_or$measure
ratio_or$tau_method
ratio_or$ci_method
ratio_or$settings
ratio_or$label_audit
ratio_or$exclusion_log
class(ratio_or)
class(ratio_or$meta)
class(ratio_or$table)

## Omit studylab: the package should assign study identifiers.
ratio_auto_labels <- meta_ratio(
  Olkin95, "event.e", "n.e", "event.c", "n.c",
  measure = "OR"
)
head(ratio_auto_labels$table)

## Omit measure and model: defaults should be random-effects OR.
ratio_defaults <- meta_ratio(
  Olkin95, "event.e", "n.e", "event.c", "n.c",
  studylab = "author", duplicate_action = "make_unique"
)
summary(ratio_defaults)

## Fixed-effect sensitivity analysis.
ratio_fixed <- meta_ratio(
  Olkin95, "event.e", "n.e", "event.c", "n.c",
  studylab = "author", measure = "OR", model = "fixed",
  duplicate_action = "make_unique"
)
summary(ratio_fixed)

## Risk ratio rather than odds ratio.
ratio_rr <- meta_ratio(
  Olkin95, "event.e", "n.e", "event.c", "n.c",
  studylab = "author", measure = "RR", model = "random",
  duplicate_action = "make_unique"
)
summary(ratio_rr)

## Try a different tau estimator and Knapp-Hartung interval.
ratio_pm <- meta_ratio(
  Olkin95, "event.e", "n.e", "event.c", "n.c",
  studylab = "author", measure = "OR",
  tau_method = "PM", ci_method = "HK",
  duplicate_action = "make_unique"
)
summary(ratio_pm)

###############################################################################
## 3. META_RATIO() SUBGROUPS
###############################################################################

ratio_subgroup <- meta_ratio(
  Olkin95, "event.e", "n.e", "event.c", "n.c",
  studylab = "author", subgroup = "year_cat",
  measure = "OR", model = "random",
  duplicate_action = "make_unique"
)
summary(ratio_subgroup)
ratio_subgroup$meta.subgroup.summary
ratio_subgroup$subgroup_test
table_subgroups(ratio_subgroup)
table_subgroups(ratio_subgroup, output = "data")

## Check fixed-effect subgroup behaviour separately.
ratio_subgroup_fixed <- meta_ratio(
  Olkin95, "event.e", "n.e", "event.c", "n.c",
  studylab = "author", subgroup = "year_cat",
  model = "fixed", duplicate_action = "make_unique"
)
summary(ratio_subgroup_fixed)
ratio_subgroup_fixed$subgroup_test

###############################################################################
## 4. PRE-COMPUTED EFFECTS AND CONFIDENCE INTERVALS
###############################################################################

## Simulate the common situation where a paper supplies only OR and 95% CI.
Olkin95_effects <- Olkin95 |>
  mutate(
    odds_ratio = (event.e / (n.e - event.e)) /
      (event.c / (n.c - event.c)),
    se_log_or = sqrt(
      1 / event.e + 1 / (n.e - event.e) +
        1 / event.c + 1 / (n.c - event.c)
    ),
    lower = exp(log(odds_ratio) - 1.96 * se_log_or),
    upper = exp(log(odds_ratio) + 1.96 * se_log_or)
  )
head(Olkin95_effects)

ratio_precomputed <- meta_ratio(
  data = Olkin95_effects,
  effect = "odds_ratio", lower = "lower", upper = "upper",
  studylab = "author", measure = "OR", model = "random",
  duplicate_action = "make_unique"
)
summary(ratio_precomputed)
ratio_precomputed

## The same reported effects can be supplied directly as log(OR) and SE.
Olkin95_effects$log_odds_ratio <- log(Olkin95_effects$odds_ratio)
ratio_log_se <- meta_ratio(
  data = Olkin95_effects,
  effect = "log_odds_ratio", se = "se_log_or", effect_scale = "log",
  studylab = "author", measure = "OR", model = "random",
  duplicate_action = "make_unique"
)
summary(ratio_log_se)

## Compare pooled estimates from raw and reconstructed inputs.
c(raw_events = exp(ratio_or$meta$TE.random),
  precomputed = exp(ratio_precomputed$meta$TE.random),
  log_effect_se = exp(ratio_log_se$meta$TE.random))

###############################################################################
## 5. META_MEAN(): MD, SMD, FIXED/RANDOM AND SUBGROUPS
###############################################################################

mean_md <- meta_mean(
  dat_normand1999,
  mean.e = "m1i", sd.e = "sd1i", n.e = "n1i",
  mean.c = "m2i", sd.c = "sd2i", n.c = "n2i",
  studylab = "source", measure = "MD", model = "random",
  duplicate_action = "make_unique"
)
summary(mean_md)
mean_md
names(mean_md)
head(mean_md$table)
stopifnot(is.null(mean_md$meta.subgroup.summary)) # no implicit subgroup

mean_md_fixed <- meta_mean(
  dat_normand1999,
  "m1i", "sd1i", "n1i", "m2i", "sd2i", "n2i",
  studylab = "source", measure = "MD", model = "fixed",
  duplicate_action = "make_unique"
)
summary(mean_md_fixed)

mean_smd <- meta_mean(
  dat_normand1999,
  "m1i", "sd1i", "n1i", "m2i", "sd2i", "n2i",
  studylab = "source", measure = "SMD", model = "random",
  duplicate_action = "make_unique"
)
summary(mean_smd)

mean_subgroup <- meta_mean(
  dat_normand1999,
  "m1i", "sd1i", "n1i", "m2i", "sd2i", "n2i",
  studylab = "source", subgroup = "region",
  measure = "MD", model = "random",
  duplicate_action = "make_unique"
)
summary(mean_subgroup)
mean_subgroup$meta.subgroup.summary
mean_subgroup$subgroup_test
table_subgroups(mean_subgroup)

###############################################################################
## 6. META_PROP(): LOGIT PRIMARY MODEL, GLMM AND SUBGROUPS
###############################################################################

prop_logit <- meta_prop(
  dat_bcg, event = "tpos", n = "npos", studylab = "author",
  model = "random", sm = "PLOGIT",
  duplicate_action = "make_unique"
)
summary(prop_logit)
prop_logit
names(prop_logit)
head(prop_logit$table)
stopifnot(is.null(prop_logit$meta.subgroup.summary)) # no implicit subgroup

prop_fixed <- meta_prop(
  dat_bcg, "tpos", "npos", studylab = "author",
  model = "fixed", duplicate_action = "make_unique"
)
summary(prop_fixed)

## GLMM is available for random-effects logit analyses.
prop_glmm <- meta_prop(
  dat_bcg, "tpos", "npos", studylab = "author",
  model = "random", sm = "PLOGIT", pool_method = "glmm",
  duplicate_action = "make_unique"
)
summary(prop_glmm)

prop_subgroup <- meta_prop(
  dat_bcg, "tpos", "npos", studylab = "author",
  subgroup = "region", model = "random",
  duplicate_action = "make_unique"
)
summary(prop_subgroup)
prop_subgroup$meta.subgroup.summary
prop_subgroup$subgroup_test
table_subgroups(prop_subgroup)

## Freeman-Tukey is retained for sensitivity analysis and should warn.
prop_pft <- meta_prop(
  dat_bcg, "tpos", "npos", studylab = "author",
  sm = "PFT", model = "fixed", duplicate_action = "make_unique"
)
summary(prop_pft)

###############################################################################
## 7. META-REGRESSION: UNIVARIABLE, MULTIVARIABLE AND INTERACTION
###############################################################################

reg_ratio_year <- meta_reg(
  meta_object = ratio_or, data = Olkin95,
  moderators = ~ year, studylab = "author",
  center = "year", test = "knha"
)
summary(reg_ratio_year)
reg_ratio_year
names(reg_ratio_year)

reg_ratio_multi <- meta_reg(
  ratio_or, Olkin95, ~ year + year_cat, "author",
  reference_levels = c(year_cat = "Before 1975"),
  center = "year", test = "knha"
)
summary(reg_ratio_multi)
table_meta_reg(reg_ratio_multi)

reg_ratio_interaction <- meta_reg(
  ratio_or, Olkin95, ~ year * year_cat, "author",
  reference_levels = c(year_cat = "Before 1975"),
  scale = "year", min_studies_per_parameter = 5
)
summary(reg_ratio_interaction)

reg_mean_region <- meta_reg(
  mean_md, dat_normand1999, ~ region, "source",
  reference_levels = c(region = "UK")
)
summary(reg_mean_region)

reg_prop_region <- meta_reg(
  prop_logit, dat_bcg, ~ region, "author",
  reference_levels = c(region = "Asia/Africa")
)
summary(reg_prop_region)

###############################################################################
## 8. PREDICTION AND META-REGRESSION DIAGNOSTICS
###############################################################################

predicted_years <- predict_meta_reg(
  reg_ratio_year,
  newdata = data.frame(year = c(1960, 1975, 1990)),
  scale = "response"
)
predicted_years

ratio_diagnostics <- diagnose_meta_reg(reg_ratio_multi)
names(ratio_diagnostics)
head(ratio_diagnostics$studies)
ratio_diagnostics$collinearity
ratio_diagnostics$joint_test
ratio_diagnostics$flags

## End of script 1. Keep these objects in the Environment for script 2.
