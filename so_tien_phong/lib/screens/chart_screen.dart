import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/fee_type.dart';
import '../models/payment.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import '../widgets/charts.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  int _range = 6;
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final books = state.recentMonths(_range);
    final hasData = books.any((b) => b.total > 0);

    final selectedIndex =
        (_selected != null && _selected! < books.length) ? _selected : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Biểu đồ so sánh')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _RangeFilter(
            value: _range,
            onChanged: (v) => setState(() {
              _range = v;
              _selected = null;
            }),
          ),
          const SizedBox(height: 16),
          if (!hasData)
            const _EmptyChart()
          else ...[
            _StatRow(books: books),
            const SizedBox(height: 16),
            _ChartCard(
              title: 'So sánh 3 khoản theo tháng',
              subtitle: 'Chạm vào một tháng để xem chi tiết',
              legend: const _FeeLegend(),
              extra: _Readout(
                book: books[selectedIndex ?? books.length - 1],
                isSelection: selectedIndex != null,
              ),
              chart: SizedBox(
                height: 220,
                child: GroupedBarChart(
                  books: books,
                  selectedIndex: selectedIndex,
                  onSelect: (i) => setState(() => _selected = i),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _ChartCard(
              title: 'Tổng chi mỗi tháng',
              subtitle: 'Cộng cả 3 khoản của từng tháng',
              chart: SizedBox(
                height: 200,
                child: TotalLineChart(
                  books: books,
                  selectedIndex: selectedIndex,
                  onSelect: (i) => setState(() => _selected = i),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _ComparisonCard(books: books),
            const SizedBox(height: 16),
            _TableCard(books: books),
          ],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ bộ lọc

class _RangeFilter extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _RangeFilter({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = [3, 6, 12];
    return Row(
      children: [
        Text(
          'Khoảng',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        for (final o in options) ...[
          ChoiceChip(
            selected: o == value,
            onSelected: (_) => onChanged(o),
            label: Text('$o tháng'),
            labelStyle: const TextStyle(fontSize: 12.5),
            visualDensity: VisualDensity.compact,
          ),
          if (o != options.last) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

// ------------------------------------------------------------------- thẻ số

class _StatRow extends StatelessWidget {
  final List<MonthBook> books;

  const _StatRow({required this.books});

  @override
  Widget build(BuildContext context) {
    final total = books.fold<double>(0, (s, b) => s + b.total);
    final active = books.where((b) => b.total > 0).toList();
    final avg = active.isEmpty ? 0.0 : total / active.length;
    final highest = active.isEmpty
        ? null
        : active.reduce((a, b) => a.total >= b.total ? a : b);

    return Row(
      children: [
        Expanded(
          child: _StatTile(label: 'Tổng chi', value: formatMoney(total)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
              label: 'Trung bình/tháng', value: formatMoney(avg)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            label: 'Tháng cao nhất',
            value: highest == null
                ? '—'
                : formatMonthShort(highest.year, highest.month),
            sub: highest == null ? null : formatMoneyShort(highest.total),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;

  const _StatTile({required this.label, required this.value, this.sub});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: theme.textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(sub!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- khung biểu đồ

class _ChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget chart;
  final Widget? legend;
  final Widget? extra;

  const _ChartCard({
    required this.title,
    this.subtitle,
    required this.chart,
    this.legend,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: theme.textTheme.bodySmall),
                ],
                if (legend != null) ...[
                  const SizedBox(height: 12),
                  legend!,
                ],
                if (extra != null) ...[
                  const SizedBox(height: 12),
                  extra!,
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          chart,
        ],
      ),
    );
  }
}

class _FeeLegend extends StatelessWidget {
  const _FeeLegend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: FeeType.values.map((t) {
        final color = FeeColors.of(context, t);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              t.label,
              style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

/// Dòng đọc số của tháng đang chọn (thay cho tooltip nổi).
class _Readout extends StatelessWidget {
  final MonthBook book;
  final bool isSelection;

  const _Readout({required this.book, required this.isSelection});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tint(context, theme.colorScheme.primary, 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderOf(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSelection ? Icons.touch_app_outlined : Icons.schedule,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                formatMonthLabel(book.year, book.month),
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                formatMoney(book.total),
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final t in FeeType.values) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: FeeColors.of(context, t),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              t.label,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatMoneyShort(book.item(t).amount),
                        style: const TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                if (t != FeeType.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- so sánh

class _ComparisonCard extends StatelessWidget {
  final List<MonthBook> books;

  const _ComparisonCard({required this.books});

  @override
  Widget build(BuildContext context) {
    if (books.length < 2) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final current = books.last;
    final previous = books[books.length - 2];

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tháng ${current.month} so với tháng ${previous.month}',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (final type in FeeType.values)
            _DeltaRow(
              label: type.label,
              color: FeeColors.of(context, type),
              current: current.item(type).amount,
              previous: previous.item(type).amount,
            ),
          Divider(color: AppTheme.borderOf(context), height: 20),
          _DeltaRow(
            label: 'Tổng cộng',
            color: theme.colorScheme.primary,
            current: current.total,
            previous: previous.total,
            bold: true,
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _DeltaRow extends StatelessWidget {
  final String label;
  final Color color;
  final double current;
  final double previous;
  final bool bold;

  const _DeltaRow({
    required this.label,
    required this.color,
    required this.current,
    required this.previous,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = current - previous;
    final percent = previous > 0 ? (diff / previous * 100) : null;

    IconData icon;
    String text;
    if (diff.abs() < 1) {
      icon = Icons.remove;
      text = 'Không đổi';
    } else if (diff > 0) {
      icon = Icons.arrow_upward;
      text = percent != null
          ? '+${formatMoneyShort(diff)} (${percent.toStringAsFixed(0)}%)'
          : '+${formatMoneyShort(diff)}';
    } else {
      icon = Icons.arrow_downward;
      text = percent != null
          ? '-${formatMoneyShort(diff.abs())} (${percent.abs().toStringAsFixed(0)}%)'
          : '-${formatMoneyShort(diff.abs())}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: bold ? 14 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            formatMoneyShort(current),
            style: TextStyle(
              fontSize: bold ? 14 : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 96,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(icon, size: 13, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- bảng số

class _TableCard extends StatelessWidget {
  final List<MonthBook> books;

  const _TableCard({required this.books});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = books.reversed.where((b) => b.total > 0).toList();
    if (rows.isEmpty) return const SizedBox.shrink();

    return AppCard(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bảng số liệu',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Cùng số liệu với biểu đồ, dạng bảng để đọc chính xác.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 38,
              dataRowMinHeight: 36,
              dataRowMaxHeight: 44,
              columnSpacing: 18,
              columns: const [
                DataColumn(label: Text('Tháng')),
                DataColumn(label: Text('Điện')),
                DataColumn(label: Text('Phòng')),
                DataColumn(label: Text('Quản lý')),
                DataColumn(label: Text('Tổng')),
              ],
              rows: rows.map((b) {
                return DataRow(cells: [
                  DataCell(Text(formatMonthShort(b.year, b.month))),
                  DataCell(Text(formatMoneyShort(
                      b.item(FeeType.electricity).amount))),
                  DataCell(
                      Text(formatMoneyShort(b.item(FeeType.room).amount))),
                  DataCell(Text(
                      formatMoneyShort(b.item(FeeType.management).amount))),
                  DataCell(Text(
                    formatMoneyShort(b.total),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  )),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
      child: Column(
        children: [
          Icon(Icons.insert_chart_outlined,
              size: 52, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 14),
          Text(
            'Chưa có số liệu để vẽ',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Nhập số tiền cho vài tháng, biểu đồ so sánh sẽ hiện ở đây.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
