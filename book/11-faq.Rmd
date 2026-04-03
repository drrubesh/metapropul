# FAQ & Troubleshooting {#faq}

## Installation

### Q: `remotes::install_github()` fails with an error about dependencies

Make sure you have a working C compiler and the required system libraries.
On macOS, install Xcode Command Line Tools:

```bash
xcode-select --install
```

On Ubuntu/Debian:

```bash
sudo apt-get install r-base-dev
```

If a specific dependency fails (e.g., `meta` or `metafor`), install it
directly first:

```r
install.packages(c("meta", "metafor", "metasens", "gt"))
remotes::install_github("drrubesh/metapropul")
```

---

## Data preparation

### Q: My data has study labels with special characters or duplicates — is that okay?

metapropul uses `make.unique()` internally to handle duplicate labels.
Special characters (accents, hyphens, parentheses) are generally fine.
Avoid purely numeric labels — use `"Smith 2020"` rather than `1`.

### Q: I have pre-computed log ORs from RevMan. How do I import them?

```r
result <- meta_ratio(
  data     = my_data,
  effect   = "log_or_column",    # log-scale
  lower    = "log_lower_ci",
  upper    = "log_upper_ci",
  studylab = "study_label",
  measure  = "OR"
)
```

Make sure the values are on the **log scale** (ln OR). metapropul will
back-transform for all output automatically.

### Q: My data has a mix of studies with events and studies with pre-computed ORs

metapropul requires consistent input within a single `meta_ratio()` call.
Split the analysis or standardise to pre-computed effects:

```r
# Compute log ORs from event data externally, then combine
library(dplyr)
my_data <- my_data |>
  mutate(log_or = log((event.e / (n.e - event.e)) / (event.c / (n.c - event.c))))
```

---

## Model fitting

### Q: When should I use `model = "fixed"` vs. `model = "random"`?

In almost all systematic reviews, use `model = "random"` (the default).
Fixed-effect models assume all studies estimate the *same* underlying effect,
which is rarely defensible. Random-effects models acknowledge between-study
heterogeneity.

### Q: What tau² estimator should I use?

The default `tau_method = "REML"` is the best overall choice. Some
considerations:

- `"PM"` (Paule-Mandel) is recommended when k < 5
- `"DL"` (DerSimonian-Laird) is traditional but downward-biased for τ²
- REML is preferred by most methodological guidelines including Cochrane

### Q: Should I use `ci_method = "HK"` or `ci_method = "classic"`?

Use `"HK"` (Hartung-Knapp, the default) for small meta-analyses (k < 20).
It produces more conservative, better-calibrated confidence intervals.
`"classic"` (Wald-type) CIs tend to be too narrow when k is small.

---

## Proportions

### Q: My proportions are near zero — which transformation should I use?

Use `sm = "PFT"` (Freeman-Tukey double arcsine) when proportions are
consistently below 0.10 or above 0.90, or when any study has zero events.
The logit (`"PLOGIT"`) is undefined for 0 or 1 and may be unstable near
those boundaries.

```r
result <- meta_prop(data, event = "events", n = "total", sm = "PFT")
```

### Q: `publication_bias()` fails on my `meta_prop` object

`publication_bias()` only supports `sm = "PLOGIT"` for proportion data.
If you used `sm = "PFT"`, re-fit with `sm = "PLOGIT"` for the bias assessment.

```r
# For publication bias testing only
result_logit <- meta_prop(data, event = "events", n = "total", sm = "PLOGIT")
publication_bias(result_logit)
```

---

## Forest plots

### Q: The forest plot is clipped / cut off in the RStudio Viewer

The Viewer pane has limited canvas space. Export to PDF instead:

```r
forest_meta(result, save_as = "pdf", filename = "forest.pdf")
```

For large k (> 40), also increase the height:

```r
forest_meta(result, save_as = "pdf", height = 16, width = 12)
```

### Q: Subgroup headers are missing or misaligned

Ensure every study has a non-`NA` value in the subgroup column:

```r
table(is.na(my_data$subgroup))   # should be all FALSE
```

Also verify the subgroup column is character or factor — not numeric.

### Q: I see `"2 22"` in the forest plot header

This is a known artefact when `metabin` objects are plotted with k > 30.
metapropul automatically patches this by converting to a `metagen` object
for plotting. If it persists after updating metapropul, file an issue on GitHub.

### Q: JAMA layout shows "Source" instead of my study labels

This is a fixed behaviour of `meta::forest.metagen()` with JAMA layout —
the label "Source" is hardcoded in the `meta` package. Use `layout = "RevMan5"`
if you need a custom column header.

---

## Publication bias

### Q: `publication_bias()` returned `invisible(NULL)` without running tests

This happens when k < 10. Tests have insufficient power below this threshold.
Use `doi_plot()` instead:

```r
doi_plot(result)
```

### Q: Trim-and-fill imputed 0 studies — does that mean no bias?

Not necessarily. Trim-and-fill only detects asymmetry in one direction.
Zero imputed studies means the funnel is roughly symmetric, but asymmetry
can have causes other than publication bias (e.g., clinical heterogeneity,
small-study effects). Always combine with Egger's test and clinical judgment.

---

## Meta-regression

### Q: I get `"Mismatch: N study label(s) not found"`

The study labels in `meta_object` must match exactly those in `data[[studylab]]`.
Common causes:

```r
# Check what labels the meta object has
result$meta$studlab

# Check what your data has
dat_bcg$author

# Diagnose mismatches
setdiff(result$meta$studlab, dat_bcg$author)
```

Fix trailing spaces, case differences, or punctuation differences.

### Q: R² analog is negative — is that a bug?

No. metapropul clamps negative R² values to 0. A negative R² analog means
the moderator increased τ² rather than explaining it — this can happen with
small k or a poor-fitting moderator.

### Q: `bubble_plot()` shows the y-axis on the log scale

This is correct and expected. The y-axis in a bubble plot from
`metafor::regplot()` is always on the model scale (log for ratio measures,
logit for proportions). Back-transformation is not applied to axes because
the linear regression line is only linear on the model scale.

---

## General

### Q: How do I cite metapropul?

```r
citation("metapropul")
```

Until the CRAN submission is accepted, cite the GitHub repository:

> Polani R (2025). *metapropul: A Practical Toolkit for Meta-Analysis in
> Systematic Reviews*. R package version 0.1.0.
> https://github.com/drrubesh/metapropul

### Q: I found a bug — where do I report it?

Please open an issue at:
<https://github.com/drrubesh/metapropul/issues>

Include a **minimal reproducible example** — the smallest code that
reproduces the problem — along with your R version and metapropul version:

```r
sessionInfo()
packageVersion("metapropul")
```

### Q: Can I use metapropul with RevMan data exports?

Yes. Export your studies as a CSV from RevMan, import with `readr::read_csv()`
or `readxl::read_excel()`, and pass to the appropriate `meta_*()` function.
Pre-computed log effect sizes and CIs are supported via the `effect`, `lower`,
`upper` arguments.

### Q: Does metapropul support network meta-analysis (NMA)?

Not currently. metapropul focuses on pairwise (two-arm) meta-analysis.
For NMA, consider the `gemtc` or `netmeta` packages.
