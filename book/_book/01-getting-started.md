# Getting Started {#getting-started}

## Installation

metapropul is currently available from GitHub while the CRAN submission is
being finalised.

```r
# install.packages("remotes")   # if needed
remotes::install_github("drrubesh/metapropul")
```

Once installed, load the package:

```r
library(metapropul)
```

<div class="callout-note">
<strong>Note</strong>
metapropul requires R ≥ 4.1.0 and automatically pulls in `meta`, `metafor`,
`metasens`, `gt`, `dplyr`, and `tibble` as dependencies.
</div>

---

## Built-in datasets

metapropul ships with several ready-to-use datasets so you can follow along
with every example in this book without needing your own data.

### `Olkin95` — Binary outcome, k = 70

Classic dataset of 70 studies used throughout the `meta` package documentation.
Suitable for `meta_ratio()` with OR or RR.

```r
data(Olkin95, package = "metapropul")
head(Olkin95)
#>          author year event.e  n.e event.c  n.c
#> 1  Auckland 1972 1972      36  532      60  538
#> 2    Block 1984 1984       1   69       5   61
#> ...
```

| Column | Description |
|--------|-------------|
| `author` | Study label |
| `year` | Publication year |
| `event.e` | Events in experimental arm |
| `n.e` | Total in experimental arm |
| `event.c` | Events in control arm |
| `n.c` | Total in control arm |

### `dat_normand1999` — Continuous outcome, k = 9

Nine studies comparing length of hospital stay between two groups.
Suitable for `meta_mean()` with MD or SMD.

```r
data(dat_normand1999, package = "metapropul")
head(dat_normand1999, 3)
#>               source n1i m1i sd1i n2i m2i sd2i
#> 1 Stewart 1994 (US)  65 8.45 3.83  40 9.45 3.34
#> ...
```

| Column | Description |
|--------|-------------|
| `source` | Study label |
| `n1i`, `m1i`, `sd1i` | Sample size, mean, SD — group 1 |
| `n2i`, `m2i`, `sd2i` | Sample size, mean, SD — group 2 |

### `dat_bcg` — Proportions, k = 13

Thirteen BCG vaccine trials reporting tuberculosis events in vaccinated and
control arms. Suitable for `meta_prop()` or `meta_ratio()`.

```r
data(dat_bcg, package = "metapropul")
head(dat_bcg, 3)
#>       author year tpos  npos tneg nneg cpos cneg  ablat
#> 1 Aronson     1948   4   123  119   NA   11  139   44
#> ...
```

| Column | Description |
|--------|-------------|
| `author` | Study label |
| `tpos` / `npos` | TB events / total in vaccinated arm |
| `cpos` / `cneg` | TB events / total in control arm |
| `ablat` | Absolute latitude (useful as a moderator) |

---

## Bringing your own data

Your data must be a **data frame** (or tibble) with at least one row per study.
The minimum requirements depend on the analysis type:

| Analysis | Minimum columns needed |
|----------|----------------------|
| `meta_ratio()` | event counts (4 cols) **or** pre-computed effect + CI |
| `meta_mean()` | group means + SDs + Ns (6 cols) **or** pre-computed effect + CI |
| `meta_prop()` | event count + total (2 cols) |

### Example: Reading from a spreadsheet

```r
library(readxl)
my_data <- read_excel("my_studies.xlsx")

# Inspect column names — these will be passed as arguments
names(my_data)
#> [1] "study"   "events_tx" "n_tx" "events_ctrl" "n_ctrl"

result <- meta_ratio(
  data    = my_data,
  event.e = "events_tx",
  n.e     = "n_tx",
  event.c = "events_ctrl",
  n.c     = "n_ctrl",
  studylab = "study"
)
```

### Example: Pre-computed log odds ratios

If your data already has effect sizes (e.g., exported from RevMan):

```r
result <- meta_ratio(
  data    = my_data,
  effect  = "log_or",
  lower   = "lower_ci",
  upper   = "upper_ci",
  studylab = "study"
)
```

<div class="callout-tip">
<strong>Tip — Column naming</strong>
metapropul is flexible: you always pass column names as quoted strings, so
your spreadsheet column names can be anything. No renaming required.
</div>

---

## The analysis object

Every `meta_*()` function returns an **analysis object** — a named list that
stores everything downstream functions need. You never have to re-specify the
effect measure, transformation, or subgroup structure: metapropul reads it
from the object automatically.

```r
result <- meta_prop(dat_bcg, event = "tpos", n = "npos", studylab = "author")

# The object knows what it is
class(result)
#> [1] "meta_prop"

# Summarise it
summary(result)

# Forest plot — zero extra arguments needed
forest_meta(result)

# Publication bias — auto-configured for proportions
publication_bias(result, plot_method = c("original", "contour"))

# Summary table
table_meta(result)
```

---

## Output formats

Most plotting and table functions accept a `save_as` argument:

| Value | What happens |
|-------|-------------|
| `"viewer"` (default) | Renders in the RStudio Plots / Viewer pane |
| `"pdf"` | Saves a high-resolution PDF to `tempdir()` (path printed) |
| `"png"` | Saves a 300 dpi PNG |
| `"tiff"` | Saves a LZW-compressed TIFF (journal standard) |
| `"docx"` *(tables only)* | Saves a Word document |

```r
# Save a PDF forest plot for your manuscript
forest_meta(result, save_as = "pdf", filename = "my_forest.pdf")

# Save a Word table
table_meta(result, save_as = "docx", filename = "Table1.docx")
```

---

## Next steps

Jump to the chapter that matches your outcome type:

- **Binary events (OR/RR/HR)** → Chapter \@ref(meta-ratio)
- **Continuous outcomes (MD/SMD)** → Chapter \@ref(meta-mean)
- **Proportions** → Chapter \@ref(meta-prop)
