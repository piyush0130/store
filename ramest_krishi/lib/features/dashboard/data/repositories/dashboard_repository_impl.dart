import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/entities/dashboard_metrics.dart';
import '../datasources/dashboard_local_ds.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardLocalDataSource localDataSource;

  DashboardRepositoryImpl(this.localDataSource);

  @override
  Future<DashboardMetrics> getMetrics() async {
    return await localDataSource.getMetrics();
  }
}
