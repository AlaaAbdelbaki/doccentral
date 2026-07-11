import 'package:docentral/features/clinic/presentation/providers/clinic_provisioning_controller_provider.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/router/app_routes.dart';
import 'package:docentral/shared/design_system/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'widgets/sign_up_form.dart';

class SignUpPage extends ConsumerWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AsyncValue<void> state = ref.watch(
      clinicProvisioningControllerProvider,
    );

    ref.listen<AsyncValue<void>>(clinicProvisioningControllerProvider, (
      AsyncValue<void>? previous,
      AsyncValue<void> next,
    ) {
      if (previous is! AsyncLoading<void>) return;
      next.when(
        data: (_) => context.goNamed(AppRoutes.calendar.name),
        error: (Object error, StackTrace stackTrace) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.signUpOfflineError)));
        },
        loading: () {},
      );
    });

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: _SignUpForm(
              isSubmitting: state.isLoading,
              onSubmit: (SignUpFormResult result) {
                ref
                    .read(clinicProvisioningControllerProvider.notifier)
                    .signUp(
                      clinicName: result.clinicName,
                      dentistFirstName: result.firstName,
                      dentistLastName: result.lastName,
                      email: result.email,
                      password: result.password,
                    );
              },
            ),
          ),
        ),
      ),
    );
  }
}
