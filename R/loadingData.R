processTable <- function(jaspResults, dataset, options) {

  # Auxiliary function.
  # Returns TRUE if and only if an option has been assigned in the GUI
  .isAssigned <- function(option) {
    not_assigned <- as.character(option) == ""
    return(!not_assigned)
  }

  # Only if everything has been assigned ...
  if(.isAssigned(options$p) && .isAssigned(options$n) && .isAssigned(options$q)) {
    # ... print the inputs as a table
    stats <- createJaspTable(gettext("Some descriptives"))
    stats$dependOn(c("p", "n", "q")) # Declare dependencies to make the object disappear / reappear when needed

    stats$addColumnInfo(name = gettext("p"))
    stats$addColumnInfo(name = gettext("q"))
    stats$addColumnInfo(name = gettext("n"))

    stats[["p"]] <- dataset[[options$p]]
    stats[["q"]] <- dataset[[options$q]]
    stats[["n"]] <- dataset[[options$n]]

    jaspResults[["stats"]] <- stats
  } else {
    expl <- createJaspHtml(text = "Select times and positions")
    expl$dependOn(c("p", "q", "n")) # Declare dependencies to make the object disappear / reappear when needed

    jaspResults[["Explanation"]] <- expl
  }

}
