// SQLite database setup, table creation, and CRUD operations.

import '../utils/debug_log.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/business_settings.dart';
import '../../models/category.dart';
import '../../models/customer.dart';
import '../../models/customer_history.dart';
import '../../models/dashboard_data.dart';
import '../../models/debt.dart';
import '../../models/debt_with_sale.dart';
import '../../models/invoice.dart';
import '../../models/product.dart';
import '../../models/purchase.dart';
import '../../models/report_data.dart';
import '../../models/sale.dart';
import '../../models/stock_movement.dart';
import '../utils/formatters.dart';

/// Singleton helper for all local SQLite database operations.
class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper _instance = DatabaseHelper._internal();

  /// Returns the shared [DatabaseHelper] instance.
  factory DatabaseHelper() => _instance;

  static Database? _database;

  static const String _dbName = 'vynex.db';
  static const int _dbVersion = 4;

  /// Opens or returns the cached database connection.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, _dbName);
      return openDatabase(
        path,
        version: _dbVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      logDebug('DatabaseHelper._initDatabase error: $e');
      rethrow;
    }
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE debts ADD COLUMN '
        'collected_revenue REAL NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE debts ADD COLUMN payment_history TEXT',
      );
      await db.execute(
        'UPDATE debts SET collected_revenue = amount_paid '
        'WHERE amount_paid > 0',
      );
      await db.execute(
        'UPDATE sales SET profit = 0, total_revenue = 0 '
        'WHERE is_fully_paid = 0',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE sales ADD COLUMN '
        'payment_method TEXT NOT NULL DEFAULT "cash"',
      );
      await db.execute(
        'ALTER TABLE sales ADD COLUMN '
        'sale_type TEXT NOT NULL DEFAULT "product"',
      );
    }

    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE sales ADD COLUMN product_id INTEGER',
      );
      await db.execute(
        'ALTER TABLE sales ADD COLUMN '
        'sale_source TEXT NOT NULL DEFAULT "manual"',
      );
      await db.execute(
        'ALTER TABLE sales ADD COLUMN customer_id INTEGER',
      );
      await db.execute(
        'ALTER TABLE sales ADD COLUMN spot_cost REAL',
      );

      await db.execute(
        'ALTER TABLE purchases ADD COLUMN product_id INTEGER',
      );
      await db.execute(
        'ALTER TABLE purchases ADD COLUMN '
        'purchase_type TEXT NOT NULL DEFAULT "general"',
      );

      await db.execute(
        'ALTER TABLE debts ADD COLUMN customer_id INTEGER',
      );

      await _createV2Tables(db);
      await _seedPredefinedCategories(db);
    }

    await _createV2Indexes(db);
  }

  Future<void> _createV2Indexes(Database db) async {
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sales_customer '
      'ON sales(customer_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sales_product '
      'ON sales(product_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_debts_customer '
      'ON debts(customer_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_movements_product '
      'ON stock_movements(product_id)',
    );
  }

  /// True when the database has business data (V1 upgrade skip onboarding).
  Future<bool> hasExistingUserData() async {
    try {
      final db = await database;
      for (final table in [
        'sales',
        'purchases',
        'products',
        'customers',
      ]) {
        final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $table'),
        );
        if ((count ?? 0) > 0) return true;
      }
      return false;
    } catch (e) {
      logDebug('DatabaseHelper.hasExistingUserData error: $e');
      return false;
    }
  }

  Future<void> _createV2Tables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        color_hex TEXT NOT NULL DEFAULT 'FFD700',
        icon_name TEXT NOT NULL DEFAULT 'category',
        is_predefined INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category_id INTEGER,
        barcode TEXT,
        default_cost_price REAL NOT NULL DEFAULT 0,
        default_selling_price REAL NOT NULL DEFAULT 0,
        current_stock INTEGER NOT NULL DEFAULT 0,
        low_stock_threshold INTEGER NOT NULL DEFAULT 5,
        unit TEXT NOT NULL DEFAULT 'piece',
        description TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        date_added TEXT NOT NULL,
        last_updated TEXT NOT NULL,
        FOREIGN KEY (category_id)
          REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        movement_type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        reference_id INTEGER,
        reference_type TEXT,
        note TEXT,
        date_recorded TEXT NOT NULL,
        FOREIGN KEY (product_id)
          REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        notes TEXT,
        date_added TEXT NOT NULL,
        last_updated TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_number TEXT NOT NULL UNIQUE,
        sale_id INTEGER,
        customer_id INTEGER,
        customer_name TEXT NOT NULL,
        customer_phone TEXT,
        subtotal REAL NOT NULL,
        total REAL NOT NULL,
        notes TEXT,
        date_issued TEXT NOT NULL,
        FOREIGN KEY (sale_id)
          REFERENCES sales(id) ON DELETE SET NULL,
        FOREIGN KEY (customer_id)
          REFERENCES customers(id) ON DELETE SET NULL
      )
    ''');
  }

  Future<void> _seedPredefinedCategories(Database db) async {
    final predefined = [
      {
        'name': 'Cables and Chargers',
        'color_hex': 'FFD700',
        'icon_name': 'cable',
        'is_predefined': 1,
        'sort_order': 1,
      },
      {
        'name': 'Phone Cases',
        'color_hex': '4CAF50',
        'icon_name': 'phone_android',
        'is_predefined': 1,
        'sort_order': 2,
      },
      {
        'name': 'Bulbs and Lighting',
        'color_hex': 'FFC107',
        'icon_name': 'lightbulb',
        'is_predefined': 1,
        'sort_order': 3,
      },
      {
        'name': 'Computer Accessories',
        'color_hex': '2196F3',
        'icon_name': 'computer',
        'is_predefined': 1,
        'sort_order': 4,
      },
      {
        'name': 'Repair Services',
        'color_hex': 'FF5722',
        'icon_name': 'build',
        'is_predefined': 1,
        'sort_order': 5,
      },
      {
        'name': 'Printing',
        'color_hex': '9C27B0',
        'icon_name': 'print',
        'is_predefined': 1,
        'sort_order': 6,
      },
      {
        'name': 'Stationery',
        'color_hex': '00BCD4',
        'icon_name': 'edit',
        'is_predefined': 1,
        'sort_order': 7,
      },
      {
        'name': 'Other',
        'color_hex': '607D8B',
        'icon_name': 'category',
        'is_predefined': 1,
        'sort_order': 8,
      },
    ];

    for (final cat in predefined) {
      await db.insert(
        'categories',
        cat,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        cost_price REAL NOT NULL,
        total_cost REAL NOT NULL,
        date_purchased TEXT NOT NULL,
        notes TEXT,
        product_id INTEGER,
        purchase_type TEXT NOT NULL DEFAULT 'general'
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_name TEXT NOT NULL,
        quantity_sold INTEGER NOT NULL DEFAULT 1,
        cost_price REAL NOT NULL,
        selling_price REAL NOT NULL,
        profit REAL NOT NULL,
        total_revenue REAL NOT NULL,
        is_fully_paid INTEGER NOT NULL DEFAULT 1,
        debt_note TEXT,
        date_sold TEXT NOT NULL,
        payment_method TEXT NOT NULL DEFAULT 'cash',
        sale_type TEXT NOT NULL DEFAULT 'product',
        product_id INTEGER,
        sale_source TEXT NOT NULL DEFAULT 'manual',
        customer_id INTEGER,
        spot_cost REAL
      )
    ''');

    await db.execute('''
      CREATE TABLE debts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        client_name TEXT,
        amount_owed REAL NOT NULL,
        amount_paid REAL NOT NULL DEFAULT 0,
        balance REAL NOT NULL,
        is_cleared INTEGER NOT NULL DEFAULT 0,
        date_created TEXT NOT NULL,
        last_updated TEXT NOT NULL,
        collected_revenue REAL NOT NULL DEFAULT 0,
        payment_history TEXT,
        customer_id INTEGER,
        FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE business_settings (
        id INTEGER PRIMARY KEY DEFAULT 1,
        business_name TEXT NOT NULL DEFAULT 'Vynex',
        owner_name TEXT,
        phone_number TEXT,
        currency_label TEXT NOT NULL DEFAULT 'KES',
        business_tagline TEXT,
        pin_hash TEXT NOT NULL DEFAULT '1234'
      )
    ''');

    await _createV2Tables(db);
    await _seedPredefinedCategories(db);
    await _createV2Indexes(db);
    await initSettings(db);
  }

  // ---------------------------------------------------------------------------
  // Purchase CRUD
  // ---------------------------------------------------------------------------

  /// Inserts a purchase and returns the new row id.
  Future<int> insertPurchase(Purchase purchase) async {
    try {
      final db = await database;
      final map = purchase.toMap()..remove('id');
      return db.insert('purchases', map);
    } catch (e) {
      logDebug('DatabaseHelper.insertPurchase error: $e');
      rethrow;
    }
  }

  /// Returns all purchases ordered by date descending.
  Future<List<Purchase>> getPurchases() async {
    try {
      final db = await database;
      final maps = await db.query(
        'purchases',
        orderBy: 'date_purchased DESC, id DESC',
      );
      return maps.map(Purchase.fromMap).toList();
    } catch (e) {
      logDebug('DatabaseHelper.getPurchases error: $e');
      rethrow;
    }
  }

  /// Get all purchases within a date range, inclusive.
  Future<List<Purchase>> getPurchasesByDateRange(
    String dateFrom,
    String dateTo,
  ) async {
    try {
      final db = await database;
      final maps = await db.query(
        'purchases',
        where: 'date_purchased >= ? AND date_purchased <= ?',
        whereArgs: [dateFrom, dateTo],
        orderBy: 'date_purchased ASC',
      );
      return maps.map(Purchase.fromMap).toList();
    } catch (e) {
      logDebug('DatabaseHelper.getPurchasesByDateRange error: $e');
      rethrow;
    }
  }

  /// Returns a single purchase by id, or null if not found.
  Future<Purchase?> getPurchaseById(int id) async {
    try {
      final db = await database;
      final maps = await db.query(
        'purchases',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return Purchase.fromMap(maps.first);
    } catch (e) {
      logDebug('DatabaseHelper.getPurchaseById error: $e');
      rethrow;
    }
  }

  /// Updates an existing purchase record.
  Future<int> updatePurchase(Purchase purchase) async {
    try {
      final db = await database;
      return db.update(
        'purchases',
        purchase.toMap(),
        where: 'id = ?',
        whereArgs: [purchase.id],
      );
    } catch (e) {
      logDebug('DatabaseHelper.updatePurchase error: $e');
      rethrow;
    }
  }

  /// Deletes a purchase by id.
  Future<int> deletePurchase(int id) async {
    try {
      final db = await database;
      return db.delete(
        'purchases',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      logDebug('DatabaseHelper.deletePurchase error: $e');
      rethrow;
    }
  }

  /// Returns the sum of all purchase total costs.
  Future<double> getTotalSpent() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COALESCE(SUM(total_cost), 0) AS total FROM purchases',
      );
      return (result.first['total'] as num?)?.toDouble() ?? 0;
    } catch (e) {
      logDebug('DatabaseHelper.getTotalSpent error: $e');
      rethrow;
    }
  }

  /// Returns the total number of purchase records.
  Future<int> getPurchasesCount() async {
    try {
      final db = await database;
      final result =
          await db.rawQuery('SELECT COUNT(*) AS count FROM purchases');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      logDebug('DatabaseHelper.getPurchasesCount error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Sale CRUD
  // ---------------------------------------------------------------------------

  /// Inserts a sale and returns the new row id.
  Future<int> insertSale(Sale sale) async {
    try {
      final db = await database;
      final map = sale.toMap();
      map.remove('id');
      return db.insert('sales', map);
    } catch (e) {
      logDebug('DatabaseHelper.insertSale error: $e');
      rethrow;
    }
  }

  /// Returns all sales ordered by date descending.
  Future<List<Sale>> getSales() async {
    try {
      final db = await database;
      final maps = await db.query(
        'sales',
        orderBy: 'date_sold DESC, id DESC',
      );
      return maps.map(Sale.fromMap).toList();
    } catch (e) {
      logDebug('DatabaseHelper.getSales error: $e');
      rethrow;
    }
  }

  /// Get all sales within a date range, inclusive.
  Future<List<Sale>> getSalesByDateRange(
    String dateFrom,
    String dateTo,
  ) async {
    try {
      final db = await database;
      final maps = await db.query(
        'sales',
        where: 'date_sold >= ? AND date_sold <= ?',
        whereArgs: [dateFrom, dateTo],
        orderBy: 'date_sold ASC',
      );
      return maps.map(Sale.fromMap).toList();
    } catch (e) {
      logDebug('DatabaseHelper.getSalesByDateRange error: $e');
      rethrow;
    }
  }

  /// Returns a single sale by id, or null if not found.
  Future<Sale?> getSaleById(int id) async {
    try {
      final db = await database;
      final maps = await db.query(
        'sales',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return Sale.fromMap(maps.first);
    } catch (e) {
      logDebug('DatabaseHelper.getSaleById error: $e');
      rethrow;
    }
  }

  /// Updates an existing sale record.
  Future<int> updateSale(Sale sale) async {
    try {
      final db = await database;
      return db.update(
        'sales',
        sale.toMap(),
        where: 'id = ?',
        whereArgs: [sale.id],
      );
    } catch (e) {
      logDebug('DatabaseHelper.updateSale error: $e');
      rethrow;
    }
  }

  /// Deletes a sale by id.
  Future<int> deleteSale(int id) async {
    try {
      final db = await database;
      return db.delete(
        'sales',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      logDebug('DatabaseHelper.deleteSale error: $e');
      rethrow;
    }
  }

  /// Returns the sum of all sale total revenue.
  Future<double> getTotalRevenue() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COALESCE(SUM(total_revenue), 0) AS total FROM sales',
      );
      return (result.first['total'] as num?)?.toDouble() ?? 0;
    } catch (e) {
      logDebug('DatabaseHelper.getTotalRevenue error: $e');
      rethrow;
    }
  }

  /// Returns the sum of all sale profit.
  Future<double> getTotalProfit() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COALESCE(SUM(profit), 0) AS total FROM sales',
      );
      return (result.first['total'] as num?)?.toDouble() ?? 0;
    } catch (e) {
      logDebug('DatabaseHelper.getTotalProfit error: $e');
      rethrow;
    }
  }

  /// Returns the total number of sale records.
  Future<int> getSalesCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) AS count FROM sales');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      logDebug('DatabaseHelper.getSalesCount error: $e');
      rethrow;
    }
  }

  /// Returns all-time profit from sales.
  Future<double> getAllTimeProfit() async {
    return getTotalProfit();
  }

  String _reportFilterClause({
    String paymentMethodFilter = 'all',
    String saleTypeFilter = 'all',
    String saleSourceFilter = 'all',
  }) {
    var clause = '';
    if (paymentMethodFilter != 'all') {
      clause += " AND payment_method = '$paymentMethodFilter'";
    }
    if (saleTypeFilter != 'all') {
      clause += " AND sale_type = '$saleTypeFilter'";
    }
    if (saleSourceFilter != 'all') {
      clause += " AND sale_source = '$saleSourceFilter'";
    }
    return clause;
  }

  /// Get daily revenue and profit totals for the line chart.
  Future<List<Map<String, dynamic>>> getDailyChartData(
    String dateFrom,
    String dateTo, {
    String paymentMethodFilter = 'all',
    String saleTypeFilter = 'all',
    String saleSourceFilter = 'all',
  }) async {
    try {
      final db = await database;
      final filter = _reportFilterClause(
        paymentMethodFilter: paymentMethodFilter,
        saleTypeFilter: saleTypeFilter,
        saleSourceFilter: saleSourceFilter,
      );
      final result = await db.rawQuery(
        '''
        SELECT
          date_sold AS date,
          SUM(total_revenue) AS revenue,
          SUM(profit) AS profit
        FROM sales
        WHERE date_sold >= ?
          AND date_sold <= ?
          AND is_fully_paid = 1
          $filter
        GROUP BY date_sold
        ORDER BY date_sold ASC
        ''',
        [dateFrom, dateTo],
      );
      return result
          .map(
            (r) => {
              'date': r['date'] as String,
              'revenue': (r['revenue'] as num?)?.toDouble() ?? 0.0,
              'profit': (r['profit'] as num?)?.toDouble() ?? 0.0,
            },
          )
          .toList();
    } catch (e) {
      logDebug('DatabaseHelper.getDailyChartData error: $e');
      rethrow;
    }
  }

  /// Get monthly revenue and profit for the bar chart.
  Future<List<Map<String, dynamic>>> getMonthlyChartData() async {
    try {
      final db = await database;
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
      final fromStr = '${sixMonthsAgo.year}-'
          '${sixMonthsAgo.month.toString().padLeft(2, '0')}-01';

      final result = await db.rawQuery(
        '''
        SELECT
          substr(date_sold, 1, 7) AS month,
          SUM(total_revenue) AS revenue,
          SUM(profit) AS profit,
          COUNT(*) AS count
        FROM sales
        WHERE date_sold >= ?
          AND is_fully_paid = 1
        GROUP BY substr(date_sold, 1, 7)
        ORDER BY month ASC
        ''',
        [fromStr],
      );

      return result
          .map(
            (r) => {
              'month': r['month'] as String,
              'revenue': (r['revenue'] as num?)?.toDouble() ?? 0.0,
              'profit': (r['profit'] as num?)?.toDouble() ?? 0.0,
              'count': (r['count'] as num?)?.toInt() ?? 0,
            },
          )
          .toList();
    } catch (e) {
      logDebug('DatabaseHelper.getMonthlyChartData error: $e');
      rethrow;
    }
  }

  /// Get top items ranked by total profit for a period.
  Future<List<Map<String, dynamic>>> getTopItems(
    String dateFrom,
    String dateTo, {
    int limit = 10,
    String paymentMethodFilter = 'all',
    String saleTypeFilter = 'all',
    String saleSourceFilter = 'all',
  }) async {
    try {
      final db = await database;
      final filter = _reportFilterClause(
        paymentMethodFilter: paymentMethodFilter,
        saleTypeFilter: saleTypeFilter,
        saleSourceFilter: saleSourceFilter,
      );
      final result = await db.rawQuery(
        '''
        SELECT
          item_name,
          SUM(quantity_sold) AS total_qty,
          SUM(total_revenue) AS total_revenue,
          SUM(profit) AS total_profit
        FROM sales
        WHERE date_sold >= ?
          AND date_sold <= ?
          AND is_fully_paid = 1
          $filter
        GROUP BY item_name
        ORDER BY total_profit DESC
        LIMIT ?
        ''',
        [dateFrom, dateTo, limit],
      );

      return result
          .map(
            (r) => {
              'item_name': r['item_name'] as String,
              'total_qty': (r['total_qty'] as num?)?.toInt() ?? 0,
              'total_revenue': (r['total_revenue'] as num?)?.toDouble() ?? 0.0,
              'total_profit': (r['total_profit'] as num?)?.toDouble() ?? 0.0,
            },
          )
          .toList();
    } catch (e) {
      logDebug('DatabaseHelper.getTopItems error: $e');
      rethrow;
    }
  }

  /// Count sales paid via installments (cleared debt) in a period.
  Future<int> getInstallmentSalesCount({
    required String dateFrom,
    required String dateTo,
  }) async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        '''
        SELECT COUNT(*) as count
        FROM sales s
        INNER JOIN debts d ON d.sale_id = s.id
        WHERE s.date_sold >= ? AND s.date_sold <= ?
          AND s.is_fully_paid = 1
          AND d.is_cleared = 1
        ''',
        [dateFrom, dateTo],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      logDebug('DatabaseHelper.getInstallmentSalesCount error: $e');
      rethrow;
    }
  }

  /// Get summary statistics for the selected period.
  Future<Map<String, dynamic>> getPeriodSummary(
    String dateFrom,
    String dateTo, {
    String paymentMethodFilter = 'all',
    String saleTypeFilter = 'all',
    String saleSourceFilter = 'all',
  }) async {
    try {
      final db = await database;
      final filter = _reportFilterClause(
        paymentMethodFilter: paymentMethodFilter,
        saleTypeFilter: saleTypeFilter,
        saleSourceFilter: saleSourceFilter,
      );

      final salesResult = await db.rawQuery(
        '''
        SELECT
          COUNT(*) AS count,
          SUM(total_revenue) AS revenue,
          SUM(profit) AS profit
        FROM sales
        WHERE date_sold >= ? AND date_sold <= ?
          AND is_fully_paid = 1
          $filter
        ''',
        [dateFrom, dateTo],
      );

      final allSalesResult = await db.rawQuery(
        '''
        SELECT COUNT(*) AS count
        FROM sales
        WHERE date_sold >= ? AND date_sold <= ?
          $filter
        ''',
        [dateFrom, dateTo],
      );

      final purchasesResult = await db.rawQuery(
        '''
        SELECT
          COUNT(*) AS count,
          SUM(total_cost) AS spent
        FROM purchases
        WHERE date_purchased >= ? AND date_purchased <= ?
        ''',
        [dateFrom, dateTo],
      );

      final pendingDebtsResult = await db.rawQuery(
        '''
        SELECT
          COUNT(*) AS count,
          SUM(balance) AS balance
        FROM debts
        WHERE is_cleared = 0
        ''',
      );

      final s = salesResult.first;
      final allS = allSalesResult.first;
      final p = purchasesResult.first;
      final d = pendingDebtsResult.first;

      return {
        'paid_sales_count': (s['count'] as num?)?.toInt() ?? 0,
        'total_sales_count': (allS['count'] as num?)?.toInt() ?? 0,
        'total_revenue': (s['revenue'] as num?)?.toDouble() ?? 0.0,
        'total_profit': (s['profit'] as num?)?.toDouble() ?? 0.0,
        'purchases_count': (p['count'] as num?)?.toInt() ?? 0,
        'total_spent': (p['spent'] as num?)?.toDouble() ?? 0.0,
        'pending_debts_count': (d['count'] as num?)?.toInt() ?? 0,
        'total_debt_balance': (d['balance'] as num?)?.toDouble() ?? 0.0,
      };
    } catch (e) {
      logDebug('DatabaseHelper.getPeriodSummary error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Debt CRUD
  // ---------------------------------------------------------------------------

  /// Inserts a debt and returns the new row id.
  Future<int> insertDebt(Debt debt) async {
    try {
      final db = await database;
      final map = debt.toMap();
      map.remove('id');
      return db.insert('debts', map);
    } catch (e) {
      logDebug('DatabaseHelper.insertDebt error: $e');
      rethrow;
    }
  }

  /// Returns all debts: pending first, then cleared by date created.
  Future<List<Debt>> getDebts() async {
    try {
      final db = await database;
      final maps = await db.query(
        'debts',
        orderBy: 'is_cleared ASC, date_created DESC',
      );
      return maps.map(Debt.fromMap).toList();
    } catch (e) {
      logDebug('DatabaseHelper.getDebts error: $e');
      rethrow;
    }
  }

  /// Returns a single debt by id, or null if not found.
  Future<Debt?> getDebtById(int id) async {
    try {
      final db = await database;
      final maps = await db.query(
        'debts',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return Debt.fromMap(maps.first);
    } catch (e) {
      logDebug('DatabaseHelper.getDebtById error: $e');
      rethrow;
    }
  }

  /// Returns debts joined with sale item name and revenue.
  Future<List<DebtWithSale>> getDebtsWithSale() async {
    try {
      final db = await database;
      final maps = await db.rawQuery('''
        SELECT
          d.*,
          s.item_name,
          s.date_sold,
          s.total_revenue AS sale_revenue
        FROM debts d
        INNER JOIN sales s ON d.sale_id = s.id
        ORDER BY d.is_cleared ASC, d.date_created DESC
        ''');
      return maps.map((m) {
        final debt = Debt.fromMap(m);
        return DebtWithSale(
          debt: debt,
          itemName: m['item_name'] as String,
          dateSold: m['date_sold'] as String,
          saleRevenue: (m['sale_revenue'] as num).toDouble(),
        );
      }).toList();
    } catch (e) {
      logDebug('DatabaseHelper.getDebtsWithSale error: $e');
      rethrow;
    }
  }

  /// Returns the debt linked to a sale, or null if not found.
  Future<Debt?> getDebtBySaleId(int saleId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'debts',
        where: 'sale_id = ?',
        whereArgs: [saleId],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return Debt.fromMap(maps.first);
    } catch (e) {
      logDebug('DatabaseHelper.getDebtBySaleId error: $e');
      rethrow;
    }
  }

  /// Updates an existing debt record.
  Future<int> updateDebt(Debt debt) async {
    try {
      final db = await database;
      return db.update(
        'debts',
        debt.toMap(),
        where: 'id = ?',
        whereArgs: [debt.id],
      );
    } catch (e) {
      logDebug('DatabaseHelper.updateDebt error: $e');
      rethrow;
    }
  }

  /// Marks a debt as fully cleared.
  Future<int> markDebtCleared(int id) async {
    try {
      final db = await database;
      final debtMaps = await db.query(
        'debts',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (debtMaps.isEmpty) return 0;

      final debt = Debt.fromMap(debtMaps.first);
      final cleared = debt.copyWith(
        amountPaid: debt.amountOwed,
        isCleared: true,
        lastUpdated: Formatters.todayString(),
      );
      return updateDebt(cleared);
    } catch (e) {
      logDebug('DatabaseHelper.markDebtCleared error: $e');
      rethrow;
    }
  }

  /// Returns the count of debts that are not cleared.
  Future<int> getPendingDebtsCount() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) AS count FROM debts WHERE is_cleared = 0',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      logDebug('DatabaseHelper.getPendingDebtsCount error: $e');
      rethrow;
    }
  }

  /// Returns the sum of all pending debt balances.
  Future<double> getTotalDebtBalance() async {
    try {
      final db = await database;
      final result = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(balance), 0) AS total
        FROM debts
        WHERE is_cleared = 0
        ''',
      );
      return (result.first['total'] as num?)?.toDouble() ?? 0;
    } catch (e) {
      logDebug('DatabaseHelper.getTotalDebtBalance error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Settings
  // ---------------------------------------------------------------------------

  /// Inserts default business settings on first launch.
  Future<void> initSettings([Database? dbInstance]) async {
    try {
      final db = dbInstance ?? await database;
      final existing = await db.query(
        'business_settings',
        where: 'id = ?',
        whereArgs: [1],
        limit: 1,
      );
      if (existing.isEmpty) {
        final defaults = BusinessSettings.defaults();
        await db.insert('business_settings', defaults.toMap());
      }
    } catch (e) {
      logDebug('DatabaseHelper.initSettings error: $e');
      rethrow;
    }
  }

  /// Returns the business settings row.
  Future<BusinessSettings> getSettings() async {
    try {
      final db = await database;
      await initSettings(db);
      final maps = await db.query(
        'business_settings',
        where: 'id = ?',
        whereArgs: [1],
        limit: 1,
      );
      if (maps.isEmpty) {
        final defaults = BusinessSettings.defaults();
        await db.insert('business_settings', defaults.toMap());
        return defaults;
      }
      return BusinessSettings.fromMap(maps.first);
    } catch (e) {
      logDebug('DatabaseHelper.getSettings error: $e');
      return BusinessSettings.defaults();
    }
  }

  /// Updates business settings.
  Future<int> updateSettings(BusinessSettings settings) async {
    try {
      final db = await database;
      return db.update(
        'business_settings',
        settings.toMap(),
        where: 'id = ?',
        whereArgs: [settings.id],
      );
    } catch (e) {
      logDebug('DatabaseHelper.updateSettings error: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Dashboard aggregates
  // ---------------------------------------------------------------------------

  /// Returns revenue, profit, and spent totals for the given month.
  Future<Map<String, double>> getMonthlyStats(DateTime month) async {
    try {
      final db = await database;
      final start = Formatters.monthStartString(month);
      final end = Formatters.monthEndString(month);

      final revenueResult = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(total_revenue), 0) AS total
        FROM sales
        WHERE date_sold >= ? AND date_sold <= ?
        ''',
        [start, end],
      );

      final profitResult = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(profit), 0) AS total
        FROM sales
        WHERE date_sold >= ? AND date_sold <= ?
        ''',
        [start, end],
      );

      final spentResult = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(total_cost), 0) AS total
        FROM purchases
        WHERE date_purchased >= ? AND date_purchased <= ?
        ''',
        [start, end],
      );

      return {
        'revenue': (revenueResult.first['total'] as num?)?.toDouble() ?? 0,
        'profit': (profitResult.first['total'] as num?)?.toDouble() ?? 0,
        'spent': (spentResult.first['total'] as num?)?.toDouble() ?? 0,
      };
    } catch (e) {
      logDebug('DatabaseHelper.getMonthlyStats error: $e');
      rethrow;
    }
  }

  /// Returns aggregated dashboard statistics and recent records.
  Future<DashboardData> getDashboardData() async {
    try {
      final db = await database;

      final purchaseCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM purchases'),
          ) ??
          0;

      final saleCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM sales'),
          ) ??
          0;

      final profitResult = await db.rawQuery(
        'SELECT SUM(profit) as total FROM sales',
      );
      final totalProfit =
          (profitResult.first['total'] as num?)?.toDouble() ?? 0.0;

      final pendingDebts = Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM debts WHERE is_cleared = 0',
            ),
          ) ??
          0;

      final now = DateTime.now();
      final monthStart =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-01';

      final monthRevenueResult = await db.rawQuery(
        'SELECT SUM(total_revenue) as total FROM sales '
        'WHERE date_sold >= ?',
        [monthStart],
      );
      final monthRevenue =
          (monthRevenueResult.first['total'] as num?)?.toDouble() ?? 0.0;

      final monthProfitResult = await db.rawQuery(
        'SELECT SUM(profit) as total FROM sales '
        'WHERE date_sold >= ?',
        [monthStart],
      );
      final monthProfit =
          (monthProfitResult.first['total'] as num?)?.toDouble() ?? 0.0;

      final monthSpentResult = await db.rawQuery(
        'SELECT SUM(total_cost) as total FROM purchases '
        'WHERE date_purchased >= ?',
        [monthStart],
      );
      final monthSpent =
          (monthSpentResult.first['total'] as num?)?.toDouble() ?? 0.0;

      final salesMaps = await db.query(
        'sales',
        orderBy: 'date_sold DESC, id DESC',
        limit: 5,
      );
      final recentSales = salesMaps.map(Sale.fromMap).toList();

      final purchaseMaps = await db.query(
        'purchases',
        orderBy: 'date_purchased DESC, id DESC',
        limit: 3,
      );
      final recentPurchases = purchaseMaps.map(Purchase.fromMap).toList();

      final inventorySummary = await getInventorySummary();
      final customerStats = await getCustomerStats();

      return DashboardData(
        totalPurchases: purchaseCount,
        totalSales: saleCount,
        totalProfit: totalProfit,
        pendingDebts: pendingDebts,
        monthRevenue: monthRevenue,
        monthProfit: monthProfit,
        monthSpent: monthSpent,
        recentSales: recentSales,
        recentPurchases: recentPurchases,
        totalCatalogProducts:
            inventorySummary['total_products'] as int,
        lowStockCount: inventorySummary['low_stock_count'] as int,
        outOfStockCount:
            inventorySummary['out_of_stock_count'] as int,
        totalInventoryValue:
            inventorySummary['total_inventory_value'] as double,
        totalCustomers: customerStats['total_customers'] as int,
        customersWithDebt:
            customerStats['customers_with_debt'] as int,
      );
    } catch (e) {
      logDebug('DatabaseHelper.getDashboardData error: $e');
      rethrow;
    }
  }

  /// Closes the database connection so the file can be replaced.
  Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }

  // ---------------------------------------------------------------------------
  // V2 Category CRUD
  // ---------------------------------------------------------------------------

  Future<List<Category>> getCategories() async {
    final db = await database;
    final maps = await db.query(
      'categories',
      orderBy: 'sort_order ASC, name ASC',
    );
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return db.delete(
      'categories',
      where: 'id = ? AND is_predefined = 0',
      whereArgs: [id],
    );
  }

  // ---------------------------------------------------------------------------
  // V2 Product CRUD
  // ---------------------------------------------------------------------------

  Future<List<Product>> getProducts() async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'is_active = 1',
      orderBy: 'name ASC',
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  Future<int> insertProduct(Product product) async {
    final db = await database;
    return db.insert(
      'products',
      product.toMap()..remove('id'),
    );
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'barcode = ? AND is_active = 1',
      whereArgs: [barcode],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<Product?> getProductById(int id) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  /// Search products by name or barcode.
  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'is_active = 1 AND '
          '(name LIKE ? OR barcode LIKE ?)',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  /// Get products with low or zero stock.
  Future<List<Product>> getLowStockProducts() async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'is_active = 1 AND '
          'current_stock <= low_stock_threshold',
      orderBy: 'current_stock ASC',
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  /// Update stock quantity directly.
  Future<void> updateProductStock(
    int productId,
    int newStock,
  ) async {
    final db = await database;
    final today = DateTime.now()
        .toIso8601String()
        .substring(0, 10);
    await db.update(
      'products',
      {
        'current_stock': newStock,
        'last_updated': today,
      },
      where: 'id = ?',
      whereArgs: [productId],
    );
  }

  // ---------------------------------------------------------------------------
  // V2 Customer CRUD
  // ---------------------------------------------------------------------------

  Future<List<Customer>> getCustomers() async {
    final db = await database;
    final maps = await db.query(
      'customers',
      orderBy: 'name ASC',
    );
    return maps.map((m) => Customer.fromMap(m)).toList();
  }

  Future<int> insertCustomer(Customer customer) async {
    final db = await database;
    return db.insert(
      'customers',
      customer.toMap()..remove('id'),
    );
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await database;
    return db.update(
      'customers',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<Customer?> getCustomerById(int id) async {
    final db = await database;
    final maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Customer.fromMap(maps.first);
  }

  /// Delete a customer and unlink from sales and debts.
  Future<void> deleteCustomer(int id) async {
    final db = await database;
    await db.update(
      'sales',
      {'customer_id': null},
      where: 'customer_id = ?',
      whereArgs: [id],
    );
    await db.update(
      'debts',
      {'customer_id': null},
      where: 'customer_id = ?',
      whereArgs: [id],
    );
    await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get complete customer history including sales,
  /// debts, stats and favorite items.
  Future<CustomerHistory> getCustomerHistory(
    int customerId,
  ) async {
    final db = await database;

    final salesMaps = await db.query(
      'sales',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date_sold DESC',
    );
    final sales = salesMaps.map((m) => Sale.fromMap(m)).toList();

    final spentResult = await db.rawQuery('''
      SELECT COALESCE(SUM(total_revenue), 0) as total
      FROM sales
      WHERE customer_id = ? AND is_fully_paid = 1
    ''', [customerId]);
    final totalSpent =
        (spentResult.first['total'] as num?)?.toDouble() ?? 0.0;

    final debtsMaps = await db.query(
      'debts',
      where: 'customer_id = ? AND is_cleared = 0',
      whereArgs: [customerId],
      orderBy: 'date_created DESC',
    );
    final activeDebts = debtsMaps.map((m) => Debt.fromMap(m)).toList();

    final balanceResult = await db.rawQuery('''
      SELECT COALESCE(SUM(balance), 0) as total
      FROM debts
      WHERE customer_id = ? AND is_cleared = 0
    ''', [customerId]);
    final outstandingBalance =
        (balanceResult.first['total'] as num?)?.toDouble() ?? 0.0;

    final lastPurchase =
        sales.isNotEmpty ? sales.first.dateSold : null;

    final favResult = await db.rawQuery('''
      SELECT
        item_name,
        COUNT(*) as purchase_count,
        SUM(quantity_sold) as total_qty,
        SUM(total_revenue) as total_spent
      FROM sales
      WHERE customer_id = ?
      GROUP BY item_name
      ORDER BY total_qty DESC
      LIMIT 5
    ''', [customerId]);

    final favoriteItems = favResult.map((row) {
      return {
        'item_name': row['item_name'] as String,
        'purchase_count': row['purchase_count'] as int,
        'total_qty': row['total_qty'] as int,
        'total_spent': (row['total_spent'] as num).toDouble(),
      };
    }).toList();

    return CustomerHistory(
      customerId: customerId,
      totalSalesCount: sales.length,
      totalAmountSpent: totalSpent,
      outstandingDebtBalance: outstandingBalance,
      lastPurchaseDate: lastPurchase,
      recentSales: sales,
      activeDebts: activeDebts,
      favoriteItems: favoriteItems,
    );
  }

  /// Get all sales linked to a customer.
  Future<List<Sale>> getCustomerSales(int customerId) async {
    final db = await database;
    final maps = await db.query(
      'sales',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date_sold DESC',
    );
    return maps.map((m) => Sale.fromMap(m)).toList();
  }

  /// Get all debts linked to a customer with sale item names.
  Future<List<DebtWithSale>> getCustomerDebts(
    int customerId, {
    bool clearedOnly = false,
    bool activeOnly = false,
  }) async {
    final db = await database;
    var where = 'd.customer_id = ?';
    final args = <Object>[customerId];
    if (clearedOnly) {
      where += ' AND d.is_cleared = 1';
    } else if (activeOnly) {
      where += ' AND d.is_cleared = 0';
    }
    final maps = await db.rawQuery('''
      SELECT d.*, s.item_name as sale_item_name,
             s.date_sold as sale_date_sold,
             s.total_revenue as sale_revenue
      FROM debts d
      LEFT JOIN sales s ON d.sale_id = s.id
      WHERE $where
      ORDER BY d.date_created DESC
    ''', args);
    return maps.map((m) {
      final debtMap = Map<String, dynamic>.from(m);
      final itemName = debtMap.remove('sale_item_name') as String? ?? '';
      final dateSold =
          debtMap.remove('sale_date_sold') as String? ?? '';
      final saleRevenue =
          (debtMap.remove('sale_revenue') as num?)?.toDouble() ?? 0.0;
      return DebtWithSale(
        debt: Debt.fromMap(debtMap),
        itemName: itemName.isEmpty ? 'Unknown item' : itemName,
        dateSold: dateSold,
        saleRevenue: saleRevenue,
      );
    }).toList();
  }

  /// Link a sale to a customer.
  Future<void> linkSaleToCustomer(
    int saleId,
    int customerId,
  ) async {
    final db = await database;
    await db.update(
      'sales',
      {'customer_id': customerId},
      where: 'id = ?',
      whereArgs: [saleId],
    );
  }

  /// Link a debt to a customer (when sale has customer).
  Future<void> linkDebtToCustomer(
    int debtId,
    int customerId,
  ) async {
    final db = await database;
    await db.update(
      'debts',
      {'customer_id': customerId},
      where: 'id = ?',
      whereArgs: [debtId],
    );
  }

  /// Last purchase date per customer (single query).
  Future<Map<int, String>> getCustomerLastPurchaseDates() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT customer_id,
             MAX(date_sold) as last_date
      FROM sales
      WHERE customer_id IS NOT NULL
      GROUP BY customer_id
    ''');
    return {
      for (final row in result)
        row['customer_id'] as int: row['last_date'] as String,
    };
  }

  /// Customer ids with outstanding debt.
  Future<Set<int>> getCustomerIdsWithOutstandingDebt() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DISTINCT customer_id as id
      FROM debts
      WHERE customer_id IS NOT NULL
        AND is_cleared = 0
    ''');
    return result.map((r) => r['id'] as int).toSet();
  }

  /// Get customer stats for dashboard.
  Future<Map<String, dynamic>> getCustomerStats() async {
    final db = await database;

    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM customers',
    );
    final total = Sqflite.firstIntValue(totalResult) ?? 0;

    final withDebtResult = await db.rawQuery('''
      SELECT COUNT(DISTINCT customer_id) as count
      FROM debts
      WHERE customer_id IS NOT NULL
        AND is_cleared = 0
    ''');
    final withDebt = Sqflite.firstIntValue(withDebtResult) ?? 0;

    return {
      'total_customers': total,
      'customers_with_debt': withDebt,
    };
  }

  // ---------------------------------------------------------------------------
  // V2 Stock movement CRUD
  // ---------------------------------------------------------------------------

  Future<int> insertStockMovement(StockMovement movement) async {
    final db = await database;
    return db.insert(
      'stock_movements',
      movement.toMap()..remove('id'),
    );
  }

  /// Get all stock movements for a product, newest first.
  Future<List<StockMovement>> getStockMovements(
    int productId, {
    int? limit,
  }) async {
    final db = await database;
    final maps = await db.query(
      'stock_movements',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'date_recorded DESC, id DESC',
      limit: limit,
    );
    return maps.map((m) => StockMovement.fromMap(m)).toList();
  }

  /// Get total number of stock movements for a product.
  Future<int> getStockMovementCount(int productId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM stock_movements '
      'WHERE product_id = ?',
      [productId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get all products sorted by stock level ascending.
  /// Products with lowest stock appear first.
  Future<List<Product>> getProductsByStockLevel() async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'is_active = 1',
      orderBy: 'current_stock ASC, name ASC',
    );
    return maps.map((m) => Product.fromMap(m)).toList();
  }

  /// Get inventory summary stats.
  Future<Map<String, dynamic>> getInventorySummary() async {
    final db = await database;

    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products '
      'WHERE is_active = 1',
    );
    final totalProducts = Sqflite.firstIntValue(totalResult) ?? 0;

    final lowResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products '
      'WHERE is_active = 1 '
      'AND current_stock <= low_stock_threshold '
      'AND current_stock > 0',
    );
    final lowStockCount = Sqflite.firstIntValue(lowResult) ?? 0;

    final outResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products '
      'WHERE is_active = 1 AND current_stock = 0',
    );
    final outOfStockCount = Sqflite.firstIntValue(outResult) ?? 0;

    final valueResult = await db.rawQuery(
      'SELECT SUM(current_stock * default_cost_price) '
      'as total_value FROM products WHERE is_active = 1',
    );
    final totalValue =
        (valueResult.first['total_value'] as num?)?.toDouble() ?? 0.0;

    final retailResult = await db.rawQuery(
      'SELECT SUM(current_stock * default_selling_price) '
      'as retail_value FROM products WHERE is_active = 1',
    );
    final retailValue =
        (retailResult.first['retail_value'] as num?)?.toDouble() ?? 0.0;

    return {
      'total_products': totalProducts,
      'low_stock_count': lowStockCount,
      'out_of_stock_count': outOfStockCount,
      'total_inventory_value': totalValue,
      'total_retail_value': retailValue,
    };
  }

  // ---------------------------------------------------------------------------
  // V2 Invoice CRUD
  // ---------------------------------------------------------------------------

  Future<int> insertInvoice(Invoice invoice) async {
    final db = await database;
    return db.insert(
      'invoices',
      invoice.toMap()..remove('id'),
    );
  }

  Future<List<Invoice>> getInvoices() async {
    final db = await database;
    final maps = await db.query(
      'invoices',
      orderBy: 'date_issued DESC, id DESC',
    );
    return maps.map((m) => Invoice.fromMap(m)).toList();
  }

  Future<int> getInvoiceCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM invoices',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Invoice?> getInvoiceById(int id) async {
    final db = await database;
    final maps = await db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Invoice.fromMap(maps.first);
  }

  Future<List<Invoice>> getInvoicesForSale(
    int saleId,
  ) async {
    final db = await database;
    final maps = await db.query(
      'invoices',
      where: 'sale_id = ?',
      whereArgs: [saleId],
      orderBy: 'date_issued DESC',
    );
    return maps.map((m) => Invoice.fromMap(m)).toList();
  }

  Future<List<Invoice>> getInvoicesForCustomer(
    int customerId,
  ) async {
    final db = await database;
    final maps = await db.query(
      'invoices',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'date_issued DESC',
    );
    return maps.map((m) => Invoice.fromMap(m)).toList();
  }

  Future<int> deleteInvoice(int id) async {
    final db = await database;
    return db.delete(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get inventory report data.
  Future<InventoryReportData> getInventoryReportData() async {
    try {
      final db = await database;

      final allProducts = await db.query(
        'products',
        where: 'is_active = 1',
      );

      var inStock = 0;
      var lowStock = 0;
      var outOfStock = 0;
      var costValue = 0.0;
      var retailValue = 0.0;

      for (final p in allProducts) {
        final stock = p['current_stock'] as int;
        final threshold = p['low_stock_threshold'] as int;
        final cost = (p['default_cost_price'] as num).toDouble();
        final retail = (p['default_selling_price'] as num).toDouble();

        costValue += stock * cost;
        retailValue += stock * retail;

        if (stock == 0) {
          outOfStock++;
        } else if (stock <= threshold) {
          lowStock++;
        } else {
          inStock++;
        }
      }

      final potentialProfit = retailValue - costValue;

      final lowMaps = await db.rawQuery('''
        SELECT id, name, current_stock,
               low_stock_threshold, unit
        FROM products
        WHERE is_active = 1
          AND current_stock <= low_stock_threshold
        ORDER BY current_stock ASC
        LIMIT 20
      ''');
      final lowStockItems = lowMaps
          .map(
            (m) => LowStockItem(
              productId: m['id'] as int,
              productName: m['name'] as String,
              currentStock: m['current_stock'] as int,
              threshold: m['low_stock_threshold'] as int,
              unit: m['unit'] as String? ?? 'piece',
            ),
          )
          .toList();

      final thirtyDaysAgo = DateTime.now()
          .subtract(const Duration(days: 30))
          .toIso8601String()
          .substring(0, 10);

      final deadMaps = await db.rawQuery('''
        SELECT p.id, p.name, p.current_stock,
               p.default_cost_price,
               MAX(s.date_sold) as last_sale
        FROM products p
        LEFT JOIN sales s ON s.product_id = p.id
        WHERE p.is_active = 1
          AND p.current_stock > 0
        GROUP BY p.id
        HAVING last_sale IS NULL
            OR last_sale < ?
        ORDER BY p.current_stock DESC
        LIMIT 10
      ''', [thirtyDaysAgo]);

      final deadStockItems = deadMaps.map((m) {
        final stock = m['current_stock'] as int;
        final cost = (m['default_cost_price'] as num).toDouble();
        return DeadStockItem(
          productId: m['id'] as int,
          productName: m['name'] as String,
          currentStock: stock,
          stockValue: stock * cost,
          lastSaleDate: m['last_sale'] as String? ?? 'Never sold',
        );
      }).toList();

      final topMaps = await db.rawQuery('''
        SELECT
          p.name as product_name,
          COALESCE(SUM(s.quantity_sold), 0) as total_units,
          COALESCE(SUM(s.total_revenue), 0) as total_revenue,
          COUNT(DISTINCT sm.id) as restock_count
        FROM products p
        LEFT JOIN sales s
          ON s.product_id = p.id
          AND s.sale_source = 'stock'
        LEFT JOIN stock_movements sm
          ON sm.product_id = p.id
          AND sm.movement_type = 'restock'
        WHERE p.is_active = 1
        GROUP BY p.id
        ORDER BY total_units DESC
        LIMIT 10
      ''');

      final topMoving = topMaps
          .map(
            (m) => TopMovingItem(
              productName: m['product_name'] as String,
              totalUnitsSold: (m['total_units'] as num).toInt(),
              totalRevenue: (m['total_revenue'] as num).toDouble(),
              restockCount: (m['restock_count'] as num).toInt(),
            ),
          )
          .toList();

      return InventoryReportData(
        totalProducts: allProducts.length,
        inStockCount: inStock,
        lowStockCount: lowStock,
        outOfStockCount: outOfStock,
        totalStockValueAtCost: costValue,
        totalStockValueAtRetail: retailValue,
        potentialProfit: potentialProfit,
        lowStockItems: lowStockItems,
        deadStockItems: deadStockItems,
        topMovingItems: topMoving,
      );
    } catch (e) {
      logDebug('DatabaseHelper.getInventoryReportData error: $e');
      rethrow;
    }
  }

  /// Get customer report data for a date range.
  Future<CustomerReportData> getCustomerReportData({
    required String dateFrom,
    required String dateTo,
  }) async {
    try {
      final db = await database;

      final totalResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM customers',
      );
      final total = Sqflite.firstIntValue(totalResult) ?? 0;

      final newResult = await db.rawQuery('''
        SELECT COUNT(*) as count FROM customers
        WHERE date_added >= ? AND date_added <= ?
      ''', [dateFrom, dateTo]);
      final newCount = Sqflite.firstIntValue(newResult) ?? 0;

      final debtResult = await db.rawQuery('''
        SELECT COUNT(DISTINCT customer_id) as count
        FROM debts
        WHERE customer_id IS NOT NULL
          AND is_cleared = 0
      ''');
      final withDebt = Sqflite.firstIntValue(debtResult) ?? 0;

      final balanceResult = await db.rawQuery('''
        SELECT COALESCE(SUM(balance), 0) as total
        FROM debts
        WHERE customer_id IS NOT NULL
          AND is_cleared = 0
      ''');
      final totalDebt =
          (balanceResult.first['total'] as num?)?.toDouble() ?? 0.0;

      final topResult = await db.rawQuery('''
        SELECT
          c.id, c.name, c.phone,
          COUNT(s.id) as purchase_count,
          COALESCE(SUM(s.total_revenue), 0) as total_spent,
          MAX(s.date_sold) as last_purchase
        FROM customers c
        LEFT JOIN sales s
          ON s.customer_id = c.id
          AND s.is_fully_paid = 1
          AND s.date_sold >= ?
          AND s.date_sold <= ?
        GROUP BY c.id
        ORDER BY total_spent DESC
        LIMIT 10
      ''', [dateFrom, dateTo]);

      final topCustomers = topResult
          .map(
            (m) => TopCustomer(
              customerId: m['id'] as int,
              customerName: m['name'] as String,
              customerPhone: m['phone'] as String?,
              totalPurchases: (m['purchase_count'] as num).toInt(),
              totalSpent: (m['total_spent'] as num).toDouble(),
              lastPurchaseDate: m['last_purchase'] as String?,
            ),
          )
          .toList();

      final debtDetailResult = await db.rawQuery('''
        SELECT
          c.id, c.name, c.phone,
          SUM(d.balance) as total_balance,
          COUNT(d.id) as debt_count
        FROM customers c
        INNER JOIN debts d
          ON d.customer_id = c.id
          AND d.is_cleared = 0
        GROUP BY c.id
        ORDER BY total_balance DESC
        LIMIT 10
      ''');

      final debtItems = debtDetailResult
          .map(
            (m) => CustomerDebtItem(
              customerId: m['id'] as int,
              customerName: m['name'] as String,
              customerPhone: m['phone'] as String?,
              totalDebtBalance: (m['total_balance'] as num).toDouble(),
              debtCount: (m['debt_count'] as num).toInt(),
            ),
          )
          .toList();

      return CustomerReportData(
        totalCustomers: total,
        newCustomersThisPeriod: newCount,
        customersWithDebt: withDebt,
        totalOutstandingDebt: totalDebt,
        topCustomers: topCustomers,
        customersWithActiveDebt: debtItems,
      );
    } catch (e) {
      logDebug('DatabaseHelper.getCustomerReportData error: $e');
      rethrow;
    }
  }

  /// Get sale source breakdown for a date range.
  Future<SaleSourceBreakdown> getSaleSourceBreakdown({
    required String dateFrom,
    required String dateTo,
    String paymentMethodFilter = 'all',
    String saleTypeFilter = 'all',
    String saleSourceFilter = 'all',
  }) async {
    try {
      final db = await database;
      final filter = _reportFilterClause(
        paymentMethodFilter: paymentMethodFilter,
        saleTypeFilter: saleTypeFilter,
        saleSourceFilter: saleSourceFilter,
      );

      final result = await db.rawQuery('''
        SELECT
          sale_source,
          COUNT(*) as count,
          COALESCE(SUM(total_revenue), 0) as revenue
        FROM sales
        WHERE date_sold >= ? AND date_sold <= ?
          AND is_fully_paid = 1
          $filter
        GROUP BY sale_source
      ''', [dateFrom, dateTo]);

      var stockCount = 0;
      var spotCount = 0;
      var serviceCount = 0;
      var manualCount = 0;
      var stockRev = 0.0;
      var spotRev = 0.0;
      var serviceRev = 0.0;
      var manualRev = 0.0;

      for (final row in result) {
        final source = row['sale_source'] as String;
        final count = (row['count'] as num).toInt();
        final rev = (row['revenue'] as num).toDouble();
        switch (source) {
          case 'stock':
            stockCount = count;
            stockRev = rev;
          case 'spot_buy':
            spotCount = count;
            spotRev = rev;
          case 'service':
            serviceCount = count;
            serviceRev = rev;
          default:
            manualCount += count;
            manualRev += rev;
        }
      }

      return SaleSourceBreakdown(
        stockCount: stockCount,
        stockRevenue: stockRev,
        spotBuyCount: spotCount,
        spotBuyRevenue: spotRev,
        serviceCount: serviceCount,
        serviceRevenue: serviceRev,
        manualCount: manualCount,
        manualRevenue: manualRev,
      );
    } catch (e) {
      logDebug('DatabaseHelper.getSaleSourceBreakdown error: $e');
      rethrow;
    }
  }
}
