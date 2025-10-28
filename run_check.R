invisible(lapply(
  c(
    "shiny",
    "shinydashboard",
    "shinyWidgets",
    "dplyr",
    "sf",
    "leaflet",
    "tidyr",
    "DT",
    "ggplot2",
    "htmlwidgets",
    "rlang",
    "data.table"
  ),
  function(pkg) {
    if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
      message("Warning: package '", pkg, "' is not installed")
    }
  }
))

tryCatch(
  {
    source("app.R", local = FALSE)
    cat("Sourced app without error\n")
  },
  error = function(e) {
    cat("Error sourcing app:", conditionMessage(e), "\n")
    if (interactive()) traceback()
    quit(status = 1)
  }
)
