import 'package:unisinos_usp_app/services/modal_route_observer.dart';
import 'dart:async';
import 'package:unisinos_usp_app/widgets/app_startup_failure.dart';
import 'package:unisinos_usp_app/services/startup_route.dart';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;
import 'package:get/get.dart';
import 'package:unisinos_usp_app/routes/routes.dart';
import 'package:unisinos_usp_app/services/ai_assistant_context_service.dart';
import 'package:unisinos_usp_app/services/initializer.dart';
import 'package:unisinos_usp_app/themes/app_theme.dart';
import 'package:unisinos_usp_app/widgets/ai_assistant_launcher.dart';
import 'package:widgets_spo/screens/not_found_screen.dart';
import 'package:widgets_spo/utils.dart';
import 'package:widgets_spo/utils/app_theme.dart' as spo_theme;

Future<void> main() async {
  await runZonedGuarded(_startApp, (error, stack) {
    debugPrint(error.toString());
    debugPrint(stack.toString());
  });
}

Future<void> _startApp({Uri? requestedLocation}) async {
  final location = requestedLocation ?? Uri.base;
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Initializer.init();
  } catch (error, stack) {
    debugPrint(error.toString());
    debugPrint(stack.toString());
    final fragment = Uri.tryParse(location.fragment);
    final recoveryRoute = fragment != null &&
            !fragment.hasScheme &&
            !fragment.hasAuthority &&
            fragment.path.startsWith('/')
        ? fragment.toString()
        : '/';
    runApp(AppStartupFailure(
        routeName: recoveryRoute,
        onRetry: () => _startApp(requestedLocation: location)));
    return;
  }
  _configureWidgetsSpoTheme();
  final pages = appRoutes();

  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Plataforma eCOnectiva',
      initialRoute: startupRoute(location, pages.map((page) => page.name)),
      unknownRoute: GetPage(
        name: '/not_found',
        page: () => const NotFoundScreen(),
      ),
      navigatorObservers: [NavigationObserver.instance, ModalRouteObserver.instance],
      getPages: pages,
      theme: AppTheme.theme,
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en', 'US'),
      ],
      locale: const Locale('pt', 'BR'),
      routingCallback: (routing) {
        if (!Get.isRegistered<AiAssistantContextService>()) return;
        final String currentRoute = routing?.current ?? '';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!Get.isRegistered<AiAssistantContextService>()) return;
          final AiAssistantContextService contextService =
              Get.find<AiAssistantContextService>();
          contextService.setCurrentRoute(currentRoute);
        });
      },
      builder: (context, child) => RepaintBoundary(
        key: const ValueKey('usp-app-screenshot-surface'),
        child: AiAssistantLauncher(child: child ?? const SizedBox.shrink()),
      ),
    ),
  );
}

void _configureWidgetsSpoTheme() {
  spo_theme.textPrimaryColorGlobal = Colors.white;
  spo_theme.textSecondaryColorGlobal = const Color(0xFFA4C0E6);
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };
}
