package com.rayhunter.client.api

import com.rayhunter.client.models.*
import okhttp3.ResponseBody
import retrofit2.Response
import retrofit2.http.*

/**
 * Retrofit API interface for Rayhunter Enhanced REST API.
 * 
 * This interface defines all the HTTP endpoints available on the device.
 */
interface RayhunterApi {
    
    // System Status
    @GET("api/system-stats")
    suspend fun getSystemStats(): Response<SystemStats>
    
    // Recording Management
    @POST("api/start-recording")
    suspend fun startRecording(): Response<ApiResponse>
    
    @POST("api/stop-recording")
    suspend fun stopRecording(): Response<ApiResponse>
    
    @GET("api/qmdl-manifest")
    suspend fun getManifest(): Response<Manifest>
    
    // GPS Integration
    @POST("api/v1/gps/{latitude},{longitude}")
    suspend fun submitGPS(
        @Path("latitude") latitude: Double,
        @Path("longitude") longitude: Double
    ): Response<GpsResponse>
    
    @GET("api/gps/{recordingId}")
    suspend fun getGPSData(@Path("recordingId") recordingId: String): Response<ResponseBody>
    
    @HEAD("api/gps/{recordingId}")
    suspend fun checkGPSData(@Path("recordingId") recordingId: String): Response<Void>
    
    // Analysis Management
    @GET("api/analysis")
    suspend fun getAnalysisStatus(): Response<AnalysisStatus>
    
    @POST("api/analysis/{recordingId}")
    suspend fun startAnalysis(@Path("recordingId") recordingId: String): Response<AnalysisStatusResponse>
    
    @GET("api/analysis-report/{recordingId}")
    suspend fun getAnalysisReport(@Path("recordingId") recordingId: String): Response<AnalysisReport>
    
    // Data Downloads
    @GET("api/pcap/{recordingId}.pcapng")
    suspend fun downloadPCAP(@Path("recordingId") recordingId: String): Response<ResponseBody>
    
    @GET("api/qmdl/{recordingId}.qmdl")
    suspend fun downloadQMDL(@Path("recordingId") recordingId: String): Response<ResponseBody>
    
    @GET("api/zip/{recordingId}.zip")
    suspend fun downloadZIP(@Path("recordingId") recordingId: String): Response<ResponseBody>
    
    @GET("api/gps/{recordingId}/csv")
    suspend fun downloadGPSCSV(@Path("recordingId") recordingId: String): Response<ResponseBody>
    
    @GET("api/gps/{recordingId}/json")
    suspend fun downloadGPSJSON(@Path("recordingId") recordingId: String): Response<ResponseBody>
    
    @GET("api/gps/{recordingId}/gpx")
    suspend fun downloadGPSGPX(@Path("recordingId") recordingId: String): Response<ResponseBody>
    
    // Generic file download
    @GET
    suspend fun downloadFile(@Url url: String): Response<ResponseBody>
    
    // Data Management
    @POST("api/delete-recording/{recordingId}")
    suspend fun deleteRecording(@Path("recordingId") recordingId: String): Response<ApiResponse>
    
    @POST("api/delete-all-recordings")
    suspend fun deleteAllRecordings(): Response<ApiResponse>
    
    // Configuration
    @GET("api/config")
    suspend fun getConfig(): Response<Config>
    
    @POST("api/config")
    suspend fun setConfig(@Body config: Config): Response<ConfigResponse>
} 