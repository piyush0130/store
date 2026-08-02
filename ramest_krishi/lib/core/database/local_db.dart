import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class LocalDatabase {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('ramest_krishi.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      // Use web-specific factory
      databaseFactory = databaseFactoryFfiWeb;
      return await databaseFactory.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _createDB,
        )
      );
    } else {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
      );
    }
  }

  Future _createDB(Database db, int version) async {
    // Sync Queue (Local only, tracks offline mutations)
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        action TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // --- NEW EXPENSES TABLE ---
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        branch_id TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        expense_date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    // --- NEW PURCHASE MODULE TABLES ---
    await db.execute('''
      CREATE TABLE suppliers (
        id TEXT PRIMARY KEY,
        branch_id TEXT NOT NULL,
        name TEXT NOT NULL,
        company_name TEXT,
        gst_number TEXT,
        mobile TEXT,
        due_amount REAL DEFAULT 0.0,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE purchases (
        id TEXT PRIMARY KEY,
        branch_id TEXT NOT NULL,
        supplier_id TEXT NOT NULL,
        invoice_number TEXT,
        purchase_date TEXT,
        type TEXT DEFAULT 'INVOICE',
        total_amount REAL,
        gst_total REAL,
        paid_amount REAL,
        payment_method TEXT,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE purchase_items (
        id TEXT PRIMARY KEY,
        purchase_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        quantity REAL,
        unit_price REAL,
        gst_amount REAL,
        batch_number TEXT,
        expiry_date TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Core Tables mapping exactly to the approved Supabase Schema
    await db.execute('''
      CREATE TABLE branches (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE profiles (
        id TEXT PRIMARY KEY,
        branch_id TEXT,
        full_name TEXT NOT NULL,
        role TEXT,
        phone TEXT,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        branch_id TEXT NOT NULL,
        name TEXT NOT NULL,
        village TEXT,
        mobile TEXT,
        gst_number TEXT,
        primary_crop TEXT,
        land_area REAL,
        credit_limit REAL,
        due_amount REAL DEFAULT 0.0,
        notes TEXT,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        branch_id TEXT NOT NULL,
        name TEXT NOT NULL,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        branch_id TEXT NOT NULL,
        category_id TEXT,
        name TEXT NOT NULL,
        company TEXT,
        barcode TEXT,
        hsn_code TEXT,
        gst_percentage REAL DEFAULT 0.0,
        batch_number TEXT,
        expiry_date TEXT,
        mrp REAL NOT NULL,
        purchase_price REAL NOT NULL,
        selling_price REAL NOT NULL,
        stock_quantity REAL DEFAULT 0.0,
        image_local_path TEXT,
        image_remote_url TEXT,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id TEXT PRIMARY KEY,
        branch_id TEXT NOT NULL,
        customer_id TEXT,
        user_id TEXT NOT NULL,
        total_amount REAL NOT NULL,
        paid_amount REAL NOT NULL,
        discount REAL DEFAULT 0.0,
        payment_method TEXT,
        sale_date TEXT,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        subtotal REAL NOT NULL,
        created_at TEXT,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');
    
    // Performance Indexes for Offline Sync Engine
    await db.execute('CREATE INDEX idx_products_updated_at ON products (updated_at)');
    await db.execute('CREATE INDEX idx_customers_updated_at ON customers (updated_at)');
    await db.execute('CREATE INDEX idx_sales_updated_at ON sales (updated_at)');
    
    // Foreign Key Indexes for Fast JOINs and Reporting
    await db.execute('CREATE INDEX idx_sales_customer ON sales (customer_id)');
    await db.execute('CREATE INDEX idx_sale_items_sale ON sale_items (sale_id)');
    await db.execute('CREATE INDEX idx_purchases_supplier ON purchases (supplier_id)');
    await db.execute('CREATE INDEX idx_purchase_items_purchase ON purchase_items (purchase_id)');
    await db.execute('CREATE INDEX idx_products_category ON products (category_id)');
  }
}
