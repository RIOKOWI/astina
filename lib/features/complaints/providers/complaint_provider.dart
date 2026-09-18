import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/injection/dependency_injection.dart';
import '../data/datasources/complaint_data_source.dart';
import '../data/models/complaint_model.dart';

final complaintDataSourceProvider = Provider<ComplaintDataSource>((ref) {
  return ComplaintDataSource(ref.watch(dioClientProvider));
});

class ComplaintsListState {
  const ComplaintsListState({
    this.complaints = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.error,
  });

  final List<Complaint> complaints;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  ComplaintsListState copyWith({
    List<Complaint>? complaints,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return ComplaintsListState(
      complaints: complaints ?? this.complaints,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}

class ComplaintsListNotifier extends Notifier<ComplaintsListState> {
  @override
  ComplaintsListState build() => const ComplaintsListState();

  Future<void> load({String? search, String? status, String? category}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final ds = ref.read(complaintDataSourceProvider);
      final (list, meta) = await ds.getComplaints(
        search: search,
        status: status,
        category: category,
        page: 1,
      );
      state = state.copyWith(
        complaints: list,
        isLoading: false,
        hasMore: (meta['last_page'] as int? ?? 1) > 1,
        currentPage: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore({
    String? search,
    String? status,
    String? category,
  }) async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final ds = ref.read(complaintDataSourceProvider);
      final nextPage = state.currentPage + 1;
      final (list, meta) = await ds.getComplaints(
        search: search,
        status: status,
        category: category,
        page: nextPage,
      );
      state = state.copyWith(
        complaints: [...state.complaints, ...list],
        isLoading: false,
        hasMore: (meta['last_page'] as int? ?? 1) > nextPage,
        currentPage: nextPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final complaintsListProvider =
    NotifierProvider<ComplaintsListNotifier, ComplaintsListState>(
      ComplaintsListNotifier.new,
    );

final complaintDetailProvider = FutureProvider.autoDispose
    .family<Complaint, int>((ref, id) async {
      final ds = ref.watch(complaintDataSourceProvider);
      return ds.getComplaint(id);
    });

// Comment input state
class CommentInputState {
  const CommentInputState({this.isSubmitting = false, this.error});
  final bool isSubmitting;
  final String? error;
}

class CommentInputNotifier extends Notifier<CommentInputState> {
  @override
  CommentInputState build() => const CommentInputState();

  ComplaintDataSource get _ds => ref.read(complaintDataSourceProvider);

  Future<ComplaintComment?> submit(int complaintId, String comment) async {
    if (comment.trim().isEmpty) return null;
    state = const CommentInputState(isSubmitting: true);
    try {
      final result = await _ds.addComment(complaintId, comment.trim());
      state = const CommentInputState();
      ref.invalidate(complaintDetailProvider(complaintId));
      return result;
    } catch (e) {
      state = CommentInputState(error: e.toString());
      return null;
    }
  }
}

final commentInputProvider =
    NotifierProvider<CommentInputNotifier, CommentInputState>(
      CommentInputNotifier.new,
    );
