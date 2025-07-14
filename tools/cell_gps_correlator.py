#!/usr/bin/env python3
"""
Cell Tower GPS Correlator

This tool correlates cell tower observations from QMDL and NDJSON files
with timestamped GPS coordinates to map cellular network activity to locations.
"""

import json
import sys
import argparse
from datetime import datetime, timezone
from pathlib import Path
import csv
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass
import struct

@dataclass
class GpsPoint:
    timestamp: int  # Unix timestamp
    latitude: float
    longitude: float

@dataclass  
class CellObservation:
    timestamp: int  # Unix timestamp
    cell_id: Optional[int] = None
    lac: Optional[int] = None
    tac: Optional[int] = None
    mcc: Optional[int] = None
    mnc: Optional[int] = None
    pci: Optional[int] = None
    rsrp: Optional[int] = None
    rsrq: Optional[int] = None
    rssi: Optional[int] = None
    rat: Optional[str] = None  # Radio Access Technology
    source: str = "unknown"

@dataclass
class CorrelatedObservation:
    cell_obs: CellObservation
    gps_point: Optional[GpsPoint]
    time_diff: float  # Seconds difference between cell and GPS timestamps

class CellGpsCorrelator:
    def __init__(self, time_threshold: int = 30):
        """
        Initialize correlator
        
        Args:
            time_threshold: Maximum time difference in seconds for correlation
        """
        self.time_threshold = time_threshold
        self.gps_points: List[GpsPoint] = []
        self.cell_observations: List[CellObservation] = []
        
    def load_gps_file(self, gps_file: Path) -> None:
        """Load GPS coordinates from .gps file (format: timestamp, lat, lon)"""
        print(f"Loading GPS data from {gps_file}")
        
        with open(gps_file, 'r') as f:
            for line_num, line in enumerate(f, 1):
                line = line.strip()
                if not line:
                    continue
                    
                try:
                    parts = line.split(',')
                    if len(parts) != 3:
                        print(f"Warning: Invalid GPS line format at line {line_num}: {line}")
                        continue
                        
                    timestamp = int(float(parts[0].strip()))
                    latitude = float(parts[1].strip())
                    longitude = float(parts[2].strip())
                    
                    self.gps_points.append(GpsPoint(timestamp, latitude, longitude))
                    
                except (ValueError, IndexError) as e:
                    print(f"Warning: Could not parse GPS line {line_num}: {line} - {e}")
                    
        self.gps_points.sort(key=lambda x: x.timestamp)
        print(f"Loaded {len(self.gps_points)} GPS points")
        
    def load_ndjson_file(self, ndjson_file: Path) -> None:
        """Load cellular observations from NDJSON file"""
        print(f"Loading cellular data from {ndjson_file}")
        
        with open(ndjson_file, 'r') as f:
            for line_num, line in enumerate(f, 1):
                line = line.strip()
                if not line:
                    continue
                    
                try:
                    data = json.loads(line)
                    
                    # Extract timestamp if available
                    timestamp = None
                    if 'timestamp' in data:
                        # Try to parse various timestamp formats
                        ts_str = data['timestamp']
                        if isinstance(ts_str, (int, float)):
                            timestamp = int(ts_str)
                        elif isinstance(ts_str, str):
                            try:
                                # Try parsing as ISO format
                                dt = datetime.fromisoformat(ts_str.replace('Z', '+00:00'))
                                timestamp = int(dt.timestamp())
                            except ValueError:
                                try:
                                    # Try parsing as Unix timestamp
                                    timestamp = int(float(ts_str))
                                except ValueError:
                                    print(f"Warning: Could not parse timestamp: {ts_str}")
                    
                    # If we have timestamp, create cell observation
                    if timestamp:
                        obs = CellObservation(
                            timestamp=timestamp,
                            source="ndjson"
                        )
                        
                        # Extract cellular parameters if available
                        if 'cell_id' in data:
                            obs.cell_id = data['cell_id']
                        if 'lac' in data:
                            obs.lac = data['lac'] 
                        if 'tac' in data:
                            obs.tac = data['tac']
                        if 'mcc' in data:
                            obs.mcc = data['mcc']
                        if 'mnc' in data:
                            obs.mnc = data['mnc']
                        if 'pci' in data:
                            obs.pci = data['pci']
                        if 'rsrp' in data:
                            obs.rsrp = data['rsrp']
                        if 'rsrq' in data:
                            obs.rsrq = data['rsrq']
                        if 'rssi' in data:
                            obs.rssi = data['rssi']
                        if 'rat' in data:
                            obs.rat = data['rat']
                            
                        self.cell_observations.append(obs)
                        
                except json.JSONDecodeError as e:
                    print(f"Warning: Could not parse JSON line {line_num}: {e}")
                    
        print(f"Loaded {len(self.cell_observations)} cellular observations from NDJSON")

    def parse_qmdl_basic(self, qmdl_file: Path) -> None:
        """Basic QMDL parsing to extract timestamps and cellular info"""
        print(f"Attempting basic QMDL parsing from {qmdl_file}")
        
        with open(qmdl_file, 'rb') as f:
            data = f.read()
            
        offset = 0
        observations_found = 0
        
        while offset < len(data) - 16:
            # Look for potential diagnostic log message patterns
            # This is a simplified approach - real QMDL parsing is more complex
            
            try:
                # Try to find message header patterns
                if data[offset:offset+2] == b'\x7E\x00':  # Common QMDL frame start
                    # Skip frame header, look for timestamp
                    msg_offset = offset + 4
                    if msg_offset + 12 <= len(data):
                        # Try to extract timestamp (8 bytes, little endian)
                        timestamp_bytes = data[msg_offset:msg_offset+8]
                        timestamp_low = struct.unpack('<L', timestamp_bytes[0:4])[0]
                        timestamp_high = struct.unpack('<L', timestamp_bytes[4:8])[0]
                        
                        # Convert to Unix timestamp (simplified)
                        # QMDL timestamps are complex - this is an approximation
                        full_timestamp = (timestamp_high << 32) | timestamp_low
                        
                        # Convert from QMDL time base to Unix (approximate)
                        # This is a rough conversion and may need adjustment
                        unix_timestamp = int(full_timestamp / 1000000) + 946684800  # Approximate
                        
                        # Only keep reasonable timestamps (after year 2000)
                        if unix_timestamp > 946684800 and unix_timestamp < 2147483647:
                            obs = CellObservation(
                                timestamp=unix_timestamp,
                                source="qmdl"
                            )
                            self.cell_observations.append(obs)
                            observations_found += 1
                            
                            # Limit to prevent too many observations
                            if observations_found > 1000:
                                break
                                
            except (struct.error, ValueError):
                pass
                
            offset += 1
            
        print(f"Extracted {observations_found} timestamped observations from QMDL (basic parsing)")
        
    def find_closest_gps(self, timestamp: int) -> Optional[Tuple[GpsPoint, float]]:
        """Find the closest GPS point to a given timestamp"""
        if not self.gps_points:
            return None
            
        min_diff = float('inf')
        closest_gps = None
        
        for gps_point in self.gps_points:
            diff = abs(gps_point.timestamp - timestamp)
            if diff < min_diff:
                min_diff = diff
                closest_gps = gps_point
                
        if min_diff <= self.time_threshold:
            return closest_gps, min_diff
        return None
        
    def correlate_data(self) -> List[CorrelatedObservation]:
        """Correlate cell observations with GPS points"""
        print(f"Correlating {len(self.cell_observations)} cell observations with {len(self.gps_points)} GPS points")
        
        correlated = []
        matched_count = 0
        
        for cell_obs in self.cell_observations:
            gps_result = self.find_closest_gps(cell_obs.timestamp)
            
            if gps_result:
                gps_point, time_diff = gps_result
                correlated.append(CorrelatedObservation(cell_obs, gps_point, time_diff))
                matched_count += 1
            else:
                correlated.append(CorrelatedObservation(cell_obs, None, float('inf')))
                
        print(f"Successfully correlated {matched_count}/{len(self.cell_observations)} observations")
        return correlated
        
    def export_csv(self, correlations: List[CorrelatedObservation], output_file: Path) -> None:
        """Export correlated data to CSV"""
        print(f"Exporting correlated data to {output_file}")
        
        with open(output_file, 'w', newline='') as f:
            writer = csv.writer(f)
            
            # Write header
            header = [
                'cell_timestamp', 'cell_datetime', 'gps_timestamp', 'gps_datetime',
                'latitude', 'longitude', 'time_diff_seconds',
                'cell_id', 'lac', 'tac', 'mcc', 'mnc', 'pci',
                'rsrp', 'rsrq', 'rssi', 'rat', 'source'
            ]
            writer.writerow(header)
            
            # Write data
            for corr in correlations:
                cell = corr.cell_obs
                gps = corr.gps_point
                
                cell_datetime = datetime.fromtimestamp(cell.timestamp, tz=timezone.utc).isoformat()
                
                if gps:
                    gps_datetime = datetime.fromtimestamp(gps.timestamp, tz=timezone.utc).isoformat()
                    row = [
                        cell.timestamp, cell_datetime,
                        gps.timestamp, gps_datetime,
                        gps.latitude, gps.longitude, corr.time_diff,
                        cell.cell_id, cell.lac, cell.tac, cell.mcc, cell.mnc, cell.pci,
                        cell.rsrp, cell.rsrq, cell.rssi, cell.rat, cell.source
                    ]
                else:
                    row = [
                        cell.timestamp, cell_datetime,
                        '', '', '', '', corr.time_diff,
                        cell.cell_id, cell.lac, cell.tac, cell.mcc, cell.mnc, cell.pci,
                        cell.rsrp, cell.rsrq, cell.rssi, cell.rat, cell.source
                    ]
                    
                writer.writerow(row)
                
        print(f"Exported {len(correlations)} correlated observations")

def main():
    parser = argparse.ArgumentParser(description='Correlate cell tower observations with GPS coordinates')
    parser.add_argument('--gps', required=True, help='GPS file (.gps format)')
    parser.add_argument('--ndjson', help='NDJSON file with cellular data')
    parser.add_argument('--qmdl', help='QMDL file with cellular data') 
    parser.add_argument('--output', '-o', default='correlated_data.csv', help='Output CSV file')
    parser.add_argument('--time-threshold', '-t', type=int, default=30, 
                       help='Maximum time difference in seconds for correlation (default: 30)')
    
    args = parser.parse_args()
    
    if not args.ndjson and not args.qmdl:
        print("Error: Must specify either --ndjson or --qmdl file")
        sys.exit(1)
        
    correlator = CellGpsCorrelator(time_threshold=args.time_threshold)
    
    # Load GPS data
    gps_file = Path(args.gps)
    if not gps_file.exists():
        print(f"Error: GPS file {gps_file} not found")
        sys.exit(1)
    correlator.load_gps_file(gps_file)
    
    # Load cellular data
    if args.ndjson:
        ndjson_file = Path(args.ndjson)
        if not ndjson_file.exists():
            print(f"Error: NDJSON file {ndjson_file} not found")
            sys.exit(1)
        correlator.load_ndjson_file(ndjson_file)
        
    if args.qmdl:
        qmdl_file = Path(args.qmdl)
        if not qmdl_file.exists():
            print(f"Error: QMDL file {qmdl_file} not found")
            sys.exit(1)
        correlator.parse_qmdl_basic(qmdl_file)
    
    # Correlate and export
    correlations = correlator.correlate_data()
    
    output_file = Path(args.output)
    correlator.export_csv(correlations, output_file)
    
    print(f"\nCorrelation complete! Results saved to {output_file}")
    print(f"Matched {len([c for c in correlations if c.gps_point])} observations with GPS coordinates")

if __name__ == "__main__":
    main()
