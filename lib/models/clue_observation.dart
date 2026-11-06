import 'dart:convert';

/// Read-only territorial snapshot. Never serialized back as user metadata.
class EnvironmentalSnapshot {
  final Map<String, dynamic> data;
  EnvironmentalSnapshot(Map source) : data = Map<String, dynamic>.from(source);
  String get status => data['status']?.toString() ?? 'unavailable';
  Map<String, dynamic> get sources =>
      data['sources'] is Map ? Map<String, dynamic>.from(data['sources']) : {};
  bool matches(double? latitude, double? longitude) {
    final lat = double.tryParse('${data['analyzed_latitude']}');
    final lng = double.tryParse('${data['analyzed_longitude']}');
    return latitude != null &&
        longitude != null &&
        lat != null &&
        lng != null &&
        (latitude - lat).abs() < 0.000001 &&
        (longitude - lng).abs() < 0.000001;
  }

  static const indicators = <String, List<String>>{
    'biome': ['Bioma', '', 'biome'],
    'land_cover': ['Cobertura predominante', '', 'land_cover'],
    'vegetation_percent': ['Vegetação no entorno', '%', 'land_cover'],
    'water_distance_m': ['Distância até água', 'm', 'hydrography'],
    'altitude_m': ['Altitude', 'm', 'altitude'],
    'slope_percent': ['Declividade', '%', 'slope'],
    'built_up_percent': ['Área construída no entorno', '%', 'land_cover'],
    'population_density_km2': [
      'Densidade populacional',
      'hab./km²',
      'population'
    ],
  };
}

class ClueReading {
  final int id;
  final int? clueId;
  final String raw;
  final String? registeredAt;
  final Map<String, dynamic>? payload;
  ClueReading.fromJson(Map source)
      : id = int.tryParse('${source['id']}') ?? 0,
        clueId = int.tryParse('${source['living_clue_id']}'),
        raw = source['payload_raw']?.toString() ?? '',
        registeredAt = source['created_at']?.toString(),
        payload = _decode(source['payload_raw']);
  static Map<String, dynamic>? _decode(dynamic raw) {
    try {
      final value = raw is String ? jsonDecode(raw) : raw;
      return value is Map ? Map<String, dynamic>.from(value) : null;
    } catch (_) {
      return null;
    }
  }

  bool get simulated => payload?['dados_ficticios'] == true;
  String? get measuredAt => payload?['instante_medicao']?.toString();
  String get origin => payload?['origem']?.toString() ?? 'Origem não informada';
  String get device =>
      payload?['id_dispositivo']?.toString() ?? 'Dispositivo não informado';
  static const _attributes = {
    'unidades',
    'instante_medicao',
    'sensor_pista_id',
    'id_dispositivo',
    'origem',
    'dados_ficticios',
    'lote',
    'alvo_medido'
  };
  static const _legacyMeasurements = {'Temperatura', 'Umidade', 'UmidadeSolo'};
  bool _supportedMetric(String key, dynamic value) {
    final units = payload?['unidades'];
    return (_legacyMeasurements.contains(key) ||
            units is Map && units.containsKey(key)) &&
        double.tryParse(value.toString())?.isFinite == true;
  }

  Map<String, dynamic> get measurements =>
      Map.fromEntries((payload ?? {}).entries.where((e) =>
          !_attributes.contains(e.key) && _supportedMetric(e.key, e.value)));
  String unit(String field) {
    final units = payload?['unidades'];
    return units is Map && units[field] != null
        ? units[field].toString()
        : 'unidade não informada';
  }
}

/// Preserve the original timezone; only calculate age when it is explicit.
String observationTime(String? raw, {DateTime? now}) {
  if (raw == null || raw.isEmpty) return 'não informado';
  if (!RegExp(r'(?:Z|[+-]\d{2}:\d{2})$').hasMatch(raw))
    return '$raw (fuso não informado)';
  final instant = DateTime.tryParse(raw);
  if (instant == null) return '$raw (formato não reconhecido)';
  final age = (now ?? DateTime.now()).toUtc().difference(instant.toUtc());
  if (age.isNegative) return '$raw (data futura declarada)';
  if (age.inDays > 0) return '$raw (há ${age.inDays} dias)';
  if (age.inHours > 0) return '$raw (há ${age.inHours} horas)';
  if (age.inMinutes > 0) return '$raw (há ${age.inMinutes} minutos)';
  return '$raw (há menos de um minuto)';
}
