# Enhanced Analysis Tools

This directory contains advanced Python scripts that provide enhanced analysis capabilities for rayhunter data.

## GPS Correlation Tools

- **`rayhunter_gps_correlator.py`** - Correlates cellular data with GPS coordinates
- **`gps_correlation_summary.py`** - Generates summaries of GPS correlation analysis

## Enhanced Cellular Analysis

- **`enhanced_cellular_correlator.py`** - Advanced cellular network correlation analysis
- **`enhanced_cellular_extractor.py`** - Extract detailed cellular network information
- **`enhanced_qmdl_correlator.py`** - Enhanced QMDL file correlation and analysis
- **`comprehensive_cellular_correlator.py`** - Comprehensive cellular threat correlation

## Usage

These tools work in conjunction with the enhanced rayhunter features when compiled with:

```bash
cargo build --features="enhanced_analysis,gps_correlation"
```

## Requirements

See `tools/requirements.txt` for Python dependencies.

## Integration

These enhanced tools are automatically available when enhanced features are enabled in the rayhunter configuration. 