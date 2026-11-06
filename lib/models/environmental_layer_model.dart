class EnvironmentalLegendItem {
  final String label;
  final String color;

  const EnvironmentalLegendItem({required this.label, required this.color});

  factory EnvironmentalLegendItem.fromJson(Map<String, dynamic> json) =>
      EnvironmentalLegendItem(
        label: json['label']?.toString() ?? '',
        color: json['color']?.toString() ?? '#808080',
      );
}

class EnvironmentalLayerModel {
  final String id;
  final String name;
  final String description;
  final String tileUrl;
  final String mapRole;
  final String attribution;
  final double defaultOpacity;
  final int minZoom;
  final int maxZoom;
  final bool available;
  final List<EnvironmentalLegendItem> legend;
  final String sourceName;
  final String sourceVersion;

  const EnvironmentalLayerModel({
    required this.id,
    required this.name,
    required this.description,
    required this.tileUrl,
    required this.mapRole,
    required this.attribution,
    required this.defaultOpacity,
    required this.minZoom,
    required this.maxZoom,
    required this.available,
    required this.legend,
    required this.sourceName,
    required this.sourceVersion,
  });

  factory EnvironmentalLayerModel.fromJson(Map<String, dynamic> json) {
    final source = json['source'] is Map<String, dynamic>
        ? json['source'] as Map<String, dynamic>
        : <String, dynamic>{};
    return EnvironmentalLayerModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      tileUrl: json['tile_url']?.toString() ?? '',
      mapRole: json['map_role']?.toString() ?? 'overlay',
      attribution: json['attribution']?.toString() ?? '',
      defaultOpacity: (json['default_opacity'] as num?)?.toDouble() ?? 0.6,
      minZoom: (json['min_zoom'] as num?)?.toInt() ?? 0,
      maxZoom: (json['max_zoom'] as num?)?.toInt() ?? 18,
      available: json['available'] == true,
      legend: (json['legend'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(EnvironmentalLegendItem.fromJson)
          .toList(),
      sourceName: source['name']?.toString() ?? '',
      sourceVersion: source['version']?.toString() ?? '',
    );
  }
}
