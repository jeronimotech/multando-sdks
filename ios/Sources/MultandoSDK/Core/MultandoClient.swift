import Foundation

/// The main Multando SDK client. Thread-safe via Swift actor isolation.
public actor MultandoClient {

    // MARK: - Internal dependencies

    let config: MultandoConfig
    let httpClient: HTTPClient
    let authManager: AuthManager
    let offlineQueue: OfflineQueue?

    // MARK: - Public services

    public nonisolated let auth: AuthService
    public nonisolated let reports: ReportService
    public nonisolated let evidence: EvidenceService
    public nonisolated let infractions: InfractionService
    public nonisolated let vehicleTypes: VehicleTypeService
    public nonisolated let verification: VerificationService
    public nonisolated let blockchain: BlockchainService
    public nonisolated let chat: ChatService

    // MARK: - Init

    public init(config: MultandoConfig) {
        self.config = config

        let authManager = AuthManager()
        self.authManager = authManager

        let httpClient = HTTPClient(config: config, authManager: authManager)
        self.httpClient = httpClient

        if config.enableOfflineQueue {
            self.offlineQueue = OfflineQueue(httpClient: httpClient)
        } else {
            self.offlineQueue = nil
        }

        self.auth = AuthService(httpClient: httpClient, authManager: authManager)
        self.reports = ReportService(httpClient: httpClient)
        self.evidence = EvidenceService(httpClient: httpClient)
        self.infractions = InfractionService(httpClient: httpClient)
        self.vehicleTypes = VehicleTypeService(httpClient: httpClient)
        self.verification = VerificationService(httpClient: httpClient)
        self.blockchain = BlockchainService(httpClient: httpClient)
        self.chat = ChatService(httpClient: httpClient)
    }

    // MARK: - Convenience

    /// Whether the user currently has valid auth tokens stored.
    public var isAuthenticated: Bool {
        authManager.isAuthenticated
    }

    /// Fetches the profile of the currently authenticated user.
    public func currentUser() async throws -> UserProfile {
        try await auth.me()
    }

    /// Tears down network monitors and clears in-memory caches.
    public func dispose() {
        offlineQueue?.stop()
    }
}
