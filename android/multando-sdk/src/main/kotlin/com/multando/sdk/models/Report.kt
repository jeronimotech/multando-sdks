package com.multando.sdk.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class LocationData(
    val latitude: Double,
    val longitude: Double,
    val address: String? = null,
    val city: String? = null,
    val state: String? = null,
    val country: String? = null
)

@Serializable
data class ReportCreate(
    @SerialName("infraction_id") val infractionId: String,
    @SerialName("vehicle_type_id") val vehicleTypeId: String,
    @SerialName("license_plate") val licensePlate: String? = null,
    val description: String,
    val location: LocationData,
    @SerialName("occurred_at") val occurredAt: String,
    val source: ReportSource = ReportSource.SDK
)

@Serializable
data class ReportDetail(
    val id: String,
    @SerialName("user_id") val userId: String,
    @SerialName("infraction_id") val infractionId: String,
    @SerialName("vehicle_type_id") val vehicleTypeId: String,
    @SerialName("license_plate") val licensePlate: String? = null,
    val description: String,
    val location: LocationData,
    @SerialName("occurred_at") val occurredAt: String,
    val status: ReportStatus,
    val source: ReportSource,
    val evidence: List<EvidenceResponse>? = null,
    @SerialName("created_at") val createdAt: String,
    @SerialName("updated_at") val updatedAt: String
)

@Serializable
data class ReportSummary(
    val id: String,
    val description: String,
    val status: ReportStatus,
    val location: LocationData,
    @SerialName("occurred_at") val occurredAt: String,
    @SerialName("created_at") val createdAt: String
)

@Serializable
data class ReportList(
    val items: List<ReportSummary>,
    val total: Int,
    val page: Int,
    @SerialName("page_size") val pageSize: Int,
    @SerialName("total_pages") val totalPages: Int
)
