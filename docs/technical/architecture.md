# Architecture

## Overview

The application is built with R Shiny and deployed as a Docker container on Hugging Face Spaces.

```
disruption_mapping/
├── app.R                 # Main Shiny application
├── R/                    # Modular R functions
│   ├── data_functions.R  # Data loading and processing
│   ├── map_functions.R   # Map rendering and export
│   ├── translations.R    # EN/FR translations
│   ├── indicators.R      # Indicator definitions
│   └── ui_components.R   # UI element definitions
├── data/
│   └── geojson/          # Country boundary files
├── www/                  # Static assets
├── Dockerfile            # Container definition
└── mkdocs.yml           # Documentation config
```

## Key Components

### Frontend (UI)

- **shinydashboard**: Dashboard layout
- **shinyWidgets**: Enhanced input widgets
- **leaflet**: Interactive maps
- **DT**: Data tables

### Backend (Server)

- **sf**: Spatial data handling
- **dplyr**: Data manipulation
- **ggplot2**: Static map generation
- **ggspatial**: Map annotations (scale bar, north arrow)
- **ggrepel**: Label positioning

### Data Flow

```
CSV Upload → Validation → Join with GeoJSON → Render Map → Export PNG
```

## Map Rendering

### Interactive Maps (Leaflet)

Used for real-time exploration in the browser.

### Static Maps (ggplot2)

Used for PNG export with:

- Professional styling
- Scale bar and north arrow
- High resolution (300 DPI)

## State Management

Reactive values (`rv`) store:

- `disruption_data`: Uploaded CSV data
- `geo_data`: Geographic boundaries
- `lang`: Current language (en/fr)
- `admin_level`: Selected admin level (2/3)

## Performance Considerations

- GeoJSON files are loaded once per country selection
- Data filtering uses dplyr for efficiency
- Large datasets may slow map rendering
