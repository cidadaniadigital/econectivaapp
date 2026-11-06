import 'package:get/get.dart';

/// Unwind sequential pista views to the existing map, retaining its state.
/// A direct QR entry creates a map if no map exists in the current stack.
void returnToClueMap() {
  var found = false;
  Get.until((route) {
    found = route.settings.name?.split('?').first == '/living_clues/map';
    return found || route.isFirst;
  });
  if (!found) Get.offNamed('/living_clues/map');
}
