import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/injection/dependency_injection.dart';
import '../data/datasources/complaint_remote_data_source.dart';
import '../data/models/complaint_model.dart';
import '../data/models/complaint_attachment_model.dart';

final complaintRemoteDataSourceProvider = Provider<ComplaintRemoteDataSource>((
  ref,
) {
  final dioClient = ref.watch(dioClientProvider);
  return ComplaintRemoteDataSource(dioClient);
});

final complaintsProvider = FutureProvider.autoDispose<List<ComplaintModel>>((
  ref,
) async {
  final datasource = ref.watch(complaintRemoteDataSourceProvider);
  if (kDebugMode) developer.log('Loading complaints', name: 'Complaint');
  return datasource.getComplaints();
});

// Filtered complaints with optional status/category
final filteredComplaintsProvider = FutureProvider.autoDispose
    .family<List<ComplaintModel>, ({String? status, String? category})>((
      ref,
      filters,
    ) async {
      final datasource = ref.watch(complaintRemoteDataSourceProvider);
      if (kDebugMode) {
        developer.log(
          'Loading filtered complaints: status=${filters.status}, category=${filters.category}',
          name: 'Complaint',
        );
      }
      return datasource.getComplaints(
        status: filters.status,
        category: filters.category,
      );
    });

final complaintDetailProvider = FutureProvider.autoDispose
    .family<ComplaintModel, int>((ref, id) async {
      final datasource = ref.watch(complaintRemoteDataSourceProvider);
      if (kDebugMode)
        developer.log('Loading complaint detail: $id', name: 'Complaint');
      return datasource.getComplaintDetail(id);
    });

final complaintNotifierProvider =
    AsyncNotifierProvider<ComplaintNotifier, ComplaintState>(
      () => ComplaintNotifier(),
    );

class ComplaintState {
  final String? errorMessage;
  final bool isSubmitting;

  const ComplaintState({this.errorMessage, this.isSubmitting = false});

  ComplaintState copyWith({String? errorMessage, bool? isSubmitting}) {
    return ComplaintState(
      errorMessage: errorMessage ?? this.errorMessage,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class ComplaintNotifier extends AsyncNotifier<ComplaintState> {
  @override
  ComplaintState build() => const ComplaintState();

  Future<ComplaintModel?> createComplaint({
    required String title,
    String? description,
    required String category,
  }) async {
    state = AsyncValue.data(
      state.value!.copyWith(isSubmitting: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(complaintRemoteDataSourceProvider);
      final complaint = await datasource.createComplaint(
        title: title,
        description: description,
        category: category,
      );
      ref.invalidate(complaintsProvider);
      state = AsyncValue.data(state.value!.copyWith(isSubmitting: false));
      return complaint;
    } catch (e, st) {
      if (kDebugMode) {
        developer.log(
          'Failed to create complaint',
          name: 'Complaint',
          error: e,
          stackTrace: st,
        );
      }
      state = AsyncValue.data(
        state.value!.copyWith(isSubmitting: false, errorMessage: e.toString()),
      );
      return null;
    }
  }

  Future<ComplaintModel?> updateStatus({
    required int complaintId,
    required String status,
    String? rejectionReason,
  }) async {
    state = AsyncValue.data(
      state.value!.copyWith(isSubmitting: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(complaintRemoteDataSourceProvider);
      final complaint = await datasource.updateStatus(
        complaintId: complaintId,
        status: status,
        rejectionReason: rejectionReason,
      );
      ref.invalidate(complaintDetailProvider(complaintId));
      state = AsyncValue.data(state.value!.copyWith(isSubmitting: false));
      return complaint;
    } catch (e, st) {
      if (kDebugMode) {
        developer.log(
          'Failed to update complaint status',
          name: 'Complaint',
          error: e,
          stackTrace: st,
        );
      }
      state = AsyncValue.data(
        state.value!.copyWith(isSubmitting: false, errorMessage: e.toString()),
      );
      return null;
    }
  }

  Future<bool> postComment({
    required int complaintId,
    required String comment,
  }) async {
    state = AsyncValue.data(
      state.value!.copyWith(isSubmitting: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(complaintRemoteDataSourceProvider);
      await datasource.postComment(complaintId: complaintId, comment: comment);
      ref.invalidate(complaintDetailProvider(complaintId));
      state = AsyncValue.data(state.value!.copyWith(isSubmitting: false));
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        developer.log(
          'Failed to post comment',
          name: 'Complaint',
          error: e,
          stackTrace: st,
        );
      }
      state = AsyncValue.data(
        state.value!.copyWith(isSubmitting: false, errorMessage: e.toString()),
      );
      return false;
    }
  }

  Future<ComplaintAttachmentModel?> uploadAttachment({
    required int complaintId,
    required String filePath,
    required String fileName,
  }) async {
    state = AsyncValue.data(
      state.value!.copyWith(isSubmitting: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(complaintRemoteDataSourceProvider);
      final attachment = await datasource.uploadAttachment(
        complaintId: complaintId,
        filePath: filePath,
        fileName: fileName,
      );
      ref.invalidate(complaintDetailProvider(complaintId));
      state = AsyncValue.data(state.value!.copyWith(isSubmitting: false));
      return attachment;
    } catch (e, st) {
      if (kDebugMode) {
        developer.log(
          'Failed to upload attachment',
          name: 'Complaint',
          error: e,
          stackTrace: st,
        );
      }
      state = AsyncValue.data(
        state.value!.copyWith(isSubmitting: false, errorMessage: e.toString()),
      );
      return null;
    }
  }

  Future<bool> deleteAttachment({
    required int complaintId,
    required int attachmentId,
  }) async {
    state = AsyncValue.data(
      state.value!.copyWith(isSubmitting: true, errorMessage: null),
    );
    try {
      final datasource = ref.read(complaintRemoteDataSourceProvider);
      await datasource.deleteAttachment(
        complaintId: complaintId,
        attachmentId: attachmentId,
      );
      ref.invalidate(complaintDetailProvider(complaintId));
      state = AsyncValue.data(state.value!.copyWith(isSubmitting: false));
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        developer.log(
          'Failed to delete attachment',
          name: 'Complaint',
          error: e,
          stackTrace: st,
        );
      }
      state = AsyncValue.data(
        state.value!.copyWith(isSubmitting: false, errorMessage: e.toString()),
      );
      return false;
    }
  }
}
