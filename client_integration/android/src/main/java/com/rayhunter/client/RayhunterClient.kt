package com.rayhunter.client

import com.google.gson.Gson
import com.google.gson.GsonBuilder
import com.rayhunter.client.api.RayhunterApi
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
import java.io.IOException
import java.util.concurrent.TimeUnit

/**
 * Main client class for interacting with Rayhunter Enhanced devices.
 * 
 * This client provides a high-level interface for:
 * - Recording management (start/stop)
 * - GPS coordinate submission
 * - Analysis management
 * - Data downloads
 * - System monitoring
 */
class RayhunterClient private constructor(
    private val api: RayhunterApi,
    private val baseUrl: String
) {
    
    companion object {
        private const val DEFAULT_TIMEOUT = 30L
        private const val DEFAULT_RETRY_COUNT = 3
        
        /**
         * Create a new RayhunterClient instance.
         * 
         * @param baseUrl The base URL of the Rayhunter device (e.g., "http://192.168.1.1:8080")
         * @param timeoutSeconds Request timeout in seconds (default: 30)
         * @return Configured RayhunterClient instance
         */
        fun create(baseUrl: String, timeoutSeconds: Long = DEFAULT_TIMEOUT): RayhunterClient {
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
            
            val api = retrofit.create(RayhunterApi::class.java)
            return RayhunterClient(api, baseUrl)
        }
    }
    
    /**
     * Start cellular recording on the device.
     * 
     * @return Result indicating success or failure
     */
    suspend fun startRecording(): Result<ApiResponse> = withContext(Dispatchers.IO) {
        try {
            val response = api.startRecording()
            if (response.isSuccessful) {
                Result.success(response.body() ?: ApiResponse("success", "Recording started"))
            } else {
                Result.failure(RayhunterException("Failed to start recording: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(RayhunterException("Network error starting recording", e))
        }
    }
    
    /**
     * Stop cellular recording on the device.
     * 
     * @return Result indicating success or failure
     */
    suspend fun stopRecording(): Result<ApiResponse> = withContext(Dispatchers.IO) {
        try {
            val response = api.stopRecording()
            if (response.isSuccessful) {
                Result.success(response.body() ?: ApiResponse("success", "Recording stopped"))
            } else {
                Result.failure(RayhunterException("Failed to stop recording: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(RayhunterException("Network error stopping recording", e))
        }
    }
    
    /**
     * Submit GPS coordinates to the device.
     * 
     * @param latitude Latitude coordinate (-90.0 to 90.0)
     * @param longitude Longitude coordinate (-180.0 to 180.0)
     * @return Result with GPS response data
     */
    suspend fun submitGPS(latitude: Double, longitude: Double): Result<GpsResponse> = withContext(Dispatchers.IO) {
        try {
            validateCoordinates(latitude, longitude)
            val response = api.submitGPS(latitude, longitude)
            if (response.isSuccessful) {
                Result.success(response.body() ?: throw RayhunterException("Empty GPS response"))
            } else {
                Result.failure(RayhunterException("Failed to submit GPS: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(RayhunterException("Network error submitting GPS", e))
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
     * Start analysis for a recording.
     * 
     * @param recordingId The recording ID to analyze
     * @return Result with analysis status
     */
    suspend fun startAnalysis(recordingId: String): Result<AnalysisStatusResponse> = withContext(Dispatchers.IO) {
        try {
            val response = api.startAnalysis(recordingId)
            if (response.isSuccessful) {
                Result.success(response.body() ?: throw RayhunterException("Empty analysis response"))
            } else {
                Result.failure(RayhunterException("Failed to start analysis: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(RayhunterException("Network error starting analysis", e))
        }
    }
    
    /**
     * Get analysis report for a recording.
     * 
     * @param recordingId The recording ID
     * @return Result with analysis report
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
     * Download a file from the device.
     * 
     * @param endpoint The API endpoint (e.g., "/api/pcap/123.pcapng")
     * @param outputFile The file to save the download to
     * @return Result indicating success or failure
     */
    suspend fun downloadFile(endpoint: String, outputFile: File): Result<Unit> = withContext(Dispatchers.IO) {
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
                Result.failure(RayhunterException("Failed to download file: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(RayhunterException("Network error downloading file", e))
        }
    }
    
    /**
     * Download PCAP file for a recording.
     * 
     * @param recordingId The recording ID
     * @param outputFile The file to save the PCAP to
     * @return Result indicating success or failure
     */
    suspend fun downloadPCAP(recordingId: String, outputFile: File): Result<Unit> {
        return downloadFile("/api/pcap/$recordingId.pcapng", outputFile)
    }
    
    /**
     * Download QMDL file for a recording.
     * 
     * @param recordingId The recording ID
     * @param outputFile The file to save the QMDL to
     * @return Result indicating success or failure
     */
    suspend fun downloadQMDL(recordingId: String, outputFile: File): Result<Unit> {
        return downloadFile("/api/qmdl/$recordingId.qmdl", outputFile)
    }
    
    /**
     * Download ZIP file for a recording.
     * 
     * @param recordingId The recording ID
     * @param outputFile The file to save the ZIP to
     * @return Result indicating success or failure
     */
    suspend fun downloadZIP(recordingId: String, outputFile: File): Result<Unit> {
        return downloadFile("/api/zip/$recordingId.zip", outputFile)
    }
    
    /**
     * Download GPS data for a recording.
     * 
     * @param recordingId The recording ID
     * @param format The GPS format (csv, json, gpx)
     * @param outputFile The file to save the GPS data to
     * @return Result indicating success or failure
     */
    suspend fun downloadGPS(recordingId: String, format: String = "csv", outputFile: File): Result<Unit> {
        val endpoint = if (format == "csv") {
            "/api/gps/$recordingId"
        } else {
            "/api/gps/$recordingId/$format"
        }
        return downloadFile(endpoint, outputFile)
    }
    
    /**
     * Delete a recording.
     * 
     * @param recordingId The recording ID to delete
     * @return Result indicating success or failure
     */
    suspend fun deleteRecording(recordingId: String): Result<ApiResponse> = withContext(Dispatchers.IO) {
        try {
            val response = api.deleteRecording(recordingId)
            if (response.isSuccessful) {
                Result.success(response.body() ?: ApiResponse("success", "Recording deleted"))
            } else {
                Result.failure(RayhunterException("Failed to delete recording: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(RayhunterException("Network error deleting recording", e))
        }
    }
    
    /**
     * Delete all recordings.
     * 
     * @return Result indicating success or failure
     */
    suspend fun deleteAllRecordings(): Result<ApiResponse> = withContext(Dispatchers.IO) {
        try {
            val response = api.deleteAllRecordings()
            if (response.isSuccessful) {
                Result.success(response.body() ?: ApiResponse("success", "All recordings deleted"))
            } else {
                Result.failure(RayhunterException("Failed to delete all recordings: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(RayhunterException("Network error deleting all recordings", e))
        }
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
     * Set device configuration.
     * 
     * @param config The configuration to set
     * @return Result indicating success or failure
     */
    suspend fun setConfig(config: Config): Result<ConfigResponse> = withContext(Dispatchers.IO) {
        try {
            val response = api.setConfig(config)
            if (response.isSuccessful) {
                Result.success(response.body() ?: throw RayhunterException("Empty config response"))
            } else {
                Result.failure(RayhunterException("Failed to set config: ${response.code()}"))
            }
        } catch (e: Exception) {
            Result.failure(RayhunterException("Network error setting config", e))
        }
    }
    
    /**
     * Check if GPS data exists for a recording.
     * 
     * @param recordingId The recording ID
     * @return Result with boolean indicating existence
     */
    suspend fun hasGPSData(recordingId: String): Result<Boolean> = withContext(Dispatchers.IO) {
        try {
            val response = api.checkGPSData(recordingId)
            Result.success(response.isSuccessful)
        } catch (e: Exception) {
            Result.failure(RayhunterException("Network error checking GPS data", e))
        }
    }
    
    /**
     * Get alerts for a recording (convenience method).
     * 
     * @param recordingId The recording ID
     * @return Result with analysis report containing alerts
     */
    suspend fun getAlerts(recordingId: String): Result<AnalysisReport> {
        return getAnalysisReport(recordingId)
    }
    
    /**
     * Get the base URL of this client.
     * 
     * @return The base URL
     */
    fun getBaseUrl(): String = baseUrl
    
    private fun validateCoordinates(latitude: Double, longitude: Double) {
        if (latitude < -90.0 || latitude > 90.0) {
            throw IllegalArgumentException("Latitude must be between -90.0 and 90.0")
        }
        if (longitude < -180.0 || longitude > 180.0) {
            throw IllegalArgumentException("Longitude must be between -180.0 and 180.0")
        }
    }
} 