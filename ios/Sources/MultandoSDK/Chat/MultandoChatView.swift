import SwiftUI

/// A drop-in SwiftUI chat view for the Multando AI assistant.
///
/// ```swift
/// MultandoChatView(client: multandoClient) {
///     print("Chat closed")
/// }
/// ```
@available(iOS 16.0, *)
public struct MultandoChatView: View {

    private let client: MultandoClient
    private let onClose: (() -> Void)?
    private let headerTitle: String

    @State private var conversation: Conversation?
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = true
    @State private var isSending = false
    @State private var error: String?
    @State private var toolCalls: [[String: AnyCodable]] = []

    private static let brandRed = Color(red: 0.902, green: 0.224, blue: 0.275)
    private static let brandRedLight = Color(red: 0.992, green: 0.929, blue: 0.937)
    private static let aiBubbleBg = Color(red: 0.941, green: 0.941, blue: 0.941)

    public init(
        client: MultandoClient,
        headerTitle: String = "Multando AI",
        onClose: (() -> Void)? = nil
    ) {
        self.client = client
        self.headerTitle = headerTitle
        self.onClose = onClose
    }

    public var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()

            if isLoading {
                loadingView
            } else if let error {
                errorView(message: error)
            } else {
                chatContent
            }
        }
        .task {
            await initConversation()
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            if let onClose {
                Button(action: onClose) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(Color.gray.opacity(0.12))
                        .clipShape(Circle())
                }
            }

            Spacer()

            Text(headerTitle)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)

            Spacer()

            // Balance the layout
            Color.clear
                .frame(width: 32, height: 32)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 12) {
            Spacer()
            ProgressView()
                .tint(Self.brandRed)
            Text("Starting conversation...")
                .font(.multandoBody)
                .foregroundColor(MultandoTheme.textSecondary)
            Spacer()
        }
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Text("Something went wrong")
                .font(.multandoTitle)
                .foregroundColor(.primary)
            Text(message)
                .font(.multandoBody)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button("Retry") {
                Task { await initConversation() }
            }
            .buttonStyle(.borderedProminent)
            .tint(Self.brandRed)
            Spacer()
        }
    }

    // MARK: - Chat Content

    private var chatContent: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        if messages.isEmpty {
                            emptyState
                        }

                        ForEach(messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }

                        // Typing indicator
                        if isSending {
                            typingIndicator
                                .id("typing")
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 16)
                }
                .onChange(of: messages.count) { _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: isSending) { _ in
                    scrollToBottom(proxy: proxy)
                }
            }

            // Tool call info cards
            if !toolCalls.isEmpty {
                toolCallCards
            }

            Divider()

            inputBar
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer().frame(height: 40)
            Text("Welcome to Multando AI")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            Text("Ask me anything about traffic violations, reports, or your account.")
                .font(.multandoBody)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer().frame(height: 40)
        }
    }

    private var typingIndicator: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.gray.opacity(0.4 + Double(index) * 0.2))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Self.aiBubbleBg)
            .clipShape(RoundedRectangle(cornerRadius: 18))

            Spacer()
        }
    }

    private var toolCallCards: some View {
        VStack(spacing: 4) {
            ForEach(Array(toolCalls.enumerated()), id: \.offset) { _, tc in
                HStack {
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: 3)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Action performed")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.orange)
                        Text((tc["name"]?.value as? String) ?? (tc["type"]?.value as? String) ?? "Tool call")
                            .font(.system(size: 13))
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 8)
                    .padding(.trailing, 12)

                    Spacer()
                }
                .background(Color(red: 1.0, green: 0.973, blue: 0.882))
                .cornerRadius(10)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Camera/image button
            Button(action: handleImagePicker) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color.gray.opacity(0.6))
            }
            .frame(width: 36, height: 36)

            // Text field
            TextField("Type a message...", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .disabled(isSending)

            // Send button
            Button(action: { Task { await handleSend() } }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(
                        inputText.trimmingCharacters(in: .whitespaces).isEmpty || isSending
                            ? Color.gray.opacity(0.3)
                            : Self.brandRed
                    )
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Actions

    private func initConversation() async {
        isLoading = true
        error = nil
        do {
            let conv = try await client.chat.createConversation()
            await MainActor.run {
                conversation = conv
                messages = conv.messages
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func handleSend() async {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, let conv = conversation, !isSending else { return }

        let currentText = text
        inputText = ""
        isSending = true
        toolCalls = []

        // Optimistic user message
        let optimistic = ChatMessage(
            id: Int.random(in: 100_000...999_999),
            conversationId: conv.id,
            direction: "outbound",
            content: currentText,
            messageType: "text",
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        messages.append(optimistic)

        do {
            let request = SendMessageRequest(content: currentText)
            let response = try await client.chat.sendMessage(
                conversationId: conv.id,
                request: request
            )

            await MainActor.run {
                // Keep the optimistic message, add AI response
                messages.append(response.message)
                if !response.toolCalls.isEmpty {
                    toolCalls = response.toolCalls
                }
                isSending = false
            }
        } catch {
            await MainActor.run {
                // Remove optimistic message on failure
                messages.removeAll { $0.id == optimistic.id }
                inputText = currentText
                isSending = false
            }
        }
    }

    private func handleImagePicker() {
        // Placeholder: Integrate with PHPicker or camera in production
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if isSending {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo("typing", anchor: .bottom)
            }
        } else if let lastMessage = messages.last {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Chat Bubble

@available(iOS 16.0, *)
private struct ChatBubble: View {
    let message: ChatMessage

    private static let brandRed = Color(red: 0.902, green: 0.224, blue: 0.275)
    private static let aiBubbleBg = Color(red: 0.941, green: 0.941, blue: 0.941)

    var body: some View {
        HStack {
            if message.isOutbound { Spacer(minLength: 48) }

            VStack(alignment: message.isOutbound ? .trailing : .leading, spacing: 4) {
                Text(message.content ?? "")
                    .font(.system(size: 15))
                    .foregroundColor(message.isOutbound ? .white : .primary)
                    .lineSpacing(3)

                Text(formatTime(message.createdAt))
                    .font(.system(size: 11))
                    .foregroundColor(
                        message.isOutbound
                            ? Color.white.opacity(0.7)
                            : Color.gray
                    )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(message.isOutbound ? Self.brandRed : Self.aiBubbleBg)
            .clipShape(
                RoundedRectangle(cornerRadius: 18)
            )

            if !message.isOutbound { Spacer(minLength: 48) }
        }
    }

    private func formatTime(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else { return "" }
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        return timeFormatter.string(from: date)
    }
}
