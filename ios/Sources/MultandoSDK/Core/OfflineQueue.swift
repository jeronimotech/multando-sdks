import Foundation
import Network

/// Persists mutating HTTP requests to disk and replays them when the device regains connectivity.
public final class OfflineQueue: @unchecked Sendable {

    // MARK: - Types

    struct QueuedRequest: Codable {
        let id: String
        let method: String
        let path: String
        let body: Data?
        let timestamp: Date
    }

    // MARK: - Properties

    private let httpClient: HTTPClient
    private let monitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "com.multando.sdk.offline-queue.monitor")
    private let fileQueue = DispatchQueue(label: "com.multando.sdk.offline-queue.file")
    private var isConnected = true
    private var isProcessing = false

    private var queueFileURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("MultandoSDK", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("offline_queue.json")
    }

    // MARK: - Init

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
        self.monitor = NWPathMonitor()

        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let wasDisconnected = !self.isConnected
            self.isConnected = path.status == .satisfied
            if wasDisconnected && self.isConnected {
                Task { await self.processQueue() }
            }
        }
        monitor.start(queue: monitorQueue)
    }

    // MARK: - Public

    /// Enqueue a request for later replay.
    func enqueue(method: String, path: String, body: Data?) {
        let entry = QueuedRequest(
            id: UUID().uuidString,
            method: method,
            path: path,
            body: body,
            timestamp: Date()
        )
        fileQueue.sync {
            var items = loadQueue()
            items.append(entry)
            saveQueue(items)
        }
    }

    /// Whether the device currently has network connectivity.
    var hasConnectivity: Bool { isConnected }

    /// Stop monitoring connectivity.
    func stop() {
        monitor.cancel()
    }

    // MARK: - Processing

    private func processQueue() async {
        guard !isProcessing else { return }
        isProcessing = true
        defer { isProcessing = false }

        var items = fileQueue.sync { loadQueue() }
        var failedItems: [QueuedRequest] = []

        for item in items {
            do {
                try await httpClient.requestVoid(
                    method: item.method,
                    path: item.path,
                    body: item.body.map { RawData(data: $0) },
                    authenticated: true
                )
            } catch {
                failedItems.append(item)
            }
        }

        fileQueue.sync { saveQueue(failedItems) }
    }

    // MARK: - Persistence

    private func loadQueue() -> [QueuedRequest] {
        guard let data = try? Data(contentsOf: queueFileURL) else { return [] }
        return (try? JSONDecoder().decode([QueuedRequest].self, from: data)) ?? []
    }

    private func saveQueue(_ items: [QueuedRequest]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: queueFileURL, options: .atomic)
    }
}

// MARK: - Helper for raw data encoding

private struct RawData: Encodable {
    let data: Data
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }
}
