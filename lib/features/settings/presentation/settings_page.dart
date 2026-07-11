import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/providers/auth_service_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:docentral/shared/data/providers/locale_provider.dart';
import 'package:docentral/shared/data/providers/permission_provider.dart';
import 'package:docentral/shared/data/router/app_routes.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static String _nativeLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      case 'ar':
        return 'العربية';
      default:
        return locale.languageCode;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool canManageStaff = ref.watch(permissionCheckerProvider)(
      Permission.canManageStaff,
    );
    final Locale currentLocale = ref.watch(appLocaleProvider);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(l10n.navSettings),
          const SizedBox(height: 16),
          DropdownButton<Locale>(
            value: currentLocale,
            onChanged: (Locale? locale) {
              if (locale != null) {
                ref.read(appLocaleProvider.notifier).setLocale(locale);
              }
            },
            items: <DropdownMenuItem<Locale>>[
              for (final Locale locale in supportedLocales)
                DropdownMenuItem<Locale>(
                  value: locale,
                  child: Text(_nativeLanguageName(locale)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (canManageStaff)
            OutlinedButton(
              onPressed: () => context.goNamed(AppRoutes.addStaffUser.name),
              child: Text(l10n.addStaffButton),
            ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              ref.read(currentRoleProvider.notifier).clear();
            },
            child: Text(l10n.settingsSignOut),
          ),
        ],
      ),
    );
  }
}
