#!/usr/bin/env Rscript
# ============================================================
# build.R — Build the metapropul bookdown website
# Run from the project root:  Rscript build.R
# ============================================================

# Install bookdown if needed
if (!requireNamespace("bookdown", quietly = TRUE)) {
  install.packages("bookdown")
}

# Build the gitbook (HTML)
bookdown::render_book(
  input = "index.Rmd",
  output_format = "bookdown::gitbook",
  clean = TRUE
)

# Optionally build PDF
# bookdown::render_book(
#   input       = "index.Rmd",
#   output_format = "bookdown::pdf_book"
# )

message("\n✓ bookdown site built successfully.")
message("  Open docs/index.html in your browser to preview.")
message("  Deploy the docs/ folder to GitHub Pages.")
