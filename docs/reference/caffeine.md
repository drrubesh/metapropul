# Caffeine and Endurance Performance Dataset

This dataset contains data from randomized trials evaluating the effect
of caffeine ingestion on endurance performance, measured as time to
exhaustion or distance covered.

## Usage

``` r
data(caffeine)
```

## Format

A data frame with 8 rows and 12 variables:

- study:

  Study label

- year:

  Year of publication

- h.caf:

  Number of events in the caffeine group

- n.caf:

  Sample size in the caffeine group

- h.decaf:

  Number of events in the decaffeinated group

- n.decaf:

  Sample size in the decaffeinated group

- D1:

  Risk of bias domain 1 (e.g., "low", "some", "high")

- D2:

  Risk of bias domain 2

- D3:

  Risk of bias domain 3

- D4:

  Risk of bias domain 4

- D5:

  Risk of bias domain 5

- rob:

  Overall risk of bias

## Source

Adapted from `meta` package example datasets.

## Details

This dataset is commonly used in meta-analyses of continuous outcomes to
demonstrate methods for pooling mean differences or standardized mean
differences.

## Examples

``` r
data(caffeine)
head(caffeine)
#>            study year h.caf n.caf h.decaf n.decaf   D1   D2   D3   D4   D5  rob
#> 1   Amore-Coffea 2000     2    31      10      34 some some some some high  low
#> 2     Deliciozza 2004    10    40       9      40  low some some some high  low
#> 3 Kahve-Paradiso 2002     0     0       0       0 high high some  low  low  low
#> 4     Mama-Kaffa 1999    12    53       9      61 high high some high high  low
#> 5      Morrocona 1998     3    15       1      17  low some some  low  low  low
#> 6       Norscafe 1998    19    68       9      64 some some  low some high high
```
