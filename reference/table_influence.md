# Leave-one-out influence table

Produces a publication-ready table of leave-one-out pooled estimates
from a `meta_ratio`, `meta_mean`, or `meta_prop` object.

## Usage

``` r
table_influence(
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

## Examples

``` r
# \donttest{
data(dat_bcg, package = "metapropul")
result <- meta_prop(
  data = dat_bcg,
  event = "tpos",
  n = "npos",
  studylab = "author"
)
#> Warning: Duplicate study label(s) were made unique: Rosenthal et al, Comstock et al. See 'label_audit' in the result.
table_influence(result)
#> <div id="eexombwkke" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
#>   <style>#eexombwkke table {
#>   font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
#>   -webkit-font-smoothing: antialiased;
#>   -moz-osx-font-smoothing: grayscale;
#> }
#> 
#> #eexombwkke thead, #eexombwkke tbody, #eexombwkke tfoot, #eexombwkke tr, #eexombwkke td, #eexombwkke th {
#>   border-style: none;
#> }
#> 
#> #eexombwkke p {
#>   margin: 0;
#>   padding: 0;
#> }
#> 
#> #eexombwkke .gt_table {
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
#> #eexombwkke .gt_caption {
#>   padding-top: 4px;
#>   padding-bottom: 4px;
#> }
#> 
#> #eexombwkke .gt_title {
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
#> #eexombwkke .gt_subtitle {
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
#> #eexombwkke .gt_heading {
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
#> #eexombwkke .gt_bottom_border {
#>   border-bottom-style: solid;
#>   border-bottom-width: 2px;
#>   border-bottom-color: #D3D3D3;
#> }
#> 
#> #eexombwkke .gt_col_headings {
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
#> #eexombwkke .gt_col_heading {
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
#> #eexombwkke .gt_column_spanner_outer {
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
#> #eexombwkke .gt_column_spanner_outer:first-child {
#>   padding-left: 0;
#> }
#> 
#> #eexombwkke .gt_column_spanner_outer:last-child {
#>   padding-right: 0;
#> }
#> 
#> #eexombwkke .gt_column_spanner {
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
#> #eexombwkke .gt_spanner_row {
#>   border-bottom-style: hidden;
#> }
#> 
#> #eexombwkke .gt_group_heading {
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
#> #eexombwkke .gt_empty_group_heading {
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
#> #eexombwkke .gt_from_md > :first-child {
#>   margin-top: 0;
#> }
#> 
#> #eexombwkke .gt_from_md > :last-child {
#>   margin-bottom: 0;
#> }
#> 
#> #eexombwkke .gt_row {
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
#> #eexombwkke .gt_stub {
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
#> #eexombwkke .gt_stub_row_group {
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
#> #eexombwkke .gt_row_group_first td {
#>   border-top-width: 2px;
#> }
#> 
#> #eexombwkke .gt_row_group_first th {
#>   border-top-width: 2px;
#> }
#> 
#> #eexombwkke .gt_summary_row {
#>   color: #333333;
#>   background-color: #FFFFFF;
#>   text-transform: inherit;
#>   padding-top: 8px;
#>   padding-bottom: 8px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#> }
#> 
#> #eexombwkke .gt_first_summary_row {
#>   border-top-style: solid;
#>   border-top-color: #D3D3D3;
#> }
#> 
#> #eexombwkke .gt_first_summary_row.thick {
#>   border-top-width: 2px;
#> }
#> 
#> #eexombwkke .gt_last_summary_row {
#>   padding-top: 8px;
#>   padding-bottom: 8px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#>   border-bottom-style: solid;
#>   border-bottom-width: 2px;
#>   border-bottom-color: #D3D3D3;
#> }
#> 
#> #eexombwkke .gt_grand_summary_row {
#>   color: #333333;
#>   background-color: #FFFFFF;
#>   text-transform: inherit;
#>   padding-top: 8px;
#>   padding-bottom: 8px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#> }
#> 
#> #eexombwkke .gt_first_grand_summary_row {
#>   padding-top: 8px;
#>   padding-bottom: 8px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#>   border-top-style: double;
#>   border-top-width: 6px;
#>   border-top-color: #D3D3D3;
#> }
#> 
#> #eexombwkke .gt_last_grand_summary_row_top {
#>   padding-top: 8px;
#>   padding-bottom: 8px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#>   border-bottom-style: double;
#>   border-bottom-width: 6px;
#>   border-bottom-color: #D3D3D3;
#> }
#> 
#> #eexombwkke .gt_striped {
#>   background-color: rgba(128, 128, 128, 0.05);
#> }
#> 
#> #eexombwkke .gt_table_body {
#>   border-top-style: solid;
#>   border-top-width: 2px;
#>   border-top-color: #D3D3D3;
#>   border-bottom-style: solid;
#>   border-bottom-width: 2px;
#>   border-bottom-color: #D3D3D3;
#> }
#> 
#> #eexombwkke .gt_footnotes {
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
#> #eexombwkke .gt_footnote {
#>   margin: 0px;
#>   font-size: 90%;
#>   padding-top: 4px;
#>   padding-bottom: 4px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#> }
#> 
#> #eexombwkke .gt_sourcenotes {
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
#> #eexombwkke .gt_sourcenote {
#>   font-size: 90%;
#>   padding-top: 4px;
#>   padding-bottom: 4px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#> }
#> 
#> #eexombwkke .gt_left {
#>   text-align: left;
#> }
#> 
#> #eexombwkke .gt_center {
#>   text-align: center;
#> }
#> 
#> #eexombwkke .gt_right {
#>   text-align: right;
#>   font-variant-numeric: tabular-nums;
#> }
#> 
#> #eexombwkke .gt_font_normal {
#>   font-weight: normal;
#> }
#> 
#> #eexombwkke .gt_font_bold {
#>   font-weight: bold;
#> }
#> 
#> #eexombwkke .gt_font_italic {
#>   font-style: italic;
#> }
#> 
#> #eexombwkke .gt_super {
#>   font-size: 65%;
#> }
#> 
#> #eexombwkke .gt_footnote_marks {
#>   font-size: 75%;
#>   vertical-align: 0.4em;
#>   position: initial;
#> }
#> 
#> #eexombwkke .gt_asterisk {
#>   font-size: 100%;
#>   vertical-align: 0;
#> }
#> 
#> #eexombwkke .gt_indent_1 {
#>   text-indent: 5px;
#> }
#> 
#> #eexombwkke .gt_indent_2 {
#>   text-indent: 10px;
#> }
#> 
#> #eexombwkke .gt_indent_3 {
#>   text-indent: 15px;
#> }
#> 
#> #eexombwkke .gt_indent_4 {
#>   text-indent: 20px;
#> }
#> 
#> #eexombwkke .gt_indent_5 {
#>   text-indent: 25px;
#> }
#> 
#> #eexombwkke .katex-display {
#>   display: inline-flex !important;
#>   margin-bottom: 0.75em !important;
#> }
#> 
#> #eexombwkke div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
#>   height: 0px !important;
#> }
#> </style>
#>   <table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
#>   <thead>
#>     <tr class="gt_col_headings">
#>       <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="Study">Study</th>
#>       <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="Estimate-[95%-CI]">Pooled Proportion (%)</th>
#>       <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="I²-(%-variability)">I² (% variability)<span class="gt_footnote_marks" style="white-space:nowrap;font-style:italic;font-weight:normal;line-height:0;"><sup>1</sup></span></th>
#>       <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="Tau²">Tau²</th>
#>     </tr>
#>   </thead>
#>   <tbody class="gt_table_body">
#>     <tr><td headers="Study" class="gt_row gt_left">Omitting Aronson</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left">0.67 [0.31 – 1.42]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right">99.3</td>
#> <td headers="Tau²" class="gt_row gt_right">1.3985</td></tr>
#>     <tr><td headers="Study" class="gt_row gt_left">Omitting Ferguson &amp; Simes</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left">0.69 [0.31 – 1.52]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right">99.3</td>
#> <td headers="Tau²" class="gt_row gt_right">1.4932</td></tr>
#>     <tr><td headers="Study" class="gt_row gt_left">Omitting Rosenthal et al</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left">0.72 [0.32 – 1.59]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right">99.3</td>
#> <td headers="Tau²" class="gt_row gt_right">1.5428</td></tr>
#>     <tr><td headers="Study" class="gt_row gt_left">Omitting Hart &amp; Sutherland</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left">0.78 [0.35 – 1.74]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right">99.3</td>
#> <td headers="Tau²" class="gt_row gt_right">1.5645</td></tr>
#>     <tr><td headers="Study" class="gt_row gt_left">Omitting Frimodt-Moller et al</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left">0.76 [0.34 – 1.7]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right">99.3</td>
#> <td headers="Tau²" class="gt_row gt_right">1.5867</td></tr>
#>     <tr><td headers="Study" class="gt_row gt_left">Omitting Stein &amp; Aronson</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left">0.56 [0.33 – 0.97]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right">89.9</td>
#> <td headers="Tau²" class="gt_row gt_right">0.5987</td></tr>
#>     <tr><td headers="Study" class="gt_row gt_left">Omitting Vandiviere et al</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left">0.8 [0.36 – 1.76]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right">99.3</td>
#> <td headers="Tau²" class="gt_row gt_right">1.5132</td></tr>
#>     <tr><td headers="Study" class="gt_row gt_left">Omitting TPT Madras</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left">0.77 [0.34 – 1.72]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right">99.2</td>
#> <td headers="Tau²" class="gt_row gt_right">1.5836</td></tr>
#>     <tr><td headers="Study" class="gt_row gt_left">Omitting Coetzee &amp; Berjak</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left">0.79 [0.35 – 1.76]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right">99.3</td>
#> <td headers="Tau²" class="gt_row gt_right">1.5441</td></tr>
#>     <tr><td headers="Study" class="gt_row gt_left">Omitting Rosenthal et al.1</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left">0.73 [0.32 – 1.63]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right">99.3</td>
#> <td headers="Tau²" class="gt_row gt_right">1.5773</td></tr>
#>     <tr><td headers="Study" class="gt_row gt_left">Omitting Comstock et al</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left">0.8 [0.36 – 1.76]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right">99.2</td>
#> <td headers="Tau²" class="gt_row gt_right">1.5373</td></tr>
#>     <tr><td headers="Study" class="gt_row gt_left">Omitting Comstock &amp; Webster</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left">0.83 [0.38 – 1.78]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right">99.3</td>
#> <td headers="Tau²" class="gt_row gt_right">1.4339</td></tr>
#>     <tr><td headers="Study" class="gt_row gt_left">Omitting Comstock et al.1</td>
#> <td headers="Estimate [95% CI]" class="gt_row gt_left">0.85 [0.4 – 1.8]</td>
#> <td headers="I² (% variability)" class="gt_row gt_right">99.3</td>
#> <td headers="Tau²" class="gt_row gt_right">1.3434</td></tr>
#>   </tbody>
#>   <tfoot>
#>     <tr class="gt_footnotes">
#>       <td class="gt_footnote" colspan="4"><span class="gt_footnote_marks" style="white-space:nowrap;font-style:italic;font-weight:normal;line-height:0;"><sup>1</sup></span> I² = proportion of total observed variability attributable to between-study heterogeneity. Not a significance test; magnitude depends on study precision and number of studies.</td>
#>     </tr>
#>   </tfoot>
#> </table>
#> </div>
# }
```
