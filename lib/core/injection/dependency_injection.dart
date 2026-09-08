import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/dio_client.dart';
import '../services/secure_storage.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final dioClientProvider = Provider<DioClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return DioClient(storage);
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return AuthRemoteDataSource(dioClient);
});
