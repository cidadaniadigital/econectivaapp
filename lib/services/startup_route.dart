import 'clue_return_destination.dart';

String startupRoute(Uri location, Iterable<String> registeredRoutes) {
  final direct = Uri.tryParse(location.fragment);
  final candidate = direct != null && direct.path.isNotEmpty
      ? direct
      : Uri(path: location.path);
  if (candidate.hasScheme ||
      candidate.hasAuthority ||
      candidate.hasFragment ||
      !candidate.path.startsWith('/')) return '/splash';
  if (candidate.path == '/login')
    return ClueReturnDestination.login(candidate.queryParameters['return']);
  final segments = candidate.pathSegments;
  final matches = registeredRoutes.any((route) {
    final pattern = Uri.parse(route).pathSegments;
    if (pattern.length != segments.length) return false;
    for (var i = 0; i < pattern.length; i++) {
      if (!pattern[i].startsWith(':') && pattern[i] != segments[i])
        return false;
    }
    return true;
  });
  return matches ? candidate.toString() : '/splash';
}
