export interface Conversation {
  id: number;
  status: string;
  createdAt: string;
  updatedAt: string;
  messages: ChatMessage[];
}

export interface ChatMessage {
  id: number;
  conversationId: number;
  direction: 'inbound' | 'outbound';
  content: string | null;
  messageType: string;
  createdAt: string;
}

export interface SendMessageRequest {
  content: string;
  imageBase64?: string;
  imageMediaType?: string;
  imageHash?: string;
  imageSignature?: string;
  imageTimestamp?: string;
  imageLatitude?: number;
  imageLongitude?: number;
  deviceId?: string;
  captureMethod?: string;
}

export interface QuickReply {
  label: string;
  value: string;
}

export interface ChatResponse {
  message: ChatMessage;
  toolCalls: Record<string, unknown>[];
  quickReplies: QuickReply[];
}
