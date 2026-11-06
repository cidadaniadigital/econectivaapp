import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:unisinos_usp_app/services/clue_qr.dart';

void main() {
  testWidgets('QR exports a valid PNG with a four-module white quiet zone',
      (tester) async {
    await tester.runAsync(() async {
      final qr = ClueQr(321);
      expect(qr.url,
          'https://plataforma.atopos.spotec.app/#/living_clues/show?id=321');
      final bytes = await qr.png();
      expect(bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, (qr.matrix.moduleCount + 8) * 16);
      final pixels =
          await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(pixels!.getUint32(0), 0xffffffff);
      // A QR finder starts at (4,4), after the quiet zone.
      final at = ((4 * 16) * frame.image.width + 4 * 16) * 4;
      expect(pixels.getUint32(at), 0x000000ff);
      frame.image.dispose();
      codec.dispose();
    });
  });
}
