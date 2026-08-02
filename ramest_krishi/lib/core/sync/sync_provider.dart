import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/database/local_db.dart';
import 'sync_repository.dart';
import 'sync_service.dart';

final syncRepositoryProvider = Provider<SyncRepository>((ref) {
  return SyncRepository(LocalDatabase(), Supabase.instance.client);
});

final syncServiceProvider = ChangeNotifierProvider<SyncService>((ref) {
  final repo = ref.watch(syncRepositoryProvider);
  final service = SyncService(repo);
  
  // Auto-start the sync loop when this provider is first read (e.g., app startup)
  service.startPeriodicSync();
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});
