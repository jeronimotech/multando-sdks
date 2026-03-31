package com.multando.sdk.services

import com.multando.sdk.core.HttpClient
import com.multando.sdk.models.*

/**
 * Operations for managing evidence attached to reports.
 */
class EvidenceService internal constructor(
    private val httpClient: HttpClient
) {

    /** Attach evidence to a report. */
    suspend fun create(evidence: EvidenceCreate): EvidenceResponse =
        httpClient.request(
            method = "POST",
            path = "/api/v1/reports/${evidence.reportId}/evidence",
            body = evidence
        )

    /** List all evidence for a report. */
    suspend fun list(reportId: String): List<EvidenceResponse> =
        httpClient.request(
            method = "GET",
            path = "/api/v1/reports/$reportId/evidence"
        )

    /** Delete a specific evidence item. */
    suspend fun delete(reportId: String, evidenceId: String) {
        httpClient.requestVoid(
            method = "DELETE",
            path = "/api/v1/reports/$reportId/evidence/$evidenceId"
        )
    }
}
