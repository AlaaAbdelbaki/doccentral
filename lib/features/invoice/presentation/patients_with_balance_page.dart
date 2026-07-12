import 'package:docentral/features/invoice/domain/patient_balance.dart';
import 'package:docentral/features/invoice/presentation/providers/patients_with_balance_provider.dart';
import 'package:docentral/features/patient/presentation/providers/selected_patient_provider.dart';
import 'package:docentral/l10n/app_localizations.dart';
import 'package:docentral/shared/data/router/app_routes.dart';
import 'package:docentral/shared/design_system/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

enum _SortMode { balanceDescending, daysSinceLastPaymentDescending }

class PatientsWithBalancePage extends ConsumerStatefulWidget {
  const PatientsWithBalancePage({super.key});

  @override
  ConsumerState<PatientsWithBalancePage> createState() =>
      _PatientsWithBalancePageState();
}

class _PatientsWithBalancePageState
    extends ConsumerState<PatientsWithBalancePage> {
  _SortMode _sortMode = _SortMode.balanceDescending;

  int _daysSinceLastPayment(PatientBalance balance) {
    final DateTime? lastPaymentDate = balance.lastPaymentDate;
    if (lastPaymentDate == null) return 999999;
    return DateTime.now().difference(lastPaymentDate).inDays;
  }

  List<PatientBalance> _sorted(List<PatientBalance> balances) {
    final List<PatientBalance> sorted = List<PatientBalance>.of(balances);
    switch (_sortMode) {
      case _SortMode.balanceDescending:
        sorted.sort(
          (PatientBalance a, PatientBalance b) =>
              b.balance.compareTo(a.balance),
        );
      case _SortMode.daysSinceLastPaymentDescending:
        sorted.sort(
          (PatientBalance a, PatientBalance b) =>
              _daysSinceLastPayment(b).compareTo(_daysSinceLastPayment(a)),
        );
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final AsyncValue<List<PatientBalance>> balancesAsync = ref.watch(
      patientsWithBalanceProvider,
    );
    final NumberFormat currency = NumberFormat.currency(
      symbol: 'TND',
      decimalDigits: 3,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.patientsWithBalancePageTitle),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: DropdownButton<_SortMode>(
              value: _sortMode,
              items: <DropdownMenuItem<_SortMode>>[
                DropdownMenuItem<_SortMode>(
                  value: _SortMode.balanceDescending,
                  child: Text(l10n.patientsWithBalanceSortByBalance),
                ),
                DropdownMenuItem<_SortMode>(
                  value: _SortMode.daysSinceLastPaymentDescending,
                  child: Text(
                    l10n.patientsWithBalanceSortByDaysSinceLastPayment,
                  ),
                ),
              ],
              onChanged: (_SortMode? value) {
                if (value != null) setState(() => _sortMode = value);
              },
            ),
          ),
        ],
      ),
      body: balancesAsync.when(
        data: (List<PatientBalance> balances) {
          if (balances.isEmpty) {
            return Center(child: Text(l10n.patientsWithBalanceEmptyState));
          }
          final List<PatientBalance> sorted = _sorted(balances);
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: sorted.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(height: AppSpacing.sm),
            itemBuilder: (BuildContext context, int index) {
              final PatientBalance balance = sorted[index];
              final int daysSinceLastPayment = _daysSinceLastPayment(balance);
              return Card(
                child: ListTile(
                  title: Text(
                    '${balance.patient.firstName} ${balance.patient.lastName}',
                  ),
                  subtitle: balance.lastPaymentDate == null
                      ? Text(l10n.patientsWithBalanceNoPaymentYet)
                      : Text(
                          l10n.patientsWithBalanceDaysSinceLastPayment(
                            daysSinceLastPayment,
                          ),
                        ),
                  trailing: Text(
                    currency.format(balance.balance),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  onTap: () {
                    ref
                        .read(selectedPatientProvider.notifier)
                        .select(balance.patient);
                    context.goNamed(AppRoutes.patients.name);
                  },
                ),
              );
            },
          );
        },
        error: (Object error, StackTrace stackTrace) =>
            Center(child: Text('$error')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
