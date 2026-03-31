package com.multando.sdk.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class VehicleTypeResponse(
    val id: String,
    val name: String,
    val category: VehicleCategory,
    val description: String? = null,
    @SerialName("created_at") val createdAt: String
)
