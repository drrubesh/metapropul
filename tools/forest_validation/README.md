# Forest-plot visual validation

Run `01_generate_gallery.R` from the package root:

```r
source("tools/forest_validation/01_generate_gallery.R")
```

The script creates `manual-test-output/forest-validation/index.html`, a CSV
manifest, PNG previews, and full-resolution PDFs. It uses bundled package data
for the clinical examples and deterministic resampling for the 50-, 100-, and
200-study stress cases.

Review the gallery from top to bottom. For every figure confirm:

- no title appears unless the call supplies `title`;
- study labels and numeric columns do not collide;
- ratio axes are logarithmic and use a null value of 1;
- mean axes use a null value of 0;
- proportion axes are percentages bounded by 0 and 100;
- pooled diamonds, prediction intervals, axes, and heterogeneity text do not
  overlap;
- subgroup headings, subgroup totals, subgroup heterogeneity, and the test for
  subgroup differences are present when applicable;
- the number of displayed study rows agrees with the scenario name.

The one-study scenario is recorded as an expected validation error because
metapropul requires at least two studies for pooling.
