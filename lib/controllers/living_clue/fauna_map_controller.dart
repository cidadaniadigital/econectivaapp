import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:unisinos_usp_app/models/fauna_model.dart';
import 'package:unisinos_usp_app/webclients/fauna_webclient.dart';

class FaunaMapController extends ChangeNotifier {
  final FaunaSource source;
  FaunaMapController({FaunaSource? source})
      : source = source ?? FaunaWebclient();
  bool enabled = false;
  bool loading = false;
  bool limited = false;
  String? message;
  List<FaunaObservation> observations = [];
  Timer? _timer;
  int _serial = 0;
  bool _disposed = false;

  void toggle(bool value, double zoom, LatLngBounds bounds) {
    enabled = value;
    updateViewport(zoom, bounds, immediate: true);
  }

  void updateViewport(
    double zoom,
    LatLngBounds bounds, {
    bool immediate = false,
  }) {
    _timer?.cancel();
    final request = ++_serial;
    observations = [];
    limited = false;
    loading = false;
    message = null;
    if (!enabled) {
      notifyListeners();
      return;
    }
    if (zoom < 8 ||
        bounds.north - bounds.south > 3 ||
        bounds.east - bounds.west > 3 ||
        bounds.east <= bounds.west) {
      message = 'Aproxime o mapa para visualizar a fauna do iNaturalist.';
      notifyListeners();
      return;
    }
    loading = true;
    notifyListeners();
    _timer = Timer(Duration(milliseconds: immediate ? 0 : 700), () async {
      try {
        final result = await source.bounds(bounds);
        if (_disposed || request != _serial) return;
        observations = result.observations.take(100).toList();
        limited = result.limited;
        message = observations.isEmpty
            ? 'Nenhuma observação com foto nesta área. Isso não indica ausência de fauna.'
            : null;
      } catch (_) {
        if (_disposed || request != _serial) return;
        message =
            'Fauna temporariamente indisponível. Use “Atualizar fauna” para tentar novamente.';
      }
      loading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _serial++;
    _timer?.cancel();
    super.dispose();
  }
}
