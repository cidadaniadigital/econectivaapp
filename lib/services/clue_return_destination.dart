/// Only a positive clue ID can survive authentication. No arbitrary URL returns.
class ClueReturnDestination {
  static String? validate(String? value) {
    final uri = Uri.tryParse(value ?? '');
    if (uri == null ||
        uri.hasScheme ||
        uri.hasAuthority ||
        uri.path != '/living_clues/show' ||
        uri.hasFragment ||
        uri.queryParametersAll.length != 1 ||
        uri.queryParametersAll['id']?.length != 1) return null;
    final raw = uri.queryParameters['id'] ?? '';
    if (!RegExp(r'^[1-9][0-9]*$').hasMatch(raw)) return null;
    final id = int.tryParse(raw);
    if (id == null || id <= 0) return null;
    return '/living_clues/show?id=$id';
  }

  static String? startup(String fragment) {
    final clue = validate(fragment);
    if (clue != null) return clue;
    final uri = Uri.tryParse(fragment);
    if (uri != null &&
        !uri.hasScheme &&
        !uri.hasAuthority &&
        uri.path == '/login') {
      return login(uri.queryParameters['return']);
    }
    return null;
  }

  static String login(String? destination) {
    final safe = validate(destination);
    return safe == null
        ? '/login'
        : '/login?${Uri(queryParameters: {'return': safe}).query}';
  }

  static String publicLink(int id) {
    if (id <= 0) throw ArgumentError.value(id, 'id');
    return 'https://plataforma.atopos.spotec.app/#/living_clues/show?id=$id';
  }
}
