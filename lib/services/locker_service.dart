import 'package:get/get.dart';
import 'package:unisinos_usp_app/controllers/auth/user_controller.dart';
import 'package:unisinos_usp_app/webclients/econectiva_webclient.dart';

class LockerService extends GetxController {
  final items = <Map<String, dynamic>>[].obs;
  final loading = false.obs;
  final error = RxnString();
  final busy = <String>{}.obs;
  final api = EconectivaApi();
  int generation = 0;
  int _loadSerial = 0;
  Worker? _accountWorker;
  int? _accountId;
  void attach(UserController users) {
    void changed() {
      final id = users.user.value?.id;
      if (id == _accountId) return;
      _accountId = id;
      clear();
      if (id != null) load();
    }

    _accountWorker?.dispose();
    _accountWorker = ever(users.user, (_) => changed());
    changed();
  }

  @override
  void onClose() {
    _accountWorker?.dispose();
    super.onClose();
  }

  void clear() {
    generation++;
    _loadSerial++;
    loading.value = false;
    busy.clear();
    items.clear();
    error.value = null;
  }

  bool saved(String type, int id) =>
      items.any((e) => e['entity_type'] == type && e['entity_id'] == id);
  Future<void> load() async {
    final version = generation;
    final serial = ++_loadSerial;
    loading.value = true;
    error.value = null;
    try {
      final data = await api.get('/me/locker');
      if (version != generation || serial != _loadSerial) return;
      items.assignAll((data as List).map((e) => Map<String, dynamic>.from(e)));
    } catch (_) {
      if (version == generation && serial == _loadSerial) {
        error.value = 'Não foi possível carregar seus itens salvos.';
      }
    } finally {
      if (version == generation && serial == _loadSerial) loading.value = false;
    }
  }

  Future<void> toggle(String type, int id) async {
    final version = generation;
    final key = '$type:$id';
    if (busy.contains(key)) return;
    busy.add(key);
    _loadSerial++;
    loading.value = false;
    try {
      if (saved(type, id)) {
        await api.write('DELETE', '/me/locker/$type/$id');
        if (version != generation) return;
        items.removeWhere(
            (e) => e['entity_type'] == type && e['entity_id'] == id);
      } else {
        final item = await api.write('PUT', '/me/locker/$type/$id');
        if (version != generation) return;
        items.insert(0, Map<String, dynamic>.from(item));
      }
    } catch (_) {
      Get.snackbar('Itens salvos',
          'Não foi possível salvar a alteração. Tente novamente.');
    } finally {
      if (version == generation) busy.remove(key);
    }
  }
}
