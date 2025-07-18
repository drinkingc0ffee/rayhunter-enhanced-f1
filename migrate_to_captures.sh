#!/bin/bash

# Rayhunter GPS Data Migration Script
# This script migrates GPS data from the old gps-data directory to the new captures directory structure

set -e

echo "🔄 Rayhunter GPS Data Migration Script"
echo "======================================"

# Check if device is connected
if ! adb devices | grep -q "device$"; then
    echo "❌ No Android device connected. Please connect your device and try again."
    exit 1
fi

echo "📱 Device connected. Starting migration..."

# Create captures directory if it doesn't exist
echo "📁 Creating captures directory..."
adb shell '/bin/rootshell -c "mkdir -p /data/rayhunter/captures"'

# Check if old gps-data directory exists
if adb shell '/bin/rootshell -c "test -d /data/rayhunter/gps-data"' 2>/dev/null; then
    echo "📂 Found existing gps-data directory. Checking for legacy files..."
    
    # Check for legacy CSV file
    if adb shell '/bin/rootshell -c "test -f /data/rayhunter/gps-data/gps_coordinates.csv"' 2>/dev/null; then
        echo "📄 Found legacy CSV file. Converting to per-scan format..."
        
        # Create a migration scan with current timestamp
        MIGRATION_SCAN_ID=$(date +%s)
        echo "🆔 Migration scan ID: $MIGRATION_SCAN_ID"
        
        # Copy CSV data to new format
        adb shell "/bin/rootshell -c \"cp /data/rayhunter/gps-data/gps_coordinates.csv /data/rayhunter/captures/${MIGRATION_SCAN_ID}.gps\""
        
        echo "✅ Migrated CSV data to /data/rayhunter/captures/${MIGRATION_SCAN_ID}.gps"
    fi
    
    # Check for legacy JSON file
    if adb shell '/bin/rootshell -c "test -f /data/rayhunter/gps-data/gps_coordinates.json"' 2>/dev/null; then
        echo "📄 Found legacy JSON file. Backing up..."
        adb shell '/bin/rootshell -c "cp /data/rayhunter/gps-data/gps_coordinates.json /data/rayhunter/gps-data/gps_coordinates.json.backup"'
        echo "✅ Backed up JSON file"
    fi
    
    # Archive old directory
    echo "📦 Archiving old gps-data directory..."
    adb shell '/bin/rootshell -c "mv /data/rayhunter/gps-data /data/rayhunter/gps-data.legacy"'
    echo "✅ Archived old directory as /data/rayhunter/gps-data.legacy"
    
else
    echo "ℹ️  No existing gps-data directory found. No migration needed."
fi

# Show current directory structure
echo ""
echo "📋 Current directory structure:"
adb shell '/bin/rootshell -c "ls -la /data/rayhunter/"'

echo ""
echo "📁 Captures directory contents:"
adb shell '/bin/rootshell -c "ls -la /data/rayhunter/captures/"'

echo ""
echo "✅ Migration complete!"
echo ""
echo "📝 Next steps:"
echo "   - New GPS data will be stored in /data/rayhunter/captures/"
echo "   - Each recording session will have its own .gps file"
echo "   - Legacy data is preserved in /data/rayhunter/gps-data.legacy/"
echo "   - You can safely delete the legacy directory after verifying migration"
echo ""
echo "🔗 For more information, see the GPS API documentation." 