import 'package:flutter_test/flutter_test.dart';
import 'package:astina/features/auth/data/models/user_model.dart';
import 'package:astina/features/auth/data/models/role_model.dart';
import 'package:astina/features/auth/data/models/resident_brief_model.dart';

void main() {
  group('UserModel', () {
    group('fromJson', () {
      test('parses authenticated user correctly', () {
        final user = UserModel.fromJson(_wargaUserJson());

        expect(user.id, 1);
        expect(user.phone, '081234567890');
        expect(user.email, 'user@example.com');
        expect(user.isActive, true);
        expect(user.roles.length, 1);
        expect(user.roles.first.code, 'warga');
        expect(user.roles.first.name, 'Warga');
        expect(user.resident?.id, 15);
        expect(user.resident?.fullName, 'Budi Santoso');
      });

      test('parses with null email without throwing', () {
        final user = UserModel.fromJson(_userWithNullEmail());

        expect(user.email, isNull);
        expect(user.id, 2);
      });

      test('parses with empty roles without throwing', () {
        final user = UserModel.fromJson(_userWithEmptyRoles());

        expect(user.roles, isEmpty);
        expect(user.resident, isNull);
      });

      test('parses with null resident without throwing', () {
        final user = UserModel.fromJson(_userWithNullResident());

        expect(user.resident, isNull);
      });

      test('parses multi-role user correctly', () {
        final user = UserModel.fromJson(_multiRoleUserJson());

        expect(user.roles.length, 2);
        expect(user.roles.any((r) => r.code == 'rt'), true);
        expect(user.roles.any((r) => r.code == 'bendahara'), true);
      });

      test('round-trips to JSON correctly', () {
        final user = UserModel.fromJson(_wargaUserJson());
        final json = user.toJson();

        expect(json['id'], 1);
        expect(json['phone'], '081234567890');
        expect((json['roles'] as List).length, 1);
        expect((json['roles'] as List).first['code'], 'warga');
      });

      test('toJsonString and fromJsonString round-trip', () {
        final user = UserModel.fromJson(_multiRoleUserJson());
        final restored = UserModel.fromJsonString(user.toJsonString());

        expect(restored.id, user.id);
        expect(restored.roles.length, user.roles.length);
        expect(restored.roles.first.code, user.roles.first.code);
      });
    });

    group('role helpers', () {
      test('warga user has warga role', () {
        final user = UserModel.fromJson(_wargaUserJson());

        expect(user.hasRoleWarga, true);
        expect(user.hasRoleRt, false);
        expect(user.hasRoleBendahara, false);
        expect(user.primaryRoleCode, 'warga');
      });

      test('RT user has RT role', () {
        final user = UserModel.fromJson(_rtUserJson());

        expect(user.hasRoleRt, true);
        expect(user.hasRoleWarga, false);
        expect(user.hasRoleBendahara, false);
        expect(user.primaryRoleCode, 'rt');
      });

      test('bendahara user has bendahara role', () {
        final user = UserModel.fromJson(_bendaharaUserJson());

        expect(user.hasRoleBendahara, true);
        expect(user.hasRoleWarga, false);
        expect(user.hasRoleRt, false);
        expect(user.primaryRoleCode, 'bendahara');
      });

      test('unknown role returns false for unlisted roles', () {
        final user = UserModel.fromJson(_wargaUserJson());

        expect(user.hasRoleRt, false);
        expect(user.hasRoleBendahara, false);
        expect(user.hasRoleWarga, true);
      });

      test('empty roles returns false for all role checks', () {
        final user = UserModel.fromJson(_userWithEmptyRoles());

        expect(user.hasRoleRt, false);
        expect(user.hasRoleBendahara, false);
        expect(user.hasRoleWarga, false);
        expect(user.primaryRoleCode, isNull);
      });
    });

    group('multi-role behavior', () {
      test('RT takes priority over warga when primaryRoleCode', () {
        final user = UserModel.fromJson(_rtAndWargaUserJson());

        expect(user.hasRoleRt, true);
        expect(user.hasRoleWarga, true);
        expect(user.primaryRoleCode, 'rt');
      });

      test('RT takes priority over bendahara when primaryRoleCode', () {
        final user = UserModel.fromJson(_rtAndBendaharaUserJson());

        expect(user.hasRoleRt, true);
        expect(user.hasRoleBendahara, true);
        expect(user.primaryRoleCode, 'rt');
      });

      test('bendahara takes priority over warga when primaryRoleCode', () {
        final user = UserModel.fromJson(_bendaharaAndWargaUserJson());

        expect(user.hasRoleBendahara, true);
        expect(user.hasRoleWarga, true);
        expect(user.primaryRoleCode, 'bendahara');
      });

      test('multi-role user does not have unassigned roles', () {
        final user = UserModel.fromJson(_rtAndBendaharaUserJson());

        expect(user.hasRoleWarga, false);
      });
    });
  });

  group('RoleModel', () {
    test('parses from JSON correctly', () {
      final role = RoleModel.fromJson({
        'id': 3,
        'name': 'Warga',
        'code': 'warga',
      });

      expect(role.id, 3);
      expect(role.name, 'Warga');
      expect(role.code, 'warga');
    });
  });

  group('ResidentBriefModel', () {
    test('parses from JSON correctly', () {
      final resident = ResidentBriefModel.fromJson({
        'id': 15,
        'full_name': 'Budi Santoso',
      });

      expect(resident.id, 15);
      expect(resident.fullName, 'Budi Santoso');
    });
  });
}

// ---- Fixtures ----

Map<String, dynamic> _wargaUserJson() => {
  'id': 1,
  'phone': '081234567890',
  'email': 'user@example.com',
  'is_active': true,
  'roles': [
    {'id': 3, 'name': 'Warga', 'code': 'warga'},
  ],
  'resident': {'id': 15, 'full_name': 'Budi Santoso'},
};

Map<String, dynamic> _rtUserJson() => {
  'id': 2,
  'phone': '081200000001',
  'email': 'rt@example.com',
  'is_active': true,
  'roles': [
    {'id': 1, 'name': 'RT', 'code': 'rt'},
  ],
  'resident': {'id': 1, 'full_name': 'Pak RT'},
};

Map<String, dynamic> _bendaharaUserJson() => {
  'id': 3,
  'phone': '081200000002',
  'email': 'bendahara@example.com',
  'is_active': true,
  'roles': [
    {'id': 2, 'name': 'Bendahara', 'code': 'bendahara'},
  ],
  'resident': {'id': 2, 'full_name': 'Bendahara Satu'},
};

Map<String, dynamic> _userWithNullEmail() => {
  'id': 2,
  'phone': '081200000000',
  'email': null,
  'is_active': true,
  'roles': [
    {'id': 3, 'name': 'Warga', 'code': 'warga'},
  ],
  'resident': {'id': 16, 'full_name': 'Anonymous User'},
};

Map<String, dynamic> _userWithEmptyRoles() => {
  'id': 2,
  'phone': '081200000000',
  'email': null,
  'is_active': true,
  'roles': [],
  'resident': null,
};

Map<String, dynamic> _userWithNullResident() => {
  'id': 3,
  'phone': '081200000003',
  'email': 'noresident@example.com',
  'is_active': true,
  'roles': [
    {'id': 3, 'name': 'Warga', 'code': 'warga'},
  ],
  'resident': null,
};

Map<String, dynamic> _multiRoleUserJson() => {
  'id': 10,
  'phone': '081200000010',
  'email': 'multi@example.com',
  'is_active': true,
  'roles': [
    {'id': 1, 'name': 'RT', 'code': 'rt'},
    {'id': 2, 'name': 'Bendahara', 'code': 'bendahara'},
  ],
  'resident': {'id': 10, 'full_name': 'Multi Role User'},
};

Map<String, dynamic> _rtAndWargaUserJson() => {
  'id': 11,
  'phone': '081200000011',
  'email': 'rtwarga@example.com',
  'is_active': true,
  'roles': [
    {'id': 1, 'name': 'RT', 'code': 'rt'},
    {'id': 3, 'name': 'Warga', 'code': 'warga'},
  ],
  'resident': {'id': 11, 'full_name': 'RT Warga'},
};

Map<String, dynamic> _rtAndBendaharaUserJson() => {
  'id': 12,
  'phone': '081200000012',
  'email': 'rtbendahara@example.com',
  'is_active': true,
  'roles': [
    {'id': 1, 'name': 'RT', 'code': 'rt'},
    {'id': 2, 'name': 'Bendahara', 'code': 'bendahara'},
  ],
  'resident': {'id': 12, 'full_name': 'RT Bendahara'},
};

Map<String, dynamic> _bendaharaAndWargaUserJson() => {
  'id': 13,
  'phone': '081200000013',
  'email': 'bendharawarga@example.com',
  'is_active': true,
  'roles': [
    {'id': 2, 'name': 'Bendahara', 'code': 'bendahara'},
    {'id': 3, 'name': 'Warga', 'code': 'warga'},
  ],
  'resident': {'id': 13, 'full_name': 'Bendahara Warga'},
};
