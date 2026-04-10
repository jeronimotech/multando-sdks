package com.multando.sdk.chat

import com.multando.sdk.core.HttpClient

/**
 * Service for interacting with the Multando AI conversation API.
 */
class ChatService internal constructor(
    private val httpClient: HttpClient
) {

    /** Create a new conversation. */
    suspend fun createConversation(): Conversation =
        httpClient.request(
            method = "POST",
            path = "/api/v1/conversations",
            body = emptyMap<String, String>()
        )

    /** List all conversations for the current user. */
    suspend fun listConversations(
        page: Int = 1,
        pageSize: Int = 20
    ): List<Conversation> {
        val params = mapOf(
            "page" to page.toString(),
            "page_size" to pageSize.toString()
        )
        return httpClient.request(
            method = "GET",
            path = "/api/v1/conversations",
            queryParams = params
        )
    }

    /** Fetch a single conversation with its messages. */
    suspend fun getConversation(id: Int): Conversation =
        httpClient.request(
            method = "GET",
            path = "/api/v1/conversations/$id"
        )

    /** Send a message to an existing conversation and receive the AI response. */
    suspend fun sendMessage(conversationId: Int, request: SendMessageRequest): ChatResponse =
        httpClient.request(
            method = "POST",
            path = "/api/v1/conversations/$conversationId/messages",
            body = request
        )

    /** Delete a conversation. */
    suspend fun deleteConversation(id: Int) {
        httpClient.requestVoid(
            method = "DELETE",
            path = "/api/v1/conversations/$id"
        )
    }
}
