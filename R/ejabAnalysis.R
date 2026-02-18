ejabAnalysis <- function(jaspResults, dataset, options) {

  # Check if required variables are assigned
  if (length(options$p) == 0 || options$p == "" || 
      length(options$n) == 0 || options$n == "" || 
      length(options$q) == 0 || options$q == "" || 
      length(options$study_nums) == 0 || options$study_nums == "")
    return()

  # Read data
  p_vals <- dataset[[options$p]]
  n_vals <- dataset[[options$n]]
  q_vals <- dataset[[options$q]]
  study_num  <- dataset[[options$study_nums]]
  complete_cases <- complete.cases(p_vals, n_vals, q_vals, study_num) &
                  p_vals > 0 & p_vals < 1 &
                  n_vals > 1 &
                  q_vals >= 1
  p_vals = p_vals[complete_cases]
  n_vals = n_vals[complete_cases]
  q_vals = q_vals[complete_cases]
  study_num = study_num[complete_cases]

  # Extract options, ensuring they are scalars
  alpha <- as.numeric(options$alpha)[1]
  up    <- as.numeric(options$up)[1]
  grid_range <- c(as.numeric(options$lowerBound)[1], as.numeric(options$upperBound)[1])
  grid_n <- as.integer(options$grid_size)[1]

  # Compute eJAB values
  ejab_vals <- ejabT1E::ejab01(p_vals, n_vals, q_vals)

  # Estimate C* for different alpha values and get C* at the specified alpha
  fit_alpha <- ejabT1E::estimate_Cstar_alpha(p_vals, ejab_vals, up = up,
                                              grid_range = grid_range, grid_n = grid_n)
  # Find C* at the specified alpha (find nearest alpha in grid)
  nearest_idx <- which.min(abs(fit_alpha$alpha_grid - alpha))
  Cstar_at_alpha <- fit_alpha$Cstar_alpha[nearest_idx]
  
  # Also compute the objective at this C* for the summary table
  objective_at_alpha <- ejabT1E::objective_C(Cstar_at_alpha, p_vals, ejab_vals, up)

  # Detect candidates using C* at the specified alpha
  candidates_idx <- ejabT1E::detect_type1(p_vals, ejab_vals, alpha, Cstar_at_alpha)

  # Summary table
  if (is.null(jaspResults[["summaryTable"]])) {
    tbl <- createJaspTable(gettext("eJAB Summary"))
    tbl$dependOn(c("p", "n", "q", "study_nums", "alpha", "up", "lowerBound", "upperBound", "grid_size"))

    tbl$addColumnInfo(name = "cstar",      title = gettext("C*(α)"),          type = "number")
    tbl$addColumnInfo(name = "objective",   title = gettext("Objective"),   type = "number")
    tbl$addColumnInfo(name = "candidates",  title = gettext("Candidates"),  type = "integer")
    tbl$addColumnInfo(name = "total",       title = gettext("Total"),       type = "integer")

    tbl[["cstar"]]     <- Cstar_at_alpha
    tbl[["objective"]]  <- objective_at_alpha
    tbl[["candidates"]] <- length(candidates_idx)
    tbl[["total"]]      <- length(p_vals)
    
    # Add footnote explaining C*(α)
    tbl$addFootnote(gettextf("C*(α) is the C* value corresponding to the selected α = %s", alpha), 
                    colNames = "cstar")

    jaspResults[["summaryTable"]] <- tbl
  }

  # Candidates table
  if (is.null(jaspResults[["candidatesTable"]])) {
    ctbl <- createJaspTable(gettext("Candidate Type I Errors"))
    ctbl$dependOn(c("p", "n", "q", "study_nums", "alpha", "up", "lowerBound", "upperBound", "grid_size"))

    ctbl$addColumnInfo(name = "row",   title = gettext("Row"),       type = "integer")
    ctbl$addColumnInfo(name = "pval",  title = gettext("p-value"),   type = "number")
    ctbl$addColumnInfo(name = "nval",  title = gettext("n"),         type = "integer")
    ctbl$addColumnInfo(name = "qval",  title = gettext("q"),         type = "integer")
    ctbl$addColumnInfo(name = "ejab",  title = gettext("eJAB01"),    type = "number")

    if (length(candidates_idx) > 0) {
      ctbl[["row"]]  <- candidates_idx
      ctbl[["pval"]] <- p_vals[candidates_idx]
      ctbl[["nval"]] <- n_vals[candidates_idx]
      ctbl[["qval"]] <- q_vals[candidates_idx]
      ctbl[["ejab"]] <- ejab_vals[candidates_idx]
    } else {
      ctbl$addFootnote(gettext("No candidate Type I errors detected."))
    }

    jaspResults[["candidatesTable"]] <- ctbl
  }

  allDeps <- c("p", "n", "q", "study_nums", "up", "alpha",
               "lowerBound", "upperBound", "grid_size",
               "showCalibrationPlot", "showDataSummaryPlot")

  # --- Calibration plots (3 separate JASP plots instead of par(mfrow)) ---
  if (isTRUE(options$showCalibrationPlot)) {

    # Plot 1: Calibration curve - observed proportion vs alpha
    if (is.null(jaspResults[["calibrationCurve"]])) {
      calDf <- data.frame(alpha = fit_alpha$alpha_grid,
                          proportion = fit_alpha$proportions)
      refDf <- data.frame(alpha = c(0, up), proportion = c(0, 1))

      p1 <- ggplot2::ggplot(calDf, ggplot2::aes(x = alpha, y = proportion)) +
        ggplot2::geom_line(linewidth = 1) +
        ggplot2::geom_line(data = refDf, linetype = "dashed", color = "red", linewidth = 1) +
        ggplot2::scale_x_continuous(limits = c(0, up)) +
        ggplot2::scale_y_continuous(limits = c(0, max(fit_alpha$proportions, 1))) +
        ggplot2::labs(x = expression(alpha), y = "Observed Proportion",
                      title = "Calibration using adaptive C*(alpha)") +
        jaspGraphs::geom_rangeframe() +
        jaspGraphs::themeJaspRaw()

      calCurve <- createJaspPlot(plot = p1,
                                  title = gettext("Calibration Curve"),
                                  width = 480, height = 400)
      calCurve$dependOn(allDeps)
      jaspResults[["calibrationCurve"]] <- calCurve
    }

    # Plot 2: C*(alpha) vs alpha
    if (is.null(jaspResults[["cstarAlphaPlot"]])) {
      csDf <- data.frame(alpha = fit_alpha$alpha_grid,
                         Cstar = fit_alpha$Cstar_alpha)

      p2 <- ggplot2::ggplot(csDf, ggplot2::aes(x = alpha, y = Cstar)) +
        ggplot2::geom_line(linewidth = 1) +
        ggplot2::geom_hline(yintercept = 1, linetype = "dotted", color = "grey50") +
        ggplot2::labs(x = expression(alpha),
                      y = expression(C^"*" * (alpha)),
                      title = "C*(alpha) vs alpha") +
        jaspGraphs::geom_rangeframe() +
        jaspGraphs::themeJaspRaw()

      csPlot <- createJaspPlot(plot = p2,
                                title = gettext("C*(alpha) vs alpha"),
                                width = 480, height = 400)
      csPlot$dependOn(allDeps)
      jaspResults[["cstarAlphaPlot"]] <- csPlot
    }

    # Plot 3: Diagnostic QQ-plot
    if (is.null(jaspResults[["qqPlot"]])) {
      if (length(candidates_idx) > 0) {
        U <- ejabT1E::diagnostic_U(p_vals[candidates_idx], n_vals[candidates_idx],
                                    q_vals[candidates_idx], alpha, Cstar_at_alpha)
        n_u <- length(U)
        theoretical <- stats::ppoints(n_u)
        observed <- sort(U)
        qqDf <- data.frame(theoretical = theoretical, observed = observed)

        p3 <- ggplot2::ggplot(qqDf, ggplot2::aes(x = theoretical, y = observed)) +
          ggplot2::geom_point(size = 1.5) +
          ggplot2::geom_abline(intercept = 0, slope = 1, color = "red", linewidth = 1) +
          ggplot2::labs(x = "Theoretical Unif(0,1) Quantiles",
                        y = "Observed U_i Quantiles",
                        title = paste0("Diagnostic QQ-Plot (alpha = ", alpha,
                                       ", C* = ", round(Cstar_at_alpha, 4), ")")) +
          jaspGraphs::geom_rangeframe() +
          jaspGraphs::themeJaspRaw()

        # Add simultaneous confidence band if enough points
        if (n_u >= 2) {
          i_seq <- seq_len(n_u)
          lower <- stats::qbeta(0.025, i_seq, n_u + 1 - i_seq)
          upper <- stats::qbeta(0.975, i_seq, n_u + 1 - i_seq)
          bandDf <- data.frame(theoretical = theoretical,
                               lower = lower, upper = upper)
          p3 <- p3 +
            ggplot2::geom_line(data = bandDf,
                               ggplot2::aes(x = theoretical, y = lower),
                               linetype = "dashed", color = "grey50") +
            ggplot2::geom_line(data = bandDf,
                               ggplot2::aes(x = theoretical, y = upper),
                               linetype = "dashed", color = "grey50")
        }

        qqPlot <- createJaspPlot(plot = p3,
                                  title = gettext("Diagnostic QQ-Plot"),
                                  width = 480, height = 400)
      } else {
        qqPlot <- createJaspPlot(title = gettext("Diagnostic QQ-Plot"),
                                  width = 480, height = 400)
        qqPlot$setError(gettext("No candidate Type I errors detected; cannot produce QQ-plot."))
      }
      qqPlot$dependOn(allDeps)
      jaspResults[["qqPlot"]] <- qqPlot
    }
  }

  # --- Data summary plot (ggplot2 only, no cowplot) ---
  if (isTRUE(options$showDataSummaryPlot) && is.null(jaspResults[["dataSummaryPlot"]])) {
    if (length(p_vals) > 0) {
      logJAB <- log(ejab_vals)
      is_candidate <- (p_vals < alpha) & (ejab_vals > Cstar_at_alpha)

      plotDf <- data.frame(pValue = p_vals, logJAB = logJAB,
                           candidate = is_candidate)

      bands <- data.frame(
        ymin = c(-15, log(1/3), log(3)),
        ymax = c(log(1/3), log(3), 9),
        fill = c("green", "grey80", "red")
      )

      p4 <- ggplot2::ggplot(plotDf, ggplot2::aes(x = pValue, y = logJAB)) +
        ggplot2::geom_rect(data = bands,
                           ggplot2::aes(xmin = 0, xmax = alpha, ymin = ymin, ymax = ymax, fill = fill),
                           alpha = 0.15, inherit.aes = FALSE) +
        ggplot2::scale_fill_identity() +
        ggplot2::geom_point(size = 1.5, color = "steelblue") +
        ggplot2::geom_vline(xintercept = alpha, linetype = "dashed") +
        ggplot2::geom_hline(yintercept = log(1/3), linetype = "dashed") +
        ggplot2::geom_hline(yintercept = log(3), linetype = "dashed") +
        ggplot2::coord_cartesian(xlim = c(0, alpha), ylim = c(-3, 3)) +
        ggplot2::scale_x_continuous(name = "p-value") +
        ggplot2::scale_y_continuous(name = "ln(eJAB01)", breaks = seq(-3, 3, by = 1)) +
        ggplot2::labs(title = paste0("ln(eJAB01) vs p-value  (alpha = ", alpha,
                                     ", C*(alpha) = ", round(Cstar_at_alpha, 4), ")")) +
        jaspGraphs::geom_rangeframe() +
        jaspGraphs::themeJaspRaw()

      # Highlight candidate T1Es
      if (any(is_candidate)) {
        candDf <- plotDf[is_candidate, ]
        p4 <- p4 +
          ggplot2::geom_point(data = candDf,
                              ggplot2::aes(x = pValue, y = logJAB),
                              shape = 1, size = 3, color = "red", stroke = 1.2,
                              inherit.aes = FALSE)
      }

      dataPlot <- createJaspPlot(plot = p4,
                                  title = gettext("Data Summary: ln(eJAB01) vs pValue"),
                                  width = 600, height = 400)
    } else {
      dataPlot <- createJaspPlot(title = gettext("Data Summary: ln(eJAB01) vs pValue"),
                                  width = 600, height = 400)
      dataPlot$setError(gettext("No data available for plotting."))
    }
    dataPlot$dependOn(allDeps)
    jaspResults[["dataSummaryPlot"]] <- dataPlot
  }
}
