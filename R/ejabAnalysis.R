ejabAnalysis <- function(jaspResults, dataset, options) {

  # Check if required variables are assigned
  if (options$p == "" || options$n == "" || options$q == "")
    return()

  # Read data
  p_vals <- dataset[[options$p]]
  n_vals <- dataset[[options$n]]
  q_vals <- dataset[[options$q]]

  # Hardcoded defaults for now (Step 6 will make these configurable)
  alpha <- 0.05
  up    <- 0.05
  grid_range <- c(1/3, 3)
  grid_n <- 200

  # Compute eJAB values
  ejab_vals <- ejabT1E::ejab01(p_vals, n_vals, q_vals)

  # Estimate C*
  fit <- ejabT1E::estimate_Cstar(p_vals, ejab_vals, up = up,
                                  grid_range = grid_range, grid_n = grid_n)

  # Detect candidates
  candidates_idx <- ejabT1E::detect_type1(p_vals, ejab_vals, alpha, fit$Cstar)

  # Summary table
  if (is.null(jaspResults[["summaryTable"]])) {
    tbl <- createJaspTable(gettext("eJAB Summary"))
    tbl$dependOn(c("p", "n", "q"))

    tbl$addColumnInfo(name = "cstar",      title = gettext("C*"),          type = "number")
    tbl$addColumnInfo(name = "objective",   title = gettext("Objective"),   type = "number")
    tbl$addColumnInfo(name = "candidates",  title = gettext("Candidates"),  type = "integer")
    tbl$addColumnInfo(name = "total",       title = gettext("Total"),       type = "integer")

    tbl[["cstar"]]     <- fit$Cstar
    tbl[["objective"]]  <- fit$objective
    tbl[["candidates"]] <- length(candidates_idx)
    tbl[["total"]]      <- length(p_vals)

    jaspResults[["summaryTable"]] <- tbl
  }

  # Candidates table
  if (is.null(jaspResults[["candidatesTable"]])) {
    ctbl <- createJaspTable(gettext("Candidate Type I Errors"))
    ctbl$dependOn(c("p", "n", "q"))

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

  # Diagnostic QQ-plot
  if (is.null(jaspResults[["qqPlot"]])) {
    if (length(candidates_idx) > 0) {
      U <- ejabT1E::diagnostic_U(p_vals[candidates_idx], n_vals[candidates_idx],
                                  q_vals[candidates_idx], alpha, fit$Cstar)
      plotFun <- function() {
        ejabT1E::diagnostic_qqplot(U, alpha = alpha, Cstar = fit$Cstar)
      }
      qqPlot <- createJaspPlot(plot = plotFun,
                                title = gettext("Diagnostic QQ-Plot"),
                                width = 480, height = 400)
    } else {
      qqPlot <- createJaspPlot(title = gettext("Diagnostic QQ-Plot"),
                                width = 480, height = 400)
      qqPlot$setError(gettext("No candidate Type I errors detected; cannot produce QQ-plot."))
    }
    qqPlot$dependOn(c("p", "n", "q"))
    jaspResults[["qqPlot"]] <- qqPlot
  }
}
