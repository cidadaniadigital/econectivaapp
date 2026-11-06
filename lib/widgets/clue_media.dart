import 'package:unisinos_usp_app/widgets/living_clue_layout.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:unisinos_usp_app/models/clue_integration.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:unisinos_usp_app/webclients/econectiva_webclient.dart';

String? youtubeId(String raw) {
  final u = Uri.tryParse(raw);
  if (u == null || u.scheme != 'https' || u.userInfo.isNotEmpty) return null;
  String? id;
  if (u.host == 'youtu.be') {
    id = u.pathSegments.firstOrNull;
  } else if ([
    'youtube.com',
    'www.youtube.com',
    'm.youtube.com',
    'www.youtube-nocookie.com',
  ].contains(u.host)) {
    if (u.path == '/watch') {
      id = u.queryParameters['v'];
    } else if (u.pathSegments.length == 2 &&
        ['embed', 'shorts', 'live'].contains(u.pathSegments.first)) {
      id = u.pathSegments[1];
    }
  }
  return id != null && RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id) ? id : null;
}

String canonicalLink(String raw) {
  final uri = Uri.tryParse(raw);
  if (uri == null) return raw;
  final id = youtubeId(raw);
  return id != null
      ? 'https://www.youtube.com/watch?v=$id'
      : uri.removeFragment().toString();
}

Set<String> documentLinks(QuillController controller) {
  final urls = <String>{};
  final videos = <String>{};
  for (final op in controller.document.toDelta().toJson()) {
    final insert = op['insert'];
    if (insert is Map && insert['video'] is String) {
      videos.add(canonicalLink(insert['video']));
    }
    if (insert is Map && insert.containsKey('onlife')) {
      final block = ClueIntegration.decode(insert['onlife']);
      if (block != null) videos.add(canonicalLink(block.url));
    }
    if (insert is String) {
      for (final match in RegExp(
        r'''https?://[^\s<>"\uFFFC]+''',
      ).allMatches(insert)) {
        urls.add(
          canonicalLink(match.group(0)!.replaceAll(RegExp(r'[.,;!?)]+$'), '')),
        );
      }
    }
    final attr = op['attributes'];
    if (attr is Map && attr['link'] is String) {
      final link = Uri.tryParse(attr['link']);
      if (link != null && ['https', 'http'].contains(link.scheme)) {
        urls.add(canonicalLink(attr['link']));
      }
    }
  }
  return urls.difference(videos);
}

class ClueVideoBuilder extends EmbedBuilder {
  const ClueVideoBuilder({this.hideInEditor = false});
  final bool hideInEditor;
  @override
  String get key => 'video';
  @override
  Widget build(BuildContext context, EmbedContext embedContext) =>
      hideInEditor && !embedContext.readOnly
      ? const SizedBox.shrink()
      : ClueVideo(url: embedContext.node.value.data.toString());
}

/// Videos retain their original Delta anchors for compatibility with saved pistas.
/// Editing uses lightweight cards outside the prose rather than live players.
class ClueVideoCards extends StatelessWidget {
  const ClueVideoCards({super.key, required this.controller});
  final QuillController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      var offset = 0;
      final cards = <Widget>[];
      for (final op in controller.document.toDelta().toJson()) {
        final insert = op['insert'];
        final at = offset;
        offset += insert is String ? insert.length : 1;
        if (insert is! Map || insert['video'] is! String) continue;
        final url = insert['video'] as String;
        cards.add(
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.smart_display_outlined,
                          color: Color(0xFF9CE7DF),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Vídeo do YouTube',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'O vídeo será exibido na visualização da pista.',
                    ),
                    const SizedBox(height: 8),
                    Text(url),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => insertYouTube(
                            context,
                            controller,
                            initialUrl: url,
                            offset: at,
                          ),
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Editar vídeo'),
                        ),
                        TextButton.icon(
                          onPressed: () => controller.replaceText(
                            at,
                            1,
                            '',
                            TextSelection.collapsed(offset: at),
                          ),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Remover vídeo'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: cards,
      );
    },
  );
}

class ClueVideo extends StatefulWidget {
  const ClueVideo({super.key, required this.url});
  final String url;
  @override
  State<ClueVideo> createState() => _ClueVideoState();
}

class _ClueVideoState extends State<ClueVideo> {
  YoutubePlayerController? player;
  @override
  void initState() {
    super.initState();
    final id = youtubeId(widget.url);
    if (id != null &&
        (kIsWeb ||
            defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      player = YoutubePlayerController.fromVideoId(
        videoId: id,
        autoPlay: false,
        params: const YoutubePlayerParams(showFullscreenButton: true),
      );
    }
  }

  @override
  void dispose() {
    player?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: player == null
              ? const AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ColoredBox(
                    color: Color(0xFF111A32),
                    child: Center(
                      child: Text(
                        'Vídeo indisponível neste dispositivo',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                )
              : YoutubePlayer(controller: player!, aspectRatio: 16 / 9),
        ),
        TextButton.icon(
          onPressed: () => launchUrl(
            Uri.parse(widget.url),
            mode: LaunchMode.externalApplication,
          ),
          icon: const Icon(Icons.open_in_new, size: 16),
          label: const Text('Abrir vídeo original no YouTube'),
        ),
      ],
    ),
  );
}

class ClueLinkPreviews extends StatefulWidget {
  const ClueLinkPreviews({super.key, required this.controller, this.clueId});
  final int? clueId;
  final QuillController controller;
  @override
  State<ClueLinkPreviews> createState() => _ClueLinkPreviewsState();
}

class _ClueLinkPreviewsState extends State<ClueLinkPreviews> {
  bool cacheLoaded = false;
  Timer? timer;
  Set<String> links = {};
  final results = <String, Map<String, dynamic>?>{};
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(changed);
    changed();
  }

  void changed() {
    timer?.cancel();
    timer = Timer(const Duration(milliseconds: 450), refresh);
  }

  Future<void> refresh() async {
    if (!mounted) return;
    final current = documentLinks(widget.controller);
    setState(() => links = current);
    if (!cacheLoaded && widget.clueId != null) {
      cacheLoaded = true;
      try {
        final cached = await EconectivaApi().get(
          '/living_clues/${widget.clueId}/link_previews',
        );
        if (!mounted) return;
        for (final entry in cached as List) {
          final data = Map<String, dynamic>.from(entry);
          if ((data['title'] ?? '').toString().isNotEmpty ||
              (data['description'] ?? '').toString().isNotEmpty) {
            results[data['url']] = data;
          }
        }
        setState(() {});
      } catch (_) {
        /* Metadata failures never block the author document. */
      }
    }
    for (final url in current) {
      if (results.containsKey(url)) continue;
      results[url] = null;
      try {
        final data = await EconectivaApi().get('/link_previews', {'url': url});
        if (mounted) {
          setState(() => results[url] = Map<String, dynamic>.from(data));
        }
      } catch (_) {
        if (mounted) {
          setState(() => results[url] = {'url': url, 'failed': true});
        }
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    widget.controller.removeListener(changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: LivingClueLayout.previewMaxWidth,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            for (final url in links)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => launchUrl(
                      Uri.parse(url),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((results[url]?['image'] ?? '')
                              .toString()
                              .isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: Image.network(
                                results[url]!['image'],
                                width: 72,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  results[url]?['title']
                                              ?.toString()
                                              .isNotEmpty ??
                                          false
                                      ? results[url]!['title']
                                      : Uri.parse(url).host,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if ((results[url]?['description'] ?? '')
                                    .toString()
                                    .isNotEmpty)
                                  Text(
                                    results[url]!['description'],
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  results[url] == null
                                      ? 'Carregando prévia…'
                                      : url,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.open_in_new, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

Future<void> insertYouTube(
  BuildContext context,
  QuillController controller, {
  String? initialUrl,
  int? offset,
}) async {
  final url = await showDialog<String>(
    context: context,
    builder: (_) => _YouTubeDialog(initialUrl: initialUrl),
  );
  if (url == null) return;
  // Attach new videos at the end without replacing selected description text.
  final at = (offset ?? controller.document.length - 1).clamp(
    0,
    controller.document.length - 1,
  );
  controller.replaceText(
    at,
    offset == null ? 0 : 1,
    BlockEmbed.video(url),
    TextSelection.collapsed(offset: at + 1),
  );
}

class _YouTubeDialog extends StatefulWidget {
  const _YouTubeDialog({this.initialUrl});
  final String? initialUrl;

  @override
  State<_YouTubeDialog> createState() => _YouTubeDialogState();
}

class _YouTubeDialogState extends State<_YouTubeDialog> {
  late final TextEditingController text = TextEditingController(
    text: widget.initialUrl,
  );
  String? error;

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.initialUrl == null
          ? 'Adicionar vídeo do YouTube'
          : 'Editar vídeo do YouTube',
    ),
    content: SizedBox(
      width: 460,
      child: TextField(
        controller: text,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Endereço do vídeo',
          hintText: 'https://www.youtube.com/watch?v=…',
          errorText: error,
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
          final id = youtubeId(text.text.trim());
          if (id == null) {
            setState(
              () => error = 'Informe um endereço válido de vídeo do YouTube.',
            );
            return;
          }
          Navigator.pop(context, 'https://www.youtube.com/watch?v=$id');
        },
        child: Text(
          widget.initialUrl == null ? 'Adicionar vídeo' : 'Salvar vídeo',
        ),
      ),
    ],
  );
}
