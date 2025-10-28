# Dynamic Time Period Subtitles

## ✅ What Changed

The PNG map exports now show **dynamic time periods** extracted from your actual data instead of generic text.

### Before:
❌ "Admin area service volumes: 2025" (not meaningful)

### After:
✅ **"Jan-Dec 2025"** (shows actual data range)
✅ **"Mar-Oct 2024"** (partial year)
✅ **"Jan 2025"** (single month)
✅ **"2025"** (fallback if no month data)

---

## 🎯 How It Works

The app automatically:
1. **Reads your data** for the selected year and indicator
2. **Extracts months** from the `period_id` column (format: YYYYMM)
3. **Calculates range**: Finds minimum and maximum months
4. **Formats subtitle** based on the range

---

## 📊 Subtitle Examples

### Full Year Data
**Data**: January through December 2025
**Subtitle**: `Jan-Dec 2025`

### Partial Year Data
**Data**: March through October 2024
**Subtitle**: `Mar-Oct 2024`

### Single Month Data
**Data**: Only June 2025
**Subtitle**: `Jun 2025`

### Multiple Months (Different Format)
**Data**: May through August 2023
**Subtitle**: `May-Aug 2023`

### No Period Data
**Data**: Year only (no month information)
**Subtitle**: `2025`

---

## 🔧 Technical Details

### Data Requirement
- Your data must have a `period_id` column (format: `YYYYMM`)
- Example: `202501` = January 2025, `202412` = December 2024

### Month Extraction
```r
# Extract month from period_id
month <- as.integer(substr(period_id, 5, 6))

# 202501 → month = 1 (January)
# 202512 → month = 12 (December)
```

### Month Names
Uses 3-letter abbreviations:
```
1 → Jan    7 → Jul
2 → Feb    8 → Aug
3 → Mar    9 → Sep
4 → Apr   10 → Oct
5 → May   11 → Nov
6 → Jun   12 → Dec
```

---

## 💡 Benefits

### 1. **Accurate Information**
Shows the exact time period covered by your data, not a generic year.

### 2. **Automatic Detection**
No need to manually specify time ranges - extracted from data automatically.

### 3. **Flexible Handling**
Works with:
- Full year data (Jan-Dec)
- Partial year data (any month range)
- Single month data
- Data without month information (shows year only)

### 4. **Professional Appearance**
Maps clearly communicate the temporal scope of the data.

---

## 🎨 Visual Comparison

### Old Subtitle (Generic)
```
┌─────────────────────────────────────┐
│  Antenatal client 4th visit         │
│  Admin area service volumes: 2025   │  ← Generic, not specific
└─────────────────────────────────────┘
```

### New Subtitle (Dynamic)
```
┌─────────────────────────────────────┐
│  Antenatal client 4th visit         │
│  Jan-Dec 2025                       │  ← Specific time range!
└─────────────────────────────────────┘
```

---

## 🧪 Testing Different Scenarios

### Test Case 1: Full Year
**Upload data with**: period_id from 202501 to 202512
**Expected subtitle**: `Jan-Dec 2025`

### Test Case 2: Partial Year
**Upload data with**: period_id from 202403 to 202410
**Expected subtitle**: `Mar-Oct 2024`

### Test Case 3: Single Month
**Upload data with**: period_id = 202406 only
**Expected subtitle**: `Jun 2024`

### Test Case 4: No Month Data
**Upload data with**: only year column (no period_id)
**Expected subtitle**: `2024`

---

## 🔄 Fallback Behavior

If your data doesn't have a `period_id` column:
- ✅ App still works
- ✅ Subtitle shows: `2025` (year only)
- ✅ No errors

This ensures backward compatibility with datasets that don't have monthly breakdowns.

---

## 📝 Custom Override

You can still manually override the subtitle if needed:

```r
save_map_png(
  map_data = your_data,
  filename = "output.png",
  indicator_name = "Your Indicator",
  country_name = "Country",
  year = "2025",
  period_label = "Q1 2025 (Jan-Mar)",  # Custom override
  color_scale = "continuous"
)
```

But in the Shiny app, the period is detected automatically!

---

## ✨ Example Outputs

### Example 1: Nigeria, Full Year
```
Title: Antenatal care 1st visit
Subtitle: Jan-Dec 2025
```

### Example 2: Senegal, Partial Year
```
Title: BCG vaccine
Subtitle: Apr-Sep 2024
```

### Example 3: Sierra Leone, Single Month
```
Title: Malaria diagnosis and treatment (ACT)
Subtitle: Aug 2023
```

---

## 🎯 Where This Applies

**Affected**:
- ✅ PNG map exports (download button)

**Not Affected**:
- Interactive leaflet map (doesn't have subtitle)
- Statistics charts and tables

The dynamic time period only appears in the **static PNG map** subtitle.

---

## 🚀 Benefits for Your Workflow

### For Reports
- **Clear temporal scope**: Readers know exactly what period is covered
- **No manual editing**: Subtitle updates automatically based on data
- **Professional presentation**: Precise information enhances credibility

### For Multi-Country Analysis
- **Flexible periods**: Each country may have different data coverage
- **Automatic adaptation**: Subtitle reflects each dataset's actual range
- **No hardcoding**: One codebase handles all scenarios

### For Data Quality
- **Validation tool**: Quickly see if data covers expected time range
- **Spot gaps**: If subtitle shows "Jan-Mar" but you expected full year
- **Transparency**: Clear communication about data completeness

---

**Your maps now show exactly what time period they represent!** 📅✨

This makes your exports more informative, professional, and accurate.
