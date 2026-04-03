# metapropul documentation website

This folder contains the source files for the **metapropul** bookdown site.

## Structure

```
metapropul_bookdown/
├── index.Rmd                  Welcome page
├── 01-getting-started.Rmd    Installation & datasets
├── 02-meta-ratio.Rmd          meta_ratio() — OR, RR, HR
├── 03-meta-mean.Rmd           meta_mean() — MD, SMD
├── 04-meta-prop.Rmd           meta_prop() — proportions
├── 05-forest-plots.Rmd        forest_meta / influence / cumulative
├── 06-publication-bias.Rmd    publication_bias() / doi_plot()
├── 07-heterogeneity.Rmd       plot_heterogeneity() / plot_baujat()
├── 08-influence.Rmd           forest_influence / table_influence
├── 09-meta-regression.Rmd     meta_reg() / bubble_plot()
├── 10-tables.Rmd              table_meta / table_influence / table_cumulative
├── 11-faq.Rmd                 FAQ & troubleshooting
├── references.Rmd             Auto-generated references
├── references.bib             BibTeX references
├── _bookdown.yml              Chapter order configuration
├── _output.yml                Output format configuration
├── _common.R                  Shared knitr options
├── style.css                  Custom CSS theme
├── header.html                HTML header (fonts, meta tags)
├── preamble.tex               LaTeX preamble (for PDF)
├── build.R                    Build script
└── images/
    └── logo.svg               Package logo
```

## Building the site

### Prerequisites

```r
install.packages(c("bookdown", "metapropul"))  # metapropul from GitHub
# remotes::install_github("drrubesh/metapropul")
```

### Build HTML

```r
bookdown::render_book("index.Rmd", "bookdown::gitbook")
```

Or using the build script:

```bash
Rscript build.R
```

The rendered site appears in `docs/`. Open `docs/index.html` locally or
deploy to GitHub Pages.

### Build PDF

```r
bookdown::render_book("index.Rmd", "bookdown::pdf_book")
```

## Deploying to GitHub Pages

1. Push the `docs/` folder to your repository
2. Go to **Settings → Pages** in your GitHub repository
3. Set source to **main branch / docs folder**
4. Your site will be live at `https://drrubesh.github.io/metapropul/`

## Code chunks

All code chunks have `eval = FALSE` by default (`_common.R`).
Set `eval = TRUE` in `_common.R` when building with the package installed and
you want live output.
