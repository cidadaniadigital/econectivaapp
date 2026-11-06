import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/chat/chat_controller.dart';
import 'package:unisinos_usp_app/models/chat_message_model.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';
import 'package:unisinos_usp_app/utils/assistant_link.dart';
import 'package:widgets_spo/widgets_spo.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatController _controller = Get.find<ChatController>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final Worker _messageWorker;

  @override
  void initState() {
    super.initState();
    _messageWorker = ever<List<ChatMessageModel>>(
      _controller.messages,
      (_) => _scrollToBottom(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _messageWorker.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        leading: const SafeBackButton(),
        title: const Text('Assistente UNIUSP'),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Converse com o assistente',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Explore conteúdos e conexões. Confira as referências e os limites das respostas.',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Obx(
                  () {
                    final messages = _controller.messages;
                    if (_controller.isLoadingHistory.value &&
                        messages.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (messages.isEmpty) {
                      return Center(
                        child: Text(
                          'Comece uma conversa com o assistente.',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                      itemCount: messages.length,
                      itemBuilder: (_, index) =>
                          _buildMessageBubble(messages[index], theme),
                    );
                  },
                ),
              ),
              _buildComposer(theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message, ThemeData theme) {
    final bool isUser = message.isUser;
    final Color bubbleColor =
        isUser ? theme.colorScheme.primary : theme.colorScheme.surface;
    final Color textColor =
        isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

    final String formattedTime = _formatTime(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.15),
              child: Icon(Icons.auto_awesome,
                  color: theme.colorScheme.primary, size: 18),
            ),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMarkdownMessage(theme, message.text, textColor),
                    const SizedBox(height: 6),
                    Text(
                      formattedTime,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: textColor.withOpacity(0.8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
              child: Icon(Icons.person, color: theme.colorScheme.primary),
            ),
        ],
      ),
    );
  }

  Widget _buildMarkdownMessage(ThemeData theme, String text, Color textColor) {
    final baseStyle =
        theme.textTheme.bodyMedium?.copyWith(color: textColor, height: 1.35);
    return MarkdownBody(
      data: text,
      selectable: false,
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: baseStyle,
        a: baseStyle?.copyWith(
          color: textColor == theme.colorScheme.onPrimary
              ? textColor
              : theme.colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
        code: TextStyle(
          color: textColor,
          backgroundColor: Colors.black.withValues(alpha: 0.08),
          fontFamily: 'monospace',
        ),
        codeblockDecoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        blockquote: baseStyle,
      ),
      onTapLink: (_, href, __) => openAssistantLink(href, context),
    );
  }

  Widget _buildComposer(ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  minLines: 1,
                  maxLines: 4,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  onSubmitted: (_) => _handleSend(),
                  decoration: InputDecoration.collapsed(
                    hintText: 'Digite sua mensagem...',
                    hintStyle:
                        TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              Insets.small.width,
              Obx(
                () {
                  final sending = _controller.isSending.value;
                  return SizedBox(
                    height: 44,
                    width: 44,
                    child: ElevatedButton(
                      onPressed: sending ? null : _handleSend,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                      ),
                      child: sending
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.2),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSend() {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    _controller.sendMessage(text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 72,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatTime(DateTime timestamp) {
    final time = TimeOfDay.fromDateTime(timestamp);
    final twoDigits = (int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(time.hour)}:${twoDigits(time.minute)}';
  }
}
