import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:astina/core/constants/api_constants.dart';
import 'package:astina/features/auth/data/datasources/auth_remote_data_source.dart';
import '../../../../test/mocks/auth_mocks.mocks.dart';
import '../../../../test/fixtures/auth_fixtures.dart';

void main() {
  late MockDioClient mockDioClient;
  late AuthRemoteDataSource ds;

  setUp(() {
    mockDioClient = MockDioClient();
    ds = AuthRemoteDataSource(mockDioClient);
  });

  group('AuthRemoteDataSource', () {
    group('login', () {
      test('returns token and user on login success', () async {
        final userJson = {
          'id': 1,
          'phone': '081234567890',
          'email': 'user@example.com',
          'is_active': true,
          'roles': [
            {'id': 3, 'name': 'Warga', 'code': 'warga'},
          ],
          'resident': {'id': 15, 'full_name': 'Budi Santoso'},
        };

        when(
          mockDioClient.post(
            ApiConstants.login,
            data: {'phone': '081234567890', 'password': 'Password123!'},
          ),
        ).thenAnswer(
          (_) async => mockLoginSuccessResponse(
            token: 'dummy-test-token',
            userJson: userJson,
          ),
        );

        final (token, user) = await ds.login(
          phone: '081234567890',
          password: 'Password123!',
        );

        expect(token, 'dummy-test-token');
        expect(user.id, 1);
        expect(user.roles.first.code, 'warga');
        verify(
          mockDioClient.post(
            ApiConstants.login,
            data: {'phone': '081234567890', 'password': 'Password123!'},
          ),
        ).called(1);
      });

      test('throws ApiException on 401 login failure', () async {
        when(
          mockDioClient.post(
            ApiConstants.login,
            data: {'phone': '081234567890', 'password': 'wrongpassword'},
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ApiConstants.login),
            response: Response(
              requestOptions: RequestOptions(path: ApiConstants.login),
              statusCode: 401,
              data: {'message': 'Nomor HP atau password salah.'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => ds.login(phone: '081234567890', password: 'wrongpassword'),
          throwsA(isA<ApiException>()),
        );
      });

      test('throws ApiException on 422 validation error', () async {
        when(
          mockDioClient.post(
            ApiConstants.login,
            data: {'phone': '', 'password': ''},
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ApiConstants.login),
            response: Response(
              requestOptions: RequestOptions(path: ApiConstants.login),
              statusCode: 422,
              data: {
                'message': 'Validasi gagal.',
                'errors': {
                  'phone': ['Nomor HP wajib diisi.'],
                },
              },
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => ds.login(phone: '', password: ''),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 422),
          ),
        );
      });

      test('throws ApiException on 500 server error', () async {
        when(
          mockDioClient.post(
            ApiConstants.login,
            data: {'phone': '081234567890', 'password': 'Password123!'},
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ApiConstants.login),
            response: Response(
              requestOptions: RequestOptions(path: ApiConstants.login),
              statusCode: 500,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => ds.login(phone: '081234567890', password: 'Password123!'),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
          ),
        );
      });
    });

    group('logout', () {
      test('completes successfully on 204 No Content', () async {
        when(
          mockDioClient.post(ApiConstants.logout),
        ).thenAnswer((_) async => mockLogout204Response());

        await expectLater(ds.logout(), completes);

        verify(mockDioClient.post(ApiConstants.logout)).called(1);
      });

      test(
        'completes without throwing on 401 (already unauthenticated)',
        () async {
          when(mockDioClient.post(ApiConstants.logout)).thenThrow(
            DioException(
              requestOptions: RequestOptions(path: ApiConstants.logout),
              response: Response(
                requestOptions: RequestOptions(path: ApiConstants.logout),
                statusCode: 401,
              ),
              type: DioExceptionType.badResponse,
            ),
          );

          await expectLater(ds.logout(), completes);
        },
      );

      test('throws ApiException on 500 server error', () async {
        when(mockDioClient.post(ApiConstants.logout)).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ApiConstants.logout),
            response: Response(
              requestOptions: RequestOptions(path: ApiConstants.logout),
              statusCode: 500,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(() => ds.logout(), throwsA(isA<ApiException>()));
      });
    });

    group('getMe', () {
      test('returns UserModel on success', () async {
        final userJson = {
          'id': 1,
          'phone': '081234567890',
          'email': 'user@example.com',
          'is_active': true,
          'roles': [
            {'id': 1, 'name': 'RT', 'code': 'rt'},
          ],
          'resident': {'id': 15, 'full_name': 'Pak RT'},
        };

        when(
          mockDioClient.get(ApiConstants.me),
        ).thenAnswer((_) async => mockMeSuccessResponse(userJson: userJson));

        final user = await ds.getMe();

        expect(user.id, 1);
        expect(user.roles.first.code, 'rt');
        verify(mockDioClient.get(ApiConstants.me)).called(1);
      });

      test('throws ApiException on 401 unauthenticated', () async {
        when(mockDioClient.get(ApiConstants.me)).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: ApiConstants.me),
            response: Response(
              requestOptions: RequestOptions(path: ApiConstants.me),
              statusCode: 401,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => ds.getMe(),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
          ),
        );
      });

      test('maps roles and resident correctly on getMe', () async {
        final userJson = {
          'id': 5,
          'phone': '081200000005',
          'email': 'multi@example.com',
          'is_active': true,
          'roles': [
            {'id': 1, 'name': 'RT', 'code': 'rt'},
            {'id': 2, 'name': 'Bendahara', 'code': 'bendahara'},
          ],
          'resident': {'id': 5, 'full_name': 'Multi User'},
        };

        when(
          mockDioClient.get(ApiConstants.me),
        ).thenAnswer((_) async => mockMeSuccessResponse(userJson: userJson));

        final user = await ds.getMe();

        expect(user.hasRoleRt, true);
        expect(user.hasRoleBendahara, true);
        expect(user.hasRoleWarga, false);
        expect(user.primaryRoleCode, 'rt');
        expect(user.resident?.fullName, 'Multi User');
      });
    });
  });

  group('ApiException', () {
    test('contains message and statusCode', () {
      final ex = ApiException('Test error', statusCode: 422);

      expect(ex.message, 'Test error');
      expect(ex.statusCode, 422);
    });

    test('contains errors map on 422', () {
      final ex = ApiException(
        'Validasi gagal.',
        statusCode: 422,
        errors: {
          'phone': ['Nomor HP wajib diisi.'],
        },
      );

      expect(ex.errors?['phone']?.first, 'Nomor HP wajib diisi.');
    });
  });
}
