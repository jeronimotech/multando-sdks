package com.multando.sdk.services

import com.multando.sdk.core.HttpClient
import com.multando.sdk.models.*

/**
 * CRUD operations on traffic violation reports.
 */
class ReportService internal constructor(
    private val httpClient: HttpClient
) {

    /** Create a new report. */
    suspend fun create(report: ReportCreate): ReportDetail =
        httpClient.request(
            method = "POST",
            path = "/api/v1/reports",
            body = report
        )

    /** Fetch a paginated list of reports. */
    suspend fun list(
        page: Int = 1,
        pageSize: Int = 20,
        status: ReportStatus? = null
    ): ReportList {
        val params = mutableMapOf(
            "page" to page.toString(),
            "page_size" to pageSize.toString()
        )
        status?.let { params["status"] = it.name.lowercase() }

        return httpClient.request(
            method = "GET",
            path = "/api/v1/reports",
            queryParams = params
        )
    }

    /** Fetch a single report by ID. */
    suspend fun get(id: String): ReportDetail =
        httpClient.request(method = "GET", path = "/api/v1/reports/$id")

    /** Update an existing report. */
    suspend fun update(id: String, report: ReportCreate): ReportDetail =
        httpClient.request(
            method = "PUT",
            path = "/api/v1/reports/$id",
            body = report
        )

    /** Delete a report. */
    suspend fun delete(id: String) {
        httpClient.requestVoid(method = "DELETE", path = "/api/v1/reports/$id")
    }
}
