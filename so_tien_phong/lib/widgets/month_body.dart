import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/fee_type.dart';
import '../models/payment.dart';
import '../screens/invoice_screen.dart';
import '../screens/receipt_photos_screen.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import 'fee_card.dart';
import 'fee_editor_sheet.dart';
import 'pay_sheet.dart';

/// Phần thân dùng chung cho "Tháng này" và màn hình chi tiết một tháng.
class MonthBody extends StatelessWidget {
  final int year;
  final int month;

  const MonthBody({super.key, required this.year, required this.month});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final book = state.bookOf(year, month);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _SummaryCard(book: book),
        const SizedBox(height: 16),
        for (final type in FeeType.values) ...[
          _feeSection(context, book.item(type)),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        if (!book.isFullyPaid && book.total > 0)
          FilledButton.icon(
            onPressed: () => PaySheet.show(context, book.all),
            icon: const Icon(Icons.done_all, size: 20),
            label: Text(
              'Đóng ${FeeType.values.length - book.paidCount} khoản còn lại',
            ),
          ),
        if (book.paidCount > 0) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => InvoiceScreen(year: year, month: month),
              ),
            ),
            icon: const Icon(Icons.receipt_long_outlined, size: 19),
            label: const Text('Xem hoá đơn tháng này'),
          ),
        ],
      ],
    );
  }

  Widget _feeSection(BuildContext context, Payment payment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FeeCard(
          payment: payment,
          onTap: () => FeeEditorSheet.show(context, payment),
          onTogglePaid: payment.amount > 0
              ? () => PaySheet.show(context, [payment])
              : null,
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _MiniAction(
              icon: Icons.edit_outlined,
              label: 'Sửa số tiền',
              onTap: () => FeeEditorSheet.show(context, payment),
            ),
            const SizedBox(width: 6),
            _MiniAction(
              icon: Icons.add_a_photo_outlined,
              label: payment.images.isEmpty
                  ? 'Thêm ảnh'
                  : 'Ảnh (${payment.images.length})',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReceiptPhotosScreen(
                    year: payment.year,
                    month: payment.month,
                    type: payment.type,
                  ),
                ),
              ),
            ),
            const Spacer(),
            if (payment.isPaid)
              _MiniAction(
                icon: Icons.undo,
                label: 'Bỏ đánh dấu',
                onTap: () => _confirmUnpaid(context, payment),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _confirmUnpaid(BuildContext context, Payment payment) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bỏ đánh dấu đã đóng?'),
        content: Text(
          '${payment.type.label} sẽ quay lại trạng thái "Chưa đóng" '
          'và hoá đơn tương ứng bị xoá.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đồng ý'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AppState>().markUnpaid(payment);
    }
  }
}

class _MiniAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17, color: color),
      label: Text(label, style: TextStyle(fontSize: 12.5, color: color)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// Thẻ tóm tắt: trả lời ngay câu "tháng này đóng đủ chưa?"
class _SummaryCard extends StatelessWidget {
  final MonthBook book;

  const _SummaryCard({required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = book.isFullyPaid;
    final statusColor =
        done ? StatusColors.ok(context) : StatusColors.bad(context);
    final missing = FeeType.values.length - book.paidCount;

    return AppCard(
      padding: const EdgeInsets.all(18),
      background: tintScaffold(context, statusColor, 0.07),
      borderColor: tintScaffold(context, statusColor, 0.32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.verified_rounded : Icons.pending_actions_rounded,
                color: statusColor,
                size: 26,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  done ? 'Đã đóng đủ 3 khoản' : 'Còn $missing khoản chưa đóng',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  label: 'Tổng phải đóng',
                  value: formatMoney(book.total),
                ),
              ),
              Container(
                width: 1,
                height: 34,
                color: AppTheme.borderOf(context),
              ),
              Expanded(
                child: _Stat(
                  label: done ? 'Đã đóng' : 'Còn thiếu',
                  value: formatMoney(done ? book.paidTotal : book.remaining),
                  valueColor: statusColor,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          if (book.lastPaidAt != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.history,
                    size: 15, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Lần đóng gần nhất: ${formatDateTime(book.lastPaidAt!)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool alignEnd;

  const _Stat({
    required this.label,
    required this.value,
    this.valueColor,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 3),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
