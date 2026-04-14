package com.multando.sdk.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
enum class ReportStatus {
    @SerialName("pending") PENDING,
    @SerialName("under_review") UNDER_REVIEW,
    @SerialName("community_verified") COMMUNITY_VERIFIED,
    @SerialName("authority_review") AUTHORITY_REVIEW,
    @SerialName("verified") VERIFIED,
    @SerialName("rejected") REJECTED,
    @SerialName("appealed") APPEALED,
    @SerialName("resolved") RESOLVED
}

@Serializable
enum class ReportSource {
    @SerialName("sdk") SDK,
    @SerialName("web") WEB,
    @SerialName("mobile") MOBILE,
    @SerialName("api") API
}

@Serializable
enum class VehicleCategory {
    @SerialName("car") CAR,
    @SerialName("motorcycle") MOTORCYCLE,
    @SerialName("truck") TRUCK,
    @SerialName("bus") BUS,
    @SerialName("bicycle") BICYCLE,
    @SerialName("scooter") SCOOTER,
    @SerialName("other") OTHER
}

@Serializable
enum class EvidenceType {
    @SerialName("photo") PHOTO,
    @SerialName("video") VIDEO,
    @SerialName("audio") AUDIO,
    @SerialName("document") DOCUMENT
}
