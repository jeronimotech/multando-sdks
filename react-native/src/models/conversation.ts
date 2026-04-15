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

/**
 * Native action a quick-reply button can trigger.
 *
 * - `send_text` (default): send `QuickReply.value` as the user's next chat message.
 * - `share_location`: ask the app to share the user's current location (GPS).
 * - `take_photo`: ask the app to open the camera and capture a photo.
 * - `pick_image`: ask the app to pick an image from the gallery.
 * - `open_url`: open `QuickReply.value` as an external URL.
 */
export type QuickReplyAction =
  | 'send_text'
  | 'share_location'
  | 'take_photo'
  | 'pick_image'
  | 'open_url';

const VALID_QUICK_REPLY_ACTIONS: ReadonlyArray<QuickReplyAction> = [
  'send_text',
  'share_location',
  'take_photo',
  'pick_image',
  'open_url',
];

/**
 * Parse a raw `action` field from a server payload into a `QuickReplyAction`.
 * Returns `'send_text'` when missing, non-string, or unknown.
 */
export function parseQuickReplyAction(raw: unknown): QuickReplyAction {
  if (typeof raw !== 'string') return 'send_text';
  return (VALID_QUICK_REPLY_ACTIONS as ReadonlyArray<string>).includes(raw)
    ? (raw as QuickReplyAction)
    : 'send_text';
}

export interface QuickReply {
  label: string;
  value: string;
  action: QuickReplyAction;
}

/** Build a `QuickReply` from a raw JSON object, defaulting `action` safely. */
export function quickReplyFromJson(json: Record<string, unknown>): QuickReply {
  const label = (json.label as string) ?? '';
  const value = (json.value as string) ?? label;
  return {
    label,
    value,
    action: parseQuickReplyAction(json.action),
  };
}

/** Serialize a `QuickReply` to a wire-format JSON object. */
export function quickReplyToJson(reply: QuickReply): Record<string, unknown> {
  return {
    label: reply.label,
    value: reply.value,
    action: reply.action,
  };
}

export interface ChatResponse {
  message: ChatMessage;
  toolCalls: Record<string, unknown>[];
  quickReplies: QuickReply[];
}

/**
 * Normalize a raw `ChatResponse` payload so `quickReplies[].action` is always
 * populated with a valid `QuickReplyAction` (defaults to `'send_text'`).
 */
export function normalizeChatResponse(raw: unknown): ChatResponse {
  const obj = (raw ?? {}) as Record<string, unknown>;
  const rawQuickReplies = Array.isArray(obj.quickReplies)
    ? (obj.quickReplies as Record<string, unknown>[])
    : Array.isArray((obj as Record<string, unknown>).quick_replies)
      ? ((obj as Record<string, unknown>).quick_replies as Record<
          string,
          unknown
        >[])
      : [];
  return {
    message: obj.message as ChatMessage,
    toolCalls: Array.isArray(obj.toolCalls)
      ? (obj.toolCalls as Record<string, unknown>[])
      : Array.isArray((obj as Record<string, unknown>).tool_calls)
        ? ((obj as Record<string, unknown>).tool_calls as Record<
            string,
            unknown
          >[])
        : [],
    quickReplies: rawQuickReplies.map(quickReplyFromJson),
  };
}
