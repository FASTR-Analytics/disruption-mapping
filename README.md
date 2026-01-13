---
title: Health Service Disruption Mapping
emoji: 🏥
colorFrom: blue
colorTo: green
sdk: docker
pinned: false
license: apache-2.0
---

# Health Service Disruption Mapping

Interactive visualization of health service disruptions across administrative areas. Compare actual service counts against expected values based on historical trends.

## Features

- Interactive maps with color-coded administrative areas
- Heatmap view showing all 52+ health indicators at once
- Publication-ready PNG exports (300 DPI) with north arrow and scale bar
- Support for 17 countries across Africa
- Full French/English language support
- Dynamic time period detection

## Supported Indicators

**Maternal & Child Health**: ANC visits, institutional deliveries, postnatal care, immunizations (BCG, Penta, Measles, RR1)

**Disease Programs**: Malaria (testing, treatment, confirmation), HIV (testing, ART), TB (confirmed, treated)

**Nutrition & Other Services**: SAM treatment, vitamin A, diarrhoea, GBV, outpatient/inpatient visits

## Disruption Categories

| Color | Category | Meaning |
|-------|----------|---------|
| Dark Red | Disruption >10% | Services significantly below expected |
| Orange | Disruption 5-10% | Moderate disruption |
| Light Yellow | Stable | Within ±5% of expected |
| Light Green | Surplus 5-10% | Moderate increase |
| Dark Green | Surplus >10% | Services significantly above expected |
| Light Gray | Insufficient data | Not enough data to calculate |

## Data Format

### Required CSV Columns

| Column | Description |
|--------|-------------|
| `admin_area_2` | Administrative area name (state/province/district) |
| `indicator_common_id` | Health indicator identifier |
| `year` | Year of observation |
| `period_id` | Period identifier (format: YYYYMM) |
| `count_sum` | Actual count of services delivered |
| `count_expect_sum` | Expected count based on historical trends |

### Optional Columns

- `admin_area_3`: Sub-district level (for Level 3 analysis)

## Supported Countries

Bangladesh, Benin, Burkina Faso, Cameroon, Cote d'Ivoire, DRC, Ethiopia, Ghana, Guinea, Haiti, Kenya, Liberia, Mali, Niger, Nigeria, Senegal, Sierra Leone, Tanzania, Togo, Uganda

## Technical Stack

- **Framework**: R Shiny with shinydashboard
- **Mapping**: Leaflet for interactive maps, sf for spatial data
- **Visualization**: ggplot2 with ggspatial for professional exports
- **Deployment**: Docker container on Hugging Face Spaces

## Documentation

Full documentation: https://fastr-analytics.github.io/disruption-mapping/

## About

Developed for FASTR (Fast-track Action for effective scale-up of priority maternal, newborn, and child health and nutrition interventions).

## License

Apache 2.0
