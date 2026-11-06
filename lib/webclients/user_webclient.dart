import 'dart:convert';

import 'package:http_interceptor/http_interceptor.dart';
import 'package:unisinos_usp_app/models/user_model.dart';
import 'package:unisinos_usp_app/services/auth_user.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:widgets_spo/services/services.dart';

class UserWebclient {
  final WebClient webClient = WebClient.instance;

  String get endpoint => 'users';

  Future<AuthUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final Map<String, dynamic> data = {
      'name': name,
      'email': email,
      'password': password,
    };

    final Response response = await webClient.post(
      '/register',
      jsonEncode(data),
      [
        LoggingInterceptor(),
        ApiInterceptor(),
      ],
    );

    return AuthUser.fromJson(jsonDecode(response.body));
  }

  Future<AuthUser> login({
    required String mail,
    required String password,
  }) async {
    final Response response = await webClient.post(
      '/login',
      jsonEncode({
        'email': mail,
        'password': password,
        'device_name': '',
      }),
      [
        LoggingInterceptor(),
        ApiInterceptor(),
      ],
    );

    return AuthUser.fromJson(jsonDecode(response.body));
  }

  Future<AuthUser> loginGoogle(String idToken, String accessToken) async {
    final Response response = await webClient.post(
      '/login/google',
      jsonEncode({
        'id_token': idToken,
        'access_token': accessToken,
      }),
      [
        LoggingInterceptor(),
        ApiInterceptor(),
      ],
    );

    return AuthUser.fromJson(jsonDecode(response.body));
  }

  Future<void> forgotPassword(String email) async {
    await webClient.post(
      '/forgot_password',
      jsonEncode({'email': email}),
      [
        LoggingInterceptor(),
        ApiInterceptor(),
      ],
    );
  }

  Future<AuthUser> recoverPassword(String token, String password) async {
    final Response response = await webClient.post(
      '/recover_password',
      jsonEncode({
        'password': password,
        'reset_password_token': token,
      }),
      [
        LoggingInterceptor(),
        ApiInterceptor(),
      ],
    );

    return AuthUser.fromJson(jsonDecode(response.body));
  }

  Future<List<UserModel>> fetchUsers({
    int? limit,
    int offset = 0,
    String? search,
  }) async {
    final Response response = await webClient.get(
      '/$endpoint',
      _authInterceptors,
      {
        if (limit != null) 'limit': limit.toString(),
        'offset': offset.toString(),
        if (search != null) 'search': search,
      },
    );

    return UserModel.fromResponseBody(response.body);
  }

  Future<UserModel> fetchUserById(int id) async {
    final Response response =
        await webClient.get('/$endpoint/$id', _authInterceptors, {});
    return UserModel.fromJson(
        _extractObject(jsonDecode(response.body), 'user'));
  }

  Future<UserModel> createUser(UserModel model) async {
    final Response response = await webClient.post(
        '/$endpoint', jsonEncode(model.toCreateJson()), _authInterceptors);
    return UserModel.fromJson(
        _extractObject(jsonDecode(response.body), 'user'));
  }

  Future<UserModel> updateUser(UserModel model) async {
    final Response response = await webClient.put(
      '/$endpoint/${model.id}',
      jsonEncode(model.toUpdateJson()),
      _authInterceptors,
    );
    return UserModel.fromJson(
        _extractObject(jsonDecode(response.body), 'user'));
  }

  Future<void> deleteUser(int id) async {
    await webClient.delete('/$endpoint/$id', _authInterceptors);
  }

  List<InterceptorContract> get _authInterceptors => [
        LoggingInterceptor(),
        ApiInterceptor(),
        TokenInterceptor(),
      ];

  Map<String, dynamic> _extractObject(Object? decoded, String key) {
    if (decoded is Map<String, dynamic>) {
      if (decoded[key] is Map<String, dynamic>) {
        return decoded[key] as Map<String, dynamic>;
      }
      return decoded;
    }

    throw Exception('Resposta inválida ao processar usuário.');
  }
}
