import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/webclients/webclient.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:widgets_spo/services/services.dart';

/// Only talks to this platform's API. Missing/older/disabled APIs leave creation
/// available, without making a request to CDIG or depending on its availability.
class CdigCreationNotice extends StatefulWidget {
  const CdigCreationNotice({super.key, this.load});
  final Future<Uri?> Function()? load;

  static Future<Uri?> configuration() async {
    try {
      final response = await WebClient.instance
          .get('/integrations/cdig', [ApiInterceptor()], {}, timeOut: 5)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      if (data is! Map || data['enabled'] != true || data['url'] is! String) {
        return null;
      }
      final uri = Uri.tryParse(data['url']);
      return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
          ? uri
          : null;
    } catch (_) {
      return null;
    }
  }

  @override
  State<CdigCreationNotice> createState() => _CdigCreationNoticeState();
}

class _CdigCreationNoticeState extends State<CdigCreationNotice> {
  late final Future<Uri?> _configuration;
  @override
  void initState() {
    super.initState();
    _configuration = (widget.load ?? CdigCreationNotice.configuration)();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uri?>(
        future: _configuration,
        builder: (context, snapshot) {
          final uri = snapshot.data;
          if (uri == null) return const SizedBox.shrink();
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'As pistas criadas aqui ficam nesta plataforma. Para enviar '
                    'um conteúdo à curadoria da CDIG, cadastre-o na CDIG.',
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final opened = await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                      if (!opened && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Não foi possível abrir a CDIG.')));
                      }
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Acessar Cidadania Digital'),
                  ),
                ],
              ),
            ),
          );
        },
      );
}
