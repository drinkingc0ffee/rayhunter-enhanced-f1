//! Rayhunter Analysis Framework
//!
//! This module provides both core EFF analyzers and enhanced analysis capabilities
//! organized into separate modules for maintainability and optional feature activation.

pub mod analyzer;
pub mod information_element;
pub mod util;

// Core EFF analyzers - always available
pub mod core;

// Enhanced analyzers - conditionally compiled based on features
#[cfg(any(feature = "enhanced_analysis", feature = "gps_correlation"))]
pub mod enhanced;

// Re-export core functionality for backwards compatibility
pub use core::*;

// Conditionally re-export enhanced functionality
#[cfg(any(feature = "enhanced_analysis", feature = "gps_correlation"))]
pub use enhanced::*;
