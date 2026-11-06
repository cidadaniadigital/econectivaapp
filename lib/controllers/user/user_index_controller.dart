import 'package:get/get.dart';
import 'package:unisinos_usp_app/models/user_model.dart';
import 'package:unisinos_usp_app/utils/safe_get_snackbar.dart';
import 'package:unisinos_usp_app/webclients/user_webclient.dart';
import 'package:widgets_spo/widgets_spo.dart';

class UserIndexController extends GetxController {
  final UserWebclient _webclient = UserWebclient();

  final RxList<UserModel> users = <UserModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxString search = ''.obs;

  static const int pageSize = 20;

  @override
  void onInit() {
    super.onInit();
    loadInitial();
  }

  Future<void> loadInitial() async {
    try {
      isLoading.value = true;
      final items = await _webclient.fetchUsers(
        limit: pageSize,
        search: _normalizedSearch,
      );
      users.assignAll(items);
      hasMore.value = items.length == pageSize;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível carregar os usuários.');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || !hasMore.value) return;

    try {
      isLoadingMore.value = true;
      final items = await _webclient.fetchUsers(
        limit: pageSize,
        offset: users.length,
        search: _normalizedSearch,
      );
      users.addAll(items);
      hasMore.value = items.length == pageSize;
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível carregar mais usuários.');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> applySearch(String value) async {
    search.value = value.trim();
    await loadInitial();
  }

  Future<void> deleteUser(UserModel user) async {
    try {
      isLoading.value = true;
      await _webclient.deleteUser(user.id);
      users.removeWhere((item) => item.id == user.id);
      SafeGetSnackbar.success('Usuário removido com sucesso.');
    } catch (error, stackTrace) {
      Util.debug(exception: error, stackTrace: stackTrace);
      SafeGetSnackbar.error('Erro', 'Não foi possível remover o usuário.');
    } finally {
      isLoading.value = false;
    }
  }

  String? get _normalizedSearch => search.value.isEmpty ? null : search.value;
}
