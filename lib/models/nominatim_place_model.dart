import 'dart:convert';

class NominatimPlaceModel {
  NominatimPlaceModel({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.category,
    this.type,
  });

  final String displayName;
  final double latitude;
  final double longitude;
  final String? category;
  final String? type;

  factory NominatimPlaceModel.fromJson(Map<String, dynamic> json) {
    return NominatimPlaceModel(
      displayName: json['display_name']?.toString() ?? '',
      latitude: double.parse(json['lat'].toString()),
      longitude: double.parse(json['lon'].toString()),
      category: json['category']?.toString(),
      type: json['type']?.toString(),
    );
  }

  static List<NominatimPlaceModel> fromJsonArray(String str) {
    final decoded = jsonDecode(str);
    if (decoded is! List) return <NominatimPlaceModel>[];

    return decoded
        .whereType<Map>()
        .map((map) => NominatimPlaceModel.fromJson(
              Map<String, dynamic>.from(map),
            ))
        .where((place) => place.displayName.isNotEmpty)
        .toList();
  }
}
