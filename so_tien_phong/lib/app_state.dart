import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'db/database_helper.dart';
import 'models/fee_type.dart';
import 'models/payment.dart';
import 'services/image_service.dart';
import 'services/notification_service.dart';
import 'utils/formatters.dart';

class AppState extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Payment> _payments = [];
  bool _loading = true;

  // --- cài đặt ---
  ThemeMode _themeMode = ThemeMode.system;
  bool _reminderEnabled = false;
  int _reminderDay = 5;
  int _reminderHour = 9;
  int _reminderMinute = 0;
  double _defaultRoom = 0;
  double _defaultManagement = 0;
  double _defaultUnitPrice = 3500;

  bool get loading => _loading;
  ThemeMode get themeMode => _themeMode;
  bool get reminderEnabled => _reminderEnabled;
  int get reminderDay => _reminderDay;
  int get reminderHour => _reminderHour;
  int get reminderMinute => _reminderMinute;
  double get defaultRoom => _defaultRoom;
  double get defaultManagement => _defaultManagement;
  double get defaultUnitPrice => _defaultUnitPrice;

  TimeOfDay get reminderTime =>
      TimeOfDay(hour: _reminderHour, minute: _reminderMinute);

  // ------------------------------------------------------------------ khởi tạo

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    await _loadSettings();
    _payments = await _db.fetchAllPayments();

    _loading = false;
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('theme_mode') ?? 0;
    _themeMode = ThemeMode.values[
        themeIndex.clamp(0, ThemeMode.values.length - 1).toInt()];
    _reminderEnabled = prefs.getBool('reminder_enabled') ?? false;
    _reminderDay = prefs.getInt('reminder_day') ?? 5;
    _reminderHour = prefs.getInt('reminder_hour') ?? 9;
    _reminderMinute = prefs.getInt('reminder_minute') ?? 0;
    _defaultRoom = prefs.getDouble('default_room') ?? 0;
    _defaultManagement = prefs.getDouble('default_management') ?? 0;
    _defaultUnitPrice = prefs.getDouble('default_unit_price') ?? 3500;
  }

  // ------------------------------------------------------------- dữ liệu tháng

  /// Danh sách các tháng đã có dữ liệu, mới nhất trước.
  List<MonthBook> get months {
    final grouped = <String, List<Payment>>{};
    for (final p in _payments) {
      grouped.putIfAbsent(p.monthKey, () => []).add(p);
    }

    final books = grouped.values.map((list) {
      final first = list.first;
      return MonthBook.build(first.year, first.month, list);
    }).toList();

    // Luôn có tháng hiện tại trong danh sách, kể cả khi chưa nhập gì.
    final now = DateTime.now();
    final currentKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    if (!books.any((b) => b.key == currentKey)) {
      books.add(MonthBook.build(now.year, now.month, const []));
    }

    books.sort((a, b) => b.compareTo(a));
    return books;
  }

  MonthBook get currentMonth {
    final now = DateTime.now();
    return bookOf(now.year, now.month);
  }

  MonthBook bookOf(int year, int month) {
    final list = _payments
        .where((p) => p.year == year && p.month == month)
        .toList();
    return MonthBook.build(year, month, list);
  }

  Payment paymentOf(int year, int month, FeeType type) =>
      bookOf(year, month).item(type);

  /// Các tháng gần đây theo thứ tự thời gian tăng dần — dùng cho biểu đồ.
  List<MonthBook> recentMonths(int count) {
    final now = DateTime.now();
    final result = <MonthBook>[];
    for (int i = count - 1; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i);
      result.add(bookOf(d.year, d.month));
    }
    return result;
  }

  /// Tháng chưa đóng đủ (bỏ qua các tháng hoàn toàn trống).
  List<MonthBook> get unpaidMonths => months
      .where((m) => !m.isEmpty && !m.isFullyPaid)
      .toList();

  double get totalThisYear {
    final year = DateTime.now().year;
    return _payments
        .where((p) => p.year == year)
        .fold<double>(0, (s, p) => s + p.amount);
  }

  // ------------------------------------------------------------------- ghi/xoá

  Future<void> savePayment(Payment payment) async {
    final id = await _db.upsertPayment(payment);
    final fresh = await _db.findPayment(payment.year, payment.month, payment.type);
    _replaceLocal(id, fresh);
    notifyListeners();
  }

  /// Đánh dấu đã đóng và sinh hoá đơn (mã, ngày giờ, hình thức).
  Future<Payment> markPaid(
    Payment payment, {
    required DateTime paidAt,
    required PaymentMethod method,
    String? note,
  }) async {
    final code = payment.invoiceCode ??
        generateInvoiceCode(paidAt, payment.year, payment.month);
    final updated = payment.copyWith(
      isPaid: true,
      paidAt: paidAt,
      method: method,
      note: note ?? payment.note,
      invoiceCode: code,
    );
    await savePayment(updated);
    return paymentOf(payment.year, payment.month, payment.type);
  }

  Future<void> markUnpaid(Payment payment) async {
    final updated = payment.copyWith(
      isPaid: false,
      clearPaidAt: true,
      clearInvoiceCode: true,
    );
    await savePayment(updated);
  }

  Future<void> deleteMonth(int year, int month) async {
    final targets =
        _payments.where((p) => p.year == year && p.month == month).toList();
    for (final p in targets) {
      for (final img in p.images) {
        await ImageService.instance.deleteFile(img);
      }
    }
    await _db.deleteMonth(year, month);
    _payments.removeWhere((p) => p.year == year && p.month == month);
    notifyListeners();
  }

  // -------------------------------------------------------------------- ảnh

  /// Thêm ảnh hoá đơn. Tự tạo bản ghi phí nếu chưa có id.
  Future<void> addImages(Payment payment, List<String> paths) async {
    if (paths.isEmpty) return;
    int? id = payment.id;
    id ??= await _db.upsertPayment(payment);

    for (final path in paths) {
      await _db.addImage(id, path);
    }
    final fresh = await _db.findPayment(payment.year, payment.month, payment.type);
    _replaceLocal(id, fresh);
    notifyListeners();
  }

  Future<void> removeImage(Payment payment, String path) async {
    if (payment.id == null) return;
    await _db.removeImage(payment.id!, path);
    await ImageService.instance.deleteFile(path);
    final fresh = await _db.findPayment(payment.year, payment.month, payment.type);
    _replaceLocal(payment.id!, fresh);
    notifyListeners();
  }

  void _replaceLocal(int id, Payment? fresh) {
    if (fresh == null) return;
    final index = _payments.indexWhere((p) =>
        p.id == id ||
        (p.year == fresh.year &&
            p.month == fresh.month &&
            p.type == fresh.type));
    if (index >= 0) {
      _payments[index] = fresh;
    } else {
      _payments.add(fresh);
    }
  }

  // ---------------------------------------------------------------- cài đặt

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('theme_mode', mode.index);
  }

  Future<void> setDefaults({
    double? room,
    double? management,
    double? unitPrice,
  }) async {
    if (room != null) _defaultRoom = room;
    if (management != null) _defaultManagement = management;
    if (unitPrice != null) _defaultUnitPrice = unitPrice;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('default_room', _defaultRoom);
    await prefs.setDouble('default_management', _defaultManagement);
    await prefs.setDouble('default_unit_price', _defaultUnitPrice);
  }

  Future<bool> setReminder({
    required bool enabled,
    int? day,
    TimeOfDay? time,
  }) async {
    _reminderEnabled = enabled;
    if (day != null) _reminderDay = day;
    if (time != null) {
      _reminderHour = time.hour;
      _reminderMinute = time.minute;
    }

    bool ok = true;
    if (enabled) {
      final granted = await NotificationService.instance.requestPermission();
      if (granted) {
        await NotificationService.instance.scheduleMonthly(
          dayOfMonth: _reminderDay,
          hour: _reminderHour,
          minute: _reminderMinute,
        );
      } else {
        _reminderEnabled = false;
        ok = false;
      }
    } else {
      await NotificationService.instance.cancelMonthly();
    }

    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reminder_enabled', _reminderEnabled);
    await prefs.setInt('reminder_day', _reminderDay);
    await prefs.setInt('reminder_hour', _reminderHour);
    await prefs.setInt('reminder_minute', _reminderMinute);
    return ok;
  }

  Future<void> clearAllData() async {
    for (final p in _payments) {
      for (final img in p.images) {
        await ImageService.instance.deleteFile(img);
      }
    }
    await _db.clearAll();
    _payments = [];
    notifyListeners();
  }
}
