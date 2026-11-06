import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/services/iarete_voice/voice_conversation.dart';
import 'package:unisinos_usp_app/widgets/iarete_voice_controls.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:unisinos_usp_app/utils/assistant_link.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/ai_assistant/ai_assistant_controller.dart';
import 'package:unisinos_usp_app/models/ai_assistant_message_model.dart';

class AiAssistantPanel extends StatefulWidget {
  const AiAssistantPanel({super.key});

  @override
  State<AiAssistantPanel> createState() => _AiAssistantPanelState();
}

class _AiAssistantPanelState extends State<AiAssistantPanel>
    with WidgetsBindingObserver {
  late final VoiceConversation _voice;
  final AiAssistantController _controller = Get.find<AiAssistantController>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  late final Worker _worker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _voice = VoiceConversation(sendText: (text) async {
      final old = _controller.messages.toList();
      await _controller.sendMessage(text);
      return _controller.messages
          .where((message) => !message.isUser && !old.contains(message))
          .lastOrNull;
    });
    _voice.restore();
    _worker = ever<List<AiAssistantMessageModel>>(
      _controller.messages,
      (_) => _scrollToBottom(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePanel();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _voice.dispose();
    _worker.dispose();
    _textController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _voice.foreground();
    } else {
      _voice.background();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset + 12),
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 680),
            decoration: BoxDecoration(
              color: const Color(0xFF0F141B),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 8, 12),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.white),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Assistente do app',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Obx(() {
                    if (_controller.isLoadingHistory.value &&
                        _controller.messages.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (_controller.messages.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            _controller.errorMessage.value ??
                                'Faça uma pergunta ao assistente contextual do app.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.76),
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _controller.messages.length,
                      itemBuilder: (_, index) => _MessageBubble(
                          message: _controller.messages[index], voice: _voice),
                    );
                  }),
                ),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Obx(() => IareteVoiceControls(
                        voice: _voice,
                        sending: _controller.isSending.value,
                        onUseTranscript: (text) {
                          _textController.text = text;
                          _inputFocusNode.requestFocus();
                        }))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Focus(
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent &&
                                event.logicalKey == LogicalKeyboardKey.enter &&
                                !HardwareKeyboard.instance.isShiftPressed) {
                              _submit();
                              return KeyEventResult.handled;
                            }
                            return KeyEventResult.ignored;
                          },
                          child: TextField(
                            focusNode: _inputFocusNode,
                            controller: _textController,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.send,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Pergunte algo sobre a tela atual...',
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.08),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) => _submit(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Obx(() {
                        return FilledButton(
                          onPressed:
                              _controller.isSending.value ? null : _submit,
                          child: Text(
                            _controller.isSending.value ? '...' : 'Enviar',
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    final String value = _textController.text;
    _textController.clear();
    _controller.sendMessage(value);
  }

  Future<void> _initializePanel() async {
    await _controller.ensureHistoryLoaded();
    _scrollToBottom(animated: false);
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final double offset = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
        return;
      }
      _scrollController.jumpTo(offset);
    });
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.voice});
  final VoiceConversation voice;

  final AiAssistantMessageModel message;

  @override
  Widget build(BuildContext context) {
    final bool isUser = message.isUser;
    final Color background =
        isUser ? const Color(0xFF2563EB) : Colors.white.withValues(alpha: 0.1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isUser)
                      Text(message.content,
                          style: const TextStyle(
                              color: Colors.white, height: 1.35))
                    else
                      MarkdownBody(
                        data: message.content,
                        styleSheet:
                            MarkdownStyleSheet.fromTheme(Theme.of(context))
                                .copyWith(
                          p: const TextStyle(color: Colors.white, height: 1.35),
                          a: const TextStyle(
                              color: Color(0xFF43D4C2),
                              decoration: TextDecoration.underline),
                          code: const TextStyle(
                              color: Colors.white, fontFamily: 'monospace'),
                          listBullet: const TextStyle(color: Colors.white),
                        ),
                        onTapLink: (_, href, __) =>
                            openAssistantLink(href, context),
                      ),
                    if (!isUser && message.id != null)
                      TextButton.icon(
                          onPressed: () =>
                              voice.speak(message.id!, manual: true),
                          icon: const Icon(Icons.volume_up_outlined, size: 16),
                          label: const Text('Ouvir resposta / parar')),
                    const SizedBox(height: 6),
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final String hour = dateTime.hour.toString().padLeft(2, '0');
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
