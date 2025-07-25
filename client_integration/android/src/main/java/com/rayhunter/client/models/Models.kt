package com.rayhunter.client.models

import com.google.gson.annotations.SerializedName
import java.util.Date

/**
 * Base API response model.
 */
data class ApiResponse(
    val status: String,
    val message: String,
    val data: Any? = null
)

/**
 * GPS coordinate submission response.
 */
data class GpsResponse(
    val status: String,
    val message: String,
    val data: GpsCoordinate
)

/**
 * GPS coordinate data.
 */
data class GpsCoordinate(
    val timestamp: String,
    val latitude: Double,
    val longitude: Double
)

/**
 * System statistics from the device.
 */
data class SystemStats(
    @SerializedName("cpu_usage")
    val cpuUsage: Double,
    @SerializedName("memory_usage")
    val memoryUsage: Double,
    @SerializedName("disk_usage")
    val diskUsage: Double,
    val uptime: Long,
    val temperature: Double
)

/**
 * Recording manifest containing all recordings.
 */
data class Manifest(
    val entries: List<ManifestEntry>,
    @SerializedName("current_entry")
    val currentEntry: Int?
)

/**
 * Individual recording entry in the manifest.
 */
data class ManifestEntry(
    val name: String,
    @SerializedName("start_time")
    val startTime: String,
    @SerializedName("last_message_time")
    val lastMessageTime: String?,
    @SerializedName("qmdl_size_bytes")
    val qmdlSizeBytes: Long,
    @SerializedName("analysis_size_bytes")
    val analysisSizeBytes: Long
)

/**
 * Analysis status information.
 */
data class AnalysisStatus(
    val running: String?,
    val queued: List<String>,
    val finished: List<String>
)

/**
 * Analysis status response when starting analysis.
 */
data class AnalysisStatusResponse(
    val status: String,
    val message: String,
    @SerializedName("analysis_status")
    val analysisStatus: AnalysisStatus
)

/**
 * Complete analysis report for a recording.
 */
data class AnalysisReport(
    val metadata: ReportMetadata?,
    val statistics: ReportStatistics,
    val rows: List<AnalysisRow>
)

/**
 * Analysis report metadata.
 */
data class ReportMetadata(
    val rayhunter: RayhunterInfo?,
    val analyzers: List<AnalyzerInfo>?
)

/**
 * Rayhunter version information.
 */
data class RayhunterInfo(
    @SerializedName("rayhunter_version")
    val rayhunterVersion: String,
    @SerializedName("system_os")
    val systemOs: String
)

/**
 * Analyzer information.
 */
data class AnalyzerInfo(
    val name: String,
    val description: String
)

/**
 * Analysis report statistics.
 */
data class ReportStatistics(
    @SerializedName("num_warnings")
    val numWarnings: Int,
    @SerializedName("num_informational_logs")
    val numInformationalLogs: Int,
    @SerializedName("num_skipped_packets")
    val numSkippedPackets: Int
)

/**
 * Analysis row containing events.
 */
data class AnalysisRow(
    val analysis: List<AnalysisEntry>
)

/**
 * Individual analysis entry with timestamp and events.
 */
data class AnalysisEntry(
    val timestamp: String,
    val events: List<AnalysisEvent>
)

/**
 * Analysis event (warning or informational).
 */
data class AnalysisEvent(
    val type: String, // "warning" or "informational"
    val severity: Int?, // 0=Low, 1=Medium, 2=High (only for warnings)
    val message: String
)

/**
 * Device configuration.
 */
data class Config(
    val port: Int,
    @SerializedName("log_level")
    val logLevel: String,
    @SerializedName("capture_directory")
    val captureDirectory: String
)

/**
 * Configuration response.
 */
data class ConfigResponse(
    val status: String,
    val message: String
)

/**
 * Custom exception for Rayhunter client errors.
 */
class RayhunterException : Exception {
    constructor(message: String) : super(message)
    constructor(message: String, cause: Throwable) : super(message, cause)
} 