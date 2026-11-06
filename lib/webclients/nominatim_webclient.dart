import 'package:unisinos_usp_app/models/nominatim_place_model.dart';
import 'package:widgets_spo/widgets_spo.dart';
import 'webclient.dart';

class NominatimWebclient {
  NominatimWebclient({WebClient? client})
    : client = client ?? WebClient.instance;
  final WebClient client;
  Future<List<NominatimPlaceModel>> search({
    required String search,
    int limit = 5,
  }) async {
    if (search.trim().isEmpty) return [];
    final response = await client.get(
      '/places/search',
      [ApiInterceptor(), TokenInterceptor()],
      {'q': search.trim()},
    );
    if (response.statusCode == 429) {
      throw Exception(
        'Busca de lugares ocupada. Aguarde um instante e toque em Buscar novamente.',
      );
    }
    if (response.statusCode != 200) {
      throw Exception(
        'Não foi possível buscar lugares. Tente novamente em instantes.',
      );
    }
    return NominatimPlaceModel.fromJsonArray(response.body);
  }
}
