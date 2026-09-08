import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/injection/dependency_injection.dart';
import '../data/datasources/rt_admin_data_source.dart';
import '../data/models/rt_resident_model.dart';
import '../data/models/rt_household_model.dart';
import '../data/models/rt_user_model.dart';

// === DATASOURCE ===

final rtAdminDataSourceProvider = Provider<RtAdminDataSource>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return RtAdminDataSource(dioClient);
});

// === RESIDENT PROVIDERS ===

final rtResidentsProvider = FutureProvider.autoDispose
    .family<List<RtResidentModel>, RtResidentFilter>((ref, filter) async {
      final datasource = ref.watch(rtAdminDataSourceProvider);
      if (kDebugMode)
        developer.log('Loading RT residents', name: 'RtAdminProvider');
      return datasource.getResidents(
        search: filter.search,
        status: filter.status,
        hasAccount: filter.hasAccount,
      );
    });

final rtResidentDetailProvider = FutureProvider.autoDispose
    .family<RtResidentModel, int>((ref, id) async {
      final datasource = ref.watch(rtAdminDataSourceProvider);
      if (kDebugMode)
        developer.log('Loading resident detail: $id', name: 'RtAdminProvider');
      return datasource.getResidentDetail(id);
    });

final rtResidentNotifierProvider =
    AsyncNotifierProvider<RtResidentNotifier, RtAdminMutationState>(
      () => RtResidentNotifier(),
    );

class RtResidentFilter {
  final String? search;
  final String? status;
  final bool? hasAccount;

  const RtResidentFilter({this.search, this.status, this.hasAccount});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RtResidentFilter &&
          search == other.search &&
          status == other.status &&
          hasAccount == other.hasAccount;

  @override
  int get hashCode => search.hashCode ^ status.hashCode ^ hasAccount.hashCode;
}

// === HOUSEHOLD PROVIDERS ===

final rtHouseholdsProvider = FutureProvider.autoDispose<List<RtHouseholdModel>>(
  (ref) async {
    final datasource = ref.watch(rtAdminDataSourceProvider);
    if (kDebugMode)
      developer.log('Loading RT households', name: 'RtAdminProvider');
    return datasource.getHouseholds();
  },
);

final rtHouseholdDetailProvider = FutureProvider.autoDispose
    .family<RtHouseholdModel, int>((ref, id) async {
      final datasource = ref.watch(rtAdminDataSourceProvider);
      if (kDebugMode)
        developer.log('Loading household detail: $id', name: 'RtAdminProvider');
      return datasource.getHouseholdDetail(id);
    });

final rtHouseholdNotifierProvider =
    AsyncNotifierProvider<RtHouseholdNotifier, RtAdminMutationState>(
      () => RtHouseholdNotifier(),
    );

// === USER PROVIDERS ===

final rtUsersProvider = FutureProvider.autoDispose
    .family<List<RtUserModel>, RtUserFilter>((ref, filter) async {
      final datasource = ref.watch(rtAdminDataSourceProvider);
      if (kDebugMode)
        developer.log('Loading RT users', name: 'RtAdminProvider');
      return datasource.getUsers(
        search: filter.search,
        isActive: filter.isActive,
        role: filter.role,
      );
    });

final rtUserDetailProvider = FutureProvider.autoDispose
    .family<RtUserModel, int>((ref, id) async {
      final datasource = ref.watch(rtAdminDataSourceProvider);
      if (kDebugMode)
        developer.log('Loading user detail: $id', name: 'RtAdminProvider');
      return datasource.getUserDetail(id);
    });

final rtUserNotifierProvider =
    AsyncNotifierProvider<RtUserNotifier, RtAdminMutationState>(
      () => RtUserNotifier(),
    );

// === SHARED MUTATION STATE ===

class RtAdminMutationState {
  final String? errorMessage;
  final bool isProcessing;
  final bool lastSuccess;

  const RtAdminMutationState({
    this.errorMessage,
    this.isProcessing = false,
    this.lastSuccess = false,
  });

  RtAdminMutationState copyWith({
    String? errorMessage,
    bool? isProcessing,
    bool? lastSuccess,
  }) {
    return RtAdminMutationState(
      errorMessage: errorMessage ?? this.errorMessage,
      isProcessing: isProcessing ?? this.isProcessing,
      lastSuccess: lastSuccess ?? this.lastSuccess,
    );
  }
}

// === RESIDENT NOTIFIER ===

class RtResidentNotifier extends AsyncNotifier<RtAdminMutationState> {
  @override
  RtAdminMutationState build() => const RtAdminMutationState();

  Future<bool> create(Map<String, dynamic> data) => _mutate(() async {
    final ds = ref.read(rtAdminDataSourceProvider);
    return ds.createResident(data);
  }, onSuccess: () => ref.invalidate(rtResidentsProvider));

  Future<bool> updateResident(int id, Map<String, dynamic> data) => _mutate(
    () async {
      final ds = ref.read(rtAdminDataSourceProvider);
      return ds.updateResident(id, data);
    },
    onSuccess: () {
      ref.invalidate(rtResidentsProvider);
      ref.invalidate(rtResidentDetailProvider(id));
    },
  );

  Future<bool> _mutate(
    Future<RtResidentModel> Function() action, {
    required VoidCallback onSuccess,
  }) async {
    state = AsyncValue.data(
      state.value!.copyWith(isProcessing: true, errorMessage: null),
    );
    try {
      await action();
      ref.invalidate(rtResidentsProvider);
      state = AsyncValue.data(
        state.value!.copyWith(isProcessing: false, lastSuccess: true),
      );
      if (kDebugMode)
        developer.log('Resident mutation success', name: 'RtAdminProvider');
      return true;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Resident mutation failed',
          name: 'RtAdminProvider',
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

// === HOUSEHOLD NOTIFIER ===

class RtHouseholdNotifier extends AsyncNotifier<RtAdminMutationState> {
  @override
  RtAdminMutationState build() => const RtAdminMutationState();

  Future<bool> create(Map<String, dynamic> data) => _mutate(() async {
    final ds = ref.read(rtAdminDataSourceProvider);
    return ds.createHousehold(data);
  }, onSuccess: () => ref.invalidate(rtHouseholdsProvider));

  Future<bool> updateHousehold(int id, Map<String, dynamic> data) => _mutate(
    () async {
      final ds = ref.read(rtAdminDataSourceProvider);
      return ds.updateHousehold(id, data);
    },
    onSuccess: () {
      ref.invalidate(rtHouseholdsProvider);
      ref.invalidate(rtHouseholdDetailProvider(id));
    },
  );

  Future<bool> addMember(int householdId, Map<String, dynamic> data) => _mutate(
    () async {
      final ds = ref.read(rtAdminDataSourceProvider);
      await ds.addHouseholdMember(householdId, data);
      return ref.read(rtHouseholdDetailProvider(householdId).future);
    },
    onSuccess: () => ref.invalidate(rtHouseholdDetailProvider(householdId)),
  );

  Future<bool> removeMember(int householdId, int residentId) => _mutate(
    () async {
      final ds = ref.read(rtAdminDataSourceProvider);
      await ds.removeHouseholdMember(householdId, residentId);
      return null;
    },
    onSuccess: () => ref.invalidate(rtHouseholdDetailProvider(householdId)),
  );

  Future<bool> _mutate(
    Future<RtHouseholdModel?> Function() action, {
    required VoidCallback onSuccess,
  }) async {
    state = AsyncValue.data(
      state.value!.copyWith(isProcessing: true, errorMessage: null),
    );
    try {
      await action();
      state = AsyncValue.data(
        state.value!.copyWith(isProcessing: false, lastSuccess: true),
      );
      if (kDebugMode)
        developer.log('Household mutation success', name: 'RtAdminProvider');
      return true;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'Household mutation failed',
          name: 'RtAdminProvider',
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

// === USER NOTIFIER ===

class RtUserFilter {
  final String? search;
  final bool? isActive;
  final String? role;

  const RtUserFilter({this.search, this.isActive, this.role});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RtUserFilter &&
          search == other.search &&
          isActive == other.isActive &&
          role == other.role;

  @override
  int get hashCode => search.hashCode ^ isActive.hashCode ^ role.hashCode;
}

class RtUserNotifier extends AsyncNotifier<RtAdminMutationState> {
  @override
  RtAdminMutationState build() => const RtAdminMutationState();

  Future<bool> updateUser(int id, Map<String, dynamic> data) => _mutate(
    () async {
      final ds = ref.read(rtAdminDataSourceProvider);
      return ds.updateUser(id, data);
    },
    onSuccess: () {
      ref.invalidate(rtUsersProvider);
      ref.invalidate(rtUserDetailProvider(id));
    },
  );

  Future<bool> createAccount(int residentId, Map<String, dynamic> data) =>
      _mutate(() async {
        final ds = ref.read(rtAdminDataSourceProvider);
        return ds.createResidentAccount(residentId, data);
      }, onSuccess: () => ref.invalidate(rtResidentDetailProvider(residentId)));

  Future<bool> resetPassword(int userId, Map<String, dynamic> data) =>
      _mutate(() async {
        final ds = ref.read(rtAdminDataSourceProvider);
        await ds.resetUserPassword(userId, data);
        return null;
      }, onSuccess: () {});

  Future<bool> _mutate(
    Future<RtUserModel?> Function() action, {
    required VoidCallback onSuccess,
  }) async {
    state = AsyncValue.data(
      state.value!.copyWith(isProcessing: true, errorMessage: null),
    );
    try {
      await action();
      state = AsyncValue.data(
        state.value!.copyWith(isProcessing: false, lastSuccess: true),
      );
      if (kDebugMode)
        developer.log('User mutation success', name: 'RtAdminProvider');
      return true;
    } catch (e, st) {
      if (kDebugMode)
        developer.log(
          'User mutation failed',
          name: 'RtAdminProvider',
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
