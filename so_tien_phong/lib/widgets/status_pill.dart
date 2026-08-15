import 'package:flutter/material.dart';

import '../theme.dart';

/// Nhãn trạng thái: luôn có icon + chữ, không bao giờ chỉ dựa vào màu.
class StatusPill extends StatelessWidget {
  final bool paid;
  final String? textOverride;
  final bool dense;
  final Color? onSurface;

  const StatusPill({
    super.key,
    required this.paid,
    this.textOverride,
    this.dense = false,
    this.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    final color = paid ? StatusColors.ok(context) : StatusColors.bad(context);
    final base = onSurface ?? AppTheme.surfaceOf(context);
    final text = textOverride ?? (paid ? 'Đã đóng' : 'Chưa đóng');
    final icon = paid ? Icons.check_circle : Icons.error_outline;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 10,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: blend(base, color, 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: blend(base, color, 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: dense ? 13 : 15, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: dense ? 11.5 : 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
