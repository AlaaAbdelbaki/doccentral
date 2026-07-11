import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/providers/auth_service_provider.dart';
import 'package:docentral/shared/data/providers/current_role_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(l10n.navSettings),
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
