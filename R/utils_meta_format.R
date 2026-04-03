# Back-transform proportions depending on method
.backtransform_prop <- function(x, sm) {
  if (sm == "PLOGIT") {
    stats::plogis(x)
  } else if (sm == "PFT") {
    # Freeman–Tukey inverse approximation
    return((sin(x / 2))^2)
  } else {
    stop("Unsupported summary measure for proportions.")
  }
}

# Format I2 safely (auto-detect scale)
.format_i2 <- function(i2) {
  out <- rep(NA_real_, length(i2))
  keep <- !is.na(i2)
  out[keep & i2 <= 1] <- round(i2[keep & i2 <= 1] * 100, 1)
  out[keep & i2 > 1] <- round(i2[keep & i2 > 1], 1)
  out
}
