# tests/testthat/helper.R
# Shared fixtures loaded automatically by testthat before every test file.

suppressPackageStartupMessages({
  library(metapropul)
})

# ── Load datasets ─────────────────────────────────────────────────────────────
data(dat_bcg, package = "metapropul")
data(Olkin95, package = "metapropul")
data(dat_normand1999, package = "metapropul")

# dat_bcg columns:
#   tpos/tneg = TB pos/neg in BCG (treatment) arm
#   cpos/cneg = TB pos/neg in control arm
#   npos      = total in treatment arm (= tpos + tneg)
#   author, year, ablat, alloc, region
# n.c (control total) is not stored — compute it once.
dat_bcg$ncon <- dat_bcg$cpos + dat_bcg$cneg

# Olkin95 columns: author, year, event.e, n.e, event.c, n.c
# dat_normand1999 columns: study, source, n1i, m1i, sd1i, n2i, m2i, sd2i

# ── Ratio fixtures ────────────────────────────────────────────────────────────

.fix_ratio_events <- meta_ratio(
  data     = dat_bcg,
  event.e  = "tpos", n.e = "npos",
  event.c  = "cpos", n.c = "ncon",
  studylab = "author",
  measure  = "OR"
)

.fix_ratio_fixed <- meta_ratio(
  data     = dat_bcg,
  event.e  = "tpos", n.e = "npos",
  event.c  = "cpos", n.c = "ncon",
  studylab = "author",
  measure  = "OR",
  model    = "fixed"
)

.fix_ratio_rr <- meta_ratio(
  data     = dat_bcg,
  event.e  = "tpos", n.e = "npos",
  event.c  = "cpos", n.c = "ncon",
  studylab = "author",
  measure  = "RR"
)

# Pre-computed OR + 95% CI — exclude rows with zero cells
dat_bcg$or_se <- sqrt(1 / dat_bcg$tpos + 1 / dat_bcg$tneg +
  1 / dat_bcg$cpos + 1 / dat_bcg$cneg)
dat_bcg$or_est <- (dat_bcg$tpos / dat_bcg$tneg) /
  (dat_bcg$cpos / dat_bcg$cneg)
dat_bcg$or_lo <- dat_bcg$or_est * exp(-1.96 * dat_bcg$or_se)
dat_bcg$or_hi <- dat_bcg$or_est * exp(1.96 * dat_bcg$or_se)

bcg_clean <- dat_bcg[
  is.finite(log(dat_bcg$or_est)) &
    is.finite(log(dat_bcg$or_lo)) &
    is.finite(log(dat_bcg$or_hi)),
]

.fix_ratio_precomp <- meta_ratio(
  data = bcg_clean,
  effect = "or_est", lower = "or_lo", upper = "or_hi",
  studylab = "author",
  measure = "OR"
)

.fix_ratio_subgroup <- meta_ratio(
  data     = dat_bcg,
  event.e  = "tpos", n.e = "npos",
  event.c  = "cpos", n.c = "ncon",
  studylab = "author",
  measure  = "OR",
  subgroup = "alloc"
)

# Large k=70 (Olkin95) — triggers k>30 metagen path
.fix_ratio_large <- meta_ratio(
  data     = Olkin95,
  event.e  = "event.e", n.e = "n.e",
  event.c  = "event.c", n.c = "n.c",
  studylab = "author",
  measure  = "OR"
)

# ── Mean fixtures ─────────────────────────────────────────────────────────────

.fix_mean <- meta_mean(
  data     = dat_normand1999,
  mean.e   = "m1i", sd.e = "sd1i", n.e = "n1i",
  mean.c   = "m2i", sd.c = "sd2i", n.c = "n2i",
  studylab = "source",
  measure  = "MD"
)

.fix_mean_smd <- meta_mean(
  data     = dat_normand1999,
  mean.e   = "m1i", sd.e = "sd1i", n.e = "n1i",
  mean.c   = "m2i", sd.c = "sd2i", n.c = "n2i",
  studylab = "source",
  measure  = "SMD"
)

.fix_mean_fixed <- meta_mean(
  data     = dat_normand1999,
  mean.e   = "m1i", sd.e = "sd1i", n.e = "n1i",
  mean.c   = "m2i", sd.c = "sd2i", n.c = "n2i",
  studylab = "source",
  model    = "fixed"
)

# Pre-computed MD path
dat_normand1999$md <- dat_normand1999$m1i - dat_normand1999$m2i
dat_normand1999$se_md <- sqrt(dat_normand1999$sd1i^2 / dat_normand1999$n1i +
  dat_normand1999$sd2i^2 / dat_normand1999$n2i)
dat_normand1999$md_lo <- dat_normand1999$md - 1.96 * dat_normand1999$se_md
dat_normand1999$md_hi <- dat_normand1999$md + 1.96 * dat_normand1999$se_md

.fix_mean_precomp <- meta_mean(
  data = dat_normand1999,
  effect = "md", lower = "md_lo", upper = "md_hi",
  studylab = "source"
)

# Subgroup — split by row parity for structural testing
dat_normand1999$grp <- rep(c("A", "B"), length.out = nrow(dat_normand1999))

.fix_mean_subgroup <- meta_mean(
  data     = dat_normand1999,
  mean.e   = "m1i", sd.e = "sd1i", n.e = "n1i",
  mean.c   = "m2i", sd.c = "sd2i", n.c = "n2i",
  studylab = "source",
  subgroup = "grp"
)

# ── Proportion fixtures ───────────────────────────────────────────────────────

.fix_prop <- meta_prop(
  data     = dat_bcg,
  event    = "tpos",
  n        = "npos",
  studylab = "author"
)

.fix_prop_fixed <- meta_prop(
  data     = dat_bcg,
  event    = "tpos",
  n        = "npos",
  studylab = "author",
  model    = "fixed"
)

.fix_prop_pft <- meta_prop(
  data     = dat_bcg,
  event    = "tpos",
  n        = "npos",
  studylab = "author",
  sm       = "PFT"
)

.fix_prop_subgroup <- meta_prop(
  data     = dat_bcg,
  event    = "tpos",
  n        = "npos",
  studylab = "author",
  subgroup = "alloc"
)

.fix_prop_no_pi <- meta_prop(
  data                = dat_bcg,
  event               = "tpos",
  n                   = "npos",
  studylab            = "author",
  prediction_interval = FALSE
)

# ── Regression fixtures ───────────────────────────────────────────────────────

.fix_reg_prop <- meta_reg(
  meta_object = .fix_prop,
  data        = dat_bcg,
  moderators  = ~ablat,
  studylab    = "author"
)

.fix_reg_mean <- meta_reg(
  meta_object = .fix_mean,
  data        = dat_normand1999,
  moderators  = ~n1i,
  studylab    = "source"
)

.fix_reg_ratio <- meta_reg(
  meta_object = .fix_ratio_events,
  data        = dat_bcg,
  moderators  = ~ablat,
  studylab    = "author"
)
