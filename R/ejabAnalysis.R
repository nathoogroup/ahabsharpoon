ejabAnalysis <- function(jaspResults, dataset, options) {

  # Check if required variables are assigned
  if (length(options$p) == 0 || options$p == "" ||
      length(options$n) == 0 || options$n == "" ||
      length(options$q) == 0 || options$q == "" ||
      length(options$study_nums) == 0 || options$study_nums == "")
    return()

  # Read data. n and q accept ordinal columns (see inst/qml/EjabAnalysis.qml);
  # JASP delivers ordinal data as a factor, so coerce through as.character() to
  # recover the numeric labels rather than the factor level codes.
  asNumericCol <- function(x) if (is.factor(x)) as.numeric(as.character(x)) else as.numeric(x)
  p_vals    <- dataset[[options$p]]
  n_vals    <- asNumericCol(dataset[[options$n]])
  q_vals    <- asNumericCol(dataset[[options$q]])
  study_num <- dataset[[options$study_nums]]
  complete_cases <- complete.cases(p_vals, n_vals, q_vals, study_num) &
                   p_vals > 0 & p_vals < 1 &
                   n_vals > 1 &
                   q_vals >= 1
  p_vals    <- p_vals[complete_cases]
  n_vals    <- n_vals[complete_cases]
  q_vals    <- q_vals[complete_cases]
  study_num <- study_num[complete_cases]

  if (length(p_vals) == 0) {
    errorContainer <- createJaspContainer(gettext("eJAB Analysis"))
    errorContainer$setError(gettext(
      "No usable rows after filtering. The analysis requires p in (0, 1), n > 1, and q >= 1, with no missing values in any assigned column."
    ))
    jaspResults[["errorContainer"]] <- errorContainer
    return()
  }

  # Extract options, ensuring they are scalars
  alpha      <- as.numeric(options$alpha)[1]
  up         <- as.numeric(options$up)[1]
  grid_range <- c(as.numeric(options$lowerBound)[1], as.numeric(options$upperBound)[1])
  grid_n     <- as.integer(options$grid_size)[1]

  # Compute eJAB values (vendored from ejabT1E; see R/ejabCore.R)
  ejab_vals <- ejab01(p_vals, n_vals, q_vals)

  # Estimate C* using the integral method (minimises integrated squared deviation)
  fit <- estimate_Cstar(p_vals, ejab_vals, up = up,
                        grid_range = grid_range, grid_n = grid_n)
  Cstar_at_alpha     <- fit$Cstar
  objective_at_alpha <- fit$objective

  # Detect candidates using C* at the specified alpha
  candidates_idx <- detect_type1(p_vals, ejab_vals, alpha, Cstar_at_alpha)

  # Summary table
  if (is.null(jaspResults[["summaryContainer"]])) {
    summaryContainer <- createJaspContainer(gettext("eJAB Summary"))
    summaryContainer$dependOn(c("p", "n", "q", "study_nums", "alpha", "up", "lowerBound", "upperBound", "grid_size"))

    tbl <- createJaspTable()
    tbl$addColumnInfo(name = "cstar",      title = gettext("C*(α)"),       type = "number")
    tbl$addColumnInfo(name = "objective",  title = gettext("Objective"),   type = "number")
    tbl$addColumnInfo(name = "candidates", title = gettext("Candidates"),  type = "integer")
    tbl$addColumnInfo(name = "total",      title = gettext("Total"),       type = "integer")

    tbl[["cstar"]]      <- Cstar_at_alpha
    tbl[["objective"]]  <- objective_at_alpha
    tbl[["candidates"]] <- length(candidates_idx)
    tbl[["total"]]      <- length(p_vals)

    summaryContainer[["table"]] <- tbl
    jaspResults[["summaryContainer"]] <- summaryContainer
  }

  # Candidates table
  if (is.null(jaspResults[["candidatesContainer"]])) {
    candidatesContainer <- createJaspContainer(gettext("Candidate Type I Errors"))
    candidatesContainer$dependOn(c("p", "n", "q", "study_nums", "alpha", "up", "lowerBound", "upperBound", "grid_size"))

    ctbl <- createJaspTable()

    ctbl$addColumnInfo(name = "study",   title = gettext("Study ID"),   type = "string")
    ctbl$addColumnInfo(name = "pval",    title = gettext("p-value"),    type = "number")
    ctbl$addColumnInfo(name = "nval",    title = gettext("n"),          type = "integer")
    ctbl$addColumnInfo(name = "qval",    title = gettext("q"),          type = "integer")
    ctbl$addColumnInfo(name = "ejab",    title = gettext("eJAB01"),     type = "number")
    ctbl$addColumnInfo(name = "ejab10",  title = gettext("eJAB10"),     type = "number")
    ctbl$addColumnInfo(name = "z",       title = gettext("Z"),          type = "number")
    ctbl$addColumnInfo(name = "flagged", title = gettext("Outside ±2"), type = "string")

    if (length(candidates_idx) > 0) {
      # Per-candidate Z diagnostic: Z = qnorm(U) is N(0,1) under left-tail
      # uniformity. |Z| > 2 (or U at exactly 0/1, which gives a non-finite Z)
      # puts the candidate outside the ±2 bands and flags it as a likely
      # non-Type-I-error. Matches the red points in the Z-diagnostic plots.
      U_cand    <- diagnostic_U(p_vals[candidates_idx], n_vals[candidates_idx],
                                q_vals[candidates_idx], alpha, Cstar_at_alpha)
      Z_cand    <- stats::qnorm(U_cand)
      flag_cand <- !is.finite(Z_cand) | abs(Z_cand) > 2
      Z_cand[!is.finite(Z_cand)] <- NA_real_

      ctbl[["study"]]   <- as.character(study_num[candidates_idx])
      ctbl[["pval"]]    <- p_vals[candidates_idx]
      ctbl[["nval"]]    <- n_vals[candidates_idx]
      ctbl[["qval"]]    <- q_vals[candidates_idx]
      ctbl[["ejab"]]    <- ejab_vals[candidates_idx]
      ctbl[["ejab10"]]  <- 1 / ejab_vals[candidates_idx]
      ctbl[["z"]]       <- Z_cand
      ctbl[["flagged"]] <- ifelse(flag_cand, gettext("Yes"), gettext("No"))
    } else {
      ctbl$addFootnote(gettext("No candidate Type I errors detected."))
    }

    candidatesContainer[["table"]] <- ctbl
    jaspResults[["candidatesContainer"]] <- candidatesContainer
  }

  allDeps <- c("p", "n", "q", "study_nums", "up", "alpha",
               "lowerBound", "upperBound", "grid_size",
               "showCalibrationPlot", "showZDiagnostic")

  # Axis tick formatter: whole numbers print without decimals, genuine
  # decimals keep theirs with trailing zeros dropped (0 -> "0", 1 -> "1",
  # 0.25 -> "0.25"). Applied to every plot scale so ggplot2 does not pad
  # ticks to a common width (e.g. "0.00", "1.00").
  fmtAxis <- function(x) {
    # formatC right-justifies a vector to a common width; trimws strips that
    # padding so each label stays centred on its own tick.
    out <- trimws(formatC(x, format = "g", digits = 7))
    out[is.na(x)] <- ""
    out
  }

  # --- Calibration curve: observed contradiction proportion vs alpha ---
  if (isTRUE(options$showCalibrationPlot) && is.null(jaspResults[["calibrationCurve"]])) {
    alpha_grid <- seq(0, up, length.out = 200)[-1]
    N_cal <- sum(p_vals < up)
    proportions <- vapply(alpha_grid, function(a)
      sum(p_vals <= a & ejab_vals > Cstar_at_alpha) / N_cal, numeric(1))
    keep <- alpha_grid <= alpha
    calDf <- data.frame(alpha = alpha_grid[keep], proportion = proportions[keep])
    refDf <- data.frame(alpha = c(0, alpha), proportion = c(0, alpha / up))

    p1 <- ggplot2::ggplot(calDf, ggplot2::aes(x = alpha, y = proportion)) +
      ggplot2::geom_line(linewidth = 1) +
      ggplot2::geom_line(data = refDf, linetype = "dashed", color = "grey60", linewidth = 1) +
      ggplot2::scale_x_continuous(limits = c(0, alpha), labels = fmtAxis) +
      ggplot2::scale_y_continuous(limits = c(0, max(calDf$proportion, alpha / up) * 1.1),
                                  labels = fmtAxis) +
      ggplot2::labs(x = expression(alpha), y = "Observed Proportion") +
      jaspGraphs::geom_rangeframe() +
      jaspGraphs::themeJaspRaw() +
      ggplot2::theme(plot.margin = ggplot2::margin(5.5, 20, 5.5, 5.5))

    calCurve <- createJaspPlot(plot = p1,
                                title = gettextf("Calibration Curve (α ≤ %s)", alpha),
                                width = 480, height = 400)
    calCurve$dependOn(allDeps)
    jaspResults[["calibrationCurve"]] <- calCurve
  }

  # --- Z-diagnostic plots (normal-score transform of the U diagnostic) ---
  # The candidate diagnostic U is Unif(0,1) under the left-tail uniformity
  # assumption, so Z = qnorm(U) is N(0,1). Z reads more easily: the normal
  # QQ-plot needs no probability bands, and the index plot gets flat bands at
  # -2 and +2 (about 95% of N(0,1) lies within). Candidates with |Z| > 2 fall
  # outside the bands and are likely not Type I errors. See the source-of-truth
  # script at RPackage/Scripts/z_diagnostic.R.
  if (isTRUE(options$showZDiagnostic)) {

    # Z is computed once and shared by both plots. qnorm(U) is +/-Inf when U is
    # exactly 0 or 1 (diagnostic out of range); drop those few cases so the
    # best-fit line and the index plot stay well defined.
    if (length(candidates_idx) > 0) {
      U <- diagnostic_U(p_vals[candidates_idx], n_vals[candidates_idx],
                        q_vals[candidates_idx], alpha, Cstar_at_alpha)
      Z <- stats::qnorm(U)
      Z <- Z[is.finite(Z)]
    } else {
      Z <- numeric(0)
    }
    n_z <- length(Z)

    # Plot 1: normal QQ-plot of Z (OLS best-fit line, no bands)
    if (is.null(jaspResults[["zQqPlot"]])) {
      zQqTitle <- gettextf("Z-Diagnostic Normal QQ-Plot (α = %s, C* = %s)",
                           alpha, round(Cstar_at_alpha, 4))
      if (n_z > 0) {
        theoretical <- stats::qnorm(stats::ppoints(n_z))
        observed    <- sort(Z)

        # OLS best-fit line (C* is estimated, so the 45-degree line is inappropriate)
        fit_line <- stats::lm(observed ~ theoretical)
        int_ols  <- as.numeric(stats::coef(fit_line)[1])
        slp_ols  <- as.numeric(stats::coef(fit_line)[2])

        qqDf <- data.frame(theoretical = theoretical, observed = observed,
                           flagged = factor(abs(observed) > 2, levels = c(FALSE, TRUE)))

        pz1 <- ggplot2::ggplot(qqDf, ggplot2::aes(x = theoretical, y = observed)) +
          ggplot2::geom_abline(intercept = int_ols, slope = slp_ols,
                               color = "grey60", linetype = "dashed", linewidth = 1) +
          ggplot2::geom_point(ggplot2::aes(color = flagged), size = 1.5) +
          ggplot2::scale_color_manual(name = NULL,
                                      values = c(`FALSE` = "black", `TRUE` = "red"),
                                      labels = c(`FALSE` = "within ±2", `TRUE` = "outside ±2"),
                                      drop = FALSE) +
          ggplot2::labs(x = "Theoretical N(0, 1) Quantiles",
                        y = "Observed Z Quantiles") +
          ggplot2::scale_x_continuous(labels = fmtAxis) +
          ggplot2::scale_y_continuous(labels = fmtAxis) +
          jaspGraphs::geom_rangeframe() +
          jaspGraphs::themeJaspRaw() +
          ggplot2::theme(legend.position = "bottom",
                         legend.text = ggplot2::element_text(margin = ggplot2::margin(r = 16, l = 2)),
                         plot.margin = ggplot2::margin(5.5, 20, 5.5, 5.5))

        zQqPlot <- createJaspPlot(plot = pz1, title = zQqTitle,
                                  width = 480, height = 400)
      } else {
        zQqPlot <- createJaspPlot(title = zQqTitle, width = 480, height = 400)
        zQqPlot$setError(gettext("No candidate Type I errors detected; cannot produce QQ-plot."))
      }
      zQqPlot$dependOn(allDeps)
      jaspResults[["zQqPlot"]] <- zQqPlot
    }

    # Plot 2: Z vs candidate index, with flat reference bands at -2 and +2
    if (is.null(jaspResults[["zIndexPlot"]])) {
      zIndexTitle <- gettextf("Z-Diagnostic vs Index (α = %s)", alpha)
      if (n_z > 0) {
        idxDf <- data.frame(index = seq_len(n_z), Z = Z,
                           flagged = factor(abs(Z) > 2, levels = c(FALSE, TRUE)))
        yr    <- range(Z, -2.5, 2.5)

        pz2 <- ggplot2::ggplot(idxDf, ggplot2::aes(x = index, y = Z)) +
          ggplot2::geom_hline(yintercept = c(-2, 2), linetype = "dashed",
                              color = "grey60", linewidth = 1) +
          ggplot2::geom_point(ggplot2::aes(color = flagged), size = 1.8) +
          ggplot2::scale_color_manual(name = NULL,
                                      values = c(`FALSE` = "black", `TRUE` = "red"),
                                      labels = c(`FALSE` = "within ±2", `TRUE` = "outside ±2"),
                                      drop = FALSE) +
          ggplot2::labs(x = "Candidate Index", y = "Z Diagnostic") +
          ggplot2::scale_x_continuous(labels = fmtAxis) +
          ggplot2::scale_y_continuous(limits = yr, labels = fmtAxis) +
          jaspGraphs::geom_rangeframe() +
          jaspGraphs::themeJaspRaw() +
          ggplot2::theme(legend.position = "bottom",
                         legend.text = ggplot2::element_text(margin = ggplot2::margin(r = 16, l = 2)),
                         plot.margin = ggplot2::margin(5.5, 20, 5.5, 5.5))

        zIndexPlot <- createJaspPlot(plot = pz2, title = zIndexTitle,
                                     width = 600, height = 400)
      } else {
        zIndexPlot <- createJaspPlot(title = zIndexTitle, width = 600, height = 400)
        zIndexPlot$setError(gettext("No candidate Type I errors detected; cannot produce index plot."))
      }
      zIndexPlot$dependOn(allDeps)
      jaspResults[["zIndexPlot"]] <- zIndexPlot
    }
  }
}
