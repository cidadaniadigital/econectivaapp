import 'dart:convert';

class ClueIntegration {
  const ClueIntegration({
    required this.provider,
    required this.url,
    this.title = '',
    this.instructions = '',
    this.version = 1,
  });
  final int version;
  final String provider;
  final String url;
  final String title;
  final String instructions;
  static const providers = ['genially', 'padlet', 'framevr'];
  bool get supported =>
      version == 1 &&
      (provider == 'agent' ||
          provider == 'node' ||
          providers.contains(provider));
  bool get inline => provider == 'genially' || provider == 'padlet';
  String get name =>
      const {
        'agent': 'Agente da plataforma',
        'node': 'Grafo',
        'genially': 'Genially',
        'padlet': 'Padlet',
        'framevr': 'FrameVR',
      }[provider] ??
      'Integração';
  static String explanation(String provider) =>
      const {
        'node':
            'Vincule um grafo para explorar suas conexões a partir desta pista.',
        'agent':
            'Vincule um agente da plataforma para conversar a partir desta pista.',
        'genially': 'Inclua uma apresentação ou experiência interativa.',
        'padlet': 'Inclua um mural para compartilhar ideias e materiais.',
        'framevr': 'Conecte a pista a um ambiente virtual 3D.',
      }[provider] ??
      '';

  Map<String, dynamic> toJson() => {
        'v': version,
        'provider': provider,
        'url': url,
        if (title.isNotEmpty) 'title': title,
        if (instructions.isNotEmpty) 'instructions': instructions,
      };
  String encode() => jsonEncode(toJson());
  static ClueIntegration? decode(dynamic value) {
    try {
      final data = value is String ? jsonDecode(value) : value;
      if (data is! Map ||
          data['v'] is! int ||
          data['provider'] is! String ||
          data['url'] is! String) return null;
      return ClueIntegration(
        version: data['v'],
        provider: data['provider'],
        url: data['url'],
        title: (data['title'] ?? '').toString(),
        instructions: (data['instructions'] ?? '').toString(),
      );
    } catch (_) {
      return null;
    }
  }

  int? get agentId => provider == 'agent' && validateURL(provider, url) == null
      ? int.tryParse(
          Uri.parse(url).queryParameters['id'] ?? url.split('/').last)
      : null;

  int? get nodeId => provider == 'node' && validateURL(provider, url) == null
      ? int.tryParse(Uri.parse(url).queryParameters['focus'] ?? '')
      : null;

  static String? validateURL(String provider, String raw) {
    if (provider == 'node') {
      return raw == raw.trim() &&
              RegExp(r'^/nodes/graph\?focus=[1-9][0-9]{0,14}$').hasMatch(raw)
          ? null
          : 'Selecione um grafo válido da plataforma.';
    }
    if (provider == 'agent') {
      return raw == raw.trim() &&
              (RegExp(r'^/chat_templates/chat\?id=[1-9][0-9]{0,14}$')
                      .hasMatch(raw) ||
                  RegExp(r'^/space/agents/[1-9][0-9]{0,14}$').hasMatch(raw))
          ? null
          : 'Selecione um agente válido da plataforma.';
    }
    final u = Uri.tryParse(raw);
    if (u == null ||
        raw != raw.trim() ||
        raw.length > 2000 ||
        RegExp(r'[\r\n\t<>\\]').hasMatch(raw) ||
        u.userInfo.isNotEmpty ||
        u.host.isEmpty)
      return 'Informe um endereço válido, sem HTML ou credenciais.';
    if (u.scheme != 'https' || (u.hasPort && u.port != 443))
      return 'Use um link HTTPS do provedor.';
    final path = u.path.replaceAll(RegExp(r'^/+|/+$'), '');
    if (path.isEmpty ||
        !RegExp(r'^[A-Za-z0-9_/-]+$').hasMatch(path) ||
        path.contains('//')) return 'Use o link de visualização do conteúdo.';
    final parts = path.split('/');
    switch (provider) {
      case 'genially':
        if (u.host != 'view.genially.com' ||
            !RegExp(r'^[a-fA-F0-9]{24}$').hasMatch(parts.first))
          return 'Use o link em view.genially.com da apresentação.';
      case 'padlet':
        if (u.host != 'padlet.com' ||
            parts.length != 2 ||
            parts.first == 'api' ||
            parts.last.length < 3)
          return 'Use o link do mural Padlet ou de incorporação.';
      case 'framevr':
        if (u.host != 'framevr.io' || parts.length != 1)
          return 'Use o link da sala em framevr.io.';
      default:
        return 'Integração indisponível.';
    }
    return null;
  }

  Uri? get embedURI {
    if (!supported ||
        provider == 'agent' ||
        provider == 'node' ||
        validateURL(provider, url) != null) return null;
    final u = Uri.parse(url);
    if (provider == 'padlet') {
      final id = u.pathSegments.last.split('-').last;
      return Uri.https('padlet.com', '/embed/$id');
    }
    return u.replace(fragment: '');
  }
}
