# Hugging Face Spaces Deployment Guide

Complete step-by-step guide to deploy your Health Service Disruption Mapping app to Hugging Face Spaces.

---

## 📋 Prerequisites

✅ Hugging Face account (free at https://huggingface.co)
✅ Git installed on your computer
✅ Git LFS installed (for large GeoJSON files)
✅ Access token from Hugging Face (for pushing code)

### Install Git LFS

If you don't have Git LFS installed:

**macOS:**
```bash
brew install git-lfs
```

**Ubuntu/Debian:**
```bash
sudo apt-get install git-lfs
```

**Windows:**
Download from https://git-lfs.github.com/

---

## 🚀 Step 1: Create Your Space

### 1.1 Go to Hugging Face
Visit: https://huggingface.co/new-space

### 1.2 Fill Out the Form

**Owner:** `CIJBoulange` (your username)

**Space name:** Choose one:
- `health-disruption-mapping` ✅ Recommended
- `fastr-disruption-mapper`
- `service-disruption-viz`

**Short description:**
```
Interactive visualization of health service disruptions across administrative areas.
Compare actual vs expected service volumes for 52+ health indicators with bilingual support (EN/FR).
```

**License:** `apache-2.0` ✅ Recommended

**Space SDK:** ⚠️ **IMPORTANT: Select "Docker"**
- NOT Gradio
- NOT Static
- Must be **Docker** because your app uses a Dockerfile

**Space hardware:** `Free` (CPU - basic) ✅ Start here
- You can upgrade later if needed
- Free tier is sufficient for most use cases

**Dev Mode:** Leave **disabled** (not needed)

**Visibility:**
- ✅ **Public** - Anyone can access (recommended for sharing)
- 🔒 **Private** - Only you or your organization

### 1.3 Click "Create Space"

---

## 🔑 Step 2: Get Your Hugging Face Token

### 2.1 Generate Access Token
1. Go to https://huggingface.co/settings/tokens
2. Click **"New token"**
3. Name it: `disruption-mapping-deploy`
4. Type: Select **"Write"** (allows pushing code)
5. Click **"Generate token"**
6. **COPY THE TOKEN** - you'll need it soon!

**⚠️ Important:** Save this token somewhere safe. You won't be able to see it again!

---

## 📦 Step 3: Prepare Your Files

### 3.1 Navigate to Your App Directory

```bash
cd /Users/claireboulange/Desktop/modules/disruption_mapping
```

### 3.2 Rename README for Hugging Face

We need the special Hugging Face README with metadata:

```bash
# Backup original README
mv README.md README_LOCAL.md

# Use Hugging Face README
mv README_HUGGINGFACE.md README.md
```

### 3.3 Verify Required Files

Make sure these files exist:

```bash
ls -la | grep -E "(Dockerfile|\.dockerignore|app\.R|README\.md)"
```

You should see:
- ✅ `Dockerfile`
- ✅ `.dockerignore`
- ✅ `app.R`
- ✅ `README.md`

---

## 🔄 Step 4: Initialize Git and Push to Hugging Face

### 4.1 Initialize Git Repository

```bash
# Initialize git (if not already done)
git init

# Initialize Git LFS (required for large GeoJSON files)
git lfs install

# Add all files
git add .

# Check what will be committed
git status
```

**Note:** The repository is already configured to use Git LFS for large GeoJSON files (98MB total). The `.gitattributes` file tracks `data/geojson/*.geojson` with LFS automatically.

### 4.2 Create Initial Commit

```bash
git commit -m "Initial deployment of Health Service Disruption Mapping app"
```

### 4.3 Add Hugging Face Remote

Replace `YOUR-SPACE-NAME` with the name you chose in Step 1:

```bash
git remote add space https://huggingface.co/spaces/CIJBoulange/YOUR-SPACE-NAME
```

**Example:**
```bash
git remote add space https://huggingface.co/spaces/CIJBoulange/health-disruption-mapping
```

### 4.4 Push to Hugging Face

```bash
git push --force space main
```

**When prompted for credentials:**
- **Username:** `CIJBoulange` (your Hugging Face username)
- **Password:** Paste your access token from Step 2

**Note:** Git LFS files will be automatically uploaded to Hugging Face. The push may take longer than usual (5-10 minutes) due to the 98MB of GeoJSON data. Hugging Face natively supports Git LFS, so no additional configuration is needed.

---

## ⏱️ Step 5: Monitor Deployment

### 5.1 Check Build Status

1. Go to your Space URL:
```
https://huggingface.co/spaces/CIJBoulange/YOUR-SPACE-NAME
```

2. Look for the **"Building"** status at the top
   2. Building takes 5-15 minutes (Docker needs to install R packages)
   3. You'll see logs showing installation progress

3. **Building stages:**
   2. ⏳ Pulling Docker base image (\~2 min)
   3. ⏳ Installing system dependencies (\~3 min)
   4. ⏳ Installing R packages (\~5-8 min)
   5. ⏳ Copying app files (\~30 sec)
   6. ⏳ Starting Shiny server (\~30 sec)

### 5.2 Wait for "Running" Status

✅ **When successful**, you'll see:
- Status changes to **"Running"**
- Your app appears in an iframe
- You can interact with it!

❌ **If build fails**, check the logs (see Troubleshooting below)

---

## 🎉 Step 6: Test Your Deployed App

### 6.1 Basic Tests

1. **Load the app** - Wait for interface to appear
2. **Select country** - Choose from dropdown
3. **Upload test data** - Use a small CSV file first
4. **Select year and indicator**
5. **View map** - Check if map renders
6. **Try heatmap** - Switch to Heatmap tab
7. **Toggle language** - Click FR/EN button
8. **Download map** - Test PNG export

### 6.2 Share Your Space

Once running, share the URL:
```
https://huggingface.co/spaces/CIJBoulange/YOUR-SPACE-NAME
```

---

## 🔧 Troubleshooting

### Issue 1: Build Fails - "Cannot find Dockerfile"

**Cause:** Dockerfile not in root directory

**Fix:**
```bash
# Make sure Dockerfile is in root
ls -la Dockerfile

# If missing, check location
find . -name "Dockerfile"
```

### Issue 2: Build Fails - R Package Installation Error

**Cause:** Missing system dependencies

**Fix:** Check your Dockerfile has all dependencies (it should - we've included them)

### Issue 3: App Runs But Won't Load Data

**Cause:** Missing data files or permissions

**Fix:**
```bash
# Ensure data folder is included
ls -la data/geojson/*.geojson

# If missing, check .dockerignore doesn't exclude data/
grep -E "^data" .dockerignore
```

### Issue 4: "Failed to Build" - Out of Memory

**Cause:** Free tier has memory limits

**Fix:**
1. Go to your Space settings
2. Upgrade hardware to "CPU - upgrade" (small fee)
3. Rebuild

### Issue 5: App is Slow or Unresponsive

**Cause:** Free tier CPU is limited

**Solutions:**
- Use smaller test datasets initially
- Upgrade to paid hardware if needed
- Optimize data before upload

### Issue 6: Can't Push to Hugging Face

**Cause:** Authentication failed

**Fix:**
```bash
# Reset credentials
git remote remove space
git remote add space https://huggingface.co/spaces/CIJBoulange/YOUR-SPACE-NAME

# Try push again with correct token
git push --force space main
```

### Issue 7: Git LFS Files Not Uploading

**Cause:** Git LFS not properly initialized

**Fix:**
```bash
# Ensure Git LFS is installed
git lfs install

# Verify LFS tracking
cat .gitattributes
# Should show: data/geojson/*.geojson filter=lfs diff=lfs merge=lfs -text

# Check which files are tracked by LFS
git lfs ls-files
# Should list all 17 GeoJSON files

# If files aren't tracked, re-add them
git rm --cached data/geojson/*.geojson
git add data/geojson/*.geojson
git commit -m "Fix LFS tracking for GeoJSON files"
git push space main
```

### Issue 8: Repository Size Too Large Error

**Cause:** Files weren't tracked by LFS before commit

**Symptoms:** Error like "remote: error: File X is 26.00 MB; this exceeds GitHub's file size limit"

**Fix:**
This shouldn't happen if you followed the setup correctly. If it does:
```bash
# The repository is already configured with LFS
# Just make sure Git LFS is installed
git lfs install

# Push again - LFS should handle it
git push space main
```

---

## 🔄 Step 7: Update Your App

### To Deploy Updates:

```bash
# Make your changes to the code
# Then:

git add .
git commit -m "Description of your changes"
git push space main
```

**The Space will automatically rebuild** with your changes!

---

## ⚙️ Optional: Configure Space Settings

### Go to Space Settings:
```
https://huggingface.co/spaces/CIJBoulange/YOUR-SPACE-NAME/settings
```

### Available Options:

**Hardware:**
- Upgrade from Free to paid CPU/GPU if needed
- Only needed for high traffic or large datasets

**Visibility:**
- Switch between Public and Private
- Control who can access

**Environment Variables:**
- Add secrets (e.g., database credentials)
- Set `USE_DATABASE=true` if using PostgreSQL

**Sleep Time:**
- Free Spaces sleep after 48h of inactivity
- Wake up automatically when accessed

---

## 📊 Monitor Usage

### View Space Analytics:

1. Go to your Space
2. Check "Visitors" count
3. Monitor build history
4. View error logs if issues occur

---

## 💡 Best Practices

### 1. Test Locally First
```bash
# Always test Docker build locally before pushing
docker build -t disruption-mapping .
docker run -p 3838:3838 disruption-mapping
# Visit http://localhost:3838
```

### 2. Use Small Test Data
- Keep test CSV files small (\<10MB)
- Test with 1-2 years of data initially
- Full datasets can be uploaded by users

### 3. Document Your Updates
- Use clear commit messages
- Update README when adding features
- Keep CHANGELOG if needed

### 4. Monitor Performance
- Check app responsiveness
- Monitor memory usage in logs
- Upgrade hardware if needed

---

## 🎯 Quick Reference Commands

### Clone Your Space Locally
```bash
git clone https://huggingface.co/spaces/CIJBoulange/YOUR-SPACE-NAME
cd YOUR-SPACE-NAME
```

### Push Updates
```bash
git add .
git commit -m "Your update message"
git push
```

### Force Rebuild (without code changes)
```bash
git commit --allow-empty -m "Force rebuild"
git push
```

### Check Remote URL
```bash
git remote -v
```

---

## 📞 Getting Help

### Hugging Face Resources:
- **Docs**: https://huggingface.co/docs/hub/spaces
- **Docker Spaces Guide**: https://huggingface.co/docs/hub/spaces-sdks-docker
- **Community Forum**: https://discuss.huggingface.co/

### App-Specific Issues:
- Check `documentation/` folder
- Review app logs in Hugging Face
- Test locally with Docker first

---

## 🎉 Success Checklist

After deployment, verify:

- ✅ Space shows "Running" status
- ✅ App interface loads
- ✅ Can select country
- ✅ Can upload CSV data
- ✅ Maps render correctly
- ✅ Heatmap displays
- ✅ FR/EN toggle works
- ✅ PNG download functions
- ✅ No console errors

---

## 🚀 Next Steps

Once deployed:

1. **Test thoroughly** with real data
2. **Share the URL** with your team
3. **Gather feedback** from users
4. **Monitor usage** and performance
5. **Update as needed** with git push

---

**Your app is now live on Hugging Face Spaces!** 🎊

**Example URL:**
```
https://huggingface.co/spaces/CIJBoulange/health-disruption-mapping
```

Anyone with the link can now use your disruption mapping tool! 🗺️✨
