# ========================================
# MAP RENDERING FUNCTIONS
# ========================================

# Load GeoJSON boundaries
load_geojson_boundaries <- function(country_code, admin_level) {
  geojson_file <- file.path("data/geojson", paste0(country_code, "_backbone.geojson"))

  if (!file.exists(geojson_file)) {
    return(NULL)
  }

  geo <- st_read(geojson_file, quiet = TRUE)

  # Filter for selected admin level and make valid
  boundaries <- geo %>%
    filter(level == admin_level) %>%
    st_make_valid() %>%
    select(name, geometry)

  return(boundaries)
}

# Create continuous color palette (matching PNG scale -50 to +50)
# Gradient: DARK RED → RED → YELLOW → GREEN → DARK GREEN
# Uses all 13 colors from categorical palette for smooth transitions
create_continuous_palette <- function() {
  colorNumeric(
    palette = colorRampPalette(c(
      "#67001f", "#b2182b", "#d6604d", "#f4a582", "#fddbc7", "#fee5d9",  # 6 reds (dark→light)
      "#ffffcc",                                                          # 1 yellow (stable)
      "#e5f5e0", "#c7e9c0", "#a1d99b", "#74c476", "#41ab5d", "#006d2c"   # 6 greens (light→dark)
    ))(100),
    domain = c(-50, 50),
    na.color = "#999999"
  )
}

# Create categorical color palette
create_categorical_palette <- function() {
  colorFactor(
    palette = category_colors,
    domain = all_categories,
    na.color = "#999999"
  )
}

# Render disruption map
render_disruption_map <- function(map_data, color_scale = "continuous", show_labels = TRUE) {

  # Create color palette based on selection
  if (color_scale == "continuous") {
    pal <- create_continuous_palette()
    legend_title <- "% Change from Expected"
    # Cap values at -50 to +50 to match PNG scale
    fill_color <- ~pal(pmin(pmax(percent_change, -50), 50))
    fill_pattern <- NULL
  } else {
    pal <- create_categorical_palette()
    legend_title <- "Disruption Category"
    fill_color <- ~pal(category)
    # Use diagonal stripes for insufficient data
    fill_pattern <- ~ifelse(category == "Insufficient data", "stripe", NA)
  }

  # Create hover labels
  if (color_scale == "continuous") {
    labels <- sprintf(
      "<strong>%s</strong><br/>
      Change: <b>%s%%</b><br/>
      Actual: %s<br/>
      Expected: %s",
      map_data$name,
      round(map_data$percent_change, 1),
      format(round(map_data$total_actual), big.mark = ","),
      format(round(map_data$total_expected), big.mark = ",")
    ) %>% lapply(htmltools::HTML)
  } else {
    labels <- sprintf(
      "<strong>%s</strong><br/>
      Category: %s<br/>
      Change: %s%%<br/>
      Actual: %s<br/>
      Expected: %s",
      map_data$name,
      map_data$category,
      round(map_data$percent_change, 1),
      format(round(map_data$total_actual), big.mark = ","),
      format(round(map_data$total_expected), big.mark = ",")
    ) %>% lapply(htmltools::HTML)
  }

  # Create base map with modern basemap, scale and north arrow
  map <- leaflet(map_data, options = leafletOptions(zoomControl = TRUE)) %>%
    addProviderTiles(providers$Esri.WorldTopoMap)

  # Add stripe pattern for insufficient data (categorical mode only)
  if (!is.null(fill_pattern)) {
    map <- map %>%
      leaflet.extras2::addPatterns(
        patternId = "stripe",
        patternType = "stripe",
        stripeAngle = 45,
        stripeColor = "#666666",
        stripeWeight = 2,
        backgroundColor = "#cccccc"
      )
  }

  # Add polygons with optional pattern
  map <- map %>%
    addPolygons(
      fillColor = fill_color,
      fillPattern = fill_pattern,
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
    # Add scale bar
    addScaleBar(
      position = "bottomleft",
      options = scaleBarOptions(
        maxWidth = 100,
        metric = TRUE,
        imperial = FALSE,
        updateWhenIdle = TRUE
      )
    )

  # Add legend
  if (color_scale == "continuous") {
    map <- map %>%
      addLegend(
        position = "bottomright",
        pal = pal,
        values = ~pmin(pmax(percent_change, -50), 50),
        title = legend_title,
        opacity = 0.7,
        labFormat = labelFormat(suffix = "%")
      )
  } else {
    map <- map %>%
      addLegend(
        position = "bottomright",
        pal = pal,
        values = ~category,
        title = legend_title,
        opacity = 0.7
      )
  }

  # Add text labels on polygons if requested
  if (show_labels) {
    # Calculate centroids for label placement
    data_centroids <- suppressWarnings({
      map_data %>%
        st_centroid() %>%
        st_coordinates() %>%
        as.data.frame()
    })

    data_centroids$name <- map_data$name
    data_centroids$percent_change <- map_data$percent_change

    # Add district name labels
    map <- map %>%
      addLabelOnlyMarkers(
        data = data_centroids,
        lng = ~X,
        lat = ~Y,
        label = ~name,
        labelOptions = labelOptions(
          noHide = TRUE,
          direction = "center",
          textOnly = TRUE,
          style = list(
            "color" = "#333",
            "font-family" = "Arial, sans-serif",
            "font-size" = "10px",
            "font-weight" = "600",
            "text-shadow" = "1px 1px 2px white, -1px -1px 2px white, 1px -1px 2px white, -1px 1px 2px white, 0px 0px 3px white"
          )
        )
      ) %>%
      # Add percent change values below district names
      addLabelOnlyMarkers(
        data = data_centroids %>% mutate(Y = Y - 0.08),  # Nudge down slightly
        lng = ~X,
        lat = ~Y,
        label = ~paste0(ifelse(percent_change > 0, "+", ""), round(percent_change, 1), "%"),
        labelOptions = labelOptions(
          noHide = TRUE,
          direction = "center",
          textOnly = TRUE,
          style = list(
            "color" = "black",
            "font-family" = "Arial, sans-serif",
            "font-size" = "11px",
            "font-weight" = "bold",
            "text-shadow" = "1px 1px 3px white, -1px -1px 3px white, 1px -1px 3px white, -1px 1px 3px white, 0px 0px 4px white"
          )
        )
      )
  }

  # Add north arrow using custom HTML control
  north_arrow_html <- htmltools::tags$div(
    style = "position: absolute; top: 10px; right: 10px; z-index: 1000;",
    htmltools::tags$div(
      style = "background: white; padding: 10px; border-radius: 4px; box-shadow: 0 2px 4px rgba(0,0,0,0.2);",
      htmltools::HTML("
        <svg width='30' height='40' viewBox='0 0 30 40'>
          <polygon points='15,2 20,15 15,12 10,15' fill='black'/>
          <polygon points='15,12 20,15 15,38 10,15' fill='#999'/>
          <text x='15' y='35' text-anchor='middle' font-size='12' font-weight='bold'>N</text>
        </svg>
      ")
    )
  )

  map <- map %>%
    htmlwidgets::prependContent(north_arrow_html)

  return(map)
}

# Save map as static professional image
save_map_png <- function(map_data, filename,
                        indicator_name,
                        country_name,
                        year,
                        period_label = NULL,
                        color_scale = "continuous",
                        width = 12,
                        height = 10) {

  require(ggplot2)
  require(sf)
  require(ggspatial)

  # Prepare title and subtitle
  title_text <- indicator_name

  if (!is.null(period_label)) {
    subtitle_text <- period_label
  } else {
    subtitle_text <- paste("Admin area service volumes:", year)
  }

  # Create color palette
  if (color_scale == "continuous") {
    # Continuous gradient matching leaflet
    color_values <- c("#d7191c", "#fdae61", "#ffffbf", "#a6d96a", "#1a9641")

    # Create the map
    p <- ggplot(data = map_data) +
      geom_sf(aes(fill = pmin(pmax(percent_change, -50), 50)),
              color = "white", size = 0.3) +
      scale_fill_gradientn(
        colors = color_values,
        values = scales::rescale(c(-50, -10, 0, 10, 50)),
        limits = c(-50, 50),
        breaks = seq(-50, 50, 10),
        labels = function(x) paste0(ifelse(x > 0, "+", ""), x, "%"),
        name = "Percent change (actual vs expected)",
        guide = guide_colorbar(
          barwidth = 20,
          barheight = 0.8,
          title.position = "top",
          title.hjust = 0.5
        )
      ) +
      # Add district labels with values
      geom_sf_text(
        aes(label = paste0(round(percent_change, 0), "%")),
        size = 2.5,
        fontface = "bold",
        color = "black"
      ) +
      # Add district names
      geom_sf_text(
        aes(label = name),
        size = 2.2,
        nudge_y = -0.05,
        color = "black"
      )
  } else {
    # Categorical palette with diagonal stripes for insufficient data
    p <- ggplot(data = map_data) +
      ggpattern::geom_sf_pattern(
        aes(fill = category,
            pattern = ifelse(category == "Insufficient data", "stripe", "none"),
            pattern_angle = ifelse(category == "Insufficient data", 45, 0),
            pattern_density = ifelse(category == "Insufficient data", 0.1, 0),
            pattern_spacing = ifelse(category == "Insufficient data", 0.02, 0)),
        pattern_color = "#666666",
        pattern_fill = "#cccccc",
        color = "white",
        size = 0.3
      ) +
      scale_fill_manual(
        values = category_colors,
        name = "Disruption Category",
        drop = FALSE
      ) +
      # Add district labels
      geom_sf_text(
        aes(label = paste0(name, "\n(", round(percent_change, 0), "%)")),
        size = 2.5,
        fontface = "bold"
      )
  }

  # Add common elements
  p <- p +
    # North arrow
    annotation_north_arrow(
      location = "tr",
      which_north = "true",
      pad_x = unit(0.5, "cm"),
      pad_y = unit(0.5, "cm"),
      style = north_arrow_fancy_orienteering(
        fill = c("grey40", "white"),
        line_col = "grey20"
      )
    ) +
    # Scale bar
    annotation_scale(
      location = "bl",
      width_hint = 0.3,
      style = "ticks",
      line_width = 1,
      text_cex = 0.8
    ) +
    # Title and subtitle
    labs(
      title = title_text,
      subtitle = subtitle_text,
      caption = paste(
        "Red = disruption (below expected), Grey = stable, Green = surplus (above expected).",
        "\nValues capped at ±50%. Diagonal stripes = insufficient data."
      )
    ) +
    # Clean theme
    theme_void() +
    theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5, margin = margin(b = 5)),
      plot.subtitle = element_text(size = 12, hjust = 0.5, margin = margin(b = 15)),
      plot.caption = element_text(size = 8, hjust = 0.5, margin = margin(t = 10), color = "grey40"),
      legend.position = "bottom",
      legend.title = element_text(size = 10, face = "bold"),
      legend.text = element_text(size = 9),
      plot.margin = margin(20, 20, 20, 20)
    )

  # Save the plot
  ggsave(
    filename = filename,
    plot = p,
    width = width,
    height = height,
    dpi = 300,
    bg = "white"
  )

  return(filename)
}
