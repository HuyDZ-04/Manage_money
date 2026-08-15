import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/fee_type.dart';
import '../models/payment.dart';

/// Toàn bộ dữ liệu nằm trong SQLite trên máy — không cần internet, không tài khoản.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const _dbName = 'so_tien_phong.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE payments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            year INTEGER NOT NULL,
            month INTEGER NOT NULL,
            type TEXT NOT NULL,
            amount REAL NOT NULL DEFAULT 0,
            is_paid INTEGER NOT NULL DEFAULT 0,
            paid_at INTEGER,
            method TEXT,
            note TEXT,
            breakdown TEXT,
            meter_old REAL,
            meter_new REAL,
            unit_price REAL,
            invoice_code TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            UNIQUE(year, month, type)
          )
        ''');
        await db.execute('''
          CREATE TABLE receipt_images (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            payment_id INTEGER NOT NULL,
            path TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            FOREIGN KEY(payment_id) REFERENCES payments(id) ON DELETE CASCADE
          )
        ''');
        await db.execute(
            'CREATE INDEX idx_payments_month ON payments(year, month)');
        await db.execute(
            'CREATE INDEX idx_images_payment ON receipt_images(payment_id)');
      },
    );
  }

  // ---------------------------------------------------------------- payments

  Future<List<Payment>> fetchAllPayments() async {
    final db = await database;
    final rows = await db.query('payments', orderBy: 'year DESC, month DESC');
    if (rows.isEmpty) return [];

    final imageRows = await db.query('receipt_images', orderBy: 'created_at');
    final imagesByPayment = <int, List<String>>{};
    for (final r in imageRows) {
      final pid = r['payment_id'] as int;
      imagesByPayment.putIfAbsent(pid, () => []).add(r['path'] as String);
    }

    return rows
        .map((r) => Payment.fromMap(
              r,
              images: imagesByPayment[r['id'] as int] ?? const [],
            ))
        .toList();
  }

  /// Ghi một khoản phí. Tự tạo mới nếu chưa có (theo year+month+type).
  Future<int> upsertPayment(Payment payment) async {
    final db = await database;
    final map = payment.toMap();
    map['updated_at'] = DateTime.now().millisecondsSinceEpoch;

    if (payment.id != null) {
      await db.update('payments', map, where: 'id = ?', whereArgs: [payment.id]);
      return payment.id!;
    }

    final existing = await db.query(
      'payments',
      where: 'year = ? AND month = ? AND type = ?',
      whereArgs: [payment.year, payment.month, payment.type.key],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      final id = existing.first['id'] as int;
      await db.update('payments', map, where: 'id = ?', whereArgs: [id]);
      return id;
    }
    return db.insert('payments', map);
  }

  Future<void> deletePayment(int id) async {
    final db = await database;
    await db.delete('payments', where: 'id = ?', whereArgs: [id]);
  }

  /// Xoá sạch một tháng (cả 3 khoản).
  Future<void> deleteMonth(int year, int month) async {
    final db = await database;
    await db.delete('payments',
        where: 'year = ? AND month = ?', whereArgs: [year, month]);
  }

  Future<Payment?> findPayment(int year, int month, FeeType type) async {
    final db = await database;
    final rows = await db.query(
      'payments',
      where: 'year = ? AND month = ? AND type = ?',
      whereArgs: [year, month, type.key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final id = rows.first['id'] as int;
    final imgs = await db.query('receipt_images',
        where: 'payment_id = ?', whereArgs: [id], orderBy: 'created_at');
    return Payment.fromMap(
      rows.first,
      images: imgs.map((e) => e['path'] as String).toList(),
    );
  }

  // ------------------------------------------------------------------ images

  Future<void> addImage(int paymentId, String path) async {
    final db = await database;
    await db.insert('receipt_images', {
      'payment_id': paymentId,
      'path': path,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> removeImage(int paymentId, String path) async {
    final db = await database;
    await db.delete('receipt_images',
        where: 'payment_id = ? AND path = ?', whereArgs: [paymentId, path]);
  }

  Future<List<String>> imagesOf(int paymentId) async {
    final db = await database;
    final rows = await db.query('receipt_images',
        where: 'payment_id = ?', whereArgs: [paymentId], orderBy: 'created_at');
    return rows.map((e) => e['path'] as String).toList();
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('receipt_images');
    await db.delete('payments');
  }
}
