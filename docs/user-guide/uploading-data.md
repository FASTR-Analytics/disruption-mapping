# Uploading Data

## Supported File Format

The application accepts CSV files from the FASTR Module 3 (M3) output.

## Required Columns

Your CSV must contain these columns:

| Column | Description | Example |
|--------|-------------|---------|
| `admin_area_2` | Level 2 admin area (province/state) | `Nord Ubangi` |
| `admin_area_3` | Level 3 admin area (district) - optional | `Businga` |
| `indicator_common_id` | Indicator identifier | `vacc_bcg` |
| `year` | Year of data | `2024` |
| `period_id` | Period identifier (YYYYMM) | `202401` |
| `count_sum` | Actual service count | `1500` |
| `count_expect_sum` | Expected service count | `1800` |

## How to Upload

1. Click **"Browse..."** or drag and drop your file
2. Wait for the upload progress bar to complete
3. The app will automatically detect the admin level (2 or 3)
4. Indicators and years will populate in the dropdowns

!!! tip "File Size"
    Files up to 50MB are supported. For larger files, consider filtering to specific indicators or time periods before upload.

## Data Validation

The app performs automatic validation:

- Checks for required columns
- Validates numeric fields
- Matches admin area names to geographic boundaries

!!! warning "Name Matching"
    Admin area names in your CSV must match the names in the geographic boundaries file. If areas are missing from the map, check for spelling differences.

## Troubleshooting

### "No data found" error

- Ensure your file has the required columns
- Check that the country selection matches your data

### Missing areas on map

- Area names may not match the boundary file
- Check for spelling or encoding differences
