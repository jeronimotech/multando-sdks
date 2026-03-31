package com.multando.sdk.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class UserProfile(
    val id: String,
    val email: String,
    @SerialName("full_name") val fullName: String,
    @SerialName("wallet_address") val walletAddress: String? = null,
    @SerialName("reputation_score") val reputationScore: Double,
    @SerialName("total_reports") val totalReports: Int,
    @SerialName("verified_reports") val verifiedReports: Int,
    @SerialName("created_at") val createdAt: String,
    @SerialName("updated_at") val updatedAt: String
)

@Serializable
data class UserPublic(
    val id: String,
    @SerialName("full_name") val fullName: String,
    @SerialName("reputation_score") val reputationScore: Double
)
