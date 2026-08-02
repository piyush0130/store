import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/database/local_db.dart';

class SyncRepository {
  final LocalDatabase localDb;
  final SupabaseClient supabase;
  
  static const _lastSyncKey = 'last_successful_sync_timestamp';

  SyncRepository(this.localDb, this.supabase);

  // PUSH: Get all pending operations from local queue
  Future<List<Map<String, dynamic>>> getPendingSyncActions() async {
    final db = await localDb.database;
    return await db.query('sync_queue', orderBy: 'created_at ASC');
  }

  // PUSH: Remove an action from the queue after successful cloud sync
  Future<void> removeSyncAction(String id) async {
    final db = await localDb.database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [id]);
  }

  // PUSH: Execute a single action against Supabase
  Future<void> pushActionToCloud(Map<String, dynamic> actionRow) async {
    final tableName = actionRow['table_name'] as String;
    final action = actionRow['action'] as String;
    final payload = jsonDecode(actionRow['payload'] as String) as Map<String, dynamic>;

    try {
      if (action == 'INSERT') {
        await supabase.from(tableName).upsert(payload);
      } else if (action == 'UPDATE') {
        await supabase.from(tableName).update(payload).eq('id', payload['id']);
      } else if (action == 'DELETE') {
        // We use soft deletes, so this is actually an update
        await supabase.from(tableName).update({'deleted_at': payload['deleted_at']}).eq('id', payload['id']);
      }
    } catch (e) {
      // If error is related to constraint violations (already exists), we might want to ignore.
      // For now, rethrow so the service halts this batch.
      rethrow;
    }
  }

  // PULL: Fetch updates from cloud and merge into SQLite
  Future<void> pullUpdatesFromCloud() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncStr = prefs.getString(_lastSyncKey) ?? DateTime.fromMillisecondsSinceEpoch(0).toIso8601String();
    
    // We sync tables: products, customers, sales, sale_items, suppliers, purchases, purchase_items, expenses
    final tables = ['products', 'customers', 'sales', 'sale_items', 'suppliers', 'purchases', 'purchase_items', 'expenses'];
    
    final db = await localDb.database;
    
    for (String table in tables) {
      // Fetch anything updated on server AFTER our last sync
      final response = await supabase
          .from(table)
          .select()
          .gte('updated_at', lastSyncStr)
          .order('updated_at', ascending: true);
          
      final List<dynamic> rows = response;
      
      if (rows.isNotEmpty) {
        await db.transaction((txn) async {
          for (var row in rows) {
            final map = row as Map<String, dynamic>;
            // Upsert into local database (Conflict resolution: Server wins on PULL)
            await txn.insert(
              table, 
              map, 
              conflictAlgorithm: ConflictAlgorithm.replace
            );
          }
        });
      }
    }

    // Update last sync time to now
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }
}
