#!/bin/bash

# ====================================================================
# PostgreSQL Installation Script for macOS
# ====================================================================

echo "=================================================="
echo "Installing PostgreSQL for Disruption Mapping App"
echo "=================================================="
echo ""

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "ERROR: Homebrew is not installed."
    echo "Please install Homebrew first:"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

echo "✓ Homebrew is installed"
echo ""

# Install PostgreSQL
echo "Installing PostgreSQL 15..."
brew install postgresql@15

# Start PostgreSQL service
echo ""
echo "Starting PostgreSQL service..."
brew services start postgresql@15

# Wait a moment for service to start
echo "Waiting for PostgreSQL to start..."
sleep 3

# Create database
echo ""
echo "Creating disruption_mapping database..."
createdb disruption_mapping

# Run schema setup
echo ""
echo "Setting up database schema..."
psql -d disruption_mapping -f database_setup.sql

echo ""
echo "=================================================="
echo "✓ PostgreSQL Installation Complete!"
echo "=================================================="
echo ""
echo "Next steps:"
echo "  1. Copy .env.example to .env"
echo "  2. Edit .env with your database password"
echo "  3. Run: source('import_data_to_db.R') in R"
echo "  4. Import your data"
echo ""
echo "=================================================="
