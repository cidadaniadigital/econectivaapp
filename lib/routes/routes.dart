import 'package:get/get.dart';
import 'package:unisinos_usp_app/widgets/editing_required.dart';
import 'package:unisinos_usp_app/middleware/session_middleware.dart';
import 'package:unisinos_usp_app/screens/catalog/catalog_home_screen.dart';
import 'package:unisinos_usp_app/screens/catalog/collection_screen.dart';
import 'package:unisinos_usp_app/screens/catalog/catalog_screen.dart';
import 'package:unisinos_usp_app/routes/auth.dart';
import 'package:unisinos_usp_app/routes/categories.dart';
import 'package:unisinos_usp_app/routes/samples.dart';
import 'package:unisinos_usp_app/routes/living_clues.dart';
import 'package:unisinos_usp_app/routes/clue_connections.dart';
import 'package:unisinos_usp_app/routes/connection_types.dart';
import 'package:unisinos_usp_app/routes/chat.dart';
import 'package:unisinos_usp_app/routes/chat_templates.dart';
import 'package:unisinos_usp_app/routes/node_links.dart';
import 'package:unisinos_usp_app/routes/node_types.dart';
import 'package:unisinos_usp_app/routes/nodes.dart';
import 'package:unisinos_usp_app/routes/users.dart';
import 'package:unisinos_usp_app/screens/screens.dart';

List<GetPage> appRoutes() => [
      GetPage(name: '/splash', page: () => const SplashScreen()),
      ...authRoutes(),
      GetPage(name: '/collections/show', page: () => const CollectionScreen()),
      GetPage(
          name: '/collections/create', page: () => const CollectionScreen()),
      GetPage(name: '/catalog', page: () => const CatalogScreen()),
      GetPage(name: '/home', page: () => const CatalogHomeScreen()),
      GetPage(name: '/management', page: () => HomeScreen()),
      ...categoryRoutes(),
      ...livingClueRoutes(),
      GetPage(
          name: '/map/point_picker', page: () => const MapPointPickerScreen()),
      ...clueConnectionRoutes(),
      ...connectionTypeRoutes(),
      ...sampleRoutes(),
      ...chatRoutes(),
      ...chatTemplateRoutes(),
      ...nodeTypeRoutes(),
      ...nodeRoutes(),
      ...nodeLinkRoutes(),
      ...userRoutes(),
    ].map((page) {
      const editableResources = {
        'categories',
        'living_clues',
        'clue_connections',
        'connection_types',
        'chat_templates',
        'node_types',
        'nodes',
        'node_links',
        'samples',
        'collections'
      };
      final segments = Uri.parse(page.name).pathSegments;
      final isWriteForm = segments.length > 1 &&
          editableResources.contains(segments.first) &&
          {'create', 'update', 'pre_create', 'type_select', 'connect'}
              .contains(segments.last);
      final guarded = isWriteForm
          ? page.copy(page: () {
              final destination = Get.currentRoute;
              return EditingRequired(
                builder: (_) => page.page(),
                onConfigure: () async {
                  await Get.toNamed('/profile');
                  // GetX query parameters may belong to the popped profile.
                  // Recreate the route/binding with the original address.
                  if (Get.currentRoute == destination) {
                    Get.offNamed(destination, preventDuplicates: false);
                  }
                },
              );
            })
          : page;
      final public = {
        '/splash',
        '/login',
        '/create_account',
        '/recover_password',
        '/code_confirmation',
        '/password_recovery/:token',
        '/living_clues/show', // Its own guard runs after GetX resolves query IDs.
        '/create_password'
      };
      return public.contains(page.name)
          ? guarded
          : guarded
              .copy(middlewares: [SessionMiddleware(), ...?page.middlewares]);
    }).toList();
