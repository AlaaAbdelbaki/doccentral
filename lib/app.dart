import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/providers/locale_provider.dart';
import 'package:docentral/shared/data/router/app_router.dart';
import 'package:docentral/shared/design_system/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DocCentralApp extends ConsumerWidget {
  const DocCentralApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Locale locale = ref.watch(appLocaleProvider);
    final GoRouter router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'DocCentral',
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
