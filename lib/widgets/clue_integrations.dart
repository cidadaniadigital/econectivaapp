import 'package:unisinos_usp_app/widgets/clue_node_integration.dart';
import 'package:unisinos_usp_app/widgets/clue_agent_integration.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/ai_assistant_screen_context.dart';
import 'package:unisinos_usp_app/services/ai_assistant_context_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:unisinos_usp_app/models/clue_integration.dart';
import 'package:unisinos_usp_app/widgets/integration_frame.dart';
import 'package:unisinos_usp_app/widgets/clue_media.dart';
import 'package:unisinos_usp_app/themes/app_theme.dart';

IconData integrationIcon(String provider) => switch (provider) {
  'node' => Icons.hub_outlined,
  'agent' => Icons.psychology_outlined,
  'youtube' => Icons.smart_display_outlined,
  'genially' => Icons.auto_awesome_outlined,
  'padlet' => Icons.dashboard_outlined,
  'framevr' => Icons.view_in_ar_outlined,
  _ => Icons.extension_outlined,
};

class ClueIntegrationCards extends StatelessWidget {
  const ClueIntegrationCards({super.key, required this.controller});
  final QuillController controller;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 850
          ? 3
          : constraints.maxWidth >= 520
          ? 2
          : 1;
      final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
      final providers = [
        'youtube',
        'agent',
        'node',
        ...ClueIntegration.providers,
      ];
      final margin =
          Theme.of(context).cardTheme.margin ?? const EdgeInsets.all(4);
      final textWidth = (width - margin.horizontal - 86).clamp(
        1.0,
        double.infinity,
      );
      final base =
          Theme.of(context).textTheme.bodyMedium ??
          const TextStyle(fontSize: 14);
      double measure(String text, TextStyle style) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: textWidth);
        final height = painter.height;
        painter.dispose();
        return height;
      }

      final cardHeight = providers
          .map(
            (provider) =>
                32 +
                margin.vertical +
                6 +
                measure(
                  provider == 'youtube'
                      ? 'YouTube'
                      : ClueIntegration(provider: provider, url: '').name,
                  base.copyWith(fontWeight: FontWeight.w700, fontSize: 16),
                ) +
                measure(
                  provider == 'youtube'
                      ? 'Adicione um vídeo à pista e compartilhe novas perspectivas.'
                      : ClueIntegration.explanation(provider),
                  base.copyWith(height: 1.4),
                ),
          )
          .reduce((a, b) => a > b ? a : b);

      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: providers.map((provider) {
          final name = provider == 'youtube'
              ? 'YouTube'
              : ClueIntegration(provider: provider, url: '').name;
          return SizedBox(
            width: width,
            height: cardHeight,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => provider == 'youtube'
                    ? insertYouTube(context, controller)
                    : editClueIntegration(
                        context,
                        controller,
                        provider: provider,
                      ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        integrationIcon(provider),
                        color: const Color(0xFF9CE7DF),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              provider == 'youtube'
                                  ? 'Adicione um vídeo à pista e compartilhe novas perspectivas.'
                                  : ClueIntegration.explanation(provider),
                              style: const TextStyle(height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.add, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    },
  );
}

Future<void> editClueIntegration(
  BuildContext context,
  QuillController controller, {
  required String provider,
  ClueIntegration? initial,
  int? offset,
}) async {
  if (provider == 'node') {
    return editClueNodeIntegration(
      context,
      controller,
      initial: initial,
      offset: offset,
    );
  }
  if (provider == 'agent') {
    await editClueAgentIntegration(
      context,
      controller,
      initial: initial,
      offset: offset,
    );
    return;
  }
  if (!ClueIntegration.providers.contains(provider)) return;
  final selection = controller.selection;
  final url = TextEditingController(text: initial?.url);
  final title = TextEditingController(text: initial?.title);
  final instructions = TextEditingController(text: initial?.instructions);
  final form = GlobalKey<FormState>();
  final name = ClueIntegration(provider: provider, url: '').name;
  final result = await showDialog<ClueIntegration>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('${initial == null ? 'Adicionar' : 'Editar'} $name'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ClueIntegration.explanation(provider)),
                const SizedBox(height: 18),
                TextFormField(
                  controller: url,
                  autofocus: true,
                  maxLength: 2000,
                  decoration: InputDecoration(
                    labelText: 'Link de visualização',
                    hintText: provider == 'genially'
                        ? 'https://view.genially.com/…'
                        : null,
                  ),
                  validator: (value) => ClueIntegration.validateURL(
                    provider,
                    value?.trim() ?? '',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: title,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    labelText: 'Título (opcional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: instructions,
                  maxLength: 3000,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Instruções de acesso (opcional)',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            if (form.currentState?.validate() != true) return;
            Navigator.pop(
              context,
              ClueIntegration(
                provider: provider,
                url: url.text.trim(),
                title: title.text.trim(),
                instructions: instructions.text.trim(),
              ),
            );
          },
          child: Text(
            initial == null ? 'Inserir integração' : 'Salvar integração',
          ),
        ),
      ],
    ),
  );
  url.dispose();
  title.dispose();
  instructions.dispose();
  if (result == null) return;
  final at = (offset ?? selection.start).clamp(
    0,
    controller.document.length - 1,
  );
  final length = offset != null
      ? 1
      : selection.isValid
      ? selection.end - selection.start
      : 0;
  controller.replaceText(
    at,
    length,
    BlockEmbed('onlife', result.encode()),
    TextSelection.collapsed(offset: at + 1),
  );
}

class ClueIntegrationBuilder extends EmbedBuilder {
  const ClueIntegrationBuilder({
    this.hideAgentsInEditor = false,
    this.hideNodesInEditor = false,
  });
  final bool hideAgentsInEditor;
  final bool hideNodesInEditor;
  @override
  String get key => 'onlife';
  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final block = ClueIntegration.decode(embedContext.node.value.data);
    if (block == null ||
        !block.supported ||
        ClueIntegration.validateURL(block.provider, block.url) != null)
      return const _UnavailableIntegration();
    final editing = !embedContext.readOnly;
    if (block.provider == 'agent') {
      if (editing && hideAgentsInEditor) return const SizedBox.shrink();
      return ClueAgentIntegrationCard(
        block: block,
        editing: editing,
        onEdit: editing
            ? () => editClueAgentIntegration(
                context,
                embedContext.controller,
                initial: block,
                offset: embedContext.node.documentOffset,
              )
            : null,
        onRemove: editing
            ? () => embedContext.controller.replaceText(
                embedContext.node.documentOffset,
                1,
                '',
                TextSelection.collapsed(
                  offset: embedContext.node.documentOffset,
                ),
              )
            : null,
      );
    }
    if (block.provider == 'node') {
      if (editing && hideNodesInEditor) return const SizedBox.shrink();
      return ClueNodeIntegrationCard(
        block: block,
        editing: editing,
        onEdit: editing
            ? () => editClueNodeIntegration(
                context,
                embedContext.controller,
                initial: block,
                offset: embedContext.node.documentOffset,
              )
            : null,
        onRemove: editing
            ? () => embedContext.controller.replaceText(
                embedContext.node.documentOffset,
                1,
                '',
                TextSelection.collapsed(
                  offset: embedContext.node.documentOffset,
                ),
              )
            : null,
      );
    }
    return ClueIntegrationView(
      block: block,
      onEdit: editing
          ? () => editClueIntegration(
              context,
              embedContext.controller,
              provider: block.provider,
              initial: block,
              offset: embedContext.node.documentOffset,
            )
          : null,
      onRemove: editing
          ? () => embedContext.controller.replaceText(
              embedContext.node.documentOffset,
              1,
              '',
              TextSelection.collapsed(offset: embedContext.node.documentOffset),
            )
          : null,
      editing: editing,
    );
  }
}

class UnknownClueEmbedBuilder extends EmbedBuilder {
  const UnknownClueEmbedBuilder();
  @override
  String get key => 'unsupported';
  @override
  Widget build(BuildContext context, EmbedContext embedContext) =>
      const _UnavailableIntegration();
}

class _UnavailableIntegration extends StatelessWidget {
  const _UnavailableIntegration();
  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(18),
      child: Text(
        'Conteúdo de outra versão preservado no documento. Sua visualização não está disponível nesta versão.',
      ),
    ),
  );
}

class ClueIntegrationView extends StatelessWidget {
  const ClueIntegrationView({
    super.key,
    required this.block,
    this.editing = false,
    this.onEdit,
    this.onRemove,
  });
  final ClueIntegration block;
  final bool editing;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  Future<void> _open(BuildContext context) async {
    try {
      if (await launchUrl(
        Uri.parse(block.url),
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      ))
        return;
    } catch (_) {
      /* Keep the explanatory error below available. */
    }
    if (context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível abrir. Confira o endereço e as permissões do provedor.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  integrationIcon(block.provider),
                  color: const Color(0xFF9CE7DF),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    block.title.isEmpty ? block.name : block.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(block.name, style: Theme.of(context).textTheme.labelMedium),
            if (block.instructions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(block.instructions),
              ),
            if (editing) ...[
              const SizedBox(height: 10),
              Text(block.url),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar integração'),
                  ),
                  TextButton.icon(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remover integração'),
                  ),
                ],
              ),
            ] else ...[
              if (block.inline && block.embedURI != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: LayoutBuilder(
                    builder: (context, size) => SizedBox(
                      height: block.provider == 'padlet'
                          ? 420
                          : (size.maxWidth * 9 / 16).clamp(220.0, 440.0),
                      child: IntegrationFrame(
                        key: ValueKey(block.url),
                        uri: block.embedURI!,
                        title: block.title.isEmpty ? block.name : block.title,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  if (block.embedURI != null)
                    OutlinedButton.icon(
                      onPressed: () {
                        final origin =
                            Get.isRegistered<AiAssistantContextService>()
                            ? Get.find<AiAssistantContextService>()
                                  .resolveCurrentContext()
                            : null;
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ClueIntegrationRoom(
                              block: block,
                              originContext: origin,
                            ),
                          ),
                        );
                      },
                      icon: Icon(
                        block.inline
                            ? Icons.fullscreen
                            : Icons.view_in_ar_outlined,
                      ),
                      label: Text(
                        block.inline
                            ? 'Ampliar conteúdo'
                            : 'Entrar no ambiente',
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () => _open(context),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Abrir na origem'),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'O acesso e a participação seguem as regras do provedor. Se não carregar aqui, abra na origem.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

/// Full reading/entry surface. A 3D world must not stay alive behind another
/// application route or after handing the user to its external site.
class ClueIntegrationRoom extends StatefulWidget {
  const ClueIntegrationRoom({
    super.key,
    required this.block,
    this.originContext,
  });
  final ClueIntegration block;
  final AiAssistantScreenContext? originContext;

  @override
  State<ClueIntegrationRoom> createState() => _ClueIntegrationRoomState();
}

class _ClueIntegrationRoomState extends State<ClueIntegrationRoom>
    with WidgetsBindingObserver {
  bool _requiresReentry = false;
  bool get _isWorld => widget.block.provider == 'framevr';
  late final String _contextRoute = Get.currentRoute.isNotEmpty
      ? Get.currentRoute
      : widget.originContext?.route ??
            (Get.isRegistered<AiAssistantContextService>()
                ? Get.find<AiAssistantContextService>().currentRoute.value
                : '');
  late final AiAssistantContextProvider
  _contextProvider = () => AiAssistantScreenContext(
    screenName: '${widget.block.name} — conteúdo da pista',
    route: _contextRoute,
    stage: _requiresReentry
        ? 'janela do ambiente encerrada'
        : 'visualização de conteúdo externo',
    goal:
        'ajudar com os controles e com a pista de origem, respeitando os limites do conteúdo incorporado',
    visibleFields: [
      'voltar à pista',
      'abrir na origem',
      if (_requiresReentry) 'entrar novamente',
    ],
    filledFields: {
      'provedor': widget.block.name,
      'título': widget.block.title,
      'estado da janela': _requiresReentry
          ? 'aguardando reentrada'
          : 'incorporação exibida',
    },
    notes: const [
      'A assistente não observa o mundo, as pessoas, as mensagens, a câmera ou o áudio do provedor.',
      'A janela exibida não comprova conexão ou ingresso no ambiente externo; não afirmar isso sem informação da pessoa.',
    ],
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The navigator disables tickers when an opaque route covers this room.
    // This rebuild removes the iframe rather than only hiding its rendering.
    if (_isWorld && !TickerMode.of(context)) _requiresReentry = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isWorld &&
        !_requiresReentry &&
        (state == AppLifecycleState.hidden ||
            state == AppLifecycleState.paused ||
            state == AppLifecycleState.detached)) {
      setState(() => _requiresReentry = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (Get.isRegistered<AiAssistantContextService>()) {
      Get.find<AiAssistantContextService>().unregisterProvider(
        _contextRoute,
        _contextProvider,
      );
    }
    super.dispose();
  }

  Future<void> _openOrigin() async {
    // Prevent two simultaneous world instances when the external site opens.
    if (_isWorld) setState(() => _requiresReentry = true);
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(widget.block.url),
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
    } catch (_) {
      // The explicit reentry control remains available if the popup is blocked.
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível abrir a origem. Você pode tentar novamente.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final block = widget.block;
    if (Get.isRegistered<AiAssistantContextService>()) {
      final service = Get.find<AiAssistantContextService>();
      service.registerProvider(_contextRoute, _contextProvider);
      final route = ModalRoute.of(context);
      if (route?.isCurrent == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && route?.isCurrent == true)
            service.setCurrentRoute(_contextRoute);
        });
      }
    }
    return Theme(
      data: AppTheme.theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            block.title.isEmpty ? block.name : block.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          actions: [
            TextButton.icon(
              onPressed: _openOrigin,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir na origem'),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _isWorld
                    ? 'Você está entrando em um ambiente externo. Câmera e microfone serão solicitados pelo provedor quando necessários. Ao voltar ou mudar de tela, o ambiente será encerrado.'
                    : 'As permissões deste conteúdo são controladas pelo provedor.',
              ),
            ),
            Expanded(
              child: _requiresReentry
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.view_in_ar_outlined, size: 42),
                            const SizedBox(height: 16),
                            const Text(
                              'Ambiente encerrado',
                              style: TextStyle(fontSize: 20),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Entre novamente quando quiser continuar a exploração.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () =>
                                  setState(() => _requiresReentry = false),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Entrar novamente'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : IntegrationFrame(
                      uri: block.embedURI!,
                      title: block.name,
                      media: _isWorld,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
