# ========================================
# FASTR HEALTH SERVICE DISRUPTION MAPPING
# ========================================
# Purpose: Interactive visualization of health service disruptions
# with support for PostgreSQL database and CSV uploads

# Load required libraries
library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(dplyr)
library(sf)
library(leaflet)
library(tidyr)
library(DT)
library(ggplot2)
library(htmlwidgets)
library(rlang)
library(data.table)

# Required for professional map export
if (!requireNamespace("ggspatial", quietly = TRUE)) {
  message("ggspatial not installed. Map export will not be available.")
  message("Install with: install.packages('ggspatial')")
}

library(ggspatial)

# Optional: diagonal stripe patterns on insufficient data
pattern_available <- FALSE
tryCatch({
  if (requireNamespace("ggpattern", quietly = TRUE) &&
      requireNamespace("leaflet.extras2", quietly = TRUE)) {
    pattern_available <- TRUE
  } else {
    stop("Pattern packages missing")
  }
}, error = function(e) {
  message("Pattern packages not available - using solid colors for insufficient data")
})

# Database libraries (optional - app works without them)
db_available <- FALSE
tryCatch({
  library(DBI)
  library(RPostgres)
  db_available <- TRUE
}, error = function(e) {
  message("Database packages not available - file upload only mode")
})

# Turn off spherical geometry for faster processing
sf_use_s2(FALSE)

# Increase file upload size limit to 2GB
options(shiny.maxRequestSize = 2000*1024^2)

# Load environment variables if .env file exists
if (file.exists(".env")) {
  readRenviron(".env")
}

# Source modular R files
source("R/indicators.R")
source("R/translations.R")
source("R/data_functions.R")
source("R/map_functions.R")
source("R/ui_components.R")

# ========================================
# DATABASE CONFIGURATION
# ========================================

DB_CONFIG <- list(
  host = Sys.getenv("DB_HOST", "localhost"),
  port = as.integer(Sys.getenv("DB_PORT", "5432")),
  dbname = Sys.getenv("DB_NAME", "disruption_mapping"),
  user = Sys.getenv("DB_USER", Sys.getenv("USER")),
  password = Sys.getenv("DB_PASSWORD", "")
)

USE_DATABASE <- tolower(Sys.getenv("USE_DATABASE", "FALSE")) == "true"

# Try to connect to database
db_connection <- NULL
db_connected <- FALSE

if (db_available && USE_DATABASE) {
  tryCatch({
    db_connection <- dbConnect(
      Postgres(),
      host = DB_CONFIG$host,
      port = DB_CONFIG$port,
      dbname = DB_CONFIG$dbname,
      user = DB_CONFIG$user,
      password = DB_CONFIG$password
    )
    db_connected <- dbIsValid(db_connection)
    if (db_connected) {
      message("✓ Connected to PostgreSQL database")
    }
  }, error = function(e) {
    message("Database connection failed - using file upload mode")
    message("Error: ", e$message)
    db_connected <<- FALSE
  })
}

# ========================================
# UI DEFINITION
# ========================================

ui <- dashboardPage(
  skin = "blue",
  create_app_header(),
  create_app_sidebar(),

  dashboardBody(
    # Load external CSS and JS
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "custom.css"),
      tags$script(src = "language.js"),
      tags$script(HTML("
        document.addEventListener('DOMContentLoaded', function() {
          var menu = document.querySelector('.sidebar-menu');
          if (menu) {
            var firstItem = menu.querySelector('li');
            if (firstItem && !firstItem.classList.contains('active')) {
              firstItem.classList.add('active');
            }
          }
          var tracker = document.querySelector('.sidebarMenuSelectedTabItem');
          if (tracker && (!tracker.dataset.value || tracker.dataset.value === 'null')) {
            tracker.dataset.value = 'map';
          }
          if (window.Shiny && typeof Shiny.setInputValue === 'function') {
            Shiny.setInputValue('app_tabs', 'map', {priority: 'event'});
          }
        });
      "))
    ),

    # All tabs from ui_components.R
    tabItems(
      create_map_tab(db_connected),
      create_faceted_map_tab(),
      create_heatmap_tab(),
      create_stats_tab(),
      create_yoy_tab(),
      create_about_tab()
    )
  )
)

# ========================================
# SERVER LOGIC
# ========================================

server <- function(input, output, session) {

  # Reactive values
  rv <- reactiveValues(
    geo_data = NULL,
    disruption_data = NULL,
    map_data = NULL,
    data_admin_level = NULL,
    yoy_geo_data = NULL,
    yoy_data = NULL,
    yoy_data_admin_level = NULL,
    yoy_admin_column = NULL,
    yoy_admin_columns = character(0),
    lang = "en"  # Default language
  )

  # Language toggle
  observeEvent(input$toggle_language, {
    # Toggle between EN and FR
    rv$lang <- ifelse(rv$lang == "en", "fr", "en")

    # Update button label
    updateActionButton(session, "toggle_language",
                      label = ifelse(rv$lang == "en", "FR", "EN"))

    # Update indicator dropdown if data is loaded
    if (!is.null(rv$disruption_data)) {
      indicators <- rv$disruption_data %>%
        distinct(indicator_common_id) %>%
        left_join(current_indicator_labels(), by = c("indicator_common_id" = "indicator_id")) %>%
        arrange(indicator_name)

      indicator_choices <- setNames(indicators$indicator_common_id,
                                   ifelse(is.na(indicators$indicator_name),
                                         indicators$indicator_common_id,
                                         indicators$indicator_name))

      # Keep current selection
      current_selection <- input$indicator

        updateSelectInput(session, "indicator",
                         choices = indicator_choices,
                         selected = current_selection)
    }

    # Update YoY indicator dropdown
    if (!is.null(rv$yoy_data)) {
      yoy_indicators <- rv$yoy_data %>%
        distinct(indicator_common_id) %>%
        left_join(current_indicator_labels(), by = c("indicator_common_id" = "indicator_id")) %>%
        arrange(indicator_name)

      yoy_indicator_choices <- setNames(yoy_indicators$indicator_common_id,
                                       ifelse(is.na(yoy_indicators$indicator_name),
                                              yoy_indicators$indicator_common_id,
                                              yoy_indicators$indicator_name))

      current_yoy_selection <- input$yoy_indicator

      updateSelectInput(session, "yoy_indicator",
                       choices = yoy_indicator_choices,
                       selected = current_yoy_selection)
    }

    # Update faceted map indicator dropdowns
    if (!is.null(rv$disruption_data)) {
      faceted_indicators <- rv$disruption_data %>%
        distinct(indicator_common_id) %>%
        left_join(current_indicator_labels(), by = c("indicator_common_id" = "indicator_id")) %>%
        arrange(indicator_name)

      faceted_indicator_choices <- setNames(faceted_indicators$indicator_common_id,
                                           ifelse(is.na(faceted_indicators$indicator_name),
                                                  faceted_indicators$indicator_common_id,
                                                  faceted_indicators$indicator_name))

      # Keep current selections
      current_faceted_1 <- input$faceted_indicator1
      current_faceted_2 <- input$faceted_indicator2
      current_faceted_3 <- input$faceted_indicator3
      current_faceted_4 <- input$faceted_indicator4

      updateSelectInput(session, "faceted_indicator1",
                       choices = faceted_indicator_choices,
                       selected = current_faceted_1)
      updateSelectInput(session, "faceted_indicator2",
                       choices = faceted_indicator_choices,
                       selected = current_faceted_2)
      updateSelectInput(session, "faceted_indicator3",
                       choices = faceted_indicator_choices,
                       selected = current_faceted_3)
      updateSelectInput(session, "faceted_indicator4",
                       choices = faceted_indicator_choices,
                       selected = current_faceted_4)
    }

    # Show notification
    msg <- ifelse(rv$lang == "fr",
                  "Langue changée en français",
                  "Language changed to English")
    showNotification(msg, type = "message", duration = 2)
  })

  # Get current language translations
  tr <- reactive({
    lang <- rv$lang
    function(key) translate_text(key, lang)
  })

  # Get current indicator labels based on language
  current_indicator_labels <- reactive({
    if (rv$lang == "fr") {
      indicator_labels_fr
    } else {
      indicator_labels
    }
  })

  get_indicator_display_name <- function(indicator_id) {
    if (is.null(indicator_id) || length(indicator_id) == 0 || is.na(indicator_id)) {
      return("")
    }
    labels_df <- current_indicator_labels()
    if (is.null(labels_df) || nrow(labels_df) == 0) {
      return(as.character(indicator_id))
    }
    matches <- labels_df$indicator_name[labels_df$indicator_id == indicator_id]
    matches <- matches[!is.na(matches) & matches != ""]
    if (length(matches) == 0) {
      return(as.character(indicator_id))
    }
    as.character(matches[1])
  }

  # Initialize country choices
  observe({
    countries <- get_available_countries()
    updateSelectInput(session, "country",
                     choices = countries,
                     selected = if(length(countries) > 0) countries[1] else NULL)
    updateSelectInput(session, "yoy_country",
                     choices = countries,
                     selected = if(length(countries) > 0) countries[1] else NULL)
  })

  # Load GeoJSON when country or admin level changes
  observeEvent(c(input$country, input$admin_level), {
    req(input$country, input$admin_level)

    tryCatch({
      rv$geo_data <- load_geojson_boundaries(input$country, input$admin_level)

      if (!is.null(rv$geo_data)) {
        level_name <- if(input$admin_level == "2") "State/Province" else "District/LGA"
        showNotification(paste("Loaded", level_name, "boundaries for", tools::toTitleCase(input$country)),
                        type = "message")
      }
    }, error = function(e) {
      showNotification(paste("Error loading GeoJSON:", e$message), type = "error")
    })
  })

  observeEvent(c(input$yoy_country, input$yoy_admin_level), {
    req(input$yoy_country, input$yoy_admin_level)

    tryCatch({
      rv$yoy_geo_data <- load_geojson_boundaries(input$yoy_country, input$yoy_admin_level)

      if (!is.null(rv$yoy_geo_data)) {
        level_name <- if(input$yoy_admin_level == "3") "District/LGA" else "State/Province"
        showNotification(
          paste("Loaded", level_name, "boundaries for", tools::toTitleCase(input$yoy_country)),
          type = "message"
        )
      }
    }, error = function(e) {
      showNotification(paste("Error loading GeoJSON:", e$message), type = "error")
    })
  })

  # Load disruption data from database
  observeEvent(c(input$data_source, input$country, input$admin_level), {
    req(input$data_source == "database", db_connected, input$country, input$admin_level)

    tryCatch({
      data <- load_db_disruption_data(db_connection, input$country, input$admin_level)

      if (!is.null(data) && nrow(data) > 0) {
        rv$disruption_data <- data
        rv$data_admin_level <- input$admin_level

        # Update year choices
        years <- get_years_from_data(rv$disruption_data)
        updateSelectInput(session, "year",
                         choices = years,
                         selected = max(years))

        # Update indicator choices
        indicators <- rv$disruption_data %>%
          distinct(indicator_common_id) %>%
          left_join(current_indicator_labels(), by = c("indicator_common_id" = "indicator_id")) %>%
          arrange(indicator_name)

        indicator_choices <- setNames(indicators$indicator_common_id,
                                     ifelse(is.na(indicators$indicator_name),
                                           indicators$indicator_common_id,
                                           indicators$indicator_name))

        updateSelectInput(session, "indicator",
                         choices = indicator_choices,
                         selected = indicator_choices[1])

        # Update faceted map indicator dropdowns
        default_selections <- indicator_choices[1:min(2, length(indicator_choices))]
        updateSelectInput(session, "faceted_indicator1",
                         choices = indicator_choices,
                         selected = default_selections[1])
        updateSelectInput(session, "faceted_indicator2",
                         choices = indicator_choices,
                         selected = if(length(default_selections) >= 2) default_selections[2] else NULL)
        updateSelectInput(session, "faceted_indicator3",
                         choices = indicator_choices,
                         selected = if(length(default_selections) >= 3) default_selections[3] else NULL)
        updateSelectInput(session, "faceted_indicator4",
                         choices = indicator_choices,
                         selected = if(length(default_selections) >= 4) default_selections[4] else NULL)

        level_name <- if(input$admin_level == "2") "Admin Level 2" else "Admin Level 3"
        showNotification(paste("Data loaded from database (", level_name, ")"), type = "message")
      } else {
        showNotification("No data found in database for selected country/level", type = "warning")
        rv$disruption_data <- NULL
      }
    }, error = function(e) {
      showNotification(paste("Error loading from database:", e$message), type = "error")
      rv$disruption_data <- NULL
    })
  })

  # Load disruption data from uploaded file
  observeEvent(input$disruption_file, {
    req(input$disruption_file)

    # Show file size to user
    file_size_mb <- round(input$disruption_file$size / 1024^2, 2)
    showNotification(paste0("Uploading file (", file_size_mb, " MB)..."),
                    type = "message", duration = 3)

    tryCatch({
      withProgress(message = paste0('Loading CSV file (', file_size_mb, ' MB)...'), value = 0, {
        incProgress(0.3, detail = "Reading file...")
        result <- load_disruption_data(input$disruption_file$datapath)
        rv$disruption_data <- result$data
        rv$data_admin_level <- result$detected_level

        incProgress(0.3, detail = "Processing data...")

        # Auto-update admin level selector to match the data
        updateSelectInput(session, "admin_level", selected = result$detected_level)

        # Update year choices
        years <- get_years_from_data(rv$disruption_data)
        updateSelectInput(session, "year",
                         choices = years,
                         selected = max(years))

        incProgress(0.2, detail = "Loading indicators...")

        # Update indicator choices - optimized with data.table for speed
        unique_indicators <- unique(rv$disruption_data$indicator_common_id)
        labels_df <- current_indicator_labels()

        # Fast merge using data.table operations
        indicators_dt <- data.table(indicator_common_id = unique_indicators)
        labels_dt <- as.data.table(labels_df)
        setkey(indicators_dt, indicator_common_id)
        setkey(labels_dt, indicator_id)

        merged <- labels_dt[indicators_dt, on = .(indicator_id = indicator_common_id)]
        merged <- merged[order(indicator_name)]

        indicator_choices <- setNames(
          merged$indicator_id,
          ifelse(is.na(merged$indicator_name), merged$indicator_id, merged$indicator_name)
        )

        updateSelectInput(session, "indicator",
                         choices = indicator_choices,
                         selected = indicator_choices[1])

        # Update faceted map indicator dropdowns
        default_selections <- indicator_choices[1:min(2, length(indicator_choices))]
        updateSelectInput(session, "faceted_indicator1",
                         choices = indicator_choices,
                         selected = default_selections[1])
        updateSelectInput(session, "faceted_indicator2",
                         choices = indicator_choices,
                         selected = if(length(default_selections) >= 2) default_selections[2] else NULL)
        updateSelectInput(session, "faceted_indicator3",
                         choices = indicator_choices,
                         selected = if(length(default_selections) >= 3) default_selections[3] else NULL)
        updateSelectInput(session, "faceted_indicator4",
                         choices = indicator_choices,
                         selected = if(length(default_selections) >= 4) default_selections[4] else NULL)

        incProgress(0.2, detail = "Complete!")
      })

      level_name <- if(result$detected_level == "2") "Admin Level 2" else "Admin Level 3"
      row_count <- format(nrow(rv$disruption_data), big.mark = ",")
      showNotification(paste0("Disruption data loaded successfully (", level_name, ", ", row_count, " rows)"),
                      type = "message", duration = 5)

    }, error = function(e) {
      showNotification(paste("Error loading disruption data:", e$message), type = "error")
    })
  })

  observeEvent(input$yoy_file, {
    req(input$yoy_file)

    file_size_mb <- round(input$yoy_file$size / 1024^2, 2)
    showNotification(
      paste0("Uploading file (", file_size_mb, " MB)..."),
      type = "message",
      duration = 3
    )

    tryCatch({
      withProgress(message = paste0("Loading CSV file (", file_size_mb, " MB)..."), value = 0, {
        incProgress(0.3, detail = "Reading file...")
        result <- load_yoy_data(input$yoy_file$datapath)
        rv$yoy_data <- result$data

        incProgress(0.4, detail = "Preparing indicators...")

        available_levels <- result$available_levels
        level_labels <- c(
          "Admin level 2 – State/Province" = "2",
          "Admin level 3 – District/LGA" = "3"
        )
        available_choices <- level_labels[level_labels %in% available_levels]
        if (length(available_choices) == 0) {
          available_choices <- level_labels
        }
        selected_level <- if ("2" %in% available_choices) "2" else available_choices[1]
        rv$yoy_data_admin_level <- selected_level

        updateSelectInput(
          session,
          "yoy_admin_level",
          choices = available_choices,
          selected = selected_level
        )

        admin_columns <- result$admin_columns
        rv$yoy_admin_columns <- admin_columns
        if (length(admin_columns) > 0) {
          admin_labels <- tools::toTitleCase(gsub("_", " ", admin_columns))
          admin_choices <- setNames(
            admin_columns,
            paste0(admin_labels, " (", admin_columns, ")")
          )
          preferred_column <- NULL
          if (!is.null(selected_level)) {
            if (selected_level == "3" && "admin_area_3" %in% admin_columns) {
              preferred_column <- "admin_area_3"
            } else if (selected_level == "2" && "admin_area_2" %in% admin_columns) {
              preferred_column <- "admin_area_2"
            }
          }
          if (is.null(preferred_column) && "admin_area_4" %in% admin_columns) {
            preferred_column <- "admin_area_4"
          }
          if (is.null(preferred_column) && length(admin_columns) > 0) {
            preferred_column <- admin_columns[1]
          }
          rv$yoy_admin_column <- preferred_column
          updateSelectInput(
            session,
            "yoy_admin_column",
            choices = admin_choices,
            selected = preferred_column
          )
        } else {
          rv$yoy_admin_column <- NULL
          rv$yoy_admin_columns <- character(0)
          updateSelectInput(
            session,
            "yoy_admin_column",
            choices = setNames(character(0), character(0)),
            selected = NULL
          )
        }

        unique_indicators <- unique(rv$yoy_data$indicator_common_id)
        labels_df <- current_indicator_labels()

        indicators_dt <- data.table(indicator_common_id = unique_indicators)
        labels_dt <- as.data.table(labels_df)
        setkey(indicators_dt, indicator_common_id)
        setkey(labels_dt, indicator_id)

        merged <- labels_dt[indicators_dt, on = .(indicator_id = indicator_common_id)]
        merged <- merged[order(indicator_name)]

        indicator_choices <- setNames(
          merged$indicator_id,
          ifelse(is.na(merged$indicator_name), merged$indicator_id, merged$indicator_name)
        )

        selected_indicator <- if (length(indicator_choices) > 0) indicator_choices[1] else NULL
        updateSelectInput(
          session,
          "yoy_indicator",
          choices = indicator_choices,
          selected = selected_indicator
        )

        incProgress(0.3, detail = "Complete!")
      })

      row_count <- format(nrow(rv$yoy_data), big.mark = ",")
      showNotification(
        paste0("Year-on-year data loaded successfully (", row_count, " rows)"),
        type = "message",
        duration = 5
      )
    }, error = function(e) {
      showNotification(paste("Error loading year-on-year data:", e$message), type = "error")
      rv$yoy_data <- NULL
      rv$yoy_admin_columns <- character(0)
      rv$yoy_admin_column <- NULL
    })
  })

  observeEvent(input$yoy_admin_level, {
    req(input$yoy_admin_level)
    rv$yoy_data_admin_level <- input$yoy_admin_level

    available_cols <- rv$yoy_admin_columns
    current_col <- isolate(input$yoy_admin_column)

    if (length(available_cols) > 0) {
      preferred_column <- current_col
      if (is.null(preferred_column) || !(preferred_column %in% available_cols)) {
        if (input$yoy_admin_level == "3" && "admin_area_3" %in% available_cols) {
          preferred_column <- "admin_area_3"
        } else if (input$yoy_admin_level == "2" && "admin_area_2" %in% available_cols) {
          preferred_column <- "admin_area_2"
        } else {
          preferred_column <- available_cols[1]
        }
        updateSelectInput(session, "yoy_admin_column", selected = preferred_column)
      }
      rv$yoy_admin_column <- preferred_column
    }
  })

  observeEvent(input$yoy_admin_column, {
    req(input$yoy_admin_column)
    rv$yoy_admin_column <- input$yoy_admin_column
  })

  # Helper reactive: period window for disruption map
  disruption_window <- reactive({
    req(rv$disruption_data, input$year, input$indicator, input$period_window)

    year_data <- rv$disruption_data %>%
      filter(
        year == as.numeric(input$year),
        indicator_common_id == input$indicator
      )

    # Determine number of months to include
    months_to_include <- if(input$period_window == "all") {
      NULL  # NULL means all months
    } else {
      as.numeric(input$period_window)
    }

    window <- prepare_period_window(year_data, months = months_to_include)
    if (is.null(window$label)) {
      window$label <- as.character(input$year)
    }
    window
  })

  # Helper reactive: period window for faceted map (multiple indicators)
  faceted_window <- reactive({
    req(rv$disruption_data, input$year, input$period_window)

    # Filter by year only, NOT by indicator (allows multiple indicators)
    year_data <- rv$disruption_data %>%
      filter(year == as.numeric(input$year))

    # Determine number of months to include
    months_to_include <- if(input$period_window == "all") {
      NULL  # NULL means all months
    } else {
      as.numeric(input$period_window)
    }

    window <- prepare_period_window(year_data, months = months_to_include)
    if (is.null(window$label)) {
      window$label <- as.character(input$year)
    }
    window
  })

  # Calculate disruption summary for selected indicator
  disruption_summary <- reactive({
    req(rv$disruption_data, input$year, input$indicator, rv$data_admin_level)

    window <- disruption_window()
    filtered_data <- window$data

    if (is.null(filtered_data) || nrow(filtered_data) == 0) {
      return(NULL)
    }

    # Determine which admin column to use
    admin_col <- if(rv$data_admin_level == "3") "admin_area_3" else "admin_area_2"

    # Calculate summary by admin area using filtered data
    summary <- filtered_data %>%
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
  })

  # Create map data by joining geo and disruption data
  map_data <- reactive({
    req(rv$geo_data, disruption_summary())

    map_data <- rv$geo_data %>%
      left_join(disruption_summary(), by = c("name" = "admin_area"))

    rv$map_data <- map_data
    return(map_data)
  })

  # Render map
  output$map <- renderLeaflet({
    req(map_data())

    show_labels <- isTRUE(input$show_labels)

    render_disruption_map(
      map_data = map_data(),
      show_labels = show_labels
    )
  })

  yoy_summary_info <- reactive({
    req(rv$yoy_data, input$yoy_indicator, input$yoy_admin_level, input$yoy_admin_column, input$yoy_volume_metric)

    calculate_yoy_summary(
      data = rv$yoy_data,
      admin_level = input$yoy_admin_level,
      admin_column = input$yoy_admin_column,
      indicator_id = input$yoy_indicator,
      volume_metric = input$yoy_volume_metric
    )
  })

  yoy_map_data <- reactive({
    info <- yoy_summary_info()
    req(rv$yoy_geo_data, info)

    map_data <- rv$yoy_geo_data %>%
      left_join(info$summary, by = c("name" = "admin_area"))

    return(map_data)
  })

  output$yoy_map <- renderLeaflet({
    info <- yoy_summary_info()
    req(yoy_map_data(), info)

    render_yoy_map(
      map_data = yoy_map_data(),
      current_label = info$current_period_label,
      previous_label = info$previous_period_label,
      show_labels = isTRUE(input$yoy_show_labels)
    )
  })

  # Helper reactive: last 6-month window for heatmap
  heatmap_window <- reactive({
    req(rv$disruption_data, input$year)

    year_data <- rv$disruption_data %>%
      filter(year == as.numeric(input$year))

    window <- prepare_period_window(year_data, months = 6)
    if (is.null(window$label)) {
      window$label <- as.character(input$year)
    }
    window
  })

  # Display current indicator name on map tab
  output$current_indicator_display <- renderUI({
    req(input$indicator)

    # Add language as dependency to trigger re-render
    current_lang <- rv$lang

    indicator_text <- get_indicator_display_name(input$indicator)

    # Use the disruption_window to get the period label
    window <- disruption_window()
    period_label <- window$label

    if (is.null(period_label)) {
      period_label <- as.character(input$year)
    }

    if (!is.null(indicator_text) && indicator_text != "") {
      if (!is.null(period_label)) {
        tags$span(paste(indicator_text, "-", period_label))
      } else {
        tags$span(indicator_text)
      }
    } else {
      tags$span(style = "color: #999;", "No indicator selected")
    }
  })

  output$yoy_indicator_display <- renderUI({
    req(input$yoy_indicator, input$yoy_volume_metric)

    # Add language as dependency to trigger re-render
    current_lang <- rv$lang

    indicator_text <- get_indicator_display_name(input$yoy_indicator)

    volume_labels <- c(
      "count_final_none" = "Not adjusted",
      "count_final_outliers" = "Adjusted for outliers",
      "count_final_completeness" = "Adjusted for completeness",
      "count_final_both" = "Adjusted for completeness and outliers"
    )

    volume_label <- volume_labels[[input$yoy_volume_metric]]

    if (is.null(indicator_text) || indicator_text == "") {
      indicator_text <- input$yoy_indicator
    }

    if (!is.null(volume_label) && !is.na(volume_label)) {
      tags$span(paste(indicator_text, "-", volume_label))
    } else {
      tags$span(indicator_text)
    }
  })

  output$yoy_period_display <- renderUI({
    info <- yoy_summary_info()
    req(info$current_period_label, info$previous_period_label)

    tags$div(
      style = "margin-top: 18px;",
      tags$div(
        style = "font-size: 11px; color: #666; font-weight: 500; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px;",
        "Comparison Window"
      ),
      tags$div(
        style = "font-size: 14px; color: #333; font-weight: 600;",
        paste(info$current_period_label, "vs", info$previous_period_label)
      )
    )
  })

  # Display current indicator name on stats tab
  output$current_indicator_display_stats <- renderUI({
    req(input$indicator)

    # Add language as dependency to trigger re-render
    current_lang <- rv$lang

    indicator_text <- get_indicator_display_name(input$indicator)

    # Use the disruption_window to get the period label
    window <- disruption_window()
    period_label <- window$label

    if (is.null(period_label)) {
      period_label <- as.character(input$year)
    }

    if (!is.null(indicator_text) && indicator_text != "") {
      if (!is.null(period_label)) {
        tags$span(paste(indicator_text, "-", period_label))
      } else {
        tags$span(indicator_text)
      }
    } else {
      tags$span(style = "color: #999;", "No indicator selected")
    }
  })

  # Value boxes
  output$total_districts <- renderValueBox({
    req(disruption_summary())
    valueBox(
      nrow(disruption_summary()),
      "Total Areas",
      icon = icon("map-marker-alt"),
      color = "blue"
    )
  })

  output$disrupted_count <- renderValueBox({
    req(disruption_summary())
    count <- sum(grepl("Disruption", disruption_summary()$category))
    valueBox(
      count,
      "Areas with Disruption",
      icon = icon("exclamation-triangle"),
      color = "red"
    )
  })

  output$stable_count <- renderValueBox({
    req(disruption_summary())
    count <- sum(disruption_summary()$category == "Stable", na.rm = TRUE)
    valueBox(
      count,
      "Stable Areas",
      icon = icon("check-circle"),
      color = "yellow"
    )
  })

  output$surplus_count <- renderValueBox({
    req(disruption_summary())
    count <- sum(grepl("Surplus", disruption_summary()$category))
    valueBox(
      count,
      "Areas with Surplus",
      icon = icon("arrow-up"),
      color = "green"
    )
  })

  # Category chart
  output$category_chart <- renderPlot({
    req(disruption_summary())

    # Add language as dependency to trigger re-render
    current_lang <- rv$lang

    data <- disruption_summary() %>%
      count(category) %>%
      mutate(category = factor(category, levels = all_categories))

    # Translate category labels if French
    if (current_lang == "fr") {
      data <- data %>%
        mutate(
          category = case_when(
            category == "Disruption >20%" ~ "Perturbation >20%",
            category == "Disruption 15-20%" ~ "Perturbation 15-20%",
            category == "Disruption 10-15%" ~ "Perturbation 10-15%",
            category == "Disruption 7-10%" ~ "Perturbation 7-10%",
            category == "Disruption 5-7%" ~ "Perturbation 5-7%",
            category == "Disruption 3-5%" ~ "Perturbation 3-5%",
            category == "Stable" ~ "Stable",
            category == "Surplus 3-5%" ~ "Surplus 3-5%",
            category == "Surplus 5-7%" ~ "Surplus 5-7%",
            category == "Surplus 7-10%" ~ "Surplus 7-10%",
            category == "Surplus 10-15%" ~ "Surplus 10-15%",
            category == "Surplus 15-20%" ~ "Surplus 15-20%",
            category == "Surplus >20%" ~ "Surplus >20%",
            category == "Insufficient data" ~ "Données Insuffisantes",
            TRUE ~ as.character(category)
          )
        ) %>%
        mutate(category = factor(category, levels = c(
          "Perturbation >20%", "Perturbation 15-20%", "Perturbation 10-15%",
          "Perturbation 7-10%", "Perturbation 5-7%", "Perturbation 3-5%",
          "Stable",
          "Surplus 3-5%", "Surplus 5-7%", "Surplus 7-10%",
          "Surplus 10-15%", "Surplus 15-20%", "Surplus >20%",
          "Données Insuffisantes"
        )))
    }

    ggplot(data, aes(x = category, y = n, fill = category)) +
      geom_bar(stat = "identity") +
      scale_fill_manual(values = category_colors) +
      theme_minimal() +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "none",
        text = element_text(size = 12)
      ) +
      labs(
        x = "",
        y = tr()("axis_num_areas"),
        title = tr()("chart_distribution")
      )
  })

  # Category summary table
  output$category_summary_table <- renderDT({
    req(disruption_summary())

    # Add language as dependency to trigger re-render
    current_lang <- rv$lang

    # Translate category names if in French
    summary_data <- disruption_summary() %>%
      arrange(percent_change) %>%
      mutate(
        percent_change = round(percent_change, 1),
        total_actual = round(total_actual),
        total_expected = round(total_expected)
      )

    # Translate categories if French
    if (current_lang == "fr") {
      summary_data <- summary_data %>%
        mutate(
          category = case_when(
            category == "Disruption >20%" ~ "Perturbation >20%",
            category == "Disruption 15-20%" ~ "Perturbation 15-20%",
            category == "Disruption 10-15%" ~ "Perturbation 10-15%",
            category == "Disruption 7-10%" ~ "Perturbation 7-10%",
            category == "Disruption 5-7%" ~ "Perturbation 5-7%",
            category == "Disruption 3-5%" ~ "Perturbation 3-5%",
            category == "Stable" ~ "Stable",
            category == "Surplus 3-5%" ~ "Surplus 3-5%",
            category == "Surplus 5-7%" ~ "Surplus 5-7%",
            category == "Surplus 7-10%" ~ "Surplus 7-10%",
            category == "Surplus 10-15%" ~ "Surplus 10-15%",
            category == "Surplus 15-20%" ~ "Surplus 15-20%",
            category == "Surplus >20%" ~ "Surplus >20%",
            category == "Insufficient data" ~ "Données Insuffisantes",
            TRUE ~ as.character(category)
          )
        )
    }

    summary_data %>%
      select(
        !!tr()("col_admin_area") := admin_area,
        !!tr()("col_category") := category,
        !!tr()("col_actual_count") := total_actual,
        !!tr()("col_expected_count") := total_expected,
        !!tr()("col_pct_change") := percent_change
      ) %>%
      datatable(
        options = list(
          pageLength = 25,
          scrollX = TRUE,
          order = list(list(4, 'asc'))
        ),
        rownames = FALSE
      ) %>%
      formatStyle(
        tr()("col_category"),
        backgroundColor = styleEqual(
          if (current_lang == "fr") {
            c("Perturbation >20%", "Perturbation 15-20%", "Perturbation 10-15%",
              "Perturbation 7-10%", "Perturbation 5-7%", "Perturbation 3-5%",
              "Stable",
              "Surplus 3-5%", "Surplus 5-7%", "Surplus 7-10%",
              "Surplus 10-15%", "Surplus 15-20%", "Surplus >20%",
              "Données Insuffisantes")
          } else {
            all_categories
          },
          category_colors
        ),
        color = styleEqual(
          if (current_lang == "fr") {
            c("Perturbation >20%", "Perturbation 15-20%", "Perturbation 10-15%",
              "Perturbation 7-10%", "Perturbation 5-7%", "Perturbation 3-5%",
              "Stable",
              "Surplus 3-5%", "Surplus 5-7%", "Surplus 7-10%",
              "Surplus 10-15%", "Surplus 15-20%", "Surplus >20%",
              "Données Insuffisantes")
          } else {
            all_categories
          },
          c(rep("white", 6), "black", rep("white", 6), "white")
        )
      )
  })

  # Faceted map subtitle
  output$faceted_map_subtitle <- renderUI({
    window <- faceted_window()
    period_label <- window$label
    if (is.null(period_label)) {
      period_label <- as.character(input$year)
    }

    subtitle_text <- if (rv$lang == "fr") {
      paste("Comparaison multi-indicateurs -", period_label)
    } else {
      paste("Comparison across multiple indicators -", period_label)
    }

    tags$span(subtitle_text)
  })

  # Render faceted map plot
  output$faceted_map_plot <- renderPlot({
    req(rv$geo_data, rv$disruption_data, input$year)

    # Add language as dependency to trigger re-render
    current_lang <- rv$lang

    # Get selected indicators
    selected_indicators <- c(
      input$faceted_indicator1,
      input$faceted_indicator2,
      input$faceted_indicator3,
      input$faceted_indicator4
    )

    # Filter out NULL and empty values
    selected_indicators <- selected_indicators[!is.na(selected_indicators) & selected_indicators != ""]

    # Require at least one indicator
    req(length(selected_indicators) > 0)

    # Get filtered data from the faceted_window (includes ALL indicators)
    window <- faceted_window()
    filtered_data <- window$data

    validate(
      need(nrow(filtered_data) > 0, "No data available for the selected period.")
    )

    # Filter data for selected indicators only
    filtered_data <- filtered_data %>%
      filter(indicator_common_id %in% selected_indicators)

    # Get country name
    country_name <- tools::toTitleCase(gsub("([0-9])", " \\1", input$country))

    # Create faceted map
    create_faceted_map(
      geo_data = rv$geo_data,
      disruption_data = filtered_data,
      selected_indicators = selected_indicators,
      indicator_labels_df = current_indicator_labels(),
      year = input$year,
      period_label = window$label,
      country_name = country_name,
      admin_level = rv$data_admin_level,
      lang = rv$lang,
      show_labels = input$faceted_show_labels
    )
  })

  # Heatmap subtitle
  output$heatmap_subtitle <- renderUI({
    info <- heatmap_window()
    period_label <- info$label
    if (is.null(period_label)) {
      period_label <- as.character(input$year)
    }

    tags$span(paste("Last 6 months of data:", period_label))
  })

  # Heatmap plot
  output$heatmap_plot <- renderPlot({
    req(rv$disruption_data, input$year, rv$data_admin_level)
    info <- heatmap_window()

    # Calculate disruption for ALL indicators
    admin_col <- if(rv$data_admin_level == "3") "admin_area_3" else "admin_area_2"

    heatmap_data <- info$data

    validate(
      need(nrow(heatmap_data) > 0, "No data available for the last 6 months.")
    )

    heatmap_data <- heatmap_data %>%
      group_by(across(all_of(admin_col)), indicator_common_id) %>%
      summarise(
        total_actual = sum(count_sum, na.rm = TRUE),
        total_expected = sum(count_expect_sum, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      mutate(
        percent_change = (total_actual - total_expected) / total_expected * 100,
        category = calculate_heatmap_category(percent_change, total_expected)
      )

    names(heatmap_data)[1] <- "admin_area"

    # Join with indicator labels and use indicator_common_id as fallback
    heatmap_data <- heatmap_data %>%
      left_join(current_indicator_labels(), by = c("indicator_common_id" = "indicator_id")) %>%
      mutate(
        display_name = coalesce(indicator_name, indicator_common_id),
        category = factor(category, levels = heatmap_categories)
      )

    # Create heatmap
    ggplot(heatmap_data, aes(x = display_name, y = admin_area, fill = category)) +
      geom_tile(color = "white", size = 0.5) +
      scale_fill_manual(
        values = heatmap_colors,
        limits = heatmap_categories,
        name = "Service volumes vs expected",
        drop = FALSE
      ) +
      theme_minimal() +
      theme(
        axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
        axis.text.y = element_text(size = 10),
        axis.title = element_text(size = 12, face = "bold"),
        legend.position = "bottom",
        legend.title = element_text(size = 11, face = "bold"),
        legend.text = element_text(size = 10),
        panel.grid = element_blank(),
        plot.margin = margin(10, 10, 10, 50)
      ) +
      labs(
        x = "Health service indicator",
        y = "District",
        title = NULL
      ) +
      guides(fill = guide_legend(nrow = 1))
  })

  # Download heatmap as PNG
  output$download_heatmap <- downloadHandler(
    filename = function() {
      paste0(input$country, "_heatmap_", input$year, "_",
             format(Sys.Date(), "%Y%m%d"), ".png")
    },
    content = function(file) {
      showNotification("Generating heatmap image...", type = "message", duration = 3)

      info <- heatmap_window()
      heatmap_data <- info$data

      if (nrow(heatmap_data) == 0) {
        showNotification("No data available for the last 6 months.", type = "error", duration = 5)
        return(NULL)
      }

      # Calculate heatmap data
      admin_col <- if(rv$data_admin_level == "3") "admin_area_3" else "admin_area_2"

      heatmap_data <- heatmap_data %>%
        group_by(across(all_of(admin_col)), indicator_common_id) %>%
        summarise(
          total_actual = sum(count_sum, na.rm = TRUE),
          total_expected = sum(count_expect_sum, na.rm = TRUE),
          .groups = "drop"
        ) %>%
        mutate(
          percent_change = (total_actual - total_expected) / total_expected * 100,
          category = calculate_heatmap_category(percent_change, total_expected)
        )

      names(heatmap_data)[1] <- "admin_area"

      # Join with indicator labels and use indicator_common_id as fallback
      heatmap_data <- heatmap_data %>%
        left_join(current_indicator_labels(), by = c("indicator_common_id" = "indicator_id")) %>%
        mutate(
          display_name = coalesce(indicator_name, indicator_common_id),
          category = factor(category, levels = heatmap_categories)
        )

      period_label <- info$label
      if (is.null(period_label)) {
        period_label <- as.character(input$year)
      }

      # Create plot without legend
      p <- ggplot(heatmap_data, aes(x = display_name, y = admin_area, fill = category)) +
        geom_tile(color = "white", size = 0.5) +
        scale_fill_manual(
          values = heatmap_colors,
          limits = heatmap_categories,
          drop = FALSE
        ) +
        theme_minimal() +
        theme(
          axis.text.x = element_text(angle = 45, hjust = 1, size = 9),
          axis.text.y = element_text(size = 10),
          axis.title = element_text(size = 11, face = "bold"),
          legend.position = "none",
          panel.grid = element_blank(),
          plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
          plot.subtitle = element_text(size = 11, hjust = 0.5, margin = margin(b = 10)),
          plot.caption = element_text(size = 8, hjust = 0.5, color = "grey40", margin = margin(t = 10)),
          plot.margin = margin(15, 15, 15, 50)
        ) +
        labs(
          title = paste("Service disruptions by district and indicator -", period_label),
          subtitle = "Comparison of actual vs expected service volumes across health indicators",
          x = "Health service indicator",
          y = "District",
          caption = "Categories based on deviation from expected service volumes predicted by statistical model"
        )

      # Save
      ggsave(
        filename = file,
        plot = p,
        width = 16,
        height = 10,
        dpi = 300,
        bg = "white"
      )

      showNotification("Heatmap exported successfully!", type = "message", duration = 3)
    }
  )

  # Download faceted map as PNG
  output$download_faceted_map <- downloadHandler(
    filename = function() {
      paste0(
        input$country, "_",
        "multi_indicator_",
        input$year, "_",
        format(Sys.Date(), "%Y%m%d"),
        ".png"
      )
    },
    content = function(file) {
      showNotification("Generating multi-indicator map... This may take a few seconds.",
                      type = "message", duration = 3)

      # Get selected indicators
      selected_indicators <- c(
        input$faceted_indicator1,
        input$faceted_indicator2,
        input$faceted_indicator3,
        input$faceted_indicator4
      )

      # Filter out NULL and empty values
      selected_indicators <- selected_indicators[!is.na(selected_indicators) & selected_indicators != ""]

      if (length(selected_indicators) == 0) {
        showNotification("No indicators selected", type = "error", duration = 5)
        return(NULL)
      }

      # Get filtered data
      window <- faceted_window()
      filtered_data <- window$data %>%
        filter(indicator_common_id %in% selected_indicators)

      if (nrow(filtered_data) == 0) {
        showNotification("No data available for selected indicators", type = "error", duration = 5)
        return(NULL)
      }

      # Get country name
      country_name <- tools::toTitleCase(gsub("([0-9])", " \\1", input$country))

      # Create the plot
      tryCatch({
        p <- create_faceted_map(
          geo_data = rv$geo_data,
          disruption_data = filtered_data,
          selected_indicators = selected_indicators,
          indicator_labels_df = current_indicator_labels(),
          year = input$year,
          period_label = window$label,
          country_name = country_name,
          admin_level = rv$data_admin_level,
          lang = rv$lang,
          show_labels = input$faceted_show_labels
        )

        # Save the plot
        ggsave(
          filename = file,
          plot = p,
          width = 14,
          height = 12,
          dpi = 300,
          bg = "white"
        )

        showNotification("Multi-indicator map exported successfully!", type = "message", duration = 3)
      }, error = function(e) {
        showNotification(paste("Error exporting map:", e$message), type = "error", duration = 10)
      })
    }
  )

  # Download map as PNG
  output$download_map <- downloadHandler(
    filename = function() {
      indicator_name <- get_indicator_display_name(input$indicator)
      if (is.null(indicator_name) || indicator_name == "") {
        indicator_name <- input$indicator
      }
      indicator_safe <- gsub("[^A-Za-z0-9_-]", "_", indicator_name)
      if (is.na(indicator_safe) || indicator_safe == "") {
        indicator_safe <- gsub("[^A-Za-z0-9_-]", "_", input$indicator)
      }

      paste0(
        input$country, "_",
        indicator_safe, "_",
        input$year, "_",
        format(Sys.Date(), "%Y%m%d"),
        ".png"
      )
    },
    content = function(file) {
      # Show progress notification
      showNotification("Generating professional map image... This may take a few seconds.",
                      type = "message", duration = 3)

      # Get indicator name
      indicator_name <- get_indicator_display_name(input$indicator)
      if (is.null(indicator_name) || indicator_name == "") {
        indicator_name <- input$indicator
      }

      # Get country name
      country_name <- tools::toTitleCase(gsub("([0-9])", " \\1", input$country))

      # Use the disruption_window to get the period label
      window <- disruption_window()
      period_label <- window$label
      if (is.null(period_label)) {
        period_label <- as.character(input$year)
      }

      # Save as professional static PNG
      tryCatch({
        save_map_png(
          map_data = map_data(),
          filename = file,
          indicator_name = indicator_name,
          country_name = country_name,
          year = input$year,
          period_label = period_label,
          width = 12,
          height = 10
        )
        showNotification("Professional map exported successfully!", type = "message", duration = 3)
      }, error = function(e) {
        showNotification(paste("Error exporting map:", e$message), type = "error", duration = 10)
      })
    }
  )

  output$download_yoy_map <- downloadHandler(
    filename = function() {
      indicator_name <- get_indicator_display_name(input$yoy_indicator)
      if (is.null(indicator_name) || indicator_name == "") {
        indicator_name <- input$yoy_indicator
      }
      indicator_safe <- gsub("[^A-Za-z0-9_-]", "_", indicator_name)
      if (is.na(indicator_safe) || indicator_safe == "") {
        indicator_safe <- gsub("[^A-Za-z0-9_-]", "_", input$yoy_indicator)
      }
      volume_labels <- c(
        "count_final_none" = "not_adjusted",
        "count_final_outliers" = "adj_outliers",
        "count_final_completeness" = "adj_completeness",
        "count_final_both" = "adj_both"
      )
      volume_suffix <- volume_labels[[input$yoy_volume_metric]]
      if (is.null(volume_suffix) || is.na(volume_suffix)) {
        volume_suffix <- "volume"
      }

      paste0(
        input$yoy_country, "_",
        indicator_safe, "_",
        volume_suffix, "_yoy_",
        format(Sys.Date(), "%Y%m%d"),
        ".png"
      )
    },
    content = function(file) {
      showNotification(
        "Generating professional year-on-year map image... This may take a few seconds.",
        type = "message",
        duration = 3
      )

      indicator_name <- get_indicator_display_name(input$yoy_indicator)
      if (is.null(indicator_name) || indicator_name == "") {
        indicator_name <- input$yoy_indicator
      }

      volume_labels <- c(
        "count_final_none" = "Not adjusted",
        "count_final_outliers" = "Adjusted for outliers",
        "count_final_completeness" = "Adjusted for completeness",
        "count_final_both" = "Adjusted for completeness and outliers"
      )

      volume_label <- volume_labels[[input$yoy_volume_metric]]
      if (is.null(volume_label) || is.na(volume_label)) {
        volume_label <- "Volume"
      }

      indicator_title <- paste(indicator_name, "-", volume_label)
      country_name <- tools::toTitleCase(gsub("([0-9])", " \\1", input$yoy_country))
      info <- yoy_summary_info()

      period_label <- paste(info$current_period_label, "vs", info$previous_period_label)

      tryCatch({
        save_map_png(
          map_data = yoy_map_data(),
          filename = file,
          indicator_name = indicator_title,
          country_name = country_name,
          year = format(Sys.Date(), "%Y"),
          period_label = period_label,
          width = 12,
          height = 10,
          legend_title = "Percent change vs previous year",
          caption_text = paste(
            "Positive values = higher service utilization than the same months in the previous year; negative values = lower utilization.",
            "\nValues capped at ±50%. Areas with insufficient data display n/a."
          )
        )
        showNotification(
          "Professional year-on-year map exported successfully!",
          type = "message",
          duration = 3
        )
      }, error = function(e) {
        showNotification(paste("Error exporting year-on-year map:", e$message), type = "error", duration = 10)
      })
    }
  )
}

# Run the app
shinyApp(ui = ui, server = server)
