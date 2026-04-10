import Foundation

/// Service for interacting with the Multando AI conversation API.
public final class ChatService: Sendable {

    private let httpClient: HTTPClient

    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }

    /// Create a new conversation.
    public func createConversation() async throws -> Conversation {
        try await httpClient.request(
            method: "POST",
            path: "/api/v1/conversations",
            body: [:] as [String: String]
        )
    }

    /// List all conversations for the current user.
    public func listConversations(page: Int = 1, pageSize: Int = 20) async throws -> [Conversation] {
        let queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "page_size", value: String(pageSize)),
        ]
        return try await httpClient.request(
            method: "GET",
            path: "/api/v1/conversations",
            queryItems: queryItems
        )
    }

    /// Fetch a single conversation with its messages.
    public func getConversation(id: Int) async throws -> Conversation {
        try await httpClient.request(
            method: "GET",
            path: "/api/v1/conversations/\(id)"
        )
    }

    /// Send a message to an existing conversation and receive the AI response.
    public func sendMessage(conversationId: Int, request: SendMessageRequest) async throws -> ChatResponse {
        try await httpClient.request(
            method: "POST",
            path: "/api/v1/conversations/\(conversationId)/messages",
            body: request
        )
    }

    /// Delete a conversation.
    public func deleteConversation(id: Int) async throws {
        try await httpClient.requestVoid(
            method: "DELETE",
            path: "/api/v1/conversations/\(id)"
        )
    }
}
