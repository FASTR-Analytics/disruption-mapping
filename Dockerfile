# Use rocker/shiny-verse which includes tidyverse packages
FROM rocker/shiny-verse:4.3.1

# Install system dependencies for geospatial packages
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libsodium-dev \
    libgit2-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libudunits2-dev \
    libpq-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

# Set CRAN repo to use binary packages (faster installation)
RUN echo "options(repos = c(CRAN = 'https://packagemanager.posit.co/cran/__linux__/jammy/latest'), download.file.method = 'libcurl')" >> /usr/local/lib/R/etc/Rprofile.site

# Install core Shiny and UI packages
RUN R -e "install.packages(c('shinydashboard', 'shinyWidgets', 'DT'), Ncpus = 2)"

# Install data manipulation packages
RUN R -e "install.packages(c('tidyr', 'rlang', 'data.table'), Ncpus = 2)"

# Install geospatial packages
RUN R -e "install.packages(c('sf', 'leaflet'), Ncpus = 2)"

# Install plotting packages
RUN R -e "install.packages(c('ggplot2', 'scales', 'ggrepel'), Ncpus = 2)"

# Install htmlwidgets and ggspatial for professional map export
RUN R -e "install.packages(c('htmlwidgets', 'ggspatial'), Ncpus = 2)"

# Install pattern packages for diagonal stripes on insufficient data (optional - continue if fails)
RUN R -e "install.packages(c('ggpattern', 'leaflet.extras2'), Ncpus = 2)" || echo "Pattern packages failed to install - will use solid colors"

# Install database packages (optional but recommended)
RUN R -e "install.packages(c('DBI', 'RPostgres'), Ncpus = 2)"

# Create app directory
RUN mkdir -p /app

# Copy app files
COPY app.R /app/
COPY R/ /app/R/
COPY www/ /app/www/
COPY data/ /app/data/
COPY .env /app/

# Set working directory
WORKDIR /app

# Make port 7860 available (required by Hugging Face Spaces)
EXPOSE 7860

# Run app on port 7860
CMD ["R", "-e", "shiny::runApp(host='0.0.0.0', port=7860)"]
