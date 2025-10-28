# Quick Start Guide

## ✅ New Features Added

1. **Download Map as PNG** button
2. **Scale bar** on map (bottom-left)
3. **North arrow** on map (top-right)
4. **44 updated indicators** from your list

---

## 🚀 Run App Locally

### In RStudio Terminal:

```bash
cd /Users/claireboulange/Desktop/modules/disruption_mapping
R -e "shiny::runApp(launch.browser = TRUE)"
```

### Or in R Console:

```r
setwd("/Users/claireboulange/Desktop/modules/disruption_mapping")
shiny::runApp(launch.browser = TRUE)
```

### Or Quick Launch:

```r
source("launch_app.R")
```

---

## 📦 Install Map Export Dependencies

**Required for PNG download feature:**

```r
install.packages("webshot2")
install.packages("htmlwidgets")
```

On first use, webshot2 will download Chromium (~100MB).

---

## 🌐 Deploy to Hugging Face Spaces

### Quick Steps:

1. **Create Space**: https://huggingface.co/spaces
   - Choose **Docker SDK** (important!)

2. **Push Code**:
   ```bash
   cd /Users/claireboulange/Desktop/modules/disruption_mapping
   git init
   git remote add hf https://huggingface.co/spaces/YOUR_USERNAME/YOUR_SPACE
   git add .
   git commit -m "Initial deployment"
   git push hf main
   ```

3. **Wait for Build** (~15-20 minutes first time)

4. **Access Your App**: `https://huggingface.co/spaces/YOUR_USERNAME/YOUR_SPACE`

---

## 🗺️ Using the Map Features

**Scale Bar**: Automatically shows at bottom-left of map
- Displays metric scale (kilometers)
- Updates as you zoom

**North Arrow**: Shows at top-right of map
- Black arrow points north
- Helps with map orientation

**Download PNG**:
1. Load your data and create a map
2. Click "Download Map as PNG" button (top of map box)
3. Wait 2-5 seconds for generation
4. File downloads with format: `{country}_{indicator}_{year}_{date}.png`
5. Image includes scale bar, north arrow, legend, and labels

---

## 📁 File Structure Reference

```
disruption_mapping/
├── app.R                  # Main app (run this)
├── launch_app.R           # Quick launch
├── Dockerfile             # For Hugging Face deployment
├── R/                     # Code modules
│   ├── indicators.R       # 44 indicators defined here
│   ├── data_functions.R
│   ├── map_functions.R    # Scale + north arrow
│   └── ui_components.R
├── www/
│   └── custom.css         # FASTR theme
├── data/
│   └── geojson/           # 17 countries
└── docs/
    └── DEPLOYMENT_GUIDE.md # Full deployment guide
```

---

## 🐛 Troubleshooting

**App won't start - USE_DATABASE error:**
- Check `.env` file has `USE_DATABASE=FALSE`

**Map download doesn't work:**
```r
install.packages("webshot2")
```

**GeoJSON not loading:**
- Ensure files are in `data/geojson/`
- File names must match: `{country}_backbone.geojson`

---

## 📊 What Changed

**R/indicators.R**: Updated with 44 indicators including:
- ANC variations (before/after 20 weeks)
- Delivery types (vaginal, c-section, partograph)
- GBV cases and referrals
- Diabetes, hypertension, diarrhoea
- SAM treatment
- Maternal/neonatal/under-5 deaths
- Vitamin A, LLIN distribution

**R/map_functions.R**: Added:
- `addScaleBar()` for metric scale
- Custom north arrow (SVG)
- `save_map_png()` function for export

**app.R**: Added:
- `htmlwidgets` library
- `webshot2` check
- Download button handler
- Fixed USE_DATABASE logic

**Dockerfile**: Added:
- `htmlwidgets` and `webshot2` packages
- Chromium browser for rendering

---

## ⚡ Pro Tips

1. **Test locally first** before deploying
2. **Use database** for files >500MB
3. **Simplify GeoJSON** if maps load slowly
4. **Download maps** at high zoom for better detail
5. **Keep Hugging Face Space public** for easy sharing

---

For detailed deployment instructions, see `docs/DEPLOYMENT_GUIDE.md`
