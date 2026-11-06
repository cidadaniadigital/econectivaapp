import 'dart:convert';

class BiomeModel {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final String colorHex;
  final String? coverImageUrl;
  final Map<String, dynamic>? metadata;
  final bool isActive;

  const BiomeModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.colorHex,
    this.coverImageUrl,
    this.metadata,
    this.isActive = true,
  });

  factory BiomeModel.fromJson(Map<String, dynamic> json) {
    return BiomeModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      colorHex: json['color_hex'] ?? '#000000',
      coverImageUrl: json['cover_image_url'],
      metadata: json['metadata'] == null
          ? null
          : Map<String, dynamic>.from(json['metadata']),
      isActive: json['is_active'] == null ? true : json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'description': description,
    'color_hex': colorHex,
    'cover_image_url': coverImageUrl,
    'metadata': metadata,
    'is_active': isActive,
  };

  static List<BiomeModel> fromJsonArray(List<dynamic> json) =>
      json.map((item) => BiomeModel.fromJson(item)).toList();

  static List<BiomeModel> fromJsonString(String str) =>
      fromJsonArray(jsonDecode(str));
}
