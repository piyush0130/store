import 'package:get_it/get_it.dart';

final GetIt locator = GetIt.instance;

void setupDependencies() {
  // Register ViewModels, Repositories, and Data Sources here
  
  // Example: 
  // locator.registerLazySingleton<LocalDatabase>(() => LocalDatabaseImpl());
  // locator.registerLazySingleton<SyncRepository>(() => SyncRepositoryImpl(locator()));
}
