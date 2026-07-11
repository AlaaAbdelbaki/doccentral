import 'package:docentral/features/clinic/presentation/providers/add_staff_user_controller_provider.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/design_system/app_spacing.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'widgets/add_staff_user_form.dart';

class AddStaffUserPage extends ConsumerWidget {
  const AddStaffUserPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AsyncValue<void> state = ref.watch(addStaffUserControllerProvider);

    ref.listen<AsyncValue<void>>(addStaffUserControllerProvider, (
      AsyncValue<void>? previous,
      AsyncValue<void> next,
    ) {
      if (previous is! AsyncLoading<void>) return;
      next.when(
        data: (_) => context.pop(),
        error: (Object error, StackTrace stackTrace) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.addStaffError)));
        },
        loading: () {},
      );
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.addStaffTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: _AddStaffUserForm(
              isSubmitting: state.isLoading,
              onSubmit: (AddStaffUserFormResult result) {
                ref
                    .read(addStaffUserControllerProvider.notifier)
                    .addStaffUser(
                      firstName: result.firstName,
                      lastName: result.lastName,
                      email: result.email,
                      password: result.password,
                      role: result.role,
                    );
              },
            ),
          ),
        ),
      ),
    );
  }
}
