# ========================================
# DATA LOADING AND PROCESSING FUNCTIONS
# ========================================

# Get available countries from geojson files
get_available_countries <- function() {
  geojson_files <- list.files("data/geojson", pattern = "*_backbone.geojson", full.names = FALSE)
  available_codes <- gsub("_backbone.geojson", "", geojson_files)

  allowlist <- c(
    cameroon = "Cameroon",
    ghana = "Ghana",
    ethiopia = "Ethiopia",
    guinea = "Guinea",
    nigeria = "Nigeria",
    haiti = "Haiti",
    liberia = "Liberia",
    sierraleone = "Sierra Leone",
    senegal = "Senegal",
    somalia = "Somalia",
    somaliland = "Somaliland"
  )

  present_codes <- names(allowlist)[names(allowlist) %in% available_codes]
  if (length(present_codes) == 0) {
    return(character(0))
  }

  setNames(present_codes, allowlist[present_codes])
}

# Convert YYYYMM period identifiers to Date objects (first day of month)
period_id_to_date <- function(period_id) {
  period_int <- suppressWarnings(as.integer(period_id))
  period_str <- sprintf("%06d", period_int)

  year <- suppressWarnings(as.integer(substr(period_str, 1, 4)))
  month <- suppressWarnings(as.integer(substr(period_str, 5, 6)))

  valid <- !is.na(year) & !is.na(month) & month >= 1 & month <= 12
  dates <- as.Date(rep(NA_character_, length(period_id)))
  dates[valid] <- as.Date(
    paste(year[valid], sprintf("%02d", month[valid]), "01", sep = "-"),
    format = "%Y-%m-%d"
  )
  dates
}

# Load pre-aggregated M2 year-on-year dataset
load_yoy_data <- function(file_path) {
  data <- data.table::fread(file_path, data.table = FALSE)

  required_cols <- c(
    "indicator_common_id",
    "period_id",
    "count_final_none",
    "count_final_outliers",
    "count_final_completeness",
    "count_final_both"
  )

  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols) > 0) {
    stop("Missing required columns in file: ", paste(missing_cols, collapse = ", "))
  }

  data <- data %>%
    mutate(
      period_id = suppressWarnings(as.integer(period_id)),
      period_date = period_id_to_date(period_id)
    )

  admin_columns <- names(data)[grepl("^admin_area", names(data))]
  admin_columns <- admin_columns[
    vapply(admin_columns, function(col) {
      any(!is.na(data[[col]]) & trimws(as.character(data[[col]])) != "")
    }, logical(1))
  ]

  available_levels <- character(0)
  if ("admin_area_2" %in% admin_columns) {
    available_levels <- c(available_levels, "2")
  }
  if ("admin_area_3" %in% admin_columns) {
    available_levels <- c(available_levels, "3")
  }

  list(
    data = data,
    available_levels = available_levels,
    admin_columns = admin_columns
  )
}

# Calculate six-month year-on-year summary for selected indicator/admin level
calculate_yoy_summary <- function(data, admin_level, admin_column, indicator_id, volume_metric) {
  valid_metrics <- c(
    "count_final_none",
    "count_final_outliers",
    "count_final_completeness",
    "count_final_both"
  )

  if (!volume_metric %in% valid_metrics) {
    stop("Invalid volume metric: ", volume_metric)
  }

  admin_col <- admin_column
  if (is.null(admin_col) || length(admin_col) != 1) {
    stop("An admin column must be specified for year-on-year calculations.")
  }
  if (!admin_col %in% names(data)) {
    stop("Admin column not found in dataset: ", admin_col)
  }

  indicator_data <- data %>%
    filter(
      indicator_common_id == indicator_id,
      !is.na(.data[[admin_col]]),
      .data[[admin_col]] != ""
    )

  if (nrow(indicator_data) == 0) {
    empty_summary <- tibble::tibble(
      admin_area = character(0),
      current_total = numeric(0),
      previous_total = numeric(0),
      percent_change = numeric(0),
      absolute_change = numeric(0),
      total_actual = numeric(0),
      total_expected = numeric(0)
    )
    return(list(
      summary = empty_summary,
      current_period_label = "Latest six months",
      previous_period_label = "Same months previous year"
    ))
  }

  periods <- sort(unique(indicator_data$period_id[!is.na(indicator_data$period_id)]))
  if (length(periods) == 0) {
    empty_summary <- tibble::tibble(
      admin_area = character(0),
      current_total = numeric(0),
      previous_total = numeric(0),
      percent_change = numeric(0),
      absolute_change = numeric(0),
      total_actual = numeric(0),
      total_expected = numeric(0)
    )
    return(list(
      summary = empty_summary,
      current_period_label = "Latest six months",
      previous_period_label = "Same months previous year"
    ))
  }

  window_size <- min(6, length(periods))
  current_window <- tail(periods, n = window_size)
  previous_window <- current_window - 100

  current_dates <- period_id_to_date(current_window)
  previous_dates <- period_id_to_date(previous_window)

  current_summary <- indicator_data %>%
    filter(period_id %in% current_window) %>%
    group_by(across(all_of(admin_col))) %>%
    summarise(
      current_total = sum(.data[[volume_metric]], na.rm = TRUE),
      .groups = "drop"
    )

  previous_summary <- indicator_data %>%
    filter(period_id %in% previous_window) %>%
    group_by(across(all_of(admin_col))) %>%
    summarise(
      previous_total = sum(.data[[volume_metric]], na.rm = TRUE),
      .groups = "drop"
    )

  summary <- full_join(current_summary, previous_summary, by = admin_col) %>%
    mutate(
      current_total = replace_na(current_total, 0),
      previous_total = replace_na(previous_total, 0),
      percent_change = case_when(
        previous_total == 0 & current_total == 0 ~ 0,
        previous_total == 0 ~ NA_real_,
        TRUE ~ (current_total - previous_total) / previous_total * 100
      ),
      absolute_change = current_total - previous_total,
      total_actual = current_total,
      total_expected = previous_total
    ) %>%
    rename(admin_area = !!admin_col) %>%
    arrange(admin_area)

  current_label <- format_period_range(current_dates)
  previous_label <- format_period_range(previous_dates)

  if (is.null(current_label)) {
    current_label <- "Latest six months"
  }
  if (is.null(previous_label)) {
    previous_label <- "Same months previous year"
  }

  list(
    summary = summary,
    current_period_label = current_label,
    previous_period_label = previous_label
  )
}

# Calculate disruption category based on percent change
calculate_category <- function(percent_change, total_expected) {
  case_when(
    total_expected == 0 | is.na(total_expected) | is.infinite(percent_change) ~ "Insufficient data",
    # Surplus categories (positive)
    percent_change >= 20 ~ "Surplus >20%",
    percent_change >= 15 & percent_change < 20 ~ "Surplus 15-20%",
    percent_change >= 10 & percent_change < 15 ~ "Surplus 10-15%",
    percent_change >= 7 & percent_change < 10 ~ "Surplus 7-10%",
    percent_change >= 5 & percent_change < 7 ~ "Surplus 5-7%",
    percent_change >= 3 & percent_change < 5 ~ "Surplus 3-5%",
    # Stable
    percent_change > -3 & percent_change < 3 ~ "Stable",
    # Disruption categories (negative)
    percent_change > -5 & percent_change <= -3 ~ "Disruption 3-5%",
    percent_change > -7 & percent_change <= -5 ~ "Disruption 5-7%",
    percent_change > -10 & percent_change <= -7 ~ "Disruption 7-10%",
    percent_change > -15 & percent_change <= -10 ~ "Disruption 10-15%",
    percent_change > -20 & percent_change <= -15 ~ "Disruption 15-20%",
    percent_change <= -20 ~ "Disruption >20%",
    TRUE ~ "Stable"
  )
}

# Calculate simplified category bands for heatmap display
calculate_heatmap_category <- function(percent_change, total_expected) {
  case_when(
    total_expected == 0 | is.na(total_expected) | is.infinite(percent_change) ~ "Insufficient data",
    percent_change <= -10 ~ "Disruption >10%",
    percent_change < -5 ~ "Disruption 5-10%",
    percent_change <= 5 ~ "Stable",
    percent_change < 10 ~ "Surplus 5-10%",
    TRUE ~ "Surplus >10%"
  )
}

# Helper: return friendly label for a vector of Date objects (first of month)
format_period_range <- function(dates) {
  if (length(dates) == 0 || all(is.na(dates))) {
    return(NULL)
  }

  month_names <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun",
                   "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")

  dates <- sort(unique(stats::na.omit(dates)))
  start_date <- min(dates)
  end_date <- max(dates)

  start_year <- as.integer(format(start_date, "%Y"))
  end_year <- as.integer(format(end_date, "%Y"))
  start_month <- as.integer(format(start_date, "%m"))
  end_month <- as.integer(format(end_date, "%m"))

  if (start_year == end_year) {
    if (start_month == end_month) {
      return(paste(month_names[start_month], start_year))
    }
    if (start_month == 1 && end_month == 12) {
      return(paste("Jan-Dec", start_year))
    }
    return(paste0(month_names[start_month], "-",
                  month_names[end_month], " ", start_year))
  }

  paste(
    paste(month_names[start_month], start_year),
    paste(month_names[end_month], end_year),
    sep = " - "
  )
}

# Helper: concise label when only year column is available
format_year_range <- function(data) {
  if (!("year" %in% names(data)) || nrow(data) == 0) {
    return(NULL)
  }
  years <- sort(unique(stats::na.omit(as.integer(data$year))))
  if (length(years) == 0) {
    return(NULL)
  }
  if (length(years) == 1) {
    return(as.character(years))
  }
  paste0(min(years), "-", max(years))
}

# Filter data to the most recent `months` months (based on period_id) and
# return both filtered data and a user-friendly period label.
prepare_period_window <- function(data, months = NULL) {
  if (is.null(data) || nrow(data) == 0) {
    return(list(data = data, label = NULL))
  }

  if (!("period_id" %in% names(data))) {
    return(list(data = data, label = format_year_range(data)))
  }

  period_int <- suppressWarnings(as.integer(data$period_id))
  if (all(is.na(period_int))) {
    return(list(data = data, label = format_year_range(data)))
  }

  # Build date column (YYYYMM -> first day of month)
  period_str <- sprintf("%06d", period_int)
  period_year <- suppressWarnings(as.integer(substr(period_str, 1, 4)))
  period_month <- suppressWarnings(as.integer(substr(period_str, 5, 6)))

  valid_idx <- !is.na(period_year) & !is.na(period_month)
  if (!any(valid_idx)) {
    return(list(data = data, label = format_year_range(data)))
  }

  period_dates <- as.Date(paste(period_year[valid_idx],
                                sprintf("%02d", period_month[valid_idx]),
                                "01", sep = "-"))

  unique_dates <- sort(unique(period_dates))

  if (!is.null(months) && months > 0) {
    keep_dates <- tail(unique_dates, n = min(months, length(unique_dates)))
  } else {
    keep_dates <- unique_dates
  }

  if (length(keep_dates) == 0) {
    return(list(data = data[valid_idx, , drop = FALSE],
                label = format_year_range(data)))
  }

  # Indices of rows to keep (match by year/month)
  keep_mask <- valid_idx & (as.Date(paste(period_year,
                                          sprintf("%02d", period_month),
                                          "01", sep = "-")) %in% keep_dates)

  filtered_data <- data[keep_mask, , drop = FALSE]

  list(
    data = filtered_data,
    label = format_period_range(keep_dates)
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

  header <- data.table::fread(file_path, nrows = 0, showProgress = FALSE)

  col_classes_map <- list(
    admin_area_2 = "character",
    admin_area_3 = "character",
    indicator_common_id = "character",
    period_id = "integer",
    year = "integer",
    count_sum = "numeric",
    count_expect_sum = "numeric",
    percent_change = "numeric"
  )

  available_classes <- col_classes_map[names(col_classes_map) %in% names(header)]

  data <- data.table::fread(
    file_path,
    data.table = FALSE,
    colClasses = available_classes,
    showProgress = FALSE
  )

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
