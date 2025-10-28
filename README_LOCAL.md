# Health Service Disruption Mapping - Shiny App

An interactive Shiny application for visualizing health service disruptions across administrative areas, comparing actual service counts against expected values. Built with FASTR branding and clean modular architecture.

## Features

- **Interactive Map**: Visualize disruptions on an interactive map with color-coded administrative areas
- **Heatmap View**: Multi-indicator overview showing all services across districts at once
- **Professional Exports**: Publication-ready PNG maps (300 DPI) with north arrow and scale bar
- **Multiple Countries**: Support for 17 countries via GeoJSON boundary files
- **Multi-Level Admin**: Support for both admin level 2 (states/provinces) and level 3 (districts/LGAs)
- **44 Indicators**: Comprehensive coverage of maternal health, child health, malaria, HIV, nutrition, and more
- **Bilingual**: Full French/English language support with toggle button
- **Dual Data Sources**: Upload CSV files (up to 2GB) or connect to PostgreSQL database
- **Color Scale Options**: Continuous gradient or categorical disruption categories
- **Dynamic Time Periods**: Automatically detects and displays actual data time range
- **Summary Statistics**: Interactive charts and tables showing disruption patterns
- **FASTR Theme**: Clean teal-branded UI with custom CSS
- **Deployment Ready**: Includes Dockerfile for Hugging Face Spaces

## 📚 Documentation

Comprehensive documentation is available in the **[documentation/](documentation/)** folder:

- **[INDEX.md](documentation/INDEX.md)** - Complete documentation index
- **[QUICK_START.md](documentation/QUICK_START.md)** - Getting started guide
- **[PROFESSIONAL_MAP_EXPORT.md](documentation/PROFESSIONAL_MAP_EXPORT.md)** - Publication-ready map exports
- **[HEATMAP_FEATURE.md](documentation/HEATMAP_FEATURE.md)** - Multi-indicator heatmap overview
- **[FRENCH_TRANSLATION_GUIDE.md](documentation/FRENCH_TRANSLATION_GUIDE.md)** - Bilingual support
- **[LEAFLET_MAP_IMPROVEMENTS.md](documentation/LEAFLET_MAP_IMPROVEMENTS.md)** - Interactive map features
- **[UI_IMPROVEMENTS.md](documentation/UI_IMPROVEMENTS.md)** - User interface enhancements
- **[DYNAMIC_TIME_PERIOD.md](documentation/DYNAMIC_TIME_PERIOD.md)** - Time period detection
- **[COLOR_PALETTE_UPDATE.md](documentation/COLOR_PALETTE_UPDATE.md)** - Visual styling

👉 **Start with [documentation/INDEX.md](documentation/INDEX.md)** for a complete overview.

## Installation

### Required R Packages

Install the required packages by running:

```r
install.packages(c(
  "shiny",
  "shinydashboard",
  "shinyWidgets",
  "dplyr",
  "sf",
  "leaflet",
  "tidyr",
  "DT",
  "ggplot2"
))
```

## File Structure

```
disruption_mapping/
├── app.R                           # Main Shiny application (clean, modular)
├── launch_app.R                    # Quick launch script
├── README.md                       # This file
├── .env                           # Environment configuration
├── Dockerfile                     # Docker configuration for deployment
├── .dockerignore                  # Docker ignore file
├── R/                             # Modular R code
│   ├── indicators.R               # Indicator definitions and categories
│   ├── translations.R             # French/English translations
│   ├── data_functions.R           # Data loading and processing
│   ├── map_functions.R            # Map rendering functions
│   └── ui_components.R            # UI component functions
├── www/                           # Web assets
│   ├── custom.css                 # FASTR teal theme CSS
│   └── language.js                # Language switching JavaScript
├── data/                          # Data files
│   └── geojson/                   # Country boundary files
│       ├── bangladesh1_backbone.geojson
│       ├── nigeria_backbone.geojson
│       └── ... (17 countries total)
├── documentation/                 # 📚 Complete documentation
│   ├── INDEX.md                   # Documentation index
│   ├── QUICK_START.md             # Getting started guide
│   ├── PROFESSIONAL_MAP_EXPORT.md # Map export guide
│   ├── HEATMAP_FEATURE.md         # Heatmap overview
│   ├── FRENCH_TRANSLATION_GUIDE.md# Bilingual support
│   ├── LEAFLET_MAP_IMPROVEMENTS.md# Interactive map features
│   ├── UI_IMPROVEMENTS.md         # UI enhancements
│   ├── DYNAMIC_TIME_PERIOD.md     # Time period detection
│   └── COLOR_PALETTE_UPDATE.md    # Visual styling
└── archive/                       # Archived files
    ├── database_setup.sql
    ├── import_data_to_db.R
    └── install_postgresql.sh
```

## Data Requirements

### GeoJSON Files

GeoJSON files should contain:
- `name` field: Administrative area name
- `level` field: Administrative level (2 for districts/admin_area_2)
- `geometry` field: Polygon geometries

### Disruption CSV Files

CSV files must contain the following columns:

| Column Name | Description | Type |
|------------|-------------|------|
| `admin_area_2` | Administrative area name (must match GeoJSON `name` field) | String |
| `indicator_common_id` | Health indicator identifier | String |
| `year` | Year of observation | Integer |
| `period_id` | Period identifier (e.g., 201901 for Jan 2019) | Integer |
| `count_sum` | Actual count of services delivered | Numeric |
| `count_expect_sum` | Expected count based on historical trends | Numeric |

Optional columns:
- `quarter_id`: Quarter identifier
- `count_expected_if_above_diff_threshold`: Alternative expected count

### Supported Indicators

The app recognizes these health indicators:

- **Maternal Health**: anc1, anc4, delivery, pnc1_mother, pnc1_newborn, pnc_mother
- **Child Health**: bcg, penta1, penta3, measles1, measles2
- **Nutrition**: w4a_red, w4a_screened, w4h_red, w4h_screened
- **HIV/AIDS**: anc1_hiv_positive, anc1_hiv_tested, anc1_hiv_tx, hiv_positive, hiv_screened, hiv_tb_screened, hiv_tb_treated, hiv_tested, hiv_treated
- **Malaria**: malaria_positive, malaria_tested, malaria_tx
- **Family Planning**: fp_long, fp_short, new_fp
- **General Services**: opd, ipd

## Running the App

### Quick Launch (Recommended)

```r
# From the app directory
source("launch_app.R")
```

### From RStudio

1. Open `app.R` in RStudio
2. Click the "Run App" button

### From R Console

```r
# Set working directory to the app folder
setwd("/Users/claireboulange/Desktop/modules/disruption_mapping")

# Run the app
shiny::runApp()
```

### Using Docker

```bash
# Build the Docker image
docker build -t disruption-mapping .

# Run the container
docker run -p 3838:3838 disruption-mapping

# Access at http://localhost:3838
```

### Deploy to Hugging Face Spaces

1. Create a new Space on Hugging Face
2. Select "Docker" as the SDK
3. Push this repository to the Space
4. The app will automatically deploy using the Dockerfile

## How to Use

### 1. Select Country

- Choose a country from the dropdown menu
- The app will automatically load the corresponding GeoJSON boundaries
- Only admin level 2 (districts) will be displayed

### 2. Upload Disruption Data

- Click "Browse" to upload a CSV file with disruption analysis
- The file should be in the format described above
- The app will validate required columns

### 3. Select Parameters

- **Year**: Choose which year to analyze
- **Indicator**: Select a specific health indicator to map (all mapping is disaggregated by indicator)
- **Color Scale**: Choose between continuous gradient or categorical view
- **Show Values on Map**: Toggle to display percent change values on map polygons

### 4. Explore the Map

- Hover over areas to see details
- Click on areas for more information
- Use the legend to understand disruption categories

### 5. View Statistics

Navigate to the "Summary Statistics" tab to see:
- Bar chart of areas by disruption category
- Top 10 most disrupted areas
- Detailed summary table

### 6. Export Data

Use the "Data Table" tab to:
- View detailed data
- Filter by columns
- Export to CSV/Excel

## Disruption Categories

The app classifies areas into six categories:

| Category | Criteria | Color |
|----------|----------|-------|
| Disruption >10% | Actual is 10%+ below expected | Dark Red |
| Disruption 5-10% | Actual is 5-10% below expected | Orange |
| Stable | Actual is within ±5% of expected | Yellow |
| Surplus 5-10% | Actual is 5-10% above expected | Light Green |
| Surplus >10% | Actual is 10%+ above expected | Dark Green |
| Insufficient data | Not enough data to calculate | Gray |

## Example Workflow

### Sierra Leone Example

1. Start the app
2. Select "Sierraleone" from the country dropdown
3. Upload `/Users/claireboulange/Desktop/FASTR/Request/Sierra_Leone/M3_disruptions_analysis_admin_area_2.csv`
4. Select year "2024"
5. Choose "All Indicators" view mode
6. Explore the interactive map showing disruption patterns across districts

### Nigeria Example

1. Select "Nigeria" from the country dropdown
2. Upload your Nigeria disruption analysis CSV
3. Select desired year and indicator
4. View maps and statistics

## Customization

### Adding New Countries

1. Add a new GeoJSON file to `data/geojson/` named `{country}_backbone.geojson`
2. Ensure it has `name`, `level`, and `geometry` fields
3. The country will automatically appear in the dropdown

### Modifying Color Scheme

Edit the `category_colors` vector in `R/indicators.R`:

```r
category_colors <- c(
  "Disruption >10%" = "#d7191c",  # Change these hex codes
  "Disruption 5-10%" = "#fdae61",
  "Stable" = "#ffffbf",
  "Surplus 5-10%" = "#a6d96a",
  "Surplus >10%" = "#1a9641",
  "Insufficient data" = "#999999"
)
```

### Adding New Indicators

Add entries to the `indicator_labels` data frame in `R/indicators.R`:

```r
indicator_labels <- rbind(
  indicator_labels,
  data.frame(
    indicator_id = "new_indicator",
    indicator_name = "New Indicator Display Name",
    stringsAsFactors = FALSE
  )
)
```

### Customizing the Theme

Edit `www/custom.css` to modify the FASTR teal color scheme:

```css
:root {
  --fastr-teal: #0f706d;        /* Main brand color */
  --fastr-teal-light: #1a8b86;  /* Lighter variant */
  /* ... other color variables */
}
```

## Troubleshooting

### Map Not Displaying

- Check that the GeoJSON file exists and has valid geometries
- Ensure `level == 2` features exist in the GeoJSON
- Check the browser console for JavaScript errors

### No Data After Upload

- Verify CSV has all required columns
- Check that `admin_area_2` names match the GeoJSON `name` field exactly
- Ensure year values are numeric

### Missing Administrative Areas

- Some areas in the GeoJSON might not have data in the CSV
- These areas will display as gray on the map
- Check for name mismatches between GeoJSON and CSV

### Performance Issues

For large datasets:
- Filter data before uploading
- Use specific years/indicators rather than viewing all data
- Consider aggregating data to higher administrative levels

## Technical Notes

- **Modular Architecture**: Clean separation of concerns with R/ modules
- **sf Package**: Spatial operations for geospatial data
- **Leaflet**: Interactive mapping with custom controls
- **Spherical Geometry**: Disabled (`sf_use_s2(FALSE)`) for simpler operations
- **Reactive Programming**: Efficient updates with Shiny reactives
- **FASTR Theme**: Custom CSS with teal (#0f706d) branding
- **Database Support**: Optional PostgreSQL integration for large datasets
- **File Upload**: Supports up to 2GB CSV files

## Architecture

The app follows a clean, modular architecture:

- **R/indicators.R**: Centralized indicator definitions, categories, and color palettes
- **R/data_functions.R**: All data loading, validation, and processing logic
- **R/map_functions.R**: Map rendering with continuous/categorical color scales
- **R/ui_components.R**: Reusable UI component functions
- **www/custom.css**: FASTR-themed styles separate from application logic
- **app.R**: Clean orchestration (~440 lines vs 1000+ in monolithic version)

## Support

For issues or questions:
1. Check this README
2. Review the comprehensive documentation in **[documentation/](documentation/)**
3. Start with **[documentation/INDEX.md](documentation/INDEX.md)** for the complete guide
4. Check the "About" tab in the app
5. Verify data format requirements
6. Ensure all required packages are installed

For specific topics:
- Getting started: **[documentation/QUICK_START.md](documentation/QUICK_START.md)**
- Map exports: **[documentation/PROFESSIONAL_MAP_EXPORT.md](documentation/PROFESSIONAL_MAP_EXPORT.md)**
- Heatmap view: **[documentation/HEATMAP_FEATURE.md](documentation/HEATMAP_FEATURE.md)**
- French support: **[documentation/FRENCH_TRANSLATION_GUIDE.md](documentation/FRENCH_TRANSLATION_GUIDE.md)**

## Version History

- **v2.0** (2024): Modular architecture, FASTR theme, indicator-only mapping, multi-level admin
- **v1.0** (2024): Initial release with core functionality
