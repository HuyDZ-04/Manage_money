import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app_state.dart';
import '../models/fee_type.dart';
import '../models/payment.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import 'receipt_photos_screen.dart';

/// Hoá đơn tự sinh cho một tháng: mã, ngày giờ đóng, hình thức, chi tiết khoản.
class InvoiceScreen extends StatefulWidget {
  final int year;
  final int month;

  const InvoiceScreen({super.key, required this.year, required this.month});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final GlobalKey _captureKey = GlobalKey();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final book = state.bookOf(widget.year, widget.month);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoá đơn'),
        actions: [
          IconButton(
            tooltip: 'Chia sẻ dạng chữ',
            icon: const Icon(Icons.text_snippet_outlined),
            onPressed: () => _shareText(book),
          ),
          IconButton(
            tooltip: 'Chia sẻ dạng ảnh',
            icon: const Icon(Icons.ios_share),
            onPressed: _busy ? null : () => _shareImage(book),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          RepaintBoundary(
            key: _captureKey,
            child: _InvoiceCard(book: book),
          ),
          const SizedBox(height: 18),
          Text(
            'Ảnh hoá đơn đã lưu',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _ImageStrip(book: book),
        ],
      ),
    );
  }

  String _buildText(MonthBook book) {
    final buffer = StringBuffer()
      ..writeln('HOÁ ĐƠN ${formatMonthLabel(book.year, book.month).toUpperCase()}')
      ..writeln('------------------------------');
    for (final p in book.all) {
      buffer.writeln('${p.type.label}: ${formatMoney(p.amount)}');
      if (p.isPaid && p.paidAt != null) {
        buffer.writeln(
            '   ✔ ${p.method.label} • ${formatDateTime(p.paidAt!)}'
            '${p.invoiceCode != null ? " • ${p.invoiceCode}" : ""}');
      } else {
        buffer.writeln('   ✖ Chưa đóng');
      }
    }
    buffer
      ..writeln('------------------------------')
      ..writeln('Tổng cộng: ${formatMoney(book.total)}')
      ..writeln('Đã đóng:   ${formatMoney(book.paidTotal)}')
      ..writeln('Còn thiếu: ${formatMoney(book.remaining)}');
    return buffer.toString();
  }

  Future<void> _shareText(MonthBook book) async {
    try {
      await Share.share(
        _buildText(book),
        subject: 'Hoá đơn ${formatMonthLabel(book.year, book.month)}',
      );
    } catch (e) {
      _toast('Không chia sẻ được: $e');
    }
  }

  Future<void> _shareImage(MonthBook book) async {
    setState(() => _busy = true);
    try {
      final boundary = _captureKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        _toast('Chưa dựng xong hoá đơn, thử lại.');
        return;
      }
      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        _toast('Không tạo được ảnh hoá đơn.');
        return;
      }
      final Uint8List bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/hoadon_${book.month}_${book.year}.png');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Hoá đơn ${formatMonthLabel(book.year, book.month)}',
      );
    } catch (e) {
      _toast('Không chia sẻ được ảnh: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _InvoiceCard extends StatelessWidget {
  final MonthBook book;

  const _InvoiceCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = book.all
        .map((p) => p.invoiceCode)
        .whereType<String>()
        .toList();

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HOÁ ĐƠN THANH TOÁN',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatMonthLabel(book.year, book.month),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.receipt_long,
                  size: 30, color: theme.colorScheme.primary),
            ],
          ),
          if (code.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Mã: ${code.toSet().join(", ")}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 14),
          _dashed(context),
          const SizedBox(height: 10),
          for (final p in book.all) _InvoiceRow(payment: p),
          const SizedBox(height: 6),
          _dashed(context),
          const SizedBox(height: 12),
          _totalRow(context, 'Tổng cộng', book.total, bold: true),
          const SizedBox(height: 6),
          _totalRow(context, 'Đã đóng', book.paidTotal,
              color: StatusColors.ok(context)),
          const SizedBox(height: 6),
          _totalRow(
            context,
            'Còn thiếu',
            book.remaining,
            color: book.remaining > 0
                ? StatusColors.bad(context)
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 14, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Hoá đơn do ứng dụng tự tạo để ghi nhớ, không thay thế biên lai chính thức.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dashed(BuildContext context) => Container(
        height: 1,
        color: AppTheme.borderOf(context),
      );

  Widget _totalRow(BuildContext context, String label, double value,
      {bool bold = false, Color? color}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 15 : 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        Text(
          formatMoney(value),
          style: TextStyle(
            fontSize: bold ? 19 : 15,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final Payment payment;

  const _InvoiceRow({required this.payment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = FeeColors.of(context, payment.type);
    final paidColor = payment.isPaid
        ? StatusColors.ok(context)
        : StatusColors.bad(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  payment.type.label,
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                formatMoney(payment.amount),
                style: const TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 19, top: 3),
            child: Row(
              children: [
                Icon(
                  payment.isPaid ? Icons.check_circle : Icons.remove_circle_outline,
                  size: 13,
                  color: paidColor,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    payment.isPaid && payment.paidAt != null
                        ? '${payment.method.label} • ${formatDateTime(payment.paidAt!)}'
                        : 'Chưa đóng',
                    style: theme.textTheme.bodySmall?.copyWith(color: paidColor),
                  ),
                ),
              ],
            ),
          ),
          if (payment.type.hasBreakdown && payment.breakdown.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 19, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final item in kManagementItems)
                    if ((payment.breakdown[item.key] ?? 0) > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Text('· ${item.label}',
                                style: theme.textTheme.bodySmall),
                            const Spacer(),
                            Text(
                              formatMoney(payment.breakdown[item.key]!),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          if (payment.note != null && payment.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 19, top: 4),
              child: Text(
                'Ghi chú: ${payment.note}',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _ImageStrip extends StatelessWidget {
  final MonthBook book;

  const _ImageStrip({required this.book});

  @override
  Widget build(BuildContext context) {
    final entries = <MapEntry<Payment, String>>[];
    for (final p in book.all) {
      for (final path in p.images) {
        entries.add(MapEntry(p, path));
      }
    }

    if (entries.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          children: [
            Icon(Icons.image_outlined,
                size: 30, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 8),
            Text(
              'Chưa có ảnh hoá đơn nào cho tháng này',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReceiptPhotosScreen(
                    year: book.year,
                    month: book.month,
                    type: FeeType.room,
                  ),
                ),
              ),
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: const Text('Thêm ảnh'),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final entry = entries[i];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReceiptPhotosScreen(
                  year: book.year,
                  month: book.month,
                  type: entry.key.type,
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(entry.value),
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 110,
                  height: 110,
                  color: AppTheme.borderOf(context),
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
