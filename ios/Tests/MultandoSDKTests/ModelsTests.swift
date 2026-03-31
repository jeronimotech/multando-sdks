import XCTest
@testable import MultandoSDK

final class ModelsTests: XCTestCase {

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.keyEncodingStrategy = .convertToSnakeCase
        return e
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    // MARK: - LocationData

    func testLocationDataEncoding() throws {
        let location = LocationData(
            latitude: 40.4168,
            longitude: -3.7038,
            address: "Puerta del Sol",
            city: "Madrid",
            state: "Madrid",
            country: "Spain"
        )

        let data = try encoder.encode(location)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["latitude"] as? Double, 40.4168)
        XCTAssertEqual(json["longitude"] as? Double, -3.7038)
        XCTAssertEqual(json["address"] as? String, "Puerta del Sol")
        XCTAssertEqual(json["city"] as? String, "Madrid")
    }

    func testLocationDataDecoding() throws {
        let json = """
        {
            "latitude": 19.4326,
            "longitude": -99.1332,
            "address": "Zocalo",
            "city": "Mexico City",
            "country": "Mexico"
        }
        """.data(using: .utf8)!

        let location = try decoder.decode(LocationData.self, from: json)

        XCTAssertEqual(location.latitude, 19.4326)
        XCTAssertEqual(location.address, "Zocalo")
        XCTAssertNil(location.state)
    }

    func testLocationDataMinimalDecoding() throws {
        let json = """
        {"latitude": 0, "longitude": 0}
        """.data(using: .utf8)!

        let location = try decoder.decode(LocationData.self, from: json)

        XCTAssertEqual(location.latitude, 0)
        XCTAssertEqual(location.longitude, 0)
        XCTAssertNil(location.address)
        XCTAssertNil(location.city)
    }

    // MARK: - ReportCreate

    func testReportCreateEncoding() throws {
        let report = ReportCreate(
            infractionId: "inf-001",
            vehicleTypeId: "vt-car",
            licensePlate: "ABC1234",
            description: "Double parked",
            location: LocationData(latitude: 40.4168, longitude: -3.7038),
            occurredAt: "2025-01-15T10:00:00Z"
        )

        let data = try encoder.encode(report)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["infraction_id"] as? String, "inf-001")
        XCTAssertEqual(json["vehicle_type_id"] as? String, "vt-car")
        XCTAssertEqual(json["license_plate"] as? String, "ABC1234")
        XCTAssertEqual(json["source"] as? String, "sdk")
    }

    func testReportCreateRoundTrip() throws {
        let original = ReportCreate(
            infractionId: "inf-002",
            vehicleTypeId: "vt-moto",
            licensePlate: "XYZ5678",
            description: "Red light",
            location: LocationData(latitude: 51.5074, longitude: -0.1278, city: "London"),
            occurredAt: "2025-06-01T12:00:00Z"
        )

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(ReportCreate.self, from: data)

        XCTAssertEqual(decoded.infractionId, original.infractionId)
        XCTAssertEqual(decoded.licensePlate, original.licensePlate)
        XCTAssertEqual(decoded.location.city, "London")
        XCTAssertEqual(decoded.source, .sdk)
    }

    // MARK: - ReportDetail

    func testReportDetailDecoding() throws {
        let json = """
        {
            "id": "rpt-100",
            "user_id": "user-001",
            "infraction_id": "inf-001",
            "vehicle_type_id": "vt-car",
            "license_plate": "ABC1234",
            "description": "Double parked",
            "location": {"latitude": 40.4168, "longitude": -3.7038},
            "occurred_at": "2025-01-15T10:00:00Z",
            "status": "verified",
            "source": "sdk",
            "evidence": [],
            "created_at": "2025-01-15T10:05:00Z",
            "updated_at": "2025-01-15T11:00:00Z"
        }
        """.data(using: .utf8)!

        let detail = try decoder.decode(ReportDetail.self, from: json)

        XCTAssertEqual(detail.id, "rpt-100")
        XCTAssertEqual(detail.status, .verified)
        XCTAssertEqual(detail.source, .sdk)
        XCTAssertEqual(detail.licensePlate, "ABC1234")
        XCTAssertEqual(detail.evidence?.count, 0)
    }

    // MARK: - ReportSummary

    func testReportSummaryDecoding() throws {
        let json = """
        {
            "id": "rpt-200",
            "description": "No seatbelt",
            "status": "under_review",
            "location": {"latitude": 0, "longitude": 0},
            "occurred_at": "2025-03-01T08:00:00Z",
            "created_at": "2025-03-01T08:05:00Z"
        }
        """.data(using: .utf8)!

        let summary = try decoder.decode(ReportSummary.self, from: json)

        XCTAssertEqual(summary.id, "rpt-200")
        XCTAssertEqual(summary.status, .underReview)
        XCTAssertEqual(summary.description, "No seatbelt")
    }

    // MARK: - ReportList

    func testReportListDecoding() throws {
        let json = """
        {
            "items": [
                {
                    "id": "rpt-a",
                    "description": "Test A",
                    "status": "pending",
                    "location": {"latitude": 1, "longitude": 2},
                    "occurred_at": "2025-01-01T00:00:00Z",
                    "created_at": "2025-01-01T00:05:00Z"
                }
            ],
            "total": 50,
            "page": 3,
            "page_size": 10,
            "total_pages": 5
        }
        """.data(using: .utf8)!

        let list = try decoder.decode(ReportList.self, from: json)

        XCTAssertEqual(list.items.count, 1)
        XCTAssertEqual(list.total, 50)
        XCTAssertEqual(list.page, 3)
        XCTAssertEqual(list.pageSize, 10)
        XCTAssertEqual(list.totalPages, 5)
    }

    // MARK: - InfractionResponse

    func testInfractionResponseDecoding() throws {
        let json = """
        {
            "id": "inf-001",
            "name": "Illegal Parking",
            "description": "Parking in no-park zone",
            "severity": "medium",
            "fine_amount": 150.50,
            "points": 3,
            "created_at": "2024-06-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let infraction = try decoder.decode(InfractionResponse.self, from: json)

        XCTAssertEqual(infraction.id, "inf-001")
        XCTAssertEqual(infraction.name, "Illegal Parking")
        XCTAssertEqual(infraction.severity, .medium)
        XCTAssertEqual(infraction.fineAmount, 150.50)
        XCTAssertEqual(infraction.points, 3)
        XCTAssertNil(infraction.category)
    }

    func testInfractionResponseWithCategory() throws {
        let json = """
        {
            "id": "inf-002",
            "name": "Red Light",
            "description": "Running a red light",
            "severity": "high",
            "category": {
                "id": "cat-traffic",
                "name": "Traffic",
                "description": "Traffic violations"
            },
            "created_at": "2024-06-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let infraction = try decoder.decode(InfractionResponse.self, from: json)

        XCTAssertEqual(infraction.severity, .high)
        XCTAssertNotNil(infraction.category)
        XCTAssertEqual(infraction.category?.name, "Traffic")
    }

    // MARK: - TokenResponse

    func testTokenResponseDecoding() throws {
        let json = """
        {
            "access_token": "eyJhbGciOiJSUzI1NiJ9.test",
            "refresh_token": "refresh-abc-123",
            "token_type": "Bearer",
            "expires_in": 3600
        }
        """.data(using: .utf8)!

        let token = try decoder.decode(TokenResponse.self, from: json)

        XCTAssertEqual(token.accessToken, "eyJhbGciOiJSUzI1NiJ9.test")
        XCTAssertEqual(token.refreshToken, "refresh-abc-123")
        XCTAssertEqual(token.tokenType, "Bearer")
        XCTAssertEqual(token.expiresIn, 3600)
    }

    func testTokenResponseRoundTrip() throws {
        let original = TokenResponse(
            accessToken: "access-xyz",
            refreshToken: "refresh-xyz",
            tokenType: "Bearer",
            expiresIn: 7200
        )

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(TokenResponse.self, from: data)

        XCTAssertEqual(decoded.accessToken, original.accessToken)
        XCTAssertEqual(decoded.refreshToken, original.refreshToken)
        XCTAssertEqual(decoded.expiresIn, original.expiresIn)
    }

    // MARK: - Enums

    func testReportStatusRawValues() {
        XCTAssertEqual(ReportStatus.pending.rawValue, "pending")
        XCTAssertEqual(ReportStatus.underReview.rawValue, "under_review")
        XCTAssertEqual(ReportStatus.verified.rawValue, "verified")
        XCTAssertEqual(ReportStatus.rejected.rawValue, "rejected")
        XCTAssertEqual(ReportStatus.appealed.rawValue, "appealed")
        XCTAssertEqual(ReportStatus.resolved.rawValue, "resolved")
    }

    func testReportSourceRawValues() {
        XCTAssertEqual(ReportSource.sdk.rawValue, "sdk")
        XCTAssertEqual(ReportSource.web.rawValue, "web")
        XCTAssertEqual(ReportSource.mobile.rawValue, "mobile")
        XCTAssertEqual(ReportSource.api.rawValue, "api")
    }

    func testInfractionSeverityRawValues() {
        XCTAssertEqual(InfractionSeverity.low.rawValue, "low")
        XCTAssertEqual(InfractionSeverity.medium.rawValue, "medium")
        XCTAssertEqual(InfractionSeverity.high.rawValue, "high")
        XCTAssertEqual(InfractionSeverity.critical.rawValue, "critical")
    }

    func testEvidenceTypeRawValues() {
        XCTAssertEqual(EvidenceType.photo.rawValue, "photo")
        XCTAssertEqual(EvidenceType.video.rawValue, "video")
        XCTAssertEqual(EvidenceType.audio.rawValue, "audio")
        XCTAssertEqual(EvidenceType.document.rawValue, "document")
    }

    // MARK: - MultandoError

    func testMultandoErrorDescriptions() {
        let apiErr = MultandoError.apiError(statusCode: 500, message: "Internal Server Error")
        XCTAssertTrue(apiErr.errorDescription?.contains("500") ?? false)

        let validationErr = MultandoError.validationError("Field missing")
        XCTAssertTrue(validationErr.errorDescription?.contains("Field missing") ?? false)

        let authErr = MultandoError.authError("Token expired")
        XCTAssertTrue(authErr.errorDescription?.contains("Token expired") ?? false)
    }
}
