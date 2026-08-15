import 'dart:convert';

import 'fee_type.dart';

/// Một khoản phí của một tháng (điện / phòng / quản lý).
class Payment {
  final int? id;
  final int year;
  final int month;
  final FeeType type;

  /// Số tiền phải đóng (VND).
  final double amount;

  /// Đã đóng hay chưa.
  final bool isPaid;

  /// Ngày + giờ đóng tiền (null nếu chưa đóng).
  final DateTime? paidAt;

  final PaymentMethod method;

  /// Ghi chú tự do, ví dụ nội dung chuyển khoản.
  final String? note;

  /// Chi tiết các khoản nhỏ (chỉ dùng cho tiền quản lý):
  /// {'water': 80000, 'parking': 100000, ...}
  final Map<String, double> breakdown;

  /// Chỉ số công tơ điện (tuỳ chọn) — dùng để tự tính tiền điện.
  final double? meterOld;
  final double? meterNew;
  final double? unitPrice;

  /// Mã hoá đơn được sinh tự động khi đánh dấu đã đóng.
  final String? invoiceCode;

  final DateTime createdAt;
  final DateTime updatedAt;

  /// Đường dẫn ảnh hoá đơn (nạp riêng từ bảng receipt_images).
  final List<String> images;

  const Payment({
    this.id,
    required this.year,
    required this.month,
    required this.type,
    this.amount = 0,
    this.isPaid = false,
    this.paidAt,
    this.method = PaymentMethod.transfer,
    this.note,
    this.breakdown = const {},
    this.meterOld,
    this.meterNew,
    this.unitPrice,
    this.invoiceCode,
    required this.createdAt,
    required this.updatedAt,
    this.images = const [],
  });

  factory Payment.empty(int year, int month, FeeType type) {
    final now = DateTime.now();
    return Payment(
      year: year,
      month: month,
      type: type,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Tổng các khoản nhỏ (dùng cho tiền quản lý).
  double get breakdownTotal =>
      breakdown.values.fold<double>(0, (sum, v) => sum + v);

  /// Số điện tiêu thụ, null nếu không nhập chỉ số.
  double? get consumedKwh {
    if (meterOld == null || meterNew == null) return null;
    final diff = meterNew! - meterOld!;
    return diff < 0 ? null : diff;
  }

  String get monthKey => '$year-${month.toString().padLeft(2, '0')}';

  Payment copyWith({
    int? id,
    int? year,
    int? month,
    FeeType? type,
    double? amount,
    bool? isPaid,
    DateTime? paidAt,
    bool clearPaidAt = false,
    PaymentMethod? method,
    String? note,
    bool clearNote = false,
    Map<String, double>? breakdown,
    double? meterOld,
    double? meterNew,
    double? unitPrice,
    bool clearMeter = false,
    String? invoiceCode,
    bool clearInvoiceCode = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? images,
  }) {
    return Payment(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      isPaid: isPaid ?? this.isPaid,
      paidAt: clearPaidAt ? null : (paidAt ?? this.paidAt),
      method: method ?? this.method,
      note: clearNote ? null : (note ?? this.note),
      breakdown: breakdown ?? this.breakdown,
      meterOld: clearMeter ? null : (meterOld ?? this.meterOld),
      meterNew: clearMeter ? null : (meterNew ?? this.meterNew),
      unitPrice: clearMeter ? null : (unitPrice ?? this.unitPrice),
      invoiceCode: clearInvoiceCode ? null : (invoiceCode ?? this.invoiceCode),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      images: images ?? this.images,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'year': year,
      'month': month,
      'type': type.key,
      'amount': amount,
      'is_paid': isPaid ? 1 : 0,
      'paid_at': paidAt?.millisecondsSinceEpoch,
      'method': method.key,
      'note': note,
      'breakdown': breakdown.isEmpty ? null : jsonEncode(breakdown),
      'meter_old': meterOld,
      'meter_new': meterNew,
      'unit_price': unitPrice,
      'invoice_code': invoiceCode,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory Payment.fromMap(Map<String, Object?> map,
      {List<String> images = const []}) {
    Map<String, double> parsedBreakdown = {};
    final raw = map['breakdown'] as String?;
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        parsedBreakdown = decoded.map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        );
      } catch (_) {
        parsedBreakdown = {};
      }
    }

    return Payment(
      id: map['id'] as int?,
      year: map['year'] as int,
      month: map['month'] as int,
      type: feeTypeFromKey(map['type'] as String),
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      isPaid: (map['is_paid'] as int? ?? 0) == 1,
      paidAt: map['paid_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['paid_at'] as int),
      method: paymentMethodFromKey(map['method'] as String?),
      note: map['note'] as String?,
      breakdown: parsedBreakdown,
      meterOld: (map['meter_old'] as num?)?.toDouble(),
      meterNew: (map['meter_new'] as num?)?.toDouble(),
      unitPrice: (map['unit_price'] as num?)?.toDouble(),
      invoiceCode: map['invoice_code'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['created_at'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
          map['updated_at'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      images: images,
    );
  }
}

/// Gộp 3 khoản phí của cùng một tháng để hiển thị.
class MonthBook {
  final int year;
  final int month;
  final Map<FeeType, Payment> items;

  const MonthBook({
    required this.year,
    required this.month,
    required this.items,
  });

  factory MonthBook.build(int year, int month, List<Payment> payments) {
    final map = <FeeType, Payment>{};
    for (final t in FeeType.values) {
      map[t] = payments.firstWhere(
        (p) => p.type == t,
        orElse: () => Payment.empty(year, month, t),
      );
    }
    return MonthBook(year: year, month: month, items: map);
  }

  Payment item(FeeType type) => items[type] ?? Payment.empty(year, month, type);

  String get key => '$year-${month.toString().padLeft(2, '0')}';

  List<Payment> get all => FeeType.values.map(item).toList();

  double get total => all.fold<double>(0, (s, p) => s + p.amount);

  double get paidTotal =>
      all.where((p) => p.isPaid).fold<double>(0, (s, p) => s + p.amount);

  double get remaining => total - paidTotal;

  /// Số khoản đã có nhập số tiền (> 0).
  int get enteredCount => all.where((p) => p.amount > 0).length;

  int get paidCount => all.where((p) => p.isPaid).length;

  /// Đã đóng đủ cả 3 khoản.
  bool get isFullyPaid => paidCount == FeeType.values.length;

  /// Chưa động tới tháng này (chưa nhập gì, chưa đóng gì).
  bool get isEmpty => enteredCount == 0 && paidCount == 0;

  DateTime get date => DateTime(year, month);

  /// Ngày đóng gần nhất trong tháng.
  DateTime? get lastPaidAt {
    final dates = all
        .map((p) => p.paidAt)
        .whereType<DateTime>()
        .toList()
      ..sort();
    return dates.isEmpty ? null : dates.last;
  }

  int compareTo(MonthBook other) {
    if (year != other.year) return year.compareTo(other.year);
    return month.compareTo(other.month);
  }
}
