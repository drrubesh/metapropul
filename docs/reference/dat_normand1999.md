# Normand 1999 Meta-analysis Dataset (Continuous Outcomes)

Data from a meta-analysis of continuous outcomes, including means and
standard deviations for treatment and control groups across different
studies.

## Usage

``` r
data(dat_normand1999)
```

## Format

A data frame with 9 rows and 8 variables:

- study:

  Study ID

- source:

  Study source or name

- n1i:

  Sample size in treatment group

- m1i:

  Mean in treatment group

- sd1i:

  Standard deviation in treatment group

- n2i:

  Sample size in control group

- m2i:

  Mean in control group

- sd2i:

  Standard deviation in control group

## Details

This dataset is suitable for meta-analysis of mean differences between
two groups (treatment vs control).

## Examples

``` r
data(dat_normand1999)
head(dat_normand1999)
#>   study             source n1i m1i sd1i n2i m2i sd2i
#> 1     1          Edinburgh 155  55   47 156  75   64
#> 2     2     Orpington-Mild  31  27    7  32  29    4
#> 3     3 Orpington-Moderate  75  64   17  71 119   29
#> 4     4   Orpington-Severe  18  66   20  18 137   48
#> 5     5      Montreal-Home   8  14    8  13  18   11
#> 6     6  Montreal-Transfer  57  19    7  52  18    4
```
