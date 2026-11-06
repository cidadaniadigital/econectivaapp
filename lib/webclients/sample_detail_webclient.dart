import 'package:http_interceptor/http_interceptor.dart';
import 'package:widgets_spo/widgets_spo.dart';

import 'webclient.dart';

class SampleDetailWebclient {
  final WebClient webClient = WebClient.instance;

  Future<List<ItemSelect>?> select(
      String? search, int? offset, Map<String, String?>? params) async {
    final Response response = await webClient.get(
      '/sample_details_select',
      [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ],
      {
        'limit': webClient.defaultLimit.toString(),
        'search': search ?? '',
        'offset': (offset ?? 0).toString(),
      },
    );

    final List<ItemSelect> returnList = ItemSelect.fromJsonArray(response.body.trim() == 'null' ? '[]' : response.body);
    return returnList.isEmpty ? null : returnList;
  }
}
