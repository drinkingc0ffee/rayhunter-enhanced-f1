#!/bin/bash
# GPS API Test Script
# This script demonstrates how to use the new GPS API endpoint

# Device IP (adjust if different)
DEVICE_IP="192.168.1.1:8080"

echo "Testing GPS API endpoint..."
echo "Device: http://$DEVICE_IP"
echo

# Test 1: Valid coordinates (San Francisco) - POST
echo "Test 1: Valid coordinates (San Francisco: 37.7749,-122.4194) - POST"
curl -X POST "http://$DEVICE_IP/api/v1/gps/37.7749,-122.4194" \
     -H "Content-Type: application/json" \
     -w "\nHTTP Status: %{http_code}\n" \
     -s | jq . 2>/dev/null || echo "Response received (jq not available for formatting)"

echo -e "\n" 

# Test 2: Valid coordinates (New York) - POST
echo "Test 2: Valid coordinates (New York: 40.7128,-74.0060) - POST"
curl -X POST "http://$DEVICE_IP/api/v1/gps/40.7128,-74.0060" \
     -H "Content-Type: application/json" \
     -w "\nHTTP Status: %{http_code}\n" \
     -s | jq . 2>/dev/null || echo "Response received (jq not available for formatting)"

echo -e "\n"

# Test 3: Valid coordinates (London) - GET (GPS2REST-Android compatible)
echo "Test 3: Valid coordinates (London: 51.5074,-0.1278) - GET (GPS2REST-Android compatible)"
curl -X GET "http://$DEVICE_IP/api/v1/gps/51.5074,-0.1278" \
     -w "\nHTTP Status: %{http_code}\n" \
     -s | jq . 2>/dev/null || echo "Response received (jq not available for formatting)"

echo -e "\n"

# Test 4: Valid coordinates (Tokyo) - GET
echo "Test 4: Valid coordinates (Tokyo: 35.6762,139.6503) - GET"
curl -X GET "http://$DEVICE_IP/api/v1/gps/35.6762,139.6503" \
     -w "\nHTTP Status: %{http_code}\n" \
     -s | jq . 2>/dev/null || echo "Response received (jq not available for formatting)"

echo -e "\n"

# Test 5: Invalid coordinates format
echo "Test 5: Invalid coordinates format"
curl -X POST "http://$DEVICE_IP/api/v1/gps/invalid,format" \
     -H "Content-Type: application/json" \
     -w "\nHTTP Status: %{http_code}\n" \
     -s | jq . 2>/dev/null || echo "Response received (jq not available for formatting)"

echo -e "\n"

# Test 6: Out of range coordinates
echo "Test 6: Out of range coordinates (lat > 90)"
curl -X POST "http://$DEVICE_IP/api/v1/gps/91.0,0.0" \
     -H "Content-Type: application/json" \
     -w "\nHTTP Status: %{http_code}\n" \
     -s | jq . 2>/dev/null || echo "Response received (jq not available for formatting)"

echo -e "\n"

echo "Testing complete!"
echo
echo "To check saved data on device:"
echo "adb shell 'rootshell -c \"ls -la /data/rayhunter/gps-data/\"'"
echo "adb shell 'rootshell -c \"cat /data/rayhunter/gps-data/gps_data.csv\"'"
echo "adb shell 'rootshell -c \"cat /data/rayhunter/gps-data/gps_data.json\"'"
