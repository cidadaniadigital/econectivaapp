import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/models/file_model.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/services/collection_service.dart';
import 'package:unisinos_usp_app/webclients/file_webclient.dart';
import 'package:unisinos_usp_app/widgets/clue_cover_art.dart';

class ClueCover extends StatefulWidget {
  const ClueCover(
      {super.key, required this.clue, this.height = 240, this.collectionItems});
  final LivingClueModel clue;
  final double height;

  /// Already-loaded items avoid another collection request on its detail page.
  final List<LivingClueModel>? collectionItems;

  static const automaticDisabledKey = 'capa_automatica_desativada';

  static List<FileModel> imageFiles(LivingClueModel clue) => clue.files
      .where((file) =>
          file.livingClueId == clue.id &&
          !file.isDeleted &&
          {'jpg', 'jpeg', 'png', 'webp', 'gif'}
              .contains(file.extension.toLowerCase().replaceFirst('.', '')))
      .toList()
    ..sort((a, b) => a.id.compareTo(b.id));

  static bool hasOwnImage(LivingClueModel clue) =>
      int.tryParse('${clue.metadata?['imagem_capa_arquivo_id']}') != null ||
      imageUri(clue.imageUrl) != null ||
      (clue.metadata?[automaticDisabledKey] != true &&
          (imageFiles(clue).isNotEmpty || videoThumbnail(clue) != null));

  static Uri? imageUri(String? value) {
    final uri = Uri.tryParse(value ?? '');
    return uri != null &&
            {'http', 'https'}.contains(uri.scheme) &&
            uri.host.isNotEmpty
        ? uri
        : null;
  }

  static Uri? videoThumbnail(LivingClueModel clue) {
    for (final key in [
      'recurso_original',
      'conteudo_url',
      'url',
      'source_url'
    ]) {
      final source = imageUri(clue.metadata?[key]?.toString());
      if (source == null) continue;
      final host = source.host.toLowerCase();
      String? id;
      if (host == 'youtu.be') {
        id = source.pathSegments.firstOrNull;
      } else if (['youtube.com', 'www.youtube.com', 'm.youtube.com']
          .contains(host)) {
        id = source.queryParameters['v'];
        if (id == null &&
            source.pathSegments.length == 2 &&
            ['embed', 'shorts', 'live'].contains(source.pathSegments.first)) {
          id = source.pathSegments[1];
        }
      }
      if (id != null && RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id)) {
        return Uri.https('i.ytimg.com', '/vi/$id/hqdefault.jpg');
      }
    }
    return null;
  }

  @override
  State<ClueCover> createState() => _ClueCoverState();
}

class _ClueCoverState extends State<ClueCover> {
  late Future<List<String>> _urls;
  bool _retried = false;
  late String _signature;
  String _coverSignature() => jsonEncode([
        widget.clue.toJson(),
        widget.clue.files.map((file) => [file.id, file.livingClueId]).toList(),
        widget.collectionItems
            ?.map((item) =>
                [item.toJson(), item.files.map((file) => file.id).toList()])
            .toList()
      ]);
  @override
  void initState() {
    super.initState();
    _signature = _coverSignature();
    _urls = _resolve();
  }

  @override
  void didUpdateWidget(ClueCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    final signature = _coverSignature();
    if (signature != _signature) {
      _signature = signature;
      _retried = false;
      _urls = _resolve();
    }
  }

  Future<String?> _ownImage(LivingClueModel clue) async {
    final client = FileWebclient();
    final id = int.tryParse('${clue.metadata?['imagem_capa_arquivo_id']}');
    if (id != null && id > 0) {
      final files = await client.fetch(livingClueId: clue.id);
      if (!files.any((file) => file.id == id && file.livingClueId == clue.id)) {
        return null;
      }
      return (await client.access(id)).toString();
    }
    final legacy = ClueCover.imageUri(clue.imageUrl);
    if (legacy != null) return legacy.toString();
    if (clue.metadata?[ClueCover.automaticDisabledKey] == true) return null;
    for (final file in ClueCover.imageFiles(clue)) {
      try {
        return (await client.access(file.id)).toString();
      } catch (_) {
        // One unavailable attachment must not prevent another from being used.
      }
    }
    return ClueCover.videoThumbnail(clue)?.toString();
  }

  Future<List<String>> _resolve() async {
    try {
      final own = await _ownImage(widget.clue);
      if (own != null) return [own];
      if (!CollectionService.isCollection(widget.clue) ||
          widget.clue.metadata?[ClueCover.automaticDisabledKey] == true) {
        return [];
      }
      final items = widget.collectionItems ??
          await CollectionService().items(widget.clue);
      final urls = <String>[];
      for (final item in items.where(ClueCover.hasOwnImage)) {
        try {
          final url = await _ownImage(item);
          if (url != null && !urls.contains(url)) urls.add(url);
        } catch (_) {
          // Keep the remaining collection photos usable.
        }
        if (urls.length == 4) break;
      }
      return urls;
    } catch (_) {
      return [];
    }
  }

  Widget _placeholder() => LayoutBuilder(
      builder: (context, bounds) => ClueCoverArt(
          clue: widget.clue,
          height: bounds.hasBoundedHeight ? bounds.maxHeight : widget.height));

  Widget _image(String url) => ColoredBox(
      color: const Color(0xFFF6F8FC),
      child: Image.network(url,
          height: widget.height,
          width: double.infinity,
          fit: widget.clue.metadata?['imagem_capa_ajuste'] == 'conter'
              ? BoxFit.contain
              : BoxFit.cover,
          semanticLabel: 'Imagem de capa de ${widget.clue.name}',
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : _placeholder(),
          errorBuilder: (context, error, stack) {
            if (!_retried) {
              _retried = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _urls = _resolve();
                  });
                }
              });
            }
            return _placeholder();
          }));

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: widget.height,
          width: double.infinity,
          child: FutureBuilder<List<String>>(
            future: _urls,
            builder: (context, snapshot) {
              final urls = snapshot.data ?? const <String>[];
              if (urls.isEmpty) return _placeholder();
              if (urls.length == 1) return _image(urls.first);
              Widget tile(int index) => Expanded(child: _image(urls[index]));
              if (urls.length == 2) {
                return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [tile(0), const SizedBox(width: 3), tile(1)]);
              }
              return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    tile(0),
                    const SizedBox(width: 3),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                          Expanded(child: _image(urls[1])),
                          const SizedBox(height: 3),
                          Expanded(
                              child: urls.length == 3
                                  ? _image(urls[2])
                                  : Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                          tile(2),
                                          const SizedBox(width: 3),
                                          tile(3)
                                        ])),
                        ])),
                  ]);
            },
          ),
        ),
      );
}
