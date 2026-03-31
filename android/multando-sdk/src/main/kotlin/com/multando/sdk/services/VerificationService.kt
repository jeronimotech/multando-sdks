package com.multando.sdk.services

import com.multando.sdk.core.HttpClient
import com.multando.sdk.models.ReportDetail
import com.multando.sdk.models.ReportList
import kotlinx.serialization.Serializable

/**
 * Report verification operations (for verifiers/moderators).
 */
class VerificationService internal constructor(
    private val httpClient: HttpClient
) {

    @Serializable
    private data class VerifyBody(val notes: String? = null)

    @Serializable
    private data class RejectBody(val reason: String)

    /** Fetch the queue of reports pending verification. */
    suspend fun queue(page: Int = 1, pageSize: Int = 20): ReportList =
        httpClient.request(
            method = "GET",
            path = "/api/v1/verification/queue",
            queryParams = mapOf(
                "page" to page.toString(),
                "page_size" to pageSize.toString()
            )
        )

    /** Verify (approve) a report. */
    suspend fun verify(reportId: String, notes: String? = null): ReportDetail =
        httpClient.request(
            method = "POST",
            path = "/api/v1/verification/$reportId/verify",
            body = VerifyBody(notes)
        )

    /** Reject a report. */
    suspend fun reject(reportId: String, reason: String): ReportDetail =
        httpClient.request(
            method = "POST",
            path = "/api/v1/verification/$reportId/reject",
            body = RejectBody(reason)
        )
}
