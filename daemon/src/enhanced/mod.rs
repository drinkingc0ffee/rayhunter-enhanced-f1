//! Enhanced Daemon Functionality
//!
//! This module contains enhanced features for the rayhunter daemon
//! including GPS integration, enhanced analysis capabilities, and
//! advanced correlation algorithms.

#[cfg(feature = "enhanced_analysis")]
pub mod enhanced_analysis;

#[cfg(feature = "gps_support")]
pub mod gps;

#[cfg(feature = "gps_correlation")]
pub mod gps_correlation;

// Conditional re-exports
#[cfg(feature = "enhanced_analysis")]
pub use enhanced_analysis::*;

#[cfg(feature = "gps_support")]
pub use gps::*;

#[cfg(feature = "gps_correlation")]
pub use gps_correlation::*; 