# Getting Started

This guide will help you get started with the Health Service Disruption Mapping application.

## Accessing the Application

The application is hosted on Hugging Face Spaces:

**[https://huggingface.co/spaces/CIJBoulange/health-disruption-mapping](https://huggingface.co/spaces/CIJBoulange/health-disruption-mapping)**

!!! note "First Load"
    The app may take 30-60 seconds to wake up if it hasn't been used recently.

## Interface Overview

The application has several tabs:

### Disruption Map

Main choropleth map view for a single health indicator. Shows percent change between actual and expected service delivery across administrative areas. Use this for focused analysis of one indicator at a time.

### Multi-Indicator

Side-by-side comparison of 2 indicators on the same map layout. Useful for identifying patterns across related services (e.g., comparing ANC1 and facility deliveries).

### Year-on-Year Change

Compares service utilization between the current period and the previous year. This tab uses output from [Module 2 (Data Quality Adjustment)](https://fastr-analytics.github.io/fastr-resource-hub/05_data_quality_adjustment/) of the FASTR Analytics platform. Options include:

- **Adjusted vs raw data**: Choose whether to use outlier-adjusted values
- **Period selection**: Compare specific months or cumulative totals

### Heatmap

Matrix visualization showing all indicators across all administrative areas. Quickly identify which services and locations have the most severe disruptions.

### Data Table

Raw data view in tabular format. Filter, sort, and export the underlying numbers.

## Language Toggle

Click the **EN/FR** button in the sidebar to switch between English and French. All labels, legends, and map titles will update accordingly.

## Basic Workflow

1. **Select Country**: Choose from the dropdown menu
2. **Upload Data**: Upload your M3 disruption CSV file
3. **Select Parameters**: Choose year and indicator
4. **View Map**: The map automatically updates
5. **Export**: Download the map as PNG

## Next Steps

- [Uploading Data](uploading-data.md) - Learn about data requirements
- [Creating Maps](creating-maps.md) - Customize your visualizations
- [Exporting Maps](exporting-maps.md) - Download and share your maps
