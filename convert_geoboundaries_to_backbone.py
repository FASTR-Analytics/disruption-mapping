#!/usr/bin/env python3
"""
Convert GeoBoundaries GeoJSON files to DHIS2-style backbone format.

This script converts GeoBoundaries ADM1 and ADM2 files into the backbone
format used by the disruption mapping module, with names normalized to
match the DHIS2 backbone.

Usage:
    python convert_geoboundaries_to_backbone.py

Output:
    data/geojson/burkinafaso_backbone.geojson
"""

import json
import csv
from pathlib import Path

# Paths
DATA_DIR = Path(__file__).parent / "data"
ADM1_FILE = DATA_DIR / "geoBoundaries-BFA-ADM1_simplified.geojson"
ADM2_FILE = DATA_DIR / "geoBoundaries-BFA-ADM2_simplified.geojson"
DHIS2_BACKBONE = DATA_DIR / "backbone_DHIS2_BURKINA.csv"
OUTPUT_FILE = DATA_DIR / "geojson" / "burkinafaso_backbone.geojson"

# Name mappings: GeoBoundaries -> DHIS2
# These handle spelling differences between the two sources
REGION_NAME_MAP = {
    "Centre-Est": "Centre Est",
    "Centre-Nord": "Centre Nord",
    "Centre-Ouest": "Centre Ouest",
    "Centre-Sud": "Centre Sud",
    "Hauts-Bassins": "Hauts Bassins",
    "Sud-Ouest": "Sud Ouest",
}

PROVINCE_NAME_MAP = {
    "Boulkiemde": "Boulkiemdé",
    "Comoe": "Comoé",
    "Komonjdjari": "Komandjari",
    "Koulpelogo": "Koulpélogo",
    "Passore": "Passoré",
    "Sanguie": "Sanguié",
}


def load_geojson(filepath):
    """Load a GeoJSON file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        return json.load(f)


def load_dhis2_hierarchy():
    """
    Load DHIS2 backbone to get region-province relationships.
    Returns a dict mapping province -> region.
    """
    province_to_region = {}
    with open(DHIS2_BACKBONE, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            region = row['admin_area_2']
            province = row['admin_area_3']
            province_to_region[province] = region
    return province_to_region


def normalize_name(name, name_map):
    """Apply name mapping if exists, otherwise return original."""
    return name_map.get(name, name)


def convert_feature(feature, level, name, feature_id, parent_id=None, parent_graph=None):
    """
    Convert a GeoBoundaries feature to backbone format.
    """
    props = feature.get('properties', {})

    new_feature = {
        "type": "Feature",
        "id": feature_id,
        "geometry": feature.get('geometry'),
        "properties": {
            "code": props.get('shapeISO') or None,
            "name": name,
            "level": str(level),
            "parent": parent_id,
            "parentGraph": parent_graph,
            "groups": []
        }
    }

    return new_feature


def main():
    print("Loading files...")

    # Load source files
    adm1_data = load_geojson(ADM1_FILE)
    adm2_data = load_geojson(ADM2_FILE)
    province_to_region = load_dhis2_hierarchy()

    print(f"  ADM1 (Regions): {len(adm1_data['features'])} features")
    print(f"  ADM2 (Provinces): {len(adm2_data['features'])} features")
    print(f"  DHIS2 province-region mappings: {len(province_to_region)}")

    # Create a synthetic country-level ID for Burkina Faso
    country_id = "BFA00000000"

    # Convert features
    converted_features = []
    region_id_map = {}  # Map DHIS2 region name -> feature_id

    # Process ADM1 (Regions) - level 2
    print("\nConverting ADM1 (Regions)...")
    for feature in adm1_data['features']:
        props = feature['properties']
        gb_name = props['shapeName']
        dhis2_name = normalize_name(gb_name, REGION_NAME_MAP)

        # Use shapeID truncated to 11 chars as feature ID
        feature_id = props.get('shapeID', '')[:11]

        converted = convert_feature(
            feature,
            level=2,
            name=dhis2_name,
            feature_id=feature_id,
            parent_id=country_id,
            parent_graph=country_id
        )
        converted_features.append(converted)

        # Store ID for ADM2 parent lookup
        region_id_map[dhis2_name] = feature_id
        print(f"  ✓ {gb_name} → {dhis2_name}")

    # Process ADM2 (Provinces) - level 3
    print("\nConverting ADM2 (Provinces)...")
    for feature in adm2_data['features']:
        props = feature['properties']
        gb_name = props['shapeName']
        dhis2_name = normalize_name(gb_name, PROVINCE_NAME_MAP)

        # Use shapeID truncated to 11 chars as feature ID
        feature_id = props.get('shapeID', '')[:11]

        # Look up parent region from DHIS2 hierarchy
        parent_region = province_to_region.get(dhis2_name)
        parent_id = region_id_map.get(parent_region) if parent_region else None
        parent_graph = f"{country_id}/{parent_id}" if parent_id else None

        converted = convert_feature(
            feature,
            level=3,
            name=dhis2_name,
            feature_id=feature_id,
            parent_id=parent_id,
            parent_graph=parent_graph
        )
        converted_features.append(converted)

        status = "✓" if parent_id else "⚠"
        parent_info = f"(parent: {parent_region})" if parent_region else "(no parent found)"
        print(f"  {status} {gb_name} → {dhis2_name} {parent_info}")

    # Create output GeoJSON
    output = {
        "type": "FeatureCollection",
        "features": converted_features
    }

    # Write output
    print(f"\nWriting backbone file to: {OUTPUT_FILE}")
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(output, f)

    print(f"\nDone! Created backbone with {len(converted_features)} features:")
    print(f"  - {len(adm1_data['features'])} ADM1 regions (level 2)")
    print(f"  - {len(adm2_data['features'])} ADM2 provinces (level 3)")
    print("\nNames have been normalized to match DHIS2 backbone.")


if __name__ == "__main__":
    main()
