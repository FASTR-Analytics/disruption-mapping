# Data Format Reference

## M3 Disruption Data

### Required Columns

| Column | Type | Required | Description |
|--------|------|----------|-------------|
| `admin_area_2` | string | Yes* | Province/State name |
| `admin_area_3` | string | Yes* | District name |
| `indicator_common_id` | string | Yes | Indicator identifier |
| `year` | integer | Yes | Calendar year (e.g., 2024) |
| `period_id` | integer | Yes | Period in YYYYMM format |
| `count_sum` | numeric | Yes | Actual service count |
| `count_expect_sum` | numeric | Yes | Expected service count |

*Either `admin_area_2` or `admin_area_3` is required.

### Optional Columns

| Column | Type | Description |
|--------|------|-------------|
| `month` | integer | Month number (1-12) |
| `indicator_name` | string | Human-readable indicator name |

### Example CSV

```csv
admin_area_2,indicator_common_id,year,period_id,count_sum,count_expect_sum
Nord Ubangi,vacc_bcg,2024,202401,1500,1800
Nord Ubangi,vacc_bcg,2024,202402,1600,1750
Sud Ubangi,vacc_bcg,2024,202401,2200,2100
```

## Indicator Identifiers

### Vaccination Indicators

| ID | Description |
|----|-------------|
| `vacc_bcg` | BCG vaccine |
| `vacc_opv0` | OPV birth dose |
| `vacc_opv1` | OPV 1st dose |
| `vacc_opv2` | OPV 2nd dose |
| `vacc_opv3` | OPV 3rd dose |
| `vacc_penta1` | Pentavalent 1st dose |
| `vacc_penta2` | Pentavalent 2nd dose |
| `vacc_penta3` | Pentavalent 3rd dose |
| `vacc_measles1` | Measles 1st dose |
| `vacc_measles2` | Measles 2nd dose |

### Maternal Health Indicators

| ID | Description |
|----|-------------|
| `anc1` | Antenatal care 1st visit |
| `anc4` | Antenatal care 4th visit |
| `delivery_facility` | Facility deliveries |
| `delivery_sba` | Deliveries by Skilled Birth Attendants |
| `pnc_mother` | Postnatal care - mother |
| `pnc_newborn` | Postnatal care - newborn |

### Other Indicators

See [Indicators Reference](indicators.md) for the complete list.

## Geographic Boundaries

### GeoJSON Structure

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "properties": {
        "name": "Nord Ubangi",
        "level": "2"
      },
      "geometry": {
        "type": "MultiPolygon",
        "coordinates": [...]
      }
    }
  ]
}
```

### Admin Levels

| Level | Description | Example |
|-------|-------------|---------|
| 2 | Province/State | Nord Ubangi |
| 3 | District/LGA | Businga |

## Name Matching

Area names in your CSV must match the GeoJSON `name` property.

### Common Issues

1. **Encoding**: Ensure UTF-8 encoding for accented characters
2. **Spacing**: Check for extra spaces
3. **Case**: Matching is case-sensitive
4. **Prefixes**: Some GeoJSON files include prefixes (e.g., "nu Nord Ubangi")
