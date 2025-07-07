# Rayhunter Enhanced 🔬📡

## IMSI Catcher Detection and Cellular Monitoring System

Rayhunter Enhanced is an advanced cellular monitoring and IMSI catcher detection system designed for security researchers, network analysts, and privacy advocates. This enhanced version provides comprehensive cellular data extraction capabilities with expanded coverage and advanced analysis features.

### 🎯 What is Rayhunter?

Rayhunter helps detect and analyze potential IMSI catchers (cell-site simulators) by monitoring cellular network behavior and identifying suspicious patterns. It captures detailed cellular network information to help users understand their mobile connectivity and detect potential surveillance devices.

### 🚀 Key Features

#### 🛡️ **IMSI Catcher Detection**
- **Rogue cell detection** through neighbor cell analysis
- **Signal anomaly identification** with multi-metric monitoring
- **Location tracking prevention** via TAC/LAC monitoring
- **Fake base station identification** using cellular fingerprinting

#### 📊 **Comprehensive Cellular Data Extraction**
- **Network Identifiers**: MCC/MNC (Mobile Country/Network Code)
- **Location Information**: LAC/TAC (Location/Tracking Area Code), Cell ID/PCI
- **Cell Details**: eNodeB ID, Sector information, Physical Cell Identity
- **Signal Metrics**: RSRP, RSRQ, SINR signal strength measurements
- **Multi-Technology Support**: 2G/3G/4G/5G network analysis
- **Neighbor Cell Tracking**: Monitor surrounding cell towers

#### 📍 **GPS Integration**
- **Real-time location correlation** with cellular captures
- **External GPS support** via REST API endpoints
- **Mobile app compatibility** (GPS2REST-Android)
- **Multiple export formats** (CSV, JSON, GPX)
- **Per-scan GPS files** with automatic timestamp correlation

#### 📡 **Web Interface**
- **Real-time monitoring** dashboard
- **Data download** in multiple formats (PCAP, QMDL, ZIP)
- **Analysis tools** for captured data
- **Mobile-responsive** design

### 🔧 System Requirements

#### **Supported Hardware**
- **Primary**: Orbic RC400L mobile hotspot
- **Secondary**: TP-Link M7310/M7350 devices
- **Chipset**: Qualcomm MDM9225 and compatible modems
- **Connection**: USB or ADB access to device

#### **Development Environment**
- **Rust**: Latest stable toolchain
- **Target**: ARM cross-compilation (`armv7-unknown-linux-musleabihf`)
- **Node.js**: v16+ and npm (for web interface)
- **ADB**: Android Debug Bridge for device communication

#### **Operating System**
- **Linux**: Primary development platform
- **macOS**: Supported for development
- **Windows**: Supported via WSL

### 📋 Installation

#### **Quick Start**
```bash
# Clone the repository
git clone https://github.com/your-repo/rayhunter-enhanced.git
cd rayhunter-enhanced

# Build and deploy to device
./make.sh
```

#### **Manual Installation**
```bash
# 1. Setup Rust cross-compilation
rustup target add armv7-unknown-linux-musleabihf

# 2. Build web interface
cd bin/web && npm install && npm run build && cd ../..

# 3. Build for device
cargo build --profile firmware --target armv7-unknown-linux-musleabihf

# 4. Deploy to device via ADB
adb push target/armv7-unknown-linux-musleabihf/firmware/rayhunter-daemon /data/rayhunter/
```

### 🔍 How It Works

#### **Data Collection**
Rayhunter interfaces with the cellular modem's diagnostic interface to capture detailed network information, including:

- **Cell tower information** and network parameters
- **Signal strength measurements** and quality metrics
- **Network registration events** and location updates
- **Neighbor cell discoveries** and handoff information

#### **Analysis Engine**
The system analyzes captured data to detect:

1. **Inconsistent network behavior** that may indicate rogue base stations
2. **Signal anomalies** that deviate from expected patterns
3. **Location tracking attempts** through area code monitoring
4. **Suspicious cell configurations** not matching known networks

#### **Output Formats**
- **PCAP files**: Network packet captures for Wireshark analysis
- **QMDL files**: Raw cellular diagnostic logs
- **CSV exports**: Structured data for spreadsheet analysis
- **JSON data**: Machine-readable format for custom analysis

### 📱 GPS API Usage

#### **Submit GPS Coordinates**
```bash
# Using curl (GET method - GPS2REST-Android compatible)
curl "http://192.168.1.1:8080/api/v1/gps/37.7749,-122.4194"

# Using curl (POST method)
curl -X POST "http://192.168.1.1:8080/api/v1/gps/37.7749,-122.4194"
```

#### **Download GPS Data**
```bash
# Get GPS data for a recording session
curl "http://192.168.1.1:8080/api/gps/1720080123/csv" -o gps_data.csv
```

### 🎯 Use Cases

#### **Security Research**
- **IMSI catcher detection** in high-risk environments
- **Network security auditing** for organizations
- **Mobile privacy assessment** for individuals

#### **Network Analysis**
- **Cell tower mapping** and coverage analysis
- **Signal quality assessment** for specific locations
- **Network performance monitoring** during travel

#### **Educational Purposes**
- **Cellular technology education** with real-world data
- **Security awareness training** about mobile threats
- **Research projects** on mobile network security

### 🔐 Privacy and Ethics

#### **Privacy Protection**
- **Local processing only** - no cloud connectivity
- **User-controlled data** retention and export
- **Open source transparency** for security verification

#### **Responsible Use**
This tool is intended for:
- ✅ **Security research and education**
- ✅ **Network analysis and troubleshooting**  
- ✅ **Personal privacy protection**
- ✅ **Academic research with proper consent**

**NOT intended for:**
- ❌ Illegal surveillance or interception
- ❌ Unauthorized monitoring of others
- ❌ Commercial espionage
- ❌ Violation of privacy laws

### 📚 Documentation

- **[Installation Guide](doc/installing-from-source.md)** - Detailed setup instructions
- **[Device Support](doc/supported-devices.md)** - Hardware compatibility information
- **[Data Analysis](doc/analyzing-a-capture.md)** - How to interpret captured data
- **[Configuration](doc/configuration.md)** - System configuration options
- **[GPS Integration](GPS_API_DOCUMENTATION.md)** - GPS API documentation

### 🤝 Contributing

We welcome contributions to improve Rayhunter Enhanced:

- **Device support**: Add compatibility for new hardware
- **Analysis algorithms**: Improve detection capabilities
- **User interface**: Enhance web interface and usability
- **Documentation**: Help others understand and use the system

### ⚖️ Legal Notice

This software is provided for educational and research purposes only. Users are responsible for compliance with all applicable laws and regulations regarding cellular monitoring, privacy, and telecommunications in their jurisdiction.

### 📄 License

GNU General Public License v3.0 - see [LICENSE](LICENSE) for details.

### 🙏 Acknowledgments

- **Electronic Frontier Foundation** for the original Rayhunter project
- **Cellular security research community** for ongoing contributions
- **Open source contributors** who make this project possible

---

**⚠️ Disclaimer**: This tool is for legitimate security research and education only. Ensure compliance with local laws and regulations.

**🔬 Enhanced by**: [@drinkingc0ffee](https://github.com/drinkingc0ffee)
**📅 Fork Date**: July 2025
**🔗 Original**: [EFF Rayhunter](https://github.com/EFForg/rayhunter)
