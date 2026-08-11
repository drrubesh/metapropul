## R CMD check results

0 errors | 0 warnings | 2 notes

One note states that this is a new submission. This is expected. The second is
local-environment-only: HTML manual validation was skipped because the
installed HTML Tidy binary is not recent enough. PDF and HTML manuals were
generated successfully.

Checked locally with `R CMD check --as-cran` under the current R release.
The GitHub Actions matrix additionally checks R-devel, R-release, and the
previous R release on Linux, plus R-release on Windows and macOS.

## Test environments

* Local macOS installation, R-release
* GitHub Actions: Ubuntu, R-devel
* GitHub Actions: Ubuntu, R-release
* GitHub Actions: Ubuntu, R-oldrel
* GitHub Actions: Windows, R-release
* GitHub Actions: macOS, R-release

## Initial submission

This is the first CRAN submission of `metapropul`.

The package performs no network access during examples, tests, or vignettes.
Umbrella-review functions preserve reported meta-analysis estimates and do not
pool results across reviews.
