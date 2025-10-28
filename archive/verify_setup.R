# ====================================================================
# SETUP VERIFICATION SCRIPT
# Verify that everything is ready for the Disruption Mapping App
# ====================================================================

cat("\n====================================================================\n")
cat("DISRUPTION MAPPING APP - SETUP VERIFICATION\n")
cat("====================================================================\n\n")

# Check 1: Required files
cat("1. Checking required files...\n")
required_files <- c("app.R", "launch_app.R", "install_packages.R",
                   "prepare_data_helper.R", "example_usage.R")

all_files_present <- TRUE
for (file in required_files) {
  if (file.exists(file)) {
    cat("   ✓", file, "\n")
  } else {
    cat("   ✗", file, "MISSING\n")
    all_files_present <- FALSE
  }
}

# Check 2: GeoJSON files
cat("\n2. Checking GeoJSON boundary files...\n")
geojson_files <- list.files(pattern = "*_backbone.geojson")
if (length(geojson_files) > 0) {
  cat("   ✓ Found", length(geojson_files), "country boundary files:\n")
  for (file in geojson_files) {
    country <- gsub("_backbone.geojson", "", file)
    cat("      -", tools::toTitleCase(country), "\n")
  }
} else {
  cat("   ✗ No GeoJSON files found\n")
}

# Check 3: Nigeria test data
cat("\n3. Checking Nigeria test data...\n")
admin2_file <- "/Users/claireboulange/Desktop/modules/Oct_NGA/M3_disruptions_analysis_admin_area_2.csv"
admin3_file <- "/Users/claireboulange/Desktop/modules/Oct_NGA/M3_disruptions_analysis_admin_area_3.csv"

if (file.exists(admin2_file)) {
  cat("   ✓ Admin Level 2 data found\n")
  data2 <- read.csv(admin2_file, nrows = 1)
  cat("      Columns:", paste(names(data2), collapse = ", "), "\n")
} else {
  cat("   ✗ Admin Level 2 data not found at expected location\n")
}

if (file.exists(admin3_file)) {
  cat("   ✓ Admin Level 3 data found\n")
  data3 <- read.csv(admin3_file, nrows = 1)
  cat("      Columns:", paste(names(data3), collapse = ", "), "\n")
} else {
  cat("   ✗ Admin Level 3 data not found at expected location\n")
}

# Check 4: R packages
cat("\n4. Checking R packages...\n")
required_packages <- c("shiny", "shinydashboard", "shinyWidgets",
                      "dplyr", "sf", "leaflet", "tidyr", "DT", "ggplot2")

packages_status <- sapply(required_packages, function(pkg) {
  requireNamespace(pkg, quietly = TRUE)
})

if (all(packages_status)) {
  cat("   ✓ All required packages are installed\n")
  for (pkg in required_packages) {
    cat("      -", pkg, "\n")
  }
} else {
  cat("   ✗ Some packages are missing:\n")
  for (pkg in required_packages) {
    if (packages_status[pkg]) {
      cat("      ✓", pkg, "\n")
    } else {
      cat("      ✗", pkg, "MISSING\n")
    }
  }
  cat("\n   Run install_packages.R to install missing packages:\n")
  cat("   source('install_packages.R')\n")
}

# Check 5: App syntax
cat("\n5. Checking app.R syntax...\n")
tryCatch({
  parse("app.R")
  cat("   ✓ app.R syntax is valid\n")
}, error = function(e) {
  cat("   ✗ Syntax error in app.R:\n")
  cat("     ", e$message, "\n")
})

# Summary
cat("\n====================================================================\n")
cat("VERIFICATION SUMMARY\n")
cat("====================================================================\n\n")

if (all_files_present && length(geojson_files) > 0 && all(packages_status)) {
  cat("✓ All checks passed! You're ready to launch the app.\n\n")
  cat("To launch the app, run:\n")
  cat("  source('launch_app.R')\n\n")
  cat("To test with Nigeria data:\n")
  cat("  1. Select 'Nigeria' from country dropdown\n")
  cat("  2. Choose admin level (2 or 3)\n")
  cat("  3. Upload the corresponding CSV file\n")
  cat("  4. See NIGERIA_TEST_GUIDE.md for detailed instructions\n")
} else {
  cat("✗ Some issues detected. Please address them:\n\n")

  if (!all_files_present) {
    cat("  - Some required files are missing\n")
  }

  if (length(geojson_files) == 0) {
    cat("  - No GeoJSON boundary files found\n")
  }

  if (!all(packages_status)) {
    cat("  - Some R packages need to be installed\n")
    cat("    Run: source('install_packages.R')\n")
  }
}

cat("\n====================================================================\n\n")

# Return status invisibly
invisible(list(
  files = all_files_present,
  geojson = length(geojson_files) > 0,
  packages = all(packages_status),
  all_ok = all_files_present && length(geojson_files) > 0 && all(packages_status)
))
