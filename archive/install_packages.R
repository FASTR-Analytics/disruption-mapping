# ====================================================================
# PACKAGE INSTALLATION SCRIPT
# Install all required packages for the Disruption Mapping Shiny App
# ====================================================================

cat("Installing required packages for Disruption Mapping App...\n\n")

# List of required packages
required_packages <- c(
  "shiny",           # Core Shiny framework
  "shinydashboard",  # Dashboard layout
  "shinyWidgets",    # Enhanced UI widgets
  "dplyr",           # Data manipulation
  "sf",              # Spatial data handling
  "leaflet",         # Interactive maps
  "tidyr",           # Data tidying
  "DT",              # Interactive tables
  "ggplot2"          # Plotting
)

# Function to check and install packages
install_if_missing <- function(packages) {
  for (pkg in packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      cat(paste("Installing", pkg, "...\n"))
      install.packages(pkg, dependencies = TRUE)
    } else {
      cat(paste(pkg, "is already installed.\n"))
    }
  }
}

# Install packages
install_if_missing(required_packages)

cat("\n====================================================================\n")
cat("Installation complete!\n")
cat("====================================================================\n\n")

# Verify installation
cat("Verifying package installation...\n\n")
all_installed <- TRUE

for (pkg in required_packages) {
  can_load <- requireNamespace(pkg, quietly = TRUE)
  status <- if (can_load) "OK" else "FAILED"
  cat(sprintf("  %-20s: %s\n", pkg, status))
  if (!can_load) all_installed <- FALSE
}

cat("\n")

if (all_installed) {
  cat("All packages installed successfully!\n")
  cat("You can now run the app with: shiny::runApp()\n")
} else {
  cat("Some packages failed to install. Please install them manually.\n")
}
