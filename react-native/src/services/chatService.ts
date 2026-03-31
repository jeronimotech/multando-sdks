import { AxiosInstance } from 'axios';
import { Logger } from '../core/logger';
import {
  Conversation,
  ChatMessage,
  SendMessageRequest,
  ChatResponse,
} from '../models/conversation';

export interface ConversationListParams {
  page?: number;
  pageSize?: number;
  status?: string;
}

export class ChatService {
  private http: AxiosInstance;
  private logger: Logger;

  constructor(http: AxiosInstance, logger: Logger) {
    this.http = http;
    this.logger = logger;
  }

  /** Create a new AI conversation. */
  async createConversation(): Promise<Conversation> {
    const response = await this.http.post<Conversation>('/conversations');
    return response.data;
  }

  /** List all conversations for the current user. */
  async listConversations(
    params?: ConversationListParams,
  ): Promise<Conversation[]> {
    const response = await this.http.get<Conversation[]>('/conversations', {
      params,
    });
    return response.data;
  }

  /** Get a single conversation with its messages. */
  async getConversation(id: number): Promise<Conversation> {
    const response = await this.http.get<Conversation>(
      `/conversations/${id}`,
    );
    return response.data;
  }

  /** Send a message to an existing conversation and receive the AI response. */
  async sendMessage(
    conversationId: number,
    request: SendMessageRequest,
  ): Promise<ChatResponse> {
    const response = await this.http.post<ChatResponse>(
      `/conversations/${conversationId}/messages`,
      request,
    );
    return response.data;
  }

  /** Delete a conversation. */
  async deleteConversation(id: number): Promise<void> {
    await this.http.delete(`/conversations/${id}`);
  }
}
