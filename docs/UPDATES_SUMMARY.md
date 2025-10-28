# Disruption Mapping App - Updates Summary

## What Was Done

### 1. Multi-Level Admin Support Added ✅

The app now supports **both Administrative Level 2 and Level 3** mapping:

- **Level 2**: States, Provinces, Zones (larger regions)
- **Level 3**: Districts, LGAs, Local Government Areas (smaller regions)

### 2. Key Changes Made

#### UI Changes
- ✅ Added **"Administrative Level" selector** with options:
  - Level 2 (State/Province)
  - Level 3 (District/LGA)
- ✅ Reorganized layout for better flow
- ✅ Moved indicator selector to main row

#### Backend Changes
- ✅ **Auto-detection** of admin level from uploaded CSV
  - Detects `admin_area_3` column → Level 3
  - Only `admin_area_2` → Level 2
- ✅ **Dynamic GeoJSON filtering** based on selected level
- ✅ **Flexible year extraction** from `period_id` if `year` column missing
- ✅ **Dynamic data table** showing appropriate columns for each level
- ✅ **Updated all calculations** to work with both levels

#### Data Handling
- ✅ Handles CSV files with `admin_area_2` only (Level 2)
- ✅ Handles CSV files with `admin_area_2` + `admin_area_3` (Level 3)
- ✅ Auto-updates admin level selector to match uploaded data
- ✅ Extracts year from `period_id` format (YYYYMM)

### 3. New Files Created

1. **NIGERIA_TEST_GUIDE.md** - Complete testing guide for Nigeria data
2. **verify_setup.R** - Setup verification script
3. **UPDATES_SUMMARY.md** - This file
4. **app_backup.R** - Backup of original app

## Testing with Nigeria Data

### Files Ready for Testing

**Admin Level 2:**
```
/Users/claireboulange/Desktop/modules/Oct_NGA/M3_disruptions_analysis_admin_area_2.csv
```
- Shows state/zone level disruptions
- Columns: admin_area_2, indicator_common_id, period_id, count_sum, count_expect_sum

**Admin Level 3:**
```
/Users/claireboulange/Desktop/modules/Oct_NGA/M3_disruptions_analysis_admin_area_3.csv
```
- Shows LGA/district level disruptions
- Columns: admin_area_2, admin_area_3, indicator_common_id, period_id, count_sum, count_expect_sum

## How to Use the Updated App

### Quick Start

```r
# Navigate to app folder
setwd("/Users/claireboulange/Desktop/modules/disruption_mapping")

# Install packages (first time only)
source("install_packages.R")

# Verify everything is ready
source("verify_setup.R")

# Launch the app
source("launch_app.R")
```

### Using the App

1. **Select Country**: Choose "Nigeria" (or any other country)

2. **Select Admin Level**:
   - Level 2 for state/province view
   - Level 3 for district/LGA view

3. **Upload Data**:
   - Browse to your disruption CSV file
   - App auto-detects the level and updates selector

4. **Configure View**:
   - Select year
   - Choose "All Indicators" or specific indicator

5. **Explore**:
   - Interactive map with color-coded areas
   - Summary statistics
   - Detailed data tables

### Workflow Examples

#### Example 1: Nigeria State-Level Analysis

```r
# 1. Launch app
source("launch_app.R")

# In the app:
# - Country: Nigeria
# - Admin Level: Level 2 (State/Province)
# - Upload: Oct_NGA/M3_disruptions_analysis_admin_area_2.csv
# - Year: 2024
# - View: All Indicators

# Result: Map showing disruption patterns across Nigerian states/zones
```

#### Example 2: Nigeria LGA-Level Analysis

```r
# In the app:
# - Country: Nigeria
# - Admin Level: Level 3 (District/LGA)
# - Upload: Oct_NGA/M3_disruptions_analysis_admin_area_3.csv
# - Year: 2024
# - View: By Indicator → Select "anc1"

# Result: Detailed map showing ANC1 disruptions across all LGAs
```

#### Example 3: Comparing Levels

```r
# Step 1: View Level 2
# - Upload admin_area_2.csv
# - Note which states have disruptions

# Step 2: Switch to Level 3
# - Select Level 3 from dropdown
# - Upload admin_area_3.csv
# - Zoom into specific states to see LGA details

# Result: Identify exactly which LGAs within disrupted states need attention
```

## Benefits of Multi-Level Support

### Level 2 (State/Province)
✅ **Quick Overview**
- Identify problem regions quickly
- Good for national/regional planning
- Less visual clutter

✅ **Strategic Planning**
- Resource allocation by state
- Regional trend analysis
- Policy decisions

### Level 3 (District/LGA)
✅ **Detailed Analysis**
- Pinpoint specific problem areas
- Target interventions precisely
- Local-level monitoring

✅ **Operational Planning**
- Facility-level support planning
- Supply distribution
- Supervision scheduling

### Combined Use
✅ **Comprehensive Analysis**
- Start with Level 2 overview
- Drill down to Level 3 for details
- Identify patterns at multiple scales

## Technical Details

### Data Requirements by Level

**Level 2 CSV Requirements:**
```
Required columns:
- admin_area_2 (must match GeoJSON "name" field for level 2)
- indicator_common_id
- count_sum
- count_expect_sum
- period_id OR year
```

**Level 3 CSV Requirements:**
```
Required columns:
- admin_area_2 (parent area)
- admin_area_3 (must match GeoJSON "name" field for level 3)
- indicator_common_id
- count_sum
- count_expect_sum
- period_id OR year
```

### GeoJSON Structure

The app expects GeoJSON files with:
```json
{
  "properties": {
    "name": "Area Name",
    "level": "2",  // or "3"
    "code": "optional_code"
  },
  "geometry": {...}
}
```

### How Auto-Detection Works

```r
# When CSV is uploaded, app checks:
if ("admin_area_3" in columns) {
  detected_level <- "3"
} else if ("admin_area_2" in columns) {
  detected_level <- "2"
}

# Then auto-updates the admin level selector
```

## Validation & Troubleshooting

### Before Launching

Run the verification script:
```r
source("verify_setup.R")
```

This checks:
- ✓ All required files present
- ✓ GeoJSON boundary files available
- ✓ R packages installed
- ✓ App syntax valid
- ✓ Test data accessible

### Common Issues

**Issue 1: Map shows gray areas**
- **Cause**: Admin area names don't match between CSV and GeoJSON
- **Solution**:
  ```r
  source("prepare_data_helper.R")
  check_admin_name_matches("your_file.csv", "country_backbone.geojson")
  ```

**Issue 2: Wrong level displayed**
- **Cause**: Uploaded wrong CSV for selected level
- **Solution**: App auto-corrects. If not, manually select correct level.

**Issue 3: No years in dropdown**
- **Cause**: Missing both `year` and `period_id` columns
- **Solution**: Ensure CSV has at least `period_id` in YYYYMM format

### Checking Name Matches

```r
# For Nigeria Level 2
check_admin_name_matches(
  csv_file = "/Users/claireboulange/Desktop/modules/Oct_NGA/M3_disruptions_analysis_admin_area_2.csv",
  geojson_file = "nigeria_backbone.geojson"
)

# For Nigeria Level 3
check_admin_name_matches(
  csv_file = "/Users/claireboulange/Desktop/modules/Oct_NGA/M3_disruptions_analysis_admin_area_3.csv",
  geojson_file = "nigeria_backbone.geojson"
)
```

## Next Steps

### Immediate Testing
1. ✅ Run `verify_setup.R` to check everything
2. ✅ Launch app with `launch_app.R`
3. ✅ Test Nigeria Level 2 data
4. ✅ Test Nigeria Level 3 data
5. ✅ Compare results between levels

### Expand Usage
1. 📁 Prepare disruption data for other countries
2. 🗺️ Test with different countries (Sierra Leone, Senegal, etc.)
3. 📊 Explore different indicators
4. 📈 Analyze trends across years
5. 📤 Export results for reports

### Customization
1. 🎨 Adjust colors in `category_colors`
2. 📝 Add new indicators to `indicator_labels`
3. 🔧 Modify disruption thresholds (currently ±5%, ±10%)
4. 🌍 Add new countries by adding GeoJSON files

## File Inventory

### Core Application
- `app.R` - Main Shiny app (UPDATED for multi-level support)
- `app_backup.R` - Backup of original version

### Launch & Setup
- `launch_app.R` - App launcher
- `install_packages.R` - Package installer
- `verify_setup.R` - Setup verification (NEW)

### Documentation
- `README.md` - Complete documentation
- `QUICKSTART.md` - Quick reference
- `NIGERIA_TEST_GUIDE.md` - Nigeria testing guide (NEW)
- `UPDATES_SUMMARY.md` - This file (NEW)
- `PROJECT_SUMMARY.md` - Project overview

### Helpers
- `prepare_data_helper.R` - Data validation tools
- `example_usage.R` - Usage examples

### Data
- `nigeria_backbone.geojson` - Nigeria boundaries (Level 2 & 3)
- 16 other country GeoJSON files

## Success Metrics

The app is working correctly when:

- ✅ Both admin levels load and display
- ✅ Auto-detection works for both CSV types
- ✅ Maps show correct boundaries for each level
- ✅ Can switch between levels smoothly
- ✅ Colors match disruption categories
- ✅ Summary statistics accurate
- ✅ Data table shows appropriate columns
- ✅ All tabs functional

## Support

### Resources
1. **QUICKSTART.md** - Quick how-to
2. **NIGERIA_TEST_GUIDE.md** - Detailed testing guide
3. **README.md** - Full documentation
4. **verify_setup.R** - Diagnostic tool
5. **prepare_data_helper.R** - Data validation

### Validation Tools
```r
# Check setup
source("verify_setup.R")

# Validate data
source("prepare_data_helper.R")
validate_disruption_csv("your_file.csv")

# Check name matching
check_admin_name_matches("your_file.csv", "country_backbone.geojson")
```

---

## Ready to Start!

```r
# Quick start command:
setwd("/Users/claireboulange/Desktop/modules/disruption_mapping")
source("verify_setup.R")   # Check everything
source("launch_app.R")      # Launch app

# Then test with Nigeria data using NIGERIA_TEST_GUIDE.md
```

**All systems ready! 🚀**

---

**Created**: October 26, 2024
**Version**: 2.0 (Multi-level support)
**Status**: Ready for Testing
