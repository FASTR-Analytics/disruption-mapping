# Continuous Color Scale Feature - Quick Guide

## What Changed

The app now has a **continuous color scale** option with **values displayed directly on the map**!

### New Features

1. **Color Scale Selector**
   - **Continuous**: Smooth red-yellow-green gradient based on exact percent change
   - **Categories**: Original 6-category system (Disruption >10%, 5-10%, Stable, etc.)

2. **Show Values on Map Checkbox**
   - When checked: Displays the actual percent change value (e.g., "-15.2%") on each administrative area
   - Labels have white outline/shadow for readability
   - Works with both continuous and categorical scales

3. **Better Color Gradient**
   - Red (negative): Disruption, services below expected
   - Yellow (zero): Stable, services match expected
   - Green (positive): Surplus, services above expected
   - Smooth transitions between colors

## Using the Continuous Scale

### Step-by-Step

1. **Launch the app**
   ```r
   source("launch_app.R")
   ```

2. **Select your data**
   - Country: Nigeria
   - Admin Level: 2 or 3
   - Upload your disruption CSV

3. **Choose Continuous Scale**
   - Color Scale: Select "Continuous"
   - Check "Show Values on Map"

4. **Explore**
   - See exact percent change for each area
   - Values printed directly on the map
   - Hover for detailed information
   - Color intensity shows magnitude of change

### Visual Guide

#### Continuous Scale
```
  -50%        -25%         0%        +25%       +50%
   ├────────────┼────────────┼────────────┼────────────┤
   🔴 Dark Red   🟠 Orange    🟡 Yellow    🟢 Lt Green  🟢 Dk Green

   Severe      Moderate     Stable     Moderate    High
   Disruption  Disruption              Surplus    Surplus
```

#### What You'll See on the Map
- **Areas**: Colored by continuous gradient
- **Labels**: "-12.5%", "+8.3%", "-22.1%", etc.
- **Legend**: Continuous color bar with % values
- **Hover**: Detailed popup with area name, change %, actual, expected

## When to Use Each Scale

### Use Continuous Scale When:
✅ You need **precise values** for planning
✅ You want to see **exact percent changes** at a glance
✅ You're preparing **reports or presentations** that need specific numbers
✅ You're comparing **subtle differences** between areas
✅ You want **quick visual scanning** of many values

**Example:** "I need to know exactly which LGAs have >15% disruption for targeted interventions"

### Use Categorical Scale When:
✅ You want a **simple overview** of problem areas
✅ You're doing **initial screening** of data
✅ You prefer **clear groups** over continuous values
✅ You're presenting to **non-technical audiences**

**Example:** "Show me all areas with major disruptions vs stable areas"

## Examples

### Example 1: Nigeria State-Level with Continuous Scale

```r
# Settings in app:
# - Country: Nigeria
# - Admin Level: Level 2 (State/Province)
# - Upload: M3_disruptions_analysis_admin_area_2.csv
# - Year: 2024
# - View: All Indicators
# - Color Scale: Continuous
# - Show Values on Map: ✓

# Result:
# Map shows Nigerian states colored on red-yellow-green gradient
# Each state has its percent change value displayed
# e.g., "North Central Zone: -12.3%" visible on the polygon
```

### Example 2: Nigeria LGA-Level, Specific Indicator

```r
# Settings in app:
# - Country: Nigeria
# - Admin Level: Level 3 (District/LGA)
# - Upload: M3_disruptions_analysis_admin_area_3.csv
# - Year: 2024
# - View: By Indicator → anc1
# - Color Scale: Continuous
# - Show Values on Map: ✓

# Result:
# Detailed LGA map showing ANC1 disruption patterns
# Each LGA labeled with its specific percent change
# Easy to identify which LGAs need attention
```

### Example 3: Toggling Between Scales

```r
# Start with Categorical:
# - Quick overview of problem areas
# - See how many areas are in each category
# - Identify regions of concern

# Switch to Continuous:
# - See exact values for each area
# - Identify areas just above/below thresholds
# - Get precise numbers for reporting
```

## Benefits of Continuous Scale

### 1. **Precision**
- See exact values: -12.3% vs -11.8%
- No information lost to categorization
- Better for decision-making

### 2. **Quick Scanning**
- Values printed directly on areas
- No need to hover or click
- Scan dozens of areas in seconds

### 3. **Better Visualization**
- Smooth color transitions
- Intensity matches severity
- Easy to spot patterns

### 4. **Report-Ready**
- Screenshot shows all values
- No separate table needed
- Professional appearance

## Tips for Best Results

### 1. **Adjusting Label Display**
```
Too cluttered?
→ Uncheck "Show Values on Map"
→ Hover over areas for values instead
→ Or zoom in for level 3 data
```

### 2. **Reading the Colors**
```
Darker Red    = Worse disruption (-30%, -50%)
Light Red     = Moderate disruption (-10%, -15%)
Yellow        = Stable (-2%, +3%)
Light Green   = Moderate surplus (+10%, +15%)
Dark Green    = High surplus (+30%, +50%)
```

### 3. **Comparing Areas**
```
Similar colors = Similar performance
Adjacent values = Easy comparison
Color pattern  = Regional trends
```

### 4. **Exporting Results**
```
1. Set up continuous scale with labels
2. Zoom to desired view
3. Take screenshot (map shows all values)
4. Use for reports/presentations
```

## Technical Details

### Color Palette
- Based on ColorBrewer diverging palette
- 5-color scheme: Red → Orange → Yellow → Light Green → Dark Green
- Optimized for colorblind accessibility

### Value Ranges
- Scale: -100% to +100%
- Values beyond range are capped
- Most data falls in -50% to +50% range

### Label Styling
- **Font**: Sans-serif, bold, 11px
- **Color**: Black text
- **Shadow**: White outline for readability against any background
- **Position**: Polygon centroid (geographic center)

### Performance
- Labels calculated on-the-fly
- Centroids computed automatically
- Fast rendering even with 100+ areas

## Troubleshooting

### Labels Not Showing
**Issue**: Checkbox checked but no labels visible
**Solutions:**
- Zoom in if areas are small
- Check that data has valid percent_change values
- Try toggling checkbox off/on

### Labels Overlapping
**Issue**: Too many areas, labels overlap
**Solutions:**
- Uncheck "Show Values on Map"
- Use hover tooltips instead
- Zoom into specific regions
- Consider using Level 2 instead of Level 3

### Colors Don't Match Values
**Issue**: Area shows -15% but appears yellow
**Solutions:**
- Check you selected "Continuous" not "Categories"
- Reload data
- Check the legend scale

### Can't See Some Labels
**Issue**: Labels blend into background
**Solutions:**
- White shadow should prevent this
- Try different basemap if needed
- Zoom in to enlarge areas

## Comparison: Continuous vs Categorical

| Feature | Continuous | Categorical |
|---------|-----------|-------------|
| Precision | Exact values | Grouped ranges |
| Quick scanning | ✓✓✓ Values visible | ✓ Need to hover |
| Simplicity | ✓ Nuanced | ✓✓✓ Very simple |
| Detail level | High | Medium |
| Best for | Reports, analysis | Overview, screening |
| Color scheme | Smooth gradient | Distinct colors |
| Decision-making | Precise targeting | General priorities |

## Real-World Workflow

### Scenario: Planning Intervention Priorities

1. **Start with Categorical Scale**
   - Quick overview: How many areas disrupted?
   - Identify general problem regions
   - Decision: "North region needs attention"

2. **Switch to Continuous Scale**
   - Which specific LGAs are worst affected?
   - Read values: "-18.2%", "-15.7%", "-12.3%"
   - Decision: "Target LGAs with >15% disruption first"

3. **Enable Value Labels**
   - Print/screenshot for team meeting
   - Everyone can see exact values
   - Decision: "Allocate resources to top 10 LGAs"

4. **Export Data Table**
   - Get full list with values
   - Sort by disruption level
   - Decision: "Create intervention timeline"

## Next Steps

1. **Try it now:**
   ```r
   source("launch_app.R")
   # Upload Nigeria data
   # Select "Continuous" scale
   # Check "Show Values on Map"
   ```

2. **Compare scales:**
   - Try same data with both scales
   - See which works better for your needs
   - Use both in different contexts

3. **Create reports:**
   - Use continuous scale for precision
   - Screenshot with labels for documentation
   - Export data table for details

---

**Ready to try?** Launch the app and select "Continuous" from the Color Scale dropdown!

The continuous scale is now the **default** setting, giving you precise values right from the start.
