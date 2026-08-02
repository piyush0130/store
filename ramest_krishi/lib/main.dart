import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/di/dependency_injection.dart';
import 'core/network/supabase_client.dart';
import 'core/config/env_config.dart';
import 'core/database/local_db.dart';
import 'core/sync/sync_repository.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Must re-initialize Supabase and DB in headless isolate
      await EnvConfig.init();
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        anonKey: EnvConfig.supabaseAnonKey,
      );
      final repo = SyncRepository(LocalDatabase(), Supabase.instance.client);
      
      // Push Queue
      final pendingActions = await repo.getPendingSyncActions();
      for (var actionRow in pendingActions) {
        await repo.pushActionToCloud(actionRow);
        await repo.removeSyncAction(actionRow['id']);
      }
      // Pull Updates
      await repo.pullUpdatesFromCloud();
      
      return Future.value(true);
    } catch (err) {
      return Future.value(false); // Triggers retry depending on WorkManager policy
    }
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load Environment Variables
  await EnvConfig.init();
  
  // Initialize Dependency Injection
  setupDependencies();

  // Initialize Supabase Connection
  await SupabaseService.initialize();

  // Initialize Background Sync
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );
  Workmanager().registerPeriodicTask(
    "1",
    "backgroundSyncTask",
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
  );

  runApp(
    const ProviderScope(
      child: RamestKrishiApp(),
    ),
  );
}

class RamestKrishiApp extends ConsumerWidget {
  const RamestKrishiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Ramest Krishi Sewa Kendra',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
