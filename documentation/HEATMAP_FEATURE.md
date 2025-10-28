# Heatmap Feature - Multi-Indicator Overview

## ✅ What's New

A comprehensive **Heatmap tab** that shows disruptions across **ALL indicators at once** for the selected year.

### Features:
- 📊 **Matrix view**: Districts (rows) × Indicators (columns)
- 🎨 **Color-coded**: Same category colors as other views
- 📅 **Dynamic time period**: Shows actual data range (e.g., "Mar-Aug 2025")
- 💾 **Downloadable**: Export as high-quality PNG (300 DPI, 16×10 inches)
- 🌍 **Multi-language**: Works with EN/FR toggle

---

## 🎯 What It Shows

### Overview at a Glance
See disruption status for **all 44 health indicators** across all districts in a single view.

**Example:**
```
                 ANC1  BCG  Delivery  Malaria  ...
District A        🟢    🔴     🟡       🟢
District B        🟡    🟢     🔴       🔴
District C        🔴    🔴     🟢       🟡
...
```

### Color Legend:
- 🔴 **Red**: Disruption >10% (services significantly below expected)
- 🟠 **Orange**: Disruption 5-10% (moderate disruption)
- 🟡 **Light Yellow**: Stable (within ±5% of expected)
- 🟢 **Light Green**: Surplus 5-10% (moderate increase)
- 🟩 **Dark Green**: Surplus >10% (services significantly above expected)
- ⬜ **Light Gray**: Insufficient data

---

## 📋 How to Use

### 1. Load Your Data
1. Navigate to **Disruption Map** tab
2. Select country, year, and upload data (or use database)
3. Data is now available for all tabs

### 2. View Heatmap
1. Click **"Heatmap"** in the sidebar menu
2. The heatmap appears showing ALL indicators
3. Subtitle shows the actual time period (e.g., "Mar-Aug 2025")

### 3. Interpret the Heatmap
- **Scan horizontally** (across a row) to see all indicators for one district
- **Scan vertically** (down a column) to see one indicator across all districts
- **Identify patterns**: Clusters of red indicate widespread disruption

### 4. Download the Heatmap
- Click **"Download Heatmap as PNG"** button
- High-quality image saved with:
  - Title with time period
  - Subtitle explaining the data
  - Full legend at bottom
  - Publication-ready quality (300 DPI)

---

## 🎨 Visual Layout

### Interactive View (in app):
```
┌─────────────────────────────────────────────────┐
│ SERVICE DISRUPTIONS BY DISTRICT AND INDICATOR   │
│ Comparison of actual vs expected - Mar-Aug 2025 │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  Heatmap - All Indicators                       │
│  [Download Heatmap as PNG]                      │
├─────────────────────────────────────────────────┤
│                                                 │
│              ANC1  BCG  Delivery  Malaria  ...  │
│  District A   🟢    🔴     🟡       🟢          │
│  District B   🟡    🟢     🔴       🔴          │
│  District C   🔴    🔴     🟢       🟡          │
│  ...                                            │
│                                                 │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│  Legend                                         │
│  🔴 Disruption >10%  🟠 Disruption 5-10%       │
│  ⚪ Stable  🟢 Surplus 5-10%  🟩 Surplus >10%   │
└─────────────────────────────────────────────────┘
```

### Downloaded PNG:
- **Title**: "Service disruptions by district and indicator - Mar-Aug 2025"
- **Subtitle**: "Comparison of actual vs expected service volumes across health indicators"
- **Heatmap**: Full matrix with all data
- **Caption**: "Categories based on deviation from expected service volumes predicted by statistical model"
- **Legend**: Horizontal at bottom

---

## 💡 Use Cases

### 1. **Quick Overview**
Get a comprehensive view of health service performance across all indicators and districts in seconds.

**When to use:**
- Initial data exploration
- Executive summaries
- High-level presentations

### 2. **Pattern Identification**
Spot systematic issues across multiple indicators or districts.

**Look for:**
- **Vertical red columns**: One indicator disrupted everywhere
- **Horizontal red rows**: One district struggling across multiple services
- **Red clusters**: Related indicators affected together (e.g., all maternal health services)

### 3. **Comparative Analysis**
Compare performance across different service types.

**Questions answered:**
- Which indicators are most disrupted?
- Which districts need most support?
- Are disruptions concentrated or widespread?

### 4. **Reporting and Documentation**
Export professional heatmaps for reports and presentations.

**Perfect for:**
- Monthly/quarterly reports
- Donor presentations
- Policy briefs
- Academic papers

---

## 🔍 Analysis Tips

### Reading Patterns

**Column patterns (indicator-level):**
- **All red column**: Indicator disrupted across most districts → systemic issue
- **Mixed column**: Some districts ok, others not → localized issues
- **All green column**: Indicator performing well everywhere → success story

**Row patterns (district-level):**
- **All red row**: District struggling with most services → needs urgent support
- **Mixed row**: District has specific service gaps → targeted intervention
- **All green row**: District performing well → learn from their practices

**Clusters:**
- **Related indicators together**: E.g., all ANC services red → maternal health crisis
- **Adjacent districts**: Regional issues (supply chain, staffing, etc.)

---

## 📊 Data Included

### Automatic Calculation
The heatmap automatically:
1. Takes ALL indicators in your dataset
2. Filters for the selected year
3. Calculates disruption category for each district × indicator combination
4. Displays using standard category colors

### Time Period
- Extracted from `period_id` column in your data
- Shows as "Jan-Dec 2025" if full year
- Shows as "Mar-Aug 2025" if partial year
- Shows as "2025" if no month data

### Languages
- Indicator names show in selected language (EN/FR)
- Toggle FR button updates heatmap labels

---

## 🎯 Advantages Over Single-Indicator Map

### Single-Indicator Map:
- ✅ Detailed spatial view
- ✅ Individual indicator focus
- ❌ Need to switch indicators one by one
- ❌ Can't see cross-indicator patterns

### Multi-Indicator Heatmap:
- ✅ See ALL indicators at once
- ✅ Spot cross-cutting issues quickly
- ✅ Compare across services
- ❌ Less geographic detail

**Use both together** for comprehensive analysis!

---

## 🖼️ Export Specifications

### File Details:
- **Format**: PNG
- **Resolution**: 300 DPI (publication quality)
- **Dimensions**: 16 inches wide × 10 inches tall
- **File size**: ~2-5 MB (depends on number of indicators/districts)
- **Filename**: `{country}_heatmap_{year}_{date}.png`

### Example Filename:
`sierra_leone_heatmap_2025_20251027.png`

### Suitable For:
- ✅ PowerPoint presentations (full slide)
- ✅ Word documents (landscape page)
- ✅ Academic publications
- ✅ Web display (automatically downsampled)
- ✅ Printing (high quality maintained)

---

## 🔄 Workflow Integration

### Typical Analysis Workflow:

1. **Start with Heatmap** 🗺️
   - Get overview of all services
   - Identify priority indicators/districts

2. **Drill down with Map** 🔍
   - Select specific indicator from heatmap
   - Switch to "Disruption Map" tab
   - Examine spatial patterns in detail

3. **Check Statistics** 📊
   - Review "Summary Statistics" tab
   - See distribution charts
   - Export specific indicator maps

4. **Export for Reporting** 💾
   - Download heatmap PNG
   - Download priority indicator maps
   - Include in reports/presentations

---

## 🎨 Customization

### Current Settings:
- **Height**: 800px (interactive view)
- **Download size**: 16×10 inches
- **Text rotation**: 45° for indicator names
- **Legend position**: Bottom (horizontal)

### To Modify:
Edit in `R/ui_components.R` and `app.R`:
- Change plot height: `plotOutput("heatmap_plot", height = "1000px")`
- Change download size: `width = 18, height = 12` in `ggsave()`
- Change text angle: `angle = 90` in `theme()`

---

## ⚙️ Technical Details

### Data Processing:
1. Filter data for selected year
2. Group by admin_area × indicator
3. Sum actual and expected counts
4. Calculate percent change
5. Assign disruption category
6. Join with indicator labels

### Rendering:
- Uses `ggplot2::geom_tile()` for heatmap
- `scale_fill_manual()` for category colors
- Rotated x-axis labels for readability
- White grid lines between tiles

### Performance:
- Fast rendering (< 2 seconds for typical dataset)
- No indicator selection required
- Automatically updates when year changes

---

## 🧪 Testing

### Test Scenarios:

**1. Full year data:**
- Upload data for Jan-Dec 2025
- Heatmap subtitle shows "Jan-Dec 2025"
- All 44 indicators displayed

**2. Partial year data:**
- Upload data for Mar-Aug 2025
- Heatmap subtitle shows "Mar-Aug 2025"
- Only indicators with data shown

**3. Language toggle:**
- Switch to FR
- Indicator names update to French
- Legend remains clear

**4. Download:**
- Click "Download Heatmap as PNG"
- File saves with correct filename
- Image is high quality and complete

---

## 🚀 Quick Start

```bash
cd /Users/claireboulange/Desktop/modules/disruption_mapping
R -e "shiny::runApp()"
```

1. Load your data (via Map tab)
2. Click **"Heatmap"** in sidebar
3. View comprehensive multi-indicator overview
4. Download for your reports!

---

**Your disruption mapping tool now provides both detailed single-indicator maps AND comprehensive multi-indicator heatmaps!** 🎨📊✨
