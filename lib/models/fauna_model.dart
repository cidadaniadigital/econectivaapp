class FaunaObservation {
  final int id;
  final String scientificName;
  final String commonName;
  final String photoUrl;
  final String attribution;
  final String license;
  final String url;
  final double latitude;
  final double longitude;
  final double? distanceM;
  final double? accuracyM;
  final bool approximate;
  final DateTime? observedOn;

  FaunaObservation.fromJson(Map<String, dynamic> json)
      : id = (json['id'] as num).toInt(),
        scientificName = json['scientific_name'] as String? ?? '',
        commonName = json['common_name'] as String? ?? '',
        photoUrl = json['photo_url'] as String? ?? '',
        attribution = json['photo_attribution'] as String? ?? '',
        license = json['photo_license'] as String? ?? '',
        url = json['url'] as String? ?? '',
        latitude = (json['latitude'] as num).toDouble(),
        longitude = (json['longitude'] as num).toDouble(),
        distanceM = (json['distance_m'] as num?)?.toDouble(),
        accuracyM = (json['accuracy_m'] as num?)?.toDouble(),
        approximate = json['approximate_location'] == true,
        observedOn = DateTime.tryParse(json['observed_on'] as String? ?? '');

  String get title => commonName.isEmpty ? scientificName : commonName;
}

class FaunaResult {
  final List<FaunaObservation> observations;
  final bool limited;
  final DateTime? fetchedAt;
  FaunaResult.fromJson(Map<String, dynamic> json)
      : observations = (json['observations'] as List<dynamic>? ?? [])
            .map(
              (value) =>
                  FaunaObservation.fromJson(value as Map<String, dynamic>),
            )
            .toList(),
        limited = json['limited'] == true,
        fetchedAt = DateTime.tryParse(json['fetched_at'] as String? ?? '');
}
