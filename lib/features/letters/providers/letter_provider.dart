import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/injection/dependency_injection.dart';
import '../data/datasources/letter_remote_data_source.dart';
import '../data/models/letter_model.dart';
import '../data/models/letter_type_model.dart';

// === PROVIDERS ===

final letterRemoteDataSourceProvider = Provider<LetterRemoteDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return LetterRemoteDataSource(dioClient);
});

// Letter types (warga)
final letterTypesProvider = FutureProvider.autoDispose<List<LetterTypeModel>>((
  ref,
) async {
  final datasource = ref.watch(letterRemoteDataSourceProvider);
  if (kDebugMode) developer.log('Loading letter types', name: 'LetterProvider');
  return datasource.getLetterTypes();
});

// Letter type detail with fields (warga)
final letterTypeDetailProvider = FutureProvider.autoDispose
    .family<LetterTypeModel, int>((ref, typeId) async {
      final datasource = ref.watch(letterRemoteDataSourceProvider);
      if (kDebugMode)
        developer.log(
          'Loading letter type detail: $typeId',
          name: 'LetterProvider',
        );
      final types = await datasource.getLetterTypes();
      return types.firstWhere((t) => t.id == typeId);
    });

// My letters (warga)
final myLettersProvider = FutureProvider.autoDispose
    .family<List<LetterModel>, String?>((ref, status) async {
      final datasource = ref.watch(letterRemoteDataSourceProvider);
      if (kDebugMode)
        developer.log('Loading my letters', name: 'LetterProvider');
      return datasource.getMyLetters(status: status);
    });

// Letter detail
final letterDetailProvider = FutureProvider.autoDispose
    .family<LetterModel, int>((ref, id) async {
      final datasource = ref.watch(letterRemoteDataSourceProvider);
      if (kDebugMode)
        developer.log('Loading letter detail: $id', name: 'LetterProvider');
      return datasource.getLetterDetail(id);
    });

// === NOTIFIER ===

final letterNotifierProvider =
    AsyncNotifierProvider<LetterNotifier, LetterState>(() => LetterNotifier());

class LetterState {
  final String? errorMessage;
  final bool isSubmitting;
  final bool lastSubmitSuccess;
  final LetterModel? lastSubmittedLetter;
  final bool isDownloading;
  final String? downloadError;

  const LetterState({
    this.errorMessage,
    this.isSubmitting = false,
    this.lastSubmitSuccess = false,
    this.lastSubmittedLetter,
    this.isDownloading = false,
    this.downloadError,
  });

  LetterState copyWith({
    String? errorMessage,
    bool? isSubmitting,
    bool? lastSubmitSuccess,
    LetterModel? lastSubmittedLetter,
    bool? isDownloading,
    String? downloadError,
  }) {
    return LetterState(
      errorMessage: errorMessage ?? this.errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      lastSubmitSuccess: lastSubmitSuccess ?? this.lastSubmitSuccess,
      lastSubmittedLetter: lastSubmittedLetter ?? this.lastSubmittedLetter,
      isDownloading: isDownloading ?? this.isDownloading,
      downloadError: downloadError ?? this.downloadError,
    );
  }
}

class LetterNotifier extends AsyncNotifier<LetterState> {
  @override
  LetterState build() => const LetterState();

  Future<bool> submitLetter({
    required int letterTypeId,
    required Map<String, dynamic> fields,
    String? purpose,
  }) async {
    state = AsyncValue.data(
      state.value!.copyWith(
        isSubmitting: true,
        errorMessage: null,
        lastSubmitSuccess: false,
      ),
    );
    try {
      final datasource = ref.read(letterRemoteDataSourceProvider);
      final letter = await datasource.submitLetter(
        letterTypeId: letterTypeId,
        fields: fields,
        purpose: purpose,
      );
      ref.invalidate(myLettersProvider(null));
      state = AsyncValue.data(
        state.value!.copyWith(
          isSubmitting: false,
          lastSubmitSuccess: true,
          lastSubmittedLetter: letter,
        ),
      );
      if (kDebugMode)
        developer.log('Letter submitted successfully', name: 'LetterProvider');
      return true;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to submit letter',
          name: 'LetterProvider',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        state.value!.copyWith(
          isSubmitting: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
          lastSubmitSuccess: false,
        ),
      );
      return false;
    }
  }

  Future<List<int>?> downloadDocument(int letterId) async {
    state = AsyncValue.data(
      state.value!.copyWith(isDownloading: true, downloadError: null),
    );
    try {
      final datasource = ref.read(letterRemoteDataSourceProvider);
      if (kDebugMode) {
        developer.log(
          'Downloading document for letter: $letterId',
          name: 'LetterProvider',
        );
      }
      final bytes = await datasource.downloadDocument(letterId);
      state = AsyncValue.data(state.value!.copyWith(isDownloading: false));
      return bytes;
    } catch (e, st) {
      if (kDebugMode) {
        developer.log(
          'Failed to download document',
          name: 'LetterProvider',
          error: e,
          stackTrace: st,
        );
      }
      state = AsyncValue.data(
        state.value!.copyWith(
          isDownloading: false,
          downloadError: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return null;
    }
  }

  Future<List<int>?> generateDocument(int letterId) async {
    state = AsyncValue.data(
      state.value!.copyWith(isDownloading: true, downloadError: null),
    );
    try {
      final datasource = ref.read(letterRemoteDataSourceProvider);
      if (kDebugMode) {
        developer.log(
          'Generating document for letter: $letterId',
          name: 'LetterProvider',
        );
      }
      final bytes = await datasource.generateDocument(letterId);
      state = AsyncValue.data(state.value!.copyWith(isDownloading: false));
      return bytes;
    } catch (e, st) {
      if (kDebugMode) {
        developer.log(
          'Failed to generate document',
          name: 'LetterProvider',
          error: e,
          stackTrace: st,
        );
      }
      state = AsyncValue.data(
        state.value!.copyWith(
          isDownloading: false,
          downloadError: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return null;
    }
  }
}

// === RT ADMIN ===

final pendingLettersProvider = FutureProvider.autoDispose<List<LetterModel>>((
  ref,
) async {
  final datasource = ref.watch(letterRemoteDataSourceProvider);
  if (kDebugMode)
    developer.log('Loading pending letters for RT', name: 'LetterProvider');
  return datasource.getPendingLetters();
});

final rtLetterNotifierProvider =
    AsyncNotifierProvider<RtLetterNotifier, RtLetterState>(
      () => RtLetterNotifier(),
    );

class RtLetterState {
  final String? errorMessage;
  final bool isProcessing;
  final int? lastProcessedId;

  const RtLetterState({
    this.errorMessage,
    this.isProcessing = false,
    this.lastProcessedId,
  });

  RtLetterState copyWith({
    String? errorMessage,
    bool? isProcessing,
    int? lastProcessedId,
  }) {
    return RtLetterState(
      errorMessage: errorMessage ?? this.errorMessage,
      isProcessing: isProcessing ?? this.isProcessing,
      lastProcessedId: lastProcessedId ?? this.lastProcessedId,
    );
  }
}

class RtLetterNotifier extends AsyncNotifier<RtLetterState> {
  @override
  RtLetterState build() => const RtLetterState();

  Future<bool> approveLetter(int id) async {
    state = AsyncValue.data(
      state.value!.copyWith(isProcessing: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(letterRemoteDataSourceProvider);
      await datasource.approveLetter(id);
      ref.invalidate(pendingLettersProvider);
      ref.invalidate(letterDetailProvider(id));
      state = AsyncValue.data(
        state.value!.copyWith(isProcessing: false, lastProcessedId: id),
      );
      if (kDebugMode)
        developer.log('Letter approved: $id', name: 'LetterProvider');
      return true;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to approve letter',
          name: 'LetterProvider',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        state.value!.copyWith(
          isProcessing: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return false;
    }
  }

  Future<bool> rejectLetter(int id, String reason) async {
    state = AsyncValue.data(
      state.value!.copyWith(isProcessing: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(letterRemoteDataSourceProvider);
      await datasource.rejectLetter(id, reason);
      ref.invalidate(pendingLettersProvider);
      ref.invalidate(letterDetailProvider(id));
      state = AsyncValue.data(
        state.value!.copyWith(isProcessing: false, lastProcessedId: id),
      );
      if (kDebugMode)
        developer.log('Letter rejected: $id', name: 'LetterProvider');
      return true;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to reject letter',
          name: 'LetterProvider',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        state.value!.copyWith(
          isProcessing: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return false;
    }
  }
}

// === RT ADMIN: LETTER TYPES ===

final rtLetterTypeNotifierProvider =
    AsyncNotifierProvider<RtLetterTypeNotifier, RtLetterTypeState>(
      () => RtLetterTypeNotifier(),
    );

class RtLetterTypeState {
  final String? errorMessage;
  final bool isProcessing;

  const RtLetterTypeState({this.errorMessage, this.isProcessing = false});

  RtLetterTypeState copyWith({String? errorMessage, bool? isProcessing}) {
    return RtLetterTypeState(
      errorMessage: errorMessage ?? this.errorMessage,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}

class RtLetterTypeNotifier extends AsyncNotifier<RtLetterTypeState> {
  @override
  RtLetterTypeState build() => const RtLetterTypeState();

  Future<LetterTypeModel?> createLetterType(Map<String, dynamic> data) async {
    state = AsyncValue.data(
      state.value!.copyWith(isProcessing: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(letterRemoteDataSourceProvider);
      final letterType = await datasource.createLetterType(data);
      ref.invalidate(letterTypesProvider);
      state = AsyncValue.data(state.value!.copyWith(isProcessing: false));
      if (kDebugMode)
        developer.log(
          'Letter type created: ${letterType.id}',
          name: 'LetterProvider',
        );
      return letterType;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to create letter type',
          name: 'LetterProvider',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        state.value!.copyWith(
          isProcessing: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return null;
    }
  }

  Future<LetterTypeModel?> updateLetterType(
    int id,
    Map<String, dynamic> data,
  ) async {
    state = AsyncValue.data(
      state.value!.copyWith(isProcessing: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(letterRemoteDataSourceProvider);
      final letterType = await datasource.updateLetterType(id, data);
      ref.invalidate(letterTypesProvider);
      ref.invalidate(letterTypeDetailProvider(id));
      state = AsyncValue.data(state.value!.copyWith(isProcessing: false));
      if (kDebugMode)
        developer.log('Letter type updated: $id', name: 'LetterProvider');
      return letterType;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to update letter type',
          name: 'LetterProvider',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        state.value!.copyWith(
          isProcessing: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return null;
    }
  }

  Future<bool> deleteLetterType(int id) async {
    state = AsyncValue.data(
      state.value!.copyWith(isProcessing: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(letterRemoteDataSourceProvider);
      await datasource.deleteLetterType(id);
      ref.invalidate(letterTypesProvider);
      state = AsyncValue.data(state.value!.copyWith(isProcessing: false));
      if (kDebugMode)
        developer.log('Letter type deleted: $id', name: 'LetterProvider');
      return true;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to delete letter type',
          name: 'LetterProvider',
          error: e,
          stackTrace: st,
        );
      state = AsyncValue.data(
        state.value!.copyWith(
          isProcessing: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
      return false;
    }
  }

  Future<LetterFieldModel?> addField(
    int letterTypeId,
    Map<String, dynamic> data,
  ) async {
    try {
      final datasource = ref.read(letterRemoteDataSourceProvider);
      final field = await datasource.addField(letterTypeId, data);
      ref.invalidate(letterTypeDetailProvider(letterTypeId));
      return field;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to add field',
          name: 'LetterProvider',
          error: e,
          stackTrace: st,
        );
      return null;
    }
  }

  Future<LetterFieldModel?> updateField(
    int letterTypeId,
    int fieldId,
    Map<String, dynamic> data,
  ) async {
    try {
      final datasource = ref.read(letterRemoteDataSourceProvider);
      final field = await datasource.updateField(letterTypeId, fieldId, data);
      ref.invalidate(letterTypeDetailProvider(letterTypeId));
      return field;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to update field',
          name: 'LetterProvider',
          error: e,
          stackTrace: st,
        );
      return null;
    }
  }

  Future<bool> deleteField(int letterTypeId, int fieldId) async {
    try {
      final datasource = ref.read(letterRemoteDataSourceProvider);
      await datasource.deleteField(letterTypeId, fieldId);
      ref.invalidate(letterTypeDetailProvider(letterTypeId));
      return true;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Failed to delete field',
          name: 'LetterProvider',
          error: e,
          stackTrace: st,
        );
      return false;
    }
  }
}
