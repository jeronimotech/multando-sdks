import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/multando_client.dart';
import '../models/conversation.dart';

/// A drop-in AI chat widget that third-party apps can embed.
///
/// Provides the full Multa AI experience: text messages, image upload,
/// location sharing, quick-reply chips, markdown rendering, and typing
/// indicators.
///
/// ```dart
/// MultandoChat(
///   client: multandoClient,
///   primaryColor: Color(0xFFEF4444),
///   placeholder: 'Ask Multa anything...',
///   welcomeTitle: 'Welcome!',
/// )
/// ```
class MultandoChat extends StatefulWidget {
  const MultandoChat({
    super.key,
    required this.client,
    this.primaryColor = const Color(0xFFEF4444),
    this.placeholder = 'Ask Multa anything...',
    this.welcomeTitle = 'Multa AI',
    this.welcomeSubtitle =
        'I can help you report infractions, check your rewards, '
            'and answer questions. Type a message to get started!',
    this.suggestions = const [
      'Report an infraction',
      'Check my rewards',
      'What infractions exist?',
    ],
    this.showCamera = true,
    this.showGallery = false,
    this.showLocation = true,
    this.onPickImage,
    this.onShareLocation,
    this.onOpenUrl,
    this.locale = 'es',
  });

  /// The initialized [MultandoClient] to use for API calls.
  final MultandoClient client;

  /// Brand color used for user bubbles, icons, and chips.
  final Color primaryColor;

  /// Placeholder text in the message input.
  final String placeholder;

  /// Title shown on the welcome screen.
  final String welcomeTitle;

  /// Subtitle shown on the welcome screen.
  final String welcomeSubtitle;

  /// Suggestion chips shown on the welcome screen.
  final List<String> suggestions;

  /// Whether to show the camera button.
  final bool showCamera;

  /// Whether to show the gallery button.
  final bool showGallery;

  /// Whether to show the location button.
  final bool showLocation;

  /// Callback to pick an image. Return base64-encoded bytes or null.
  /// If not provided, the camera/gallery buttons are hidden.
  final Future<String?> Function(bool fromCamera)? onPickImage;

  /// Callback to share location. Return "lat, lon" string or null.
  /// If not provided, the location button is hidden.
  final Future<String?> Function()? onShareLocation;

  /// Callback when a quick reply with action=openUrl is tapped.
  final void Function(String url)? onOpenUrl;

  /// Locale for quick reply action dispatching ('en' or 'es').
  final String locale;

  @override
  State<MultandoChat> createState() => _MultandoChatState();
}

class _MultandoChatState extends State<MultandoChat> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  Conversation? _conversation;
  List<ChatMessage> _messages = [];
  List<QuickReply> _quickReplies = [];
  List<Map<String, dynamic>> _toolCalls = [];
  bool _isSending = false;
  String? _error;
  String? _pendingImageBase64;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text, {String? imageBase64}) async {
    final content = text.trim();
    if (content.isEmpty && imageBase64 == null) return;

    setState(() {
      _isSending = true;
      _error = null;
      _quickReplies = [];
    });

    try {
      // Create conversation on first message.
      var conv = _conversation;
      if (conv == null) {
        conv = await widget.client.chat.createConversation();
        setState(() {
          _conversation = conv;
        });
      }

      // Add optimistic user message.
      final userMsg = ChatMessage(
        id: -DateTime.now().millisecondsSinceEpoch,
        conversationId: conv.id,
        direction: 'inbound',
        content: content.isNotEmpty ? content : '[image]',
        messageType: imageBase64 != null ? 'image' : 'text',
        createdAt: DateTime.now(),
      );
      setState(() => _messages = [..._messages, userMsg]);
      _scrollToBottom();

      // Send to API.
      final request = SendMessageRequest(
        content: content.isNotEmpty ? content : 'Analyze this image',
        imageBase64: imageBase64,
      );
      final response = await widget.client.chat.sendMessage(conv.id, request);

      setState(() {
        _messages = [
          ..._messages.where((m) => m.id != userMsg.id),
          userMsg,
          response.message,
        ];
        _toolCalls = response.toolCalls;
        _quickReplies = response.quickReplies;
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isSending = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _handleQuickReply(QuickReply reply) async {
    switch (reply.action) {
      case QuickReplyAction.shareLocation:
        if (widget.onShareLocation != null) {
          final loc = await widget.onShareLocation!();
          if (loc != null) {
            await _sendMessage('My current location: $loc');
          }
        }
        return;
      case QuickReplyAction.takePhoto:
        if (widget.onPickImage != null) {
          final b64 = await widget.onPickImage!(true);
          if (b64 != null) {
            setState(() => _pendingImageBase64 = b64);
          }
        }
        return;
      case QuickReplyAction.pickImage:
        if (widget.onPickImage != null) {
          final b64 = await widget.onPickImage!(false);
          if (b64 != null) {
            setState(() => _pendingImageBase64 = b64);
          }
        }
        return;
      case QuickReplyAction.openUrl:
        widget.onOpenUrl?.call(reply.value);
        return;
      case QuickReplyAction.sendText:
        await _sendMessage(reply.value);
        return;
    }
  }

  void _onSendPressed() {
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingImageBase64 == null) return;
    _controller.clear();
    final img = _pendingImageBase64;
    setState(() => _pendingImageBase64 = null);
    _sendMessage(text.isNotEmpty ? text : '', imageBase64: img);
  }

  /// Resets the conversation state, clearing all messages.
  void resetConversation() {
    setState(() {
      _conversation = null;
      _messages = [];
      _quickReplies = [];
      _toolCalls = [];
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primaryColor;
    final surfaceBg = Colors.grey.shade100;
    final surfaceText = Colors.grey.shade800;

    return Column(
      children: [
        // Messages
        Expanded(
          child: _messages.isEmpty
              ? _buildWelcome(primary, surfaceText)
              : ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _messages.length +
                      (_isSending ? 1 : 0) +
                      (_toolCalls.isNotEmpty ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_toolCalls.isNotEmpty &&
                        index == _messages.length + (_isSending ? 1 : 0)) {
                      return _buildToolCalls(primary);
                    }
                    if (_isSending && index == _messages.length) {
                      return _buildTypingIndicator(primary);
                    }
                    return _buildBubble(_messages[index], primary, surfaceBg);
                  },
                ),
        ),

        // Error banner
        if (_error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.red.shade50,
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => setState(() => _error = null),
                ),
              ],
            ),
          ),

        // Image preview
        if (_pendingImageBase64 != null)
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            alignment: Alignment.centerLeft,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(_pendingImageBase64!),
                    height: 72,
                    width: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => setState(() => _pendingImageBase64 = null),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(Icons.close,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Quick reply chips
        if (_quickReplies.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickReplies.map((reply) {
                return ActionChip(
                  label: Text(reply.label),
                  labelStyle: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  backgroundColor: primary.withAlpha(20),
                  side: BorderSide(color: primary.withAlpha(80)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed:
                      _isSending ? null : () => _handleQuickReply(reply),
                );
              }).toList(),
            ),
          ),

        // Input bar
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            left: 8,
            right: 8,
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 8,
          ),
          child: Row(
            children: [
              if (widget.showCamera && widget.onPickImage != null)
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined),
                  color: Colors.grey.shade500,
                  onPressed: () async {
                    final b64 = await widget.onPickImage!(true);
                    if (b64 != null) {
                      setState(() => _pendingImageBase64 = b64);
                    }
                  },
                  tooltip: 'Take photo',
                ),
              if (widget.showGallery && widget.onPickImage != null)
                IconButton(
                  icon: const Icon(Icons.photo_library_outlined),
                  color: Colors.grey.shade500,
                  onPressed: () async {
                    final b64 = await widget.onPickImage!(false);
                    if (b64 != null) {
                      setState(() => _pendingImageBase64 = b64);
                    }
                  },
                  tooltip: 'Pick from gallery',
                ),
              if (widget.showLocation && widget.onShareLocation != null)
                IconButton(
                  icon: const Icon(Icons.location_on_outlined),
                  color: Colors.grey.shade500,
                  onPressed: () async {
                    final loc = await widget.onShareLocation!();
                    if (loc != null) {
                      _sendMessage('My current location: $loc');
                    }
                  },
                  tooltip: 'Share location',
                ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _onSendPressed(),
                    maxLines: 4,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: widget.placeholder,
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: _isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primary,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                color: primary,
                onPressed: _isSending ? null : _onSendPressed,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------- Sub-widgets ---------------

  Widget _buildWelcome(Color primary, Color textColor) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.smart_toy_outlined, size: 40, color: primary),
            ),
            const SizedBox(height: 24),
            Text(
              widget.welcomeTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.welcomeSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: widget.suggestions.map((label) {
                return ActionChip(
                  label: Text(label),
                  labelStyle: TextStyle(color: primary, fontSize: 13),
                  backgroundColor: primary.withAlpha(20),
                  side: BorderSide(color: primary.withAlpha(50)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: () => _sendMessage(label),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(
      ChatMessage message, Color primary, Color surfaceBg) {
    final isUser = message.direction == 'inbound';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? primary : surfaceBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
              ),
              child: Text(
                message.content ?? '',
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.grey.shade800,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Padding(
                  padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCalls(Color primary) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _toolCalls.map((tc) {
          final name = (tc['name'] as String? ?? tc['tool'] as String? ?? 'action')
              .replaceAll('_', ' ');
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: primary.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: primary.withAlpha(40)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.build_circle_outlined, size: 14, color: primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: 12,
                      color: primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
