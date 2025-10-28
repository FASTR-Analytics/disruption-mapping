# ========================================
# DATA LOADING AND PROCESSING FUNCTIONS
# ========================================

# Get available countries from geojson files
get_available_countries <- function() {
  geojson_files <- list.files("data/geojson", pattern = "*_backbone.geojson", full.names = FALSE)
  countries <- gsub("_backbone.geojson", "", geojson_files)
  # Clean up country names for display
  country_names <- tools::toTitleCase(gsub("([0-9])", " \\1", countries))
  setNames(countries, country_names)
}

# Calculate disruption category based on percent change
calculate_category <- function(percent_change, total_expected) {
  case_when(
    total_expected == 0 | is.na(total_expected) | is.infinite(percent_change) ~ "Insufficient data",
    percent_change >= 10 ~ "Surplus >10%",
    percent_change >= 5 & percent_change < 10 ~ "Surplus 5-10%",
    percent_change > -5 & percent_change < 5 ~ "Stable",
    percent_change > -10 & percent_change <= -5 ~ "Disruption 5-10%",
    percent_change <= -10 ~ "Disruption >10%",
    TRUE ~ "Stable"
  )
}

# Calculate disruption summary for a specific indicator
calculate_disruption_summary <- function(data, year_val, indicator_id, admin_level) {

  year_data <- data %>%
    filter(year == as.numeric(year_val),
           indicator_common_id == indicator_id)

  # Determine which admin column to use
  admin_col <- if(admin_level == "3") "admin_area_3" else "admin_area_2"

  # Calculate summary by admin area
  summary <- year_data %>%
    group_by(across(all_of(admin_col))) %>%
    summarise(
      total_actual = sum(count_sum, na.rm = TRUE),
      total_expected = sum(count_expect_sum, na.rm = TRUE),
      .groups = "drop"
    )

  # Rename the grouping column to a standard name
  names(summary)[1] <- "admin_area"

  # Calculate percent change and category
  summary <- summary %>%
    mutate(
      percent_change = (total_actual - total_expected) / total_expected * 100,
      category = calculate_category(percent_change, total_expected)
    ) %>%
    mutate(category = factor(category, levels = all_categories))

  return(summary)
}

# Load and validate disruption data from CSV
load_disruption_data <- function(file_path) {

  data <- read.csv(file_path, stringsAsFactors = FALSE)

  # Detect admin level from columns
  has_admin_2 <- "admin_area_2" %in% names(data)
  has_admin_3 <- "admin_area_3" %in% names(data)

  # Validate required columns
  required_cols_base <- c("indicator_common_id", "count_sum", "count_expect_sum")

  # Determine which admin level this file is for
  if (has_admin_3) {
    detected_level <- "3"
    required_cols <- c("admin_area_2", "admin_area_3", required_cols_base)
  } else if (has_admin_2) {
    detected_level <- "2"
    required_cols <- c("admin_area_2", required_cols_base)
  } else {
    stop("Missing admin area columns (admin_area_2 or admin_area_3)")
  }

  if (!all(required_cols %in% names(data))) {
    missing <- setdiff(required_cols, names(data))
    stop(paste("Missing required columns:", paste(missing, collapse = ", ")))
  }

  # Extract year from period_id if year column doesn't exist
  if (!"year" %in% names(data)) {
    if ("period_id" %in% names(data)) {
      data$year <- as.integer(substr(data$period_id, 1, 4))
    } else {
      stop("Missing 'year' or 'period_id' column")
    }
  }

  return(list(
    data = data,
    detected_level = detected_level
  ))
}

# Get unique years from data
get_years_from_data <- function(data) {
  sort(unique(data$year))
}

# Get unique indicators from data
get_indicators_from_data <- function(data) {
  data %>%
    distinct(indicator_common_id) %>%
    left_join(indicator_labels, by = c("indicator_common_id" = "indicator_id")) %>%
    arrange(indicator_name)
}

# ========================================
# DATABASE FUNCTIONS
# ========================================

# Get available countries from database
get_db_countries <- function(con) {
  if (is.null(con) || !dbIsValid(con)) return(character(0))

  tryCatch({
    countries <- dbGetQuery(con, "SELECT country_code, country_name FROM countries ORDER BY country_name")
    setNames(countries$country_code, countries$country_name)
  }, error = function(e) {
    message("Error querying countries from database: ", e$message)
    return(character(0))
  })
}

# Get available years for a country from database
get_db_years <- function(con, country_code, admin_level) {
  if (is.null(con) || !dbIsValid(con)) return(integer(0))

  tryCatch({
    query <- "SELECT DISTINCT d.year
              FROM disruption_data d
              JOIN countries c ON d.country_id = c.country_id
              JOIN admin_areas a ON d.admin_area_id = a.admin_area_id
              WHERE c.country_code = $1 AND a.admin_level = $2
              ORDER BY d.year DESC"
    result <- dbGetQuery(con, query, params = list(country_code, as.integer(admin_level)))
    result$year
  }, error = function(e) {
    message("Error querying years from database: ", e$message)
    return(integer(0))
  })
}

# Load disruption data from database
load_db_disruption_data <- function(con, country_code, admin_level, year = NULL) {
  if (is.null(con) || !dbIsValid(con)) return(NULL)

  tryCatch({
    query <- "SELECT
                a.admin_level,
                CASE
                  WHEN a.admin_level = 3 THEN parent.area_name
                  ELSE a.area_name
                END as admin_area_2,
                CASE
                  WHEN a.admin_level = 3 THEN a.area_name
                  ELSE NULL
                END as admin_area_3,
                i.indicator_code as indicator_common_id,
                d.period_id,
                d.year,
                d.count_actual as count_sum,
                d.count_expected as count_expect_sum,
                d.percent_change
              FROM disruption_data d
              JOIN countries c ON d.country_id = c.country_id
              JOIN admin_areas a ON d.admin_area_id = a.admin_area_id
              LEFT JOIN admin_areas parent ON a.parent_area_id = parent.admin_area_id
              JOIN indicators i ON d.indicator_id = i.indicator_id
              WHERE c.country_code = $1
                AND a.admin_level = $2"

    params <- list(country_code, as.integer(admin_level))

    if (!is.null(year)) {
      query <- paste(query, "AND d.year = $3")
      params <- c(params, list(as.integer(year)))
    }

    query <- paste(query, "ORDER BY d.year, d.period_id, a.area_name")

    result <- dbGetQuery(con, query, params = params)

    # Remove admin_area_3 column if it's all NULL (Level 2 data)
    if (all(is.na(result$admin_area_3))) {
      result$admin_area_3 <- NULL
    }

    return(result)
  }, error = function(e) {
    message("Error loading data from database: ", e$message)
    return(NULL)
  })
}
