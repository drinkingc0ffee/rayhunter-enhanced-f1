import Foundation
import Alamofire

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
public class RayhunterAlertClient {
    
    private let baseURL: String
    private let session: Session
    
    /**
     * Create a new RayhunterAlertClient instance.
     * 
     * - Parameter baseURL: The base URL of the Rayhunter device (e.g., "http://192.168.1.1:8080")
     * - Parameter timeout: Request timeout in seconds (default: 30)
     */
    public init(baseURL: String, timeout: TimeInterval = 30) {
        self.baseURL = baseURL
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        
        self.session = Session(configuration: configuration)
    }
    
    // MARK: - Recording Information
    
    /**
     * Get the current recording manifest.
     * 
     * - Parameter completion: Completion handler with result
     */
    public func getManifest(completion: @escaping (Result<Manifest, RayhunterError>) -> Void) {
        let url = "\(baseURL)/api/qmdl-manifest"
        
        session.request(url)
            .validate()
            .responseDecodable(of: Manifest.self) { response in
                switch response.result {
                case .success(let manifest):
                    completion(.success(manifest))
                case .failure(let error):
                    completion(.failure(RayhunterError.networkError("Failed to get manifest", error)))
                }
            }
    }
    
    // MARK: - System Monitoring
    
    /**
     * Get system statistics.
     * 
     * - Parameter completion: Completion handler with result
     */
    public func getSystemStats(completion: @escaping (Result<SystemStats, RayhunterError>) -> Void) {
        let url = "\(baseURL)/api/system-stats"
        
        session.request(url)
            .validate()
            .responseDecodable(of: SystemStats.self) { response in
                switch response.result {
                case .success(let stats):
                    completion(.success(stats))
                case .failure(let error):
                    completion(.failure(RayhunterError.networkError("Failed to get system stats", error)))
                }
            }
    }
    
    // MARK: - Analysis Information
    
    /**
     * Get analysis status.
     * 
     * - Parameter completion: Completion handler with result
     */
    public func getAnalysisStatus(completion: @escaping (Result<AnalysisStatus, RayhunterError>) -> Void) {
        let url = "\(baseURL)/api/analysis"
        
        session.request(url)
            .validate()
            .responseDecodable(of: AnalysisStatus.self) { response in
                switch response.result {
                case .success(let status):
                    completion(.success(status))
                case .failure(let error):
                    completion(.failure(RayhunterError.networkError("Failed to get analysis status", error)))
                }
            }
    }
    
    /**
     * Get analysis report for a recording (contains attack alerts).
     * 
     * - Parameter recordingId: The recording ID
     * - Parameter completion: Completion handler with result
     */
    public func getAnalysisReport(recordingId: String, completion: @escaping (Result<AnalysisReport, RayhunterError>) -> Void) {
        let url = "\(baseURL)/api/analysis-report/\(recordingId)"
        
        session.request(url)
            .validate()
            .responseDecodable(of: AnalysisReport.self) { response in
                switch response.result {
                case .success(let report):
                    completion(.success(report))
                case .failure(let error):
                    completion(.failure(RayhunterError.networkError("Failed to get analysis report", error)))
                }
            }
    }
    
    /**
     * Get attack alerts for a recording (convenience method).
     * 
     * - Parameter recordingId: The recording ID
     * - Parameter completion: Completion handler with result
     */
    public func getAttackAlerts(recordingId: String, completion: @escaping (Result<AnalysisReport, RayhunterError>) -> Void) {
        getAnalysisReport(recordingId: recordingId, completion: completion)
    }
    
    /**
     * Check if a recording has any attack alerts.
     * 
     * - Parameter recordingId: The recording ID
     * - Parameter completion: Completion handler with result
     */
    public func hasAttackAlerts(recordingId: String, completion: @escaping (Result<Bool, RayhunterError>) -> Void) {
        getAnalysisReport(recordingId: recordingId) { result in
            switch result {
            case .success(let report):
                completion(.success(report.statistics.numWarnings > 0))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /**
     * Get the count of attack alerts for a recording.
     * 
     * - Parameter recordingId: The recording ID
     * - Parameter completion: Completion handler with result
     */
    public func getAttackAlertCount(recordingId: String, completion: @escaping (Result<Int, RayhunterError>) -> Void) {
        getAnalysisReport(recordingId: recordingId) { result in
            switch result {
            case .success(let report):
                completion(.success(report.statistics.numWarnings))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    /**
     * Get the latest attack alerts from all recordings.
     * 
     * - Parameter completion: Completion handler with result
     */
    public func getLatestAttackAlerts(completion: @escaping (Result<[AttackAlertSummary], RayhunterError>) -> Void) {
        getManifest { manifestResult in
            switch manifestResult {
            case .success(let manifest):
                let group = DispatchGroup()
                var alerts: [AttackAlertSummary] = []
                let queue = DispatchQueue(label: "com.rayhunter.alerts", attributes: .concurrent)
                
                for entry in manifest.entries {
                    group.enter()
                    self.getAnalysisReport(recordingId: entry.name) { reportResult in
                        queue.async {
                            if case .success(let report) = reportResult, report.statistics.numWarnings > 0 {
                                let alert = AttackAlertSummary(
                                    recordingId: entry.name,
                                    startTime: entry.startTime,
                                    attackCount: report.statistics.numWarnings,
                                    lastMessageTime: entry.lastMessageTime
                                )
                                alerts.append(alert)
                            }
                            group.leave()
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    completion(.success(alerts))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Evidence Downloads
    
    /**
     * Download evidence file for forensic analysis.
     * 
     * - Parameter endpoint: The API endpoint (e.g., "/api/pcap/123.pcapng")
     * - Parameter outputURL: The file URL to save the download to
     * - Parameter completion: Completion handler with result
     */
    public func downloadEvidenceFile(endpoint: String, outputURL: URL, completion: @escaping (Result<Void, RayhunterError>) -> Void) {
        let url = "\(baseURL)\(endpoint)"
        
        session.download(url) { _, _ in
            return (outputURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        .validate()
        .responseData { response in
            switch response.result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(RayhunterError.networkError("Failed to download evidence file", error)))
            }
        }
    }
    
    /**
     * Download PCAP evidence file for a recording.
     * 
     * - Parameter recordingId: The recording ID
     * - Parameter outputURL: The file URL to save the PCAP to
     * - Parameter completion: Completion handler with result
     */
    public func downloadPCAPEvidence(recordingId: String, outputURL: URL, completion: @escaping (Result<Void, RayhunterError>) -> Void) {
        downloadEvidenceFile(endpoint: "/api/pcap/\(recordingId).pcapng", outputURL: outputURL, completion: completion)
    }
    
    /**
     * Download QMDL evidence file for a recording.
     * 
     * - Parameter recordingId: The recording ID
     * - Parameter outputURL: The file URL to save the QMDL to
     * - Parameter completion: Completion handler with result
     */
    public func downloadQMDLEvidence(recordingId: String, outputURL: URL, completion: @escaping (Result<Void, RayhunterError>) -> Void) {
        downloadEvidenceFile(endpoint: "/api/qmdl/\(recordingId).qmdl", outputURL: outputURL, completion: completion)
    }
    
    /**
     * Download ZIP evidence archive for a recording.
     * 
     * - Parameter recordingId: The recording ID
     * - Parameter outputURL: The file URL to save the ZIP to
     * - Parameter completion: Completion handler with result
     */
    public func downloadZIPEvidence(recordingId: String, outputURL: URL, completion: @escaping (Result<Void, RayhunterError>) -> Void) {
        downloadEvidenceFile(endpoint: "/api/zip/\(recordingId).zip", outputURL: outputURL, completion: completion)
    }
    
    // MARK: - Configuration
    
    /**
     * Get device configuration.
     * 
     * - Parameter completion: Completion handler with result
     */
    public func getConfig(completion: @escaping (Result<Config, RayhunterError>) -> Void) {
        let url = "\(baseURL)/api/config"
        
        session.request(url)
            .validate()
            .responseDecodable(of: Config.self) { response in
                switch response.result {
                case .success(let config):
                    completion(.success(config))
                case .failure(let error):
                    completion(.failure(RayhunterError.networkError("Failed to get config", error)))
                }
            }
    }
    
    /**
     * Get the base URL of this client.
     * 
     * - Returns: The base URL
     */
    public func getBaseURL() -> String {
        return baseURL
    }
}

/**
 * Summary of attack alerts for a recording.
 */
public struct AttackAlertSummary {
    public let recordingId: String
    public let startTime: String
    public let attackCount: Int
    public let lastMessageTime: String?
    
    public init(recordingId: String, startTime: String, attackCount: Int, lastMessageTime: String?) {
        self.recordingId = recordingId
        self.startTime = startTime
        self.attackCount = attackCount
        self.lastMessageTime = lastMessageTime
    }
} 