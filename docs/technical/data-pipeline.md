# Data Pipeline

## Overview

The application processes HMIS data through a visualization pipeline.

```
M3 CSV → Upload → Validate → Transform → Join → Visualize → Export
```

## Input Data (M3 Output)

The Module 3 (M3) output from FASTR contains service utilization data with expected values.

### Key Fields

| Field | Type | Description |
|-------|------|-------------|
| `admin_area_2` | string | Province/State name |
| `admin_area_3` | string | District name (optional) |
| `indicator_common_id` | string | Indicator code |
| `year` | integer | Calendar year |
| `period_id` | integer | YYYYMM format |
| `count_sum` | numeric | Actual service count |
| `count_expect_sum` | numeric | Expected service count |

## Processing Steps

### 1. Upload & Validation

```r
# Detect admin level
detected_level <- if("admin_area_3" %in% names(data)) "3" else "2"

# Validate required columns
required_cols <- c("indicator_common_id", "year", "count_sum", "count_expect_sum")
```

### 2. Aggregation

Data is aggregated by admin area and indicator:

```r
summary_data <- data %>%
  group_by(admin_area, indicator_common_id) %>%
  summarise(
    total_actual = sum(count_sum, na.rm = TRUE),
    total_expected = sum(count_expect_sum, na.rm = TRUE)
  )
```

### 3. Percent Change Calculation

```r
percent_change = (total_actual - total_expected) / total_expected * 100
```

### 4. Geographic Join

Data is joined to GeoJSON boundaries by admin area name:

```r
map_data <- geo_data %>%
  left_join(summary_data, by = c("name" = "admin_area"))
```

### 5. Name Cleaning

Area names are cleaned for display:

```r
# Remove prefixes: "nu ", "su ", etc.
name <- gsub("^[a-z]{2,3} ", "", name)

# Remove suffixes: " Province", " Region", etc.
name <- gsub(" Province$", "", name, ignore.case = TRUE)
```

## Geographic Boundaries

### GeoJSON Files

Located in `data/geojson/`:

- `cameroon_backbone.geojson`
- `drc_backbone.geojson`
- `ethiopia_backbone.geojson`
- ... (one per country)

### Structure

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "name": "Nord Ubangi",
        "level": "2"
      },
      "geometry": { ... }
    }
  ]
}
```

## Performance Notes

- GeoJSON files range from 1-26 MB
- Files are stored with Git LFS
- Boundaries are loaded once per country selection
