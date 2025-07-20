//! Enhanced IMSI Catcher Detection and Analysis
//!
//! This module contains advanced analyzers that extend the core
//! detection capabilities with GPS correlation, cellular network
//! mapping, and comprehensive threat analysis.

#[cfg(feature = "gps_correlation")]
pub mod gps_correlation;

#[cfg(feature = "enhanced_analysis")]
pub mod cellular_network;

// Conditional re-exports based on enabled features
#[cfg(feature = "gps_correlation")]
pub use gps_correlation::*;

#[cfg(feature = "enhanced_analysis")]
pub use cellular_network::*; 