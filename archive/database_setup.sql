-- ====================================================================
-- DISRUPTION MAPPING DATABASE SETUP
-- PostgreSQL database schema for health service disruption data
-- ====================================================================

-- Create database (run as postgres user)
-- CREATE DATABASE disruption_mapping;
-- \c disruption_mapping;

-- ====================================================================
-- 1. COUNTRIES TABLE
-- ====================================================================
CREATE TABLE IF NOT EXISTS countries (
    country_id SERIAL PRIMARY KEY,
    country_code VARCHAR(10) UNIQUE NOT NULL,
    country_name VARCHAR(100) NOT NULL,
    geojson_file VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ====================================================================
-- 2. ADMINISTRATIVE AREAS TABLE
-- ====================================================================
CREATE TABLE IF NOT EXISTS admin_areas (
    admin_area_id SERIAL PRIMARY KEY,
    country_id INTEGER REFERENCES countries(country_id),
    admin_level INTEGER NOT NULL,  -- 1, 2, or 3
    area_code VARCHAR(50),
    area_name VARCHAR(255) NOT NULL,
    parent_area_id INTEGER REFERENCES admin_areas(admin_area_id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(country_id, admin_level, area_name)
);

CREATE INDEX idx_admin_areas_country ON admin_areas(country_id);
CREATE INDEX idx_admin_areas_level ON admin_areas(admin_level);
CREATE INDEX idx_admin_areas_parent ON admin_areas(parent_area_id);

-- ====================================================================
-- 3. INDICATORS TABLE
-- ====================================================================
CREATE TABLE IF NOT EXISTS indicators (
    indicator_id SERIAL PRIMARY KEY,
    indicator_code VARCHAR(50) UNIQUE NOT NULL,
    indicator_name VARCHAR(255) NOT NULL,
    indicator_category VARCHAR(100),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ====================================================================
-- 4. DISRUPTION DATA TABLE
-- ====================================================================
CREATE TABLE IF NOT EXISTS disruption_data (
    disruption_id BIGSERIAL PRIMARY KEY,
    country_id INTEGER REFERENCES countries(country_id),
    admin_area_id INTEGER REFERENCES admin_areas(admin_area_id),
    indicator_id INTEGER REFERENCES indicators(indicator_id),
    period_id INTEGER NOT NULL,  -- YYYYMM format
    year INTEGER NOT NULL,
    month INTEGER,
    quarter INTEGER,
    count_actual NUMERIC(15,2),
    count_expected NUMERIC(15,2),
    count_expected_threshold NUMERIC(15,2),
    percent_change NUMERIC(10,2),
    category VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for fast querying
CREATE INDEX idx_disruption_country ON disruption_data(country_id);
CREATE INDEX idx_disruption_admin ON disruption_data(admin_area_id);
CREATE INDEX idx_disruption_indicator ON disruption_data(indicator_id);
CREATE INDEX idx_disruption_year ON disruption_data(year);
CREATE INDEX idx_disruption_period ON disruption_data(period_id);
CREATE INDEX idx_disruption_composite ON disruption_data(country_id, year, admin_area_id);

-- ====================================================================
-- 5. UPLOAD HISTORY TABLE
-- ====================================================================
CREATE TABLE IF NOT EXISTS upload_history (
    upload_id SERIAL PRIMARY KEY,
    country_id INTEGER REFERENCES countries(country_id),
    admin_level INTEGER,
    file_name VARCHAR(255),
    records_imported INTEGER,
    upload_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    uploaded_by VARCHAR(100),
    notes TEXT
);

-- ====================================================================
-- 6. MATERIALIZED VIEW FOR QUICK ACCESS
-- ====================================================================
CREATE MATERIALIZED VIEW IF NOT EXISTS disruption_summary AS
SELECT
    d.disruption_id,
    c.country_code,
    c.country_name,
    a.admin_level,
    a.area_name as admin_area_name,
    COALESCE(parent.area_name, '') as parent_area_name,
    i.indicator_code,
    i.indicator_name,
    d.period_id,
    d.year,
    d.month,
    d.quarter,
    d.count_actual,
    d.count_expected,
    d.percent_change,
    CASE
        WHEN d.count_expected = 0 OR d.count_expected IS NULL THEN 'Insufficient data'
        WHEN d.percent_change >= 10 THEN 'Surplus >10%'
        WHEN d.percent_change >= 5 AND d.percent_change < 10 THEN 'Surplus 5-10%'
        WHEN d.percent_change > -5 AND d.percent_change < 5 THEN 'Stable'
        WHEN d.percent_change > -10 AND d.percent_change <= -5 THEN 'Disruption 5-10%'
        WHEN d.percent_change <= -10 THEN 'Disruption >10%'
        ELSE 'Stable'
    END as category
FROM disruption_data d
JOIN countries c ON d.country_id = c.country_id
JOIN admin_areas a ON d.admin_area_id = a.admin_area_id
JOIN indicators i ON d.indicator_id = i.indicator_id
LEFT JOIN admin_areas parent ON a.parent_area_id = parent.admin_area_id;

CREATE INDEX idx_disruption_summary_country ON disruption_summary(country_code);
CREATE INDEX idx_disruption_summary_year ON disruption_summary(year);
CREATE INDEX idx_disruption_summary_level ON disruption_summary(admin_level);

-- ====================================================================
-- 7. FUNCTIONS FOR DATA MANAGEMENT
-- ====================================================================

-- Function to refresh materialized view
CREATE OR REPLACE FUNCTION refresh_disruption_summary()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY disruption_summary;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate disruption category
CREATE OR REPLACE FUNCTION calculate_category(percent_change NUMERIC)
RETURNS VARCHAR AS $$
BEGIN
    IF percent_change IS NULL THEN
        RETURN 'Insufficient data';
    ELSIF percent_change >= 10 THEN
        RETURN 'Surplus >10%';
    ELSIF percent_change >= 5 AND percent_change < 10 THEN
        RETURN 'Surplus 5-10%';
    ELSIF percent_change > -5 AND percent_change < 5 THEN
        RETURN 'Stable';
    ELSIF percent_change > -10 AND percent_change <= -5 THEN
        RETURN 'Disruption 5-10%';
    ELSIF percent_change <= -10 THEN
        RETURN 'Disruption >10%';
    ELSE
        RETURN 'Stable';
    END IF;
END;
$$ LANGUAGE plpgsql;

-- Function to upsert country
CREATE OR REPLACE FUNCTION upsert_country(
    p_country_code VARCHAR,
    p_country_name VARCHAR,
    p_geojson_file VARCHAR DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
    v_country_id INTEGER;
BEGIN
    INSERT INTO countries (country_code, country_name, geojson_file)
    VALUES (p_country_code, p_country_name, p_geojson_file)
    ON CONFLICT (country_code)
    DO UPDATE SET
        country_name = EXCLUDED.country_name,
        geojson_file = COALESCE(EXCLUDED.geojson_file, countries.geojson_file),
        updated_at = CURRENT_TIMESTAMP
    RETURNING country_id INTO v_country_id;

    RETURN v_country_id;
END;
$$ LANGUAGE plpgsql;

-- ====================================================================
-- 8. INSERT INITIAL DATA
-- ====================================================================

-- Insert countries
INSERT INTO countries (country_code, country_name, geojson_file) VALUES
    ('NGA', 'Nigeria', 'nigeria_backbone.geojson'),
    ('SEN', 'Senegal', 'senegal_backbone.geojson'),
    ('SLE', 'Sierra Leone', 'sierraleone_backbone.geojson'),
    ('GIN', 'Guinea', 'guinea_backbone.geojson'),
    ('LBR', 'Liberia', 'liberia_backbone.geojson'),
    ('GHA', 'Ghana', 'ghana_backbone.geojson'),
    ('CMR', 'Cameroon', 'cameroon_backbone.geojson'),
    ('COD', 'DRC', 'drc_backbone.geojson'),
    ('ETH', 'Ethiopia', 'ethiopia_backbone.geojson'),
    ('MLI', 'Mali', 'mali_backbone.geojson'),
    ('MWI', 'Malawi', 'malawi_backbone.geojson'),
    ('HTI', 'Haiti', 'haiti_backbone.geojson'),
    ('SOM', 'Somalia', 'somalia_backbone.geojson'),
    ('BGD', 'Bangladesh', 'bangladesh1_backbone.geojson')
ON CONFLICT (country_code) DO NOTHING;

-- Insert standard indicators
INSERT INTO indicators (indicator_code, indicator_name, indicator_category) VALUES
    ('anc1', 'Antenatal client 1st visit', 'Maternal Health'),
    ('anc4', 'Antenatal client 4th visit', 'Maternal Health'),
    ('delivery', 'Institutional delivery', 'Maternal Health'),
    ('pnc1_mother', 'Postnatal care 1 (mothers)', 'Maternal Health'),
    ('pnc1_newborn', 'Postnatal care 1 (newborns)', 'Maternal Health'),
    ('bcg', 'BCG dose', 'Child Health'),
    ('penta1', 'Pentavalent 1st dose', 'Child Health'),
    ('penta3', 'Pentavalent 3rd dose', 'Child Health'),
    ('measles1', 'Measles vaccine 1', 'Child Health'),
    ('measles2', 'Measles vaccine 2', 'Child Health'),
    ('malaria_tested', 'Fever case tested for malaria', 'Malaria'),
    ('malaria_positive', 'Fever case tested positive for malaria', 'Malaria'),
    ('malaria_tx', 'Malaria treated with ACT', 'Malaria'),
    ('fp_long', 'Family planning methods- long acting', 'Family Planning'),
    ('fp_short', 'Family planning methods- short acting', 'Family Planning'),
    ('new_fp', 'New family planning acceptors', 'Family Planning'),
    ('opd', 'Outpatient visit', 'General Services'),
    ('ipd', 'Inpatient visit', 'General Services')
ON CONFLICT (indicator_code) DO NOTHING;

-- ====================================================================
-- 9. GRANT PERMISSIONS
-- ====================================================================

-- Create app user (if not exists)
-- CREATE USER disruption_app WITH PASSWORD 'your_secure_password_here';

-- Grant permissions
-- GRANT CONNECT ON DATABASE disruption_mapping TO disruption_app;
-- GRANT USAGE ON SCHEMA public TO disruption_app;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO disruption_app;
-- GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO disruption_app;
-- GRANT INSERT, UPDATE ON disruption_data, upload_history TO disruption_app;
-- GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO disruption_app;

-- ====================================================================
-- 10. HELPFUL QUERIES
-- ====================================================================

-- Count records by country and year
-- SELECT c.country_name, d.year, COUNT(*) as records
-- FROM disruption_data d
-- JOIN countries c ON d.country_id = c.country_id
-- GROUP BY c.country_name, d.year
-- ORDER BY c.country_name, d.year;

-- Get available years for a country
-- SELECT DISTINCT year
-- FROM disruption_data d
-- JOIN countries c ON d.country_id = c.country_id
-- WHERE c.country_code = 'NGA'
-- ORDER BY year;

-- Get summary for a specific country, year, and level
-- SELECT * FROM disruption_summary
-- WHERE country_code = 'NGA'
--   AND year = 2024
--   AND admin_level = 2
-- ORDER BY percent_change;

-- Refresh the materialized view after data updates
-- SELECT refresh_disruption_summary();

-- ====================================================================
-- SETUP COMPLETE
-- ====================================================================
-- Next steps:
-- 1. Run this script to create the schema
-- 2. Use import_data_to_db.R to import CSV data
-- 3. Update app.R to read from database
-- ====================================================================
