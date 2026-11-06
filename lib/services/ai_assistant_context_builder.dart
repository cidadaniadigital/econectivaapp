import 'package:unisinos_usp_app/models/ai_assistant_screen_context.dart';

class AiAssistantContextBuilder {
  static Map<String, dynamic> toApi(AiAssistantScreenContext context) {
    final route = Uri.tryParse(context.route);
    final references = <String, int>{};
    if (route != null &&
        const {
          '/living_clues/show',
          '/living_clues/update',
          '/collections/show'
        }.contains(route.path)) {
      final id = int.tryParse(
          route.queryParameters['id'] ?? context.filledFields['id'] ?? '');
      if (id != null && id > 0) references['living_clue_id'] = id;
    }
    return {
      'version': 1,
      'screen_name': context.screenName,
      'route': context.route,
      'stage': context.stage,
      'goal': context.goal,
      'references': references,
      'visible_fields': context.visibleFields,
      'filled_fields': context.filledFields,
      'notes': context.notes
    };
  }

  static String build(AiAssistantScreenContext context) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('Tela: ${context.screenName}')
      ..writeln('Rota: ${context.route}')
      ..writeln('Etapa: ${context.stage}')
      ..writeln('Objetivo: ${context.goal}');

    if (context.visibleFields.isNotEmpty) {
      buffer.writeln('Campos visíveis: ${context.visibleFields.join(', ')}');
    }

    if (context.filledFields.isNotEmpty) {
      buffer.writeln('Campos preenchidos:');
      context.filledFields.forEach((key, value) {
        buffer.writeln('- $key: $value');
      });
    }

    if (context.notes.isNotEmpty) {
      buffer.writeln('Observações relevantes:');
      for (final note in context.notes) {
        buffer.writeln('- $note');
      }
    }

    return buffer.toString().trim();
  }
}
