# Professional Map Export Guide

## ✅ New Professional Map Export Feature!

Your app now creates **publication-ready static maps** that look like professional reports, similar to your example image.

---

## 🎨 What You Get

### Before (Old Method)
- Screenshot of interactive leaflet map
- Lower quality
- No proper layout
- Interactive elements captured

### After (New Method)
- **Publication-quality static map**
- **High resolution** (300 DPI)
- **Professional layout** with:
  - ✅ Clear title (indicator name)
  - ✅ Subtitle (time period)
  - ✅ District labels with values
  - ✅ North arrow (top-right)
  - ✅ Scale bar (bottom-left)
  - ✅ Clean continuous legend at bottom
  - ✅ Explanatory caption
  - ✅ White background, clean borders

---

## 📋 Map Features

### Layout Elements

**Title**: Indicator name (e.g., "Antenatal client 4th visit")

**Subtitle**: Dynamic time period (e.g., "Jan-Dec 2025", "Mar-Oct 2024", or "2025")

**Map Area**:
- District polygons with color gradient
- **District names** labeled on each area
- **Percentage values** shown on each district
- White borders between districts

**North Arrow**: Fancy orienteering style (top-right)

**Scale Bar**: Metric scale with ticks (bottom-left, shows "80 km" etc.)

**Legend**:
- Horizontal color bar at bottom
- Shows range from -50% to +50%
- Labels: "-50%", "-40%", ..., "0%", "+10%", ..., "+50%"
- Title: "Percent change (actual vs expected)"

**Caption**:
"Red = disruption (below expected), Yellow = stable, Green = surplus (above expected).
Values capped at ±50%. Diagonal stripes = insufficient data."

---

## 🎯 How to Use

### 1. Install Required Package

```r
install.packages("ggspatial")
```

This adds professional north arrows and scale bars to maps.

### 2. Create a Map in the App

1. Launch app
2. Select country
3. Upload data or use database
4. Select year and indicator
5. Choose color scale (continuous recommended)

### 3. Click "Download Map as PNG"

- Button is at top of map box
- Creates professional static map
- Downloads automatically
- File format: `{country}_{indicator}_{year}_{date}.png`

Example: `nigeria_Antenatal_client_4th_visit_2025_20251027.png`

### 4. Open the Downloaded Map

- High quality 300 DPI
- 12 inches wide × 10 inches tall
- Perfect for reports, presentations, publications

---

## ⚙️ Technical Details

### Map Specifications

**Resolution**: 300 DPI (publication quality)

**Dimensions**:
- Width: 12 inches (3600 pixels at 300 DPI)
- Height: 10 inches (3000 pixels at 300 DPI)

**Format**: PNG with white background

**Color Palette**:
- Red → Orange → Yellow → Light Green → Green
- Matches leaflet interactive map
- Values capped at ±50% for better visibility

**Labels**:
- District names: 2.2pt font
- Percentage values: 2.5pt bold font
- Both in black for maximum readability

**Map Elements**:
- North arrow: Fancy orienteering style with grey/white fill
- Scale bar: Black ticks with metric units
- Legend: 20-unit wide color bar, 0.8-unit tall

---

## 🎨 Color Scale Options

### Continuous (Recommended)

Shows smooth gradient from red (disruption) to green (surplus).

**Advantages:**
- Shows exact percent change
- Professional appearance
- Matches example image
- Better for reports

**Legend**: Horizontal bar with breakpoints at -50%, -40%, ..., 0%, +10%, ..., +50%

### Categorical

Shows discrete categories with solid colors.

**Advantages:**
- Quick visual assessment
- Clear groupings
- Good for presentations

**Legend**: Shows 6 categories (Disruption >10%, Disruption 5-10%, etc.)

---

## 📊 What Gets Labeled

### District Labels Show:
1. **District name** (e.g., "Kenema")
2. **Percentage change** (e.g., "+20%")

Both appear on each district polygon for easy reading.

### Legend Shows:
- Full color gradient or categories
- Value ranges
- Clear explanation of what colors mean

### Title Area Shows:
- Indicator name in large bold text
- Time period in subtitle
- Country/level context

---

## 💡 Customization Options

The `save_map_png()` function accepts parameters:

```r
save_map_png(
  map_data = map_data(),           # Your map data
  filename = "output.png",          # Output file
  indicator_name = "Your Indicator",  # Title
  country_name = "Country",         # Country name
  year = "2025",                    # Year
  period_label = NULL,              # Custom subtitle (optional)
  color_scale = "continuous",       # "continuous" or "categorical"
  width = 12,                       # Width in inches
  height = 10                       # Height in inches
)
```

**Change dimensions:**
```r
width = 14, height = 12  # Larger map
width = 10, height = 8   # Smaller map
```

**Custom subtitle:**
```r
period_label = "Mar-Aug 2025"  # Override automatic time range detection
```

---

## 🔧 Troubleshooting

### "ggspatial package not found"

```r
install.packages("ggspatial")
```

### "Error in annotation_north_arrow"

Make sure `ggspatial` is loaded:
```r
library(ggspatial)
```

### Labels overlap

Automatic label placement works best with:
- 10-20 districts (optimal)
- Clean polygon shapes
- Not too many tiny districts

For very crowded maps, you might want to:
- Export at larger dimensions
- Use categorical view with fewer labels
- Adjust text size in the function

### Map looks different from interactive view

This is normal! The static map:
- Uses fixed colors (not dynamic)
- Shows all labels at once (not on hover)
- Has professional layout (not interactive controls)

Both views show the same data, just presented differently.

---

## 📐 Size Comparison

**12×10 inches @ 300 DPI:**
- **File size**: ~2-5 MB (depends on complexity)
- **Resolution**: 3600×3000 pixels
- **Print quality**: Excellent
- **Screen display**: Very sharp

**Perfect for:**
- Reports and documents
- PowerPoint presentations
- Journal publications
- Posters and infographics
- Web display (will be downsampled automatically)

---

## 🎯 Best Practices

### For Publications
1. Use **continuous color scale**
2. Keep at **12×10 inches**
3. Ensure district names are readable
4. Include in supplementary materials

### For Presentations
1. Either scale works
2. Slightly larger (14×12) for projection
3. High contrast works well on screens

### For Reports
1. Continuous scale for technical reports
2. Categorical for executive summaries
3. Standard 12×10 fits well in documents

### For Social Media
1. May need to crop/resize after export
2. Consider 10×10 for square posts
3. High DPI ensures quality after resizing

---

## 🔄 Workflow Integration

### 1. Data Analysis → Map Export

```r
# In your analysis script
source("launch_app.R")
# Upload data, create map, download
# Use downloaded PNG in your report
```

### 2. Batch Export (Future Feature)

Currently: One map at a time through app
Future: Could add script to batch export all indicators

### 3. Customize After Export

The PNG can be edited in:
- PowerPoint (add annotations)
- Photoshop/GIMP (adjust colors)
- Illustrator/Inkscape (vector editing of text)

---

## 📚 Comparison: Interactive vs Static

| Feature | Interactive (Leaflet) | Static (ggplot2) |
|---------|----------------------|------------------|
| **Use Case** | Exploration | Publication |
| **Zoom** | Yes | No |
| **Labels** | On hover | Always visible |
| **Export** | Not built for print | Print-ready |
| **File Size** | HTML (large) | PNG (smaller) |
| **Quality** | Screen only | 300 DPI print |
| **Sharing** | Share app link | Share image file |
| **Professional** | Medium | High |

**Both are valuable!**
- Interactive map: Explore and analyze
- Static map: Document and publish

---

## ✨ Example Output

Your exported map will look like:

```
┌─────────────────────────────────────────┐
│   Antenatal client 4th visit            │
│   Jan-Dec 2025                           │
├─────────────────────────────────────────┤
│                    ↑N                    │
│   ┌──────┬──────┬──────┐                │
│   │Green │Yellow│ Red  │                │
│   │+20% │  0%  │ -15% │                │
│   └──────┴──────┴──────┘                │
│   ├─────────┤ 80 km                     │
│                                          │
│  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓          │
│  -50%  -25%   0%   +25%  +50%          │
│  Percent change (actual vs expected)    │
│                                          │
│  Red = disruption, Green = surplus      │
└─────────────────────────────────────────┘
```

(Actual map is much more detailed with real district shapes!)

---

## 🚀 Next Steps

1. **Install ggspatial**: `install.packages("ggspatial")`
2. **Test the feature**: Load data and click download
3. **Check the output**: Open the PNG file
4. **Adjust if needed**: Change dimensions in code
5. **Use in reports**: Include in your publications!

---

**Your maps are now publication-ready!** 📊✨

This new export creates professional-quality maps suitable for:
- ✅ Journal publications
- ✅ Government reports
- ✅ Conference presentations
- ✅ Technical documentation
- ✅ Policy briefs

Just like your example image!
