package com.multando.sdk.chat

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Divider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonPrimitive
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

private val BrandRed = Color(0xFFE63946)
private val BrandRedLight = Color(0xFFFDEDEF)
private val AiBubbleBg = Color(0xFFF0F0F0)
private val ToolCallBg = Color(0xFFFFF8E1)
private val ToolCallAccent = Color(0xFFFFC107)

/**
 * A drop-in Jetpack Compose chat screen for the Multando AI assistant.
 *
 * @param chatService The chat service instance (typically from MultandoSDK.client.chat).
 * @param headerTitle Optional title for the header. Defaults to "Multando AI".
 * @param onClose Callback invoked when the user taps the back button.
 */
@Composable
fun MultandoChatScreen(
    chatService: ChatService,
    headerTitle: String = "Multando AI",
    onClose: (() -> Unit)? = null,
) {
    val scope = rememberCoroutineScope()
    val listState = rememberLazyListState()

    var conversation by remember { mutableStateOf<Conversation?>(null) }
    val messages = remember { mutableStateListOf<ChatMessage>() }
    var inputText by remember { mutableStateOf("") }
    var isLoading by remember { mutableStateOf(true) }
    var isSending by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var toolCalls by remember { mutableStateOf<List<JsonObject>>(emptyList()) }

    // Initialize conversation on first composition
    LaunchedEffect(Unit) {
        try {
            val conv = chatService.createConversation()
            conversation = conv
            messages.addAll(conv.messages)
            isLoading = false
        } catch (e: Exception) {
            error = e.message ?: "Failed to start conversation"
            isLoading = false
        }
    }

    // Auto-scroll to bottom when messages change
    LaunchedEffect(messages.size, isSending) {
        if (messages.isNotEmpty()) {
            listState.animateScrollToItem(messages.size - 1)
        }
    }

    Column(modifier = Modifier.fillMaxSize().background(Color.White)) {
        // Header
        ChatHeader(title = headerTitle, onClose = onClose)
        Divider()

        when {
            isLoading -> {
                LoadingContent()
            }
            error != null -> {
                ErrorContent(
                    message = error!!,
                    onRetry = {
                        scope.launch {
                            isLoading = true
                            error = null
                            try {
                                val conv = chatService.createConversation()
                                conversation = conv
                                messages.clear()
                                messages.addAll(conv.messages)
                            } catch (e: Exception) {
                                error = e.message ?: "Failed to start conversation"
                            }
                            isLoading = false
                        }
                    },
                )
            }
            else -> {
                // Messages list
                LazyColumn(
                    state = listState,
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                        .padding(horizontal = 12.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    // Empty state
                    if (messages.isEmpty() && !isSending) {
                        item {
                            EmptyState()
                        }
                    }

                    items(messages, key = { it.id }) { message ->
                        ChatBubble(message = message)
                    }

                    // Typing indicator
                    if (isSending) {
                        item {
                            TypingIndicator()
                        }
                    }
                }

                // Tool call info cards
                if (toolCalls.isNotEmpty()) {
                    ToolCallCards(toolCalls = toolCalls)
                }

                Divider()

                // Input bar
                ChatInputBar(
                    text = inputText,
                    onTextChange = { inputText = it },
                    isSending = isSending,
                    onSend = {
                        val text = inputText.trim()
                        if (text.isNotEmpty() && conversation != null && !isSending) {
                            inputText = ""
                            isSending = true
                            toolCalls = emptyList()

                            // Optimistic user message
                            val optimistic = ChatMessage(
                                id = (System.currentTimeMillis() % Int.MAX_VALUE).toInt(),
                                conversationId = conversation!!.id,
                                direction = "outbound",
                                content = text,
                                messageType = "text",
                                createdAt = currentIsoTime(),
                            )
                            messages.add(optimistic)

                            scope.launch {
                                try {
                                    val request = SendMessageRequest(content = text)
                                    val response = chatService.sendMessage(
                                        conversationId = conversation!!.id,
                                        request = request,
                                    )
                                    messages.add(response.message)
                                    if (response.toolCalls.isNotEmpty()) {
                                        toolCalls = response.toolCalls
                                    }
                                } catch (e: Exception) {
                                    messages.remove(optimistic)
                                    inputText = text
                                }
                                isSending = false
                            }
                        }
                    },
                    onImagePicker = {
                        // Placeholder: integrate with ActivityResultContracts for camera/gallery
                    },
                )
            }
        }
    }
}

@Composable
private fun ChatHeader(title: String, onClose: (() -> Unit)?) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        if (onClose != null) {
            IconButton(onClick = onClose) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "Close",
                )
            }
        } else {
            Spacer(modifier = Modifier.width(48.dp))
        }

        Text(
            text = title,
            modifier = Modifier.weight(1f),
            textAlign = TextAlign.Center,
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
        )

        Spacer(modifier = Modifier.width(48.dp))
    }
}

@Composable
private fun LoadingContent() {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center,
    ) {
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            CircularProgressIndicator(color = BrandRed)
            Spacer(modifier = Modifier.height(12.dp))
            Text(
                text = "Starting conversation...",
                style = MaterialTheme.typography.bodyMedium,
                color = Color.Gray,
            )
        }
    }
}

@Composable
private fun ErrorContent(message: String, onRetry: () -> Unit) {
    Box(
        modifier = Modifier.fillMaxSize(),
        contentAlignment = Alignment.Center,
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier.padding(horizontal = 32.dp),
        ) {
            Text(
                text = "Something went wrong",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = message,
                style = MaterialTheme.typography.bodyMedium,
                color = Color.Gray,
                textAlign = TextAlign.Center,
            )
            Spacer(modifier = Modifier.height(16.dp))
            Button(
                onClick = onRetry,
                colors = ButtonDefaults.buttonColors(containerColor = BrandRed),
            ) {
                Text("Retry")
            }
        }
    }
}

@Composable
private fun EmptyState() {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 48.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(
            text = "Welcome to Multando AI",
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.Bold,
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "Ask me anything about traffic violations, reports, or your account.",
            style = MaterialTheme.typography.bodyMedium,
            color = Color.Gray,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 24.dp),
        )
    }
}

@Composable
private fun ChatBubble(message: ChatMessage) {
    val isUser = message.isOutbound
    val screenWidth = LocalConfiguration.current.screenWidthDp.dp

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = if (isUser) Arrangement.End else Arrangement.Start,
    ) {
        Surface(
            modifier = Modifier.widthIn(max = screenWidth * 0.78f),
            shape = RoundedCornerShape(
                topStart = 18.dp,
                topEnd = 18.dp,
                bottomStart = if (isUser) 18.dp else 4.dp,
                bottomEnd = if (isUser) 4.dp else 18.dp,
            ),
            color = if (isUser) BrandRed else AiBubbleBg,
        ) {
            Column(modifier = Modifier.padding(horizontal = 14.dp, vertical = 10.dp)) {
                Text(
                    text = message.content ?: "",
                    fontSize = 15.sp,
                    lineHeight = 21.sp,
                    color = if (isUser) Color.White else Color(0xFF333333),
                )
                Spacer(modifier = Modifier.height(4.dp))
                Text(
                    text = formatTime(message.createdAt),
                    fontSize = 11.sp,
                    color = if (isUser) Color.White.copy(alpha = 0.7f) else Color.Gray,
                    modifier = Modifier.align(if (isUser) Alignment.End else Alignment.Start),
                )
            }
        }
    }
}

@Composable
private fun TypingIndicator() {
    Row(modifier = Modifier.fillMaxWidth()) {
        Surface(
            shape = RoundedCornerShape(18.dp, 18.dp, 18.dp, 4.dp),
            color = AiBubbleBg,
        ) {
            Row(
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp),
                horizontalArrangement = Arrangement.spacedBy(4.dp),
            ) {
                repeat(3) { index ->
                    Surface(
                        modifier = Modifier.size(8.dp),
                        shape = CircleShape,
                        color = Color.Gray.copy(alpha = 0.4f + index * 0.2f),
                    ) {}
                }
            }
        }
    }
}

@Composable
private fun ToolCallCards(toolCalls: List<JsonObject>) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 4.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        toolCalls.forEach { tc ->
            Surface(
                shape = RoundedCornerShape(10.dp),
                color = ToolCallBg,
            ) {
                Row(modifier = Modifier.padding(start = 0.dp)) {
                    Surface(
                        modifier = Modifier
                            .width(3.dp)
                            .height(40.dp),
                        color = ToolCallAccent,
                    ) {}
                    Column(
                        modifier = Modifier.padding(
                            start = 10.dp,
                            end = 12.dp,
                            top = 8.dp,
                            bottom = 8.dp,
                        ),
                    ) {
                        Text(
                            text = "Action performed",
                            fontSize = 11.sp,
                            fontWeight = FontWeight.SemiBold,
                            color = Color(0xFFF57F17),
                        )
                        Text(
                            text = tc["name"]?.jsonPrimitive?.content
                                ?: tc["type"]?.jsonPrimitive?.content
                                ?: "Tool call",
                            fontSize = 13.sp,
                            color = Color(0xFF333333),
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun ChatInputBar(
    text: String,
    onTextChange: (String) -> Unit,
    isSending: Boolean,
    onSend: () -> Unit,
    onImagePicker: () -> Unit,
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 12.dp, vertical = 8.dp),
        verticalAlignment = Alignment.Bottom,
    ) {
        // Image picker button
        IconButton(
            onClick = onImagePicker,
            modifier = Modifier.size(40.dp),
        ) {
            Icon(
                imageVector = Icons.Default.Add,
                contentDescription = "Attach image",
                tint = Color.Gray,
            )
        }

        // Text input
        OutlinedTextField(
            value = text,
            onValueChange = onTextChange,
            modifier = Modifier
                .weight(1f)
                .padding(horizontal = 4.dp),
            placeholder = { Text("Type a message...") },
            enabled = !isSending,
            maxLines = 5,
            shape = RoundedCornerShape(20.dp),
        )

        // Send button
        IconButton(
            onClick = onSend,
            enabled = text.trim().isNotEmpty() && !isSending,
            modifier = Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(
                    if (text.trim().isNotEmpty() && !isSending) BrandRed
                    else Color.Gray.copy(alpha = 0.3f)
                ),
        ) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.Send,
                contentDescription = "Send",
                tint = Color.White,
                modifier = Modifier.size(20.dp),
            )
        }
    }
}

private fun formatTime(isoString: String): String {
    return try {
        val parser = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US)
        parser.timeZone = TimeZone.getTimeZone("UTC")
        val date = parser.parse(isoString) ?: return ""
        val formatter = SimpleDateFormat("HH:mm", Locale.getDefault())
        formatter.format(date)
    } catch (e: Exception) {
        ""
    }
}

private fun currentIsoTime(): String {
    val formatter = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
    formatter.timeZone = TimeZone.getTimeZone("UTC")
    return formatter.format(Date())
}
