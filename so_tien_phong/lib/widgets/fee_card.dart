import 'package:flutter/material.dart';

import '../models/fee_type.dart';
import '../models/payment.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import 'status_pill.dart';

/// Thẻ hiển thị một khoản phí trong tháng.
class FeeCard extends StatelessWidget {
  final Payment payment;
  final VoidCallback? onTap;
  final VoidCallback? onTogglePaid;

  const FeeCard({
    super.key,
    required this.payment,
    this.onTap,
    this.onTogglePaid,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = FeeColors.of(context, payment.type);
    final hasAmount = payment.amount > 0;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tint(context, color, 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(payment.type.icon, color: color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payment.type.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasAmount ? formatMoney(payment.amount) : 'Chưa nhập số tiền',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: hasAmount
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(paid: payment.isPaid),
            ],
          ),
          if (payment.isPaid && payment.paidAt != null) ...[
            const SizedBox(height: 10),
            Divider(color: AppTheme.borderOf(context), height: 1),
            const SizedBox(height: 9),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _MetaChip(
                  icon: Icons.event_available_outlined,
                  text: formatDateTime(payment.paidAt!),
                ),
                _MetaChip(
                  icon: payment.method.icon,
                  text: payment.method.label,
                ),
                if (payment.images.isNotEmpty)
                  _MetaChip(
                    icon: Icons.photo_library_outlined,
                    text: '${payment.images.length} ảnh',
                  ),
                if (payment.invoiceCode != null)
                  _MetaChip(
                    icon: Icons.receipt_long_outlined,
                    text: payment.invoiceCode!,
                  ),
              ],
            ),
          ] else if (onTogglePaid != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onTogglePaid,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Đánh dấu đã đóng'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 42),
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(fontSize: 12.5, color: color),
        ),
      ],
    );
  }
}
