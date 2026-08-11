## METAPROPUL FOREST-PLOT VISUAL VALIDATION GALLERY
## Run from the package root. Outputs are deliberately excluded from builds.

required <- c("devtools", "meta", "metafor")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) stop("Install required packages: ", paste(missing, collapse = ", "))

devtools::load_all(quiet = TRUE)

output_root <- file.path(getwd(), "manual-test-output", "forest-validation")
figure_dir <- file.path(output_root, "figures")
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

data(dat_bcg, package = "metapropul")
data(Olkin95, package = "metapropul")
data(dat_normand1999, package = "metapropul")

set.seed(20260809)

make_ratio <- function(k, model = "random") {
  idx <- sample(seq_len(nrow(Olkin95)), k, replace = k > nrow(Olkin95))
  d <- Olkin95[idx, , drop = FALSE]
  d$validation_study <- sprintf("Ratio study %03d: %s", seq_len(k), d$author)
  meta_ratio(d, event.e = "event.e", n.e = "n.e", event.c = "event.c",
    n.c = "n.c", studylab = "validation_study", measure = "OR",
    model = model, duplicate_action = "make_unique", ci_method = "classic")
}

make_mean <- function(k) {
  idx <- sample(seq_len(nrow(dat_normand1999)), k,
    replace = k > nrow(dat_normand1999))
  d <- dat_normand1999[idx, , drop = FALSE]
  d$validation_study <- sprintf("Mean study %03d: %s", seq_len(k), d$source)
  meta_mean(d, mean.e = "m1i", sd.e = "sd1i", n.e = "n1i",
    mean.c = "m2i", sd.c = "sd2i", n.c = "n2i",
    studylab = "validation_study", measure = "MD",
    duplicate_action = "make_unique", ci_method = "classic")
}

make_prop <- function(k) {
  idx <- sample(seq_len(nrow(dat_bcg)), k, replace = k > nrow(dat_bcg))
  d <- dat_bcg[idx, , drop = FALSE]
  d$validation_study <- sprintf("Proportion study %03d: %s", seq_len(k), d$author)
  meta_prop(d, event = "tpos", n = "npos", studylab = "validation_study",
    duplicate_action = "make_unique", ci_method = "classic")
}

manifest <- list()
add_manifest <- function(id, family, studies, scenario, file, expected) {
  manifest[[length(manifest) + 1L]] <<- data.frame(
    id = id, family = family, studies = studies, scenario = scenario,
    file = file, expected = expected, stringsAsFactors = FALSE
  )
}

save_forest <- function(id, object, family, studies, scenario,
                        preview = studies <= 50L, fun = forest_meta, ...) {
  pdf_name <- paste0(id, ".pdf")
  pdf_path <- file.path(figure_dir, pdf_name)
  fun(object, save_as = "pdf", filename = pdf_path, ...)
  if (preview) {
    png_name <- paste0(id, ".png")
    png_path <- file.path(figure_dir, png_name)
    fun(object, save_as = "png", filename = png_path, ...)
  }
  add_manifest(id, family, studies, scenario, file.path("figures", pdf_name),
    "Readable rows; aligned columns; separated axis and statistics; no default title")
}

## A single study must be rejected clearly rather than plotted as a pooled
## meta-analysis.
one_study_message <- tryCatch({
  make_prop(1)
  "UNEXPECTED: one-study model was fitted"
}, error = function(e) paste("Expected validation error:", conditionMessage(e)))
add_manifest("one-study-guardrail", "All", 1L, "Minimum-study validation",
  "", one_study_message)

## Core study-count matrix.
study_counts <- c(2L, 10L, 50L, 100L, 200L)
for (k in study_counts) {
  save_forest(sprintf("ratio-k%03d", k), make_ratio(k), "Ratio", k,
    "Random-effects odds ratio")
  save_forest(sprintf("mean-k%03d", k), make_mean(k), "Mean", k,
    "Random-effects mean difference")
  save_forest(sprintf("prop-k%03d", k), make_prop(k), "Proportion", k,
    "Random-effects logit proportion")
}

## Fixed effects and explicit titles: the first must remain untitled and the
## second must show exactly the supplied heading.
ratio_fixed <- make_ratio(10, model = "fixed")
save_forest("ratio-fixed-k010", ratio_fixed, "Ratio", 10L,
  "Fixed-effect model")
save_forest("ratio-explicit-title-k010", make_ratio(10), "Ratio", 10L,
  "Explicit user title", title = "User-supplied validation title")

## Subgroups from bundled data, including a singleton subgroup.
prop_subgroup <- suppressWarnings(meta_prop(dat_bcg, event = "tpos", n = "npos",
  studylab = "author",
  subgroup = "region", singleton_action = "retain",
  duplicate_action = "make_unique", ci_method = "classic"))
save_forest("prop-subgroups-bcg", prop_subgroup, "Proportion",
  nrow(dat_bcg), "Four region subgroups including a singleton")

## Influence and cumulative layouts use the same fitted built-in-data model.
prop_base <- suppressWarnings(meta_prop(dat_bcg, event = "tpos", n = "npos",
  studylab = "author",
  duplicate_action = "make_unique", ci_method = "classic"))
save_forest("prop-influence-bcg", prop_base, "Influence", nrow(dat_bcg),
  "Leave-one-out influence", fun = forest_influence)
save_forest("prop-cumulative-bcg", prop_base, "Cumulative", nrow(dat_bcg),
  "Cumulative meta-analysis", fun = forest_cumulative)

## Additional supported effect families.
cor_data <- data.frame(
  Study = paste("Correlation study", seq_len(10)),
  r = seq(-0.20, 0.45, length.out = 10),
  n = seq(80, 260, length.out = 10)
)
cor_fit <- meta_cor(cor_data, "r", "n", "Study", ci_method = "classic")
save_forest("correlation-k010", cor_fit, "Correlation", 10L,
  "Fisher-z correlation")

rate_data <- data.frame(
  Study = paste("Rate cohort", seq_len(10)),
  events = c(0, 1, 2, 4, 7, 9, 12, 18, 25, 31),
  person_time = seq(500, 5000, length.out = 10)
)
rate_fit <- meta_rate(rate_data, "events", "person_time", "Study",
  irscale = 1000, ci_method = "classic")
save_forest("rate-k010", rate_fit, "Incidence rate", 10L,
  "Events per 1000 person-years")

generic_data <- data.frame(
  Study = paste("Generic study", seq_len(10)),
  effect = seq(-0.4, 0.5, length.out = 10),
  se = seq(0.08, 0.20, length.out = 10)
)
generic_fit <- meta_generic(generic_data, "effect", se = "se",
  studylab = "Study", ci_method = "classic")
save_forest("generic-k010", generic_fit, "Generic", 10L,
  "Inverse-variance continuous effect")

## Edge cases: zero/all events, duplicate labels, missing values, and extreme
## proportions. The omitted missing row is retained in the audit trail.
edge <- data.frame(
  Study = c("Duplicate", "Duplicate", "Zero", "All", "Near zero",
    "Near one", "Missing"),
  event = c(1, 2, 0, 100, 1, 99, NA),
  total = rep(100, 7),
  subgroup = c("A", "A", "B", "B", "C", "C", "C")
)
edge_fit <- meta_prop(edge, event = "event", n = "total", studylab = "Study",
  subgroup = "subgroup",
  missing_action = "exclude", duplicate_action = "make_unique",
  singleton_action = "retain", ci_method = "classic")
save_forest("prop-edge-cases", edge_fit, "Proportion", 6L,
  "Missing, duplicate, zero, all-event, and extreme proportions")

manifest_df <- do.call(rbind, manifest)
utils::write.csv(manifest_df, file.path(output_root, "manifest.csv"),
  row.names = FALSE)

escape_html <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}

cards <- vapply(seq_len(nrow(manifest_df)), function(i) {
  row <- manifest_df[i, ]
  png <- file.path("figures", paste0(row$id, ".png"))
  visual <- if (file.exists(file.path(output_root, png))) {
    sprintf('<a href="%s"><img src="%s" loading="lazy" alt="%s"></a>',
      row$file, png, escape_html(row$scenario))
  } else if (nzchar(row$file)) {
    sprintf('<p><a class="pdf" href="%s">Open full-resolution PDF</a></p>', row$file)
  } else {
    ""
  }
  sprintf(paste0('<article><h2>%s</h2><p><strong>%s</strong> · k = %s</p>',
    '<p>%s</p>%s<p class="expected">Expected: %s</p></article>'),
    escape_html(row$id), escape_html(row$family), row$studies,
    escape_html(row$scenario), visual, escape_html(row$expected))
}, character(1))

html <- c(
  "<!doctype html><html><head><meta charset='utf-8'>",
  "<meta name='viewport' content='width=device-width,initial-scale=1'>",
  "<title>metapropul forest-plot validation</title>",
  "<style>body{font-family:system-ui,sans-serif;max-width:1500px;margin:auto;padding:2rem;color:#17212b}header{border-bottom:3px solid #176b87;margin-bottom:2rem}article{border:1px solid #ccd6dd;border-radius:10px;padding:1rem;margin:1.5rem 0;background:#fff}img{display:block;max-width:100%;height:auto;margin:1rem auto;border:1px solid #e5e7eb}.expected{background:#eef7f9;padding:.7rem}.pdf{font-weight:700;color:#075985}code{background:#f1f5f9;padding:.1rem .3rem}</style>",
  "</head><body><header><h1>metapropul forest-plot validation</h1>",
  paste0("<p>Generated ", format(Sys.time(), "%Y-%m-%d %H:%M %Z"),
    ". Titles are opt-in. Click previews for full PDFs.</p></header>"),
  cards,
  "</body></html>"
)
writeLines(html, file.path(output_root, "index.html"), useBytes = TRUE)

message("Forest validation gallery: ",
  normalizePath(file.path(output_root, "index.html"), mustWork = TRUE))
message("Scenarios generated: ", nrow(manifest_df))
