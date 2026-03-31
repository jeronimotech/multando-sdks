package com.multando.sdk.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
enum class InfractionSeverity {
    @SerialName("low") LOW,
    @SerialName("medium") MEDIUM,
    @SerialName("high") HIGH,
    @SerialName("critical") CRITICAL
}

@Serializable
data class InfractionCategory(
    val id: String,
    val name: String,
    val description: String? = null
)

@Serializable
data class InfractionResponse(
    val id: String,
    val name: String,
    val description: String,
    val severity: InfractionSeverity,
    val category: InfractionCategory? = null,
    @SerialName("fine_amount") val fineAmount: Double? = null,
    val points: Int? = null,
    @SerialName("created_at") val createdAt: String
)
