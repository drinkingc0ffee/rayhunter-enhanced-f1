package com.rayhunter.client

import com.google.gson.Gson
import com.google.gson.GsonBuilder
import com.rayhunter.client.api.RayhunterAlertApi
import com.rayhunter.client.models.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.ResponseBody
import retrofit2.Response
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.TimeUnit

/**
 * Mobile client for Rayhunter Enhanced attack detection and environment monitoring.
 * 
 * This client provides a read-only interface for mobile users to:
 * - Monitor their environment for cellular attacks
 * - Get real-time attack alerts and notifications
 * - Access forensic evidence for analysis
 * - Check device status and recording information
 * 
 * IMPORTANT: This is a read-only client - mobile users receive information
 * about their environment, they do not submit data to the device.
 */
class RayhunterAlertClient private constructor(
    private val api: RayhunterAlertApi,
    private val baseUrl: String
) {
    
    companion object {
        private const val DEFAULT_TIMEOUT = 30L
        
        /**
         * Create a new RayhunterAlertClient instance.
         * 
         * @param baseUrl The base URL of the Rayhunter device (e.g., "http://192.168.1.1:8080")
         * @param timeoutSeconds Request timeout in seconds (default: 30)
         * @return Configured RayhunterAlertClient instance
         */
        fun create(baseUrl: String, timeoutSeconds: Long = DEFAULT_TIMEOUT): RayhunterAlertClient {
            val gson = GsonBuilder()
                .setDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'")
                .create()
            
            val client = OkHttpClient.Builder()
                .connectTimeout(timeoutSeconds, TimeUnit.SECONDS)
                .readTimeout(timeoutSeconds, TimeUnit.SECONDS)
                .writeTimeout(timeoutSeconds, TimeUnit.SECONDS)
                .build()
            
            val retrofit = Retrofit.Builder()
                .baseUrl(baseUrl)
                .client(client)
                .addConverterFactory(GsonConverterFactory.create(gson))
                .build()
            
            val api = retrofit.create(RayhunterAlertApi::class.java)
            return RayhunterAlertClient(api, baseUrl)
        }
    }
    
    /**
     * Get the current recording manifest.
     * 
     * @return Result with manifest data
     */
    suspend fun getManifest(): Result<Manifest> = withContext(Dispatchers.IO) {
        try {
            val response = api.getManifest()
            if (response.isSuccessful) {
                Result.success(response.body() ?: throw RayhunterException("Empty manifest response"))
            } else {
                Result.failure(RayhunterException("Failed to get manifest: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(RayhunterException("Network error getting manifest", e))
        }
    }
    
    /**
     * Get system statistics.
     * 
     * @return Result with system stats
     */
    suspend fun getSystemStats(): Result<SystemStats> = withContext(Dispatchers.IO) {
        try {
            val response = api.getSystemStats()
            if (response.isSuccessful) {
                Result.success(response.body() ?: throw RayhunterException("Empty system stats response"))
            } else {
                Result.failure(RayhunterException("Failed to get system stats: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(RayhunterException("Network error getting system stats", e))
        }
    }
    
    /**
     * Get analysis status.
     * 
     * @return Result with analysis status
     */
    suspend fun getAnalysisStatus(): Result<AnalysisStatus> = withContext(Dispatchers.IO) {
        try {
            val response = api.getAnalysisStatus()
            if (response.isSuccessful) {
                Result.success(response.body() ?: throw RayhunterException("Empty analysis status response"))
            } else {
                Result.failure(RayhunterException("Failed to get analysis status: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(RayhunterException("Network error getting analysis status", e))
        }
    }
    
    /**
     * Get analysis report for a recording (contains attack alerts).
     * 
     * @param recordingId The recording ID
     * @return Result with analysis report containing attack alerts
     */
    suspend fun getAnalysisReport(recordingId: String): Result<AnalysisReport> = withContext(Dispatchers.IO) {
        try {
            val response = api.getAnalysisReport(recordingId)
            if (response.isSuccessful) {
                Result.success(response.body() ?: throw RayhunterException("Empty analysis report response"))
            } else {
                Result.failure(RayhunterException("Failed to get analysis report: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(RayhunterException("Network error getting analysis report", e))
        }
    }
    
    /**
     * Get attack alerts for a recording (convenience method).
     * 
     * @param recordingId The recording ID
     * @return Result with analysis report containing attack alerts
     */
    suspend fun getAttackAlerts(recordingId: String): Result<AnalysisReport> {
        return getAnalysisReport(recordingId)
    }
    
    /**
     * Check if a recording has any attack alerts.
     * 
     * @param recordingId The recording ID
     * @return Result with boolean indicating if attacks were detected
     */
    suspend fun hasAttackAlerts(recordingId: String): Result<Boolean> = withContext(Dispatchers.IO) {
        try {
            val report = getAnalysisReport(recordingId).getOrThrow()
            Result.success(report.statistics.numWarnings > 0)
        } catch (e: Exception) {
            Result.failure(RayhunterException("Error checking for attack alerts", e))
        }
    }
    
    /**
     * Get the count of attack alerts for a recording.
     * 
     * @param recordingId The recording ID
     * @return Result with number of attack alerts
     */
    suspend fun getAttackAlertCount(recordingId: String): Result<Int> = withContext(Dispatchers.IO) {
        try {
            val report = getAnalysisReport(recordingId).getOrThrow()
            Result.success(report.statistics.numWarnings)
        } catch (e: Exception) {
            Result.failure(RayhunterException("Error getting attack alert count", e))
        }
    }
    
    /**
     * Get the latest attack alerts from all recordings.
     * 
     * @return Result with list of recordings that have attack alerts
     */
    suspend fun getLatestAttackAlerts(): Result<List<AttackAlertSummary>> = withContext(Dispatchers.IO) {
        try {
            val manifest = getManifest().getOrThrow()
            val alerts = mutableListOf<AttackAlertSummary>()
            
            for (entry in manifest.entries) {
                val report = getAnalysisReport(entry.name).getOrNull()
                if (report != null && report.statistics.numWarnings > 0) {
                    alerts.add(AttackAlertSummary(
                        recordingId = entry.name,
                        startTime = entry.startTime,
                        attackCount = report.statistics.numWarnings,
                        lastMessageTime = entry.lastMessageTime
                    ))
                }
            }
            
            Result.success(alerts)
        } catch (e: Exception) {
            Result.failure(RayhunterException("Error getting latest attack alerts", e))
        }
    }
    
    /**
     * Download evidence files for forensic analysis.
     * 
     * @param endpoint The API endpoint (e.g., "/api/pcap/123.pcapng")
     * @param outputFile The file to save the download to
     * @return Result indicating success or failure
     */
    suspend fun downloadEvidenceFile(endpoint: String, outputFile: File): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            val response = api.downloadFile(endpoint)
            if (response.isSuccessful) {
                val body = response.body() ?: throw RayhunterException("Empty download response")
                val inputStream = body.byteStream()
                val outputStream = FileOutputStream(outputFile)
                
                inputStream.use { input ->
                    outputStream.use { output ->
                        input.copyTo(output)
                    }
                }
                Result.success(Unit)
            } else {
                Result.failure(RayhunterException("Failed to download evidence file: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(RayhunterException("Network error downloading evidence file", e))
        }
    }
    
    /**
     * Download PCAP evidence file for a recording.
     * 
     * @param recordingId The recording ID
     * @param outputFile The file to save the PCAP to
     * @return Result indicating success or failure
     */
    suspend fun downloadPCAPEvidence(recordingId: String, outputFile: File): Result<Unit> {
        return downloadEvidenceFile("/api/pcap/$recordingId.pcapng", outputFile)
    }
    
    /**
     * Download QMDL evidence file for a recording.
     * 
     * @param recordingId The recording ID
     * @param outputFile The file to save the QMDL to
     * @return Result indicating success or failure
     */
    suspend fun downloadQMDLEvidence(recordingId: String, outputFile: File): Result<Unit> {
        return downloadEvidenceFile("/api/qmdl/$recordingId.qmdl", outputFile)
    }
    
    /**
     * Download ZIP evidence archive for a recording.
     * 
     * @param recordingId The recording ID
     * @param outputFile The file to save the ZIP to
     * @return Result indicating success or failure
     */
    suspend fun downloadZIPEvidence(recordingId: String, outputFile: File): Result<Unit> {
        return downloadEvidenceFile("/api/zip/$recordingId.zip", outputFile)
    }
    
    /**
     * Get device configuration.
     * 
     * @return Result with configuration data
     */
    suspend fun getConfig(): Result<Config> = withContext(Dispatchers.IO) {
        try {
            val response = api.getConfig()
            if (response.isSuccessful) {
                Result.success(response.body() ?: throw RayhunterException("Empty config response"))
            } else {
                Result.failure(RayhunterException("Failed to get config: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(RayhunterException("Network error getting config", e))
        }
    }
    
    /**
     * Get the base URL of this client.
     * 
     * @return The base URL
     */
    fun getBaseUrl(): String = baseUrl
}

/**
 * Summary of attack alerts for a recording.
 */
data class AttackAlertSummary(
    val recordingId: String,
    val startTime: String,
    val attackCount: Int,
    val lastMessageTime: String?
) 