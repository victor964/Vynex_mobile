// SQLite database setup, table creation, and CRUD operations.

import '../utils/debug_log.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../models/business_settings.dart';
import '../../models/dashboard_data.dart';
import '../../models/debt.dart';
import '../../models/debt_with_sale.dart';
import '../../models/purchase.dart';
import '../../models/sale.dart';
import '../utils/formatters.dart';

/// Singleton helper for all local SQLite database operations.
class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper _instance = DatabaseHelper._internal();

  /// Returns the shared [DatabaseHelper] instance.
  factory DatabaseHelper() => _instance;

  static Database? _database;

  static const String _dbName = 'vynex.db';
  static const int _dbVersion = 3;

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
        notes TEXT
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
        sale_type TEXT NOT NULL DEFAULT 'product'
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
  }) {
    var clause = '';
    if (paymentMethodFilter != 'all') {
      clause += " AND payment_method = '$paymentMethodFilter'";
    }
    if (saleTypeFilter != 'all') {
      clause += " AND sale_type = '$saleTypeFilter'";
    }
    return clause;
  }

  /// Get daily revenue and profit totals for the line chart.
  Future<List<Map<String, dynamic>>> getDailyChartData(
    String dateFrom,
    String dateTo, {
    String paymentMethodFilter = 'all',
    String saleTypeFilter = 'all',
  }) async {
    try {
      final db = await database;
      final filter = _reportFilterClause(
        paymentMethodFilter: paymentMethodFilter,
        saleTypeFilter: saleTypeFilter,
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
  }) async {
    try {
      final db = await database;
      final filter = _reportFilterClause(
        paymentMethodFilter: paymentMethodFilter,
        saleTypeFilter: saleTypeFilter,
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
  }) async {
    try {
      final db = await database;
      final filter = _reportFilterClause(
        paymentMethodFilter: paymentMethodFilter,
        saleTypeFilter: saleTypeFilter,
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
}
