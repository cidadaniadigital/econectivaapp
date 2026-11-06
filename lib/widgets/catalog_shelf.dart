import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';

/// A horizontal catalog row with explicit controls for desktop users.
class CatalogShelf extends StatefulWidget {
  const CatalogShelf(
      {super.key,
      required this.title,
      required this.itemCount,
      required this.itemBuilder});

  final String title;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  State<CatalogShelf> createState() => _CatalogShelfState();
}

class _CatalogShelfState extends State<CatalogShelf> {
  final _controller = ScrollController();
  bool _canPrevious = false;
  bool _canNext = false;

  void _updateControls() {
    if (!mounted ||
        !_controller.hasClients ||
        !_controller.position.hasContentDimensions) {
      return;
    }
    final position = _controller.position;
    final previous = position.pixels > position.minScrollExtent + 1;
    final next = position.pixels < position.maxScrollExtent - 1;
    if (previous != _canPrevious || next != _canNext) {
      setState(() {
        _canPrevious = previous;
        _canNext = next;
      });
    }
  }

  void _scroll(int direction) {
    final position = _controller.position;
    final target =
        (position.pixels + direction * position.viewportDimension * .8)
            .clamp(position.minScrollExtent, position.maxScrollExtent);
    _controller.animateTo(target,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateControls);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 28),
          Row(children: [
            Expanded(
                child: Text(widget.title,
                    style: Theme.of(context).textTheme.titleLarge)),
            IconButton(
                tooltip: 'Pistas anteriores em ${widget.title}',
                onPressed: _canPrevious ? () => _scroll(-1) : null,
                icon: const Icon(Icons.chevron_left)),
            IconButton(
                tooltip: 'Próximas pistas em ${widget.title}',
                onPressed: _canNext ? () => _scroll(1) : null,
                icon: const Icon(Icons.chevron_right)),
          ]),
          const SizedBox(height: 12),
          NotificationListener<ScrollMetricsNotification>(
            onNotification: (_) {
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => _updateControls());
              return false;
            },
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {...PointerDeviceKind.values},
                  scrollbars: false),
              child: Scrollbar(
                controller: _controller,
                thumbVisibility: true,
                child: SizedBox(
                  height: 287,
                  child: ListView.separated(
                    controller: _controller,
                    padding: const EdgeInsets.only(bottom: 12),
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.itemCount,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: widget.itemBuilder,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}
