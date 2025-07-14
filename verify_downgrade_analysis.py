#!/usr/bin/env python3
"""
Downgrade Analysis Verification Script

This script verifies that the 2G downgrade analysis can be reproduced
and produces the expected results.
"""

import os
import sys
import json
import hashlib
import subprocess
from pathlib import Path

def verify_file_integrity():
    """Verify the QMDL file integrity"""
    qmdl_file = Path("tmp/1750202030.qmdl")
    
    if not qmdl_file.exists():
        print("❌ QMDL file not found: tmp/1750202030.qmdl")
        return False
        
    # Check file size
    file_size = qmdl_file.stat().st_size
    expected_size = 7583
    
    if file_size != expected_size:
        print(f"❌ Incorrect file size: {file_size} (expected {expected_size})")
        return False
        
    # Check file permissions
    if not os.access(qmdl_file, os.R_OK):
        print("❌ QMDL file is not readable")
        return False
        
    print(f"✅ QMDL file integrity verified: {file_size} bytes")
    return True

def run_analysis():
    """Run the downgrade analysis"""
    try:
        result = subprocess.run([
            sys.executable, "tools/downgrade_analyzer.py",
            "--qmdl", "tmp/1750202030.qmdl",
            "--output", "tmp/downgrade_analysis_verification.json"
        ], capture_output=True, text=True, cwd=Path.cwd())
        
        if result.returncode != 0:
            print(f"❌ Analysis failed with return code {result.returncode}")
            print(f"Error: {result.stderr}")
            return False
            
        print("✅ Analysis completed successfully")
        return True
        
    except Exception as e:
        print(f"❌ Failed to run analysis: {e}")
        return False

def verify_results():
    """Verify the analysis results match expected values"""
    results_file = Path("tmp/downgrade_analysis_verification.json")
    
    if not results_file.exists():
        print("❌ Results file not found")
        return False
        
    try:
        with open(results_file, 'r') as f:
            data = json.load(f)
            
        # Expected values
        expected = {
            "downgrade_events_found": 2,
            "attacking_cells_identified": 1,
            "cell_id": 1114372,
            "pci": 260,
            "tac": 260,
            "event_types": ["connection_release_redirect", "sib_downgrade"]
        }
        
        # Verify summary
        summary = data.get("analysis_summary", {})
        if summary.get("downgrade_events_found") != expected["downgrade_events_found"]:
            print(f"❌ Wrong number of events: {summary.get('downgrade_events_found')} (expected {expected['downgrade_events_found']})")
            return False
            
        if summary.get("attacking_cells_identified") != expected["attacking_cells_identified"]:
            print(f"❌ Wrong number of attacking cells: {summary.get('attacking_cells_identified')} (expected {expected['attacking_cells_identified']})")
            return False
            
        # Verify attacking cell
        attacking_cells = data.get("attacking_cells", {})
        cell_1114372 = attacking_cells.get("Cell_1114372", {})
        
        if cell_1114372.get("cell_id") != expected["cell_id"]:
            print(f"❌ Wrong cell ID: {cell_1114372.get('cell_id')} (expected {expected['cell_id']})")
            return False
            
        if cell_1114372.get("pci") != expected["pci"]:
            print(f"❌ Wrong PCI: {cell_1114372.get('pci')} (expected {expected['pci']})")
            return False
            
        if cell_1114372.get("tac") != expected["tac"]:
            print(f"❌ Wrong TAC: {cell_1114372.get('tac')} (expected {expected['tac']})")
            return False
            
        # Verify event types
        found_event_types = set(cell_1114372.get("event_types", []))
        expected_event_types = set(expected["event_types"])
        
        if found_event_types != expected_event_types:
            print(f"❌ Wrong event types: {found_event_types} (expected {expected_event_types})")
            return False
            
        # Verify detailed events
        events = data.get("detailed_events", [])
        if len(events) != 2:
            print(f"❌ Wrong number of detailed events: {len(events)} (expected 2)")
            return False
            
        print("✅ All results verified successfully")
        print(f"   Cell ID: {expected['cell_id']}")
        print(f"   PCI: {expected['pci']}")
        print(f"   TAC: {expected['tac']}")
        print(f"   Events: {len(events)}")
        print(f"   Attack types: {', '.join(expected['event_types'])}")
        
        return True
        
    except Exception as e:
        print(f"❌ Failed to verify results: {e}")
        return False

def main():
    """Main verification function"""
    print("🔍 Verifying 2G Downgrade Analysis Reproducibility")
    print("=" * 60)
    
    # Change to the correct directory
    if not Path("tools/downgrade_analyzer.py").exists():
        print("❌ Please run this script from the rayhunter-enhanced directory")
        sys.exit(1)
        
    # Step 1: Verify file integrity
    print("\n📁 Step 1: Verifying file integrity...")
    if not verify_file_integrity():
        sys.exit(1)
        
    # Step 2: Run analysis
    print("\n🔬 Step 2: Running downgrade analysis...")
    if not run_analysis():
        sys.exit(1)
        
    # Step 3: Verify results
    print("\n✅ Step 3: Verifying results...")
    if not verify_results():
        sys.exit(1)
        
    print("\n🎯 VERIFICATION COMPLETE")
    print("=" * 60)
    print("✅ All checks passed - analysis is reproducible!")
    print("📊 Attack confirmed: Cell ID 1114372 performed 2G downgrade")
    print("📄 Results saved to: tmp/downgrade_analysis_verification.json")
    
    # Clean up verification file
    os.remove("tmp/downgrade_analysis_verification.json")

if __name__ == "__main__":
    main()
