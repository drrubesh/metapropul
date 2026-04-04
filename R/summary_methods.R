#' @keywords internal
.cat_note <- function(..., indent = 2L) {
  txt <- paste0(..., collapse = "")
  wrapped <- strwrap(
    txt,
    width = 78,
    indent = indent,
    exdent = indent
  )
  cat(paste0(wrapped, collapse = "\n"), "\n", sep = "")
}

#' @keywords internal
.cat_section <- function(title) {
  cat("\n", title, "\n", sep = "")
  cat(paste(rep("-", nchar(title)), collapse = ""), "\n", sep = "")
}

#' @keywords internal
.print_subgroup_summary <- function(x) {
  if (is.null(x) || nrow(x) == 0) {
    return(invisible(NULL))
  }

  for (i in seq_len(nrow(x))) {
    cat(sprintf(
      "%s: %.2f (95%% CI: %.2f, %.2f)",
      x$Subgroup[i],
      x$Estimate[i],
      x$lower[i],
      x$upper[i]
    ))

    if ("Tau2" %in% names(x) && !is.na(x$Tau2[i])) {
      cat(sprintf(", Tau\u00b2 = %.4f", x$Tau2[i]))
    }

    if ("I2" %in% names(x) && !is.na(x$I2[i])) {
      cat(sprintf(", I\u00b2 = %.1f%%", x$I2[i]))
    }

    cat("\n")
  }

  invisible(NULL)
}

#' @keywords internal
.summary_meta_generic <- function(
  object,
  type = c("ratio", "prop", "mean"),
  ...
) {
  type <- match.arg(type)
  meta_result <- object$meta
  model <- object$model
  measure <- object$measure

  cat("\nMeta-analysis Summary\n")
  cat("----------------------\n")
  cat(sprintf("Number of studies: %d\n", meta_result$k))

  if (type != "prop" && all(c("n.e", "n.c") %in% names(meta_result))) {
    has_group_totals <- !is.null(meta_result$n.e) &&
      !is.null(meta_result$n.c) &&
      length(meta_result$n.e) > 0L &&
      length(meta_result$n.c) > 0L &&
      any(!is.na(meta_result$n.e)) &&
      any(!is.na(meta_result$n.c))

    if (isTRUE(has_group_totals)) {
      n_exp <- sum(meta_result$n.e, na.rm = TRUE)
      n_con <- sum(meta_result$n.c, na.rm = TRUE)
      total_n <- n_exp + n_con

      cat(sprintf(
        "Total observations: %s (%s experimental, %s control)\n",
        formatC(total_n, format = "d", big.mark = ","),
        formatC(n_exp, format = "d", big.mark = ","),
        formatC(n_con, format = "d", big.mark = ",")
      ))

      has_event_totals <- !is.null(meta_result$event.e) &&
        !is.null(meta_result$event.c) &&
        length(meta_result$event.e) > 0L &&
        length(meta_result$event.c) > 0L &&
        any(!is.na(meta_result$event.e)) &&
        any(!is.na(meta_result$event.c))

      if (isTRUE(has_event_totals)) {
        ev_exp <- sum(meta_result$event.e, na.rm = TRUE)
        ev_con <- sum(meta_result$event.c, na.rm = TRUE)

        cat(sprintf(
          "Total events: %s\n",
          formatC(ev_exp + ev_con, format = "d", big.mark = ",")
        ))
      }
    } else {
      cat(
        "Total observations: not available from pre-computed effect sizes\n"
      )
    }
  }

  i2_val <- NA_real_
  tau2_val <- NA_real_

  cat("\n")

  if (type == "prop") {
    s <- object$meta.summary
    pi_lower <- s$pred.lower
    pi_upper <- s$pred.upper
    i2_val <- s$I2
    tau2_val <- s$Tau2

    cat(sprintf(
      "Overall pooled proportion = %.1f%% (95%% CI: %.1f%%, %.1f%%)\n",
      s$Estimate, s$lower, s$upper
    ))

    if (!is.na(pi_lower) && !is.na(pi_upper)) {
      cat(sprintf(
        "Prediction interval: %.1f%% \u2013 %.1f%%\n",
        pi_lower, pi_upper
      ))
    }

    Q_val <- meta_result$Q
    df_val <- meta_result$df.Q
    pQ_val <- meta_result$pval.Q

    if (!is.null(Q_val) && !is.na(Q_val)) {
      cat(sprintf(
        "Q = %.2f (df = %d), p %s\n",
        Q_val, df_val, .fmt_pval(pQ_val)
      ))
    }

    cat(sprintf("I\u00b2 = %.1f%%\n", .format_i2(i2_val)))
    cat(sprintf("Tau\u00b2 = %.4f\n", tau2_val))
  } else {
    is_ratio <- measure %in% c("OR", "RR", "HR")
    i2_val <- meta_result$I2
    tau2_val <- meta_result$tau2

    if (identical(model, "random")) {
      est <- meta_result$TE.random
      lci <- meta_result$lower.random
      uci <- meta_result$upper.random
      pval <- meta_result$pval.random
      pi_low <- meta_result$lower.predict
      pi_high <- meta_result$upper.predict
    } else {
      est <- meta_result$TE.common
      lci <- meta_result$lower.common
      uci <- meta_result$upper.common
      pval <- meta_result$pval.common
      pi_low <- NA_real_
      pi_high <- NA_real_
    }

    if (is_ratio) {
      est <- exp(est)
      lci <- exp(lci)
      uci <- exp(uci)
      pi_low <- if (!is.na(pi_low)) exp(pi_low) else NA_real_
      pi_high <- if (!is.na(pi_high)) exp(pi_high) else NA_real_
    }

    cat(sprintf(
      "Overall pooled %s = %.2f (95%% CI: %.2f, %.2f)\n",
      measure, est, lci, uci
    ))

    if (!is.na(pi_low) && !is.na(pi_high)) {
      cat(sprintf(
        "Prediction interval: %.2f \u2013 %.2f\n",
        pi_low, pi_high
      ))
    }

    cat(sprintf("p-value = %s\n", .fmt_pval(pval)))

    Q_val <- meta_result$Q
    df_val <- meta_result$df.Q
    pQ_val <- meta_result$pval.Q

    if (!is.null(Q_val) && !is.na(Q_val)) {
      cat(sprintf(
        "Q = %.2f (df = %d), p %s\n",
        Q_val, df_val, .fmt_pval(pQ_val)
      ))
    }

    cat(sprintf("I\u00b2 = %.1f%%\n", .format_i2(i2_val)))
    cat(sprintf("Tau\u00b2 = %.4f\n", tau2_val))
  }

  if (isTRUE(object$subgroup)) {
    .cat_section("Subgroup results")

    if (!is.null(object$meta.subgroup.summary)) {
      .print_subgroup_summary(object$meta.subgroup.summary)

      if ("I2" %in% names(object$meta.subgroup.summary)) {
        i2_tmp <- object$meta.subgroup.summary$I2
        if (length(i2_tmp) > 0 && any(!is.na(i2_tmp))) {
          i2_val <- max(i2_tmp, na.rm = TRUE)
        }
      }
    }

    if (identical(model, "random") && !is.null(meta_result$Q.b.random)) {
      cat(sprintf(
        "\nTest for subgroup differences (random): Q = %.2f, df = %d, p %s\n",
        meta_result$Q.b.random,
        meta_result$df.Q.b.random,
        .fmt_pval(meta_result$pval.Q.b.random)
      ))
    } else if (identical(model, "fixed") &&
      !is.null(meta_result$Q.b.common)) {
      cat(sprintf(
        "\nTest for subgroup differences (common): Q = %.2f, df = %d, p %s\n",
        meta_result$Q.b.common,
        meta_result$df.Q.b.common,
        .fmt_pval(meta_result$pval.Q.b.common)
      ))
    }
  }

  .cat_section("Notes")

  if (type == "prop") {
    sm_used <- if (!is.null(object$sm)) object$sm else "PLOGIT"

    if (identical(sm_used, "PLOGIT")) {
      .cat_note(
        "- Proportions pooled using logit transformation and ",
        "back-transformed to percentages."
      )
    } else if (identical(sm_used, "PFT")) {
      .cat_note(
        "- Proportions pooled using Freeman-Tukey double arcsine ",
        "transformation and back-transformed to percentages."
      )
      .cat_note("- PFT may be useful when proportions are close to 0 or 1.")
    } else {
      .cat_note(
        sprintf(
          "- Proportions pooled using %s and back-transformed ",
          sm_used
        ),
        "to percentages."
      )
    }

    .cat_note(
      "- p-value omitted for pooled proportions; focus on the ",
      "confidence interval and prediction interval."
    )
  } else {
    if (identical(measure, "OR")) {
      .cat_note(
        "- Pooled OR < 1 indicates lower odds in the experimental group."
      )
    } else if (identical(measure, "RR")) {
      .cat_note(
        "- Pooled RR < 1 indicates lower risk in the experimental group."
      )
    } else if (identical(measure, "HR")) {
      .cat_note(
        "- Pooled HR < 1 indicates lower hazard in the experimental group."
      )
    } else {
      .cat_note(sprintf("- Continuous outcomes pooled as %s.", measure))
    }
  }

  .cat_note(
    "- I\u00b2 quantifies the proportion of total variability ",
    "attributable to between-study heterogeneity rather than ",
    "sampling error."
  )
  .cat_note(
    "- However, I\u00b2 increases with study precision and may ",
    "approach 100% even when Tau\u00b2 remains unchanged."
  )
  .cat_note(
    "- Therefore, I\u00b2 should not be used alone to judge ",
    "heterogeneity or decide whether studies should be pooled."
  )
  .cat_note(
    "- Tau\u00b2 represents the variance of true effects across ",
    "studies and is generally more informative than I\u00b2 for ",
    "judging the magnitude of heterogeneity."
  )

  if (!is.na(i2_val) && i2_val >= 75) {
    .cat_note(
      "- High I\u00b2 observed. Interpret cautiously because I\u00b2 ",
      "may be inflated in large or highly precise studies."
    )
  }

  if (identical(model, "random")) {
    .cat_note(
      "- The prediction interval shows the range of effects expected ",
      "in a new study and helps assess clinical relevance."
    )

    if (!is.null(object$ci_method)) {
      .cat_note(
        sprintf(
          "- Confidence interval method for random-effects model: %s.",
          object$ci_method
        )
      )
    }
  } else {
    .cat_note(
      "- Common-effect model used; Tau\u00b2 is reported descriptively ",
      "but not used for weighting."
    )
  }

  if (isTRUE(object$subgroup)) {
    .cat_note(
      "- The subgroup-difference test assesses whether pooled effects ",
      "differ between subgroup levels; a non-significant result does ",
      "not prove the subgroups are equivalent."
    )
    .cat_note(
      "- Subgroup-specific prediction intervals are not shown in this ",
      "summary."
    )
  }

  .cat_note(
    "- Decisions to pool studies should be based on clinical ",
    "relevance, not solely on statistical heterogeneity."
  )

  cat("\nFor study-level results: object$table\n")
  invisible(object)
}

#' @keywords internal
.fmt_pval <- function(p) {
  if (is.null(p) || is.na(p)) {
    return("NA")
  }
  if (p < 0.001) {
    return("< 0.001")
  }
  sprintf("= %.3f", p)
}

#' @export
summary.meta_ratio <- function(object, ...) {
  .summary_meta_generic(object, type = "ratio", ...)
}

#' @export
summary.meta_mean <- function(object, ...) {
  .summary_meta_generic(object, type = "mean", ...)
}

#' @export
summary.meta_prop <- function(object, ...) {
  .summary_meta_generic(object, type = "prop", ...)
}

#' @export
print.meta_ratio <- function(x, ...) {
  summary(x, ...)
}

#' @export
print.meta_mean <- function(x, ...) {
  summary(x, ...)
}

#' @export
print.meta_prop <- function(x, ...) {
  summary(x, ...)
}


#' @export
summary.meta_reg <- function(object, ...) {
  cat("\nMeta-regression Summary\n")
  cat("------------------------\n")

  ms <- object$meta.summary
  ms$tau2_null <- round(ms$tau2_null, 4)
  ms$tau2 <- round(ms$tau2, 4)
  ms$R2_analog <- if (is.na(ms$R2_analog)) {
    NA_real_
  } else {
    round(ms$R2_analog, 2)
  }
  print(ms)

  cat("\nCoefficients (model scale):\n")
  cat("---------------------------\n")

  tbl <- object$table
  bt_label <- attr(tbl, "bt_label")

  print(as.data.frame(
    tbl[, c("Term", "Estimate", "CI.Lower", "CI.Upper", "p.value")]
  ))

  show_bt <- !is.null(bt_label) &&
    !is.na(bt_label) &&
    any(tbl$backtransformable, na.rm = TRUE)

  if (isTRUE(show_bt)) {
    cat(sprintf("\nModerator effects on %s:\n", bt_label))
    cat("--------------------------------\n")

    bt_tbl <- tbl[tbl$backtransformable, , drop = FALSE]
    bt_tbl <- bt_tbl[, c("Term", "Estimate_bt", "CI.Lower_bt", "CI.Upper_bt")]
    names(bt_tbl) <- c("Term", "Estimate", "CI.Lower", "CI.Upper")
    print(as.data.frame(bt_tbl))
  }

  scale_note <- switch(
    object$measure,
    "OR" = paste(
      "- Model-scale estimates are log odds ratios.",
      "Moderator effects are back-transformed to the OR scale."
    ),
    "RR" = paste(
      "- Model-scale estimates are log risk ratios.",
      "Moderator effects are back-transformed to the RR scale."
    ),
    "HR" = paste(
      "- Model-scale estimates are log hazard ratios.",
      "Moderator effects are back-transformed to the HR scale."
    ),
    "MD" = "- Estimates are on the mean difference scale.",
    "SMD" = "- Estimates are on the standardised mean difference scale.",
    "Proportion" = if (!is.null(object$sm) &&
                       identical(object$sm, "PLOGIT")) {
      paste(
        "- Model-scale estimates are on the logit scale.",
        "Moderator effects are back-transformed to percentages."
      )
    } else {
      paste(
        "- Proportion meta-regression output should be interpreted",
        "on the model scale used in fitting."
      )
    },
    "- Estimates are on the model's internal scale."
  )

  r2 <- object$r2_analog
  tau2_null <- object$meta.summary$tau2_null
  tau2_model <- object$meta.summary$tau2

  r2_note <- if (is.null(r2) || is.na(r2)) {
    paste(
      "- R\u00b2 analog is not meaningful because heterogeneity",
      "in the null model was near zero."
    )
  } else if (r2 <= 0 && tau2_model > tau2_null) {
    paste(
      "- R\u00b2 analog = 0%: moderators did not reduce between-study",
      "variance. Residual heterogeneity was larger than in the null model."
    )
  } else if (r2 <= 0) {
    paste(
      "- R\u00b2 analog = 0%: moderators did not reduce between-study",
      "variance."
    )
  } else if (r2 < 25) {
    paste0(
      "- R\u00b2 analog = ", r2,
      "%: modest proportion of between-study variance explained."
    )
  } else if (r2 < 50) {
    paste0(
      "- R\u00b2 analog = ", r2,
      "%: moderate proportion of between-study variance explained."
    )
  } else {
    paste0(
      "- R\u00b2 analog = ", r2,
      "%: substantial proportion of between-study variance explained."
    )
  }

  .cat_section("Notes")
  .cat_note(scale_note)
  .cat_note(
    "- The intercept is not back-transformed because it is often not ",
    "interpretable unless continuous moderators are centered."
  )
  .cat_note(
    "- In models with interactions or uncentered continuous moderators, ",
    "some coefficient-based back-transformations may be difficult to ",
    "interpret because they depend on reference values of other moderators."
  )
  .cat_note(r2_note)
  .cat_note(
    "- QE tests residual heterogeneity after accounting for moderators."
  )
  .cat_note(
    "- QM tests whether moderators jointly explain heterogeneity."
  )
  .cat_note("- Use object$meta to access the full rma() model.")

  invisible(object)
}

#' @export
print.meta_reg <- function(x, ...) {
  summary(x, ...)
}
