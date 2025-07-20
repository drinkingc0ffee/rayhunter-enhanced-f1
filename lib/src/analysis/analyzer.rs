use chrono::{DateTime, FixedOffset};
use serde::{Deserialize, Serialize};
use std::borrow::Cow;

use crate::util::RuntimeMetadata;
use crate::{diag::MessagesContainer, gsmtap_parser};

use super::{
    core::connection_redirect_downgrade::ConnectionRedirect2GDowngradeAnalyzer,
    core::imsi_requested::ImsiRequestedAnalyzer, 
    information_element::InformationElement,
    core::null_cipher::NullCipherAnalyzer, 
    core::priority_2g_downgrade::LteSib6And7DowngradeAnalyzer,
};

#[cfg(feature = "enhanced_analysis")]
use super::enhanced::cellular_network::CellularNetworkAnalyzer;

#[derive(Debug, Clone, Deserialize, Serialize)]
#[serde(default)]
pub struct AnalyzerConfig {
    pub imsi_requested: bool,
    pub connection_redirect_2g_downgrade: bool,
    pub lte_sib6_and_7_downgrade: bool,
    pub null_cipher: bool,
    pub cellular_network: bool,
}

impl Default for AnalyzerConfig {
    fn default() -> Self {
        AnalyzerConfig {
            imsi_requested: true,
            connection_redirect_2g_downgrade: true,
            lte_sib6_and_7_downgrade: true,
            null_cipher: true,
            cellular_network: true,
        }
    }
}

/// Qualitative measure of how severe a Warning event type is.
/// The levels should break down like this:
///   * Low: if combined with a large number of other Warnings, user should investigate
///   * Medium: if combined with a few other Warnings, user should investigate
///   * High: user should investigate
#[derive(Serialize, Debug, Clone)]
pub enum Severity {
    Low,
    Medium,
    High,
}

/// `QualitativeWarning` events will always be shown to the user in some manner,
/// while `Informational` ones may be hidden based on user settings.
#[derive(Serialize, Debug, Clone)]
#[serde(tag = "type")]
pub enum EventType {
    Informational,
    QualitativeWarning { severity: Severity },
}

/// Events are user-facing signals that can be emitted by an [Analyzer] upon a
/// message being received. They can be used to signifiy an IC detection
/// warning, or just to display some relevant information to the user.
#[derive(Serialize, Debug, Clone)]
pub struct Event {
    pub event_type: EventType,
    pub message: String,
}

/// An [Analyzer] represents one type of heuristic for detecting an IMSI Catcher
/// (IC). While maintaining some amount of state is useful, be mindful of how
/// much memory your [Analyzer] uses at runtime, since rayhunter may run for
/// many hours at a time with dozens of [Analyzers](Analyzer) working in parallel.
pub trait Analyzer {
    /// Returns a user-friendly, concise name for your heuristic.
    fn get_name(&self) -> Cow<str>;

    /// Returns a user-friendly description of what your heuristic looks for,
    /// the types of [Events](Event) it may return, as well as possible false-positive
    /// conditions that may trigger an [Event]. If different [Events](Event) have
    /// different false-positive conditions, consider including them in its
    /// `message` field.
    fn get_description(&self) -> Cow<str>;

    /// Analyze a single [InformationElement], possibly returning an [Event] if your
    /// heuristic deems it relevant. Again, be mindful of any state your
    /// [Analyzer] updates per message, since it may be run over hundreds or
    /// thousands of them alongside many other [Analyzers](Analyzer).
    fn analyze_information_element(&mut self, ie: &InformationElement) -> Option<Event>;
}

/// A [QmdlAnalyzer] operates at the QMDL message level, before GSMTAP parsing.
/// This allows for extraction of cellular network information that may not be
/// available in the parsed GSMTAP messages, such as detailed cell parameters
/// and signal measurements.
pub trait QmdlAnalyzer {
    /// Returns a user-friendly, concise name for your analyzer.
    fn get_name(&self) -> Cow<str>;

    /// Returns a user-friendly description of what your analyzer extracts or analyzes.
    fn get_description(&self) -> Cow<str>;

    /// Analyze a single QMDL message, possibly returning an [Event] if relevant
    /// information is found or extracted.
    fn analyze_qmdl_message(&mut self, qmdl_message: &crate::diag::Message) -> Option<Event>;
}

#[derive(Serialize, Debug)]
pub struct AnalyzerMetadata {
    pub name: String,
    pub description: String,
}

#[derive(Serialize, Debug)]
pub struct ReportMetadata {
    pub analyzers: Vec<AnalyzerMetadata>,
    pub rayhunter: RuntimeMetadata,
}

#[derive(Serialize, Debug, Clone)]
pub struct PacketAnalysis {
    pub timestamp: DateTime<FixedOffset>,
    pub events: Vec<Option<Event>>,
    #[cfg(feature = "gps_correlation")]
    pub gps_correlation: Option<super::enhanced::gps_correlation::GpsCorrelation>,
}

#[derive(Serialize, Debug)]
pub struct AnalysisRow {
    pub timestamp: DateTime<FixedOffset>,
    pub skipped_message_reasons: Vec<String>,
    pub analysis: Vec<PacketAnalysis>,
}

impl AnalysisRow {
    pub fn is_empty(&self) -> bool {
        self.skipped_message_reasons.is_empty() && self.analysis.is_empty()
    }

    pub fn contains_warnings(&self) -> bool {
        for analysis in &self.analysis {
            for event in analysis.events.iter().flatten() {
                if matches!(event.event_type, EventType::QualitativeWarning { .. }) {
                    return true;
                }
            }
        }
        false
    }
}

pub struct Harness {
    analyzers: Vec<Box<dyn Analyzer + Send>>,
    qmdl_analyzers: Vec<Box<dyn QmdlAnalyzer + Send>>,
}

impl Default for Harness {
    fn default() -> Self {
        Self::new()
    }
}

impl Harness {
    pub fn new() -> Self {
        Self {
            analyzers: Vec::new(),
            qmdl_analyzers: Vec::new(),
        }
    }

    pub fn new_with_config(analyzer_config: &AnalyzerConfig) -> Self {
        let mut harness = Harness::new();

        if analyzer_config.imsi_requested {
            harness.add_analyzer(Box::new(ImsiRequestedAnalyzer::new()));
        }
        if analyzer_config.connection_redirect_2g_downgrade {
            harness.add_analyzer(Box::new(ConnectionRedirect2GDowngradeAnalyzer {}));
        }
        if analyzer_config.lte_sib6_and_7_downgrade {
            harness.add_analyzer(Box::new(LteSib6And7DowngradeAnalyzer {}));
        }
        if analyzer_config.null_cipher {
            harness.add_analyzer(Box::new(NullCipherAnalyzer {}));
        }
        #[cfg(feature = "enhanced_analysis")]
        if analyzer_config.cellular_network {
            harness.add_qmdl_analyzer(Box::new(CellularNetworkAnalyzer::new()));
        }

        harness
    }

    pub fn add_analyzer(&mut self, analyzer: Box<dyn Analyzer + Send>) {
        self.analyzers.push(analyzer);
    }

    pub fn add_qmdl_analyzer(&mut self, analyzer: Box<dyn QmdlAnalyzer + Send>) {
        self.qmdl_analyzers.push(analyzer);
    }

    pub fn analyze_qmdl_messages(&mut self, container: MessagesContainer) -> AnalysisRow {
        let mut row = AnalysisRow {
            timestamp: chrono::Local::now().fixed_offset(),
            skipped_message_reasons: Vec::new(),
            analysis: Vec::new(),
        };
        for maybe_qmdl_message in container.into_messages() {
            let qmdl_message = match maybe_qmdl_message {
                Ok(msg) => msg,
                Err(err) => {
                    row.skipped_message_reasons.push(format!("{err:?}"));
                    continue;
                }
            };

            // Run QMDL-level analyzers first
            let qmdl_analysis_result = self.analyze_qmdl_message(&qmdl_message);
            if qmdl_analysis_result.iter().any(Option::is_some) {
                let mut packet_analysis = PacketAnalysis {
                    timestamp: chrono::Local::now().fixed_offset(),
                    events: qmdl_analysis_result,
                    #[cfg(feature = "gps_correlation")]
                    gps_correlation: None, // Will be filled by GPS correlator
                };
                row.analysis.push(packet_analysis);
            }

            // Then run traditional GSMTAP-based analyzers
            let gsmtap_message = match gsmtap_parser::parse(qmdl_message) {
                Ok(msg) => msg,
                Err(err) => {
                    row.skipped_message_reasons.push(format!("{err:?}"));
                    continue;
                }
            };

            let Some((timestamp, gsmtap_msg)) = gsmtap_message else {
                continue;
            };

            let element = match InformationElement::try_from(&gsmtap_msg) {
                Ok(element) => element,
                Err(err) => {
                    row.skipped_message_reasons.push(format!("{err:?}"));
                    continue;
                }
            };

            let analysis_result = self.analyze_information_element(&element);
            if analysis_result.iter().any(Option::is_some) {
                let mut packet_analysis = PacketAnalysis {
                    timestamp: timestamp.to_datetime(),
                    events: analysis_result,
                    #[cfg(feature = "gps_correlation")]
                    gps_correlation: None, // Will be filled by GPS correlator
                };
                row.analysis.push(packet_analysis);
            }
        }
        row
    }

    fn analyze_information_element(&mut self, ie: &InformationElement) -> Vec<Option<Event>> {
        self.analyzers
            .iter_mut()
            .map(|analyzer| analyzer.analyze_information_element(ie))
            .collect()
    }

    fn analyze_qmdl_message(&mut self, msg: &crate::diag::Message) -> Vec<Option<Event>> {
        self.qmdl_analyzers
            .iter_mut()
            .map(|analyzer| analyzer.analyze_qmdl_message(msg))
            .collect()
    }

    pub fn get_names(&self) -> Vec<Cow<'_, str>> {
        let mut names = self.analyzers
            .iter()
            .map(|analyzer| analyzer.get_name())
            .collect::<Vec<_>>();
        
        let qmdl_names = self.qmdl_analyzers
            .iter()
            .map(|analyzer| analyzer.get_name());
        names.extend(qmdl_names);
        names
    }

    pub fn get_descriptions(&self) -> Vec<Cow<'_, str>> {
        let mut descriptions = self.analyzers
            .iter()
            .map(|analyzer| analyzer.get_description())
            .collect::<Vec<_>>();
        
        let qmdl_descriptions = self.qmdl_analyzers
            .iter()
            .map(|analyzer| analyzer.get_description());
        descriptions.extend(qmdl_descriptions);
        descriptions
    }

    pub fn get_metadata(&self) -> ReportMetadata {
        let names = self.get_names();
        let descriptions = self.get_descriptions();
        let mut analyzers = Vec::new();
        for (name, description) in names.iter().zip(descriptions.iter()) {
            analyzers.push(AnalyzerMetadata {
                name: name.to_string(),
                description: description.to_string(),
            });
        }

        let rayhunter = RuntimeMetadata::new();

        ReportMetadata {
            analyzers,
            rayhunter,
        }
    }
}
