# Health Service Disruption Mapping

Interactive visualization of health service disruptions across administrative areas with bilingual support (English/French).

## Overview

This application allows health analysts to visualize and compare actual vs expected service volumes for 52+ health indicators. It supports data from multiple countries and provides tools for identifying service disruptions at various administrative levels.

## Features

- **Multi-country support**: Currently includes DRC, Haiti, Ethiopia, Cameroon, Ghana, Guinea, Liberia, Senegal, Sierra Leone, Somalia, and Somaliland
- **52+ health indicators**: Vaccination, maternal health, nutrition, and more
- **Bilingual interface**: English and French
- **Interactive maps**: Choropleth maps with customizable color scales
- **Multi-indicator comparison**: Side-by-side comparison of 2 indicators
- **Export capabilities**: Download maps as PNG images
- **Year-on-year analysis**: Compare current period to previous year

## Quick Start

1. Go to [the app on Hugging Face](https://huggingface.co/spaces/CIJBoulange/health-disruption-mapping)
2. Select a country from the dropdown
3. Upload your disruption data CSV file (M3 output)
4. Select year and indicator
5. View and export your map

## Data Source

This app visualizes outputs from the [FASTR Analytics Platform](https://fastr-analytics.github.io/fastr-resource-hub/) - a web-based tool for data quality assessment, adjustment, and analysis of routine health data from DHIS2 and other sources.

| Tab | Input | Documentation |
|-----|-------|---------------|
| Disruption Map | M3 output | [Service Utilization](https://fastr-analytics.github.io/fastr-resource-hub/06a_service_utilization/) |
| Multi-Indicator | M3 output | [Service Utilization](https://fastr-analytics.github.io/fastr-resource-hub/06a_service_utilization/) |
| Year-on-Year | M2 output | [Data Quality Adjustment](https://fastr-analytics.github.io/fastr-resource-hub/05_data_quality_adjustment/) |
| Heatmap | M3 output | [Service Utilization](https://fastr-analytics.github.io/fastr-resource-hub/06a_service_utilization/) |

## Data Requirements

Required CSV columns:

- `admin_area_2` or `admin_area_3`: Administrative area name
- `indicator_common_id`: Indicator identifier
- `year`: Year of data
- `count_sum`: Actual service count
- `count_expect_sum`: Expected service count

See [Data Format](reference/data-format.md) for detailed specifications.

## Support

For issues or questions, please [open an issue on GitHub](https://github.com/FASTR-Analytics/disruption-mapping/issues).

---
*Documentation built with MkDocs and Material theme*
