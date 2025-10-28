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
source("R/data_functions.R")
source("R/map_functions.R")
source("R/translations.R")
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
      tags$script(src = "language.js")
    ),

    # All tabs from ui_components.R
    tabItems(
      create_map_tab(db_connected),
      create_heatmap_tab(),
      create_stats_tab(),
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

    # Show notification
    msg <- ifelse(rv$lang == "fr",
                  "Langue changée en français",
                  "Language changed to English")
    showNotification(msg, type = "message", duration = 2)
  })

  # Get current language translations
  tr <- reactive({
    lang <- rv$lang
    function(key) t(key, lang)
  })

  # Get current indicator labels based on language
  current_indicator_labels <- reactive({
    if (rv$lang == "fr") {
      indicator_labels_fr
    } else {
      indicator_labels
    }
  })

  # Initialize country choices
  observe({
    countries <- get_available_countries()
    updateSelectInput(session, "country",
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

    tryCatch({
      withProgress(message = 'Loading CSV file...', value = 0, {
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

        incProgress(0.4, detail = "Complete!")
      })

      level_name <- if(result$detected_level == "2") "Admin Level 2" else "Admin Level 3"
      showNotification(paste("Disruption data loaded successfully (", level_name, ")"), type = "message")

    }, error = function(e) {
      showNotification(paste("Error loading disruption data:", e$message), type = "error")
    })
  })

  # Calculate disruption summary for selected indicator
  disruption_summary <- reactive({
    req(rv$disruption_data, input$year, input$indicator, rv$data_admin_level)

    calculate_disruption_summary(
      data = rv$disruption_data,
      year_val = input$year,
      indicator_id = input$indicator,
      admin_level = rv$data_admin_level
    )
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
    req(map_data(), input$color_scale, input$show_labels)

    render_disruption_map(
      map_data = map_data(),
      color_scale = input$color_scale,
      show_labels = input$show_labels
    )
  })

  # Display current indicator name on map tab
  output$current_indicator_display <- renderUI({
    req(input$indicator)

    indicator_name <- current_indicator_labels() %>%
      filter(indicator_id == input$indicator) %>%
      pull(indicator_name) %>%
      head(1)

    if (length(indicator_name) > 0) {
      tags$span(indicator_name)
    } else {
      tags$span(style = "color: #999;", "No indicator selected")
    }
  })

  # Display current indicator name on stats tab
  output$current_indicator_display_stats <- renderUI({
    req(input$indicator)

    indicator_name <- current_indicator_labels() %>%
      filter(indicator_id == input$indicator) %>%
      pull(indicator_name) %>%
      head(1)

    if (length(indicator_name) > 0) {
      tags$span(indicator_name)
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

  # Heatmap subtitle
  output$heatmap_subtitle <- renderUI({
    req(input$year, rv$disruption_data)

    # Calculate time period from data
    year_data <- rv$disruption_data %>%
      filter(year == as.numeric(input$year))

    # Extract months from period_id if available
    if ("period_id" %in% names(year_data) && nrow(year_data) > 0) {
      year_data <- year_data %>%
        mutate(month = as.integer(substr(period_id, 5, 6)))

      min_month <- min(year_data$month, na.rm = TRUE)
      max_month <- max(year_data$month, na.rm = TRUE)

      month_names <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun",
                      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")

      if (min_month == 1 && max_month == 12) {
        period_label <- paste("Jan-Dec", input$year)
      } else {
        period_label <- paste0(month_names[min_month], "-",
                              month_names[max_month], " ", input$year)
      }
    } else {
      period_label <- as.character(input$year)
    }

    tags$span(paste("Comparison of actual vs expected service volumes -", period_label))
  })

  # Heatmap plot
  output$heatmap_plot <- renderPlot({
    req(rv$disruption_data, input$year, rv$data_admin_level)

    # Calculate disruption for ALL indicators
    admin_col <- if(rv$data_admin_level == "3") "admin_area_3" else "admin_area_2"

    heatmap_data <- rv$disruption_data %>%
      filter(year == as.numeric(input$year)) %>%
      group_by(across(all_of(admin_col)), indicator_common_id) %>%
      summarise(
        total_actual = sum(count_sum, na.rm = TRUE),
        total_expected = sum(count_expect_sum, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      mutate(
        percent_change = (total_actual - total_expected) / total_expected * 100,
        category = calculate_category(percent_change, total_expected)
      )

    names(heatmap_data)[1] <- "admin_area"

    # Join with indicator labels and use indicator_common_id as fallback
    heatmap_data <- heatmap_data %>%
      left_join(current_indicator_labels(), by = c("indicator_common_id" = "indicator_id")) %>%
      mutate(display_name = coalesce(indicator_name, indicator_common_id))

    # Create heatmap
    ggplot(heatmap_data, aes(x = display_name, y = admin_area, fill = category)) +
      geom_tile(color = "white", size = 0.5) +
      scale_fill_manual(
        values = category_colors,
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

      # Calculate heatmap data
      admin_col <- if(rv$data_admin_level == "3") "admin_area_3" else "admin_area_2"

      heatmap_data <- rv$disruption_data %>%
        filter(year == as.numeric(input$year)) %>%
        group_by(across(all_of(admin_col)), indicator_common_id) %>%
        summarise(
          total_actual = sum(count_sum, na.rm = TRUE),
          total_expected = sum(count_expect_sum, na.rm = TRUE),
          .groups = "drop"
        ) %>%
        mutate(
          percent_change = (total_actual - total_expected) / total_expected * 100,
          category = calculate_category(percent_change, total_expected)
        )

      names(heatmap_data)[1] <- "admin_area"

      # Join with indicator labels and use indicator_common_id as fallback
      heatmap_data <- heatmap_data %>%
        left_join(current_indicator_labels(), by = c("indicator_common_id" = "indicator_id")) %>%
        mutate(display_name = coalesce(indicator_name, indicator_common_id))

      # Create title with time period
      year_data <- rv$disruption_data %>%
        filter(year == as.numeric(input$year))

      if ("period_id" %in% names(year_data) && nrow(year_data) > 0) {
        year_data <- year_data %>%
          mutate(month = as.integer(substr(period_id, 5, 6)))

        min_month <- min(year_data$month, na.rm = TRUE)
        max_month <- max(year_data$month, na.rm = TRUE)
        month_names <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun",
                        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")

        if (min_month == 1 && max_month == 12) {
          period_label <- paste("Jan-Dec", input$year)
        } else {
          period_label <- paste0(month_names[min_month], "-",
                                month_names[max_month], " ", input$year)
        }
      } else {
        period_label <- as.character(input$year)
      }

      # Create plot
      p <- ggplot(heatmap_data, aes(x = display_name, y = admin_area, fill = category)) +
        geom_tile(color = "white", size = 0.5) +
        scale_fill_manual(
          values = category_colors,
          name = "Service volumes vs expected",
          drop = FALSE
        ) +
        theme_minimal() +
        theme(
          axis.text.x = element_text(angle = 45, hjust = 1, size = 9),
          axis.text.y = element_text(size = 10),
          axis.title = element_text(size = 11, face = "bold"),
          legend.position = "bottom",
          legend.title = element_text(size = 10, face = "bold"),
          legend.text = element_text(size = 9),
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
        ) +
        guides(fill = guide_legend(nrow = 1))

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

  # Download map as PNG
  output$download_map <- downloadHandler(
    filename = function() {
      indicator_name <- current_indicator_labels() %>%
        filter(indicator_id == input$indicator) %>%
        pull(indicator_name) %>%
        head(1)

      indicator_safe <- gsub("[^A-Za-z0-9_-]", "_", indicator_name)

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
      indicator_name <- current_indicator_labels() %>%
        filter(indicator_id == input$indicator) %>%
        pull(indicator_name) %>%
        head(1)

      # Get country name
      country_name <- tools::toTitleCase(gsub("([0-9])", " \\1", input$country))

      # Calculate time period from data
      year_data <- rv$disruption_data %>%
        filter(year == as.numeric(input$year),
               indicator_common_id == input$indicator)

      # Extract months from period_id if available
      if ("period_id" %in% names(year_data) && nrow(year_data) > 0) {
        # Extract month from period_id (format: YYYYMM)
        year_data <- year_data %>%
          mutate(month = as.integer(substr(period_id, 5, 6)))

        min_month <- min(year_data$month, na.rm = TRUE)
        max_month <- max(year_data$month, na.rm = TRUE)

        # Month names
        month_names <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun",
                        "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")

        # Create period label
        if (min_month == max_month) {
          period_label <- paste(month_names[min_month], input$year)
        } else if (min_month == 1 && max_month == 12) {
          period_label <- paste("Jan-Dec", input$year)
        } else {
          period_label <- paste0(month_names[min_month], "-",
                                month_names[max_month], " ", input$year)
        }
      } else {
        # Fallback if no period_id
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
          color_scale = input$color_scale,
          width = 12,
          height = 10
        )
        showNotification("Professional map exported successfully!", type = "message", duration = 3)
      }, error = function(e) {
        showNotification(paste("Error exporting map:", e$message), type = "error", duration = 10)
      })
    }
  )
}

# Run the app
shinyApp(ui = ui, server = server)
