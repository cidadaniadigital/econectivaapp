import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/utils/assistant_link.dart';

void main() {
  test('provider reference opens the corresponding USP clue route', () {
    expect(resolveAssistantLink('#/space/research/55'),
        '/living_clues/show?id=55');
    expect(
        resolveAssistantLink('/space/research/55'), '/living_clues/show?id=55');
    expect(resolveAssistantLink('#/living_clues/show?id=55'),
        '/living_clues/show?id=55');
  });
  test('external references preserve HTTP URLs and query strings', () {
    expect(resolveAssistantLink('https://example.org/reference?v=2'),
        'https://example.org/reference?v=2');
  });
  test('unrecognized internal destinations and executable schemes are refused',
      () {
    for (final href in [
      null,
      '',
      '/users/delete',
      '//example.org/path',
      'javascript:alert(1)',
      'file:///tmp/a',
      '/space/research/0',
      '/space/research/-1',
      '/space/research/55?delete=true',
      '/living_clues/show?id=0',
      '/living_clues/show?id=55&return=https://example.org'
    ]) {
      expect(resolveAssistantLink(href), isNull, reason: '$href');
    }
  });
}
