# Cumulative meta-analysis table

Produces a step-by-step table of cumulative pooled estimates, adding one
study at a time in the order they appear in the data.

## Usage

``` r
table_cumulative_meta(
  object,
  title = NULL,
  include_heterogeneity = TRUE,
  save_as = c("viewer", "docx", "pdf"),
  filename = NULL
)
```

## Arguments

- object:

  A `meta_ratio`, `meta_mean`, or `meta_prop` object.

- title:

  Optional character string for the table title. No title is added when
  `NULL` (the default).

- include_heterogeneity:

  Logical. Include I\\^2\\ and Tau\\^2\\ columns (default `TRUE`).

- save_as:

  One of `"viewer"` (default), `"docx"`, or `"pdf"`.

- filename:

  Optional file path. If `NULL`, a timestamped file is created in
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html) when saving to
  file.

## Value

A `gt` table, invisibly if saved to file.

## Details

**Study ordering:** Sort your data by year before fitting the model for
a meaningful cumulative analysis:


    dat <- dat[order(dat$year), ]
    result <- meta_ratio(data = dat, ...)
    table_cumulative_meta(result)

## Examples

``` r
# \donttest{
data(dat_bcg, package = "metapropul")
dat_bcg <- dat_bcg[order(dat_bcg$year), ]
result <- meta_prop(
  data = dat_bcg,
  event = "tpos",
  n = "npos",
  studylab = "author"
)
#> Warning: Duplicate study label(s) were made unique: Rosenthal et al, Comstock et al. See 'label_audit' in the result.
table_cumulative_meta(result)
#> <div id="mwlefoodfi" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
#>   <style>#mwlefoodfi table {
#>   font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
#>   -webkit-font-smoothing: antialiased;
#>   -moz-osx-font-smoothing: grayscale;
#> }
#> 
#> #mwlefoodfi thead, #mwlefoodfi tbody, #mwlefoodfi tfoot, #mwlefoodfi tr, #mwlefoodfi td, #mwlefoodfi th {
#>   border-style: none;
#> }
#> 
#> #mwlefoodfi p {
#>   margin: 0;
#>   padding: 0;
#> }
#> 
#> #mwlefoodfi .gt_table {
#>   display: table;
#>   border-collapse: collapse;
#>   line-height: normal;
#>   margin-left: auto;
#>   margin-right: auto;
#>   color: #333333;
#>   font-size: 16px;
#>   font-weight: normal;
#>   font-style: normal;
#>   background-color: #FFFFFF;
#>   width: auto;
#>   border-top-style: solid;
#>   border-top-width: 2px;
#>   border-top-color: #A8A8A8;
#>   border-right-style: none;
#>   border-right-width: 2px;
#>   border-right-color: #D3D3D3;
#>   border-bottom-style: solid;
#>   border-bottom-width: 2px;
#>   border-bottom-color: #A8A8A8;
#>   border-left-style: none;
#>   border-left-width: 2px;
#>   border-left-color: #D3D3D3;
#> }
#> 
#> #mwlefoodfi .gt_caption {
#>   padding-top: 4px;
#>   padding-bottom: 4px;
#> }
#> 
#> #mwlefoodfi .gt_title {
#>   color: #333333;
#>   font-size: 125%;
#>   font-weight: initial;
#>   padding-top: 4px;
#>   padding-bottom: 4px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#>   border-bottom-color: #FFFFFF;
#>   border-bottom-width: 0;
#> }
#> 
#> #mwlefoodfi .gt_subtitle {
#>   color: #333333;
#>   font-size: 85%;
#>   font-weight: initial;
#>   padding-top: 3px;
#>   padding-bottom: 5px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#>   border-top-color: #FFFFFF;
#>   border-top-width: 0;
#> }
#> 
#> #mwlefoodfi .gt_heading {
#>   background-color: #FFFFFF;
#>   text-align: center;
#>   border-bottom-color: #FFFFFF;
#>   border-left-style: none;
#>   border-left-width: 1px;
#>   border-left-color: #D3D3D3;
#>   border-right-style: none;
#>   border-right-width: 1px;
#>   border-right-color: #D3D3D3;
#> }
#> 
#> #mwlefoodfi .gt_bottom_border {
#>   border-bottom-style: solid;
#>   border-bottom-width: 2px;
#>   border-bottom-color: #D3D3D3;
#> }
#> 
#> #mwlefoodfi .gt_col_headings {
#>   border-top-style: solid;
#>   border-top-width: 2px;
#>   border-top-color: #D3D3D3;
#>   border-bottom-style: solid;
#>   border-bottom-width: 2px;
#>   border-bottom-color: #D3D3D3;
#>   border-left-style: none;
#>   border-left-width: 1px;
#>   border-left-color: #D3D3D3;
#>   border-right-style: none;
#>   border-right-width: 1px;
#>   border-right-color: #D3D3D3;
#> }
#> 
#> #mwlefoodfi .gt_col_heading {
#>   color: #333333;
#>   background-color: #FFFFFF;
#>   font-size: 100%;
#>   font-weight: normal;
#>   text-transform: inherit;
#>   border-left-style: none;
#>   border-left-width: 1px;
#>   border-left-color: #D3D3D3;
#>   border-right-style: none;
#>   border-right-width: 1px;
#>   border-right-color: #D3D3D3;
#>   vertical-align: bottom;
#>   padding-top: 5px;
#>   padding-bottom: 6px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#>   overflow-x: hidden;
#> }
#> 
#> #mwlefoodfi .gt_column_spanner_outer {
#>   color: #333333;
#>   background-color: #FFFFFF;
#>   font-size: 100%;
#>   font-weight: normal;
#>   text-transform: inherit;
#>   padding-top: 0;
#>   padding-bottom: 0;
#>   padding-left: 4px;
#>   padding-right: 4px;
#> }
#> 
#> #mwlefoodfi .gt_column_spanner_outer:first-child {
#>   padding-left: 0;
#> }
#> 
#> #mwlefoodfi .gt_column_spanner_outer:last-child {
#>   padding-right: 0;
#> }
#> 
#> #mwlefoodfi .gt_column_spanner {
#>   border-bottom-style: solid;
#>   border-bottom-width: 2px;
#>   border-bottom-color: #D3D3D3;
#>   vertical-align: bottom;
#>   padding-top: 5px;
#>   padding-bottom: 5px;
#>   overflow-x: hidden;
#>   display: inline-block;
#>   width: 100%;
#> }
#> 
#> #mwlefoodfi .gt_spanner_row {
#>   border-bottom-style: hidden;
#> }
#> 
#> #mwlefoodfi .gt_group_heading {
#>   padding-top: 8px;
#>   padding-bottom: 8px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#>   color: #333333;
#>   background-color: #FFFFFF;
#>   font-size: 100%;
#>   font-weight: initial;
#>   text-transform: inherit;
#>   border-top-style: solid;
#>   border-top-width: 2px;
#>   border-top-color: #D3D3D3;
#>   border-bottom-style: solid;
#>   border-bottom-width: 2px;
#>   border-bottom-color: #D3D3D3;
#>   border-left-style: none;
#>   border-left-width: 1px;
#>   border-left-color: #D3D3D3;
#>   border-right-style: none;
#>   border-right-width: 1px;
#>   border-right-color: #D3D3D3;
#>   vertical-align: middle;
#>   text-align: left;
#> }
#> 
#> #mwlefoodfi .gt_empty_group_heading {
#>   padding: 0.5px;
#>   color: #333333;
#>   background-color: #FFFFFF;
#>   font-size: 100%;
#>   font-weight: initial;
#>   border-top-style: solid;
#>   border-top-width: 2px;
#>   border-top-color: #D3D3D3;
#>   border-bottom-style: solid;
#>   border-bottom-width: 2px;
#>   border-bottom-color: #D3D3D3;
#>   vertical-align: middle;
#> }
#> 
#> #mwlefoodfi .gt_from_md > :first-child {
#>   margin-top: 0;
#> }
#> 
#> #mwlefoodfi .gt_from_md > :last-child {
#>   margin-bottom: 0;
#> }
#> 
#> #mwlefoodfi .gt_row {
#>   padding-top: 8px;
#>   padding-bottom: 8px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#>   margin: 10px;
#>   border-top-style: solid;
#>   border-top-width: 1px;
#>   border-top-color: #D3D3D3;
#>   border-left-style: none;
#>   border-left-width: 1px;
#>   border-left-color: #D3D3D3;
#>   border-right-style: none;
#>   border-right-width: 1px;
#>   border-right-color: #D3D3D3;
#>   vertical-align: middle;
#>   overflow-x: hidden;
#> }
#> 
#> #mwlefoodfi .gt_stub {
#>   color: #333333;
#>   background-color: #FFFFFF;
#>   font-size: 100%;
#>   font-weight: initial;
#>   text-transform: inherit;
#>   border-right-style: solid;
#>   border-right-width: 2px;
#>   border-right-color: #D3D3D3;
#>   padding-left: 5px;
#>   padding-right: 5px;
#> }
#> 
#> #mwlefoodfi .gt_stub_row_group {
#>   color: #333333;
#>   background-color: #FFFFFF;
#>   font-size: 100%;
#>   font-weight: initial;
#>   text-transform: inherit;
#>   border-right-style: solid;
#>   border-right-width: 2px;
#>   border-right-color: #D3D3D3;
#>   padding-left: 5px;
#>   padding-right: 5px;
#>   vertical-align: top;
#> }
#> 
#> #mwlefoodfi .gt_row_group_first td {
#>   border-top-width: 2px;
#> }
#> 
#> #mwlefoodfi .gt_row_group_first th {
#>   border-top-width: 2px;
#> }
#> 
#> #mwlefoodfi .gt_summary_row {
#>   color: #333333;
#>   background-color: #FFFFFF;
#>   text-transform: inherit;
#>   padding-top: 8px;
#>   padding-bottom: 8px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#> }
#> 
#> #mwlefoodfi .gt_first_summary_row {
#>   border-top-style: solid;
#>   border-top-color: #D3D3D3;
#> }
#> 
#> #mwlefoodfi .gt_first_summary_row.thick {
#>   border-top-width: 2px;
#> }
#> 
#> #mwlefoodfi .gt_last_summary_row {
#>   padding-top: 8px;
#>   padding-bottom: 8px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#>   border-bottom-style: solid;
#>   border-bottom-width: 2px;
#>   border-bottom-color: #D3D3D3;
#> }
#> 
#> #mwlefoodfi .gt_grand_summary_row {
#>   color: #333333;
#>   background-color: #FFFFFF;
#>   text-transform: inherit;
#>   padding-top: 8px;
#>   padding-bottom: 8px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#> }
#> 
#> #mwlefoodfi .gt_first_grand_summary_row {
#>   padding-top: 8px;
#>   padding-bottom: 8px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#>   border-top-style: double;
#>   border-top-width: 6px;
#>   border-top-color: #D3D3D3;
#> }
#> 
#> #mwlefoodfi .gt_last_grand_summary_row_top {
#>   padding-top: 8px;
#>   padding-bottom: 8px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#>   border-bottom-style: double;
#>   border-bottom-width: 6px;
#>   border-bottom-color: #D3D3D3;
#> }
#> 
#> #mwlefoodfi .gt_striped {
#>   background-color: rgba(128, 128, 128, 0.05);
#> }
#> 
#> #mwlefoodfi .gt_table_body {
#>   border-top-style: solid;
#>   border-top-width: 2px;
#>   border-top-color: #D3D3D3;
#>   border-bottom-style: solid;
#>   border-bottom-width: 2px;
#>   border-bottom-color: #D3D3D3;
#> }
#> 
#> #mwlefoodfi .gt_footnotes {
#>   color: #333333;
#>   background-color: #FFFFFF;
#>   border-bottom-style: none;
#>   border-bottom-width: 2px;
#>   border-bottom-color: #D3D3D3;
#>   border-left-style: none;
#>   border-left-width: 2px;
#>   border-left-color: #D3D3D3;
#>   border-right-style: none;
#>   border-right-width: 2px;
#>   border-right-color: #D3D3D3;
#> }
#> 
#> #mwlefoodfi .gt_footnote {
#>   margin: 0px;
#>   font-size: 90%;
#>   padding-top: 4px;
#>   padding-bottom: 4px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#> }
#> 
#> #mwlefoodfi .gt_sourcenotes {
#>   color: #333333;
#>   background-color: #FFFFFF;
#>   border-bottom-style: none;
#>   border-bottom-width: 2px;
#>   border-bottom-color: #D3D3D3;
#>   border-left-style: none;
#>   border-left-width: 2px;
#>   border-left-color: #D3D3D3;
#>   border-right-style: none;
#>   border-right-width: 2px;
#>   border-right-color: #D3D3D3;
#> }
#> 
#> #mwlefoodfi .gt_sourcenote {
#>   font-size: 90%;
#>   padding-top: 4px;
#>   padding-bottom: 4px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#> }
#> 
#> #mwlefoodfi .gt_left {
#>   text-align: left;
#> }
#> 
#> #mwlefoodfi .gt_center {
#>   text-align: center;
#> }
#> 
#> #mwlefoodfi .gt_right {
#>   text-align: right;
#>   font-variant-numeric: tabular-nums;
#> }
#> 
#> #mwlefoodfi .gt_font_normal {
#>   font-weight: normal;
#> }
#> 
#> #mwlefoodfi .gt_font_bold {
#>   font-weight: bold;
#> }
#> 
#> #mwlefoodfi .gt_font_italic {
#>   font-style: italic;
#> }
#> 
#> #mwlefoodfi .gt_super {
#>   font-size: 65%;
#> }
#> 
#> #mwlefoodfi .gt_footnote_marks {
#>   font-size: 75%;
#>   vertical-align: 0.4em;
#>   position: initial;
#> }
#> 
#> #mwlefoodfi .gt_asterisk {
#>   font-size: 100%;
#>   vertical-align: 0;
#> }
#> 
#> #mwlefoodfi .gt_indent_1 {
#>   text-indent: 5px;
#> }
#> 
#> #mwlefoodfi .gt_indent_2 {
#>   text-indent: 10px;
#> }
#> 
#> #mwlefoodfi .gt_indent_3 {
#>   text-indent: 15px;
#> }
#> 
#> #mwlefoodfi .gt_indent_4 {
#>   text-indent: 20px;
#> }
#> 
#> #mwlefoodfi .gt_indent_5 {
#>   text-indent: 25px;
#> }
#> 
#> #mwlefoodfi .katex-display {
#>   display: inline-flex !important;
#>   margin-bottom: 0.75em !important;
#> }
#> 
#> #mwlefoodfi div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
#>   height: 0px !important;
#> }
#> </style>
#>   <table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
#>   <thead>
#>     <tr class="gt_col_headings">
#>       <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="Step">Step</th>
#>       <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="Study-Added">Study</th>
#>       <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="Estimate-[95%-CI]">Pooled Proportion (%)</th>
#>       <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="I²-(%-variability)">I² (% variability)<span class="gt_footnote_marks" style="white-space:nowrap;font-style:italic;font-weight:normal;line-height:0;"><sup>1</sup></span></th>
#>       <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="Tau²">Tau²</th>
#>     </tr>
#>   </thead>
#>   <tbody class="gt_table_body">
#>     <tr><td headers="Step" class="gt_row gt_right">1</td>
#> <td headers="Study Added" class="gt_row gt_left">Adding Aronson (k=1)</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left">3.25 [1.23 – 8.34]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right">NA</td>
#> <td headers="Tau²" class="gt_row gt_right">NA</td></tr>
#>     <tr><td headers="Step" class="gt_row gt_right">2</td>
#> <td headers="Study Added" class="gt_row gt_left">Adding Ferguson &amp; Simes (k=2)</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left">2.4 [0.0974 – 38.3]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right">0.0</td>
#> <td headers="Tau²" class="gt_row gt_right">0.0000</td></tr>
#>     <tr><td headers="Step" class="gt_row gt_right">3</td>
#> <td headers="Study Added" class="gt_row gt_left">Adding Stein &amp; Aronson (k=3)</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left">4.56 [0.391 – 36.7]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right">92.5</td>
#> <td headers="Tau²" class="gt_row gt_right">0.9439</td></tr>
#>     <tr><td headers="Step" class="gt_row gt_right">4</td>
#> <td headers="Study Added" class="gt_row gt_left">Adding Rosenthal et al (k=4)</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left">3.46 [0.683 – 15.8]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right">92.7</td>
#> <td headers="Tau²" class="gt_row gt_right">0.9852</td></tr>
#>     <tr><td headers="Step" class="gt_row gt_right">5</td>
#> <td headers="Study Added" class="gt_row gt_left">Adding Rosenthal et al.1 (k=5)</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left">2.63 [0.718 – 9.19]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right">97.0</td>
#> <td headers="Tau²" class="gt_row gt_right">1.0821</td></tr>
#>     <tr><td headers="Step" class="gt_row gt_right">6</td>
#> <td headers="Study Added" class="gt_row gt_left">Adding Coetzee &amp; Berjak (k=6)</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left">1.86 [0.516 – 6.49]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right">98.7</td>
#> <td headers="Tau²" class="gt_row gt_right">1.4960</td></tr>
#>     <tr><td headers="Step" class="gt_row gt_right">7</td>
#> <td headers="Study Added" class="gt_row gt_left">Adding Comstock &amp; Webster (k=7)</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left">1.37 [0.378 – 4.83]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right">98.6</td>
#> <td headers="Tau²" class="gt_row gt_right">1.8849</td></tr>
#>     <tr><td headers="Step" class="gt_row gt_right">8</td>
#> <td headers="Study Added" class="gt_row gt_left">Adding Frimodt-Moller et al (k=8)</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left">1.24 [0.414 – 3.67]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right">98.8</td>
#> <td headers="Tau²" class="gt_row gt_right">1.6748</td></tr>
#>     <tr><td headers="Step" class="gt_row gt_right">9</td>
#> <td headers="Study Added" class="gt_row gt_left">Adding Vandiviere et al (k=9)</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left">1.07 [0.389 – 2.89]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right">98.7</td>
#> <td headers="Tau²" class="gt_row gt_right">1.6651</td></tr>
#>     <tr><td headers="Step" class="gt_row gt_right">10</td>
#> <td headers="Study Added" class="gt_row gt_left">Adding Comstock et al (k=10)</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left">0.953 [0.381 – 2.36]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right">99.3</td>
#> <td headers="Tau²" class="gt_row gt_right">1.5899</td></tr>
#>     <tr><td headers="Step" class="gt_row gt_right">11</td>
#> <td headers="Study Added" class="gt_row gt_left">Adding Comstock et al.1 (k=11)</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left">0.805 [0.329 – 1.96]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right">99.3</td>
#> <td headers="Tau²" class="gt_row gt_right">1.7227</td></tr>
#>     <tr><td headers="Step" class="gt_row gt_right">12</td>
#> <td headers="Study Added" class="gt_row gt_left">Adding Hart &amp; Sutherland (k=12)</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left">0.766 [0.34 – 1.72]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right">99.2</td>
#> <td headers="Tau²" class="gt_row gt_right">1.5836</td></tr>
#>     <tr><td headers="Step" class="gt_row gt_right" style="font-weight: bold;">13</td>
#> <td headers="Study Added" class="gt_row gt_left" style="font-weight: bold;">Adding TPT Madras (k=13)</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left" style="font-weight: bold;">0.747 [0.356 – 1.56]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right" style="font-weight: bold;">99.2</td>
#> <td headers="Tau²" class="gt_row gt_right" style="font-weight: bold;">1.4477</td></tr>
#>   </tbody>
#>   <tfoot>
#>     <tr class="gt_footnotes">
#>       <td class="gt_footnote" colspan="5"><span class="gt_footnote_marks" style="white-space:nowrap;font-style:italic;font-weight:normal;line-height:0;"><sup>1</sup></span> I² = proportion of total observed variability attributable to between-study heterogeneity. Not a significance test; magnitude depends on study precision and number of studies.</td>
#>     </tr>
#>   </tfoot>
#> </table>
#> </div>
# }
```
