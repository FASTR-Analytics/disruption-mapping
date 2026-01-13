# Contributing

## Getting Started

### Prerequisites

- R 4.3+
- Git with LFS
- Docker (optional, for local testing)

### Clone the Repository

```bash
git clone https://github.com/CIJBoulange/health-disruption-mapping.git
cd health-disruption-mapping
git lfs pull  # Download large GeoJSON files
```

### Install Dependencies

```r
install.packages(c(
  "shiny", "shinydashboard", "shinyWidgets",
  "sf", "leaflet", "dplyr", "ggplot2",
  "ggspatial", "ggrepel", "DT"
))
```

### Run Locally

```r
shiny::runApp()
```

## Code Structure

```
R/
├── data_functions.R   # Data loading, country list, period parsing
├── map_functions.R    # Leaflet maps, ggplot maps, PNG export
├── translations.R     # UI text, country names in EN/FR
├── indicators.R       # Indicator definitions and labels
└── ui_components.R    # Reusable UI elements
```

## Making Changes

### Branch Naming

- `feature/description` - New features
- `fix/description` - Bug fixes
- `docs/description` - Documentation updates

### Code Style

- Use tidyverse style for R code
- Comment complex logic
- Keep functions focused and modular

### Testing

Before submitting:

1. Run the app locally
2. Test with multiple countries
3. Test both English and French
4. Verify map exports work

## Adding a New Country

1. **Add GeoJSON file**

   ```bash
   # Add to data/geojson/
   cp newcountry_backbone.geojson data/geojson/
   git lfs track "data/geojson/*.geojson"
   ```

2. **Update country list** in `R/data_functions.R`:

   ```r
   allowlist <- c(
     ...,
     newcountry = "New Country Name"
   )
   ```

3. **Add translations** in `R/translations.R`:

   ```r
   country_names <- list(
     en = list(..., newcountry = "New Country"),
     fr = list(..., newcountry = "Nouveau Pays")
   )
   ```

## Submitting Changes

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Submit a pull request
5. Describe your changes clearly

## Questions?

Open an issue on GitHub for questions or suggestions.
