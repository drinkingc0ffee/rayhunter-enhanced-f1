#!/bin/bash

# Rayhunter QMDL Files Migration Script
# This script migrates QMDL files from the old qmdl directory to the new captures directory

set -e

echo "🔄 Rayhunter QMDL Files Migration Script"
echo "========================================"

# Check if device is connected
if ! adb devices | grep -q "device$"; then
    echo "❌ No Android device connected. Please connect your device and try again."
    exit 1
fi

echo "📱 Device connected. Starting QMDL migration..."

# Check if old qmdl directory exists and has files
if adb shell '/bin/rootshell -c "test -d /data/rayhunter/qmdl"' 2>/dev/null; then
    echo "📂 Found existing qmdl directory. Checking for files..."
    
    # Count files to migrate
    QMDL_COUNT=$(adb shell '/bin/rootshell -c "find /data/rayhunter/qmdl -name \"*.qmdl\" 2>/dev/null | wc -l"')
    NDJSON_COUNT=$(adb shell '/bin/rootshell -c "find /data/rayhunter/qmdl -name \"*.ndjson\" 2>/dev/null | wc -l"')
    GPS_COUNT=$(adb shell '/bin/rootshell -c "find /data/rayhunter/qmdl -name \"*.gps\" 2>/dev/null | wc -l"')
    MANIFEST_EXISTS=$(adb shell '/bin/rootshell -c "test -f /data/rayhunter/qmdl/manifest.toml && echo 1 || echo 0"')
    
    echo "📊 Found files to migrate:"
    echo "   - QMDL files: $QMDL_COUNT"
    echo "   - NDJSON files: $NDJSON_COUNT"
    echo "   - GPS files: $GPS_COUNT"
    echo "   - Manifest file: $([ "$MANIFEST_EXISTS" = "1" ] && echo "Yes" || echo "No")"
    
    if [ "$QMDL_COUNT" -gt 0 ] || [ "$NDJSON_COUNT" -gt 0 ] || [ "$GPS_COUNT" -gt 0 ]; then
        echo "🔄 Migrating files to captures directory..."
        
        # Move all files to captures directory
        adb shell '/bin/rootshell -c "cp -r /data/rayhunter/qmdl/* /data/rayhunter/captures/"'
        
        echo "✅ Files copied to captures directory"
        
        # Archive old directory
        echo "📦 Archiving old qmdl directory..."
        adb shell '/bin/rootshell -c "mv /data/rayhunter/qmdl /data/rayhunter/qmdl.legacy"'
        echo "✅ Archived old directory as /data/rayhunter/qmdl.legacy"
        
    else
        echo "ℹ️  No files found in qmdl directory. No migration needed."
    fi
    
else
    echo "ℹ️  No existing qmdl directory found. No migration needed."
fi

# Show current directory structure
echo ""
echo "📋 Current directory structure:"
adb shell '/bin/rootshell -c "ls -la /data/rayhunter/"'

echo ""
echo "📁 Captures directory contents:"
adb shell '/bin/rootshell -c "ls -la /data/rayhunter/captures/"'

echo ""
echo "✅ QMDL migration complete!"
echo ""
echo "📝 Next steps:"
echo "   - All QMDL, NDJSON, and GPS files are now in /data/rayhunter/captures/"
echo "   - Legacy directory is preserved in /data/rayhunter/qmdl.legacy/"
echo "   - New recordings will be created in the captures directory"
echo "   - You can safely delete the legacy directory after verifying migration"
echo ""
echo "🔗 For more information, see the GPS API documentation." 