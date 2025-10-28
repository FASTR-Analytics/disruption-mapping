# ========================================
# UI COMPONENT FUNCTIONS
# ========================================

# Create dashboard header
create_app_header <- function() {
  dashboardHeader(
    title = "Disruption Mapping",
    tags$li(class = "dropdown",
            tags$style(HTML("
              .lang-toggle {
                margin: 10px 15px;
                padding: 5px 15px;
                background: #0f706d;
                color: white;
                border: none;
                border-radius: 4px;
                cursor: pointer;
                font-weight: 500;
              }
              .lang-toggle:hover {
                background: #1a8b86;
              }
            ")),
            actionButton("toggle_language", "FR",
                        class = "lang-toggle",
                        onclick = "")
    )
  )
}

# Create dashboard sidebar
create_app_sidebar <- function() {
  dashboardSidebar(
    sidebarMenu(
      menuItem("Disruption Map", tabName = "map", icon = icon("map")),
      menuItem("Heatmap", tabName = "heatmap", icon = icon("th")),
      menuItem("Summary Statistics", tabName = "stats", icon = icon("chart-bar")),
      menuItem("About", tabName = "about", icon = icon("info-circle"))
    )
  )
}

# Create map tab
create_map_tab <- function(db_connected = FALSE) {
  tabItem(
    tabName = "map",
    fluidRow(
      box(
        title = "Data Selection",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        collapsed = FALSE,

        # Data source selection
        conditionalPanel(
          condition = "true",  # Always show
          fluidRow(
            column(12,
              radioButtons("data_source", "Data Source:",
                          choices = if (db_connected) {
                            c("Database" = "database", "Upload File" = "upload")
                          } else {
                            c("Upload File" = "upload")
                          },
                          selected = if (db_connected) "database" else "upload",
                          inline = TRUE)
            )
          )
        ),

        fluidRow(
          column(3,
            selectInput("country", "Select Country:",
                       choices = NULL,
                       selected = NULL)
          ),
          column(3,
            selectInput("admin_level", "Administrative Level:",
                       choices = c("Level 2 (State/Province)" = "2",
                                 "Level 3 (District/LGA)" = "3"),
                       selected = "2")
          ),
          column(3,
            conditionalPanel(
              condition = "input.data_source == 'upload'",
              fileInput("disruption_file", "Upload Disruption CSV:",
                       accept = c(".csv")),
              helpText(
                tags$div(
                  style = "margin-top: -10px; padding: 8px; background: #f8f9fa; border-left: 3px solid #3c8dbc; font-size: 11px;",
                  tags$p(style = "margin: 0 0 5px 0; font-weight: 600;", "Where to find your CSV:"),
                  tags$ol(
                    style = "margin: 5px 0 5px 0; padding-left: 18px;",
                    tags$li("Go to your country instance"),
                    tags$li("Navigate to: ", tags$strong("modules > M3 Service utilization > Files")),
                    tags$li("Download: ", tags$code(style = "font-size: 10px;", "M3_disruption_analysis_admin_area_2.csv"), " or ", tags$code(style = "font-size: 10px;", "M3_disruption_analysis_admin_area_3.csv"))
                  ),
                  tags$p(style = "margin: 5px 0 0 0; font-size: 10px; color: #666; font-style: italic;",
                         "Large files may take 10-30 seconds to process.")
                )
              )
            )
          ),
          column(3,
            selectInput("year", "Select Year:",
                       choices = NULL,
                       selected = NULL)
          )
        ),

        fluidRow(
          column(3,
            selectInput("indicator", "Select Indicator:",
                       choices = NULL,
                       selected = NULL)
          ),
          column(3,
            selectInput("color_scale", "Color Scale:",
                       choices = c("Continuous" = "continuous",
                                 "Categories" = "categorical"),
                       selected = "continuous")
          ),
          column(3,
            checkboxInput("show_labels", "Show Values on Map", value = TRUE)
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
        height = "750px",
        fluidRow(
          column(8,
            tags$div(
              style = "background: #f4f6f9; padding: 12px 15px; border-radius: 4px; margin-bottom: 10px; border-left: 4px solid #00a65a;",
              tags$div(
                style = "font-size: 11px; color: #666; font-weight: 500; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px;",
                "Current Indicator"
              ),
              tags$div(
                style = "font-size: 16px; color: #333; font-weight: 600;",
                uiOutput("current_indicator_display", inline = TRUE)
              )
            )
          ),
          column(4,
            downloadButton("download_map", "Download Map as PNG",
                          class = "btn-primary pull-right",
                          style = "margin-bottom: 10px; margin-top: 15px;")
          )
        ),
        leafletOutput("map", height = "600px")
      )
    ),

    fluidRow(
      valueBoxOutput("total_districts", width = 3),
      valueBoxOutput("disrupted_count", width = 3),
      valueBoxOutput("stable_count", width = 3),
      valueBoxOutput("surplus_count", width = 3)
    )
  )
}

# Create statistics tab
create_stats_tab <- function() {
  tabItem(
    tabName = "stats",
    fluidRow(
      box(
        title = NULL,
        status = "info",
        solidHeader = FALSE,
        width = 12,
        tags$div(
          style = "background: #f4f6f9; padding: 12px 15px; border-radius: 4px; border-left: 4px solid #00a65a;",
          tags$div(
            style = "font-size: 11px; color: #666; font-weight: 500; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px;",
            "Current Indicator"
          ),
          tags$div(
            style = "font-size: 16px; color: #333; font-weight: 600;",
            uiOutput("current_indicator_display_stats", inline = TRUE)
          )
        )
      )
    ),
    fluidRow(
      box(
        title = "Disruption Categories Distribution",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        plotOutput("category_chart", height = "400px")
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
  )
}

# Create heatmap tab
create_heatmap_tab <- function() {
  tabItem(
    tabName = "heatmap",
    fluidRow(
      box(
        title = NULL,
        status = "info",
        solidHeader = FALSE,
        width = 12,
        tags$div(
          style = "background: #f4f6f9; padding: 12px 15px; border-radius: 4px; border-left: 4px solid #00a65a;",
          tags$div(
            style = "font-size: 11px; color: #666; font-weight: 500; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px;",
            "Service Disruptions by District and Indicator"
          ),
          tags$div(
            style = "font-size: 14px; color: #333; font-weight: 600;",
            uiOutput("heatmap_subtitle", inline = TRUE)
          )
        )
      )
    ),
    fluidRow(
      box(
        title = "Heatmap - All Indicators",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        fluidRow(
          column(12,
            downloadButton("download_heatmap", "Download Heatmap as PNG",
                          class = "btn-primary pull-right",
                          style = "margin-bottom: 10px;")
          )
        ),
        plotOutput("heatmap_plot", height = "800px")
      )
    ),
    fluidRow(
      box(
        title = "Legend",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        tags$div(
          style = "padding: 10px;",
          tags$p(style = "margin-bottom: 10px; font-weight: 600;", "Categories based on deviation from expected service volumes predicted by statistical model"),
          tags$div(
            style = "display: flex; gap: 20px; flex-wrap: wrap; align-items: center;",
            tags$div(
              style = "display: flex; align-items: center; gap: 8px;",
              tags$div(style = "width: 30px; height: 20px; background: #d7191c; border: 1px solid #ccc;"),
              tags$span("Disruption >10%")
            ),
            tags$div(
              style = "display: flex; align-items: center; gap: 8px;",
              tags$div(style = "width: 30px; height: 20px; background: #fdae61; border: 1px solid #ccc;"),
              tags$span("Disruption 5-10%")
            ),
            tags$div(
              style = "display: flex; align-items: center; gap: 8px;",
              tags$div(style = "width: 30px; height: 20px; background: #cccccc; border: 1px solid #ccc;"),
              tags$span("Stable")
            ),
            tags$div(
              style = "display: flex; align-items: center; gap: 8px;",
              tags$div(style = "width: 30px; height: 20px; background: #a6d96a; border: 1px solid #ccc;"),
              tags$span("Surplus 5-10%")
            ),
            tags$div(
              style = "display: flex; align-items: center; gap: 8px;",
              tags$div(style = "width: 30px; height: 20px; background: #1a9641; border: 1px solid #ccc;"),
              tags$span("Surplus >10%")
            ),
            tags$div(
              style = "display: flex; align-items: center; gap: 8px;",
              tags$div(style = "width: 30px; height: 20px; background: white; border: 1px solid #ccc;"),
              tags$span("Insufficient data")
            )
          )
        )
      )
    )
  )
}

# Create about tab
create_about_tab <- function() {
  tabItem(
    tabName = "about",
    fluidRow(
      box(
        title = "About This Tool",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        h4("Disruption Mapping"),
        p("This interactive tool visualizes disruptions in health service delivery by comparing
          actual service counts against expected values based on historical trends. All mapping
          is disaggregated by individual indicator."),

        h4("Color Scale Options"),
        tags$ul(
          tags$li(tags$b("Continuous:"), " Shows percent change on a smooth red-yellow-green gradient.
                  Red indicates disruption (negative), yellow is stable, green is surplus (positive)."),
          tags$li(tags$b("Categories:"), " Groups disruptions into discrete categories for easier interpretation."),
          tags$li(tags$b("Show Values on Map:"), " Displays the actual percent change value on each area for quick reference.")
        ),

        h4("Disruption Categories (when using categorical scale)"),
        tags$ul(
          tags$li(tags$b("Disruption >10%:"), " Actual services are 10% or more below expected"),
          tags$li(tags$b("Disruption 5-10%:"), " Actual services are 5-10% below expected"),
          tags$li(tags$b("Stable:"), " Actual services are within ±5% of expected"),
          tags$li(tags$b("Surplus 5-10%:"), " Actual services are 5-10% above expected"),
          tags$li(tags$b("Surplus >10%:"), " Actual services are 10% or more above expected"),
          tags$li(tags$b("Insufficient data:"), " Not enough data to calculate disruptions")
        ),

        h4("Data Requirements"),
        p("The disruption analysis CSV file should contain:"),
        tags$ul(
          tags$li(tags$code("admin_area_2"), " - Administrative area name (required for level 2)"),
          tags$li(tags$code("admin_area_3"), " - Administrative area name (required for level 3, in addition to admin_area_2)"),
          tags$li(tags$code("indicator_common_id"), " - Indicator identifier"),
          tags$li(tags$code("period_id"), " or ", tags$code("year"), " - Time period"),
          tags$li(tags$code("count_sum"), " - Actual count"),
          tags$li(tags$code("count_expect_sum"), " - Expected count based on historical trends")
        ),

        h4("How to Use"),
        tags$ol(
          tags$li("Select a country from the dropdown"),
          tags$li("Choose administrative level (2 for states/provinces, 3 for districts/LGAs)"),
          tags$li("Upload a disruption analysis CSV file or use database (if configured)"),
          tags$li("Select year and indicator to map"),
          tags$li("Choose color scale (continuous for precise values, categorical for quick overview)"),
          tags$li("Toggle 'Show Values on Map' to display percent change labels on areas"),
          tags$li("Explore the map (hover for details, zoom and pan) and statistics tabs")
        )
      )
    )
  )
}
