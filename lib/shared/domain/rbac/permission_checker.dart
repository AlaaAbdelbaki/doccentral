import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/role.dart';

const _doctorPermissions = {
  ...assistantPermissions,
  Permission.canManageClinic,
  Permission.canManageStaff,
  Permission.canAssignRoles,
  Permission.canViewFinances,
  Permission.canUnlockVisit,
};

const assistantPermissions = {
  ...nursePermissions,
  Permission.canCreatePatient,
  Permission.canEditPatient,
  Permission.canCreateVisit,
  Permission.canEditVisit,
  Permission.canCompleteVisit,
  Permission.canCreateInvoice,
  Permission.canEditInvoice,
  Permission.canRecordPayment,
  Permission.canManageAppointments,
  Permission.canCheckInPatient,
};

const nursePermissions = {
  Permission.canViewPatients,
  Permission.canViewVisits,
  Permission.canViewAppointments,
  Permission.canAddClinicalNotes,
};

const _matrix = {
  Role.doctor: _doctorPermissions,
  Role.assistant: assistantPermissions,
  Role.nurse: nursePermissions,
};

/// Single source of truth for all permission checks.
/// All three enforcement layers (router, provider, domain) MUST call this function.
bool hasPermission(Role role, Permission permission) {
  return _matrix[role]?.contains(permission) ?? false;
}
