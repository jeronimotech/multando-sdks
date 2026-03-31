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
    @SerialName("image_media_type") val imageMediaType: String? = null
)

@Serializable
data class ChatResponse(
    val message: ChatMessage,
    @SerialName("tool_calls") val toolCalls: List<JsonObject> = emptyList()
)
