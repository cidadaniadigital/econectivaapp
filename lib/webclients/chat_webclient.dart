import 'dart:convert';
import 'package:http_interceptor/http_interceptor.dart';
import 'package:unisinos_usp_app/models/chat_message_model.dart';
import 'package:unisinos_usp_app/services/auth_user.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:widgets_spo/services/services.dart';

class ChatWebclient {
  final WebClient _webClient = WebClient.instance;
  List<InterceptorContract> get _interceptors =>
      [ApiInterceptor(), TokenInterceptor()];

  Future<String> sendMessage(
      {required String message, AuthUser? user, String? fileUrl}) async {
    final response = await _webClient.post(
        '/ai/messages',
        jsonEncode({
          'message': message,
          'context': 'Conversa geral da plataforma Cidig.'
        }),
        _interceptors);
    final messages = (jsonDecode(response.body) as List<dynamic>? ?? const []).map((item) =>
        ChatMessageModel.fromHistoryJson(item as Map<String, dynamic>));
    final replies = messages.where((item) => !item.isUser).toList();
    if (replies.isEmpty)
      throw const FormatException('Resposta inválida do chat.');
    return replies.last.text;
  }

  Future<List<ChatMessageModel>> fetchHistory({int limit = 50}) async {
    final response = await _webClient.get('/ai/messages', _interceptors,
        {'limit': limit.toString(), 'offset': '0'});
    final messages = (jsonDecode(response.body) as List<dynamic>? ?? const [])
        .map((item) =>
            ChatMessageModel.fromHistoryJson(item as Map<String, dynamic>))
        .toList();
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return messages;
  }
}
