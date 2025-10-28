# Deployment Guide - Health Service Disruption Mapping

This guide covers running the app locally and deploying to Hugging Face Spaces.

---

## 🚀 Running Locally

### Prerequisites

Install required R packages:

```r
# Core packages
install.packages(c(
  "shiny",
  "shinydashboard",
  "shinyWidgets",
  "dplyr",
  "sf",
  "leaflet",
  "tidyr",
  "DT",
  "ggplot2",
  "htmlwidgets",
  "webshot2"
))

# Optional: Database support
install.packages(c("DBI", "RPostgres"))
```

### Option 1: RStudio Terminal (Recommended)

```bash
# In RStudio Terminal, navigate to app directory
cd /Users/claireboulange/Desktop/modules/disruption_mapping

# Run the app
R -e "shiny::runApp(launch.browser = TRUE)"
```

### Option 2: R Console

```r
# Set working directory
setwd("/Users/claireboulange/Desktop/modules/disruption_mapping")

# Run the app
shiny::runApp(launch.browser = TRUE)
```

### Option 3: Quick Launch Script

```r
# From the app directory
source("launch_app.R")
```

### Option 4: RStudio "Run App" Button

1. Open `app.R` in RStudio
2. Click the "Run App" button in the top-right corner

---

## 📦 Testing Map Export Feature

The app includes a "Download Map as PNG" button. To test it:

1. **Install webshot2** (if not already installed):
   ```r
   install.packages("webshot2")
   ```

2. **Launch the app** and load a map

3. **Click "Download Map as PNG"**
   - Map will be saved with scale bar and north arrow
   - Filename format: `{country}_{indicator}_{year}_{date}.png`
   - Resolution: 1200x800 pixels at 2x zoom (high quality)

**Troubleshooting:**
- If download fails, ensure webshot2 is installed
- On first use, webshot2 may need to download Chromium (~100MB)
- Allow a few seconds for the image to generate

---

## 🌐 Deploying to Hugging Face Spaces

### Step 1: Prepare Your Repository

Your app is already configured with:
- ✅ `Dockerfile` - Docker configuration
- ✅ `.dockerignore` - Optimized builds
- ✅ Modular structure - Clean organization
- ✅ All dependencies specified

### Step 2: Create a Hugging Face Space

1. **Go to Hugging Face**: https://huggingface.co/spaces

2. **Create New Space**:
   - Click "Create new Space"
   - Choose a name: `health-disruption-mapping` (or your preference)
   - License: Choose appropriate license (e.g., MIT)
   - **SDK: Docker** (IMPORTANT!)
   - Click "Create Space"

### Step 3: Push Your Code

#### Option A: Using Git (Recommended)

```bash
# Navigate to your app directory
cd /Users/claireboulange/Desktop/modules/disruption_mapping

# Initialize git (if not already a repo)
git init

# Add Hugging Face remote (replace USERNAME and SPACENAME)
git remote add hf https://huggingface.co/spaces/USERNAME/SPACENAME

# Add all files
git add .

# Commit
git commit -m "Initial deployment of disruption mapping app"

# Push to Hugging Face
git push hf main
```

#### Option B: Using Hugging Face Web Interface

1. Go to your Space's "Files" tab
2. Click "Add file" → "Upload files"
3. Upload these files/folders:
   - `app.R`
   - `launch_app.R`
   - `.env`
   - `Dockerfile`
   - `.dockerignore`
   - `R/` folder (all files)
   - `www/` folder (CSS)
   - `data/geojson/` folder (all GeoJSON files)

### Step 4: Configure Space Settings

1. **Go to Settings tab** in your Space

2. **Set Space Hardware** (if needed):
   - Free tier (CPU basic) works for most use cases
   - Upgrade to CPU upgrade or GPU if you have large datasets

3. **Environment Variables** (optional):
   - If using database, set these secrets:
     - `DB_HOST`
     - `DB_PORT`
     - `DB_NAME`
     - `DB_USER`
     - `DB_PASSWORD`
     - `USE_DATABASE=TRUE`

4. **Set Space to Public or Private** as needed

### Step 5: Monitor Deployment

1. **Build Progress**:
   - Go to "Logs" tab
   - Watch Docker build process
   - Build takes ~10-20 minutes first time
   - Subsequent builds are faster (cached layers)

2. **Check for Errors**:
   - If build fails, check logs for missing dependencies
   - Common issues:
     - Missing R package in Dockerfile
     - GeoJSON files not uploaded
     - Typos in file paths

3. **App Running**:
   - When build succeeds, you'll see: `Running on http://0.0.0.0:3838`
   - Space will show "Running" status
   - Click "App" tab to view your live app

### Step 6: Access Your Deployed App

Your app will be available at:
```
https://huggingface.co/spaces/USERNAME/SPACENAME
```

Share this URL with colleagues!

---

## 🔧 Post-Deployment Configuration

### Update Data

To update GeoJSON files or data:

```bash
# Add new geojson files to data/geojson/
git add data/geojson/new_country_backbone.geojson

# Commit and push
git commit -m "Add new country boundaries"
git push hf main
```

The Space will automatically rebuild and redeploy.

### Update Indicators

Edit `R/indicators.R` to add new indicators:

```r
indicator_labels <- rbind(
  indicator_labels,
  data.frame(
    indicator_id = "new_indicator",
    indicator_name = "New Indicator Name",
    stringsAsFactors = FALSE
  )
)
```

Then commit and push:
```bash
git add R/indicators.R
git commit -m "Add new indicator"
git push hf main
```

### Update App Code

Make changes to any `.R` files, then:

```bash
git add .
git commit -m "Description of changes"
git push hf main
```

---

## 🐛 Troubleshooting

### Local Issues

**App won't start - database error:**
```bash
# Check .env file
cat .env

# Ensure USE_DATABASE=FALSE if not using database
# Edit .env to set USE_DATABASE=FALSE
```

**Map won't display:**
- Ensure GeoJSON files are in `data/geojson/`
- Check file names match pattern: `{country}_backbone.geojson`
- Verify GeoJSON has `name`, `level`, and `geometry` fields

**Map export fails:**
```r
# Install webshot2
install.packages("webshot2")

# First time may require Chromium download
library(webshot2)
```

### Deployment Issues

**Build fails - missing package:**
- Add package to `Dockerfile` in appropriate section
- Rebuild by pushing updated Dockerfile

**App loads but map is blank:**
- Check Logs tab for errors
- Ensure `data/geojson/` folder uploaded correctly
- Verify file permissions in Docker

**App is slow:**
- Consider upgrading Space hardware (Settings → Hardware)
- Optimize GeoJSON files (simplify geometries if needed)
- Use database for large datasets

**File upload doesn't work:**
- 2GB limit applies
- For larger files, use database instead
- Check Hugging Face storage limits

---

## 📊 Performance Optimization

### For Large Datasets

1. **Use PostgreSQL Database**:
   - See `docs/DATABASE_SETUP_GUIDE.md`
   - Much faster than CSV upload
   - No file size limits

2. **Simplify GeoJSON**:
   ```r
   # In R, simplify geometries
   library(sf)
   geo <- st_read("country_backbone.geojson")
   geo_simple <- st_simplify(geo, dTolerance = 0.01)
   st_write(geo_simple, "country_backbone_simple.geojson")
   ```

3. **Optimize Images**:
   - GeoJSON files can be large
   - Consider using TopoJSON instead (smaller)
   - Or simplify polygon geometries

---

## 🔒 Security Best Practices

### Database Credentials

**Never commit credentials to git!**

Use Hugging Face Secrets:
1. Go to Space Settings → Variables and secrets
2. Add secrets (not visible in logs):
   - `DB_PASSWORD`
   - `DB_USER`
3. Reference in `.env`:
   ```
   DB_PASSWORD=${DB_PASSWORD}
   DB_USER=${DB_USER}
   ```

### Access Control

- Set Space to **Private** if data is sensitive
- Use Hugging Face Pro for team access controls
- Add authentication layer if needed

---

## 📝 Maintenance

### Regular Updates

```bash
# Pull latest changes
git pull hf main

# Make updates locally
# Test thoroughly

# Push updates
git add .
git commit -m "Update description"
git push hf main
```

### Monitor Space

- Check "Analytics" tab for usage stats
- Review "Logs" for errors
- Update dependencies periodically

### Backup

```bash
# Backup entire app
tar -czf disruption_mapping_backup_$(date +%Y%m%d).tar.gz \
  app.R launch_app.R R/ www/ data/ Dockerfile .env

# Store backup safely
```

---

## 🎯 Quick Reference

### Local Testing
```bash
cd /Users/claireboulange/Desktop/modules/disruption_mapping
R -e "shiny::runApp(launch.browser = TRUE)"
```

### Deploy to HF
```bash
git add .
git commit -m "Your message"
git push hf main
```

### Update Single File
```bash
git add R/indicators.R
git commit -m "Update indicators"
git push hf main
```

### Check Logs
- Go to Space → Logs tab
- Monitor build and runtime logs

---

## 📚 Additional Resources

- **Hugging Face Spaces Docs**: https://huggingface.co/docs/hub/spaces
- **Docker Spaces Guide**: https://huggingface.co/docs/hub/spaces-sdks-docker
- **Shiny Deployment**: https://shiny.rstudio.com/articles/deployment-web.html

---

## ✅ Deployment Checklist

Before deploying:

- [ ] All R packages listed in Dockerfile
- [ ] GeoJSON files in `data/geojson/`
- [ ] `.env` file configured (USE_DATABASE=FALSE for file mode)
- [ ] Test locally with `shiny::runApp()`
- [ ] Test map export functionality
- [ ] Update README.md with deployment URL
- [ ] Git repo initialized and clean
- [ ] No sensitive data in git history
- [ ] Dockerfile builds successfully locally (optional test)

After deploying:

- [ ] Check build logs for errors
- [ ] Test app functionality on Hugging Face
- [ ] Test file upload (if not using database)
- [ ] Test all indicators
- [ ] Test map export
- [ ] Share URL with team
- [ ] Document any custom configuration

---

**Questions?** Check the main README.md or docs/ folder for more information.
