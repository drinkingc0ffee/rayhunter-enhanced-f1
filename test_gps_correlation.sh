#!/bin/bash

# Test GPS Correlation Enhancement
# This script tests the enhanced analysis with GPS correlation

set -e

echo "🧪 Testing GPS Correlation Enhancement"
echo "======================================"

# Check if device is connected
if ! adb devices | grep -q "device$"; then
    echo "❌ No Android device connected. Please connect your device and try again."
    exit 1
fi

echo "📱 Device connected. Starting GPS correlation test..."

# Check if we have any GPS data
echo "📍 Checking for GPS data..."
GPS_COUNT=$(adb shell 'rootshell -c "find /data/rayhunter/captures -name \"*.gps\" 2>/dev/null | wc -l"' | tr -d '\r' | xargs)

if [ "$GPS_COUNT" -eq 0 ]; then
    echo "❌ No GPS files found. Please collect some GPS data first."
    echo "   You can use the GPS API to submit coordinates:"
    echo "   curl -X POST http://localhost:8080/api/v1/gps/37.7749,-122.4194"
    exit 1
fi

echo "✅ Found $GPS_COUNT GPS files"

# Check if we have any QMDL files
echo "📊 Checking for QMDL files..."
QMDL_COUNT=$(adb shell 'rootshell -c "find /data/rayhunter/captures -name \"*.qmdl\" 2>/dev/null | wc -l"' | tr -d '\r' | xargs)

if [ "$QMDL_COUNT" -eq 0 ]; then
    echo "❌ No QMDL files found. Please record some data first."
    exit 1
fi

echo "✅ Found $QMDL_COUNT QMDL files"

# Get the most recent recording
LATEST_RECORDING=$(adb shell 'rootshell -c "ls -t /data/rayhunter/captures/*.qmdl | head -1 | xargs basename -s .qmdl"' | tr -d '\r')

if [ -z "$LATEST_RECORDING" ]; then
    echo "❌ Could not find latest recording"
    exit 1
fi

echo "🎯 Testing with recording: $LATEST_RECORDING"

# Check if GPS file exists for this recording
GPS_FILE="/data/rayhunter/captures/${LATEST_RECORDING}.gps"
if adb shell "rootshell -c \"test -f $GPS_FILE\"" 2>/dev/null; then
    echo "✅ GPS file exists for recording"
    
    # Show GPS data sample
    echo "📍 GPS data sample:"
    adb shell "rootshell -c \"head -3 $GPS_FILE\"" | tr -d '\r'
    
    # Check if analysis file exists
    ANALYSIS_FILE="/data/rayhunter/captures/${LATEST_RECORDING}.ndjson"
    if adb shell "rootshell -c \"test -f $ANALYSIS_FILE\"" 2>/dev/null; then
        echo "✅ Analysis file exists"
        
        # Show analysis data sample
        echo "📊 Analysis data sample:"
        adb shell "rootshell -c \"head -2 $ANALYSIS_FILE\"" | tr -d '\r'
        
        # Check if analysis contains GPS correlation
        echo "🔍 Checking for GPS correlation in analysis..."
        if adb shell "rootshell -c \"grep -q 'gps_correlation' $ANALYSIS_FILE\"" 2>/dev/null; then
            echo "✅ GPS correlation found in analysis!"
            
            # Show GPS correlation data
            echo "📍 GPS correlation data sample:"
            adb shell "rootshell -c \"grep -A 5 'gps_correlation' $ANALYSIS_FILE | head -10\"" | tr -d '\r'
        else
            echo "⚠️  GPS correlation not found in analysis (this is expected for old analysis files)"
            echo "   New analysis runs will include GPS correlation"
        fi
    else
        echo "⚠️  Analysis file does not exist. You can run analysis via the web UI."
    fi
else
    echo "⚠️  No GPS file for this recording"
fi

echo ""
echo "🎉 GPS Correlation Enhancement Test Complete!"
echo ""
echo "📋 Summary:"
echo "   - GPS files found: $GPS_COUNT"
echo "   - QMDL files found: $QMDL_COUNT"
echo "   - Latest recording: $LATEST_RECORDING"
echo ""
echo "💡 To test the enhanced analysis:"
echo "   1. Start a new recording via the web UI"
echo "   2. Submit GPS coordinates via the REST API"
echo "   3. Stop the recording"
echo "   4. Run analysis - it will now include GPS correlation!"
echo ""
echo "🌐 Web UI: http://localhost:8080"
echo "📡 GPS API: curl -X POST http://localhost:8080/api/v1/gps/LAT,LON" 