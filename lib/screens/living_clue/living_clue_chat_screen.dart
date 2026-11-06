import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:unisinos_usp_app/models/ai_assistant_screen_context.dart';
import 'package:unisinos_usp_app/controllers/living_clue/living_clue_chat_controller.dart';
import 'package:unisinos_usp_app/models/living_clue_chat_message_model.dart';
import 'package:unisinos_usp_app/services/ai_assistant_context_service.dart';
import 'package:unisinos_usp_app/widgets/safe_back_button.dart';
import 'package:unisinos_usp_app/widgets/starfield_background.dart';
import 'package:unisinos_usp_app/utils/assistant_link.dart';

class LivingClueChatScreen extends StatefulWidget {
  const LivingClueChatScreen({super.key});

  @override
  State<LivingClueChatScreen> createState() => _LivingClueChatScreenState();
}

class _LivingClueChatScreenState extends State<LivingClueChatScreen> {
  final LivingClueChatController _controller =
      Get.find<LivingClueChatController>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final Worker _messagesWorker;
  late final Worker _initialLoadWorker;
  bool _initialBottomDone = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _messagesWorker = ever<int>(_controller.messagesVersion, (_) {
      if (!mounted) return;
      if (_controller.lastMutationType == 'prepend') return;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });
    _initialLoadWorker =
        ever<bool>(_controller.initialLoadFinished, (finished) {
      if (!finished || _initialBottomDone || !mounted) return;
      _initialBottomDone = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });
  }

  @override
  void dispose() {
    _messagesWorker.dispose();
    _initialLoadWorker.dispose();
    _textController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Get.find<AiAssistantContextService>().registerProvider(
      '/living_clues/:id/chat',
      _buildAiContext,
    );
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        leading: const SafeBackButton(),
        title:
            Obx(() => Text(_controller.livingClue.value?.name ?? 'Pista viva')),
        actions: [
          IconButton(
            tooltip: 'Limpar conversa',
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmClearMessages,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: StarfieldBackground()),
          Column(
            children: [
              Obx(() {
                final model = _controller.livingClue.value;
                if (model == null) return const SizedBox.shrink();
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  color: Colors.black.withValues(alpha: 0.35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Converse com esta pista viva a partir das leituras mais recentes.',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                );
              }),
              Expanded(
                child: Obx(() {
                  if (_controller.isLoading.value &&
                      _controller.messages.isEmpty) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.white));
                  }

                  if (_controller.livingClue.value == null &&
                      _controller.livingClueId == null) {
                    return const Center(
                        child: Text('Pista viva não informada.',
                            style: TextStyle(color: Colors.white)));
                  }

                  if (_controller.messages.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Faça uma pergunta para esta pista viva.',
                          style: TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    itemCount: _controller.messages.length +
                        (_controller.isLoadingMore.value ? 1 : 0),
                    itemBuilder: (_, index) {
                      if (_controller.isLoadingMore.value && index == 0) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white)),
                        );
                      }

                      final int messageIndex =
                          _controller.isLoadingMore.value ? index - 1 : index;
                      final LivingClueChatMessageModel message =
                          _controller.messages[messageIndex];
                      return _buildMessageBubble(message, theme);
                    },
                  );
                }),
              ),
              _buildComposer(theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
      LivingClueChatMessageModel message, ThemeData theme) {
    final bool isUser = message.isUser;
    final Color bubbleColor =
        isUser ? theme.colorScheme.primary : theme.colorScheme.surface;
    final Color textColor =
        isUser ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface;

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
              backgroundColor: Colors.green.shade100,
              child: const Icon(Icons.forest, color: Colors.green, size: 18),
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
                    color: Colors.black.withValues(alpha: 0.08),
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
                      DateFormat('dd/MM HH:mm')
                          .format(message.timestamp.toLocal()),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: textColor.withValues(alpha: 0.8),
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
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.15),
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
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
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
                  cursorColor: theme.colorScheme.primary,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  decoration: InputDecoration.collapsed(
                    hintText: 'Pergunte algo...',
                    hintStyle:
                        TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              Obx(() {
                final bool sending = _controller.isSending.value;
                return SizedBox(
                  width: 44,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: sending ? null : _handleSend,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                    ),
                    child: sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSend() async {
    final String text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    await _controller.sendMessage(text);
  }

  Future<void> _confirmClearMessages() async {
    final bool? confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Limpar conversa'),
        content: const Text(
            'Deseja apagar o histórico desta conversa com a pista viva?'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Apagar')),
        ],
      ),
    );
    if (confirmed ?? false) {
      await _controller.clearMessages();
    }
  }

  Future<void> _onScroll() async {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels > 80) return;
    if (_controller.isLoadingMore.value || !_controller.hasMore.value) return;

    final double previousMaxScrollExtent =
        _scrollController.position.maxScrollExtent;
    final double previousPixels = _scrollController.position.pixels;
    final bool loaded = await _controller.loadOlderMessages();
    if (!loaded || !_scrollController.hasClients) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final double newMaxScrollExtent =
          _scrollController.position.maxScrollExtent;
      final double delta = newMaxScrollExtent - previousMaxScrollExtent;
      _scrollController.jumpTo(previousPixels + delta);
    });
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  AiAssistantScreenContext _buildAiContext() {
    final clue = _controller.livingClue.value;
    return AiAssistantScreenContext(
      screenName: 'Chat da pista viva',
      route: '/living_clues/:id/chat',
      stage: 'conversa contextual',
      goal: 'interagir com a pista viva e obter respostas contextualizadas',
      visibleFields: const <String>[
        'mensagens',
        'campo de pergunta',
        'ação de envio',
      ],
      filledFields: <String, String>{
        'pista_id': _controller.livingClueId?.toString() ?? '-',
        'pista_nome': clue?.name ?? '-',
        'total_mensagens': _controller.messages.length.toString(),
      },
      notes: const <String>[
        'A conversa aceita texto livre e renderiza respostas em markdown.',
      ],
    );
  }
}
