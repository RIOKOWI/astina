import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/injection/dependency_injection.dart';
import '../data/datasources/profile_remote_data_source.dart';
import '../data/models/resident_model.dart';
import '../data/models/household_model.dart';
import '../data/models/document_model.dart';

final profileRemoteDataSourceProvider = Provider<ProfileRemoteDataSource>((
  ref,
) {
  final dioClient = ref.watch(dioClientProvider);
  return ProfileRemoteDataSource(dioClient);
});

final residentProvider = FutureProvider.autoDispose<ResidentModel>((ref) async {
  final datasource = ref.watch(profileRemoteDataSourceProvider);
  if (kDebugMode)
    developer.log('Loading resident data', name: 'ProfileProvider');
  return datasource.getResident();
});

final householdProvider = FutureProvider.autoDispose<HouseholdModel>((
  ref,
) async {
  final datasource = ref.watch(profileRemoteDataSourceProvider);
  if (kDebugMode)
    developer.log('Loading household data', name: 'ProfileProvider');
  return datasource.getHousehold();
});

final documentsProvider = FutureProvider.autoDispose<List<DocumentModel>>((
  ref,
) async {
  final datasource = ref.watch(profileRemoteDataSourceProvider);
  if (kDebugMode) developer.log('Loading documents', name: 'ProfileProvider');
  return datasource.getDocuments();
});

final profileNotifierProvider =
    AsyncNotifierProvider<ProfileNotifier, ProfileState>(
      () => ProfileNotifier(),
    );

class ProfileState {
  final bool isUpdating;
  final bool isUploading;
  final String? error;
  final String? successMessage;

  const ProfileState({
    this.isUpdating = false,
    this.isUploading = false,
    this.error,
    this.successMessage,
  });

  ProfileState copyWith({
    bool? isUpdating,
    bool? isUploading,
    String? error,
    String? successMessage,
  }) {
    return ProfileState(
      isUpdating: isUpdating ?? this.isUpdating,
      isUploading: isUploading ?? this.isUploading,
      error: error,
      successMessage: successMessage,
    );
  }
}

class ProfileNotifier extends AsyncNotifier<ProfileState> {
  @override
  ProfileState build() => const ProfileState();

  Future<void> updateResident(Map<String, dynamic> data) async {
    final current = state.valueOrNull ?? const ProfileState();
    state = AsyncValue.data(
      current.copyWith(isUpdating: true, error: null, successMessage: null),
    );
    try {
      final datasource = ref.read(profileRemoteDataSourceProvider);
      await datasource.updateResident(data);
      ref.invalidate(residentProvider);
      state = AsyncValue.data(
        current.copyWith(
          isUpdating: false,
          successMessage: 'Data resident berhasil diperbarui',
        ),
      );
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to update resident',
          name: 'ProfileProvider',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        current.copyWith(isUpdating: false, error: e.toString()),
      );
    }
  }

  Future<void> uploadKtp(String filePath) async {
    final current = state.valueOrNull ?? const ProfileState();
    state = AsyncValue.data(
      current.copyWith(isUploading: true, error: null, successMessage: null),
    );
    try {
      final datasource = ref.read(profileRemoteDataSourceProvider);
      await datasource.uploadKtp(filePath);
      ref.invalidate(documentsProvider);
      state = AsyncValue.data(
        current.copyWith(
          isUploading: false,
          successMessage: 'KTP berhasil diupload',
        ),
      );
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to upload KTP',
          name: 'ProfileProvider',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        current.copyWith(isUploading: false, error: e.toString()),
      );
    }
  }

  Future<void> uploadKk(String filePath) async {
    final current = state.valueOrNull ?? const ProfileState();
    state = AsyncValue.data(
      current.copyWith(isUploading: true, error: null, successMessage: null),
    );
    try {
      final datasource = ref.read(profileRemoteDataSourceProvider);
      await datasource.uploadKk(filePath);
      ref.invalidate(documentsProvider);
      state = AsyncValue.data(
        current.copyWith(
          isUploading: false,
          successMessage: 'Kartu Keluarga berhasil diupload',
        ),
      );
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to upload KK',
          name: 'ProfileProvider',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        current.copyWith(isUploading: false, error: e.toString()),
      );
    }
  }

  void clearMessages() {
    final current = state.valueOrNull ?? const ProfileState();
    state = AsyncValue.data(
      current.copyWith(error: null, successMessage: null),
    );
  }
}
