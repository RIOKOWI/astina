import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/injection/dependency_injection.dart';
import '../data/datasources/dashboard_remote_data_source.dart';
import '../data/models/dashboard_summary_model.dart';

final dashboardDataSourceProvider = Provider<DashboardRemoteDataSource>((ref) {
  return DashboardRemoteDataSource(ref.watch(dioClientProvider));
});

class DashboardSummaryNotifier extends Notifier<DashboardSummary> {
  @override
  DashboardSummary build() => const DashboardSummary();

  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;
    try {
      final ds = ref.read(dashboardDataSourceProvider);
      final summary = await ds.getSummary();
      state = summary;
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refresh() async {
    _isLoading = true;
    try {
      final ds = ref.read(dashboardDataSourceProvider);
      final summary = await ds.getSummary();
      state = summary;
    } finally {
      _isLoading = false;
    }
  }
}

final dashboardSummaryProvider =
    NotifierProvider<DashboardSummaryNotifier, DashboardSummary>(
      DashboardSummaryNotifier.new,
    );
