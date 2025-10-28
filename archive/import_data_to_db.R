# ====================================================================
# DATA IMPORT TO POSTGRESQL DATABASE
# Import disruption data from CSV files into PostgreSQL
# ====================================================================

library(DBI)
library(RPostgres)
library(dplyr)
library(readr)

# ====================================================================
# DATABASE CONNECTION CONFIGURATION
# ====================================================================

# Option 1: Set connection parameters directly
DB_CONFIG <- list(
  host = "localhost",
  port = 5432,
  dbname = "disruption_mapping",
  user = "disruption_app",  # or your postgres username
  password = "your_password_here"  # Change this!
)

# Option 2: Use environment variables (more secure)
# Create a .env file with:
# DB_HOST=localhost
# DB_PORT=5432
# DB_NAME=disruption_mapping
# DB_USER=disruption_app
# DB_PASSWORD=your_password

# Load environment variables if .env file exists
if (file.exists(".env")) {
  readRenviron(".env")
  DB_CONFIG <- list(
    host = Sys.getenv("DB_HOST", "localhost"),
    port = as.integer(Sys.getenv("DB_PORT", "5432")),
    dbname = Sys.getenv("DB_NAME", "disruption_mapping"),
    user = Sys.getenv("DB_USER", "postgres"),
    password = Sys.getenv("DB_PASSWORD", "")
  )
}

# ====================================================================
# HELPER FUNCTIONS
# ====================================================================

# Connect to database
connect_db <- function() {
  tryCatch({
    con <- dbConnect(
      Postgres(),
      host = DB_CONFIG$host,
      port = DB_CONFIG$port,
      dbname = DB_CONFIG$dbname,
      user = DB_CONFIG$user,
      password = DB_CONFIG$password
    )
    cat("✓ Connected to PostgreSQL database\n")
    return(con)
  }, error = function(e) {
    cat("✗ Database connection failed:\n")
    cat("  ", e$message, "\n")
    cat("\nPlease check:\n")
    cat("  1. PostgreSQL is running\n")
    cat("  2. Database 'disruption_mapping' exists\n")
    cat("  3. Credentials are correct\n")
    cat("  4. User has necessary permissions\n")
    return(NULL)
  })
}

# Get or create country ID
get_country_id <- function(con, country_code, country_name, geojson_file = NULL) {
  query <- "SELECT upsert_country($1, $2, $3)"
  result <- dbGetQuery(con, query, params = list(country_code, country_name, geojson_file))
  return(result[[1]])
}

# Get or create admin area ID
get_admin_area_id <- function(con, country_id, admin_level, area_name, parent_area_id = NULL, area_code = NULL) {
  # Check if exists
  query <- "SELECT admin_area_id FROM admin_areas
            WHERE country_id = $1 AND admin_level = $2 AND area_name = $3"
  result <- dbGetQuery(con, query, params = list(country_id, admin_level, area_name))

  if (nrow(result) > 0) {
    return(result$admin_area_id[1])
  }

  # Insert new
  query <- "INSERT INTO admin_areas (country_id, admin_level, area_name, parent_area_id, area_code)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING admin_area_id"
  result <- dbGetQuery(con, query,
                      params = list(country_id, admin_level, area_name, parent_area_id, area_code))
  return(result$admin_area_id[1])
}

# Get or create indicator ID
get_indicator_id <- function(con, indicator_code, indicator_name = NULL) {
  # Check if exists
  query <- "SELECT indicator_id FROM indicators WHERE indicator_code = $1"
  result <- dbGetQuery(con, query, params = list(indicator_code))

  if (nrow(result) > 0) {
    return(result$indicator_id[1])
  }

  # Insert new
  query <- "INSERT INTO indicators (indicator_code, indicator_name)
            VALUES ($1, $2)
            RETURNING indicator_id"
  result <- dbGetQuery(con, query,
                      params = list(indicator_code, indicator_name %||% indicator_code))
  return(result$indicator_id[1])
}

# ====================================================================
# MAIN IMPORT FUNCTION
# ====================================================================

import_disruption_csv <- function(con, csv_file, country_code, country_name,
                                 geojson_file = NULL, batch_size = 1000) {

  cat("\n====================================================================\n")
  cat("IMPORTING:", basename(csv_file), "\n")
  cat("====================================================================\n\n")

  # Read CSV
  cat("Reading CSV file...\n")
  data <- read_csv(csv_file, show_col_types = FALSE)
  cat("✓ Loaded", nrow(data), "rows\n\n")

  # Get country ID
  country_id <- get_country_id(con, country_code, country_name, geojson_file)
  cat("✓ Country ID:", country_id, "\n")

  # Detect admin level
  has_admin_3 <- "admin_area_3" %in% names(data)
  admin_level <- if(has_admin_3) 3 else 2
  cat("✓ Detected admin level:", admin_level, "\n\n")

  # Extract year from period_id if needed
  if (!"year" %in% names(data) && "period_id" %in% names(data)) {
    data$year <- as.integer(substr(data$period_id, 1, 4))
  }

  # Calculate month and quarter
  if ("period_id" %in% names(data)) {
    data$month <- as.integer(substr(data$period_id, 5, 6))
    data$quarter <- ceiling(data$month / 3)
  } else {
    data$month <- NA
    data$quarter <- NA
  }

  # Calculate percent change
  data$percent_change <- ((data$count_sum - data$count_expect_sum) / data$count_expect_sum) * 100

  # Start transaction
  dbBegin(con)

  tryCatch({
    cat("Processing areas and indicators...\n")

    # Create lookup tables for admin areas
    admin_area_map <- list()

    # For Level 3 data, we need both level 2 and level 3
    if (admin_level == 3) {
      # Get unique admin_area_2 (parent areas)
      admin2_unique <- unique(data$admin_area_2)
      cat("  Processing", length(admin2_unique), "level 2 areas...\n")

      for (area2 in admin2_unique) {
        if (!is.na(area2) && area2 != "") {
          admin_area_map[[paste0("L2_", area2)]] <-
            get_admin_area_id(con, country_id, 2, area2)
        }
      }

      # Get unique admin_area_3 with their parents
      admin3_data <- data %>%
        distinct(admin_area_2, admin_area_3) %>%
        filter(!is.na(admin_area_3), admin_area_3 != "")

      cat("  Processing", nrow(admin3_data), "level 3 areas...\n")

      for (i in 1:nrow(admin3_data)) {
        area2 <- admin3_data$admin_area_2[i]
        area3 <- admin3_data$admin_area_3[i]
        parent_id <- admin_area_map[[paste0("L2_", area2)]]

        admin_area_map[[paste0("L3_", area3)]] <-
          get_admin_area_id(con, country_id, 3, area3, parent_id)
      }
    } else {
      # Level 2 data
      admin2_unique <- unique(data$admin_area_2)
      cat("  Processing", length(admin2_unique), "level 2 areas...\n")

      for (area2 in admin2_unique) {
        if (!is.na(area2) && area2 != "") {
          admin_area_map[[paste0("L2_", area2)]] <-
            get_admin_area_id(con, country_id, 2, area2)
        }
      }
    }

    # Create lookup for indicators
    cat("  Processing indicators...\n")
    indicator_map <- list()
    indicators_unique <- unique(data$indicator_common_id)

    for (ind in indicators_unique) {
      if (!is.na(ind) && ind != "") {
        indicator_map[[ind]] <- get_indicator_id(con, ind)
      }
    }

    cat("✓ Lookups created\n\n")

    # Prepare data for insert
    cat("Preparing data for insert...\n")

    insert_data <- data %>%
      mutate(
        country_id = country_id,
        admin_area_id = if(admin_level == 3) {
          sapply(admin_area_3, function(x) admin_area_map[[paste0("L3_", x)]])
        } else {
          sapply(admin_area_2, function(x) admin_area_map[[paste0("L2_", x)]])
        },
        indicator_id = sapply(indicator_common_id, function(x) indicator_map[[x]]),
        period_id = if("period_id" %in% names(data)) period_id else year * 100 + 1,
        count_actual = count_sum,
        count_expected = count_expect_sum,
        count_expected_threshold = if("count_expected_if_above_diff_threshold" %in% names(data)) {
          count_expected_if_above_diff_threshold
        } else {
          count_expect_sum
        }
      ) %>%
      filter(!is.na(admin_area_id), !is.na(indicator_id)) %>%
      select(country_id, admin_area_id, indicator_id, period_id, year,
             month, quarter, count_actual, count_expected, count_expected_threshold,
             percent_change)

    cat("✓ Prepared", nrow(insert_data), "records for insert\n\n")

    # Insert in batches
    cat("Inserting data in batches of", batch_size, "...\n")
    total_rows <- nrow(insert_data)
    batches <- ceiling(total_rows / batch_size)

    for (i in 1:batches) {
      start_idx <- (i - 1) * batch_size + 1
      end_idx <- min(i * batch_size, total_rows)
      batch_data <- insert_data[start_idx:end_idx, ]

      dbWriteTable(con, "disruption_data", batch_data, append = TRUE, row.names = FALSE)

      cat(sprintf("  Batch %d/%d: Inserted rows %d-%d\n", i, batches, start_idx, end_idx))
    }

    cat("\n✓ All data inserted\n\n")

    # Log upload
    cat("Logging upload history...\n")
    dbExecute(con, "
      INSERT INTO upload_history (country_id, admin_level, file_name, records_imported)
      VALUES ($1, $2, $3, $4)",
      params = list(country_id, admin_level, basename(csv_file), nrow(insert_data))
    )

    # Commit transaction
    dbCommit(con)
    cat("✓ Transaction committed\n")

    cat("\n====================================================================\n")
    cat("IMPORT COMPLETE\n")
    cat("====================================================================\n")
    cat("Country:", country_name, "\n")
    cat("Admin Level:", admin_level, "\n")
    cat("Records Imported:", nrow(insert_data), "\n")
    cat("====================================================================\n\n")

    return(TRUE)

  }, error = function(e) {
    cat("\n✗ Error during import:\n")
    cat("  ", e$message, "\n")
    dbRollback(con)
    cat("✗ Transaction rolled back\n")
    return(FALSE)
  })
}

# ====================================================================
# BATCH IMPORT FUNCTION
# ====================================================================

import_all_disruption_files <- function(files_config) {
  con <- connect_db()
  if (is.null(con)) return(FALSE)

  on.exit(dbDisconnect(con))

  results <- list()

  for (config in files_config) {
    cat("\n")
    success <- import_disruption_csv(
      con = con,
      csv_file = config$file,
      country_code = config$country_code,
      country_name = config$country_name,
      geojson_file = config$geojson_file
    )
    results[[config$country_name]] <- success

    # Refresh materialized view after each import
    if (success) {
      cat("Refreshing materialized view...\n")
      dbExecute(con, "SELECT refresh_disruption_summary()")
      cat("✓ View refreshed\n")
    }
  }

  # Summary
  cat("\n====================================================================\n")
  cat("IMPORT SUMMARY\n")
  cat("====================================================================\n")
  for (name in names(results)) {
    status <- if(results[[name]]) "✓ Success" else "✗ Failed"
    cat(sprintf("%-30s: %s\n", name, status))
  }
  cat("====================================================================\n\n")

  return(all(unlist(results)))
}

# ====================================================================
# EXAMPLE USAGE
# ====================================================================

# Example 1: Import single file
import_nigeria <- function() {
  con <- connect_db()
  if (is.null(con)) return(FALSE)
  on.exit(dbDisconnect(con))

  import_disruption_csv(
    con = con,
    csv_file = "/Users/claireboulange/Desktop/modules/Oct_NGA/M3_disruptions_analysis_admin_area_2.csv",
    country_code = "NGA",
    country_name = "Nigeria",
    geojson_file = "nigeria_backbone.geojson"
  )

  # Refresh view
  dbExecute(con, "SELECT refresh_disruption_summary()")
}

# Example 2: Import multiple files
import_all_countries <- function() {
  files_to_import <- list(
    list(
      file = "/Users/claireboulange/Desktop/modules/Oct_NGA/M3_disruptions_analysis_admin_area_2.csv",
      country_code = "NGA",
      country_name = "Nigeria",
      geojson_file = "nigeria_backbone.geojson"
    ),
    list(
      file = "/Users/claireboulange/Desktop/modules/Oct_NGA/M3_disruptions_analysis_admin_area_3.csv",
      country_code = "NGA",
      country_name = "Nigeria",
      geojson_file = "nigeria_backbone.geojson"
    ),
    list(
      file = "/Users/claireboulange/Desktop/FASTR/Request/Sierra_Leone/M3_disruptions_analysis_admin_area_2.csv",
      country_code = "SLE",
      country_name = "Sierra Leone",
      geojson_file = "sierraleone_backbone.geojson"
    )
    # Add more files as needed
  )

  import_all_disruption_files(files_to_import)
}

# ====================================================================
# UTILITY FUNCTIONS
# ====================================================================

# Query available data
query_available_data <- function() {
  con <- connect_db()
  if (is.null(con)) return(NULL)
  on.exit(dbDisconnect(con))

  cat("\n====================================================================\n")
  cat("AVAILABLE DATA IN DATABASE\n")
  cat("====================================================================\n\n")

  # Countries
  cat("Countries:\n")
  countries <- dbGetQuery(con, "SELECT * FROM countries ORDER BY country_name")
  print(countries)

  cat("\n\nData by country and year:\n")
  summary <- dbGetQuery(con, "
    SELECT
      c.country_name,
      a.admin_level,
      d.year,
      COUNT(*) as records,
      COUNT(DISTINCT d.admin_area_id) as areas,
      COUNT(DISTINCT d.indicator_id) as indicators
    FROM disruption_data d
    JOIN countries c ON d.country_id = c.country_id
    JOIN admin_areas a ON d.admin_area_id = a.admin_area_id
    GROUP BY c.country_name, a.admin_level, d.year
    ORDER BY c.country_name, a.admin_level, d.year
  ")
  print(summary)

  cat("\n====================================================================\n\n")

  return(summary)
}

# Clear all disruption data (use with caution!)
clear_all_disruption_data <- function() {
  cat("WARNING: This will delete ALL disruption data!\n")
  cat("Type 'YES' to confirm: ")
  response <- readline()

  if (response != "YES") {
    cat("Operation cancelled\n")
    return(FALSE)
  }

  con <- connect_db()
  if (is.null(con)) return(FALSE)
  on.exit(dbDisconnect(con))

  dbBegin(con)
  tryCatch({
    dbExecute(con, "DELETE FROM disruption_data")
    dbExecute(con, "DELETE FROM upload_history")
    dbCommit(con)
    cat("✓ All disruption data deleted\n")
    return(TRUE)
  }, error = function(e) {
    dbRollback(con)
    cat("✗ Error:", e$message, "\n")
    return(FALSE)
  })
}

# ====================================================================
# INSTRUCTIONS
# ====================================================================

cat("\n====================================================================\n")
cat("DATA IMPORT SCRIPT LOADED\n")
cat("====================================================================\n\n")
cat("Available functions:\n")
cat("  - import_nigeria()           : Import Nigeria data\n")
cat("  - import_all_countries()     : Import all configured countries\n")
cat("  - query_available_data()     : See what's in the database\n")
cat("  - clear_all_disruption_data(): Delete all data (use with caution!)\n\n")
cat("Example usage:\n")
cat("  source('import_data_to_db.R')\n")
cat("  import_nigeria()\n")
cat("  query_available_data()\n\n")
cat("====================================================================\n\n")
