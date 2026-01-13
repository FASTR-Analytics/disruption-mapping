# Creating Maps

## Single Indicator Map

The main **Disruption Map** tab shows a single indicator at a time.

### Configuration Options

| Option | Description |
|--------|-------------|
| **Year** | Filter data to a specific year |
| **Indicator** | Select the health indicator to display |
| **Color Scale** | Choose continuous or categorical coloring |
| **Show Labels** | Toggle area names on/off |

### Color Scale

The map uses a diverging color scale:

- **Red**: Disruption (actual < expected)
- **Yellow**: Stable (actual ≈ expected)
- **Green**: Surplus (actual > expected)

Values are capped at ±50% for visual clarity.

## Multi-Indicator Comparison

The **Multi-Indicator** tab displays 2 indicators side by side.

### Steps

1. Go to the **Multi-Indicator** tab
2. Select **Indicator 1** and **Indicator 2** from the dropdowns
3. Both maps will display with the same year filter

!!! tip "Best Practices"
    Compare related indicators (e.g., ANC 1st visit vs ANC 4th visit) to identify patterns in service delivery.

## Interactive Features

### Zoom and Pan

- **Scroll** to zoom in/out
- **Click and drag** to pan
- **Double-click** to reset view

### Hover Information

Hover over any area to see:

- Area name
- Actual count
- Expected count
- Percent change

## Map Labels

When **Show Labels** is enabled:

- **Percentage** displays on the centroid
- **Area name** displays below the percentage

Area names are automatically cleaned:

- Prefixes like "nu", "su" are removed
- Suffixes like "Province", "Region" are removed

Example: `nu Nord Ubangi Province` → `Nord Ubangi`
