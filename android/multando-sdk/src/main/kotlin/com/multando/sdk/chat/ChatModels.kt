package com.multando.sdk.chat

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonObject

@Serializable
data class Conversation(
    val id: Int,
    val status: String,
    @SerialName("created_at") val createdAt: String,
    @SerialName("updated_at") val updatedAt: String,
    val messages: List<ChatMessage> = emptyList()
)

@Serializable
data class ChatMessage(
    val id: Int,
    @SerialName("conversation_id") val conversationId: Int,
    val direction: String,
    val content: String? = null,
    @SerialName("message_type") val messageType: String,
    @SerialName("created_at") val createdAt: String
) {
    /** Whether this message was sent by the user. */
    val isOutbound: Boolean get() = direction == "outbound"
}

@Serializable
data class SendMessageRequest(
    val content: String,
    @SerialName("image_base64") val imageBase64: String? = null,
    @SerialName("image_media_type") val imageMediaType: String? = null,
    @SerialName("image_hash") val imageHash: String? = null,
    @SerialName("image_signature") val imageSignature: String? = null,
    @SerialName("image_timestamp") val imageTimestamp: String? = null,
    @SerialName("image_latitude") val imageLatitude: Double? = null,
    @SerialName("image_longitude") val imageLongitude: Double? = null,
    @SerialName("device_id") val deviceId: String? = null,
    @SerialName("capture_method") val captureMethod: String? = null
)

/**
 * Native action a quick-reply button can trigger.
 *
 * The wire format is snake_case. Unknown values deserialize to [SEND_TEXT]
 * because the consuming [kotlinx.serialization.json.Json] is configured with
 * `coerceInputValues = true` + `ignoreUnknownKeys = true` in
 * [com.multando.sdk.core.HttpClient], so clients are forward-compatible with
 * backend actions added after this SDK version was released.
 */
@Serializable
enum class QuickReplyAction {
    /** Send [QuickReply.value] as the user's next chat message. */
    @SerialName("send_text") SEND_TEXT,

    /** Ask the app to share the user's current location (GPS). */
    @SerialName("share_location") SHARE_LOCATION,

    /** Ask the app to open the camera and capture a photo. */
    @SerialName("take_photo") TAKE_PHOTO,

    /** Ask the app to pick an image from the gallery. */
    @SerialName("pick_image") PICK_IMAGE,

    /** Open [QuickReply.value] as an external URL. */
    @SerialName("open_url") OPEN_URL,
}

@Serializable
data class QuickReply(
    /** Display text for the button. */
    val label: String,
    /** Text to send when the button is tapped, or a URL when [action] is [QuickReplyAction.OPEN_URL]. */
    val value: String,
    /** Native action to perform on tap. Defaults to [QuickReplyAction.SEND_TEXT] for missing/unknown values. */
    val action: QuickReplyAction = QuickReplyAction.SEND_TEXT
)

@Serializable
data class ChatResponse(
    val message: ChatMessage,
    @SerialName("tool_calls") val toolCalls: List<JsonObject> = emptyList(),
    @SerialName("quick_replies") val quickReplies: List<QuickReply> = emptyList()
)
