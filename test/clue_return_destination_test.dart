import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/services/clue_return_destination.dart';

void main() {
  test('only internal positive clue IDs survive login', () {
    expect(ClueReturnDestination.validate('/living_clues/show?id=8'),
        '/living_clues/show?id=8');
    for (final value in [
      'https://evil.test/living_clues/show?id=8',
      '//evil.test/living_clues/show?id=8',
      '/living_clues/show?id=-1',
      '/living_clues/show?id=0',
      '/living_clues/show?id=8&id=9',
      '/living_clues/show?id=8&next=https://evil.test',
      '/home',
      '/living_clues/show?id=8#other'
    ]) {
      expect(ClueReturnDestination.validate(value), isNull, reason: value);
    }
    final login =
        Uri.parse(ClueReturnDestination.login('/living_clues/show?id=8'));
    expect(login.queryParameters['return'], '/living_clues/show?id=8');
    expect(ClueReturnDestination.publicLink(8),
        'https://plataforma.atopos.spotec.app/#/living_clues/show?id=8');
  });
}
