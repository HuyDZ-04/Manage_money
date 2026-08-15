import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../utils/formatters.dart';
import '../widgets/month_body.dart';
import 'invoice_screen.dart';

class MonthDetailScreen extends StatelessWidget {
  final int year;
  final int month;

  const MonthDetailScreen({
    super.key,
    required this.year,
    required this.month,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(formatMonthLabel(year, month)),
        actions: [
          IconButton(
            tooltip: 'Hoá đơn',
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => InvoiceScreen(year: year, month: month),
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                await _confirmDelete(context);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.delete_outline),
                  title: Text('Xoá dữ liệu tháng này'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: MonthBody(year: year, month: month),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá dữ liệu tháng?'),
        content: Text(
          'Toàn bộ số tiền, hoá đơn và ảnh của '
          '${formatMonthLabel(year, month)} sẽ bị xoá. Không khôi phục được.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AppState>().deleteMonth(year, month);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}
