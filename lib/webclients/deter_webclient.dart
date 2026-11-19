import 'dart:convert';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:widgets_spo/services/services.dart';

abstract class DeterSource {
  Future<Map<String, dynamic>> nearby(
    double latitude,
    double longitude,
    int radius,
  );
}

class DeterWebclient implements DeterSource {
  @override
  Future<Map<String, dynamic>> nearby(
    double latitude,
    double longitude,
    int radius,
  ) async {
    final response = await WebClient.instance.get(
      '/deter/nearby',
      [ApiInterceptor(), TokenInterceptor()],
      {
        'latitude': '$latitude',
        'longitude': '$longitude',
        'radius_m': '$radius',
      },
      timeOut: 15,
    );
    if (response.statusCode != 200) throw Exception('DETER indisponível');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
