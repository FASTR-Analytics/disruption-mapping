# Deployment

## Hugging Face Spaces

The application is deployed on Hugging Face Spaces using Docker.

### Prerequisites

- Hugging Face account
- Git with LFS installed
- Access token with write permissions

### Deployment Steps

1. **Create a new Space**

   - Go to [huggingface.co/new-space](https://huggingface.co/new-space)
   - Select **Docker** as the SDK
   - Choose **Public** or **Private** visibility

2. **Configure Git Remote**

   ```bash
   git remote add space https://huggingface.co/spaces/YOUR_USERNAME/YOUR_SPACE_NAME
   ```

3. **Push to Deploy**

   ```bash
   git push space main
   ```

4. **Monitor Build**

   - Check the Space page for build status
   - Build takes 5-15 minutes (R package installation)

### Updating the App

```bash
git add .
git commit -m "Your update message"
git push space main
```

The Space automatically rebuilds on push.

## Docker Configuration

### Dockerfile Overview

```dockerfile
FROM rocker/shiny-verse:4.3.1

# System dependencies
RUN apt-get update && apt-get install -y \
    libgdal-dev libgeos-dev libproj-dev ...

# R packages
RUN R -e "install.packages(c('shinydashboard', 'sf', 'leaflet', ...))"

# Copy app files
COPY app.R /app/
COPY R/ /app/R/
COPY data/ /app/data/

EXPOSE 7860
CMD ["R", "-e", "shiny::runApp(host='0.0.0.0', port=7860)"]
```

### Port Configuration

Hugging Face Spaces requires port **7860**.

## Local Development

### Run Locally with Docker

```bash
docker build -t disruption-mapping .
docker run -p 3838:7860 disruption-mapping
```

Visit `http://localhost:3838`

### Run Locally with R

```r
shiny::runApp()
```

## Troubleshooting

### Build Fails

- Check Dockerfile syntax
- Ensure all R packages are available on CRAN
- Review build logs on Hugging Face

### App Crashes

- Check memory limits (free tier is limited)
- Reduce data size if needed
- Review error logs in Space settings
