# ========================================
# UI COMPONENT FUNCTIONS
# ========================================

# Compatibility wrapper for shinydashboard menu items
dash_menu_item <- function(...) {
  if (exists("context_menuItem", asNamespace("shinydashboard"), inherits = FALSE)) {
    get("context_menuItem", asNamespace("shinydashboard"))(...)
  } else {
    shinydashboard::menuItem(...)
  }
}

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
      id = "app_tabs",
      selected = "map",
      dash_menu_item("Disruption Map", tabName = "map", icon = icon("map")),
      dash_menu_item("Multi-indicator Map", tabName = "faceted_map", icon = icon("th-large")),
      dash_menu_item("Heatmap", tabName = "heatmap", icon = icon("th")),
      dash_menu_item("Summary Statistics", tabName = "stats", icon = icon("chart-bar")),
      dash_menu_item("Year-on-year change", tabName = "yoy_map", icon = icon("chart-line")),
      dash_menu_item("About", tabName = "about", icon = icon("info-circle"))
    )
  )
}

# Create map tab
create_map_tab <- function(db_connected = FALSE) {
  tab <- tabItem(
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
            selectInput("period_window", "Time Period:",
                       choices = c("All months (full year)" = "all",
                                 "Last 6 months" = "6",
                                 "Last 3 months" = "3"),
                       selected = "all")
          ),
          column(9)
        ),

        fluidRow(
          column(4,
            selectInput("indicator", "Select Indicator:",
                       choices = NULL,
                       selected = NULL)
          ),
          column(4,
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

  # Ensure default tab is visible on initial load
  if (is.null(tab$attribs$class)) {
    tab$attribs$class <- "active"
  } else if (!grepl("\\bactive\\b", tab$attribs$class)) {
    tab$attribs$class <- paste(tab$attribs$class, "active")
  }
  tab
}

# Create faceted map tab
create_faceted_map_tab <- function() {
  tabItem(
    tabName = "faceted_map",
    fluidRow(
      box(
        title = "Multi-Indicator Selection",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        collapsed = FALSE,

        tags$div(
          style = "background: #f8f9fa; padding: 12px; border-left: 3px solid #3c8dbc; margin-bottom: 15px;",
          tags$p(
            style = "margin: 0; font-size: 12px; color: #555;",
            tags$b("Note: "),
            "Configure the Disruption Map tab first to load data. This view will display up to 4 indicators simultaneously in a faceted layout."
          )
        ),

        fluidRow(
          column(3,
            selectInput("faceted_indicator1", "Indicator 1:",
                       choices = NULL,
                       selected = NULL)
          ),
          column(3,
            selectInput("faceted_indicator2", "Indicator 2:",
                       choices = NULL,
                       selected = NULL)
          ),
          column(3,
            selectInput("faceted_indicator3", "Indicator 3:",
                       choices = NULL,
                       selected = NULL)
          ),
          column(3,
            selectInput("faceted_indicator4", "Indicator 4:",
                       choices = NULL,
                       selected = NULL)
          )
        )
      )
    ),

    fluidRow(
      box(
        title = "Multi-Indicator Comparison Map",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        fluidRow(
          column(8,
            tags$div(
              style = "background: #f4f6f9; padding: 12px 15px; border-radius: 4px; margin-bottom: 10px; border-left: 4px solid #00a65a;",
              tags$div(
                style = "font-size: 11px; color: #666; font-weight: 500; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px;",
                "Viewing Multiple Indicators"
              ),
              tags$div(
                style = "font-size: 14px; color: #333; font-weight: 600;",
                uiOutput("faceted_map_subtitle", inline = TRUE)
              )
            )
          ),
          column(4,
            checkboxInput("faceted_show_labels", "Show area names", value = FALSE,
                         width = "100%"),
            downloadButton("download_faceted_map", "Download as PNG",
                          class = "btn-primary pull-right",
                          style = "margin-bottom: 10px;")
          )
        ),
        plotOutput("faceted_map_plot", height = "900px")
      )
    )
  )
}

create_yoy_tab <- function() {
  tabItem(
    tabName = "yoy_map",
    fluidRow(
      box(
        title = "Data Selection",
        status = "primary",
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        collapsed = FALSE,
        fluidRow(
          column(
            3,
            selectInput(
              "yoy_country",
              "Select Country:",
              choices = NULL,
              selected = NULL
            )
          ),
          column(
            3,
            selectInput(
              "yoy_admin_level",
              "Geographic level:",
              choices = c(
                "Admin level 2 – State/Province" = "2",
                "Admin level 3 – District/LGA" = "3"
              ),
              selected = "2"
            )
          ),
          column(
            3,
            fileInput(
              "yoy_file",
              "Upload Adjusted CSV:",
              accept = c(".csv")
            ),
            helpText(
              tags$div(
                style = "margin-top: -10px; padding: 8px; background: #f8f9fa; border-left: 3px solid #3c8dbc; font-size: 11px;",
                tags$p(
                  style = "margin: 0 0 5px 0; font-weight: 600;",
                  "Where to find your CSV:"
                ),
                tags$ol(
                  style = "margin: 5px 0 5px 0; padding-left: 18px;",
                  tags$li("Go to your country instance"),
                  tags$li("Navigate to: ", tags$strong("modules > M2 Data quality adjustments > Files")),
                  tags$li(
                    "Download: ",
                    tags$code(style = "font-size: 10px;", "M2_adjusted_data_admin_area.csv")
                  )
                ),
                tags$p(
                  style = "margin: 5px 0 0 0; font-size: 10px; color: #666; font-style: italic;",
                  "Large files may take 10-30 seconds to process."
                )
              )
            )
          ),
          column(
            3,
            selectInput(
              "yoy_indicator",
              "Select Indicator:",
              choices = NULL,
              selected = NULL
            )
          )
        ),
        fluidRow(
          column(
            3,
            selectInput(
              "yoy_admin_column",
              "Match CSV column:",
              choices = NULL,
              selected = NULL
            )
          ),
          column(
            3,
            selectInput(
              "yoy_volume_metric",
              "Service utilization:",
              choices = c(
                "Not adjusted" = "count_final_none",
                "Adjusted for outliers" = "count_final_outliers",
                "Adjusted for completeness" = "count_final_completeness",
                "Adjusted for completeness and outliers" = "count_final_both"
              ),
              selected = "count_final_both"
            )
          ),
          column(
            3,
            checkboxInput(
              "yoy_show_labels",
              "Show Values on Map",
              value = TRUE
            )
          ),
          column(
            3,
            uiOutput("yoy_period_display")
          )
        )
      )
    ),
    fluidRow(
      box(
        title = "Year-on-year Change Map",
        status = "info",
        solidHeader = TRUE,
        width = 12,
        height = "750px",
        fluidRow(
          column(
            8,
            tags$div(
              style = "background: #f4f6f9; padding: 12px 15px; border-radius: 4px; margin-bottom: 10px; border-left: 4px solid #00a65a;",
              tags$div(
                style = "font-size: 11px; color: #666; font-weight: 500; text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 4px;",
                "Current Indicator"
              ),
              tags$div(
                style = "font-size: 16px; color: #333; font-weight: 600;",
                uiOutput("yoy_indicator_display", inline = TRUE)
              )
            )
          ),
          column(
            4,
            downloadButton(
              "download_yoy_map",
              "Download Map as PNG",
              class = "btn-primary pull-right",
              style = "margin-bottom: 10px; margin-top: 15px;"
            )
          )
        ),
        leafletOutput("yoy_map", height = "600px")
      )
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
            style = "font-size: 12px; color: #555; margin-top: 6px;",
            "Configure the Disruption Map first; the statistics below reuse the same indicator and filtered dataset."
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
            style = "font-size: 12px; color: #555; margin-top: 6px;",
            "Start on the Disruption Map tab; once data is loaded, revisit the Heatmap to view every indicator at once."
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
              tags$div(style = "width: 30px; height: 20px; background: #ffffcc; border: 1px solid #ccc;"),
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
              tags$div(style = "width: 30px; height: 20px; background: #f0f0f0; border: 1px solid #ccc;"),
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
        h4("Map Modes"),
        tags$ul(
          tags$li(tags$b("Disruption Map:"), " Compares actual counts to modelled expectations. Categories flag disruption, stability, or surplus relative to the expected baseline."),
          tags$li(tags$b("Year-on-year change:"), " Calculates percent change in service volumes between the latest six complete months and the equivalent months one year earlier. You can choose which adjusted volume to display (not adjusted, outliers removed, completeness adjusted, or both corrections).")
        ),

        h4("Color Scale"),
        p("Both maps use the same continuous gradient, capped at ±50% for readability:"),
        tags$ul(
          tags$li(tags$b("Deep red:"), " Large decrease in services (negative percent change)."),
          tags$li(tags$b("Yellow:"), " Stable performance (within ±3%)."),
          tags$li(tags$b("Deep green:"), " Large increase in services (positive percent change)."),
          tags$li(tags$b("Grey hatch / n/a:"), " Insufficient data for the selected period or a zero baseline.")
        ),
        p("Enable ", tags$b("Show Values on Map"), " to print the percent change directly on each area."),

        h4("Data Requirements"),
        p("Upload one of the supported CSV extracts:"),
        tags$ul(
          tags$li(tags$b("Disruption map:"), " `M3_disruption_analysis_admin_area_2.csv` or `_3.csv` with columns ", tags$code("admin_area_2"), ", ", tags$code("admin_area_3"), ", ", tags$code("indicator_common_id"), ", ", tags$code("period_id/year"), ", ", tags$code("count_sum"), ", ", tags$code("count_expect_sum"), " plus the pre-computed disruption metrics."),
          tags$li(tags$b("Year-on-year map:"), " `M2_adjusted_data_admin_area.csv` with the relevant `admin_area_*` columns, ", tags$code("indicator_common_id"), ", ", tags$code("period_id"), " and the four volume measures: ", tags$code("count_final_none"), ", ", tags$code("count_final_outliers"), ", ", tags$code("count_final_completeness"), ", ", tags$code("count_final_both"), ".")
        ),
        p("After upload, choose which geography column best matches the boundary file (for example `admin_area_2`, `admin_area_3`, or another admin field)."),

        h4("How to Use"),
        tags$ol(
          tags$li("Select a country and administrative level to load matching boundaries."),
          tags$li("Upload the corresponding CSV (or connect to the database where available)."),
          tags$li("Pick the indicator and, for the year-on-year tab, the service utilization measure and geography column."),
          tags$li("Use the map toggle to show or hide labels, hover for detailed tooltips, and pan/zoom as needed."),
          tags$li("Switch to the heatmap or statistics tabs for complementary summaries."),
          tags$li("Download any map or heatmap as a high-resolution PNG using the buttons provided.")
        )
      )
    )
  )
}
