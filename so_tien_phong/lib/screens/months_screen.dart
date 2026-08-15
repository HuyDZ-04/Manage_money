import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/fee_type.dart';
import '../models/payment.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import 'month_detail_screen.dart';

class MonthsScreen extends StatelessWidget {
  const MonthsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final months = state.months;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sổ theo tháng'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openMonthPicker(context),
        icon: const Icon(Icons.add),
        label: const Text('Tháng khác'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        itemCount: months.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) return _YearSummary(state: state);
          final book = months[index - 1];
          return _MonthTile(
            book: book,
            isCurrent: book.year == now.year && book.month == now.month,
          );
        },
      ),
    );
  }

  Future<void> _openMonthPicker(BuildContext context) async {
    final now = DateTime.now();
    int year = now.year;
    int month = now.month;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Chọn tháng'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => setLocal(() => year--),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('$year',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  IconButton(
                    onPressed: () => setLocal(() => year++),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: List.generate(12, (i) {
                  final m = i + 1;
                  return ChoiceChip(
                    selected: m == month,
                    onSelected: (_) => setLocal(() => month = m),
                    label: Text('T$m'),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, DateTime(year, month)),
              child: const Text('Mở'),
            ),
          ],
        ),
      ),
    );

    if (picked != null && context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              MonthDetailScreen(year: picked.year, month: picked.month),
        ),
      );
    }
  }
}

class _YearSummary extends StatelessWidget {
  final AppState state;

  const _YearSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final year = DateTime.now().year;
    final unpaid = state.unpaidMonths.length;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tổng chi năm $year', style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  formatMoney(state.totalThisYear),
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Tháng chưa xong', style: theme.textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                '$unpaid',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: unpaid == 0
                      ? StatusColors.ok(context)
                      : StatusColors.bad(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthTile extends StatelessWidget {
  final MonthBook book;
  final bool isCurrent;

  const _MonthTile({required this.book, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final empty = book.isEmpty;
    final done = book.isFullyPaid;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              MonthDetailScreen(year: book.year, month: book.month),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Tháng ${book.month}/${book.year}',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (isCurrent) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: tint(context, theme.colorScheme.primary, 0.16),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Hiện tại',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              Text(
                empty ? '—' : formatMoney(book.total),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final type in FeeType.values) ...[
                Expanded(child: _FeeDot(payment: book.item(type))),
                if (type != FeeType.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 15,
                color: done
                    ? StatusColors.ok(context)
                    : theme.colorScheme.outline,
              ),
              const SizedBox(width: 6),
              Text(
                empty
                    ? 'Chưa nhập dữ liệu'
                    : (done
                        ? 'Đã đóng đủ • ${book.lastPaidAt != null ? formatDate(book.lastPaidAt!) : ''}'
                        : 'Đã đóng ${book.paidCount}/3 khoản'),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chấm trạng thái từng khoản — có icon + chữ viết tắt, không chỉ dựa vào màu.
class _FeeDot extends StatelessWidget {
  final Payment payment;

  const _FeeDot({required this.payment});

  @override
  Widget build(BuildContext context) {
    final color = FeeColors.of(context, payment.type);
    final paid = payment.isPaid;
    final base = AppTheme.surfaceOf(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
      decoration: BoxDecoration(
        color: paid ? blend(base, color, 0.14) : base,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: paid ? blend(base, color, 0.45) : AppTheme.borderOf(context),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            paid ? Icons.check : payment.type.icon,
            size: 14,
            color: paid ? color : Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              _short(payment.type),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: paid ? color : Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _short(FeeType type) {
    switch (type) {
      case FeeType.electricity:
        return 'Điện';
      case FeeType.room:
        return 'Phòng';
      case FeeType.management:
        return 'Quản lý';
    }
  }
}
