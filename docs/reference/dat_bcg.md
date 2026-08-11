# Example Dataset: dat_bcg

This dataset contains results from clinical trials evaluating the
efficacy of Bacillus Calmette-Guérin (BCG) vaccine against tuberculosis.

## Usage

``` r
data(dat_bcg)
```

## Format

A data frame with 13 rows and 11 variables:

- trial:

  Trial ID

- author:

  First author of the study

- year:

  Year of publication

- tpos:

  Number of tuberculosis cases in the treatment group (BCG vaccinated)

- tneg:

  Number without tuberculosis in the treatment group

- cpos:

  Number of tuberculosis cases in the control group (not vaccinated)

- cneg:

  Number without tuberculosis in the control group

- ablat:

  Latitude of the study location

- alloc:

  Randomization method (e.g., random, alternate)

- npos:

  Total sample size in the treatment group

- region:

  Region of the study (e.g., North America, Europe)

## Source

Colditz et al., 1994. Meta-analysis of BCG vaccine efficacy.

## Details

This dataset is commonly used in meta-analysis examples to explore
heterogeneity of BCG vaccine efficacy across different regions.
