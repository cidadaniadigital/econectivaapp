import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:unisinos_usp_app/webclients/living_clue_webclient.dart';

typedef SimilarCluesSearch = Future<List<LivingClueModel>> Function(
    String name);

/// Advisory search only: never validates or blocks the form's save action.
class SimilarCluesNotice extends StatefulWidget {
  const SimilarCluesNotice({
    super.key,
    required this.nameController,
    this.search,
  });

  final TextEditingController nameController;
  final SimilarCluesSearch? search;

  @override
  State<SimilarCluesNotice> createState() => _SimilarCluesNoticeState();
}

class _SimilarCluesNoticeState extends State<SimilarCluesNotice> {
  Timer? _timer;
  int _generation = 0;
  String _query = '';
  bool _loading = false;
  bool _failed = false;
  List<LivingClueModel> _matches = [];

  @override
  void initState() {
    super.initState();
    widget.nameController.addListener(_nameChanged);
    _nameChanged();
  }

  @override
  void didUpdateWidget(SimilarCluesNotice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nameController != widget.nameController) {
      oldWidget.nameController.removeListener(_nameChanged);
      widget.nameController.addListener(_nameChanged);
      _query = '';
      _nameChanged();
    }
  }

  void _nameChanged() {
    final query = widget.nameController.text.trim().replaceAll(
          RegExp(r'\s+'),
          ' ',
        );
    if (query == _query) return;
    _query = query;
    _timer?.cancel();
    final generation = ++_generation;
    setState(() {
      _matches = [];
      _failed = false;
      _loading = false;
    });
    if (query.runes.length < 3) return;
    _timer = Timer(
      const Duration(milliseconds: 600),
      () => _search(query, generation),
    );
  }

  Future<void> _search(String query, int generation) async {
    if (!mounted || generation != _generation) return;
    setState(() => _loading = true);
    try {
      final matches = await (widget.search?.call(query) ??
          LivingClueWebclient().fetch(search: query, limit: 5));
      if (!mounted || generation != _generation) return;
      setState(() {
        _matches = matches.take(5).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    ++_generation;
    widget.nameController.removeListener(_nameChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && !_failed && _matches.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Theme.of(context).colorScheme.primary.withAlpha(120)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_loading)
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Buscando pistas semelhantes…',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              )
            else if (_failed) ...[
              const Text(
                'Não foi possível buscar pistas semelhantes. Você pode continuar o cadastro.',
                style: TextStyle(color: Color(0xFFCCDDE5)),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _failed = false);
                  _search(_query, _generation);
                },
                child: const Text('Tentar novamente'),
              ),
            ] else ...[
              const Text(
                'Encontramos pistas semelhantes',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Alguma delas corresponde ao que você deseja registrar? Toque para conferir sem perder o cadastro.',
                style: TextStyle(color: Color(0xFFB8D0DC)),
              ),
              const SizedBox(height: 8),
              for (final clue in _matches)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    clue.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    [
                      if (clue.category?.name.isNotEmpty ?? false)
                        clue.category!.name,
                      if (clue.description?.trim().isNotEmpty ?? false)
                        clue.description!.trim(),
                    ].join(' · '),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFB8D0DC)),
                  ),
                  trailing: const Icon(
                    Icons.open_in_new,
                    color: Color(0xFF80D6EE),
                    size: 20,
                  ),
                  onTap: () => _preview(clue),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => setState(() => _matches = []),
                  child: const Text('Continuar com uma nova pista'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _preview(LivingClueModel clue) async {
    final open = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(clue.name),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (clue.category != null) ...[
                  Text(
                    clue.category!.name,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  (clue.description?.trim().isNotEmpty ?? false)
                      ? clue.description!
                      : 'Esta pista não possui descrição.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar ao cadastro'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ver pista completa'),
          ),
        ],
      ),
    );
    if ((open ?? false) && mounted) {
      await Get.toNamed('/living_clues/show?id=${clue.id}');
    }
  }
}
