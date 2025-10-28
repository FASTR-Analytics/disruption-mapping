# PostgreSQL Database Setup Guide

## Why Use a Database?

### Problems with File Uploads
- ❌ **File size limits**: Shiny has default upload limit (~5MB, max ~30MB without tricks)
- ❌ **Performance**: Large CSV files slow down the app
- ❌ **Memory**: Loading big files into RAM can crash the app
- ❌ **No persistence**: Need to re-upload files every session

### Benefits of PostgreSQL
- ✅ **No size limits**: Handle gigabytes of data
- ✅ **Fast queries**: Indexed database is much faster
- ✅ **Persistence**: Data stays loaded, no re-uploading
- ✅ **Multi-user**: Multiple people can use the app simultaneously
- ✅ **Data management**: Easy to update, version, and backup
- ✅ **Security**: Better control over data access

## Installation

### Step 1: Install PostgreSQL

#### macOS (using Homebrew)
```bash
# Install PostgreSQL
brew install postgresql@15

# Start PostgreSQL service
brew services start postgresql@15

# Check it's running
psql --version
```

#### macOS (using Postgres.app)
1. Download from https://postgresapp.com/
2. Drag to Applications
3. Open Postgres.app
4. Click "Initialize" to create a new server

#### Ubuntu/Debian
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

#### Windows
1. Download from https://www.postgresql.org/download/windows/
2. Run installer
3. Remember the password you set for postgres user
4. Add PostgreSQL bin to PATH

### Step 2: Create Database

```bash
# Connect to PostgreSQL
psql -U postgres

# In psql prompt:
CREATE DATABASE disruption_mapping;
CREATE USER disruption_app WITH PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE disruption_mapping TO disruption_app;

# Quit
\q
```

### Step 3: Run Schema Setup

```bash
# Navigate to app folder
cd /Users/claireboulange/Desktop/modules/disruption_mapping

# Run SQL setup script
psql -U postgres -d disruption_mapping -f database_setup.sql
```

### Step 4: Configure Connection

```bash
# Copy example env file
cp .env.example .env

# Edit .env with your credentials
nano .env  # or use any text editor
```

Edit the `.env` file:
```
DB_HOST=localhost
DB_PORT=5432
DB_NAME=disruption_mapping
DB_USER=disruption_app
DB_PASSWORD=your_secure_password  # Use the password from Step 2
USE_DATABASE=TRUE
```

### Step 5: Install R Packages

```r
# Install database packages
install.packages(c("DBI", "RPostgres", "pool"))

# Verify installation
library(DBI)
library(RPostgres)
```

## Data Import

### Import Your First Dataset

```r
# Load import script
source("import_data_to_db.R")

# Import Nigeria Level 2 data
con <- connect_db()
if (!is.null(con)) {
  import_disruption_csv(
    con = con,
    csv_file = "/Users/claireboulange/Desktop/modules/Oct_NGA/M3_disruptions_analysis_admin_area_2.csv",
    country_code = "NGA",
    country_name = "Nigeria",
    geojson_file = "nigeria_backbone.geojson"
  )

  # Refresh materialized view
  dbExecute(con, "SELECT refresh_disruption_summary()")

  dbDisconnect(con)
}
```

### Import Multiple Datasets

```r
source("import_data_to_db.R")

# Define all files to import
files_to_import <- list(
  list(
    file = "/Users/claireboulange/Desktop/modules/Oct_NGA/M3_disruptions_analysis_admin_area_2.csv",
    country_code = "NGA",
    country_name = "Nigeria",
    geojson_file = "nigeria_backbone.geojson"
  ),
  list(
    file = "/Users/claireboulange/Desktop/modules/Oct_NGA/M3_disruptions_analysis_admin_area_3.csv",
    country_code = "NGA",
    country_name = "Nigeria",
    geojson_file = "nigeria_backbone.geojson"
  )
)

# Import all
import_all_disruption_files(files_to_import)
```

### Verify Data Import

```r
source("import_data_to_db.R")
query_available_data()
```

This will show:
- List of countries in database
- Number of records by country, admin level, and year
- Number of areas and indicators

## Database Schema Overview

### Tables

1. **countries** - Country master list
2. **admin_areas** - Administrative areas (levels 1, 2, 3)
3. **indicators** - Health indicators master list
4. **disruption_data** - Main data table
5. **upload_history** - Tracks data imports
6. **disruption_summary** - Materialized view for fast queries

### Key Features

- **Foreign keys**: Ensures data integrity
- **Indexes**: Fast queries on country, year, admin area
- **Materialized view**: Pre-calculated summaries
- **Functions**: Helper functions for data management

## Using the Database in the App

### Option 1: Database Only (Recommended)

Edit `.env`:
```
USE_DATABASE=TRUE
```

The app will:
- Connect to database on startup
- Show dropdown of available countries and years
- Query data directly from database
- No file uploads needed

### Option 2: Hybrid (Database + Upload)

Edit `.env`:
```
USE_DATABASE=TRUE
```

The app will:
- Prefer database data when available
- Allow file uploads as fallback
- Best of both worlds

### Option 3: Upload Only (Original)

Edit `.env`:
```
USE_DATABASE=FALSE
```

The app will:
- Work as before with file uploads
- No database required
- Subject to file size limits

## Performance Optimization

### Refresh Materialized View

After importing data, refresh the view:

```r
con <- connect_db()
dbExecute(con, "SELECT refresh_disruption_summary()")
dbDisconnect(con)
```

Or in psql:
```sql
SELECT refresh_disruption_summary();
```

### Database Maintenance

```sql
-- Analyze tables (updates statistics for query planner)
ANALYZE disruption_data;
ANALYZE admin_areas;

-- Vacuum (reclaim storage, optional)
VACUUM ANALYZE disruption_data;

-- Reindex (if queries slow down)
REINDEX TABLE disruption_data;
```

## Troubleshooting

### Connection Failed

**Error**: `could not connect to server`

**Solutions**:
1. Check PostgreSQL is running:
   ```bash
   # macOS
   brew services list

   # Linux
   sudo systemctl status postgresql

   # Check process
   ps aux | grep postgres
   ```

2. Check port is correct (default 5432):
   ```bash
   psql -U postgres -c "SHOW port;"
   ```

3. Check credentials in `.env` file

### Permission Denied

**Error**: `permission denied for database`

**Solution**:
```sql
-- Connect as postgres user
psql -U postgres

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE disruption_mapping TO disruption_app;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO disruption_app;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO disruption_app;
```

### Import Fails

**Error**: `duplicate key value violates unique constraint`

**Cause**: Data already exists for that country/period

**Solutions**:
1. Delete existing data first:
   ```sql
   DELETE FROM disruption_data
   WHERE country_id = (SELECT country_id FROM countries WHERE country_code = 'NGA');
   ```

2. Or clear all data:
   ```r
   source("import_data_to_db.R")
   clear_all_disruption_data()  # BE CAREFUL!
   ```

### Slow Queries

**Solutions**:
1. Refresh materialized view:
   ```sql
   SELECT refresh_disruption_summary();
   ```

2. Analyze tables:
   ```sql
   ANALYZE disruption_data;
   ```

3. Check indexes exist:
   ```sql
   \d+ disruption_data
   ```

## Security Best Practices

### 1. Use Strong Passwords

```bash
# Generate random password
openssl rand -base64 32
```

### 2. Don't Commit .env File

The `.gitignore` already excludes `.env`, but double-check:
```bash
cat .gitignore | grep .env
```

### 3. Restrict Database Access

```sql
-- Only allow local connections
-- Edit pg_hba.conf:
# TYPE  DATABASE        USER            ADDRESS         METHOD
local   disruption_mapping  disruption_app              md5
host    disruption_mapping  disruption_app  127.0.0.1/32 md5
```

### 4. Regular Backups

```bash
# Backup database
pg_dump -U postgres disruption_mapping > backup_$(date +%Y%m%d).sql

# Restore from backup
psql -U postgres -d disruption_mapping < backup_20241026.sql
```

## Data Management

### Update Existing Data

```r
con <- connect_db()

# Update specific records
dbExecute(con, "
  UPDATE disruption_data
  SET count_actual = $1, percent_change = $2
  WHERE disruption_id = $3",
  params = list(new_actual, new_pct, id)
)

dbDisconnect(con)
```

### Delete Old Data

```r
con <- connect_db()

# Delete data before certain year
dbExecute(con, "
  DELETE FROM disruption_data
  WHERE year < 2020"
)

# Refresh view
dbExecute(con, "SELECT refresh_disruption_summary()")

dbDisconnect(con)
```

### Export Data

```r
con <- connect_db()

# Export to CSV
data <- dbGetQuery(con, "
  SELECT * FROM disruption_summary
  WHERE country_code = 'NGA' AND year = 2024
")
write.csv(data, "nigeria_2024_export.csv", row.names = FALSE)

dbDisconnect(con)
```

## Advanced: Connection Pooling

For production deployments with many concurrent users:

```r
# In app.R
library(pool)

# Create connection pool
pool <- dbPool(
  drv = Postgres(),
  host = DB_CONFIG$host,
  port = DB_CONFIG$port,
  dbname = DB_CONFIG$dbname,
  user = DB_CONFIG$user,
  password = DB_CONFIG$password,
  minSize = 2,
  maxSize = 10
)

# Use pool instead of con
data <- dbGetQuery(pool, "SELECT ...")

# Close pool when done
poolClose(pool)
```

## Migration from File-Based to Database

### Step 1: Inventory Files

```r
# List all your disruption CSV files
files <- c(
  "/Users/claireboulange/Desktop/modules/Oct_NGA/M3_disruptions_analysis_admin_area_2.csv",
  "/Users/claireboulange/Desktop/modules/Oct_NGA/M3_disruptions_analysis_admin_area_3.csv",
  # ... more files
)
```

### Step 2: Import All

```r
source("import_data_to_db.R")

# Import each file
for (file in files) {
  # Determine country from filename or path
  # Then import
  import_disruption_csv(con, file, country_code, country_name)
}
```

### Step 3: Verify

```r
query_available_data()
```

### Step 4: Update App

Edit `.env`:
```
USE_DATABASE=TRUE
```

### Step 5: Test

```r
source("launch_app.R")
# App should now use database
```

## FAQs

**Q: How much data can the database handle?**
A: PostgreSQL can handle millions of rows easily. A table with 10 million disruption records would be <1GB.

**Q: Will this slow down my app?**
A: No, it will be FASTER. Database queries with proper indexes are much faster than loading CSV files.

**Q: Can I still use file uploads?**
A: Yes! You can use both. Enable database but keep upload option as backup.

**Q: How do I back up the database?**
A: Use `pg_dump` command shown in Security section above.

**Q: Can multiple users access the app simultaneously?**
A: Yes! That's a major advantage of using a database.

**Q: What if I don't have admin access to install PostgreSQL?**
A: You can use cloud PostgreSQL services like:
- AWS RDS
- Google Cloud SQL
- Azure Database for PostgreSQL
- Heroku Postgres (free tier available)

## Next Steps

1. ✅ Install PostgreSQL
2. ✅ Create database and run schema
3. ✅ Configure `.env` file
4. ✅ Import your data
5. ✅ Launch app with database support
6. 📊 Enjoy fast, unlimited data access!

---

**Questions?** Check the troubleshooting section or review the SQL schema in `database_setup.sql`.
