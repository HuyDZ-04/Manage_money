import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final NumberFormat _vnd = NumberFormat.decimalPattern('vi');

/// 1250000 -> "1.250.000 ₫"
String formatMoney(num value, {bool withSymbol = true}) {
  final s = _vnd.format(value.round());
  return withSymbol ? '$s ₫' : s;
}

/// Rút gọn cho trục biểu đồ: 1.250.000 -> "1,25 tr"
String formatMoneyShort(num value) {
  final v = value.abs();
  if (v >= 1000000) {
    final m = value / 1000000;
    final String text;
    if (m == m.roundToDouble() || m.abs() >= 10) {
      text = m.toStringAsFixed(0);
    } else {
      text = m.toStringAsFixed(1).replaceAll('.', ',');
    }
    return '$text tr';
  }
  if (v >= 1000) {
    final k = value / 1000;
    return '${k.toStringAsFixed(0)}k';
  }
  return value.toStringAsFixed(0);
}

String formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

String formatTime(DateTime d) => DateFormat('HH:mm').format(d);

String formatDateTime(DateTime d) =>
    DateFormat('HH:mm • dd/MM/yyyy').format(d);

String formatMonthLabel(int year, int month) =>
    'Tháng $month/$year';

String formatMonthShort(int year, int month) =>
    'T$month/${year.toString().substring(2)}';

/// Đọc số tiền người dùng gõ, chấp nhận cả "1.250.000", "1250000", "1 250 000".
double parseMoney(String input) {
  final cleaned = input.replaceAll(RegExp(r'[^0-9,\.]'), '');
  if (cleaned.isEmpty) return 0;
  // Bỏ dấu chấm phân cách nghìn, đổi dấu phẩy thập phân thành dấu chấm.
  final normalized = cleaned.replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(normalized) ?? 0;
}

/// Tự chèn dấu chấm phân cách nghìn khi gõ số tiền.
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final value = int.tryParse(digitsOnly);
    if (value == null) return oldValue;
    final formatted = _vnd.format(value);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Sinh mã hoá đơn theo kỳ thanh toán: HD2608-0342
/// (tháng/năm của kỳ + 4 số cuối lấy từ mốc thời gian đóng)
String generateInvoiceCode(DateTime when, int year, int month) {
  final mm = month.toString().padLeft(2, '0');
  final yy = (year % 100).toString().padLeft(2, '0');
  final seq = (when.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
  return 'HD$mm$yy-$seq';
}
