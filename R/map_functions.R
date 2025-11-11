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

# Render disruption map
render_disruption_map <- function(map_data, show_labels = TRUE) {

  # Create continuous color palette
  pal <- create_continuous_palette()
  legend_title <- "% Change from Expected"
  fill_color <- ~pal(pmin(pmax(percent_change, -50), 50))

  # Create hover labels
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

  # Create base map with modern basemap, scale and north arrow
  map <- leaflet(map_data, options = leafletOptions(zoomControl = TRUE)) %>%
    addProviderTiles(providers$Esri.WorldTopoMap) %>%
    addPolygons(
      fillColor = fill_color,
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
    ) %>%
    # Add legend
    addLegend(
      position = "bottomright",
      pal = pal,
      values = ~pmin(pmax(percent_change, -50), 50),
      title = legend_title,
      opacity = 0.7,
      labFormat = labelFormat(suffix = "%")
    )

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

render_yoy_map <- function(map_data, current_label, previous_label, show_labels = TRUE) {
  pal <- create_continuous_palette()
  legend_title <- "% Change vs Previous Year"

  current_label <- ifelse(is.null(current_label), "Current period", current_label)
  previous_label <- ifelse(is.null(previous_label), "Previous year", previous_label)

  percent_display <- ifelse(
    is.na(map_data$percent_change),
    "n/a",
    paste0(round(map_data$percent_change, 1), "%")
  )

  current_display <- ifelse(
    is.na(map_data$current_total),
    "n/a",
    format(round(map_data$current_total), big.mark = ",")
  )

  previous_display <- ifelse(
    is.na(map_data$previous_total),
    "n/a",
    format(round(map_data$previous_total), big.mark = ",")
  )

  absolute_display <- ifelse(
    is.na(map_data$absolute_change),
    "n/a",
    format(round(map_data$absolute_change), big.mark = ",")
  )

  labels <- sprintf(
    "<strong>%s</strong><br/>
    Change: <b>%s</b><br/>
    %s: %s<br/>
    %s: %s<br/>
    Absolute change: %s",
    map_data$name,
    percent_display,
    current_label,
    current_display,
    previous_label,
    previous_display,
    absolute_display
  ) %>% lapply(htmltools::HTML)

  map <- leaflet(map_data, options = leafletOptions(zoomControl = TRUE)) %>%
    addProviderTiles(providers$Esri.WorldTopoMap) %>%
    addPolygons(
      fillColor = ~pal(pmin(pmax(percent_change, -50), 50)),
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
    addScaleBar(
      position = "bottomleft",
      options = scaleBarOptions(
        maxWidth = 100,
        metric = TRUE,
        imperial = FALSE,
        updateWhenIdle = TRUE
      )
    ) %>%
    addLegend(
      position = "bottomright",
      pal = pal,
      values = ~pmin(pmax(percent_change, -50), 50),
      title = legend_title,
      opacity = 0.7,
      labFormat = labelFormat(suffix = "%")
    )

  if (show_labels) {
    data_centroids <- suppressWarnings({
      map_data %>%
        st_centroid() %>%
        st_coordinates() %>%
        as.data.frame()
    })

    data_centroids$name <- map_data$name
    data_centroids$label_value <- percent_display

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
      addLabelOnlyMarkers(
        data = data_centroids %>% mutate(Y = Y - 0.08),
        lng = ~X,
        lat = ~Y,
        label = ~label_value,
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

  map %>%
    htmlwidgets::prependContent(north_arrow_html)
}

# Save map as static professional image
save_map_png <- function(map_data, filename,
                        indicator_name,
                        country_name,
                        year,
                        period_label = NULL,
                        width = 12,
                        height = 10,
                        legend_title = "Percent change (actual vs expected)",
                        caption_text = paste(
                          "Red = disruption (below expected), Yellow = stable, Green = surplus (above expected).",
                          "\nValues capped at ±50%. Diagonal stripes = insufficient data."
                        )) {

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
      name = legend_title,
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
      caption = caption_text
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

# Create faceted map showing multiple indicators
create_faceted_map <- function(geo_data, disruption_data,
                               selected_indicators,
                               indicator_labels_df,
                               year = NULL,
                               period_label = NULL,
                               country_name = NULL,
                               admin_level = "2",
                               lang = "en") {

  require(ggplot2)
  require(sf)
  require(dplyr)
  require(tidyr)

  # Filter for selected indicators
  selected_indicators <- selected_indicators[!is.na(selected_indicators) & selected_indicators != ""]

  if (length(selected_indicators) == 0) {
    stop("No indicators selected")
  }

  # Determine admin column
  admin_col <- if(admin_level == "3") "admin_area_3" else "admin_area_2"

  # Calculate summary for all selected indicators
  summary_data <- disruption_data %>%
    filter(indicator_common_id %in% selected_indicators) %>%
    group_by(across(all_of(admin_col)), indicator_common_id) %>%
    summarise(
      total_actual = sum(count_sum, na.rm = TRUE),
      total_expected = sum(count_expect_sum, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    mutate(
      percent_change = (total_actual - total_expected) / total_expected * 100
    )

  names(summary_data)[1] <- "admin_area"

  # Join with indicator labels
  summary_data <- summary_data %>%
    left_join(indicator_labels_df, by = c("indicator_common_id" = "indicator_id")) %>%
    mutate(
      indicator_display = coalesce(indicator_name, indicator_common_id)
    )

  # Create map data by joining with geography for each indicator
  map_data_list <- lapply(selected_indicators, function(ind) {
    ind_summary <- summary_data %>% filter(indicator_common_id == ind)
    geo_data %>%
      left_join(ind_summary, by = c("name" = "admin_area")) %>%
      mutate(
        indicator_common_id = ind,
        indicator_display = unique(ind_summary$indicator_display)[1]
      )
  })

  # Combine all map data
  map_data_all <- do.call(rbind, map_data_list)

  # Ensure indicator_display is a factor with correct order
  map_data_all <- map_data_all %>%
    mutate(indicator_display = factor(indicator_display,
                                      levels = unique(indicator_display)))

  # Continuous gradient matching leaflet
  color_values <- c("#d7191c", "#fdae61", "#ffffbf", "#a6d96a", "#1a9641")

  # Determine optimal number of columns based on number of indicators
  n_indicators <- length(selected_indicators)
  ncols <- if (n_indicators == 1) 1 else if (n_indicators <= 2) 2 else 2

  # Translate legend title
  legend_title <- if (lang == "fr") "% Changement" else "% Change"

  # Create the faceted map
  p <- ggplot(data = map_data_all) +
    geom_sf(aes(fill = pmin(pmax(percent_change, -50), 50)),
            color = "white", size = 0.3) +
    scale_fill_gradientn(
      colors = color_values,
      values = scales::rescale(c(-50, -10, 0, 10, 50)),
      limits = c(-50, 50),
      breaks = seq(-50, 50, 25),
      labels = function(x) paste0(ifelse(x > 0, "+", ""), x, "%"),
      name = legend_title,
      guide = guide_colorbar(
        barwidth = 15,
        barheight = 0.8,
        title.position = "top",
        title.hjust = 0.5
      ),
      na.value = "#999999"
    ) +
    # Add percent values
    geom_sf_text(
      aes(label = ifelse(!is.na(percent_change),
                        paste0(round(percent_change, 0), "%"),
                        "n/a")),
      size = 2.5,
      fontface = "bold",
      color = "black"
    ) +
    # Facet by indicator with dynamic columns
    facet_wrap(~indicator_display, ncol = ncols) +
    # Clean theme
    theme_void() +
    theme(
      plot.title = element_text(size = 16, face = "bold", hjust = 0.5, margin = margin(b = 5)),
      plot.subtitle = element_text(size = 12, hjust = 0.5, margin = margin(b = 15)),
      plot.caption = element_text(size = 8, hjust = 0.5, margin = margin(t = 10), color = "grey40"),
      legend.position = "bottom",
      legend.title = element_text(size = 10, face = "bold"),
      legend.text = element_text(size = 9),
      strip.text = element_text(size = 11, face = "bold", margin = margin(5, 0, 5, 0)),
      strip.background = element_rect(fill = "#f0f0f0", color = NA),
      plot.margin = margin(15, 15, 15, 15)
    )

  # Add north arrow and scale bar (once for entire plot)
  p <- p +
    annotation_north_arrow(
      location = "tr",
      which_north = "true",
      pad_x = unit(0.5, "cm"),
      pad_y = unit(0.5, "cm"),
      height = unit(1, "cm"),
      width = unit(1, "cm"),
      style = north_arrow_fancy_orienteering(
        fill = c("grey40", "white"),
        line_col = "grey20"
      )
    ) +
    annotation_scale(
      location = "bl",
      width_hint = 0.2,
      style = "ticks",
      line_width = 1,
      text_cex = 0.8
    )

  # Translate text elements
  if (lang == "fr") {
    title_text <- if (!is.null(country_name)) {
      paste("Perturbations de Services -", country_name)
    } else {
      "Perturbations de Services"
    }
    caption_text <- "Rouge = perturbation (inférieur au prévu), Jaune = stable, Vert = surplus (supérieur au prévu). Valeurs limitées à ±50%."
    year_label <- "Année:"
  } else {
    title_text <- if (!is.null(country_name)) {
      paste("Service Disruption -", country_name)
    } else {
      "Service Disruption"
    }
    caption_text <- "Red = disruption (below expected), Yellow = stable, Green = surplus (above expected). Values capped at ±50%."
    year_label <- "Year:"
  }

  # Add title if provided
  if (!is.null(period_label) && !is.null(country_name)) {
    p <- p + labs(
      title = title_text,
      subtitle = period_label,
      caption = caption_text
    )
  } else if (!is.null(year)) {
    p <- p + labs(
      title = title_text,
      subtitle = paste(year_label, year),
      caption = caption_text
    )
  } else {
    p <- p + labs(
      title = title_text,
      caption = caption_text
    )
  }

  return(p)
}
