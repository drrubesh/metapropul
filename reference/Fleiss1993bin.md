# Fleiss1993bin: Aspirin After Myocardial Infarction Dataset (Binary Outcomes)

This dataset contains binary outcome data from randomized controlled
trials investigating the effect of aspirin versus placebo on mortality
after myocardial infarction.

## Usage

``` r
data(Fleiss1993bin)
```

## Format

A data frame with 7 rows and 6 variables:

- study:

  Study label

- year:

  Publication year

- d.asp:

  Number of deaths in the aspirin (treatment) group

- n.asp:

  Number of participants in the aspirin (treatment) group

- d.plac:

  Number of deaths in the placebo (control) group

- n.plac:

  Number of participants in the placebo (control) group

## Source

Fleiss, J.L. (1993). *The statistical basis of meta-analysis*.
Statistical Methods in Medical Research. Adapted for use in the `meta`
package.

## Details

This dataset is often used in examples to illustrate meta-analysis
methods for binary outcomes, such as risk ratios, odds ratios, and risk
differences.

## Examples

``` r
data(Fleiss1993bin)
head(Fleiss1993bin)
#>   study year d.asp n.asp d.plac n.plac
#> 1 MRC-1 1974    49   615     67    624
#> 2   CDP 1976    44   758     64    771
#> 3 MRC-2 1979   102   832    126    850
#> 4  GASP 1979    32   317     38    309
#> 5 PARIS 1980    85   810     52    406
#> 6  AMIS 1980   246  2267    219   2257
```
