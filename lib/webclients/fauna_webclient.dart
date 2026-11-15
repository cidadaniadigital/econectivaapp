import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:unisinos_usp_app/models/fauna_model.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:widgets_spo/services/services.dart';

abstract class FaunaSource {
  Future<FaunaResult> nearby(double latitude, double longitude, int radius);
  Future<FaunaResult> bounds(LatLngBounds bounds);
}

class FaunaWebclient implements FaunaSource {
  Future<FaunaResult> _get(String route, Map<String, dynamic> params) async {
    final response = await WebClient.instance.get(
      '/biodiversity/$route',
      [ApiInterceptor(), TokenInterceptor()],
      params,
      timeOut: 25,
    );
    if (response.statusCode != 200) {
      throw Exception('Fauna temporariamente indisponível.');
    }
    return FaunaResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  @override
  Future<FaunaResult> nearby(double latitude, double longitude, int radius) =>
      _get('nearby', {
        'latitude': '$latitude',
        'longitude': '$longitude',
        'radius_m': '$radius',
      });

  @override
  Future<FaunaResult> bounds(LatLngBounds bounds) => _get('observations', {
        'north': '${bounds.north}',
        'south': '${bounds.south}',
        'east': '${bounds.east}',
        'west': '${bounds.west}',
      });
}
