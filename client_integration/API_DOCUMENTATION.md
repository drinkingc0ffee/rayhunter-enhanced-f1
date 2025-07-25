# Rayhunter Enhanced REST API Documentation

## Overview

The Rayhunter Enhanced REST API provides programmatic access to cellular monitoring and IMSI catcher detection capabilities. All endpoints return JSON unless specified otherwise.

**Base URL**: `http://{device_ip}:8080`

## Authentication

Currently, no authentication is required. The API is designed for local network use.

## Common Response Formats

### Success Response
```json
{
  "status": "success",
  "message": "Operation completed successfully",
  "data": { ... }
}
```

### Error Response
```json
{
  "status": "error",
  "error": "Description of the error"
}
```

## Core Endpoints

### 1. System Status

#### Get System Statistics
```http
GET /api/system-stats
```

**Response:**
```json
{
  "cpu_usage": 15.2,
  "memory_usage": 45.8,
  "disk_usage": 23.1,
  "uptime": 3600,
  "temperature": 42.5
}
```

### 2. Recording Management

#### Start Recording
```http
POST /api/start-recording
```

**Response:**
```json
{
  "status": "success",
  "message": "Recording started successfully"
}
```

#### Stop Recording
```http
POST /api/stop-recording
```

**Response:**
```json
{
  "status": "success", 
  "message": "Recording stopped successfully"
}
```

#### Get Recording Manifest
```http
GET /api/qmdl-manifest
```

**Response:**
```json
{
  "entries": [
    {
      "name": "1720080123",
      "start_time": "2025-01-02T10:30:00Z",
      "last_message_time": "2025-01-02T10:45:00Z",
      "qmdl_size_bytes": 1048576,
      "analysis_size_bytes": 51200
    }
  ],
  "current_entry": 0
}
```

### 3. Data Downloads

#### Download PCAP File
```http
GET /api/pcap/{recording_id}.pcapng
```

**Response:** Binary PCAP file

#### Download QMDL File
```http
GET /api/qmdl/{recording_id}.qmdl
```

**Response:** Binary QMDL file

#### Download ZIP Archive
```http
GET /api/zip/{recording_id}.zip
```

**Response:** ZIP file containing PCAP, QMDL, and GPS data

#### Download GPS Data (CSV)
```http
GET /api/gps/{recording_id}
GET /api/gps/{recording_id}/csv
```

**Response:** CSV file with GPS coordinates
```csv
timestamp,latitude,longitude
1735901415,37.7749,-122.4194
1735901420,37.7849,-122.4094
```

#### Download GPS Data (JSON)
```http
GET /api/gps/{recording_id}/json
```

**Response:**
```json
{
  "recording_id": "1720080123",
  "start_time": "2025-01-02T10:30:00Z",
  "end_time": "2025-01-02T10:45:00Z",
  "total_entries": 2,
  "gps_entries": [
    {
      "timestamp": "2025-01-02T10:30:15.123Z",
      "latitude": 37.7749,
      "longitude": -122.4194
    }
  ]
}
```

#### Download GPS Data (GPX)
```http
GET /api/gps/{recording_id}/gpx
```

**Response:** GPX file for mapping applications

### 4. GPS Integration

#### Submit GPS Coordinates
```http
GET|POST /api/v1/gps/{latitude},{longitude}
```

**Parameters:**
- `latitude`: Float between -90.0 and 90.0
- `longitude`: Float between -180.0 and 180.0

**Example:**
```http
POST /api/v1/gps/37.7749,-122.4194
```

**Response:**
```json
{
  "status": "success",
  "message": "GPS coordinate saved successfully",
  "data": {
    "timestamp": "2025-01-02T10:30:15.123Z",
    "latitude": 37.7749,
    "longitude": -122.4194
  }
}
```

#### Check GPS Data Exists
```http
HEAD /api/gps/{recording_id}
```

**Response:** 200 if exists, 404 if not

### 5. Analysis Management

#### Get Analysis Status
```http
GET /api/analysis
```

**Response:**
```json
{
  "running": "1720080123",
  "queued": ["1720080124"],
  "finished": ["1720080122"]
}
```

#### Start Analysis
```http
POST /api/analysis/{recording_id}
```

**Response:**
```json
{
  "status": "accepted",
  "analysis_status": {
    "running": "1720080123",
    "queued": ["1720080124"],
    "finished": ["1720080122"]
  }
}
```

#### Get Analysis Report
```http
GET /api/analysis-report/{recording_id}
```

**Response:**
```json
{
  "metadata": {
    "rayhunter": {
      "rayhunter_version": "0.4.0-enhanced",
      "system_os": "Linux 5.4.0"
    },
    "analyzers": [
      {
        "name": "IMSI Requested",
        "description": "Detects when IMSI is requested unnecessarily"
      }
    ]
  },
  "statistics": {
    "num_warnings": 2,
    "num_informational_logs": 15,
    "num_skipped_packets": 0
  },
  "rows": [
    {
      "analysis": [
        {
          "timestamp": "2025-01-02T10:30:15.123Z",
          "events": [
            {
              "type": "warning",
              "severity": 2,
              "message": "Cell suggested use of null cipher"
            }
          ]
        }
      ]
    }
  ]
}
```

### 6. Data Management

#### Delete Recording
```http
POST /api/delete-recording/{recording_id}
```

**Response:**
```json
{
  "status": "success",
  "message": "Recording deleted successfully"
}
```

#### Delete All Recordings
```http
POST /api/delete-all-recordings
```

**Response:**
```json
{
  "status": "success",
  "message": "All recordings deleted successfully"
}
```

### 7. Configuration

#### Get Configuration
```http
GET /api/config
```

**Response:**
```json
{
  "port": 8080,
  "log_level": "info",
  "capture_directory": "/data/rayhunter/captures"
}
```

#### Set Configuration
```http
POST /api/config
Content-Type: application/json

{
  "port": 8080,
  "log_level": "debug",
  "capture_directory": "/data/rayhunter/captures"
}
```

**Response:**
```json
{
  "status": "accepted",
  "message": "wrote config and triggered restart"
}
```

## Error Codes

| Code | Description |
|------|-------------|
| 200 | Success |
| 400 | Bad Request - Invalid parameters |
| 404 | Not Found - Resource doesn't exist |
| 500 | Internal Server Error |
| 503 | Service Unavailable - Device busy |

## Rate Limiting

Currently, no rate limiting is implemented. However, it's recommended to:
- Poll status endpoints no more than once per second
- Limit GPS coordinate submissions to reasonable intervals
- Implement exponential backoff for retries

## WebSocket Support

The API does not currently support WebSockets. For real-time updates, use polling with the status endpoints.

## File Upload

Currently, the API only supports GPS coordinate submission. File uploads are not supported.

## CORS

CORS is enabled for local network access. Cross-origin requests from mobile apps should work without issues.

## Examples

### Complete Workflow

1. **Start Recording**
```bash
curl -X POST http://192.168.1.1:8080/api/start-recording
```

2. **Submit GPS Coordinates**
```bash
curl -X POST http://192.168.1.1:8080/api/v1/gps/37.7749,-122.4194
```

3. **Check Status**
```bash
curl http://192.168.1.1:8080/api/qmdl-manifest
```

4. **Stop Recording**
```bash
curl -X POST http://192.168.1.1:8080/api/stop-recording
```

5. **Start Analysis**
```bash
curl -X POST http://192.168.1.1:8080/api/analysis/1720080123
```

6. **Get Results**
```bash
curl http://192.168.1.1:8080/api/analysis-report/1720080123
```

7. **Download Data**
```bash
curl http://192.168.1.1:8080/api/zip/1720080123.zip -o capture.zip
```

### Python Example

```python
import requests

class RayhunterClient:
    def __init__(self, base_url):
        self.base_url = base_url
    
    def start_recording(self):
        response = requests.post(f"{self.base_url}/api/start-recording")
        return response.json()
    
    def submit_gps(self, lat, lon):
        response = requests.post(f"{self.base_url}/api/v1/gps/{lat},{lon}")
        return response.json()
    
    def get_alerts(self, recording_id):
        response = requests.get(f"{self.base_url}/api/analysis-report/{recording_id}")
        return response.json()

# Usage
client = RayhunterClient("http://192.168.1.1:8080")
client.start_recording()
client.submit_gps(37.7749, -122.4194)
alerts = client.get_alerts("1720080123")
```

### JavaScript Example

```javascript
class RayhunterClient {
    constructor(baseURL) {
        this.baseURL = baseURL;
    }
    
    async startRecording() {
        const response = await fetch(`${this.baseURL}/api/start-recording`, {
            method: 'POST'
        });
        return response.json();
    }
    
    async submitGPS(lat, lon) {
        const response = await fetch(`${this.baseURL}/api/v1/gps/${lat},${lon}`, {
            method: 'POST'
        });
        return response.json();
    }
    
    async getAlerts(recordingId) {
        const response = await fetch(`${this.baseURL}/api/analysis-report/${recordingId}`);
        return response.json();
    }
}

// Usage
const client = new RayhunterClient('http://192.168.1.1:8080');
client.startRecording();
client.submitGPS(37.7749, -122.4194);
const alerts = await client.getAlerts('1720080123');
``` 