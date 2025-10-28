---
title: Health Service Disruption Mapping
emoji: 🏥
colorFrom: blue
colorTo: green
sdk: docker
pinned: false
license: apache-2.0
---

# Health Service Disruption Mapping 🗺️

Interactive visualization of health service disruptions across administrative areas. Compare actual service counts against expected values based on historical trends.

## 🌟 Features

- **🗺️ Interactive Maps**: Visualize disruptions with color-coded administrative areas
- **📊 Heatmap View**: Multi-indicator overview showing all 52+ health services at once
- **🖼️ Professional Exports**: Publication-ready PNG maps (300 DPI) with north arrow and scale bar
- **🌍 Multi-Country**: Support for 17 countries across Africa
- **🇫🇷 Bilingual**: Full French/English language support
- **📈 52+ Health Indicators**: Maternal health, child health, malaria, HIV, TB, nutrition, and more
- **⏱️ Dynamic Time Periods**: Automatically detects data time range (e.g., "Jan-Dec 2025")

## 📋 Supported Indicators

### Maternal & Child Health
ANC visits, institutional deliveries, postnatal care, immunizations (BCG, Penta, Measles, RR1)

### Disease Programs
Malaria (testing, treatment, confirmation), HIV (testing, ART), TB (confirmed, treated)

### Nutrition & Other Services
SAM treatment, vitamin A, diarrhoea, GBV, outpatient/inpatient visits

## 🎨 Visualizations

1. **Disruption Map**: Geographic view of a single indicator
2. **Heatmap**: Matrix view of all indicators × districts
3. **Statistics**: Charts and summary tables
4. **Downloads**: Export maps as high-quality PNG files

## 🎯 How to Use

### 1. Select Data Source
- Upload your disruption analysis CSV file
- Or connect to PostgreSQL database (if configured)

### 2. Choose Parameters
- **Country**: Select from 17 available countries
- **Year**: Choose analysis year
- **Indicator**: Select specific health service (for map view)
- **Admin Level**: Choose Level 2 (states/provinces) or Level 3 (districts/LGAs)

### 3. Explore Visualizations
- **Map Tab**: Detailed spatial view of one indicator
- **Heatmap Tab**: Overview of all indicators across districts
- **Statistics Tab**: Charts showing disruption patterns
- **FR/EN Toggle**: Switch between French and English

### 4. Export Your Analysis
- Download high-quality PNG maps
- Include in reports and presentations
- Publication-ready 300 DPI quality

## 📊 Disruption Categories

| Color | Category | Meaning |
|-------|----------|---------|
| 🔴 Dark Red | Disruption >10% | Services significantly below expected |
| 🟠 Orange | Disruption 5-10% | Moderate disruption |
| 🟡 Light Yellow | Stable | Within ±5% of expected |
| 🟢 Light Green | Surplus 5-10% | Moderate increase |
| 🟩 Dark Green | Surplus >10% | Services significantly above expected |
| ⬜ Light Gray | Insufficient data | Not enough data to calculate |

## 📂 Data Format

### Required CSV Columns:
- `admin_area_2`: Administrative area name (state/province/district)
- `indicator_common_id`: Health indicator identifier
- `year`: Year of observation
- `period_id`: Period identifier (format: YYYYMM)
- `count_sum`: Actual count of services delivered
- `count_expect_sum`: Expected count based on historical trends

### Optional Columns:
- `admin_area_3`: Sub-district level (for Level 3 analysis)

## 🌍 Supported Countries

Bangladesh, Benin, Burkina Faso, Côte d'Ivoire, Ethiopia, Ghana, Guinea, Kenya, Liberia, Mali, Niger, Nigeria, Senegal, Sierra Leone, Tanzania, Togo, Uganda

## 🔧 Technical Stack

- **Framework**: R Shiny with shinydashboard
- **Mapping**: Leaflet for interactive maps, sf for spatial data
- **Visualization**: ggplot2 with ggspatial for professional exports
- **Database**: Optional PostgreSQL support
- **Deployment**: Docker container on Hugging Face Spaces

## 📚 Documentation

Complete documentation available in the `documentation/` folder:
- Getting started guide
- Indicator reference (52+ indicators)
- Map export guide
- Heatmap feature guide
- French translation guide
- And more...

## 📖 Example Workflow

1. Upload your disruption analysis CSV
2. Select country and year
3. View **Heatmap** for overview of all services
4. Identify priority indicators
5. Switch to **Map** tab for detailed spatial view
6. Export high-quality PNG maps
7. Use in reports, presentations, or publications

## 🎓 Use Cases

- **Health Program Monitoring**: Track service delivery disruptions
- **Emergency Response**: Identify areas needing support
- **Policy Planning**: Evidence-based resource allocation
- **Research**: Publication-ready visualizations
- **Reporting**: Generate professional maps for stakeholders

## 🤝 About

Developed for FASTR (Fast-track Action for effective scale-up of priority maternal, newborn, and child health and nutrition interventions).

Built with ❤️ using R Shiny and deployed on Hugging Face Spaces.

## 📄 License

Apache 2.0 License - Free to use and modify with attribution.

---

**Need help?** Check the documentation folder or visit the About tab in the app.
