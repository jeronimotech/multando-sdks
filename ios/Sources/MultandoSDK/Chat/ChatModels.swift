import Foundation

/// A conversation with the Multando AI assistant.
public struct Conversation: Codable, Sendable {
    public let id: Int
    public let status: String
    public let createdAt: String
    public let updatedAt: String
    public var messages: [ChatMessage]

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case messages
    }
}

/// A single message in a conversation.
public struct ChatMessage: Codable, Sendable, Identifiable {
    public let id: Int
    public let conversationId: Int
    public let direction: String
    public let content: String?
    public let messageType: String
    public let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case direction
        case content
        case messageType = "message_type"
        case createdAt = "created_at"
    }

    /// Whether this message was sent by the user.
    public var isOutbound: Bool { direction == "outbound" }
}

/// Payload for sending a message to the AI.
public struct SendMessageRequest: Codable, Sendable {
    public let content: String
    public let imageBase64: String?
    public let imageMediaType: String?
    public let imageHash: String?
    public let imageSignature: String?
    public let imageTimestamp: String?
    public let imageLatitude: Double?
    public let imageLongitude: Double?
    public let deviceId: String?
    public let captureMethod: String?

    public init(
        content: String,
        imageBase64: String? = nil,
        imageMediaType: String? = nil,
        imageHash: String? = nil,
        imageSignature: String? = nil,
        imageTimestamp: String? = nil,
        imageLatitude: Double? = nil,
        imageLongitude: Double? = nil,
        deviceId: String? = nil,
        captureMethod: String? = nil
    ) {
        self.content = content
        self.imageBase64 = imageBase64
        self.imageMediaType = imageMediaType
        self.imageHash = imageHash
        self.imageSignature = imageSignature
        self.imageTimestamp = imageTimestamp
        self.imageLatitude = imageLatitude
        self.imageLongitude = imageLongitude
        self.deviceId = deviceId
        self.captureMethod = captureMethod
    }

    enum CodingKeys: String, CodingKey {
        case content
        case imageBase64 = "image_base64"
        case imageMediaType = "image_media_type"
        case imageHash = "image_hash"
        case imageSignature = "image_signature"
        case imageTimestamp = "image_timestamp"
        case imageLatitude = "image_latitude"
        case imageLongitude = "image_longitude"
        case deviceId = "device_id"
        case captureMethod = "capture_method"
    }
}

/// Native action a quick-reply button can trigger.
public enum QuickReplyAction: String, Codable, Sendable, Hashable {
    /// Send `QuickReply.value` as the user's next chat message.
    case sendText = "send_text"
    /// Ask the app to share the user's current location (GPS).
    case shareLocation = "share_location"
    /// Ask the app to open the camera and capture a photo.
    case takePhoto = "take_photo"
    /// Ask the app to pick an image from the gallery.
    case pickImage = "pick_image"
    /// Open `QuickReply.value` as an external URL.
    case openUrl = "open_url"
}

/// A quick-reply suggestion that the UI can render as a tappable chip/button.
public struct QuickReply: Codable, Sendable, Hashable {
    /// Display text for the button.
    public let label: String
    /// Text to send when the button is tapped.
    public let value: String
    /// Native action to perform when the button is tapped. Defaults to `.sendText`.
    public let action: QuickReplyAction

    public init(
        label: String,
        value: String,
        action: QuickReplyAction = .sendText
    ) {
        self.label = label
        self.value = value
        self.action = action
    }

    enum CodingKeys: String, CodingKey {
        case label
        case value
        case action
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.label = try container.decode(String.self, forKey: .label)
        self.value = (try? container.decode(String.self, forKey: .value)) ?? self.label
        // Tolerate missing or unknown action values by defaulting to .sendText.
        if let raw = try? container.decodeIfPresent(String.self, forKey: .action),
           let parsed = QuickReplyAction(rawValue: raw) {
            self.action = parsed
        } else {
            self.action = .sendText
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(label, forKey: .label)
        try container.encode(value, forKey: .value)
        try container.encode(action, forKey: .action)
    }
}

/// Response from the AI after sending a message.
public struct ChatResponse: Codable, Sendable {
    public let message: ChatMessage
    public let toolCalls: [[String: AnyCodable]]
    public let quickReplies: [QuickReply]

    enum CodingKeys: String, CodingKey {
        case message
        case toolCalls = "tool_calls"
        case quickReplies = "quick_replies"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        message = try container.decode(ChatMessage.self, forKey: .message)
        toolCalls = try container.decodeIfPresent([[String: AnyCodable]].self, forKey: .toolCalls) ?? []
        quickReplies = try container.decodeIfPresent([QuickReply].self, forKey: .quickReplies) ?? []
    }

    public init(
        message: ChatMessage,
        toolCalls: [[String: AnyCodable]] = [],
        quickReplies: [QuickReply] = []
    ) {
        self.message = message
        self.toolCalls = toolCalls
        self.quickReplies = quickReplies
    }
}

/// A type-erased Codable wrapper for handling arbitrary JSON values in tool calls.
public struct AnyCodable: Codable, @unchecked Sendable {
    public let value: Any?

    public init(_ value: Any?) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let arrayVal = try? container.decode([AnyCodable].self) {
            value = arrayVal.map { $0.value }
        } else if let dictVal = try? container.decode([String: AnyCodable].self) {
            value = dictVal.mapValues { $0.value }
        } else {
            value = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if value == nil {
            try container.encodeNil()
        } else if let boolVal = value as? Bool {
            try container.encode(boolVal)
        } else if let intVal = value as? Int {
            try container.encode(intVal)
        } else if let doubleVal = value as? Double {
            try container.encode(doubleVal)
        } else if let stringVal = value as? String {
            try container.encode(stringVal)
        } else {
            try container.encodeNil()
        }
    }
}
