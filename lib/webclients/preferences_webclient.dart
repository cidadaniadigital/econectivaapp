import 'dart:convert';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:widgets_spo/services/services.dart';

class PreferencesWebclient {
  final WebClient _client = WebClient.instance;
  Future<bool> editingEnabled() async {
    final response = await _client
        .get('/me/preferences', [ApiInterceptor(), TokenInterceptor()], {});
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['usage_mode'] != 'explorer';
  }

  Future<void> setEditingEnabled(bool enabled) async {
    await _client.put(
        '/me/preferences',
        jsonEncode({'usage_mode': enabled ? 'inventor' : 'explorer'}),
        [ApiInterceptor(), TokenInterceptor()]);
  }
}
