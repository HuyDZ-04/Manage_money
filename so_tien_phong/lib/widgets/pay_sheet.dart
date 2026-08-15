import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models/fee_type.dart';
import '../models/payment.dart';
import '../theme.dart';
import '../utils/formatters.dart';

/// Bảng xác nhận đóng tiền: chọn ngày, giờ, hình thức (chuyển khoản / tiền mặt...).
class PaySheet extends StatefulWidget {
  final List<Payment> payments;

  const PaySheet({super.key, required this.payments});

  static Future<bool?> show(BuildContext context, List<Payment> payments) {
    final pending = payments.where((p) => !p.isPaid).toList();
    if (pending.isEmpty) return Future.value(false);
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PaySheet(payments: pending),
    );
  }

  @override
  State<PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<PaySheet> {
  late DateTime _date;
  late TimeOfDay _time;
  PaymentMethod _method = PaymentMethod.transfer;
  late final TextEditingController _note;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
    _time = TimeOfDay(hour: now.hour, minute: now.minute);
    _note = TextEditingController(
      text: widget.payments.length == 1 ? (widget.payments.first.note ?? '') : '',
    );
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  DateTime get _paidAt => DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      );

  double get _total =>
      widget.payments.fold<double>(0, (s, p) => s + p.amount);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Chọn ngày đóng tiền',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: 'Chọn giờ đóng tiền',
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    final state = context.read<AppState>();
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();

    for (final p in widget.payments) {
      await state.markPaid(
        p,
        paidAt: _paidAt,
        method: _method,
        note: note,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final multiple = widget.payments.length > 1;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: AppTheme.borderOf(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              multiple ? 'Đóng ${widget.payments.length} khoản' : 'Xác nhận đã đóng',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              widget.payments
                  .map((p) => p.type.label)
                  .join(' • '),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceOf(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderOf(context)),
              ),
              child: Row(
                children: [
                  const Text('Tổng tiền',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(
                    formatMoney(_total),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Ngày đóng',
                    value: formatDate(_date),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.schedule_outlined,
                    label: 'Giờ đóng',
                    value: _time.format(context),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            Text('Hình thức',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PaymentMethod.values.map((m) {
                final selected = m == _method;
                return ChoiceChip(
                  selected: selected,
                  onSelected: (_) => setState(() => _method = m),
                  avatar: Icon(m.icon, size: 17),
                  label: Text(m.label),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            TextField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Nội dung chuyển khoản / ghi chú',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Hoá đơn sẽ được tạo tự động kèm ngày giờ và hình thức đóng.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            FilledButton.icon(
              onPressed: _saving ? null : _confirm,
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: Text(_saving ? 'Đang lưu...' : 'Xác nhận đã đóng'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceOf(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderOf(context)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodySmall),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
