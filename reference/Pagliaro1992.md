# Portal Vein Thrombosis After Splenectomy Dataset

This dataset contains data from studies evaluating the incidence of
portal vein thrombosis following splenectomy.

## Usage

``` r
data(Pagliaro1992)
```

## Format

A data frame with 28 rows and 8 variables:

- id:

  Study identifier

- treat.exp:

  Experimental treatment group label

- logOR:

  Log odds ratio

- selogOR:

  Standard error of the log odds ratio

- bleed.exp:

  Number of bleeding events in the experimental group

- n.exp:

  Sample size in the experimental group

- bleed.plac:

  Number of bleeding events in the placebo/control group

- n.plac:

  Sample size in the placebo/control group

## Source

Pagliaro et al., 1992. Adapted for meta-analysis teaching purposes.

## Details

Useful for demonstrating meta-analyses involving rare event binary
outcomes.

## Examples

``` r
data(Pagliaro1992)
head(Pagliaro1992)
#>   id     treat.exp       logOR   selogOR bleed.exp n.exp bleed.plac n.plac
#> 2  1  Beta-blocker -2.25316973 0.7981401         2    43         13     41
#> 3  1 Sclerotherapy -0.53202783 0.5040352         9    42         13     41
#> 5  2  Beta-blocker -0.02785695 0.4416590        12    68         13     72
#> 6  2 Sclerotherapy -0.01680712 0.4329688        13    73         13     72
#> 7  3  Beta-blocker -0.28768207 0.8036376         4    20          4     16
#> 8  4  Beta-blocker -0.57536414 0.3257233        20   116         30    111
```
