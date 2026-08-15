import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/payment.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import '../widgets/month_body.dart';
import 'month_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final state = context.watch<AppState>();
    final overdue = state.unpaidMonths
        .where((m) => !(m.year == now.year && m.month == now.month))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(formatMonthLabel(now.year, now.month)),
      ),
      body: Column(
        children: [
          if (overdue.isNotEmpty) _OverdueBanner(months: overdue),
          Expanded(child: MonthBody(year: now.year, month: now.month)),
        ],
      ),
    );
  }
}

class _OverdueBanner extends StatelessWidget {
  final List<MonthBook> months;

  const _OverdueBanner({required this.months});

  @override
  Widget build(BuildContext context) {
    final color = StatusColors.bad(context);
    final first = months.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        background: tintScaffold(context, color, 0.09),
        borderColor: tintScaffold(context, color, 0.35),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                MonthDetailScreen(year: first.year, month: first.month),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: color, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                months.length == 1
                    ? '${formatMonthLabel(first.year, first.month)} vẫn còn khoản chưa đóng'
                    : '${months.length} tháng trước còn khoản chưa đóng',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
