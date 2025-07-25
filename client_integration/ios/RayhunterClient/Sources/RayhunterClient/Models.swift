import Foundation

// MARK: - Base Models

/**
 * Base API response model.
 */
public struct ApiResponse: Codable {
    public let status: String
    public let message: String
    public let data: String?
    
    public init(status: String, message: String, data: String? = nil) {
        self.status = status
        self.message = message
        self.data = data
    }
}

/**
 * System statistics from the device.
 */
public struct SystemStats: Codable {
    public let cpuUsage: Double
    public let memoryUsage: Double
    public let diskUsage: Double
    public let uptime: Int64
    public let temperature: Double
    
    enum CodingKeys: String, CodingKey {
        case cpuUsage = "cpu_usage"
        case memoryUsage = "memory_usage"
        case diskUsage = "disk_usage"
        case uptime
        case temperature
    }
}

/**
 * Recording manifest containing all recordings.
 */
public struct Manifest: Codable {
    public let entries: [ManifestEntry]
    public let currentEntry: Int?
    
    enum CodingKeys: String, CodingKey {
        case entries
        case currentEntry = "current_entry"
    }
}

/**
 * Individual recording entry in the manifest.
 */
public struct ManifestEntry: Codable {
    public let name: String
    public let startTime: String
    public let lastMessageTime: String?
    public let qmdlSizeBytes: Int64
    public let analysisSizeBytes: Int64
    
    enum CodingKeys: String, CodingKey {
        case name
        case startTime = "start_time"
        case lastMessageTime = "last_message_time"
        case qmdlSizeBytes = "qmdl_size_bytes"
        case analysisSizeBytes = "analysis_size_bytes"
    }
}

/**
 * Analysis status information.
 */
public struct AnalysisStatus: Codable {
    public let running: String?
    public let queued: [String]
    public let finished: [String]
}

/**
 * Analysis status response when starting analysis.
 */
public struct AnalysisStatusResponse: Codable {
    public let status: String
    public let message: String
    public let analysisStatus: AnalysisStatus
    
    enum CodingKeys: String, CodingKey {
        case status
        case message
        case analysisStatus = "analysis_status"
    }
}

/**
 * Complete analysis report for a recording.
 */
public struct AnalysisReport: Codable {
    public let metadata: ReportMetadata?
    public let statistics: ReportStatistics
    public let rows: [AnalysisRow]
}

/**
 * Analysis report metadata.
 */
public struct ReportMetadata: Codable {
    public let rayhunter: RayhunterInfo?
    public let analyzers: [AnalyzerInfo]?
}

/**
 * Rayhunter version information.
 */
public struct RayhunterInfo: Codable {
    public let rayhunterVersion: String
    public let systemOs: String
    
    enum CodingKeys: String, CodingKey {
        case rayhunterVersion = "rayhunter_version"
        case systemOs = "system_os"
    }
}

/**
 * Analyzer information.
 */
public struct AnalyzerInfo: Codable {
    public let name: String
    public let description: String
}

/**
 * Analysis report statistics.
 */
public struct ReportStatistics: Codable {
    public let numWarnings: Int
    public let numInformationalLogs: Int
    public let numSkippedPackets: Int
    
    enum CodingKeys: String, CodingKey {
        case numWarnings = "num_warnings"
        case numInformationalLogs = "num_informational_logs"
        case numSkippedPackets = "num_skipped_packets"
    }
}

/**
 * Analysis row containing events.
 */
public struct AnalysisRow: Codable {
    public let analysis: [AnalysisEntry]
}

/**
 * Individual analysis entry with timestamp and events.
 */
public struct AnalysisEntry: Codable {
    public let timestamp: String
    public let events: [AnalysisEvent]
}

/**
 * Analysis event (warning or informational).
 */
public struct AnalysisEvent: Codable {
    public let type: String // "warning" or "informational"
    public let severity: Int? // 0=Low, 1=Medium, 2=High (only for warnings)
    public let message: String
}

/**
 * Device configuration.
 */
public struct Config: Codable {
    public let port: Int
    public let logLevel: String
    public let captureDirectory: String
    
    enum CodingKeys: String, CodingKey {
        case port
        case logLevel = "log_level"
        case captureDirectory = "capture_directory"
    }
}

// MARK: - Error Handling

/**
 * Custom error for Rayhunter client errors.
 */
public enum RayhunterError: Error, LocalizedError {
    case networkError(String, Error)
    case invalidResponse(String)
    case decodingError(String)
    case validationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .networkError(let message, let error):
            return "Network error: \(message) - \(error.localizedDescription)"
        case .invalidResponse(let message):
            return "Invalid response: \(message)"
        case .decodingError(let message):
            return "Decoding error: \(message)"
        case .validationError(let message):
            return "Validation error: \(message)"
        }
    }
} 