# Cisapride and Reflux Esophagitis Dataset

This dataset provides data from randomized controlled trials evaluating
the efficacy of Cisapride versus placebo in healing reflux esophagitis.

## Usage

``` r
data(cisapride)
```

## Format

A data frame with 13 rows and 5 variables:

- study:

  Study label

- event.cisa:

  Number of healed patients in the cisapride group

- n.cisa:

  Total number of patients in the cisapride group

- event.plac:

  Number of healed patients in the placebo group

- n.plac:

  Total number of patients in the placebo group

## Source

Adapted from `meta` package example datasets.

## Details

This dataset is used to illustrate meta-analytic methods for binary
outcomes like risk ratios and odds ratios.

## Examples

``` r
data(cisapride)
head(cisapride)
#>                        study event.cisa n.cisa event.plac n.plac
#> 1              Creytens [13]         15     16          9     16
#> 2                  Milo [14]         12     16          1     16
#> 3 Francois and De Nutte [15]         29     34         18     34
#> 4     Deruyttere et al. [16]         42     56         31     56
#> 5                Hannon [17]         14     22          6     22
#> 6                Roesch [18]         44     54         17     55
```
