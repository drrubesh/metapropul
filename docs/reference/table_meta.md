# Summary table for meta-analysis results

Produces a publication-ready table from a supported metapropul
meta-analysis object. Includes study-level estimates, a pooled row, and
a footnote explaining I\\^2\\.

## Usage

``` r
table_meta(
  meta_result,
  title = NULL,
  save_as = c("viewer", "docx", "pdf"),
  filename = NULL
)
```

## Arguments

- meta_result:

  A supported metapropul meta-analysis object.

- title:

  Optional character string for the table title. No title is added when
  `NULL` (the default).

- save_as:

  One of `"viewer"` (default), `"docx"` (Word), or `"pdf"`.

- filename:

  Optional file path. If `NULL`, a timestamped file is created in
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html).

## Value

A `gt` table (invisibly when saving to file).

## Examples

``` r
# \donttest{
data(dat_bcg, package = "metapropul")
result <- meta_prop(
  data = dat_bcg, event = "tpos", n = "npos",
  studylab = "author"
)
#> Warning: Duplicate study label(s) were made unique: Rosenthal et al, Comstock et al. See 'label_audit' in the result.
table_meta(result)
#> <div id="ulbfdpbcyv" style="padding-left:0px;padding-right:0px;padding-top:10px;padding-bottom:10px;overflow-x:auto;overflow-y:auto;width:auto;height:auto;">
#>   <style>#ulbfdpbcyv table {
#>   font-family: system-ui, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol', 'Noto Color Emoji';
#>   -webkit-font-smoothing: antialiased;
#>   -moz-osx-font-smoothing: grayscale;
#> }
#> 
#> #ulbfdpbcyv thead, #ulbfdpbcyv tbody, #ulbfdpbcyv tfoot, #ulbfdpbcyv tr, #ulbfdpbcyv td, #ulbfdpbcyv th {
#>   border-style: none;
#> }
#> 
#> #ulbfdpbcyv p {
#>   margin: 0;
#>   padding: 0;
#> }
#> 
#> #ulbfdpbcyv .gt_table {
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
#> #ulbfdpbcyv .gt_caption {
#>   padding-top: 4px;
#>   padding-bottom: 4px;
#> }
#> 
#> #ulbfdpbcyv .gt_title {
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
#> #ulbfdpbcyv .gt_subtitle {
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
#> #ulbfdpbcyv .gt_heading {
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
#> #ulbfdpbcyv .gt_bottom_border {
#>   border-bottom-style: solid;
#>   border-bottom-width: 2px;
#>   border-bottom-color: #D3D3D3;
#> }
#> 
#> #ulbfdpbcyv .gt_col_headings {
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
#> #ulbfdpbcyv .gt_col_heading {
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
#> #ulbfdpbcyv .gt_column_spanner_outer {
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
#> #ulbfdpbcyv .gt_column_spanner_outer:first-child {
#>   padding-left: 0;
#> }
#> 
#> #ulbfdpbcyv .gt_column_spanner_outer:last-child {
#>   padding-right: 0;
#> }
#> 
#> #ulbfdpbcyv .gt_column_spanner {
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
#> #ulbfdpbcyv .gt_spanner_row {
#>   border-bottom-style: hidden;
#> }
#> 
#> #ulbfdpbcyv .gt_group_heading {
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
#> #ulbfdpbcyv .gt_empty_group_heading {
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
#> #ulbfdpbcyv .gt_from_md > :first-child {
#>   margin-top: 0;
#> }
#> 
#> #ulbfdpbcyv .gt_from_md > :last-child {
#>   margin-bottom: 0;
#> }
#> 
#> #ulbfdpbcyv .gt_row {
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
#> #ulbfdpbcyv .gt_stub {
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
#> #ulbfdpbcyv .gt_stub_row_group {
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
#> #ulbfdpbcyv .gt_row_group_first td {
#>   border-top-width: 2px;
#> }
#> 
#> #ulbfdpbcyv .gt_row_group_first th {
#>   border-top-width: 2px;
#> }
#> 
#> #ulbfdpbcyv .gt_summary_row {
#>   color: #333333;
#>   background-color: #FFFFFF;
#>   text-transform: inherit;
#>   padding-top: 8px;
#>   padding-bottom: 8px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#> }
#> 
#> #ulbfdpbcyv .gt_first_summary_row {
#>   border-top-style: solid;
#>   border-top-color: #D3D3D3;
#> }
#> 
#> #ulbfdpbcyv .gt_first_summary_row.thick {
#>   border-top-width: 2px;
#> }
#> 
#> #ulbfdpbcyv .gt_last_summary_row {
#>   padding-top: 8px;
#>   padding-bottom: 8px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#>   border-bottom-style: solid;
#>   border-bottom-width: 2px;
#>   border-bottom-color: #D3D3D3;
#> }
#> 
#> #ulbfdpbcyv .gt_grand_summary_row {
#>   color: #333333;
#>   background-color: #FFFFFF;
#>   text-transform: inherit;
#>   padding-top: 8px;
#>   padding-bottom: 8px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#> }
#> 
#> #ulbfdpbcyv .gt_first_grand_summary_row {
#>   padding-top: 8px;
#>   padding-bottom: 8px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#>   border-top-style: double;
#>   border-top-width: 6px;
#>   border-top-color: #D3D3D3;
#> }
#> 
#> #ulbfdpbcyv .gt_last_grand_summary_row_top {
#>   padding-top: 8px;
#>   padding-bottom: 8px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#>   border-bottom-style: double;
#>   border-bottom-width: 6px;
#>   border-bottom-color: #D3D3D3;
#> }
#> 
#> #ulbfdpbcyv .gt_striped {
#>   background-color: rgba(128, 128, 128, 0.05);
#> }
#> 
#> #ulbfdpbcyv .gt_table_body {
#>   border-top-style: solid;
#>   border-top-width: 2px;
#>   border-top-color: #D3D3D3;
#>   border-bottom-style: solid;
#>   border-bottom-width: 2px;
#>   border-bottom-color: #D3D3D3;
#> }
#> 
#> #ulbfdpbcyv .gt_footnotes {
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
#> #ulbfdpbcyv .gt_footnote {
#>   margin: 0px;
#>   font-size: 90%;
#>   padding-top: 4px;
#>   padding-bottom: 4px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#> }
#> 
#> #ulbfdpbcyv .gt_sourcenotes {
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
#> #ulbfdpbcyv .gt_sourcenote {
#>   font-size: 90%;
#>   padding-top: 4px;
#>   padding-bottom: 4px;
#>   padding-left: 5px;
#>   padding-right: 5px;
#> }
#> 
#> #ulbfdpbcyv .gt_left {
#>   text-align: left;
#> }
#> 
#> #ulbfdpbcyv .gt_center {
#>   text-align: center;
#> }
#> 
#> #ulbfdpbcyv .gt_right {
#>   text-align: right;
#>   font-variant-numeric: tabular-nums;
#> }
#> 
#> #ulbfdpbcyv .gt_font_normal {
#>   font-weight: normal;
#> }
#> 
#> #ulbfdpbcyv .gt_font_bold {
#>   font-weight: bold;
#> }
#> 
#> #ulbfdpbcyv .gt_font_italic {
#>   font-style: italic;
#> }
#> 
#> #ulbfdpbcyv .gt_super {
#>   font-size: 65%;
#> }
#> 
#> #ulbfdpbcyv .gt_footnote_marks {
#>   font-size: 75%;
#>   vertical-align: 0.4em;
#>   position: initial;
#> }
#> 
#> #ulbfdpbcyv .gt_asterisk {
#>   font-size: 100%;
#>   vertical-align: 0;
#> }
#> 
#> #ulbfdpbcyv .gt_indent_1 {
#>   text-indent: 5px;
#> }
#> 
#> #ulbfdpbcyv .gt_indent_2 {
#>   text-indent: 10px;
#> }
#> 
#> #ulbfdpbcyv .gt_indent_3 {
#>   text-indent: 15px;
#> }
#> 
#> #ulbfdpbcyv .gt_indent_4 {
#>   text-indent: 20px;
#> }
#> 
#> #ulbfdpbcyv .gt_indent_5 {
#>   text-indent: 25px;
#> }
#> 
#> #ulbfdpbcyv .katex-display {
#>   display: inline-flex !important;
#>   margin-bottom: 0.75em !important;
#> }
#> 
#> #ulbfdpbcyv div.Reactable > div.rt-table > div.rt-thead > div.rt-tr.rt-tr-group-header > div.rt-th-group:after {
#>   height: 0px !important;
#> }
#> </style>
#>   <table class="gt_table" data-quarto-disable-processing="false" data-quarto-bootstrap="false">
#>   <thead>
#>     <tr class="gt_col_headings">
#>       <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="Study">Study</th>
#>       <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="Events">Events</th>
#>       <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="Total">Total</th>
#>       <th class="gt_col_heading gt_columns_bottom_border gt_right" rowspan="1" colspan="1" scope="col" id="Weight-(%)">Weight (%)</th>
#>       <th class="gt_col_heading gt_columns_bottom_border gt_left" rowspan="1" colspan="1" scope="col" id="Proportion-[95%-CI]">Proportion [95% CI]</th>
#>     </tr>
#>   </thead>
#>   <tbody class="gt_table_body">
#>     <tr><td headers="Study" class="gt_row gt_left">Aronson</td>
#> <td headers="Events" class="gt_row gt_right">4</td>
#> <td headers="Total" class="gt_row gt_right">123</td>
#> <td headers="Weight (%)" class="gt_row gt_right">6.9</td>
#> <td headers="Proportion [95% CI]" class="gt_row gt_left">3.3% [0.9 – 8.1]</td></tr>
#>     <tr><td headers="Study" class="gt_row gt_left">Ferguson &amp; Simes</td>
#> <td headers="Events" class="gt_row gt_right">6</td>
#> <td headers="Total" class="gt_row gt_right">306</td>
#> <td headers="Weight (%)" class="gt_row gt_right">7.3</td>
#> <td headers="Proportion [95% CI]" class="gt_row gt_left">2% [0.7 – 4.2]</td></tr>
#>     <tr><td headers="Study" class="gt_row gt_left">Rosenthal et al</td>
#> <td headers="Events" class="gt_row gt_right">3</td>
#> <td headers="Total" class="gt_row gt_right">231</td>
#> <td headers="Weight (%)" class="gt_row gt_right">6.6</td>
#> <td headers="Proportion [95% CI]" class="gt_row gt_left">1.3% [0.3 – 3.7]</td></tr>
#>     <tr><td headers="Study" class="gt_row gt_left">Hart &amp; Sutherland</td>
#> <td headers="Events" class="gt_row gt_right">62</td>
#> <td headers="Total" class="gt_row gt_right">13598</td>
#> <td headers="Weight (%)" class="gt_row gt_right">8.1</td>
#> <td headers="Proportion [95% CI]" class="gt_row gt_left">0.5% [0.3 – 0.6]</td></tr>
#>     <tr><td headers="Study" class="gt_row gt_left">Frimodt-Moller et al</td>
#> <td headers="Events" class="gt_row gt_right">33</td>
#> <td headers="Total" class="gt_row gt_right">5069</td>
#> <td headers="Weight (%)" class="gt_row gt_right">8.0</td>
#> <td headers="Proportion [95% CI]" class="gt_row gt_left">0.7% [0.4 – 0.9]</td></tr>
#>     <tr><td headers="Study" class="gt_row gt_left">Stein &amp; Aronson</td>
#> <td headers="Events" class="gt_row gt_right">180</td>
#> <td headers="Total" class="gt_row gt_right">1541</td>
#> <td headers="Weight (%)" class="gt_row gt_right">8.1</td>
#> <td headers="Proportion [95% CI]" class="gt_row gt_left">11.7% [10.1 – 13.4]</td></tr>
#>     <tr><td headers="Study" class="gt_row gt_left">Vandiviere et al</td>
#> <td headers="Events" class="gt_row gt_right">8</td>
#> <td headers="Total" class="gt_row gt_right">2545</td>
#> <td headers="Weight (%)" class="gt_row gt_right">7.5</td>
#> <td headers="Proportion [95% CI]" class="gt_row gt_left">0.3% [0.1 – 0.6]</td></tr>
#>     <tr><td headers="Study" class="gt_row gt_left">TPT Madras</td>
#> <td headers="Events" class="gt_row gt_right">505</td>
#> <td headers="Total" class="gt_row gt_right">88391</td>
#> <td headers="Weight (%)" class="gt_row gt_right">8.2</td>
#> <td headers="Proportion [95% CI]" class="gt_row gt_left">0.6% [0.5 – 0.6]</td></tr>
#>     <tr><td headers="Study" class="gt_row gt_left">Coetzee &amp; Berjak</td>
#> <td headers="Events" class="gt_row gt_right">29</td>
#> <td headers="Total" class="gt_row gt_right">7499</td>
#> <td headers="Weight (%)" class="gt_row gt_right">8.0</td>
#> <td headers="Proportion [95% CI]" class="gt_row gt_left">0.4% [0.3 – 0.6]</td></tr>
#>     <tr><td headers="Study" class="gt_row gt_left">Rosenthal et al.1</td>
#> <td headers="Events" class="gt_row gt_right">17</td>
#> <td headers="Total" class="gt_row gt_right">1716</td>
#> <td headers="Weight (%)" class="gt_row gt_right">7.9</td>
#> <td headers="Proportion [95% CI]" class="gt_row gt_left">1% [0.6 – 1.6]</td></tr>
#>     <tr><td headers="Study" class="gt_row gt_left">Comstock et al</td>
#> <td headers="Events" class="gt_row gt_right">186</td>
#> <td headers="Total" class="gt_row gt_right">50634</td>
#> <td headers="Weight (%)" class="gt_row gt_right">8.2</td>
#> <td headers="Proportion [95% CI]" class="gt_row gt_left">0.4% [0.3 – 0.4]</td></tr>
#>     <tr><td headers="Study" class="gt_row gt_left">Comstock &amp; Webster</td>
#> <td headers="Events" class="gt_row gt_right">5</td>
#> <td headers="Total" class="gt_row gt_right">2498</td>
#> <td headers="Weight (%)" class="gt_row gt_right">7.2</td>
#> <td headers="Proportion [95% CI]" class="gt_row gt_left">0.2% [0.1 – 0.5]</td></tr>
#>     <tr><td headers="Study" class="gt_row gt_left">Comstock et al.1</td>
#> <td headers="Events" class="gt_row gt_right">27</td>
#> <td headers="Total" class="gt_row gt_right">16913</td>
#> <td headers="Weight (%)" class="gt_row gt_right">8.0</td>
#> <td headers="Proportion [95% CI]" class="gt_row gt_left">0.2% [0.1 – 0.2]</td></tr>
#>     <tr><td headers="Study" class="gt_row gt_left" style="font-weight: bold;">Pooled</td>
#> <td headers="Events" class="gt_row gt_right" style="font-weight: bold;">NA</td>
#> <td headers="Total" class="gt_row gt_right" style="font-weight: bold;">NA</td>
#> <td headers="Weight (%)" class="gt_row gt_right" style="font-weight: bold;">NA</td>
#> <td headers="Proportion [95% CI]" class="gt_row gt_left" style="font-weight: bold;">0.7% [0.4 – 1.6]  (I² = 99.2%)<span class="gt_footnote_marks" style="white-space:nowrap;font-style:italic;font-weight:normal;line-height:0;"><sup>1</sup></span></td></tr>
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
