import 'package:docentral/shared/data/router/permission_route_guard.dart';
import 'package:docentral/shared/domain/exceptions/permission_denied_exception.dart';
import 'package:docentral/shared/domain/rbac/permission.dart';
import 'package:docentral/shared/domain/rbac/permission_checker.dart';
import 'package:docentral/shared/domain/rbac/permission_checker_service.dart';
import 'package:docentral/shared/domain/rbac/permission_guard.dart';
import 'package:docentral/shared/domain/rbac/role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Doctor-restricted permissions', () {
    const doctorOnly = [
      Permission.canManageClinic,
      Permission.canManageStaff,
      Permission.canAssignRoles,
      Permission.canViewFinances,
      Permission.canUnlockVisit,
    ];

    test('doctor has all 5 restricted permissions', () {
      for (final p in doctorOnly) {
        expect(hasPermission(Role.doctor, p), isTrue, reason: '$p');
      }
    });

    test('assistant lacks all 5 restricted permissions', () {
      for (final p in doctorOnly) {
        expect(hasPermission(Role.assistant, p), isFalse, reason: '$p');
      }
    });

    test('nurse lacks all 5 restricted permissions', () {
      for (final p in doctorOnly) {
        expect(hasPermission(Role.nurse, p), isFalse, reason: '$p');
      }
    });
  });

  group('Shared permissions', () {
    test('doctor and assistant can create patients, nurse cannot', () {
      expect(hasPermission(Role.doctor, Permission.canCreatePatient), isTrue);
      expect(hasPermission(Role.assistant, Permission.canCreatePatient), isTrue);
      expect(hasPermission(Role.nurse, Permission.canCreatePatient), isFalse);
    });

    test('all roles can view patients', () {
      for (final role in Role.values) {
        expect(hasPermission(role, Permission.canViewPatients), isTrue, reason: '$role');
      }
    });
  });

  group('Layer 1 — Router guard uses hasPermission', () {
    test('allows access when role has permission', () {
      final redirect = permissionRouteGuard(
        role: Role.doctor,
        required: Permission.canManageClinic,
        redirectTo: '/unauthorized',
      );
      expect(redirect, isNull);
    });

    test('redirects when role lacks permission', () {
      final redirect = permissionRouteGuard(
        role: Role.assistant,
        required: Permission.canManageClinic,
        redirectTo: '/unauthorized',
      );
      expect(redirect, '/unauthorized');
    });

    test('redirects when no user is authenticated', () {
      final redirect = permissionRouteGuard(
        role: null,
        required: Permission.canViewPatients,
        redirectTo: '/login',
      );
      expect(redirect, '/login');
    });
  });

  group('Layer 2 — PermissionCheckerService uses hasPermission', () {
    test('returns true for permitted role', () {
      final checker = const PermissionCheckerService(Role.doctor);
      expect(checker(Permission.canViewFinances), isTrue);
    });

    test('returns false for unpermitted role', () {
      final checker = const PermissionCheckerService(Role.nurse);
      expect(checker(Permission.canViewFinances), isFalse);
    });

    test('returns false when role is null (unauthenticated)', () {
      final checker = const PermissionCheckerService(null);
      expect(checker(Permission.canViewPatients), isFalse);
    });
  });

  group('Layer 3 — Domain requirePermission uses hasPermission', () {
    test('does not throw when role has permission', () {
      expect(
        () => requirePermission(Role.doctor, Permission.canManageStaff),
        returnsNormally,
      );
    });

    test('throws PermissionDeniedException when role lacks permission', () {
      expect(
        () => requirePermission(Role.assistant, Permission.canManageStaff),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('exception carries the denied permission', () {
      try {
        requirePermission(Role.nurse, Permission.canUnlockVisit);
        fail('expected exception');
      } on PermissionDeniedException catch (e) {
        expect(e.permission, Permission.canUnlockVisit);
      }
    });
  });
}
