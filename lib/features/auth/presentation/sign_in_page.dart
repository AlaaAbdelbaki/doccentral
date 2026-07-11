import 'package:docentral/features/auth/presentation/providers/sign_in_controller_provider.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/router/app_routes.dart';
import 'package:docentral/shared/design_system/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'widgets/sign_in_form.dart';

class SignInPage extends ConsumerWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AsyncValue<void> state = ref.watch(signInControllerProvider);

    ref.listen<AsyncValue<void>>(signInControllerProvider, (
      AsyncValue<void>? previous,
      AsyncValue<void> next,
    ) {
      if (previous is! AsyncLoading<void>) return;
      next.when(
        data: (_) => context.goNamed(AppRoutes.calendar.name),
        error: (Object error, StackTrace stackTrace) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.signInError)));
        },
        loading: () {},
      );
    });

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: _SignInForm(
              isSubmitting: state.isLoading,
              onSubmit: (String email, String password) {
                ref
                    .read(signInControllerProvider.notifier)
                    .signIn(email: email, password: password);
              },
            ),
          ),
        ),
      ),
    );
  }
}
