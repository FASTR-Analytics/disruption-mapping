# Quick Start Guide - Disruption Mapping App

## Installation (First Time Only)

Open R or RStudio and run:

```r
# Navigate to the app folder
setwd("/Users/claireboulange/Desktop/modules/disruption_mapping")

# Install required packages
source("install_packages.R")
```

## Launch the App

### Option 1: Using the Launcher (Recommended)
```r
source("launch_app.R")
```

### Option 2: Direct Launch
```r
setwd("/Users/claireboulange/Desktop/modules/disruption_mapping")
shiny::runApp()
```

### Option 3: From RStudio
1. Open `app.R` in RStudio
2. Click the "Run App" button at the top right

## Using the App - 3 Easy Steps

### 1. Select Country
Choose from the dropdown: Nigeria, Senegal, Sierra Leone, Guinea, etc.

### 2. Upload Data
Click "Browse" and select your disruption CSV file
- Example: `M3_disruptions_analysis_admin_area_2.csv`
- Or use the template format

### 3. Explore
- Select year (e.g., 2024)
- Choose "All Indicators" or specific indicator
- Hover over map areas to see details
- Check Summary Statistics tab for charts

## Example Files to Upload

### Sierra Leone Example
**File:** `/Users/claireboulange/Desktop/FASTR/Request/Sierra_Leone/M3_disruptions_analysis_admin_area_2.csv`

Steps:
1. Select "Sierraleone" from country dropdown
2. Upload the file above
3. Select year 2024 or 2023
4. View the map!

### From Pipeline Outputs
If you've run the modules pipeline:
- Look for `M3_disruptions_analysis_admin_area_2.csv` in `/Users/claireboulange/Desktop/modules/`
- Upload this file directly to the app

## Understanding the Map Colors

| Color | Meaning |
|-------|---------|
| 🔴 Dark Red | Disruption >10% (Critical) |
| 🟠 Orange | Disruption 5-10% (Moderate) |
| 🟡 Yellow | Stable (±5%) |
| 🟢 Light Green | Surplus 5-10% |
| 🟢 Dark Green | Surplus >10% |
| ⚪ Gray | Insufficient data |

## Troubleshooting

### "No countries in dropdown"
- Check that `*_backbone.geojson` files exist in the folder
- GeoJSON files should be in the same folder as `app.R`

### "Map is empty/gray"
- Ensure admin area names in CSV match GeoJSON names exactly
- Use the helper script to check:
  ```r
  source("prepare_data_helper.R")
  check_admin_name_matches("your_file.csv", "country_backbone.geojson")
  ```

### "Package installation failed"
- Make sure you have internet connection
- Try installing packages individually:
  ```r
  install.packages("sf")
  install.packages("leaflet")
  ```

### "App won't launch"
- Verify all packages are installed:
  ```r
  source("install_packages.R")  # Re-run installation
  ```

## Data Validation

Before uploading, validate your CSV:

```r
source("prepare_data_helper.R")
validate_disruption_csv("path/to/your/file.csv")
```

## Need Help?

1. Check `README.md` for detailed documentation
2. Run `example_usage.R` for examples
3. Use `prepare_data_helper.R` for data checking

## File Structure

```
disruption_mapping/
├── app.R                          # Main app (don't edit unless customizing)
├── QUICKSTART.md                  # This file
├── README.md                      # Full documentation
├── install_packages.R             # Package installer
├── launch_app.R                   # App launcher
├── prepare_data_helper.R          # Data validation tools
├── example_usage.R                # Usage examples
└── *_backbone.geojson            # Country boundary files
```

## Tips

- Start with "All Indicators" view for overview
- Use "By Indicator" to investigate specific services
- Export data from "Data Table" tab for further analysis
- Check "Summary Statistics" for quick insights

---

**Ready?** Run `source("launch_app.R")` to get started!
