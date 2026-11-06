import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/services/startup_route.dart';

void main() {
  const routes = [
    '/splash',
    '/home',
    '/login',
    '/collections/show',
    '/living_clues/show',
    '/password_recovery/:token'
  ];
  test('direct collection and clue URLs survive web reload', () {
    expect(
        startupRoute(
            Uri.parse('http://localhost/#/collections/show?id=66'), routes),
        '/collections/show?id=66');
    expect(
        startupRoute(
            Uri.parse('http://localhost/#/living_clues/show?id=8'), routes),
        '/living_clues/show?id=8');
    expect(
        startupRoute(
            Uri.parse('http://localhost/password_recovery/test-token'), routes),
        '/password_recovery/test-token');
  });
  test('login preserves only validated return and unknown paths are safe', () {
    final route = startupRoute(
        Uri.parse(
            'http://localhost/#/login?return=%2Fliving_clues%2Fshow%3Fid%3D8'),
        routes);
    expect(
        Uri.parse(route).queryParameters['return'], '/living_clues/show?id=8');
    expect(
        startupRoute(
            Uri.parse('http://localhost/#/login?return=https://evil.test'),
            routes),
        '/login');
    expect(
        startupRoute(Uri.parse('http://localhost/#//evil.test/home'), routes),
        '/splash');
    expect(startupRoute(Uri.parse('http://localhost/#/unknown'), routes),
        '/splash');
  });
}
