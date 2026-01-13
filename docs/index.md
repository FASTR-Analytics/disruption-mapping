# Health Service Disruption Mapping

Interactive visualization of health service disruptions across administrative areas with bilingual support (English/French).

## Overview

This application allows health analysts to visualize and compare actual vs expected service volumes for 52+ health indicators. It supports data from multiple countries and provides tools for identifying service disruptions at various administrative levels.

## Features

- **Multi-country support**: Currently includes Cameroon, DRC, Ethiopia, Ghana, Guinea, Haiti, Liberia, Nigeria, Senegal, Sierra Leone, Somalia, and Somaliland
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

## Data Requirements

The app expects CSV files with the following columns:

- `admin_area_2` or `admin_area_3`: Administrative area name
- `indicator_common_id`: Indicator identifier
- `year`: Year of data
- `count_sum`: Actual service count
- `count_expect_sum`: Expected service count

See [Data Format](reference/data-format.md) for detailed specifications.

## Support

For issues or questions, please [open an issue on GitHub](https://github.com/CIJBoulange/health-disruption-mapping/issues).
