# ====================================================================
# EXAMPLE USAGE - DISRUPTION MAPPING APP
# This script demonstrates how to use the app with your data
# ====================================================================

# ====================================================================
# STEP 1: INSTALL PACKAGES (Run once)
# ====================================================================

# Uncomment the line below to install packages
# source("install_packages.R")

# ====================================================================
# STEP 2: CHECK YOUR DATA (Optional but recommended)
# ====================================================================

# Load the helper functions
source("prepare_data_helper.R")

# Check what data is available
summarize_available_data()

# Validate a specific disruption CSV file
# Example for Sierra Leone:
validate_disruption_csv("/Users/claireboulange/Desktop/FASTR/Request/Sierra_Leone/M3_disruptions_analysis_admin_area_2.csv")

# Check if admin area names match between GeoJSON and CSV
check_admin_name_matches(
  csv_file = "/Users/claireboulange/Desktop/FASTR/Request/Sierra_Leone/M3_disruptions_analysis_admin_area_2.csv",
  geojson_file = "sierraleone_backbone.geojson"
)

# ====================================================================
# STEP 3: LAUNCH THE APP
# ====================================================================

# Method 1: Use the launcher script
source("launch_app.R")

# Method 2: Direct launch
# shiny::runApp()

# ====================================================================
# STEP 4: USE THE APP
# ====================================================================

# Once the app is running:
#
# 1. Select your country from the dropdown (e.g., "Sierraleone")
#
# 2. Upload your disruption CSV file using the file picker
#    - The file should be an M3_disruptions_analysis_admin_area_2.csv
#    - Or any CSV with the required columns
#
# 3. Select the year you want to analyze
#
# 4. Choose view mode:
#    - "All Indicators" - See overall disruption across all services
#    - "By Indicator" - Focus on a specific health indicator
#
# 5. Explore the tabs:
#    - "Disruption Map" - Interactive map with color-coded areas
#    - "Summary Statistics" - Charts and summary tables
#    - "Data Table" - Detailed data view with filters
#    - "About" - Information about the tool

# ====================================================================
# PREPARING DATA FROM PIPELINE OUTPUTS
# ====================================================================

# If you have run the main pipeline modules and want to prepare
# disruption data for the app:

prepare_disruption_data_for_app <- function(modules_path = "/Users/claireboulange/Desktop/modules") {
  library(dplyr)

  # Look for M3_disruptions file in the modules folder
  disruption_files <- list.files(
    path = modules_path,
    pattern = "M3_disruptions_analysis_admin_area_2.csv",
    full.names = TRUE
  )

  if (length(disruption_files) > 0) {
    cat("Found disruption analysis file:\n")
    cat(disruption_files[1], "\n\n")

    # Validate it
    if (validate_disruption_csv(disruption_files[1])) {
      cat("\n✓ File is ready to use with the app!\n")
      cat("Path to use:", disruption_files[1], "\n")
      return(disruption_files[1])
    }
  } else {
    cat("No M3_disruptions file found in:", modules_path, "\n")
    cat("Please run Module 3 of the pipeline first.\n")
    return(NULL)
  }
}

# Run this to find your disruption data
# disruption_file <- prepare_disruption_data_for_app()

# ====================================================================
# WORKING WITH MULTIPLE COUNTRIES
# ====================================================================

# Example: Process disruption data for multiple countries

process_multiple_countries <- function() {
  # Define your country-specific data paths
  country_data <- list(
    sierraleone = list(
      geojson = "sierraleone_backbone.geojson",
      csv = "/Users/claireboulange/Desktop/FASTR/Request/Sierra_Leone/M3_disruptions_analysis_admin_area_2.csv"
    ),
    nigeria = list(
      geojson = "nigeria_backbone.geojson",
      csv = "/Users/claireboulange/Desktop/FASTR/Request/Nigeria/M3_disruptions_analysis_admin_area_2.csv"
    )
    # Add more countries as needed
  )

  # Check each country's data
  for (country in names(country_data)) {
    cat("\n====================================================================\n")
    cat("Checking", toupper(country), "\n")
    cat("====================================================================\n\n")

    # Check if files exist
    if (file.exists(country_data[[country]]$geojson)) {
      cat("✓ GeoJSON found\n")
    } else {
      cat("✗ GeoJSON not found:", country_data[[country]]$geojson, "\n")
      next
    }

    if (file.exists(country_data[[country]]$csv)) {
      cat("✓ CSV found\n\n")

      # Validate and check matches
      validate_disruption_csv(country_data[[country]]$csv)
      cat("\n")
      check_admin_name_matches(
        country_data[[country]]$csv,
        country_data[[country]]$geojson
      )
    } else {
      cat("✗ CSV not found:", country_data[[country]]$csv, "\n")
    }
  }
}

# Uncomment to run the multi-country check
# process_multiple_countries()

# ====================================================================
# EXPORTING DATA FROM THE APP
# ====================================================================

# While using the app, you can:
#
# 1. Go to the "Data Table" tab
# 2. Use the filters to select specific data
# 3. Click the export button to download as CSV or Excel
#
# The exported data will include calculated disruption categories
# and percent changes for further analysis.

# ====================================================================
# TIPS AND TRICKS
# ====================================================================

# Tip 1: Year Selection
# - Start with the most recent year to see current disruptions
# - Compare multiple years by switching the year filter

# Tip 2: Indicator Focus
# - Use "All Indicators" to get a general overview
# - Switch to "By Indicator" to investigate specific services
# - Look at high-priority indicators like delivery, penta3, anc4

# Tip 3: Identifying Patterns
# - Disruptions often cluster geographically
# - Check the "Top 10 Most Disrupted Areas" chart for priority areas
# - Compare disruption patterns across different indicators

# Tip 4: Data Quality
# - Gray areas (Insufficient data) may indicate:
#   * Missing admin area in the disruption CSV
#   * Name mismatch between CSV and GeoJSON
#   * Zero expected values
# - Use check_admin_name_matches() to debug

# Tip 5: Performance
# - For large datasets, filter by year and indicator
# - Close other R sessions if the app runs slowly
# - Consider using RStudio's native Shiny viewer

cat("\n====================================================================\n")
cat("Ready to start!\n")
cat("Run: source('launch_app.R')\n")
cat("====================================================================\n\n")
