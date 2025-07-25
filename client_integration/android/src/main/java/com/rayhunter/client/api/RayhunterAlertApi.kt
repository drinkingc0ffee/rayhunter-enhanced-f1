package com.rayhunter.client.api

import com.rayhunter.client.models.*
import okhttp3.ResponseBody
import retrofit2.Response
import retrofit2.http.*

/**
 * Read-only Retrofit API interface for Rayhunter Enhanced attack detection.
 * 
 * This interface defines HTTP endpoints for mobile users to monitor their environment.
 * IMPORTANT: This is a read-only API - mobile users receive information about their
 * environment, they do not submit data or control the device.
 */
interface RayhunterAlertApi {
    
    // System Status
    @GET("api/system-stats")
    suspend fun getSystemStats(): Response<SystemStats>
    
    // Recording Information (Read-Only)
    @GET("api/qmdl-manifest")
    suspend fun getManifest(): Response<Manifest>
    
    // Analysis Information (Read-Only)
    @GET("api/analysis")
    suspend fun getAnalysisStatus(): Response<AnalysisStatus>
    
    @GET("api/analysis-report/{recordingId}")
    suspend fun getAnalysisReport(@Path("recordingId") recordingId: String): Response<AnalysisReport>
    
    // Evidence Downloads (Read-Only)
    @GET("api/pcap/{recordingId}.pcapng")
    suspend fun downloadPCAP(@Path("recordingId") recordingId: String): Response<ResponseBody>
    
    @GET("api/qmdl/{recordingId}.qmdl")
    suspend fun downloadQMDL(@Path("recordingId") recordingId: String): Response<ResponseBody>
    
    @GET("api/zip/{recordingId}.zip")
    suspend fun downloadZIP(@Path("recordingId") recordingId: String): Response<ResponseBody>
    
    // Generic file download
    @GET
    suspend fun downloadFile(@Url url: String): Response<ResponseBody>
    
    // Configuration (Read-Only)
    @GET("api/config")
    suspend fun getConfig(): Response<Config>
} 