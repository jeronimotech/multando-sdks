package com.multando.sdk.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class EvidenceCreate(
    @SerialName("report_id") val reportId: String,
    @SerialName("evidence_type") val evidenceType: EvidenceType,
    @SerialName("file_url") val fileUrl: String,
    val description: String? = null
)

@Serializable
data class EvidenceResponse(
    val id: String,
    @SerialName("report_id") val reportId: String,
    @SerialName("evidence_type") val evidenceType: EvidenceType,
    @SerialName("file_url") val fileUrl: String,
    val description: String? = null,
    @SerialName("created_at") val createdAt: String
)
