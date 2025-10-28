# ====================================================================
# DISRUPTION MAPPING SHINY APP
# Interactive visualization of health service disruptions
# ====================================================================

library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(dplyr)
library(sf)
library(leaflet)
library(tidyr)
library(DT)
library(ggplot2)

# Turn off spherical geometry
sf_use_s2(FALSE)

# Define indicator labels
indicator_labels <- data.frame(
  indicator_id = c("anc1", "anc1_hiv_positive", "anc1_hiv_tested", "anc1_hiv_tx",
                   "anc4", "bcg", "delivery", "fp_long", "fp_short",
                   "hiv_positive", "hiv_screened", "hiv_tb_screened", "hiv_tb_treated",
                   "hiv_tested", "hiv_treated",
                   "ipd", "malaria_positive", "malaria_tested", "malaria_tx",
                   "measles1", "measles2", "new_fp", "opd", "penta1", "penta3",
                   "pnc1_mother", "pnc1_newborn", "pnc_mother",
                   "w4a_red", "w4a_screened", "w4h_red", "w4h_screened"),
  indicator_name = c("Antenatal client 1st visit",
                     "Antenatal client tested positive for HIV on ANC first visit",
                     "Antenatal client tested for HIV on first ANC visit",
                     "Antenatal client HIV+ newly initiated on ART",
                     "Antenatal client 4th visit",
                     "BCG dose",
                     "Institutional delivery (normal, assisted, and csection)",
                     "Family planning methods- long acting",
                     "Family planning methods- short acting",
                     "Clients HIV+",
                     "HIV test conducted",
                     "Client HIV+ screened for TB",
                     "HIV-TB + patients started/continued ART",
                     "HIV tested through PICT",
                     "HIV clients given ART",
                     "Inpatient visit",
                     "Fever case tested positive for malaria (RDT and microscopy)",
                     "Fever case tested for malaria (RDT and microscopy)",
                     "Malaria treated with ACT",
                     "Measles vaccine 1",
                     "Measles vaccine 2",
                     "New family planning acceptors",
                     "Outpatient visit",
                     "Pentavalent 1st dose",
                     "Pentavalent 3rd dose",
                     "Postnatal care 1 (mothers)",
                     "Postnatal care 1 (newborns)",
                     "Postnatal care mother",
                     "Child identified as severely underweight (Weight for Age < -3)",
                     "Child screened for underweight (Weight for Age)",
                     "Child identified as severely wasted (Weight for Height <-3)",
                     "Child screened for wasting (Weight for Height)"),
  stringsAsFactors = FALSE
)

# Define all category levels
all_categories <- c("Disruption >10%", "Disruption 5-10%", "Stable",
                    "Surplus 5-10%", "Surplus >10%", "Insufficient data")

# Define color palette for disruption categories
category_colors <- c(
  "Disruption >10%" = "#d7191c",
  "Disruption 5-10%" = "#fdae61",
  "Stable" = "#ffffbf",
  "Surplus 5-10%" = "#a6d96a",
  "Surplus >10%" = "#1a9641",
  "Insufficient data" = "#999999"
)

# Get available countries from geojson files
get_available_countries <- function() {
  geojson_files <- list.files(pattern = "*_backbone.geojson", full.names = FALSE)
  countries <- gsub("_backbone.geojson", "", geojson_files)
  # Clean up country names for display
  country_names <- tools::toTitleCase(gsub("([0-9])", " \\1", countries))
  setNames(countries, country_names)
}

# ====================================================================
# UI
# ====================================================================

ui <- dashboardPage(
  skin = "blue",

  dashboardHeader(title = "Health Service Disruption Mapping"),

  dashboardSidebar(
    sidebarMenu(
      menuItem("Disruption Map", tabName = "map", icon = icon("map")),
      menuItem("Summary Statistics", tabName = "stats", icon = icon("chart-bar")),
      menuItem("Data Table", tabName = "data", icon = icon("table")),
      menuItem("About", tabName = "about", icon = icon("info-circle"))
    )
  ),

  dashboardBody(
    tags$head(
      tags$style(HTML("
        .box-title { font-weight: bold; }
        .info-box { min-height: 90px; }
        .small-box { min-height: 120px; }
      "))
    ),

    tabItems(
      # Map tab
      tabItem(
        tabName = "map",
        fluidRow(
          box(
            title = "Data Selection",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            collapsible = TRUE,

            fluidRow(
              column(3,
                selectInput("country", "Select Country:",
                           choices = NULL,  # Will be populated in server
                           selected = NULL)
              ),
              column(3,
                fileInput("disruption_file", "Upload Disruption CSV:",
                         accept = c(".csv"))
              ),
              column(3,
                selectInput("year", "Select Year:",
                           choices = NULL,
                           selected = NULL)
              ),
              column(3,
                selectInput("view_mode", "View Mode:",
                           choices = c("All Indicators" = "all",
                                     "By Indicator" = "indicator"),
                           selected = "all")
              )
            ),

            conditionalPanel(
              condition = "input.view_mode == 'indicator'",
              fluidRow(
                column(6,
                  selectInput("indicator", "Select Indicator:",
                             choices = NULL,
                             selected = NULL)
                )
              )
            )
          )
        ),

        fluidRow(
          box(
            title = "Disruption Map",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            height = "700px",
            leafletOutput("map", height = "650px")
          )
        ),

        fluidRow(
          valueBoxOutput("total_districts", width = 3),
          valueBoxOutput("disrupted_count", width = 3),
          valueBoxOutput("stable_count", width = 3),
          valueBoxOutput("surplus_count", width = 3)
        )
      ),

      # Statistics tab
      tabItem(
        tabName = "stats",
        fluidRow(
          box(
            title = "Disruption Categories Distribution",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            plotOutput("category_chart", height = "400px")
          ),
          box(
            title = "Top 10 Most Disrupted Areas",
            status = "danger",
            solidHeader = TRUE,
            width = 6,
            plotOutput("top_disrupted_chart", height = "400px")
          )
        ),
        fluidRow(
          box(
            title = "Category Summary by Administrative Area",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            DTOutput("category_summary_table")
          )
        )
      ),

      # Data tab
      tabItem(
        tabName = "data",
        fluidRow(
          box(
            title = "Disruption Data Details",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            DTOutput("data_table")
          )
        )
      ),

      # About tab
      tabItem(
        tabName = "about",
        fluidRow(
          box(
            title = "About This Tool",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            h4("Health Service Disruption Mapping"),
            p("This interactive tool visualizes disruptions in health service delivery by comparing
              actual service counts against expected values based on historical trends."),

            h4("Disruption Categories"),
            tags$ul(
              tags$li(tags$b("Disruption >10%:"), " Actual services are 10% or more below expected"),
              tags$li(tags$b("Disruption 5-10%:"), " Actual services are 5-10% below expected"),
              tags$li(tags$b("Stable:"), " Actual services are within 5% of expected"),
              tags$li(tags$b("Surplus 5-10%:"), " Actual services are 5-10% above expected"),
              tags$li(tags$b("Surplus >10%:"), " Actual services are 10% or more above expected"),
              tags$li(tags$b("Insufficient data:"), " Not enough data to calculate disruptions")
            ),

            h4("Data Requirements"),
            p("The disruption analysis CSV file should contain the following columns:"),
            tags$ul(
              tags$li(tags$code("admin_area_2"), " - Administrative area name"),
              tags$li(tags$code("indicator_common_id"), " - Indicator identifier"),
              tags$li(tags$code("year"), " - Year of observation"),
              tags$li(tags$code("count_sum"), " - Actual count"),
              tags$li(tags$code("count_expect_sum"), " - Expected count based on historical trends")
            ),

            h4("How to Use"),
            tags$ol(
              tags$li("Select a country from the dropdown"),
              tags$li("Upload a disruption analysis CSV file"),
              tags$li("Choose a year and view mode (all indicators or specific indicator)"),
              tags$li("Explore the map and statistics tabs")
            )
          )
        )
      )
    )
  )
)

# ====================================================================
# SERVER
# ====================================================================

server <- function(input, output, session) {

  # Reactive values
  rv <- reactiveValues(
    geo_data = NULL,
    disruption_data = NULL,
    map_data = NULL
  )

  # Initialize country choices
  observe({
    countries <- get_available_countries()
    updateSelectInput(session, "country",
                     choices = countries,
                     selected = if(length(countries) > 0) countries[1] else NULL)
  })

  # Load GeoJSON when country changes
  observeEvent(input$country, {
    req(input$country)

    geojson_file <- paste0(input$country, "_backbone.geojson")

    if (file.exists(geojson_file)) {
      tryCatch({
        geo <- st_read(geojson_file, quiet = TRUE)
        # Filter for level 2 (districts/admin_area_2)
        rv$geo_data <- geo %>%
          filter(level == 2) %>%
          st_make_valid() %>%
          select(name, geometry)

        showNotification(paste("Loaded boundaries for", tools::toTitleCase(input$country)),
                        type = "message")
      }, error = function(e) {
        showNotification(paste("Error loading GeoJSON:", e$message), type = "error")
      })
    }
  })

  # Load disruption data from uploaded file
  observeEvent(input$disruption_file, {
    req(input$disruption_file)

    tryCatch({
      rv$disruption_data <- read.csv(input$disruption_file$datapath, stringsAsFactors = FALSE)

      # Validate required columns
      required_cols <- c("admin_area_2", "indicator_common_id", "year",
                        "count_sum", "count_expect_sum")

      if (!all(required_cols %in% names(rv$disruption_data))) {
        missing <- setdiff(required_cols, names(rv$disruption_data))
        showNotification(paste("Missing required columns:", paste(missing, collapse = ", ")),
                        type = "error")
        rv$disruption_data <- NULL
        return()
      }

      # Update year choices
      years <- sort(unique(rv$disruption_data$year))
      updateSelectInput(session, "year",
                       choices = years,
                       selected = max(years))

      # Update indicator choices
      indicators <- rv$disruption_data %>%
        distinct(indicator_common_id) %>%
        left_join(indicator_labels, by = c("indicator_common_id" = "indicator_id")) %>%
        arrange(indicator_name)

      indicator_choices <- setNames(indicators$indicator_common_id,
                                   ifelse(is.na(indicators$indicator_name),
                                         indicators$indicator_common_id,
                                         indicators$indicator_name))

      updateSelectInput(session, "indicator",
                       choices = indicator_choices,
                       selected = indicator_choices[1])

      showNotification("Disruption data loaded successfully", type = "message")

    }, error = function(e) {
      showNotification(paste("Error loading disruption data:", e$message), type = "error")
    })
  })

  # Calculate disruption summary
  disruption_summary <- reactive({
    req(rv$disruption_data, input$year, input$view_mode)

    year_data <- rv$disruption_data %>%
      filter(year == as.numeric(input$year))

    if (input$view_mode == "all") {
      # Overall summary (all indicators)
      summary <- year_data %>%
        group_by(admin_area_2) %>%
        summarise(
          total_actual = sum(count_sum, na.rm = TRUE),
          total_expected = sum(count_expect_sum, na.rm = TRUE),
          .groups = "drop"
        )
    } else {
      # By indicator summary
      req(input$indicator)
      summary <- year_data %>%
        filter(indicator_common_id == input$indicator) %>%
        group_by(admin_area_2) %>%
        summarise(
          total_actual = sum(count_sum, na.rm = TRUE),
          total_expected = sum(count_expect_sum, na.rm = TRUE),
          .groups = "drop"
        )
    }

    # Calculate percent change and category
    summary <- summary %>%
      mutate(
        percent_change = (total_actual - total_expected) / total_expected * 100,
        category = case_when(
          total_expected == 0 | is.na(total_expected) | is.infinite(percent_change) ~ "Insufficient data",
          percent_change >= 10 ~ "Surplus >10%",
          percent_change >= 5 & percent_change < 10 ~ "Surplus 5-10%",
          percent_change > -5 & percent_change < 5 ~ "Stable",
          percent_change > -10 & percent_change <= -5 ~ "Disruption 5-10%",
          percent_change <= -10 ~ "Disruption >10%",
          TRUE ~ "Stable"
        )
      ) %>%
      mutate(category = factor(category, levels = all_categories))

    return(summary)
  })

  # Create map data by joining geo and disruption data
  map_data <- reactive({
    req(rv$geo_data, disruption_summary())

    map_data <- rv$geo_data %>%
      left_join(disruption_summary(), by = c("name" = "admin_area_2"))

    rv$map_data <- map_data
    return(map_data)
  })

  # Render map
  output$map <- renderLeaflet({
    req(map_data())

    data <- map_data()

    # Create color palette
    pal <- colorFactor(
      palette = category_colors,
      domain = all_categories,
      na.color = "#999999"
    )

    # Create labels
    labels <- sprintf(
      "<strong>%s</strong><br/>
      Category: %s<br/>
      Actual: %s<br/>
      Expected: %s<br/>
      Change: %s%%",
      data$name,
      data$category,
      format(round(data$total_actual), big.mark = ","),
      format(round(data$total_expected), big.mark = ","),
      round(data$percent_change, 1)
    ) %>% lapply(htmltools::HTML)

    # Create map
    leaflet(data) %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      addPolygons(
        fillColor = ~pal(category),
        weight = 1,
        opacity = 1,
        color = "white",
        dashArray = "3",
        fillOpacity = 0.7,
        highlightOptions = highlightOptions(
          weight = 3,
          color = "#666",
          dashArray = "",
          fillOpacity = 0.8,
          bringToFront = TRUE
        ),
        label = labels,
        labelOptions = labelOptions(
          style = list("font-weight" = "normal", padding = "3px 8px"),
          textsize = "12px",
          direction = "auto"
        )
      ) %>%
      addLegend(
        position = "bottomright",
        pal = pal,
        values = ~category,
        title = "Disruption Category",
        opacity = 0.7
      )
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

    data <- disruption_summary() %>%
      count(category) %>%
      mutate(category = factor(category, levels = all_categories))

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
        y = "Number of Areas",
        title = "Distribution of Areas by Disruption Category"
      )
  })

  # Top disrupted chart
  output$top_disrupted_chart <- renderPlot({
    req(disruption_summary())

    data <- disruption_summary() %>%
      arrange(percent_change) %>%
      head(10) %>%
      mutate(admin_area_2 = factor(admin_area_2, levels = admin_area_2))

    ggplot(data, aes(x = admin_area_2, y = percent_change, fill = percent_change)) +
      geom_bar(stat = "identity") +
      scale_fill_gradient2(low = "#d7191c", mid = "#ffffbf", high = "#1a9641",
                          midpoint = 0) +
      coord_flip() +
      theme_minimal() +
      theme(
        legend.position = "none",
        text = element_text(size = 12)
      ) +
      labs(
        x = "",
        y = "Percent Change from Expected",
        title = "Top 10 Areas with Highest Disruption"
      )
  })

  # Category summary table
  output$category_summary_table <- renderDT({
    req(disruption_summary())

    disruption_summary() %>%
      arrange(percent_change) %>%
      mutate(
        percent_change = round(percent_change, 1),
        total_actual = round(total_actual),
        total_expected = round(total_expected)
      ) %>%
      select(
        `Administrative Area` = admin_area_2,
        Category = category,
        `Actual Count` = total_actual,
        `Expected Count` = total_expected,
        `% Change` = percent_change
      ) %>%
      datatable(
        options = list(
          pageLength = 25,
          scrollX = TRUE,
          order = list(list(4, 'asc'))  # Sort by % Change
        ),
        rownames = FALSE
      ) %>%
      formatStyle(
        'Category',
        backgroundColor = styleEqual(
          all_categories,
          category_colors
        ),
        color = styleEqual(
          all_categories,
          c(rep("white", 2), "black", rep("white", 2), "white")
        )
      )
  })

  # Data table
  output$data_table <- renderDT({
    req(rv$disruption_data, input$year)

    data <- rv$disruption_data %>%
      filter(year == as.numeric(input$year))

    if (input$view_mode == "indicator") {
      req(input$indicator)
      data <- data %>%
        filter(indicator_common_id == input$indicator)
    }

    data %>%
      left_join(indicator_labels, by = c("indicator_common_id" = "indicator_id")) %>%
      mutate(
        percent_change = round((count_sum - count_expect_sum) / count_expect_sum * 100, 1)
      ) %>%
      select(
        Area = admin_area_2,
        Indicator = indicator_name,
        Period = period_id,
        Year = year,
        Actual = count_sum,
        Expected = count_expect_sum,
        `% Change` = percent_change
      ) %>%
      datatable(
        options = list(
          pageLength = 25,
          scrollX = TRUE
        ),
        rownames = FALSE,
        filter = "top"
      )
  })
}

# Run the app
shinyApp(ui = ui, server = server)
