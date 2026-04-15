// Models for the AI chat / conversation feature.

class Conversation {
  const Conversation({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as int,
      status: json['status'] as String? ?? 'active',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      messages: json['messages'] != null
          ? (json['messages'] as List)
              .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  final int id;

  /// One of: active, completed, abandoned.
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.direction,
    this.content,
    required this.messageType,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as int,
      conversationId: json['conversation_id'] as int,
      direction: json['direction'] as String? ?? 'inbound',
      content: json['content'] as String?,
      messageType: json['message_type'] as String? ?? 'text',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final int id;
  final int conversationId;

  /// One of: inbound (user), outbound (AI).
  final String direction;
  final String? content;

  /// One of: text, image.
  final String messageType;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'conversation_id': conversationId,
        'direction': direction,
        if (content != null) 'content': content,
        'message_type': messageType,
        'created_at': createdAt.toIso8601String(),
      };
}

class SendMessageRequest {
  const SendMessageRequest({
    required this.content,
    this.imageBase64,
    this.imageMediaType = 'image/jpeg',
    this.imageHash,
    this.imageSignature,
    this.imageTimestamp,
    this.imageLatitude,
    this.imageLongitude,
    this.deviceId,
    this.captureMethod,
  });

  final String content;
  final String? imageBase64;
  final String imageMediaType;
  // Evidence metadata from SDK signing
  final String? imageHash;
  final String? imageSignature;
  final String? imageTimestamp;
  final double? imageLatitude;
  final double? imageLongitude;
  final String? deviceId;
  final String? captureMethod;

  Map<String, dynamic> toJson() => {
        'content': content,
        if (imageBase64 != null) 'image_base64': imageBase64,
        if (imageBase64 != null) 'image_media_type': imageMediaType,
        if (imageHash != null) 'image_hash': imageHash,
        if (imageSignature != null) 'image_signature': imageSignature,
        if (imageTimestamp != null) 'image_timestamp': imageTimestamp,
        if (imageLatitude != null) 'image_latitude': imageLatitude,
        if (imageLongitude != null) 'image_longitude': imageLongitude,
        if (deviceId != null) 'device_id': deviceId,
        if (captureMethod != null) 'capture_method': captureMethod,
      };
}

class ChatResponse {
  const ChatResponse({
    required this.message,
    this.toolCalls = const [],
    this.quickReplies = const [],
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      message: ChatMessage.fromJson(json['message'] as Map<String, dynamic>),
      toolCalls: json['tool_calls'] != null
          ? (json['tool_calls'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList()
          : const [],
      quickReplies: json['quick_replies'] != null
          ? (json['quick_replies'] as List)
              .map((e) => QuickReply.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [],
    );
  }

  final ChatMessage message;
  final List<Map<String, dynamic>> toolCalls;
  final List<QuickReply> quickReplies;

  Map<String, dynamic> toJson() => {
        'message': message.toJson(),
        'tool_calls': toolCalls,
        'quick_replies': quickReplies.map((q) => q.toJson()).toList(),
      };
}

/// Native action a quick-reply button can trigger.
enum QuickReplyAction {
  /// Send [QuickReply.value] as the user's next chat message.
  sendText,

  /// Ask the app to share the user's current location (GPS).
  shareLocation,

  /// Ask the app to open the camera and capture a photo.
  takePhoto,

  /// Ask the app to pick an image from the gallery.
  pickImage,

  /// Open [QuickReply.value] as an external URL.
  openUrl,
}

QuickReplyAction _parseQuickReplyAction(dynamic raw) {
  if (raw is! String) return QuickReplyAction.sendText;
  switch (raw) {
    case 'share_location':
      return QuickReplyAction.shareLocation;
    case 'take_photo':
      return QuickReplyAction.takePhoto;
    case 'pick_image':
      return QuickReplyAction.pickImage;
    case 'open_url':
      return QuickReplyAction.openUrl;
    case 'send_text':
    default:
      return QuickReplyAction.sendText;
  }
}

String _quickReplyActionToWire(QuickReplyAction a) {
  switch (a) {
    case QuickReplyAction.shareLocation:
      return 'share_location';
    case QuickReplyAction.takePhoto:
      return 'take_photo';
    case QuickReplyAction.pickImage:
      return 'pick_image';
    case QuickReplyAction.openUrl:
      return 'open_url';
    case QuickReplyAction.sendText:
      return 'send_text';
  }
}

class QuickReply {
  const QuickReply({
    required this.label,
    required this.value,
    this.action = QuickReplyAction.sendText,
  });

  factory QuickReply.fromJson(Map<String, dynamic> json) {
    return QuickReply(
      label: json['label'] as String,
      value: (json['value'] ?? json['label']) as String,
      action: _parseQuickReplyAction(json['action']),
    );
  }

  final String label;
  final String value;
  final QuickReplyAction action;

  Map<String, dynamic> toJson() => {
        'label': label,
        'value': value,
        'action': _quickReplyActionToWire(action),
      };
}
