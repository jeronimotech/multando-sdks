import XCTest
@testable import MultandoSDK

/// A URLProtocol subclass that intercepts requests and returns canned responses.
final class MockURLProtocol: URLProtocol {

    /// Map of path -> (statusCode, responseData)
    static var handlers: [String: (Int, Data)] = [:]

    /// Reset all registered handlers.
    static func reset() {
        handlers = [:]
    }

    /// Register a canned response for a given path suffix.
    static func register(pathSuffix: String, statusCode: Int = 200, json: Any) {
        let data = try! JSONSerialization.data(withJSONObject: json)
        handlers[pathSuffix] = (statusCode, data)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let path = url.path
        var match: (Int, Data)?
        for (suffix, handler) in MockURLProtocol.handlers {
            if path.hasSuffix(suffix) {
                match = handler
                break
            }
        }

        guard let (statusCode, data) = match else {
            let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data("{\"detail\":\"Not Found\"}".utf8))
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

final class ReportServiceTests: XCTestCase {

    private var client: MultandoClient!

    override func setUp() {
        super.setUp()
        MockURLProtocol.reset()

        // Register the mock protocol
        URLProtocol.registerClass(MockURLProtocol.self)

        let config = MultandoConfig(
            baseURL: "https://api.test.multando.io",
            apiKey: "test-key"
        )
        client = MultandoClient(config: config)
    }

    override func tearDown() {
        URLProtocol.unregisterClass(MockURLProtocol.self)
        MockURLProtocol.reset()
        super.tearDown()
    }

    func testCreateReportReturnsDetail() async throws {
        let responseJson: [String: Any] = [
            "id": "rpt-001",
            "user_id": "user-001",
            "infraction_id": "inf-001",
            "vehicle_type_id": "vt-car",
            "license_plate": "ABC1234",
            "description": "Illegal parking",
            "location": [
                "latitude": 40.4168,
                "longitude": -3.7038,
                "address": "Test Street"
            ],
            "occurred_at": "2025-01-15T10:00:00Z",
            "status": "pending",
            "source": "sdk",
            "evidence": [] as [Any],
            "created_at": "2025-01-15T10:05:00Z",
            "updated_at": "2025-01-15T10:05:00Z"
        ]

        MockURLProtocol.register(pathSuffix: "/reports", json: responseJson)

        let report = ReportCreate(
            infractionId: "inf-001",
            vehicleTypeId: "vt-car",
            licensePlate: "ABC1234",
            description: "Illegal parking",
            location: LocationData(latitude: 40.4168, longitude: -3.7038),
            occurredAt: "2025-01-15T10:00:00Z"
        )

        let detail = try await client.reports.create(report)

        XCTAssertEqual(detail.id, "rpt-001")
        XCTAssertEqual(detail.infractionId, "inf-001")
        XCTAssertEqual(detail.licensePlate, "ABC1234")
        XCTAssertEqual(detail.status, .pending)
    }

    func testListReportsReturnsPaginatedList() async throws {
        let responseJson: [String: Any] = [
            "items": [
                [
                    "id": "rpt-001",
                    "description": "Test report",
                    "status": "pending",
                    "location": [
                        "latitude": 40.4168,
                        "longitude": -3.7038
                    ],
                    "occurred_at": "2025-01-15T10:00:00Z",
                    "created_at": "2025-01-15T10:05:00Z"
                ]
            ],
            "total": 1,
            "page": 1,
            "page_size": 20,
            "total_pages": 1
        ]

        MockURLProtocol.register(pathSuffix: "/reports", json: responseJson)

        let list = try await client.reports.list()

        XCTAssertEqual(list.items.count, 1)
        XCTAssertEqual(list.total, 1)
        XCTAssertEqual(list.page, 1)
        XCTAssertEqual(list.pageSize, 20)
        XCTAssertEqual(list.items.first?.id, "rpt-001")
    }

    func testGetReportByIdReturnsDetail() async throws {
        let responseJson: [String: Any] = [
            "id": "rpt-002",
            "user_id": "user-001",
            "infraction_id": "inf-002",
            "vehicle_type_id": "vt-moto",
            "description": "Red light",
            "location": [
                "latitude": 19.4326,
                "longitude": -99.1332
            ],
            "occurred_at": "2025-02-01T08:00:00Z",
            "status": "verified",
            "source": "sdk",
            "created_at": "2025-02-01T08:05:00Z",
            "updated_at": "2025-02-01T09:00:00Z"
        ]

        MockURLProtocol.register(pathSuffix: "/reports/rpt-002", json: responseJson)

        let detail = try await client.reports.get(id: "rpt-002")

        XCTAssertEqual(detail.id, "rpt-002")
        XCTAssertEqual(detail.status, .verified)
        XCTAssertEqual(detail.vehicleTypeId, "vt-moto")
    }

    func testDeleteReportDoesNotThrow() async throws {
        MockURLProtocol.register(pathSuffix: "/reports/rpt-003", statusCode: 204, json: [:])

        // Should not throw.
        try await client.reports.delete(id: "rpt-003")
    }

    func testListWithStatusFilter() async throws {
        let responseJson: [String: Any] = [
            "items": [] as [Any],
            "total": 0,
            "page": 1,
            "page_size": 20,
            "total_pages": 0
        ]

        MockURLProtocol.register(pathSuffix: "/reports", json: responseJson)

        let list = try await client.reports.list(status: .verified)

        XCTAssertEqual(list.items.count, 0)
        XCTAssertEqual(list.total, 0)
    }
}
