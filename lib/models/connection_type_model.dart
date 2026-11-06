import 'dart:convert';

class ConnectionTypeModel {
  int id;
  String name;
  String strokeStyle;
  bool isDirectional;
  DateTime? createdAt;
  DateTime? updatedAt;

  ConnectionTypeModel({
    required this.id,
    required this.name,
    this.strokeStyle = 'solid',
    this.isDirectional = true,
    this.createdAt,
    this.updatedAt,
  });

  ConnectionTypeModel.fromJson(Map<String, dynamic> json)
      : id = json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
        name = json['name'] ?? '',
        strokeStyle = json['stroke_style'] ?? 'solid',
        isDirectional = json['is_directional'] == null
            ? true
            : json['is_directional'] == true,
        createdAt = json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
        updatedAt = json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'stroke_style': strokeStyle,
        'is_directional': isDirectional,
      };

  static List<ConnectionTypeModel> fromJsonArray(String str) {
    return List<ConnectionTypeModel>.from(
      (jsonDecode(str) as List<dynamic>? ?? const [])
          .map((map) => ConnectionTypeModel.fromJson(map)),
    );
  }
}
