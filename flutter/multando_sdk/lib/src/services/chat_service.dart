import '../core/http_client.dart';
import '../models/conversation.dart';

/// Service for AI chat conversations.
class ChatService {
  ChatService({required MultandoHttpClient httpClient}) : _http = httpClient;

  final MultandoHttpClient _http;

  /// Create a new conversation.
  Future<Conversation> createConversation() async {
    final response = await _http.post<Map<String, dynamic>>(
      '/conversations',
      data: {},
    );
    return Conversation.fromJson(response.data!);
  }

  /// List all conversations for the current user.
  Future<List<Conversation>> listConversations() async {
    final response = await _http.get<dynamic>('/conversations');
    final data = response.data;
    if (data is List) {
      return data
          .cast<Map<String, dynamic>>()
          .map(Conversation.fromJson)
          .toList();
    }
    if (data is Map<String, dynamic>) {
      final items = data['items'] as List? ?? [];
      return items
          .cast<Map<String, dynamic>>()
          .map(Conversation.fromJson)
          .toList();
    }
    return [];
  }

  /// Get a single conversation by ID, including its messages.
  Future<Conversation> getConversation(int id) async {
    final response =
        await _http.get<Map<String, dynamic>>('/conversations/$id');
    return Conversation.fromJson(response.data!);
  }

  /// Send a message to a conversation and receive the AI response.
  Future<ChatResponse> sendMessage(
    int conversationId,
    SendMessageRequest request,
  ) async {
    final response = await _http.post<Map<String, dynamic>>(
      '/conversations/$conversationId/messages',
      data: request.toJson(),
    );
    return ChatResponse.fromJson(response.data!);
  }

  /// Delete a conversation.
  Future<void> deleteConversation(int id) async {
    await _http.delete<void>('/conversations/$id');
  }
}
