# Lung Cancer and Smoking Cohort Study Dataset

Data from cohort studies investigating the association between smoking
and lung cancer.

## Usage

``` r
data(lungcancer)
```

## Format

A data frame with 7 rows and 6 variables:

- study:

  Study label

- participants:

  Number of participants in the study

- d.smokers:

  Number of lung cancer deaths among smokers

- py.smokers:

  Person-years among smokers

- d.nonsmokers:

  Number of lung cancer deaths among non-smokers

- py.nonsmokers:

  Person-years among non-smokers

## Source

Adapted from `meta` package examples.

## Details

This dataset is often used for meta-analysis of cohort study data to
calculate relative risks (RR) for smoking.

## Examples

``` r
data(lungcancer)
head(lungcancer)
#>                     study participants d.smokers py.smokers d.nonsmokers
#> 1         British Doctors        34000       129      77669           16
#> 2         Men in 9 States       188000       233     144242           85
#> 3           U.S. Veterans       248000       519     248735          180
#> 4 California Occupational        67000       138     168794            3
#> 5       California Legion        60000        98      76754           11
#> 6       Canadian Veterans        78000       317     123766           57
#>   py.nonsmokers
#> 1        191331
#> 2        523758
#> 3       1063265
#> 4         53206
#> 5         42246
#> 6        259234
```
