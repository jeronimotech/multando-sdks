import XCTest
@testable import MultandoSDK

final class MultandoClientTests: XCTestCase {

    func testClientInitializesWithConfig() async {
        let config = MultandoConfig(
            baseURL: "https://api.test.multando.io",
            apiKey: "test-key"
        )
        let client = MultandoClient(config: config)

        // Verify services are accessible
        let _ = client.auth
        let _ = client.reports
        let _ = client.evidence
        let _ = client.infractions
        let _ = client.vehicleTypes
        let _ = client.verification
        let _ = client.blockchain
    }

    func testClientIsNotAuthenticatedByDefault() async {
        let config = MultandoConfig(
            baseURL: "https://api.test.multando.io",
            apiKey: "test-key"
        )
        let client = MultandoClient(config: config)

        let isAuth = await client.isAuthenticated
        XCTAssertFalse(isAuth)
    }

    func testClientConfigPreservesValues() async {
        let config = MultandoConfig(
            baseURL: "https://custom.api.io",
            apiKey: "my-key-123",
            locale: "es",
            timeout: 60,
            enableOfflineQueue: true,
            logLevel: .debug
        )
        let client = MultandoClient(config: config)
        let storedConfig = await client.config

        XCTAssertEqual(storedConfig.baseURL, "https://custom.api.io")
        XCTAssertEqual(storedConfig.apiKey, "my-key-123")
        XCTAssertEqual(storedConfig.locale, "es")
        XCTAssertEqual(storedConfig.timeout, 60)
        XCTAssertTrue(storedConfig.enableOfflineQueue)
        XCTAssertEqual(storedConfig.logLevel, .debug)
    }

    func testSDKInitializeReturnsClient() {
        let config = MultandoConfig(
            baseURL: "https://api.test.multando.io",
            apiKey: "test-key"
        )
        let client = MultandoSDK.initialize(config: config)

        XCTAssertNotNil(client)
    }

    func testSDKVersion() {
        XCTAssertEqual(MultandoSDK.version, "1.0.0")
    }

    func testDisposeIsSafe() async {
        let config = MultandoConfig(
            baseURL: "https://api.test.multando.io",
            apiKey: "test-key"
        )
        let client = MultandoClient(config: config)

        // Should not crash.
        await client.dispose()
    }

    func testOfflineQueueIsNilWhenDisabled() async {
        let config = MultandoConfig(
            baseURL: "https://api.test.multando.io",
            apiKey: "test-key",
            enableOfflineQueue: false
        )
        let client = MultandoClient(config: config)
        let queue = await client.offlineQueue

        XCTAssertNil(queue)
    }

    func testOfflineQueueExistsWhenEnabled() async {
        let config = MultandoConfig(
            baseURL: "https://api.test.multando.io",
            apiKey: "test-key",
            enableOfflineQueue: true
        )
        let client = MultandoClient(config: config)
        let queue = await client.offlineQueue

        XCTAssertNotNil(queue)
    }
}
