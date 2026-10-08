import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaundia_app/core/network/api_client.dart';
import 'package:kaundia_app/core/network/api_exception.dart';
import 'package:kaundia_app/features/superadmin/data/rbac_repository.dart';
import 'package:kaundia_app/features/superadmin/domain/rbac_entities.dart';
import 'package:kaundia_app/features/superadmin/presentation/bloc/rbac_bloc.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

const _permissions = [
  PermissionDef(key: 'members_view', resource: 'members', action: 'view', description: 'View members'),
  PermissionDef(key: 'members_edit', resource: 'members', action: 'edit', description: 'Edit members'),
  PermissionDef(key: 'roles_view', resource: 'roles', action: 'view', description: 'View roles'),
];

RoleDef _role(String id, String name, List<String> keys) =>
    RoleDef(id: id, name: name, description: null, permissionKeys: keys);

final _roleAdministrator = _role('2', 'administrator', ['members_view']);
final _roleSuperAdmin = _role('1', 'super_admin', const []);

final _user = AdminUser(
  id: '7',
  name: 'Karim',
  email: 'karim@example.com',
  role: 'administrator',
  roleId: '2',
);

void _stubBase(
  _MockApiClient client, {
  List<AdminUser> users = const [],
  List<Map<String, dynamic>> overrides = const [],
}) {
  when(() => client.getUri('/admin/rbac/permissions'))
      .thenAnswer((_) async => [for (final p in _permissions) _permissionJson(p)]);
  when(() => client.getUri('/admin/rbac/roles')).thenAnswer((_) async => [
        _roleJson(_roleSuperAdmin),
        _roleJson(_roleAdministrator),
      ]);
  when(() => client.getUri('/admin/rbac/users'))
      .thenAnswer((_) async => [for (final u in users) _userJson(u)]);
  if (users.isNotEmpty) {
    when(() => client.getUri('/admin/rbac/users/${users.first.id}/overrides'))
        .thenAnswer((_) async => overrides);
  }
}

Map<String, dynamic> _permissionJson(PermissionDef p) => {
      'key': p.key,
      'resource': p.resource,
      'action': p.action,
      'description': p.description,
    };

Map<String, dynamic> _roleJson(RoleDef r) => {
      'id': int.parse(r.id),
      'name': r.name,
      'description': r.description,
      'permission_keys': r.permissionKeys,
    };

Map<String, dynamic> _userJson(AdminUser u) => {
      'id': int.parse(u.id),
      'name': u.name,
      'email': u.email,
      'role': u.role,
      'role_id': u.roleId == null ? null : int.parse(u.roleId!),
    };

/// Emitted in order by a successful RbacStarted with no users loaded.
final List<Matcher> _startStates = [
  isA<RbacState>().having((s) => s.status, 'status', RbacStatus.loading),
  isA<RbacState>().having((s) => s.status, 'status', RbacStatus.ready),
];

void main() {
  late _MockApiClient client;

  setUp(() {
    client = _MockApiClient();
  });

  group('RbacBloc — permission matrix save flow', () {
    blocTest<RbacBloc, RbacState>(
      'loads data, toggles a draft permission and saves via PUT',
      setUp: () {
        _stubBase(client);
        when(() => client.put('/admin/rbac/roles/2/permissions', any(that: equals({
              'permission_keys': ['members_view', 'roles_view'],
            })))).thenAnswer(
            (_) async => _roleJson(_role('2', 'administrator', ['members_view', 'roles_view'])));
      },
      build: () => RbacBloc(RbacRepository(client)),
      act: (bloc) async {
        bloc.add(const RbacStarted());
        await pumpEventQueue();
        bloc.add(const RbacRoleSelected('2'));
        bloc.add(const RbacPermissionToggled('roles_view'));
        bloc.add(const RbacMatrixSaveRequested());
        await pumpEventQueue();
      },
      expect: () => [
        ..._startStates,
        // role selected -> draft reset to the administrator role's keys
        isA<RbacState>()
            .having((s) => s.selectedRoleId, 'selectedRoleId', '2')
            .having((s) => s.draftKeys, 'draftKeys', {'members_view'}),
        // toggle
        isA<RbacState>().having((s) => s.draftKeys, 'draftKeys', {'members_view', 'roles_view'}),
        // saving
        isA<RbacState>().having((s) => s.savingMatrix, 'savingMatrix', true),
        // saved: roles list updated, saving flag cleared
        isA<RbacState>()
            .having((s) => s.savingMatrix, 'savingMatrix', false)
            .having((s) => s.matrixSaveError, 'matrixSaveError', false)
            .having(
                (s) => s.roles.where((r) => r.id == '2').single.permissionKeys,
                'updated role keys',
                ['members_view', 'roles_view']),
      ],
      verify: (_) {
        verify(() => client.put('/admin/rbac/roles/2/permissions', any(that: equals({
              'permission_keys': ['members_view', 'roles_view'],
            })))).called(1);
      },
    );

    blocTest<RbacBloc, RbacState>(
      'super_admin role cannot be saved',
      setUp: () {
        _stubBase(client);
      },
      build: () => RbacBloc(RbacRepository(client)),
      act: (bloc) async {
        bloc.add(const RbacStarted());
        await pumpEventQueue();
        bloc.add(const RbacRoleSelected('1'));
        bloc.add(const RbacMatrixSaveRequested());
        await pumpEventQueue();
      },
      expect: () => [..._startStates],
      verify: (bloc) {
        // Selecting the super_admin role is a no-op emit-wise (same keys), but
        // the role is locked and no PUT may happen.
        expect(bloc.state.selectedRoleId, '1');
        expect(bloc.state.selectedRole!.isSuperAdmin, isTrue);
        verifyNever(() => client.put(any(), any()));
      },
    );

    blocTest<RbacBloc, RbacState>(
      'matrix save failure surfaces matrixSaveError with saveChange kind',
      setUp: () {
        _stubBase(client);
        when(() => client.put(any(), any()))
            .thenThrow(const ApiException(type: ApiExceptionType.server));
      },
      build: () => RbacBloc(RbacRepository(client)),
      act: (bloc) async {
        bloc.add(const RbacStarted());
        await pumpEventQueue();
        bloc.add(const RbacRoleSelected('2'));
        bloc.add(const RbacPermissionToggled('roles_view'));
        bloc.add(const RbacMatrixSaveRequested());
        await pumpEventQueue();
      },
      expect: () => [
        ..._startStates,
        isA<RbacState>().having((s) => s.selectedRoleId, 'selectedRoleId', '2'),
        isA<RbacState>().having((s) => s.draftKeys, 'draftKeys', {'members_view', 'roles_view'}),
        isA<RbacState>().having((s) => s.savingMatrix, 'savingMatrix', true),
        isA<RbacState>()
            .having((s) => s.savingMatrix, 'savingMatrix', false)
            .having((s) => s.matrixSaveError, 'matrixSaveError', true)
            .having((s) => s.errorKind, 'errorKind', RbacErrorKind.saveChange),
      ],
    );
  });

  group('RbacBloc — load failures', () {
    blocTest<RbacBloc, RbacState>(
      'permission load failure sets failure status with loadPermissions kind',
      setUp: () {
        when(() => client.getUri('/admin/rbac/permissions'))
            .thenThrow(const ApiException(type: ApiExceptionType.network));
      },
      build: () => RbacBloc(RbacRepository(client)),
      act: (bloc) => bloc.add(const RbacStarted()),
      expect: () => [
        isA<RbacState>().having((s) => s.status, 'status', RbacStatus.loading),
        isA<RbacState>()
            .having((s) => s.status, 'status', RbacStatus.failure)
            .having((s) => s.errorKind, 'errorKind', RbacErrorKind.loadPermissions),
      ],
    );

    blocTest<RbacBloc, RbacState>(
      'role load failure sets failure status with loadRoles kind',
      setUp: () {
        when(() => client.getUri('/admin/rbac/permissions')).thenAnswer((_) async => const []);
        when(() => client.getUri('/admin/rbac/roles'))
            .thenThrow(const ApiException(type: ApiExceptionType.server));
      },
      build: () => RbacBloc(RbacRepository(client)),
      act: (bloc) => bloc.add(const RbacStarted()),
      expect: () => [
        isA<RbacState>().having((s) => s.status, 'status', RbacStatus.loading),
        isA<RbacState>()
            .having((s) => s.status, 'status', RbacStatus.failure)
            .having((s) => s.errorKind, 'errorKind', RbacErrorKind.loadRoles),
      ],
    );

    blocTest<RbacBloc, RbacState>(
      'user load failure keeps the page usable and flags loadUsers',
      setUp: () {
        when(() => client.getUri('/admin/rbac/permissions')).thenAnswer((_) async => const []);
        when(() => client.getUri('/admin/rbac/roles')).thenAnswer((_) async => const []);
        when(() => client.getUri('/admin/rbac/users'))
            .thenThrow(const ApiException(type: ApiExceptionType.network));
      },
      build: () => RbacBloc(RbacRepository(client)),
      act: (bloc) => bloc.add(const RbacStarted()),
      expect: () => [
        isA<RbacState>().having((s) => s.status, 'status', RbacStatus.loading),
        isA<RbacState>()
            .having((s) => s.status, 'status', RbacStatus.ready)
            .having((s) => s.hasUsers, 'hasUsers', false),
        isA<RbacState>().having((s) => s.errorKind, 'errorKind', RbacErrorKind.loadUsers),
      ],
    );
  });

  group('RbacBloc — users, role assignment and overrides', () {
    blocTest<RbacBloc, RbacState>(
      'assign role PATCHes and replaces the user in the list',
      setUp: () {
        _stubBase(client, users: [_user]);
        when(() => client.patch('/admin/rbac/users/7/role', any(that: equals({
              'role': 'super_admin',
              'role_id': null,
            })))).thenAnswer((_) async => _userJson(const AdminUser(
              id: '7',
              name: 'Karim',
              email: 'karim@example.com',
              role: 'super_admin',
              roleId: null,
            )));
      },
      build: () => RbacBloc(RbacRepository(client)),
      act: (bloc) async {
        bloc.add(const RbacStarted());
        await pumpEventQueue();
        bloc.add(const RbacRoleAssignDraftChanged('super_admin'));
        bloc.add(const RbacRoleAssignSubmitted());
        await pumpEventQueue();
      },
      expect: () => [
        ..._startStates,
        // overrides loading + ready for the first user
        isA<RbacState>().having((s) => s.overridesStatus, 'overridesStatus', OverridesStatus.loading),
        isA<RbacState>().having((s) => s.overridesStatus, 'overridesStatus', OverridesStatus.ready),
        isA<RbacState>().having((s) => s.roleAssignDraft, 'roleAssignDraft', 'super_admin'),
        isA<RbacState>().having((s) => s.savingRoleAssign, 'savingRoleAssign', true),
        isA<RbacState>()
            .having((s) => s.savingRoleAssign, 'savingRoleAssign', false)
            .having((s) => s.users.single.role, 'updated role', 'super_admin'),
      ],
    );

    blocTest<RbacBloc, RbacState>(
      'create user appends to the list and reports the email',
      setUp: () {
        _stubBase(client, users: [_user]);
        when(() => client.post('/admin/rbac/users', any(that: equals({
              'name': 'New Admin',
              'email': 'new@example.com',
              'password': 'secret',
              'role': 'administrator',
              'role_id': null,
            })))).thenAnswer((_) async => {
              'id': 9,
              'name': 'New Admin',
              'email': 'new@example.com',
              'role': 'administrator',
              'role_id': null,
            });
      },
      build: () => RbacBloc(RbacRepository(client)),
      act: (bloc) async {
        bloc.add(const RbacStarted());
        await pumpEventQueue();
        bloc.add(const RbacCreateUserSubmitted(
          name: 'New Admin',
          email: 'new@example.com',
          password: 'secret',
          role: AdminRoleName.administrator,
        ));
        await pumpEventQueue();
      },
      expect: () => [
        ..._startStates,
        isA<RbacState>().having((s) => s.overridesStatus, 'overridesStatus', OverridesStatus.loading),
        isA<RbacState>().having((s) => s.overridesStatus, 'overridesStatus', OverridesStatus.ready),
        isA<RbacState>().having((s) => s.creatingUser, 'creatingUser', true),
        isA<RbacState>()
            .having((s) => s.creatingUser, 'creatingUser', false)
            .having((s) => s.createUserSuccess, 'createUserSuccess', 'new@example.com')
            .having((s) => s.users.length, 'users.length', 2),
      ],
    );

    blocTest<RbacBloc, RbacState>(
      'create user business error surfaces the businessMessage',
      setUp: () {
        _stubBase(client, users: [_user]);
        when(() => client.post(any(), any())).thenThrow(const ApiException(
          type: ApiExceptionType.business,
          statusCode: 400,
          businessMessage: 'Email already exists',
        ));
      },
      build: () => RbacBloc(RbacRepository(client)),
      act: (bloc) async {
        bloc.add(const RbacStarted());
        await pumpEventQueue();
        bloc.add(const RbacCreateUserSubmitted(
          name: 'New Admin',
          email: 'new@example.com',
          password: 'secret',
          role: AdminRoleName.administrator,
        ));
        await pumpEventQueue();
      },
      expect: () => [
        ..._startStates,
        isA<RbacState>().having((s) => s.overridesStatus, 'overridesStatus', OverridesStatus.loading),
        isA<RbacState>().having((s) => s.overridesStatus, 'overridesStatus', OverridesStatus.ready),
        isA<RbacState>().having((s) => s.creatingUser, 'creatingUser', true),
        isA<RbacState>()
            .having((s) => s.creatingUser, 'creatingUser', false)
            .having((s) => s.createUserError, 'createUserError', 'Email already exists'),
      ],
    );

    blocTest<RbacBloc, RbacState>(
      'apply override replaces same-key entries and PUTs the full list',
      setUp: () {
        _stubBase(client, users: [_user], overrides: [
          {'permission_key': 'roles_view', 'granted': true},
        ]);
        when(() => client.put('/admin/rbac/users/7/overrides', any(that: equals([
              {
                'permission_key': 'roles_view',
                'granted': false,
              },
            ])))).thenAnswer((_) async => [
              {'permission_key': 'roles_view', 'granted': false},
            ]);
      },
      build: () => RbacBloc(RbacRepository(client)),
      act: (bloc) async {
        bloc.add(const RbacStarted());
        await pumpEventQueue();
        bloc.add(const RbacOverrideDraftChanged(permissionKey: 'roles_view', granted: false));
        bloc.add(const RbacOverrideApplied(permissionKey: 'roles_view', granted: false));
        await pumpEventQueue();
      },
      expect: () => [
        ..._startStates,
        isA<RbacState>().having((s) => s.overridesStatus, 'overridesStatus', OverridesStatus.loading),
        isA<RbacState>()
            .having((s) => s.overridesStatus, 'overridesStatus', OverridesStatus.ready)
            .having((s) => s.overrides.single.permissionKey, 'override key', 'roles_view')
            .having((s) => s.overrideDraftKey, 'overrideDraftKey', 'members_view'),
        isA<RbacState>()
            .having((s) => s.overrideDraftKey, 'overrideDraftKey', 'roles_view')
            .having((s) => s.overrideDraftGranted, 'overrideDraftGranted', false),
        isA<RbacState>().having((s) => s.savingOverrides, 'savingOverrides', true),
        isA<RbacState>()
            .having((s) => s.savingOverrides, 'savingOverrides', false)
            .having((s) => s.overrides.single.granted, 'override granted', false),
      ],
    );

    blocTest<RbacBloc, RbacState>(
      'remove override deletes the entry via PUT',
      setUp: () {
        _stubBase(client, users: [_user], overrides: [
          {'permission_key': 'roles_view', 'granted': true},
        ]);
        when(() => client.put('/admin/rbac/users/7/overrides', any(that: equals([]))))
            .thenAnswer((_) async => []);
      },
      build: () => RbacBloc(RbacRepository(client)),
      act: (bloc) async {
        bloc.add(const RbacStarted());
        await pumpEventQueue();
        bloc.add(const RbacOverrideRemoved('roles_view'));
        await pumpEventQueue();
      },
      expect: () => [
        ..._startStates,
        isA<RbacState>().having((s) => s.overridesStatus, 'overridesStatus', OverridesStatus.loading),
        isA<RbacState>()
            .having((s) => s.overridesStatus, 'overridesStatus', OverridesStatus.ready)
            .having((s) => s.overrides.single.granted, 'override granted', true),
        isA<RbacState>().having((s) => s.savingOverrides, 'savingOverrides', true),
        isA<RbacState>()
            .having((s) => s.savingOverrides, 'savingOverrides', false)
            .having((s) => s.overrides, 'overrides', isEmpty),
      ],
    );
  });
}
