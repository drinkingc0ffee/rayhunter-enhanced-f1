# Rayhunter Enhanced Client Integration

This directory contains comprehensive REST API documentation and **read-only client libraries** for mobile users to monitor their environment for cellular attacks.

## 📱 **Mobile-Focused Design**

The client libraries are designed for **mobile users to receive information about their environment**. Mobile users can monitor for attacks and access forensic data, but cannot control the device or submit data.

**Key Features:**
- ✅ **Environment Monitoring**: Check for IMSI catchers and cellular attacks
- ✅ **Attack Alerts**: Get notified when attacks are detected  
- ✅ **Evidence Access**: Download forensic data for analysis
- ✅ **Status Information**: Check device and recording status
- ❌ **Device Control**: Cannot start/stop recordings or control the device
- ❌ **Data Submission**: Cannot submit GPS or other data to the device

## 📋 Contents

- **📖 API Documentation**: Complete REST API reference
- **🤖 Android Client**: Kotlin library for environment monitoring
- **🍎 iOS Client**: Swift library for environment monitoring
- **📱 Example Apps**: Sample implementations
- **🧪 Testing Tools**: API testing utilities

## 🚀 Quick Start

### Android
```kotlin
// Add to your app's build.gradle
implementation files('libs/rayhunter-client.aar')

// Initialize read-only client
val client = RayhunterAlertClient.create("http://192.168.1.1:8080")

// Check for attack alerts
val alerts = client.getLatestAttackAlerts()

// Get system status
val stats = client.getSystemStats()
```

### iOS
```swift
// Add to your Podfile
pod 'RayhunterClient'

// Initialize read-only client
let client = RayhunterAlertClient(baseURL: "http://192.168.1.1:8080")

// Check for attack alerts
client.getLatestAttackAlerts { result in
    // Handle alerts
}

// Get system status
client.getSystemStats { result in
    // Handle status
}
```

## 🔗 API Base URL

The default API base URL is: `http://192.168.1.1:8080`

You can discover the device IP by:
1. Connecting to the Rayhunter device's WiFi network
2. Checking the device's web interface
3. Using network discovery tools

## 📊 Data Formats

All API responses use standard formats:
- **JSON**: For structured data and metadata
- **Binary**: For evidence file downloads (PCAP, QMDL, ZIP)

## 🔐 Authentication

Currently, the API does not require authentication. This is designed for local network use where the device acts as a WiFi hotspot.

## 📱 Mobile App Integration

### Key Features for Mobile Apps
- **Real-time monitoring**: Poll for new attack alerts every few seconds
- **Attack detection**: Get notified when IMSI catchers are detected
- **Evidence access**: Download forensic data for analysis
- **Status monitoring**: Check device and recording status

### Best Practices
- **Error handling**: Implement robust error handling for network issues
- **Background processing**: Use background tasks for continuous monitoring
- **Data caching**: Cache downloaded evidence files locally
- **User notifications**: Alert users when attacks are detected

## 🎯 **Read-Only Design Philosophy**

### ✅ **What Mobile Users Can Do**
- Monitor their environment for attacks
- Receive real-time attack alerts
- Access forensic evidence data
- Check device status and health
- View recording information

### ❌ **What Mobile Users Cannot Do**
- Start or stop recordings
- Control device operations
- Submit GPS coordinates
- Delete recordings
- Modify device configuration

## 🧪 Testing

Use the included testing tools to verify API functionality:

```bash
# Test basic connectivity
python3 test_api.py --host 192.168.1.1

# Test environment monitoring
python3 test_monitoring.py --host 192.168.1.1
```

## 📄 License

This client integration code follows the same MIT license as the main Rayhunter Enhanced project.

## 🤝 Contributing

When contributing to the client libraries:
1. Follow the existing code style
2. Add comprehensive error handling
3. Include unit tests
4. Update documentation
5. Test on real devices
6. **Maintain read-only design**: Do not add device control functionality

## 📞 Support

For issues with the client libraries:
1. Check the API documentation first
2. Review the example apps
3. Test with the provided testing tools
4. Open an issue with detailed error information

## 🔒 Security Notice

**IMPORTANT**: These client libraries are designed for read-only environment monitoring. Mobile users receive information about their environment but cannot control the device or submit data. This design protects both users and the device from potential abuse. 