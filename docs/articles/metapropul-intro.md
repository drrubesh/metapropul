# Getting started with metapropul

`metapropul` provides one workflow from model fitting to
publication-ready reporting. Rather than repeat isolated function
examples, the documentation is organised around reproducible case
studies using datasets bundled with the package.

``` r

library(metapropul)
```

## Choose a case study

1.  [BCG vaccine
    effectiveness](https://drrubesh.github.io/metapropul/articles/case-ratio-bcg.md)
    uses
    [`meta_ratio()`](https://drrubesh.github.io/metapropul/reference/meta_ratio.md)
    and demonstrates subgroup analysis, fixed and random effects,
    tables, forest plots, cumulative and influence analyses,
    heterogeneity, and publication bias.
2.  [Tuberculosis event proportions and
    meta-regression](https://drrubesh.github.io/metapropul/articles/case-proportion-regression.md)
    uses
    [`meta_prop()`](https://drrubesh.github.io/metapropul/reference/meta_prop.md)
    and demonstrates transformations, subgroup analysis, moderator
    preprocessing, Knapp–Hartung inference, predictions, collinearity,
    influence diagnostics, and all regression plots.
3.  [Continuous outcomes and study
    appraisal](https://drrubesh.github.io/metapropul/articles/case-mean-appraisal.md)
    uses
    [`meta_mean()`](https://drrubesh.github.io/metapropul/reference/meta_mean.md)
    and demonstrates MD/SMD models, cumulative and influence results,
    DOI assessment, and risk-of-bias figures.
4.  [Umbrella reviews without pooling
    meta-analyses](https://drrubesh.github.io/metapropul/articles/umbrella-reviews.md)
    covers credibility classification, GRADE recording, review quality,
    primary-study diagnostics, overlap, and selection sensitivity.

## Shared design

Core analysis objects can be passed directly to the package’s table and
plot functions. Study labels are matched explicitly in meta-regression,
subgroup results are taken from the fitted meta-analysis object, and
ratio/proportion outputs are back-transformed for interpretation.

The repository also provides non-vignette audit scripts under
`tools/manual_cases/`. These save every table and figure to disk and
perform explicit structural checks.
