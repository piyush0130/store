import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dashboard_metrics.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../data/datasources/dashboard_local_ds.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../../../core/database/local_db.dart';

// Provides LocalDatabase instance
final localDatabaseProvider = Provider((ref) => LocalDatabase());

final dashboardLocalDsProvider = Provider((ref) {
  return DashboardLocalDataSource(ref.watch(localDatabaseProvider));
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(ref.watch(dashboardLocalDsProvider));
});

// AutoDisposeAsyncNotifier automatically fetches data on mount and handles loading/error states
class DashboardMetricsNotifier extends AutoDisposeAsyncNotifier<DashboardMetrics> {
  @override
  Future<DashboardMetrics> build() async {
    return _fetchMetrics();
  }

  Future<DashboardMetrics> _fetchMetrics() async {
    final repo = ref.watch(dashboardRepositoryProvider);
    return await repo.getMetrics();
  }

  // Called when a sale is made or sync happens to refresh dashboard
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchMetrics());
  }
}

final dashboardMetricsProvider = AsyncNotifierProvider.autoDispose<DashboardMetricsNotifier, DashboardMetrics>(() {
  return DashboardMetricsNotifier();
});
