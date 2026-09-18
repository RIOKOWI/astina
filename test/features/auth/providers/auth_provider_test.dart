import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:astina/core/services/auth_state.dart';
import 'package:astina/features/auth/providers/auth_provider.dart';
import 'package:astina/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:astina/core/injection/dependency_injection.dart';
import 'package:astina/core/services/router_refresh_notifier.dart';
import '../../../mocks/auth_mocks.mocks.dart';

/// A test notifier that bypasses async _init() by setting state synchronously in build().
/// This allows tests to control initial state without timing issues.
class _TestAuthNotifier extends AuthNotifier {
  @override
  AuthState build() {
    // Set initial unauthenticated state synchronously — no async _init() needed.
    state = const Unauthenticated();
    routerRefreshNotifier.update(state);
    return state;
  }
}

void main() {
  late MockDioClient mockDioClient;
  late MockSecureStorageService mockStorage;
  late ProviderContainer container;

  setUp(() {
    mockDioClient = MockDioClient();
    mockStorage = MockSecureStorageService();
    container = ProviderContainer(
      overrides: [
        dioClientProvider.overrideWithValue(mockDioClient),
        secureStorageProvider.overrideWithValue(mockStorage),
        authProvider.overrideWith(() => _TestAuthNotifier()),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthProvider', () {
    group('login', () {
      test('updates state to Authenticated on login success', () async {
        when(mockStorage.saveToken(any)).thenAnswer((_) async {});
        when(mockStorage.saveUser(any)).thenAnswer((_) async {});
        when(
          mockDioClient.post(
            '/auth/login',
            data: {'phone': '081234567890', 'password': 'Password123!'},
          ),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 200,
            data: {
              'success': true,
              'data': {'token': 'new-dummy-token', 'user': _wargaUserJson()},
            },
          ),
        );

        await container
            .read(authProvider.notifier)
            .login(phone: '081234567890', password: 'Password123!');

        final state = container.read(authProvider);
        expect(state.isAuthenticated, true);
        expect(state.user?.id, 1);
        expect(state.user?.phone, '081234567890');
      });

      test('saves token to storage on login success', () async {
        when(mockStorage.saveToken(any)).thenAnswer((_) async {});
        when(mockStorage.saveUser(any)).thenAnswer((_) async {});
        when(
          mockDioClient.post(
            '/auth/login',
            data: {'phone': '081234567890', 'password': 'Password123!'},
          ),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 200,
            data: {
              'success': true,
              'data': {'token': 'saved-token-xyz', 'user': _wargaUserJson()},
            },
          ),
        );

        await container
            .read(authProvider.notifier)
            .login(phone: '081234567890', password: 'Password123!');

        verify(mockStorage.saveToken('saved-token-xyz')).called(1);
      });

      test('throws ApiException on login failure', () async {
        when(
          mockDioClient.post(
            '/auth/login',
            data: {'phone': '081234567890', 'password': 'wrong'},
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/login'),
            response: Response(
              requestOptions: RequestOptions(path: '/auth/login'),
              statusCode: 401,
              data: {'message': 'Nomor HP atau password salah.'},
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        expect(
          () => container
              .read(authProvider.notifier)
              .login(phone: '081234567890', password: 'wrong'),
          throwsA(isA<ApiException>()),
        );
      });

      test('does not update auth state on login failure', () async {
        when(
          mockDioClient.post('/auth/login', data: anyNamed('data')),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/login'),
            response: Response(
              requestOptions: RequestOptions(path: '/auth/login'),
              statusCode: 401,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        try {
          await container
              .read(authProvider.notifier)
              .login(phone: '081234567890', password: 'wrong');
        } catch (_) {}

        final state = container.read(authProvider);
        expect(state.isAuthenticated, false);
      });
    });

    group('logout', () {
      test('updates state to Unauthenticated on logout', () async {
        when(mockStorage.saveToken(any)).thenAnswer((_) async {});
        when(mockStorage.saveUser(any)).thenAnswer((_) async {});
        when(mockStorage.clearAll()).thenAnswer((_) async {});
        when(
          mockDioClient.post('/auth/login', data: anyNamed('data')),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 200,
            data: {
              'success': true,
              'data': {'token': 'token', 'user': _wargaUserJson()},
            },
          ),
        );
        when(mockDioClient.post('/auth/logout')).thenAnswer(
          (_) async => Response<void>(
            requestOptions: RequestOptions(path: '/auth/logout'),
            statusCode: 204,
          ),
        );

        await container
            .read(authProvider.notifier)
            .login(phone: '081234567890', password: 'Password123!');
        expect(container.read(authProvider).isAuthenticated, true);

        await container.read(authProvider.notifier).logout();

        final state = container.read(authProvider);
        expect(state.isAuthenticated, false);
        expect(state.user, isNull);
      });

      test('clears secure storage on logout', () async {
        when(mockStorage.saveToken(any)).thenAnswer((_) async {});
        when(mockStorage.saveUser(any)).thenAnswer((_) async {});
        when(mockStorage.clearAll()).thenAnswer((_) async {});
        when(
          mockDioClient.post('/auth/login', data: anyNamed('data')),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 200,
            data: {
              'success': true,
              'data': {'token': 'token', 'user': _wargaUserJson()},
            },
          ),
        );
        when(mockDioClient.post('/auth/logout')).thenAnswer(
          (_) async => Response<void>(
            requestOptions: RequestOptions(path: '/auth/logout'),
            statusCode: 204,
          ),
        );

        await container
            .read(authProvider.notifier)
            .login(phone: '081234567890', password: 'Password123!');
        await container.read(authProvider.notifier).logout();

        verify(mockStorage.clearAll()).called(1);
      });

      test('clears storage even when logout API fails with 500', () async {
        when(mockStorage.saveToken(any)).thenAnswer((_) async {});
        when(mockStorage.saveUser(any)).thenAnswer((_) async {});
        when(mockStorage.clearAll()).thenAnswer((_) async {});
        when(
          mockDioClient.post('/auth/login', data: anyNamed('data')),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 200,
            data: {
              'success': true,
              'data': {'token': 'token', 'user': _wargaUserJson()},
            },
          ),
        );
        when(mockDioClient.post('/auth/logout')).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/auth/logout'),
            response: Response(
              requestOptions: RequestOptions(path: '/auth/logout'),
              statusCode: 500,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        await container
            .read(authProvider.notifier)
            .login(phone: '081234567890', password: 'Password123!');
        await container.read(authProvider.notifier).logout();

        verify(mockStorage.clearAll()).called(1);
        expect(container.read(authProvider).isAuthenticated, false);
      });
    });

    group('currentUserRoleProvider', () {
      test('returns warga when user has warga role', () async {
        when(mockStorage.saveToken(any)).thenAnswer((_) async {});
        when(mockStorage.saveUser(any)).thenAnswer((_) async {});
        when(
          mockDioClient.post('/auth/login', data: anyNamed('data')),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 200,
            data: {
              'success': true,
              'data': {'token': 'token', 'user': _wargaUserJson()},
            },
          ),
        );

        await container
            .read(authProvider.notifier)
            .login(phone: '081234567890', password: 'Password123!');

        expect(container.read(currentUserRoleProvider), UserRole.warga);
      });

      test('returns rt when user has rt role', () async {
        when(mockStorage.saveToken(any)).thenAnswer((_) async {});
        when(mockStorage.saveUser(any)).thenAnswer((_) async {});
        when(
          mockDioClient.post('/auth/login', data: anyNamed('data')),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 200,
            data: {
              'success': true,
              'data': {'token': 'token-rt', 'user': _rtUserJson()},
            },
          ),
        );

        await container
            .read(authProvider.notifier)
            .login(phone: '081200000001', password: 'Password123!');

        expect(container.read(currentUserRoleProvider), UserRole.rt);
      });

      test('returns unknown when user has no roles', () async {
        when(mockStorage.saveToken(any)).thenAnswer((_) async {});
        when(mockStorage.saveUser(any)).thenAnswer((_) async {});
        when(
          mockDioClient.post('/auth/login', data: anyNamed('data')),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 200,
            data: {
              'success': true,
              'data': {'token': 'token-norole', 'user': _noRoleUserJson()},
            },
          ),
        );

        await container
            .read(authProvider.notifier)
            .login(phone: '081299999999', password: 'Password123!');

        expect(container.read(currentUserRoleProvider), UserRole.unknown);
      });

      test('returns bendahara when user has bendahara role', () async {
        when(mockStorage.saveToken(any)).thenAnswer((_) async {});
        when(mockStorage.saveUser(any)).thenAnswer((_) async {});
        when(
          mockDioClient.post('/auth/login', data: anyNamed('data')),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 200,
            data: {
              'success': true,
              'data': {
                'token': 'token-bendahara',
                'user': _bendaharaUserJson(),
              },
            },
          ),
        );

        await container
            .read(authProvider.notifier)
            .login(phone: '081200000002', password: 'Password123!');

        expect(container.read(currentUserRoleProvider), UserRole.bendahara);
      });
    });

    group('AuthState', () {
      test('Authenticated exposes user after login', () async {
        when(mockStorage.saveToken(any)).thenAnswer((_) async {});
        when(mockStorage.saveUser(any)).thenAnswer((_) async {});
        when(
          mockDioClient.post('/auth/login', data: anyNamed('data')),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 200,
            data: {
              'success': true,
              'data': {'token': 'token', 'user': _wargaUserJson()},
            },
          ),
        );

        await container
            .read(authProvider.notifier)
            .login(phone: '081234567890', password: 'Password123!');

        final state = container.read(authProvider);
        expect(state.isAuthenticated, true);
        expect(state.user, isNotNull);
        expect(state.user?.id, 1);
      });

      test('Unauthenticated has null user initially', () {
        final state = container.read(authProvider);
        expect(state.isAuthenticated, false);
        expect(state.user, isNull);
      });
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

Map<String, dynamic> _noRoleUserJson() => {
  'id': 99,
  'phone': '081299999999',
  'email': 'norole@example.com',
  'is_active': true,
  'roles': [],
  'resident': null,
};
