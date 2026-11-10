import 'package:flutter/material.dart';
import 'package:unisinos_usp_app/models/living_clue_model.dart';
import 'package:url_launcher/url_launcher.dart';

class CdigSource extends StatelessWidget {
  const CdigSource({super.key, required this.clue});
  final LivingClueModel clue;

  @override
  Widget build(BuildContext context) {
    final data = clue.metadata?['cdig'];
    if (data is! Map) return const SizedBox.shrink();
    final uri = Uri.tryParse('${data['url'] ?? ''}');
    final validUrl = uri != null &&
        {'http', 'https'}.contains(uri.scheme) &&
        uri.host.isNotEmpty;
    final subject = data['subject'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Acervo Cidadania Digital',
                style: Theme.of(context).textTheme.titleLarge),
            if (data['state'] == 'unavailable')
              const Text('Este conteúdo deixou de estar disponível na origem. '
                  'A referência e as interações locais foram preservadas.'),
            for (final field in const {
              'author': 'Autoria',
              'publisher': 'Publicação',
              'rights': 'Direitos',
              'language': 'Idioma',
            }.entries)
              if (data[field.key] is String &&
                  (data[field.key] as String).isNotEmpty)
                Text('${field.value}: ${data[field.key]}'),
            if (subject is Map && (subject['Name'] ?? subject['name']) != null)
              Text('Tema: ${subject['Name'] ?? subject['name']}'),
            if (validUrl)
              TextButton.icon(
                onPressed: () async {
                  final opened = await launchUrl(uri,
                      mode: LaunchMode.externalApplication);
                  if (!opened && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Não foi possível abrir a referência.')));
                  }
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Consultar referência de origem'),
              ),
          ],
        ),
      ),
    );
  }
}
