package com.multando.sdk

import com.multando.sdk.models.LocationData
import com.multando.sdk.models.ReportCreate
import com.multando.sdk.models.ReportDetail
import com.multando.sdk.models.ReportList
import com.multando.sdk.models.ReportSource
import com.multando.sdk.models.ReportStatus
import com.multando.sdk.models.ReportSummary
import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString
import okhttp3.mockwebserver.MockResponse
import okhttp3.mockwebserver.MockWebServer
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Before
import org.junit.Test

class ReportServiceTest {

    private lateinit var server: MockWebServer
    private val json = Json {
        ignoreUnknownKeys = true
        encodeDefaults = true
        isLenient = true
        coerceInputValues = true
    }

    private val sampleDetailJson = """
        {
            "id": "rpt-001",
            "user_id": "user-001",
            "infraction_id": "inf-001",
            "vehicle_type_id": "vt-car",
            "license_plate": "ABC1234",
            "description": "Illegal parking",
            "location": {
                "latitude": 40.4168,
                "longitude": -3.7038,
                "address": "Test Street"
            },
            "occurred_at": "2025-01-15T10:00:00Z",
            "status": "pending",
            "source": "sdk",
            "evidence": [],
            "created_at": "2025-01-15T10:05:00Z",
            "updated_at": "2025-01-15T10:05:00Z"
        }
    """.trimIndent()

    private val sampleListJson = """
        {
            "items": [
                {
                    "id": "rpt-001",
                    "description": "Illegal parking",
                    "status": "pending",
                    "location": {
                        "latitude": 40.4168,
                        "longitude": -3.7038
                    },
                    "occurred_at": "2025-01-15T10:00:00Z",
                    "created_at": "2025-01-15T10:05:00Z"
                }
            ],
            "total": 1,
            "page": 1,
            "page_size": 20,
            "total_pages": 1
        }
    """.trimIndent()

    @Before
    fun setUp() {
        server = MockWebServer()
        server.start()
    }

    @After
    fun tearDown() {
        server.shutdown()
    }

    @Test
    fun `ReportDetail deserializes from JSON`() {
        val detail = json.decodeFromString<ReportDetail>(sampleDetailJson)

        assertEquals("rpt-001", detail.id)
        assertEquals("inf-001", detail.infractionId)
        assertEquals("ABC1234", detail.licensePlate)
        assertEquals(ReportStatus.PENDING, detail.status)
        assertEquals(ReportSource.SDK, detail.source)
        assertEquals(40.4168, detail.location.latitude, 0.001)
    }

    @Test
    fun `ReportList deserializes from JSON`() {
        val list = json.decodeFromString<ReportList>(sampleListJson)

        assertEquals(1, list.items.size)
        assertEquals(1, list.total)
        assertEquals(1, list.page)
        assertEquals(20, list.pageSize)
        assertEquals(1, list.totalPages)
        assertEquals("rpt-001", list.items[0].id)
    }

    @Test
    fun `ReportCreate serializes to JSON with correct keys`() {
        val report = ReportCreate(
            infractionId = "inf-001",
            vehicleTypeId = "vt-car",
            licensePlate = "ABC1234",
            description = "Double parked",
            location = LocationData(latitude = 40.4168, longitude = -3.7038),
            occurredAt = "2025-01-15T10:00:00Z",
        )

        val encoded = json.encodeToString(report)

        assert(encoded.contains("\"infraction_id\""))
        assert(encoded.contains("\"vehicle_type_id\""))
        assert(encoded.contains("\"license_plate\""))
        assert(encoded.contains("\"occurred_at\""))
        assert(encoded.contains("\"source\""))
    }

    @Test
    fun `ReportCreate round-trips through serialization`() {
        val original = ReportCreate(
            infractionId = "inf-002",
            vehicleTypeId = "vt-moto",
            licensePlate = "XYZ5678",
            description = "Red light",
            location = LocationData(
                latitude = 51.5074,
                longitude = -0.1278,
                city = "London",
            ),
            occurredAt = "2025-06-01T12:00:00Z",
        )

        val encoded = json.encodeToString(original)
        val decoded = json.decodeFromString<ReportCreate>(encoded)

        assertEquals(original.infractionId, decoded.infractionId)
        assertEquals(original.licensePlate, decoded.licensePlate)
        assertEquals(original.location.city, decoded.location.city)
        assertEquals(ReportSource.SDK, decoded.source)
    }

    @Test
    fun `MockWebServer returns report detail on POST`() {
        server.enqueue(
            MockResponse()
                .setBody(sampleDetailJson)
                .setResponseCode(200)
                .addHeader("Content-Type", "application/json")
        )

        val url = server.url("/api/v1/reports")

        // Verify the server is reachable and responds.
        val client = okhttp3.OkHttpClient()
        val request = okhttp3.Request.Builder()
            .url(url)
            .post(
                okhttp3.RequestBody.create(
                    okhttp3.MediaType.parse("application/json"),
                    "{}"
                )
            )
            .build()

        val response = client.newCall(request).execute()
        val body = response.body()?.string() ?: ""

        assertEquals(200, response.code())
        val detail = json.decodeFromString<ReportDetail>(body)
        assertEquals("rpt-001", detail.id)
    }

    @Test
    fun `MockWebServer returns report list on GET`() {
        server.enqueue(
            MockResponse()
                .setBody(sampleListJson)
                .setResponseCode(200)
                .addHeader("Content-Type", "application/json")
        )

        val url = server.url("/api/v1/reports")

        val client = okhttp3.OkHttpClient()
        val request = okhttp3.Request.Builder()
            .url(url)
            .get()
            .build()

        val response = client.newCall(request).execute()
        val body = response.body()?.string() ?: ""

        assertEquals(200, response.code())
        val list = json.decodeFromString<ReportList>(body)
        assertEquals(1, list.items.size)
    }

    @Test
    fun `ReportSummary deserializes correctly`() {
        val summaryJson = """
            {
                "id": "rpt-300",
                "description": "Stop sign",
                "status": "under_review",
                "location": {"latitude": 0, "longitude": 0},
                "occurred_at": "2025-03-01T08:00:00Z",
                "created_at": "2025-03-01T08:05:00Z"
            }
        """.trimIndent()

        val summary = json.decodeFromString<ReportSummary>(summaryJson)

        assertEquals("rpt-300", summary.id)
        assertEquals(ReportStatus.UNDER_REVIEW, summary.status)
        assertEquals("Stop sign", summary.description)
    }

    @Test
    fun `LocationData handles optional fields`() {
        val minimalJson = """{"latitude": 10.0, "longitude": 20.0}"""
        val location = json.decodeFromString<LocationData>(minimalJson)

        assertEquals(10.0, location.latitude, 0.001)
        assertEquals(20.0, location.longitude, 0.001)
        assertEquals(null, location.address)
        assertEquals(null, location.city)
    }
}
