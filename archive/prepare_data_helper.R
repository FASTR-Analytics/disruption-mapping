# ====================================================================
# DATA PREPARATION HELPER
# Functions to help prepare and validate disruption data
# ====================================================================

library(dplyr)

# Function to check if a CSV file is valid for the app
validate_disruption_csv <- function(file_path) {
  cat("Validating file:", basename(file_path), "\n")

  # Try to read the file
  tryCatch({
    data <- read.csv(file_path, stringsAsFactors = FALSE)

    # Check required columns
    required_cols <- c("admin_area_2", "indicator_common_id", "year",
                      "count_sum", "count_expect_sum")

    missing_cols <- setdiff(required_cols, names(data))

    if (length(missing_cols) > 0) {
      cat("  ERROR: Missing required columns:\n")
      cat(paste("    -", missing_cols, collapse = "\n"), "\n")
      return(FALSE)
    }

    cat("  ✓ All required columns present\n")
    cat("  ✓ Rows:", nrow(data), "\n")
    cat("  ✓ Years:", paste(sort(unique(data$year)), collapse = ", "), "\n")
    cat("  ✓ Admin areas:", length(unique(data$admin_area_2)), "\n")
    cat("  ✓ Indicators:", length(unique(data$indicator_common_id)), "\n")

    # Check for common issues
    if (any(is.na(data$admin_area_2))) {
      cat("  WARNING: Some admin_area_2 values are NA\n")
    }

    if (any(data$count_expect_sum == 0, na.rm = TRUE)) {
      cat("  WARNING: Some expected counts are zero\n")
    }

    return(TRUE)

  }, error = function(e) {
    cat("  ERROR:", e$message, "\n")
    return(FALSE)
  })
}

# Function to find disruption files in a directory
find_disruption_files <- function(directory = "/Users/claireboulange/Desktop/modules") {
  cat("Searching for disruption files in:", directory, "\n\n")

  # Look for files that might be disruption analyses
  all_files <- list.files(directory, pattern = "*.csv", full.names = TRUE, recursive = TRUE)

  # Filter for likely disruption files
  disruption_files <- all_files[grepl("disruption|M3_", basename(all_files), ignore.case = TRUE)]

  if (length(disruption_files) == 0) {
    cat("No disruption files found.\n")
    cat("Looking for any CSV files with required columns...\n\n")

    # Check all CSVs for required columns
    for (file in all_files) {
      if (file.size(file) > 0) {
        tryCatch({
          data <- read.csv(file, nrows = 1)
          required_cols <- c("admin_area_2", "indicator_common_id", "year",
                           "count_sum", "count_expect_sum")
          if (all(required_cols %in% names(data))) {
            disruption_files <- c(disruption_files, file)
          }
        }, error = function(e) {})
      }
    }
  }

  if (length(disruption_files) > 0) {
    cat("Found", length(disruption_files), "potential disruption file(s):\n\n")
    for (file in disruption_files) {
      cat("File:", basename(file), "\n")
      cat("Path:", file, "\n")
      validate_disruption_csv(file)
      cat("\n")
    }
  } else {
    cat("No suitable disruption files found.\n")
  }

  return(disruption_files)
}

# Function to compare admin area names between GeoJSON and CSV
check_admin_name_matches <- function(csv_file, geojson_file) {
  cat("Checking admin area name matches...\n\n")

  # Read CSV
  csv_data <- read.csv(csv_file, stringsAsFactors = FALSE)
  csv_areas <- unique(csv_data$admin_area_2)

  # Read GeoJSON
  library(sf)
  geo_data <- st_read(geojson_file, quiet = TRUE)
  geo_areas <- unique(geo_data$name[geo_data$level == 2])

  cat("CSV has", length(csv_areas), "unique admin areas\n")
  cat("GeoJSON has", length(geo_areas), "level 2 areas\n\n")

  # Find mismatches
  in_csv_not_geo <- setdiff(csv_areas, geo_areas)
  in_geo_not_csv <- setdiff(geo_areas, csv_areas)

  if (length(in_csv_not_geo) > 0) {
    cat("Areas in CSV but not in GeoJSON:\n")
    cat(paste("  -", in_csv_not_geo, collapse = "\n"), "\n\n")
  }

  if (length(in_geo_not_csv) > 0) {
    cat("Areas in GeoJSON but not in CSV:\n")
    cat(paste("  -", in_geo_not_csv, collapse = "\n"), "\n\n")
  }

  if (length(in_csv_not_geo) == 0 && length(in_geo_not_csv) == 0) {
    cat("✓ All admin area names match perfectly!\n")
  }

  return(list(
    csv_only = in_csv_not_geo,
    geo_only = in_geo_not_csv,
    matched = intersect(csv_areas, geo_areas)
  ))
}

# Function to create a summary of available data
summarize_available_data <- function() {
  cat("====================================================================\n")
  cat("DISRUPTION MAPPING DATA SUMMARY\n")
  cat("====================================================================\n\n")

  # Check GeoJSON files
  geojson_files <- list.files(pattern = "*_backbone.geojson")
  cat("Available Countries (GeoJSON):\n")
  if (length(geojson_files) > 0) {
    countries <- gsub("_backbone.geojson", "", geojson_files)
    cat(paste("  ", 1:length(countries), ".", tools::toTitleCase(countries), collapse = "\n"), "\n\n")
  } else {
    cat("  None found\n\n")
  }

  # Check for disruption files
  cat("Searching for disruption CSV files...\n\n")
  disruption_files <- find_disruption_files()

  cat("\n====================================================================\n\n")
}

# Example usage
cat("====================================================================\n")
cat("DISRUPTION MAPPING - DATA PREPARATION HELPER\n")
cat("====================================================================\n\n")
cat("Available functions:\n")
cat("  - validate_disruption_csv(file_path)\n")
cat("  - find_disruption_files(directory)\n")
cat("  - check_admin_name_matches(csv_file, geojson_file)\n")
cat("  - summarize_available_data()\n\n")
cat("Example:\n")
cat("  summarize_available_data()\n")
cat("  validate_disruption_csv('path/to/file.csv')\n\n")
cat("====================================================================\n\n")
