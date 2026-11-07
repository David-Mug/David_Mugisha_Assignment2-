import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';

/// Root widget: applies the theme and hands navigation to go_router.
///
/// It is a [ConsumerWidget] so it can `ref.watch` the router provider.
class CampusCareApp extends ConsumerWidget {
  const CampusCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
