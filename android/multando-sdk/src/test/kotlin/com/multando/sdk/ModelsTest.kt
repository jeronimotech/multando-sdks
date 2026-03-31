package com.multando.sdk

import com.multando.sdk.models.*
import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class ModelsTest {

    private val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
        isLenient = true
        coerceInputValues = true
    }

    // MARK: - Enums

    @Test
    fun `ReportStatus serializes to correct JSON values`() {
        assertEquals("\"pending\"", json.encodeToString(ReportStatus.PENDING))
        assertEquals("\"under_review\"", json.encodeToString(ReportStatus.UNDER_REVIEW))
        assertEquals("\"verified\"", json.encodeToString(ReportStatus.VERIFIED))
        assertEquals("\"rejected\"", json.encodeToString(ReportStatus.REJECTED))
        assertEquals("\"appealed\"", json.encodeToString(ReportStatus.APPEALED))
        assertEquals("\"resolved\"", json.encodeToString(ReportStatus.RESOLVED))
    }

    @Test
    fun `ReportStatus deserializes from JSON values`() {
        assertEquals(ReportStatus.PENDING, json.decodeFromString("\"pending\""))
        assertEquals(ReportStatus.UNDER_REVIEW, json.decodeFromString("\"under_review\""))
        assertEquals(ReportStatus.VERIFIED, json.decodeFromString("\"verified\""))
    }

    @Test
    fun `ReportSource serializes to correct JSON values`() {
        assertEquals("\"sdk\"", json.encodeToString(ReportSource.SDK))
        assertEquals("\"web\"", json.encodeToString(ReportSource.WEB))
        assertEquals("\"mobile\"", json.encodeToString(ReportSource.MOBILE))
        assertEquals("\"api\"", json.encodeToString(ReportSource.API))
    }

    @Test
    fun `InfractionSeverity serializes to correct JSON values`() {
        assertEquals("\"low\"", json.encodeToString(InfractionSeverity.LOW))
        assertEquals("\"medium\"", json.encodeToString(InfractionSeverity.MEDIUM))
        assertEquals("\"high\"", json.encodeToString(InfractionSeverity.HIGH))
        assertEquals("\"critical\"", json.encodeToString(InfractionSeverity.CRITICAL))
    }

    @Test
    fun `VehicleCategory has expected members`() {
        val values = VehicleCategory.values()
        assertEquals(7, values.size)
        assertNotNull(VehicleCategory.CAR)
        assertNotNull(VehicleCategory.MOTORCYCLE)
        assertNotNull(VehicleCategory.TRUCK)
        assertNotNull(VehicleCategory.OTHER)
    }

    @Test
    fun `EvidenceType serializes correctly`() {
        assertEquals("\"photo\"", json.encodeToString(EvidenceType.PHOTO))
        assertEquals("\"video\"", json.encodeToString(EvidenceType.VIDEO))
        assertEquals("\"audio\"", json.encodeToString(EvidenceType.AUDIO))
        assertEquals("\"document\"", json.encodeToString(EvidenceType.DOCUMENT))
    }

    // MARK: - Auth models

    @Test
    fun `TokenResponse round-trips through serialization`() {
        val original = TokenResponse(
            accessToken = "access-xyz",
            refreshToken = "refresh-xyz",
            tokenType = "Bearer",
            expiresIn = 7200,
        )

        val encoded = json.encodeToString(original)
        val decoded = json.decodeFromString<TokenResponse>(encoded)

        assertEquals(original.accessToken, decoded.accessToken)
        assertEquals(original.refreshToken, decoded.refreshToken)
        assertEquals(original.tokenType, decoded.tokenType)
        assertEquals(original.expiresIn, decoded.expiresIn)
    }

    @Test
    fun `LoginRequest serializes correctly`() {
        val request = LoginRequest(email = "test@example.com", password = "secret")
        val encoded = json.encodeToString(request)

        assertTrue(encoded.contains("\"email\""))
        assertTrue(encoded.contains("test@example.com"))
        assertTrue(encoded.contains("\"password\""))
    }

    @Test
    fun `RegisterRequest serializes with snake_case full_name`() {
        val request = RegisterRequest(
            email = "new@example.com",
            password = "pass123",
            fullName = "Test User",
        )
        val encoded = json.encodeToString(request)

        assertTrue(encoded.contains("\"full_name\""))
        assertTrue(encoded.contains("Test User"))
    }

    @Test
    fun `RefreshRequest serializes with snake_case`() {
        val request = RefreshRequest(refreshToken = "rt-123")
        val encoded = json.encodeToString(request)

        assertTrue(encoded.contains("\"refresh_token\""))
        assertTrue(encoded.contains("rt-123"))
    }

    @Test
    fun `WalletLinkRequest serializes with snake_case`() {
        val request = WalletLinkRequest(
            walletAddress = "0x1234567890abcdef",
            signature = "sig-abc",
        )
        val encoded = json.encodeToString(request)

        assertTrue(encoded.contains("\"wallet_address\""))
        assertTrue(encoded.contains("0x1234567890abcdef"))
    }

    // MARK: - Infraction models

    @Test
    fun `InfractionResponse deserializes correctly`() {
        val infractionJson = """
            {
                "id": "inf-001",
                "name": "Illegal Parking",
                "description": "Parking in no-park zone",
                "severity": "medium",
                "fine_amount": 150.50,
                "points": 3,
                "created_at": "2024-06-01T00:00:00Z"
            }
        """.trimIndent()

        val infraction = json.decodeFromString<InfractionResponse>(infractionJson)

        assertEquals("inf-001", infraction.id)
        assertEquals("Illegal Parking", infraction.name)
        assertEquals(InfractionSeverity.MEDIUM, infraction.severity)
        assertEquals(150.50, infraction.fineAmount!!, 0.01)
        assertEquals(3, infraction.points)
        assertNull(infraction.category)
    }

    @Test
    fun `InfractionResponse with category deserializes correctly`() {
        val infractionJson = """
            {
                "id": "inf-002",
                "name": "Red Light",
                "description": "Running red",
                "severity": "high",
                "category": {
                    "id": "cat-traffic",
                    "name": "Traffic"
                },
                "created_at": "2024-06-01T00:00:00Z"
            }
        """.trimIndent()

        val infraction = json.decodeFromString<InfractionResponse>(infractionJson)

        assertEquals(InfractionSeverity.HIGH, infraction.severity)
        assertNotNull(infraction.category)
        assertEquals("Traffic", infraction.category?.name)
    }

    // MARK: - Evidence models

    @Test
    fun `EvidenceCreate serializes correctly`() {
        val evidence = EvidenceCreate(
            reportId = "rpt-001",
            evidenceType = EvidenceType.PHOTO,
            fileUrl = "https://cdn.multando.io/evidence/photo1.jpg",
            description = "Front view of vehicle",
        )
        val encoded = json.encodeToString(evidence)

        assertTrue(encoded.contains("\"report_id\""))
        assertTrue(encoded.contains("\"evidence_type\""))
        assertTrue(encoded.contains("\"file_url\""))
    }

    @Test
    fun `EvidenceResponse deserializes correctly`() {
        val evidenceJson = """
            {
                "id": "ev-001",
                "report_id": "rpt-001",
                "evidence_type": "photo",
                "file_url": "https://cdn.multando.io/photo.jpg",
                "description": "Front view",
                "created_at": "2025-01-15T10:06:00Z"
            }
        """.trimIndent()

        val evidence = json.decodeFromString<EvidenceResponse>(evidenceJson)

        assertEquals("ev-001", evidence.id)
        assertEquals("rpt-001", evidence.reportId)
        assertEquals(EvidenceType.PHOTO, evidence.evidenceType)
        assertEquals("Front view", evidence.description)
    }

    // MARK: - MultandoError

    @Test
    fun `MultandoError ApiError contains status code in message`() {
        val error = MultandoError.ApiError(statusCode = 404, message = "Not Found")
        assertTrue(error.message.contains("404"))
        assertTrue(error.message.contains("Not Found"))
    }

    @Test
    fun `MultandoError ValidationError contains message`() {
        val error = MultandoError.ValidationError("Field required")
        assertTrue(error.message.contains("Field required"))
    }

    @Test
    fun `MultandoError AuthError contains message`() {
        val error = MultandoError.AuthError("Token expired")
        assertTrue(error.message.contains("Token expired"))
    }

    @Test
    fun `MultandoError DecodingError wraps cause`() {
        val cause = RuntimeException("Bad JSON")
        val error = MultandoError.DecodingError(cause)
        assertEquals(cause, error.cause)
        assertTrue(error.message.contains("Bad JSON"))
    }

    @Test
    fun `MultandoError NetworkError wraps cause`() {
        val cause = java.io.IOException("No network")
        val error = MultandoError.NetworkError(cause)
        assertEquals(cause, error.cause)
        assertTrue(error.message.contains("No network"))
    }
}
