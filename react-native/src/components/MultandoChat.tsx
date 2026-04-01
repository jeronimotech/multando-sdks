import React, { useState, useCallback, useEffect, useRef } from 'react';
import {
  View,
  Text,
  TextInput,
  TouchableOpacity,
  FlatList,
  ActivityIndicator,
  StyleSheet,
  KeyboardAvoidingView,
  Platform,
  Alert,
  ViewStyle,
  TextStyle,
  ListRenderItemInfo,
  Image,
} from 'react-native';
import { useMultando } from '../hooks/useMultando';
import {
  ChatMessage,
  Conversation,
  ChatResponse,
  SendMessageRequest,
} from '../models/conversation';

const BRAND_RED = '#E63946';
const BRAND_RED_LIGHT = '#FDEDEF';
const AI_BUBBLE_BG = '#F0F0F0';

export interface MultandoChatProps {
  /** Called when the user taps the close/back button. */
  onClose?: () => void;
  /** Optional style override for the root container. */
  style?: ViewStyle;
  /** Custom header title. Defaults to "Multando AI". */
  headerTitle?: string;
}

export function MultandoChat({
  onClose,
  style,
  headerTitle = 'Multando AI',
}: MultandoChatProps): React.ReactElement {
  const { client } = useMultando();
  const chatService = client.chat;

  const [conversation, setConversation] = useState<Conversation | null>(null);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [inputText, setInputText] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [isSending, setIsSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [toolCalls, setToolCalls] = useState<Record<string, unknown>[]>([]);

  const flatListRef = useRef<FlatList<ChatMessage>>(null);

  // Initialize conversation on mount
  useEffect(() => {
    initConversation();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const initConversation = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const conv = await chatService.createConversation();
      setConversation(conv);
      setMessages(conv.messages ?? []);
    } catch (err) {
      const message =
        err instanceof Error ? err.message : 'Failed to start conversation';
      setError(message);
    } finally {
      setIsLoading(false);
    }
  }, [chatService]);

  const handleSend = useCallback(async () => {
    const text = inputText.trim();
    if (!text || !conversation || isSending) return;

    setInputText('');
    setIsSending(true);
    setToolCalls([]);

    // Optimistically add the user message
    const optimisticMsg: ChatMessage = {
      id: Date.now(),
      conversationId: conversation.id,
      direction: 'outbound',
      content: text,
      messageType: 'text',
      createdAt: new Date().toISOString(),
    };
    setMessages((prev) => [...prev, optimisticMsg]);

    try {
      const request: SendMessageRequest = { content: text };
      const response: ChatResponse = await chatService.sendMessage(
        conversation.id,
        request,
      );

      // Replace optimistic message with server version and add AI response
      setMessages((prev) => {
        const withoutOptimistic = prev.filter(
          (m) => m.id !== optimisticMsg.id,
        );
        // The server returns the AI message; we also need the user message from
        // a fresh fetch or we trust the optimistic one was correct.
        return [...withoutOptimistic, optimisticMsg, response.message];
      });

      if (response.toolCalls && response.toolCalls.length > 0) {
        setToolCalls(response.toolCalls);
      }
    } catch (err) {
      const message =
        err instanceof Error ? err.message : 'Failed to send message';
      Alert.alert('Error', message);
      // Remove optimistic message on failure
      setMessages((prev) => prev.filter((m) => m.id !== optimisticMsg.id));
      setInputText(text);
    } finally {
      setIsSending(false);
    }
  }, [inputText, conversation, isSending, chatService]);

  const handleImagePicker = useCallback(() => {
    // Placeholder: In a real implementation, use react-native-image-picker
    // or expo-image-picker to get a base64 image.
    Alert.alert(
      'Image Attachment',
      'Image picker integration required. Use react-native-image-picker or expo-image-picker.',
    );
  }, []);

  const scrollToEnd = useCallback(() => {
    if (flatListRef.current && messages.length > 0) {
      flatListRef.current.scrollToEnd({ animated: true });
    }
  }, [messages.length]);

  useEffect(() => {
    // Scroll to bottom when messages change
    const timer = setTimeout(scrollToEnd, 100);
    return () => clearTimeout(timer);
  }, [messages.length, scrollToEnd]);

  const renderMessage = useCallback(
    ({ item }: ListRenderItemInfo<ChatMessage>) => {
      const isUser = item.direction === 'outbound';
      return (
        <View
          style={[
            styles.messageBubbleRow,
            isUser ? styles.messageBubbleRowUser : styles.messageBubbleRowAI,
          ]}
        >
          <View
            style={[
              styles.messageBubble,
              isUser ? styles.userBubble : styles.aiBubble,
            ]}
          >
            <Text
              style={[
                styles.messageText,
                isUser ? styles.userMessageText : styles.aiMessageText,
              ]}
            >
              {item.content ?? ''}
            </Text>
            <Text
              style={[
                styles.messageTime,
                isUser ? styles.userMessageTime : styles.aiMessageTime,
              ]}
            >
              {formatTime(item.createdAt)}
            </Text>
          </View>
        </View>
      );
    },
    [],
  );

  const keyExtractor = useCallback(
    (item: ChatMessage) => String(item.id),
    [],
  );

  // Loading state
  if (isLoading) {
    return (
      <View style={[styles.container, styles.centered, style]}>
        <ActivityIndicator size="large" color={BRAND_RED} />
        <Text style={styles.loadingText}>Starting conversation...</Text>
      </View>
    );
  }

  // Error state
  if (error) {
    return (
      <View style={[styles.container, styles.centered, style]}>
        <Text style={styles.errorTitle}>Something went wrong</Text>
        <Text style={styles.errorMessage}>{error}</Text>
        <TouchableOpacity style={styles.retryButton} onPress={initConversation}>
          <Text style={styles.retryButtonText}>Retry</Text>
        </TouchableOpacity>
      </View>
    );
  }

  return (
    <KeyboardAvoidingView
      style={[styles.container, style]}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      keyboardVerticalOffset={Platform.OS === 'ios' ? 88 : 0}
    >
      {/* Header */}
      <View style={styles.header}>
        {onClose && (
          <TouchableOpacity
            style={styles.closeButton}
            onPress={onClose}
            hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
          >
            <Text style={styles.closeButtonText}>{'<'}</Text>
          </TouchableOpacity>
        )}
        <Text style={styles.headerTitle}>{headerTitle}</Text>
        <View style={styles.headerSpacer} />
      </View>

      {/* Messages */}
      <FlatList
        ref={flatListRef}
        data={messages}
        renderItem={renderMessage}
        keyExtractor={keyExtractor}
        contentContainerStyle={styles.messagesList}
        showsVerticalScrollIndicator={false}
        ListEmptyComponent={
          <View style={styles.emptyContainer}>
            <Text style={styles.emptyTitle}>Welcome to Multando AI</Text>
            <Text style={styles.emptySubtitle}>
              Ask me anything about traffic infractions, reports, or your account.
            </Text>
          </View>
        }
        onContentSizeChange={scrollToEnd}
      />

      {/* Tool calls info */}
      {toolCalls.length > 0 && (
        <View style={styles.toolCallsContainer}>
          {toolCalls.map((tc, index) => (
            <View key={index} style={styles.toolCallCard}>
              <Text style={styles.toolCallLabel}>Action performed</Text>
              <Text style={styles.toolCallContent}>
                {(tc.name as string) ?? (tc.type as string) ?? 'Tool call'}
              </Text>
            </View>
          ))}
        </View>
      )}

      {/* Typing indicator */}
      {isSending && (
        <View style={styles.typingContainer}>
          <View style={styles.typingBubble}>
            <View style={styles.typingDots}>
              <View style={[styles.typingDot, styles.typingDot1]} />
              <View style={[styles.typingDot, styles.typingDot2]} />
              <View style={[styles.typingDot, styles.typingDot3]} />
            </View>
          </View>
        </View>
      )}

      {/* Input bar */}
      <View style={styles.inputBar}>
        <TouchableOpacity
          style={styles.imageButton}
          onPress={handleImagePicker}
          hitSlop={{ top: 8, bottom: 8, left: 8, right: 8 }}
        >
          <Text style={styles.imageButtonText}>+</Text>
        </TouchableOpacity>

        <TextInput
          style={styles.textInput}
          value={inputText}
          onChangeText={setInputText}
          placeholder="Type a message..."
          placeholderTextColor="#999999"
          multiline
          maxLength={4096}
          editable={!isSending}
          returnKeyType="send"
          blurOnSubmit={false}
          onSubmitEditing={handleSend}
        />

        <TouchableOpacity
          style={[
            styles.sendButton,
            (!inputText.trim() || isSending) && styles.sendButtonDisabled,
          ]}
          onPress={handleSend}
          disabled={!inputText.trim() || isSending}
        >
          <Text style={styles.sendButtonText}>{'>'}</Text>
        </TouchableOpacity>
      </View>
    </KeyboardAvoidingView>
  );
}

function formatTime(isoString: string): string {
  try {
    const date = new Date(isoString);
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  } catch {
    return '';
  }
}

// --- Styles ---

interface Styles {
  container: ViewStyle;
  centered: ViewStyle;
  loadingText: TextStyle;
  errorTitle: TextStyle;
  errorMessage: TextStyle;
  retryButton: ViewStyle;
  retryButtonText: TextStyle;
  header: ViewStyle;
  closeButton: ViewStyle;
  closeButtonText: TextStyle;
  headerTitle: TextStyle;
  headerSpacer: ViewStyle;
  messagesList: ViewStyle;
  emptyContainer: ViewStyle;
  emptyTitle: TextStyle;
  emptySubtitle: TextStyle;
  messageBubbleRow: ViewStyle;
  messageBubbleRowUser: ViewStyle;
  messageBubbleRowAI: ViewStyle;
  messageBubble: ViewStyle;
  userBubble: ViewStyle;
  aiBubble: ViewStyle;
  messageText: TextStyle;
  userMessageText: TextStyle;
  aiMessageText: TextStyle;
  messageTime: TextStyle;
  userMessageTime: TextStyle;
  aiMessageTime: TextStyle;
  toolCallsContainer: ViewStyle;
  toolCallCard: ViewStyle;
  toolCallLabel: TextStyle;
  toolCallContent: TextStyle;
  typingContainer: ViewStyle;
  typingBubble: ViewStyle;
  typingDots: ViewStyle;
  typingDot: ViewStyle;
  typingDot1: ViewStyle;
  typingDot2: ViewStyle;
  typingDot3: ViewStyle;
  inputBar: ViewStyle;
  imageButton: ViewStyle;
  imageButtonText: TextStyle;
  textInput: TextStyle;
  sendButton: ViewStyle;
  sendButtonDisabled: ViewStyle;
  sendButtonText: TextStyle;
}

const styles = StyleSheet.create<Styles>({
  container: {
    flex: 1,
    backgroundColor: '#FFFFFF',
  },
  centered: {
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  loadingText: {
    marginTop: 12,
    fontSize: 16,
    color: '#666666',
  },
  errorTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333333',
    marginBottom: 8,
  },
  errorMessage: {
    fontSize: 14,
    color: '#666666',
    textAlign: 'center',
    marginBottom: 16,
  },
  retryButton: {
    paddingHorizontal: 24,
    paddingVertical: 10,
    borderRadius: 8,
    backgroundColor: BRAND_RED,
  },
  retryButtonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#F0F0F0',
    backgroundColor: '#FFFFFF',
  },
  closeButton: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#F0F0F0',
    justifyContent: 'center',
    alignItems: 'center',
  },
  closeButtonText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333333',
  },
  headerTitle: {
    flex: 1,
    textAlign: 'center',
    fontSize: 17,
    fontWeight: '600',
    color: '#333333',
  },
  headerSpacer: {
    width: 32,
  },
  messagesList: {
    paddingHorizontal: 12,
    paddingVertical: 16,
    flexGrow: 1,
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    paddingHorizontal: 32,
    paddingVertical: 60,
  },
  emptyTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: '#333333',
    marginBottom: 8,
  },
  emptySubtitle: {
    fontSize: 14,
    color: '#999999',
    textAlign: 'center',
    lineHeight: 20,
  },
  messageBubbleRow: {
    flexDirection: 'row',
    marginBottom: 8,
  },
  messageBubbleRowUser: {
    justifyContent: 'flex-end',
  },
  messageBubbleRowAI: {
    justifyContent: 'flex-start',
  },
  messageBubble: {
    maxWidth: '78%',
    paddingHorizontal: 14,
    paddingVertical: 10,
    borderRadius: 18,
  },
  userBubble: {
    backgroundColor: BRAND_RED,
    borderBottomRightRadius: 4,
  },
  aiBubble: {
    backgroundColor: AI_BUBBLE_BG,
    borderBottomLeftRadius: 4,
  },
  messageText: {
    fontSize: 15,
    lineHeight: 21,
  },
  userMessageText: {
    color: '#FFFFFF',
  },
  aiMessageText: {
    color: '#333333',
  },
  messageTime: {
    fontSize: 11,
    marginTop: 4,
  },
  userMessageTime: {
    color: 'rgba(255,255,255,0.7)',
    textAlign: 'right',
  },
  aiMessageTime: {
    color: '#999999',
    textAlign: 'left',
  },
  toolCallsContainer: {
    paddingHorizontal: 12,
    paddingBottom: 8,
  },
  toolCallCard: {
    backgroundColor: '#FFF8E1',
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 8,
    marginBottom: 4,
    borderLeftWidth: 3,
    borderLeftColor: '#FFC107',
  },
  toolCallLabel: {
    fontSize: 11,
    fontWeight: '600',
    color: '#F57F17',
    marginBottom: 2,
  },
  toolCallContent: {
    fontSize: 13,
    color: '#333333',
  },
  typingContainer: {
    paddingHorizontal: 12,
    paddingBottom: 8,
    flexDirection: 'row',
    justifyContent: 'flex-start',
  },
  typingBubble: {
    backgroundColor: AI_BUBBLE_BG,
    borderRadius: 18,
    borderBottomLeftRadius: 4,
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  typingDots: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
  },
  typingDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: '#999999',
    opacity: 0.4,
  },
  typingDot1: {
    opacity: 0.4,
  },
  typingDot2: {
    opacity: 0.6,
  },
  typingDot3: {
    opacity: 0.8,
  },
  inputBar: {
    flexDirection: 'row',
    alignItems: 'flex-end',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderTopWidth: 1,
    borderTopColor: '#F0F0F0',
    backgroundColor: '#FFFFFF',
  },
  imageButton: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: '#F0F0F0',
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 8,
    marginBottom: 2,
  },
  imageButtonText: {
    fontSize: 20,
    fontWeight: '600',
    color: '#666666',
  },
  textInput: {
    flex: 1,
    minHeight: 36,
    maxHeight: 120,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: '#E0E0E0',
    paddingHorizontal: 14,
    paddingVertical: 8,
    fontSize: 15,
    color: '#333333',
    backgroundColor: '#FAFAFA',
  },
  sendButton: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: BRAND_RED,
    justifyContent: 'center',
    alignItems: 'center',
    marginLeft: 8,
    marginBottom: 2,
  },
  sendButtonDisabled: {
    backgroundColor: '#CCCCCC',
  },
  sendButtonText: {
    fontSize: 18,
    fontWeight: '700',
    color: '#FFFFFF',
  },
});
