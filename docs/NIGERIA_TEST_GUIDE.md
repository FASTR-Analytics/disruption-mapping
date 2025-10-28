# Testing the Disruption Mapping App with Nigeria Data

## Updates Made

The app has been updated to support **both Admin Level 2 and Admin Level 3** mapping:

### New Features
1. **Admin Level Selector** - Choose between Level 2 (State/Province) and Level 3 (District/LGA)
2. **Auto-detection** - App automatically detects which level your CSV file contains
3. **Dynamic Column Handling** - Works with both `admin_area_2` only and `admin_area_2` + `admin_area_3` columns
4. **Flexible Year Detection** - Extracts year from `period_id` if `year` column is missing

## Test Files - Nigeria

### Admin Level 2 (States)
**File:** `/Users/claireboulange/Desktop/modules/Oct_NGA/M3_disruptions_analysis_admin_area_2.csv`

**Columns:**
- `admin_area_2` - State/Zone name
- `indicator_common_id` - Health indicator
- `period_id` - Monthly period (e.g., 202001)
- `count_sum` - Actual count
- `count_expect_sum` - Expected count

**Example Row:**
```
admin_area_2,indicator_common_id,period_id,count_sum,count_expect_sum
North Central Zone,anc1,202001,78871.22,73310.74
```

### Admin Level 3 (LGAs/Districts)
**File:** `/Users/claireboulange/Desktop/modules/Oct_NGA/M3_disruptions_analysis_admin_area_3.csv`

**Columns:**
- `admin_area_2` - State/Zone name
- `admin_area_3` - LGA/District name
- `indicator_common_id` - Health indicator
- `period_id` - Monthly period
- `count_sum` - Actual count
- `count_expect_sum` - Expected count

**Example Row:**
```
admin_area_2,admin_area_3,indicator_common_id,period_id,count_sum,count_expect_sum
North Central Zone,be Benue State,anc1,202001,9048.42,9288.30
```

## How to Test

### Step 1: Launch the App

```r
setwd("/Users/claireboulange/Desktop/modules/disruption_mapping")
source("install_packages.R")  # First time only
source("launch_app.R")
```

### Step 2: Test Admin Level 2 (States)

1. **Select Country:** Choose "Nigeria" from dropdown
2. **Select Admin Level:** Choose "Level 2 (State/Province)"
3. **Upload File:** Browse to `/Users/claireboulange/Desktop/modules/Oct_NGA/M3_disruptions_analysis_admin_area_2.csv`
4. **Select Year:** Choose 2020, 2021, 2022, etc.
5. **View Mode:** Start with "All Indicators"
6. **Explore:**
   - Hover over states/zones on the map
   - Check the disruption categories
   - View summary statistics

### Step 3: Test Admin Level 3 (LGAs)

1. **Select Admin Level:** Change to "Level 3 (District/LGA)"
   - The map will reload with LGA boundaries
2. **Upload File:** Browse to `/Users/claireboulange/Desktop/modules/Oct_NGA/M3_disruptions_analysis_admin_area_3.csv`
   - The app will auto-detect Level 3 and update the selector
3. **Select Year:** Choose desired year
4. **View Mode:** Try both "All Indicators" and specific indicators
5. **Explore:**
   - More detailed map with LGA-level boundaries
   - Zoom in to see individual LGAs
   - Compare disruption patterns across LGAs

### Step 4: Test Different Views

**All Indicators View:**
- Shows overall disruption across all health services
- Good for identifying priority areas

**By Indicator View:**
- Select specific indicators like:
  - `anc1` - Antenatal care 1st visit
  - `bcg` - BCG vaccination
  - `delivery` - Institutional delivery
  - `penta3` - Pentavalent 3rd dose
- Compare disruption patterns by service type

### Step 5: Explore All Tabs

1. **Disruption Map Tab:**
   - Interactive map with color-coded areas
   - Summary boxes showing counts

2. **Summary Statistics Tab:**
   - Bar chart of disruption distribution
   - Top 10 most disrupted areas
   - Detailed summary table

3. **Data Table Tab:**
   - Filterable data table
   - Shows all months for selected year
   - Export functionality

## Expected Results

### Admin Level 2 Map
- Should show Nigerian states/zones
- Color-coded by disruption category
- Fewer polygons (larger areas)

### Admin Level 3 Map
- Should show LGAs/districts
- More detailed boundaries
- Many more polygons (smaller areas)
- May need to zoom in to see details

## Validation Checklist

- [ ] App launches without errors
- [ ] Nigeria appears in country dropdown
- [ ] Admin level selector has 2 options
- [ ] Can upload Level 2 CSV successfully
- [ ] Map shows state/zone boundaries
- [ ] Can switch to Level 3
- [ ] Can upload Level 3 CSV successfully
- [ ] Map shows LGA boundaries
- [ ] Years populate correctly (2020-2024)
- [ ] All indicators appear in dropdown
- [ ] Map colors match disruption categories
- [ ] Hover tooltips work on map
- [ ] Summary statistics display correctly
- [ ] Data table shows correct columns
- [ ] Can filter and export data

## Troubleshooting

### "Map is empty/gray"
**Cause:** Admin area names in CSV don't match GeoJSON names

**Solution:** Check name matching
```r
source("prepare_data_helper.R")
check_admin_name_matches(
  csv_file = "/Users/claireboulange/Desktop/modules/Oct_NGA/M3_disruptions_analysis_admin_area_2.csv",
  geojson_file = "nigeria_backbone.geojson"
)
```

### "No years in dropdown"
**Cause:** Year column missing from CSV

**Solution:** The app should auto-extract from `period_id`. If it doesn't, check that `period_id` column exists.

### "Wrong admin level displayed"
**Cause:** Admin level selector doesn't match uploaded file

**Solution:** The app auto-detects and updates the selector. If issues persist, manually select the correct level before uploading.

## Data Validation

Before uploading, validate your files:

```r
source("prepare_data_helper.R")

# Validate Level 2 file
validate_disruption_csv("/Users/claireboulange/Desktop/modules/Oct_NGA/M3_disruptions_analysis_admin_area_2.csv")

# Validate Level 3 file
validate_disruption_csv("/Users/claireboulange/Desktop/modules/Oct_NGA/M3_disruptions_analysis_admin_area_3.csv")
```

## Known Differences Between Levels

### Level 2 (States/Zones)
- **Pros:**
  - Overview of large regions
  - Less complex, easier to interpret
  - Fewer data quality issues
- **Cons:**
  - Less granular detail
  - May mask local disruptions

### Level 3 (LGAs/Districts)
- **Pros:**
  - Highly detailed local view
  - Identify specific problem areas
  - Better for targeted interventions
- **Cons:**
  - More complex map
  - Potential data quality issues
  - Requires more zooming/panning

## Sample Indicators to Test

Try these indicators for meaningful results:

1. **Maternal Health:**
   - `anc1` - Antenatal care coverage
   - `delivery` - Institutional deliveries

2. **Child Health:**
   - `penta3` - Full immunization proxy
   - `bcg` - Birth dose coverage

3. **Malaria:**
   - `malaria_tested` - Testing coverage
   - `malaria_tx` - Treatment coverage

4. **General Services:**
   - `opd` - Outpatient volume
   - `ipd` - Inpatient volume

## Tips for Best Results

1. **Start with Level 2** to get overview
2. **Switch to Level 3** for detailed analysis
3. **Compare years** to see trends
4. **Test multiple indicators** to find patterns
5. **Use data table** to investigate specific areas
6. **Export results** for further analysis

## Success Criteria

The app is working correctly if:
- ✅ Both admin levels load and display properly
- ✅ Maps show appropriate boundaries for each level
- ✅ Colors correctly reflect disruption categories
- ✅ Summary statistics match expectations
- ✅ Can switch between levels without errors
- ✅ All tabs function correctly

---

**Ready to test?** Run `source("launch_app.R")` and try both admin levels!
